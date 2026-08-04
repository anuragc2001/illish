import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'core/theme.dart';
import 'services/remote_config_service.dart';
import 'screens/camera_screen.dart';
import 'services/db_service.dart';
import 'services/admob_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';

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
}

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  await RemoteConfigService.initialize();

  await DBService.initialize();
  await AdMobService.initialize();

  // Initialize notifications
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

  await NotificationService().init();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('CameraError: ${e.code}, ${e.description}');
  }

  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  if (AuthService.currentUser != null && !AuthService.currentUser!.isAnonymous) {
    SyncService.startRealtimeSync();
  }

  runApp(const IllishApp());
}

class IllishApp extends StatelessWidget {
  const IllishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'illish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: cameras.isEmpty
          ? const Scaffold(body: Center(child: Text("No cameras found")))
          : const CameraScreen(),
    );
  }
}
