import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

class AdMobService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;
  static int _resultsBackClickCount = 0;

  // Test Ad Unit IDs (Use real ones in production)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android Test Interstitial ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test Interstitial ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    if (AppConfig.kIsPremiumUser) return; // Don't initialize for premium users
    
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  static void _loadInterstitialAd() {
    if (AppConfig.kIsPremiumUser || _interstitialAd != null || _isInterstitialAdLoading) return;
    
    _isInterstitialAdLoading = true;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows the interstitial ad if ready.
  /// Executes `onAdDismissed` when the user closes the ad, or immediately if the ad fails/isn't ready.
  static void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (AppConfig.kIsPremiumUser) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      onAdDismissed();
      _loadInterstitialAd(); // Try loading again for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Ad showed fullscreen content.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Ad dismissed fullscreen content.');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Pre-load next one
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show fullscreen content: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdDismissed();
      },
    );

    _interstitialAd!.show();
  }

  /// Helper specifically for the Results Screen back button (every 3rd click)
  static void handleResultsBackButton({required VoidCallback onProceed}) {
    if (AppConfig.kIsPremiumUser) {
      onProceed();
      return;
    }

    _resultsBackClickCount++;
    if (_resultsBackClickCount % 3 == 0) {
      showInterstitialAd(onAdDismissed: onProceed);
    } else {
      onProceed();
    }
  }
}
