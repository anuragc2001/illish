import 'package:isar/isar.dart';

part 'app_notification_model.g.dart';

@collection
class AppNotificationModel {
  Id id = Isar.autoIncrement;

  @Index()
  String firestoreId = '';

  String title = '';
  String subtitle = '';
  String time = '';
  String iconName = '';
  DateTime timestamp = DateTime.now();
  
  bool isRead = false;
  bool isCleared = false; // Soft delete flag
}
