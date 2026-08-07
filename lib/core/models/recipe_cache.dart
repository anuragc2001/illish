import 'package:isar/isar.dart';

part 'recipe_cache.g.dart';

@collection
@Name('RecipeCache')
class RecipeCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String speciesQuery;
  
  late String cachedJsonData;
  late DateTime lastUpdated;
}
