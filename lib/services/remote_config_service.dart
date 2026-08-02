import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      // Set default values (falling back to .env if available)
      await _remoteConfig.setDefaults({
        'gemini_api_key': dotenv.env['GEMINI_API_KEY'] ?? '',
        'gemini_model': dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.6-flash',
        'youtube_api_key': dotenv.env['YOUTUBE_API_KEY'] ?? '',
        'admob_banner_id_android': dotenv.env['ADMOB_BANNER_ID_ANDROID'] ?? 'ca-app-pub-3940256099942544/6300978111',
        'admob_banner_id_ios': dotenv.env['ADMOB_BANNER_ID_IOS'] ?? 'ca-app-pub-3940256099942544/2934735716',
        'admob_interstitial_id_android': dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID'] ?? 'ca-app-pub-3940256099942544/1033173712',
        'admob_interstitial_id_ios': dotenv.env['ADMOB_INTERSTITIAL_ID_IOS'] ?? 'ca-app-pub-3940256099942544/4411468910',
        'mock_mode': true,
        'enable_upi_payments': true,
        'sync_images_to_cloud': false,
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.fetchAndActivate();
      
      // Listen to real-time updates safely across threads
      _remoteConfig.onConfigUpdated.listen((event) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _remoteConfig.activate();
            debugPrint("Remote Config Updated: ${event.updatedKeys}");
          } catch (e) {
            debugPrint("Error activating updated remote config: $e");
          }
        });
      });
      
    } catch (e) {
      debugPrint("Remote Config Init Error: $e");
    }
  }

  static String get geminiApiKey => _remoteConfig.getString('gemini_api_key');
  static String get geminiModel => _remoteConfig.getString('gemini_model');
  
  static String get youtubeApiKey => _remoteConfig.getString('youtube_api_key');
  
  static String get admobBannerIdAndroid => _remoteConfig.getString('admob_banner_id_android');
  static String get admobBannerIdIos => _remoteConfig.getString('admob_banner_id_ios');
  
  static String get admobInterstitialIdAndroid => _remoteConfig.getString('admob_interstitial_id_android');
  static String get admobInterstitialIdIos => _remoteConfig.getString('admob_interstitial_id_ios');
  
  static bool get mockMode => _remoteConfig.getBool('mock_mode');
  static bool get enableUpiPayments => _remoteConfig.getBool('enable_upi_payments');
  static bool get syncImagesToCloud => _remoteConfig.getBool('sync_images_to_cloud');
}
