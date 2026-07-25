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

  static Future<void> saveScan(Map<String, dynamic> aiData) async {
    final record = ScanRecord()
      ..imagePath = aiData['imagePath']
      ..englishName = aiData['englishName']
      ..localName = aiData['localName']
      ..freshnessScore = aiData['freshnessScore']
      ..freshnessStatus = aiData['freshnessStatus']
      ..freshnessEvidence = aiData['freshnessEvidence']
      ..bestCuts = List<String>.from(aiData['bestCuts'] ?? [])
      ..idealFor = List<String>.from(aiData['idealFor'] ?? [])
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {
      await isar.scanRecords.put(record);
    });
  }

  static Future<List<ScanRecord>> getRecentScans() async {
    return await isar.scanRecords.where().sortByTimestampDesc().findAll();
  }

  static Future<String?> getCachedRecipes(String query) async {
    final cache = await isar.recipeCaches.where().speciesQueryEqualTo(query).findFirst();
    if (cache != null && DateTime.now().difference(cache.lastUpdated).inDays < 7) {
      return cache.cachedJsonData;
    }
    return null;
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
