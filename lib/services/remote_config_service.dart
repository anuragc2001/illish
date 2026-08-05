import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static final ValueNotifier<int> configUpdateNotifier = ValueNotifier<int>(0);

  static Future<void> initialize() async {
    try {
      // Set default values (falling back to .env if available)
      await _remoteConfig.setDefaults({
        'gemini_api_key': dotenv.env['GEMINI_API_KEY'] ?? '',
        'gemini_model': dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.6-flash',
        'youtube_api_key': dotenv.env['YOUTUBE_API_KEY'] ?? '',
        'admob_banner_id_android':
            dotenv.env['ADMOB_BANNER_ID_ANDROID'] ??
            'ca-app-pub-3940256099942544/6300978111',
        'admob_banner_id_ios':
            dotenv.env['ADMOB_BANNER_ID_IOS'] ??
            'ca-app-pub-3940256099942544/2934735716',
        'admob_interstitial_id_android':
            dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID'] ??
            'ca-app-pub-3940256099942544/1033173712',
        'admob_interstitial_id_ios':
            dotenv.env['ADMOB_INTERSTITIAL_ID_IOS'] ??
            'ca-app-pub-3940256099942544/4411468910',
        'mock_mode': true,
        'enable_upi_payments': true,
        'sync_images_to_cloud': false,
        'price_weekly': dotenv.env['PRICE_WEEKLY'] ?? '₹29',
        'price_monthly': dotenv.env['PRICE_MONTHLY'] ?? '₹99',
        'price_annual': dotenv.env['PRICE_ANNUAL'] ?? '₹499',
        'show_single_price': false,
        'phonepe_merchant_id':
            dotenv.env['PHONEPE_MERCHANT_ID'] ?? 'PGTESTPAYUAT',
        'phonepe_salt_key':
            dotenv.env['PHONEPE_SALT_KEY'] ??
            '099eb0cd-02cf-4e2a-8aca-3e6c6aff0399',
        'phonepe_salt_index': dotenv.env['PHONEPE_SALT_INDEX'] ?? '1',
        'phonepe_app_id': dotenv.env['PHONEPE_APP_ID'] ?? '',
        'phonepe_environment': dotenv.env['PHONEPE_ENVIRONMENT'] ?? 'SANDBOX',
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(days: 1),
        ),
      );

      await _remoteConfig.fetchAndActivate();

      // Listen to real-time updates safely across threads
      _remoteConfig.onConfigUpdated.listen((event) async {
        try {
          await _remoteConfig.activate();
          configUpdateNotifier.value++;
          debugPrint("Remote Config Updated: ${event.updatedKeys}");
        } catch (e) {
          debugPrint("Error activating updated remote config: $e");
        }
      });
    } catch (e) {
      debugPrint("Remote Config Init Error: $e");
    }
  }

  static String get geminiApiKey => _remoteConfig.getString('gemini_api_key');
  static String get geminiModel => _remoteConfig.getString('gemini_model');

  static String get youtubeApiKey => _remoteConfig.getString('youtube_api_key');

  static String get admobBannerIdAndroid =>
      _remoteConfig.getString('admob_banner_id_android');
  static String get admobBannerIdIos =>
      _remoteConfig.getString('admob_banner_id_ios');

  static String get admobInterstitialIdAndroid =>
      _remoteConfig.getString('admob_interstitial_id_android');
  static String get admobInterstitialIdIos =>
      _remoteConfig.getString('admob_interstitial_id_ios');

  static bool get mockMode => _remoteConfig.getBool('mock_mode');
  static bool get enableUpiPayments =>
      _remoteConfig.getBool('enable_upi_payments');
  static bool get syncImagesToCloud =>
      _remoteConfig.getBool('sync_images_to_cloud');

  static String get priceWeekly => _remoteConfig.getString('price_weekly');
  static String get priceMonthly => _remoteConfig.getString('price_monthly');
  static String get priceAnnual => _remoteConfig.getString('price_annual');
  static bool get showSinglePrice => _remoteConfig.getBool('show_single_price');

  static String get phonepeMerchantId =>
      _remoteConfig.getString('phonepe_merchant_id');
  static String get phonepeSaltKey =>
      _remoteConfig.getString('phonepe_salt_key');
  static String get phonepeSaltIndex =>
      _remoteConfig.getString('phonepe_salt_index');
  static String get phonepeAppId => _remoteConfig.getString('phonepe_app_id');
  static String get phonepeEnvironment =>
      _remoteConfig.getString('phonepe_environment');
}
