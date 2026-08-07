import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/app_notification_model.dart';
import 'db_service.dart';

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

  factory AppNotification.fromModel(AppNotificationModel model) {
    IconData getIconData(String name) {
      switch (name) {
        case 'bolt': return Icons.bolt;
        case 'trending_down': return Icons.trending_down;
        case 'school': return Icons.school;
        case 'warning': return Icons.warning;
        case 'local_fire_department': return Icons.local_fire_department;
        default: return Icons.notifications_active;
      }
    }

    return AppNotification(
      id: model.firestoreId.isNotEmpty ? model.firestoreId : model.id.toString(),
      title: model.title,
      subtitle: model.subtitle,
      time: _formatTimeAgo(model.timestamp),
      icon: getIconData(model.iconName),
    );
  }

  static String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ValueNotifier<List<AppNotification>> notifications = ValueNotifier<List<AppNotification>>([]);
  
  /* Mock data - commented out as requested
  final ValueNotifier<List<AppNotification>> notifications = ValueNotifier<List<AppNotification>>([
    AppNotification(
      id: '1',
      title: 'Freshness Streak ⚡',
      subtitle: 'You scanned 3 fresh fish this week! Great selection.',
      time: '2h ago',
      icon: Icons.bolt,
    ),
    // ...
  ]);
  */

  ValueNotifier<int> get unreadCount {
    final notifier = ValueNotifier<int>(notifications.value.length);
    notifications.addListener(() {
      notifier.value = notifications.value.length;
    });
    return notifier;
  }

  StreamSubscription<QuerySnapshot>? _firestoreSub;
  StreamSubscription<User?>? _authSub;

  Future<void> init() async {
    await _loadFromLocal();
    _setupFirebaseMessaging();
    
    // Listen for auth state changes so Firestore sync attaches even if user signs in after startup
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _setupFirestoreSync(user.uid);
      } else {
        stopSync();
      }
    });
  }

  void stopSync() {
    _firestoreSub?.cancel();
    _firestoreSub = null;
  }

  Future<void> reloadFromLocal() async {
    await _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    // 2. Load from Isar
    final models = await DBService.getNotifications();
    notifications.value = models.map((m) => AppNotification.fromModel(m)).toList();
  }

  void _setupFirebaseMessaging() {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _handleRemoteMessage(message);
    });

    // 2. Background messages (when app is in background and user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleRemoteMessage(message);
    });

    // 3. Terminated messages (when app is closed and user taps notification)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        await _handleRemoteMessage(message);
      }
    });
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    
    if (message.notification != null) {
      data['title'] = data['title'] ?? message.notification!.title ?? 'New Notification';
      data['subtitle'] = data['subtitle'] ?? message.notification!.body ?? '';
    }

    data['id'] = data['id'] ?? message.messageId;

    await _processIncomingNotification(data);
  }

  void _setupFirestoreSync(String uid) {
    _firestoreSub?.cancel();
    _firestoreSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          await DBService.markNotificationCleared(change.doc.id);
        } else if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;
          
          if (data['isCleared'] == true) {
            await DBService.markNotificationCleared(change.doc.id);
          } else {
            data['firestoreId'] = change.doc.id;
            await _processIncomingNotification(data);
          }
        }
      }
      await _loadFromLocal();
    });
  }

  Future<void> _processIncomingNotification(Map<String, dynamic> data) async {
    final rawId = data['id'] ?? data['firestoreId'];
    final title = data['title'] ?? 'New Notification';
    final timestamp = data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) ?? DateTime.now() : DateTime.now();

    final firestoreId = (rawId != null && rawId.toString().trim().isNotEmpty)
        ? rawId.toString().trim()
        : '${title.replaceAll(RegExp(r'\s+'), '_')}_${(data['subtitle'] ?? '').hashCode}';

    final notif = AppNotificationModel()
      ..firestoreId = firestoreId
      ..title = title
      ..subtitle = data['subtitle'] ?? ''
      ..iconName = data['icon'] ?? 'notifications_active'
      ..timestamp = timestamp
      ..isCleared = false;
      
    await DBService.saveNotification(notif);
    
    // Manually update in-memory list instead of calling _loadFromLocal() to avoid infinite recursion
    final appNotif = AppNotification.fromModel(notif);
    final currentList = List<AppNotification>.from(notifications.value);
    final existingIdx = currentList.indexWhere((n) => n.id == appNotif.id || (n.id == appNotif.id.toString()));
    if (existingIdx >= 0) {
      currentList[existingIdx] = appNotif;
    } else {
      currentList.insert(0, appNotif);
    }
    notifications.value = currentList;

    // Sync newly received FCM payload UP to Firestore so other devices (Phone B) receive it!
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && notif.firestoreId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notif.firestoreId)
          .set({
            'id': notif.firestoreId,
            'title': notif.title,
            'subtitle': notif.subtitle,
            'icon': notif.iconName,
            'timestamp': notif.timestamp.toIso8601String(),
            'isCleared': false,
          }, SetOptions(merge: true));
    }
  }

  void clearAll() async {
    await DBService.clearAllNotifications();
    await _loadFromLocal();

    // Soft-delete all notification documents in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isCleared': true});
      }
      await batch.commit().catchError((e) => debugPrint("Firestore clearAll error: $e"));
    }
  }

  void remove(String id) async {
    await DBService.markNotificationCleared(id);
    await _loadFromLocal();

    // Soft-delete individual notification document in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && id.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .update({'isCleared': true})
          .catchError((e) => debugPrint("Firestore delete error: $e"));
    }
  }
}
