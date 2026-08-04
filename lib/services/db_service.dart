import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/scan_record.dart';
import '../core/models/daily_scan_aggregate.dart';
import '../core/models/recipe_cache.dart';
import '../config/app_config.dart';
import 'sync_service.dart';

class DBService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    AppConfig.documentsPath = dir.path;
    debugPrint('📁 Isar DB Directory: ${dir.path}');
    isar = await Isar.open(
      [ScanRecordSchema, RecipeCacheSchema, DailyScanAggregateSchema],
      directory: dir.path,
    );
    
    await _migrateLegacyScansToAggregates();
  }

  static Future<void> _migrateLegacyScansToAggregates() async {
    final hasAggregates = await isar.dailyScanAggregates.count() > 0;
    if (hasAggregates) return; // Only run once
    
    final allScans = await isar.scanRecords.where().findAll();
    if (allScans.isEmpty) return;
    
    await isar.writeTxn(() async {
      for (var scan in allScans) {
        await updateDailyAggregate(scan);
      }
    });
  }

  static String? getImagePath(String? savedPath) {
    if (savedPath == null) return null;
    
    // If it's just a filename (new implementation), it won't contain a slash.
    if (!savedPath.contains('/')) {
      return '${AppConfig.documentsPath}/$savedPath';
    }
    
    // Legacy data handling (or if saving to documents failed):
    // Attempt to map the filename to the documents path.
    final filename = savedPath.split('/').last;
    final documentsResolved = '${AppConfig.documentsPath}/$filename';
    
    // If we actually copied it to Documents, it will exist here.
    if (File(documentsResolved).existsSync()) {
      return documentsResolved;
    }
    
    // If it's not in documents (e.g. legacy scan on Android where temp path is still valid),
    // fallback to the original absolute path. (Note: on iOS restarts, this temp path is invalid).
    return savedPath;
  }

  static Future<int> saveScan(Map<String, dynamic> aiData, {bool isBookmark = false}) async {
    if (aiData['error'] == true) {
      debugPrint("DBService.saveScan: Error scan detected, skipping DB save.");
      return -1;
    }
    
    final eName = aiData['englishName']?.toString().trim().toLowerCase() ?? '';
    if (eName.isEmpty || eName == 'unknown' || eName == 'unknown fish') {
      debugPrint("DBService.saveScan: Unknown or null fish detected, skipping DB save.");
      return -1;
    }

    final now = DateTime.now();
    final record = ScanRecord()
      ..id = now.millisecondsSinceEpoch
      ..imagePath = aiData['imagePath']
      ..englishName = aiData['englishName']
      ..localName = aiData['localName']
      ..region = aiData['location']
      ..freshnessScore = aiData['freshnessScore']
      ..freshnessStatus = aiData['freshnessStatus']
      ..freshnessEvidence = aiData['freshnessEvidence']
      ..bestCuts = List<String>.from(aiData['bestCuts'] ?? [])
      ..idealFor = List<String>.from(aiData['idealFor'] ?? [])
      ..trickeryTips = List<String>.from(aiData['trickeryTips'] ?? [])
      ..suggestedPrice = aiData['suggestedPrice']?.toString()
      ..marketAvgPrice = aiData['marketAvgPrice']?.toString()
      ..timestamp = now
      ..isBookmark = isBookmark
      ..isUnlocked = AppConfig.isPremiumUser;

    await isar.writeTxn(() async {
      await isar.scanRecords.put(record);
      
      // Update Daily Aggregate
      await updateDailyAggregate(record);
      
      // Async fire-and-forget sync to Firestore
      SyncService.upsertScanRecord(record);
      
      if (!isBookmark) {
        // Retain scans on a 30-day rolling basis.
        // Anything older than 30 days from right now is archived.
        final cutoffDate = now.subtract(const Duration(days: 30));
        final oldScans = await isar.scanRecords
            .filter()
            .isBookmarkEqualTo(false)
            .timestampLessThan(cutoffDate)
            .findAll();
            
        if (oldScans.isNotEmpty) {
          final toDelete = oldScans.map((e) => e.id).toList();
          await isar.scanRecords.deleteAll(toDelete);
          
          for (var scan in oldScans) {
            await _cleanupImageIfUnused(scan.imagePath);
            await SyncService.archiveScanRecord(scan.id); // Deletes cloud image & flags as archived
          }
        }
      }
    });
    
    return record.id;
  }

  static Future<void> unlockScan(int id) async {
    await isar.writeTxn(() async {
      final record = await isar.scanRecords.get(id);
      if (record != null) {
        record.isUnlocked = true;
        await isar.scanRecords.put(record);
      }
    });
    // Always mark as unlocked in cloud (even if archived/not in local DB)
    await SyncService.unlockScanInCloud(id);
  }

  static Future<List<ScanRecord>> getRecentScans({int offset = 0, int limit = 15}) async {
    return await isar.scanRecords
        .filter()
        .isHiddenEqualTo(false)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  static Future<List<ScanRecord>> getBookmarks({int offset = 0, int limit = 15}) async {
    return await isar.scanRecords
        .filter()
        .isBookmarkEqualTo(true)
        .and()
        .isHiddenEqualTo(false)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  static Future<bool> isBookmarked(int? id, String? imagePath) async {
    if (id != null) {
      final record = await isar.scanRecords.get(id);
      if (record != null) return record.isBookmark;
    }
    if (imagePath != null) {
      final count = await isar.scanRecords.filter().imagePathEqualTo(imagePath).isBookmarkEqualTo(true).count();
      return count > 0;
    }
    return false;
  }

  static Future<void> setBookmarkStatus(int? id, String? imagePath, bool status) async {
    if (id == null && imagePath == null) return;
    await isar.writeTxn(() async {
      ScanRecord? record;
      if (id != null) {
        record = await isar.scanRecords.get(id);
      }
      if (record == null && imagePath != null) {
        // Fallback to imagePath if id is not available
        record = await isar.scanRecords.filter().imagePathEqualTo(imagePath).sortByTimestampDesc().findFirst();
      }
      
      if (record != null) {
        record.isBookmark = status;
        await isar.scanRecords.put(record);
        SyncService.upsertScanRecord(record);
      }
    });
  }

  static Future<void> _cleanupImageIfUnused(String? imagePath) async {
    if (imagePath == null) return;
    final count = await isar.scanRecords.filter().imagePathEqualTo(imagePath).count();
    if (count == 0) {
      final absolutePath = getImagePath(imagePath);
      if (absolutePath != null) {
        final file = File(absolutePath);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (e) {
            // ignore
          }
        }
      }
    }
  }

  static Future<String?> getCachedRecipes(String query) async {
    final cache = await isar.recipeCaches.where().speciesQueryEqualTo(query).findFirst();
    if (cache != null && DateTime.now().difference(cache.lastUpdated).inDays < 7) {
      return cache.cachedJsonData;
    }
    return null;
  }

  static Future<void> deleteScan(int id) async {
    final scan = await isar.scanRecords.get(id);
    final imagePath = scan?.imagePath;
    await isar.writeTxn(() async {
      await isar.scanRecords.delete(id);
    });
    
    // Async fire-and-forget sync archive (soft delete)
    SyncService.archiveScanRecord(id);
    
    await _cleanupImageIfUnused(imagePath);
  }

  static Future<void> clearRecentScans() async {
    final scans = await isar.scanRecords.filter().isBookmarkEqualTo(false).findAll();
    await isar.writeTxn(() async {
      await isar.scanRecords.filter().isBookmarkEqualTo(false).deleteAll();
    });
    for (var scan in scans) {
      SyncService.archiveScanRecord(scan.id); // Soft delete from Firebase cloud
      await _cleanupImageIfUnused(scan.imagePath);
    }
  }

  static Future<void> hideRecentScans() async {
    final scans = await isar.scanRecords.filter().isBookmarkEqualTo(false).and().isHiddenEqualTo(false).findAll();
    await isar.writeTxn(() async {
      for (var scan in scans) {
        scan.isHidden = true;
        await isar.scanRecords.put(scan);
      }
    });
    // Sync the hidden status to Firebase for all updated scans
    for (var scan in scans) {
      SyncService.upsertScanRecord(scan);
    }
  }

  static Future<void> hideScan(int id) async {
    ScanRecord? updatedScan;
    await isar.writeTxn(() async {
      final scan = await isar.scanRecords.get(id);
      if (scan != null) {
        scan.isHidden = true;
        await isar.scanRecords.put(scan);
        updatedScan = scan;
      }
    });
    // Sync the hidden status to Firebase
    if (updatedScan != null) {
      SyncService.upsertScanRecord(updatedScan!);
    }
  }

  static Future<void> clearAll() async {
    final scans = await isar.scanRecords.where().findAll();
    await isar.writeTxn(() async {
      await isar.scanRecords.clear();
      await isar.dailyScanAggregates.clear();
    });
    for (var scan in scans) {
      final absolutePath = getImagePath(scan.imagePath);
      if (absolutePath != null) {
        final file = File(absolutePath);
        if (file.existsSync()) {
          try { file.deleteSync(); } catch (_) {}
        }
      }
    }
  }

  static Future<void> saveCachedRecipes(String query, String jsonData) async {
    final cache = RecipeCache()
      ..speciesQuery = query
      ..cachedJsonData = jsonData
      ..lastUpdated = DateTime.now();
      
    await isar.writeTxn(() async {
      await isar.recipeCaches.put(cache);
    });
  }

  static String formatAmPm(DateTime dt) {
    final local = dt.toLocal();
    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  static String normalizeFishName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    // Remove anything in parentheses
    String normalized = name.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
    if (normalized.isEmpty) return name.trim();
    // Capitalize first letter
    if (normalized.length > 1) {
      return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
    }
    return normalized.toUpperCase();
  }

  static Future<void> updateDailyAggregate(ScanRecord record) async {
    final localTime = record.timestamp.toLocal();
    final dateKey = DateTime(localTime.year, localTime.month, localTime.day);
    
    DailyScanAggregate? aggregate = await isar.dailyScanAggregates.filter().dateEqualTo(dateKey).findFirst();
    if (aggregate == null) {
      aggregate = DailyScanAggregate()
        ..date = dateKey
        ..totalScans = 0
        ..fishCounts = [];
    }

    aggregate.totalScans += 1;

    String normalizedName = normalizeFishName(record.englishName);
    
    // Parse existing fishCounts
    Map<String, int> counts = {};
    for (var fc in aggregate.fishCounts) {
      final parts = fc.split(':');
      if (parts.length == 2) {
        counts[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }

    counts[normalizedName] = (counts[normalizedName] ?? 0) + 1;

    // Determine top fish
    String topFish = normalizedName;
    int maxCount = 0;
    List<String> newFishCounts = [];
    counts.forEach((k, v) {
      newFishCounts.add('$k:$v');
      if (v > maxCount) {
        maxCount = v;
        topFish = k;
      }
    });

    aggregate.fishCounts = newFishCounts;
    aggregate.topFishName = topFish;

    await isar.dailyScanAggregates.put(aggregate);
    
    // Async fire-and-forget sync to Firebase
    SyncService.upsertDailyAggregate(aggregate);
  }
}
