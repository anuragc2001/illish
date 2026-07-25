import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../core/models/scan_record.dart';
import '../core/models/recipe_cache.dart';

class DBService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ScanRecordSchema, RecipeCacheSchema],
      directory: dir.path,
    );
  }

  static Future<void> saveScan(Map<String, dynamic> aiData, {bool isBookmark = false}) async {
    final record = ScanRecord()
      ..imagePath = aiData['imagePath']
      ..englishName = aiData['englishName']
      ..localName = aiData['localName']
      ..freshnessScore = aiData['freshnessScore']
      ..freshnessStatus = aiData['freshnessStatus']
      ..freshnessEvidence = aiData['freshnessEvidence']
      ..bestCuts = List<String>.from(aiData['bestCuts'] ?? [])
      ..idealFor = List<String>.from(aiData['idealFor'] ?? [])
      ..timestamp = DateTime.now()
      ..isBookmark = isBookmark;

    await isar.writeTxn(() async {
      await isar.scanRecords.put(record);
      
      if (!isBookmark) {
        final recentScans = await isar.scanRecords.filter().isBookmarkEqualTo(false).sortByTimestampDesc().findAll();
        if (recentScans.length > 10) {
          final toDelete = recentScans.sublist(10).map((e) => e.id).toList();
          await isar.scanRecords.deleteAll(toDelete);
        }
      }
    });
  }

  static Future<List<ScanRecord>> getRecentScans() async {
    return await isar.scanRecords.filter().isBookmarkEqualTo(false).sortByTimestampDesc().limit(10).findAll();
  }

  static Future<List<ScanRecord>> getBookmarks() async {
    return await isar.scanRecords.filter().isBookmarkEqualTo(true).sortByTimestampDesc().findAll();
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
  }

  static Future<String?> getCachedRecipes(String query) async {
    final cache = await isar.recipeCaches.where().speciesQueryEqualTo(query).findFirst();
    if (cache != null && DateTime.now().difference(cache.lastUpdated).inDays < 7) {
      return cache.cachedJsonData;
    }
    return null;
  }

  static Future<void> deleteScan(int id) async {
    await isar.writeTxn(() async {
      await isar.scanRecords.delete(id);
    });
  }

  static Future<void> clearRecentScans() async {
    await isar.writeTxn(() async {
      await isar.scanRecords.filter().isBookmarkEqualTo(false).deleteAll();
    });
  }

  static Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.scanRecords.clear();
    });
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
