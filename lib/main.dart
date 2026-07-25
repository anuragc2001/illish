import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'screens/camera_screen.dart';
import 'services/db_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");
    // TODO: Implement Isar -> Supabase sync logic here
    return Future.value(true);
  });
}

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await DBService.initialize();
  
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('CameraError: ${e.code}, ${e.description}');
  }
  
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

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
