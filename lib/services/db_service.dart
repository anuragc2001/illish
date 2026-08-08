import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/scan_record.dart';
import '../core/models/daily_scan_aggregate.dart';
import '../core/models/recipe_cache.dart';
import '../core/models/app_notification_model.dart';
import '../config/app_config.dart';
import 'sync_service.dart';

class DBService {
  static late Isar isar;
  static bool get isInitialized => Isar.instanceNames.contains(Isar.defaultName);
  static String? lastError;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    AppConfig.documentsPath = dir.path;
    try {
      isar = await Isar.open(
        [ScanRecordSchema, RecipeCacheSchema, DailyScanAggregateSchema, AppNotificationModelSchema],
        directory: dir.path,
        inspector: kDebugMode,
      );
    } catch (e) {
      lastError = e.toString();
      debugPrint('⚠️ Error opening Isar DB: $e');
      if (Isar.instanceNames.contains(Isar.defaultName)) {
        isar = Isar.getInstance()!;
      } else {
        try {
          debugPrint('⚠️ Attempting to clear and recreate Isar DB due to corruption/schema mismatch...');
          final isarFile = File('${dir.path}/default.isar');
          final lockFile = File('${dir.path}/default.isar.lock');
          if (isarFile.existsSync()) isarFile.deleteSync();
          if (lockFile.existsSync()) lockFile.deleteSync();
          
          isar = await Isar.open(
            [ScanRecordSchema, RecipeCacheSchema, DailyScanAggregateSchema, AppNotificationModelSchema],
            directory: dir.path,
            inspector: kDebugMode,
          );
        } catch (retryError) {
          lastError = retryError.toString();
          debugPrint('⚠️ Failed to recreate Isar DB: $retryError');
          // Do not rethrow. Let the app run in degraded mode.
        }
      }
    }
    
    if (isInitialized) {
      await _migrateLegacyScansToAggregates();
    }
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
    if (!isInitialized) return -1;
    
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

    List<ScanRecord> oldScans = [];
    await isar.writeTxn(() async {
      await isar.scanRecords.put(record);
      
      // Update Daily Aggregate
      await updateDailyAggregate(record);
      
      if (!isBookmark) {
        // Retain scans on a 30-day rolling basis.
        // Anything older than 30 days from right now is archived.
        final cutoffDate = now.subtract(const Duration(days: 30));
        oldScans = await isar.scanRecords
            .filter()
            .isBookmarkEqualTo(false)
            .timestampLessThan(cutoffDate)
            .findAll();
            
        if (oldScans.isNotEmpty) {
          final toDelete = oldScans.map((e) => e.id).toList();
          await isar.scanRecords.deleteAll(toDelete);
        }
      }
    });

    // Safely sync to Firestore outside transaction
    await SyncService.upsertScanRecord(record);

    if (!isBookmark && oldScans.isNotEmpty) {
      for (var scan in oldScans) {
        await _cleanupImageIfUnused(scan.imagePath);
        await SyncService.archiveScanRecord(scan.id); // Deletes cloud image & flags as archived
      }
    }
    
