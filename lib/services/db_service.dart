import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/models/scan_record.dart';
import '../core/models/recipe_cache.dart';
import '../config/app_config.dart';
import 'sync_service.dart';

class DBService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    AppConfig.documentsPath = dir.path;
    isar = await Isar.open(
      [ScanRecordSchema, RecipeCacheSchema],
      directory: dir.path,
    );
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
      
      // Async fire-and-forget sync to Firestore
      SyncService.upsertScanRecord(record);
      
      if (!isBookmark) {
        final overflowScans = await isar.scanRecords
            .filter()
            .isBookmarkEqualTo(false)
            .sortByTimestampDesc()
            .offset(15)
            .findAll();
        if (overflowScans.isNotEmpty) {
          final toDelete = overflowScans.map((e) => e.id).toList();
          await isar.scanRecords.deleteAll(toDelete);
          
          for (var scan in overflowScans) {
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
        SyncService.upsertScanRecord(record);
      }
    });
  }

  static Future<List<ScanRecord>> getRecentScans({int offset = 0, int limit = 15}) async {
    return await isar.scanRecords
        .filter()
        .isBookmarkEqualTo(false)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  static Future<List<ScanRecord>> getBookmarks({int offset = 0, int limit = 15}) async {
    return await isar.scanRecords
        .filter()
        .isBookmarkEqualTo(true)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  static Future<bool> isBookmarked(String? imagePath) async {
    if (imagePath == null) return false;
    final count = await isar.scanRecords.filter().imagePathEqualTo(imagePath).isBookmarkEqualTo(true).count();
    return count > 0;
  }

  static Future<void> removeBookmark(String? imagePath) async {
    if (imagePath == null) return;
    await isar.writeTxn(() async {
      await isar.scanRecords.filter().imagePathEqualTo(imagePath).isBookmarkEqualTo(true).deleteAll();
    });
    await _cleanupImageIfUnused(imagePath);
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

  static Future<void> clearAll() async {
    final scans = await isar.scanRecords.where().findAll();
    await isar.writeTxn(() async {
      await isar.scanRecords.clear();
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
}
