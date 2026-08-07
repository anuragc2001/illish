import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'core/theme.dart';
import 'config/app_config.dart';
import 'services/remote_config_service.dart';
import 'screens/camera_screen.dart';
import 'services/db_service.dart';
import 'services/admob_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'core/models/app_notification_model.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}

// Background messaging handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  try {
    await DBService.initialize();
    
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    if (message.notification != null) {
      data['title'] = data['title'] ?? message.notification!.title ?? 'New Notification';
      data['subtitle'] = data['subtitle'] ?? message.notification!.body ?? '';
    }
    
    final rawId = data['id'] ?? message.messageId;
    final title = data['title'] ?? 'New Notification';
    final timestamp = DateTime.now();

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
    
    // Sync to Firestore immediately from background
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
    
    debugPrint("Saved background notification directly to Isar DB and Firestore.");
  } catch (e) {
    debugPrint("Failed to save background notification: $e");
  }
}

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  // Initialize Core Services required for initial frame
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  try {
    await DBService.initialize();
  } catch (e) {
    debugPrint("DB Init Error: $e");
  }

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('CameraError: ${e.code}, ${e.description}');
  } catch (e) {
    debugPrint('Camera init error: $e');
  }

  // Load offline premium state immediately so UI builds correctly without internet
  try {
    await AppConfig.initOfflinePremiumState();
  } catch (e) {
    debugPrint('Error loading offline premium state: $e');
  }

  // Launch UI
  runApp(const IllishApp());

  // Non-blocking background initializations
  _initSecondaryServices();
}

Future<void> _initSecondaryServices() async {
  try {
    await RemoteConfigService.initialize();
  } catch (e) {
    debugPrint("RemoteConfig error: $e");
  }

  try {
    await AdMobService.initialize();
  } catch (e) {
    debugPrint("AdMob error: $e");
  }

  try {
    await PaymentService.initRevenueCat();
  } catch (e) {
    debugPrint("RevenueCat initialization error: $e");
  }

  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Subscribe to a generic topic so Campaigns can target "Topic: all_users"
    await messaging.subscribeToTopic('all_users');
  } catch (e) {
    debugPrint("Messaging permission error: $e");
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Notification init error: $e");
  }

  try {
    if (Platform.isAndroid) {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    }
  } catch (e) {
    debugPrint("Workmanager error: $e");
  }

  try {
    if (AuthService.currentUser != null && !AuthService.currentUser!.isAnonymous) {
      SyncService.startRealtimeSync();
    }
  } catch (e) {
    debugPrint("SyncService error: $e");
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class IllishApp extends StatelessWidget {
  const IllishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Illish',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: AppTheme.darkTheme,
      home: const CameraScreen(),
    );
  }
}
