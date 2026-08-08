import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  // Global update notifier for simple usages if any
  static final ValueNotifier<int> configUpdateNotifier = ValueNotifier<int>(0);

  // Individual ValueNotifiers for granular UI rebuilding
  static final ValueNotifier<String> geminiApiKey = ValueNotifier('');
  static final ValueNotifier<String> geminiModel = ValueNotifier(
    'gemini-3.6-flash',
  );
  static final ValueNotifier<String> youtubeApiKey = ValueNotifier('');
  static final ValueNotifier<String> admobBannerIdAndroid = ValueNotifier(
    'ca-app-pub-3940256099942544/6300978111',
  );
  static final ValueNotifier<String> admobBannerIdIos = ValueNotifier(
    'ca-app-pub-3940256099942544/2934735716',
  );
  static final ValueNotifier<String> admobInterstitialIdAndroid = ValueNotifier(
    'ca-app-pub-3940256099942544/1033173712',
  );
  static final ValueNotifier<String> admobInterstitialIdIos = ValueNotifier(
    'ca-app-pub-3940256099942544/4411468910',
  );
  static final ValueNotifier<String> admobRewardedInterstitialIdAndroid = ValueNotifier(
    'ca-app-pub-3940256099942544/5354046379',
  );
  static final ValueNotifier<String> admobRewardedInterstitialIdIos = ValueNotifier(
    'ca-app-pub-3940256099942544/6978759866',
  );
  static final ValueNotifier<bool> mockMode = ValueNotifier(true);
  static final ValueNotifier<bool> enablePayment = ValueNotifier(true);
  static final ValueNotifier<bool> enableVendorPayment = ValueNotifier(true);
  static final ValueNotifier<bool> syncImagesToCloud = ValueNotifier(false);
  static final ValueNotifier<String> priceWeekly = ValueNotifier('₹29');
  static final ValueNotifier<String> priceMonthly = ValueNotifier('₹99');
  static final ValueNotifier<String> priceAnnual = ValueNotifier('₹499');
  static final ValueNotifier<bool> showSinglePrice = ValueNotifier(false);
  static final ValueNotifier<String> razorpayKeyId = ValueNotifier(
    'rzp_test_your_key_here',
  );
  static final ValueNotifier<String> razorpayLogoUrl = ValueNotifier('');
  static final ValueNotifier<String> revenuecatApiKey = ValueNotifier(
    'test_oGuQAGauVpzvALdhGXEXePuPFRy',
  );
  static final ValueNotifier<int> fetchIntervalSeconds = ValueNotifier(
    3600,
  ); // 1 hour

  static Future<void> initialize() async {
    try {
      // Set defaults based on .env where applicable
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
        'admob_rewarded_interstitial_id_android':
            dotenv.env['ADMOB_REWARDED_INTERSTITIAL_ID_ANDROID'] ??
            'ca-app-pub-3940256099942544/5354046379',
        'admob_rewarded_interstitial_id_ios':
            dotenv.env['ADMOB_REWARDED_INTERSTITIAL_ID_IOS'] ??
            'ca-app-pub-3940256099942544/6978759866',
        'mock_mode': true,
        'enable_payment': true,
        'enable_vendor_payment': true,
        'sync_images_to_cloud': false,
        'price_weekly': dotenv.env['PRICE_WEEKLY'] ?? '₹29',
        'price_monthly': dotenv.env['PRICE_MONTHLY'] ?? '₹99',
        'price_annual': dotenv.env['PRICE_ANNUAL'] ?? '₹499',
        'show_single_price': false,
        'razorpay_key_id':
            dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_your_key_here',
        'razorpay_logo_url': dotenv.env['RAZORPAY_LOGO_URL'] ?? '',
        'revenuecat_api_key': dotenv.env['REVENUECAT_API_KEY'] ?? 'test_oGuQAGauVpzvALdhGXEXePuPFRy',
        'fetch_interval_seconds': 3600,
      });

      // Initial local state update before fetch to pick up .env defaults
      _updateNotifiers();

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration(seconds: fetchIntervalSeconds.value),
        ),
      );

      await _remoteConfig.fetchAndActivate();
      _updateNotifiers();

      // Listen to real-time updates safely across threads
      _remoteConfig.onConfigUpdated.listen((event) async {
        try {
          await _remoteConfig.activate();
          _updateNotifiers();

          // Re-apply interval settings if it changed
          if (event.updatedKeys.contains('fetch_interval_seconds')) {
            await _remoteConfig.setConfigSettings(
              RemoteConfigSettings(
                fetchTimeout: const Duration(minutes: 1),
                minimumFetchInterval: Duration(
                  seconds: fetchIntervalSeconds.value,
                ),
              ),
            );
          }

          debugPrint("Remote Config Updated: ${event.updatedKeys}");
        } catch (e) {
          debugPrint("Error activating updated remote config: $e");
        }
      });
      
      // Add a lifecycle observer to fetch config immediately when user switches back to the app
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
      
    } catch (e) {
      debugPrint("Remote Config Init Error: $e");
    }
  }

  static Future<void> forceFetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _updateNotifiers();
    } catch (e) {
      debugPrint("Force fetch error: $e");
    }
  }

  static void _updateNotifiers() {
    geminiApiKey.value = _remoteConfig.getString('gemini_api_key');
    geminiModel.value = _remoteConfig.getString('gemini_model');
    youtubeApiKey.value = _remoteConfig.getString('youtube_api_key');
    admobBannerIdAndroid.value = _remoteConfig.getString(
      'admob_banner_id_android',
    );
    admobBannerIdIos.value = _remoteConfig.getString('admob_banner_id_ios');
    admobInterstitialIdAndroid.value = _remoteConfig.getString(
      'admob_interstitial_id_android',
    );
    admobInterstitialIdIos.value = _remoteConfig.getString(
      'admob_interstitial_id_ios',
    );
    admobRewardedInterstitialIdAndroid.value = _remoteConfig.getString(
      'admob_rewarded_interstitial_id_android',
    );
    admobRewardedInterstitialIdIos.value = _remoteConfig.getString(
      'admob_rewarded_interstitial_id_ios',
    );
    mockMode.value = _remoteConfig.getBool('mock_mode');
    enablePayment.value = _remoteConfig.getBool('enable_payment');
    enableVendorPayment.value = _remoteConfig.getBool('enable_vendor_payment');
    syncImagesToCloud.value = _remoteConfig.getBool('sync_images_to_cloud');
    priceWeekly.value = _remoteConfig.getString('price_weekly');
    priceMonthly.value = _remoteConfig.getString('price_monthly');
    priceAnnual.value = _remoteConfig.getString('price_annual');
    showSinglePrice.value = _remoteConfig.getBool('show_single_price');
    razorpayKeyId.value = _remoteConfig.getString('razorpay_key_id');
    razorpayLogoUrl.value = _remoteConfig.getString('razorpay_logo_url');
    revenuecatApiKey.value = _remoteConfig.getString('revenuecat_api_key');
    
    // fetch_interval_seconds could be int, so getInt
    fetchIntervalSeconds.value = _remoteConfig.getInt('fetch_interval_seconds');
    if (fetchIntervalSeconds.value <= 0) fetchIntervalSeconds.value = 3600;

    configUpdateNotifier.value++;
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Whenever the user switches back to the app from Firebase Console, force a fresh fetch
      RemoteConfigService.forceFetch();
    }
  }
}