    return record.id;
  }

  static Future<void> unlockAllScans() async {
    if (!isInitialized) return;
    final lockedScans = await isar.scanRecords.filter().isUnlockedEqualTo(false).findAll();
    if (lockedScans.isEmpty) return;

    await isar.writeTxn(() async {
      for (var scan in lockedScans) {
        scan.isUnlocked = true;
        await isar.scanRecords.put(scan);
      }
    });

    for (var scan in lockedScans) {
      await SyncService.unlockScanInCloud(scan.id);
    }
  }

  static Future<void> unlockScan(int id) async {
    if (!isInitialized) return;
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
    if (!isInitialized) return [];
    return await isar.scanRecords
        .filter()
        .isHiddenEqualTo(false)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  static Future<List<ScanRecord>> getBookmarks({int offset = 0, int limit = 15}) async {
    if (!isInitialized) return [];
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
    if (!isInitialized) return false;
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
    if (!isInitialized) return;
    if (id == null && imagePath == null) return;
    
    ScanRecord? record;
    
    await isar.writeTxn(() async {
      if (id != null) {
        record = await isar.scanRecords.get(id);
      }
      if (record == null && imagePath != null) {
        // Fallback to imagePath if id is not available
        record = await isar.scanRecords.filter().imagePathEqualTo(imagePath).sortByTimestampDesc().findFirst();
      }
      
      if (record != null) {
        record!.isBookmark = status;
        await isar.scanRecords.put(record!);
      }
    });

    // Sync outside txn
    if (record != null) {
      await SyncService.upsertScanRecord(record!);
    }
  }

  static Future<void> _cleanupImageIfUnused(String? imagePath) async {
    if (!isInitialized) return;
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
    if (!isInitialized) return null;
    final cache = await isar.recipeCaches.where().speciesQueryEqualTo(query).findFirst();
    if (cache != null && DateTime.now().difference(cache.lastUpdated).inDays < 7) {
      return cache.cachedJsonData;
    }
    return null;
  }

  static Future<void> deleteScan(int id) async {
    if (!isInitialized) return;
    final scan = await isar.scanRecords.get(id);
    final imagePath = scan?.imagePath;
    await isar.writeTxn(() async {
      await isar.scanRecords.delete(id);
    });
    
    // Sync archive (soft delete) outside txn
    await SyncService.archiveScanRecord(id);
    
    await _cleanupImageIfUnused(imagePath);
  }

  static Future<void> clearRecentScans() async {
    if (!isInitialized) return;
    final scans = await isar.scanRecords.filter().isBookmarkEqualTo(false).findAll();
    await isar.writeTxn(() async {
      await isar.scanRecords.filter().isBookmarkEqualTo(false).deleteAll();
    });
    for (var scan in scans) {
      await SyncService.archiveScanRecord(scan.id); // Soft delete from Firebase cloud
      await _cleanupImageIfUnused(scan.imagePath);
    }
  }

  static Future<void> hideRecentScans() async {
    if (!isInitialized) return;
    final scans = await isar.scanRecords.filter().isBookmarkEqualTo(false).and().isHiddenEqualTo(false).findAll();
    await isar.writeTxn(() async {
      for (var scan in scans) {
        scan.isHidden = true;
        await isar.scanRecords.put(scan);
      }
    });
    // Sync the hidden status to Firebase for all updated scans
    for (var scan in scans) {
      await SyncService.upsertScanRecord(scan);
    }
  }

  static Future<void> hideScan(int id) async {
    if (!isInitialized) return;
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
      await SyncService.upsertScanRecord(updatedScan!);
    }
  }

  static Future<void> clearAll() async {
    if (!isInitialized) return;
    final scans = await isar.scanRecords.where().findAll();
    await isar.writeTxn(() async {
      await isar.scanRecords.clear();
      await isar.dailyScanAggregates.clear();
      await isar.appNotificationModels.clear();
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
    if (!isInitialized) return;
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

  static Future<void> updateDailyAggregate(ScanRecord record, {bool inTxn = true}) async {
    if (!isInitialized) return;
    final localTime = record.timestamp.toLocal();
    final dateKey = DateTime(localTime.year, localTime.month, localTime.day);
    
    DailyScanAggregate? aggregate = await isar.dailyScanAggregates.filter().dateEqualTo(dateKey).findFirst();
    aggregate ??= DailyScanAggregate()
      ..date = dateKey
      ..totalScans = 0
      ..fishCounts = [];

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

    if (inTxn) {
      await isar.dailyScanAggregates.put(aggregate!);
    } else {
      await isar.writeTxn(() async {
        await isar.dailyScanAggregates.put(aggregate!);
      });
    }
    
    // Sync to Firebase outside transaction blocking
    if (!inTxn) {
      await SyncService.upsertDailyAggregate(aggregate!);
    } else {
      // If we are in a transaction (like saveScan), defer sync to avoid blocking Isar write thread
      Future.microtask(() => SyncService.upsertDailyAggregate(aggregate!));
    }
  }

  // --- Notification Methods ---
  static Future<List<AppNotificationModel>> getNotifications() async {
    if (!isInitialized) return [];
    return await isar.appNotificationModels
        .filter()
        .isClearedEqualTo(false)
        .sortByTimestampDesc()
        .findAll();
  }

  static Future<void> saveNotification(AppNotificationModel notif) async {
    if (!isInitialized) return;
    if (notif.firestoreId.isNotEmpty) {
      final existing = await isar.appNotificationModels
          .filter()
          .firestoreIdEqualTo(notif.firestoreId)
          .findFirst();
      if (existing != null) {
        notif.id = existing.id; // Reuse existing primary key to UPDATE instead of inserting duplicate
        notif.timestamp = existing.timestamp; // Preserve original timestamp to prevent tap overwriting
      }
    }
    await isar.writeTxn(() async {
      await isar.appNotificationModels.put(notif);
    });
  }

  static Future<void> markNotificationCleared(String identifier) async {
    if (!isInitialized) return;
    await isar.writeTxn(() async {
      // Delete by firestoreId first
      final count = await isar.appNotificationModels.filter().firestoreIdEqualTo(identifier).deleteAll();
      if (count == 0) {
        // Fallback: delete by autoIncrement primary key
        final intId = int.tryParse(identifier);
        if (intId != null) {
          await isar.appNotificationModels.delete(intId);
        }
      }
    });
  }

  static Future<void> clearAllNotifications() async {
    await isar.writeTxn(() async {
      await isar.appNotificationModels.clear();
    });
  }
}

