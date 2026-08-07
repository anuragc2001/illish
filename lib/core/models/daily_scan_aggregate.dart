import 'package:isar/isar.dart';

part 'daily_scan_aggregate.g.dart';

@collection
@Name('DailyScanAggregate')
class DailyScanAggregate {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  int totalScans = 0;
  
  // The most frequently scanned fish for this day
  String? topFishName;
  
  // Format: "FishName:Count"
  List<String> fishCounts = [];
}
