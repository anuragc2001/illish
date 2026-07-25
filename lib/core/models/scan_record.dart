import 'package:isar/isar.dart';

part 'scan_record.g.dart';

@collection
class ScanRecord {
  Id id = Isar.autoIncrement;

  String? imagePath;
  String? englishName;
  String? localName;
  String? region;
  double? freshnessScore;
  String? freshnessStatus; // e.g. "Excellent"
  String? freshnessEvidence; // e.g. "Gills bright red"
  
  List<String> bestCuts = [];
  List<String> idealFor = [];
  
  DateTime timestamp = DateTime.now();
  bool isSynced = false;
  bool isBookmark = false;
}
