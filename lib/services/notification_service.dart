import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.icon = Icons.notifications_active,
  });
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final ValueNotifier<List<AppNotification>> notifications = ValueNotifier<List<AppNotification>>([
    AppNotification(
      id: '1',
      title: 'Freshness Streak ⚡',
      subtitle: 'You scanned 3 fresh fish this week! Great selection.',
      time: '2h ago',
      icon: Icons.bolt,
    ),
    AppNotification(
      id: '2',
      title: 'Market Tip 🐟',
      subtitle: 'Ilish prices are trending 10% lower in local markets today.',
      time: '5h ago',
      icon: Icons.trending_down,
    ),
    AppNotification(
      id: '3',
      title: 'Masterclass Unlocked 🎓',
      subtitle: 'Check out new guide on identifying gill freshness.',
      time: '1d ago',
      icon: Icons.school,
    ),
  ]);

  ValueNotifier<int> get unreadCount {
    final notifier = ValueNotifier<int>(notifications.value.length);
    notifications.addListener(() {
      notifier.value = notifications.value.length;
    });
    return notifier;
  }

  void clearAll() {
    notifications.value = [];
  }

  void remove(String id) {
    notifications.value = notifications.value.where((n) => n.id != id).toList();
  }
}
