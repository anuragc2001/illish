import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'remote_config_service.dart';

class AdMobService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static RewardedInterstitialAd? _rewardedInterstitialAd;
  static bool _isRewardedInterstitialAdLoading = false;

  static int _resultsBackClickCount = 0;

  // Fetch Ad Unit IDs from Remote Config
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      final id = RemoteConfigService.admobBannerIdAndroid.value;
      return id.isNotEmpty ? id : 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      final id = RemoteConfigService.admobBannerIdIos.value;
      return id.isNotEmpty ? id : 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      final id = RemoteConfigService.admobInterstitialIdAndroid.value;
      return id.isNotEmpty ? id : 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      final id = RemoteConfigService.admobInterstitialIdIos.value;
      return id.isNotEmpty ? id : 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      final id = RemoteConfigService.admobRewardedInterstitialIdAndroid.value;
      return id.isNotEmpty ? id : 'ca-app-pub-3940256099942544/5354046379';
    } else if (Platform.isIOS) {
      final id = RemoteConfigService.admobRewardedInterstitialIdIos.value;
      return id.isNotEmpty ? id : 'ca-app-pub-3940256099942544/6978759866';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    if (AppConfig.isPremiumUser) return; // Don't initialize for premium users
    
    final prefs = await SharedPreferences.getInstance();
    _resultsBackClickCount = prefs.getInt('adClickCount') ?? 0;

    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedInterstitialAd();
  }

  static void _loadInterstitialAd() {
    if (AppConfig.isPremiumUser || _interstitialAd != null || _isInterstitialAdLoading) return;
    
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

  static void _loadRewardedInterstitialAd() {
    if (AppConfig.isPremiumUser || _rewardedInterstitialAd != null || _isRewardedInterstitialAdLoading) return;

    _isRewardedInterstitialAdLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdLoading = false;
          debugPrint('RewardedInterstitialAd loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isRewardedInterstitialAdLoading = false;
          debugPrint('RewardedInterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows the interstitial ad if ready.
  /// Executes `onAdDismissed` when the user closes the ad, or immediately if the ad fails/isn't ready.
  static void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (AppConfig.isPremiumUser) {
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
    _interstitialAd!.setImmersiveMode(true);
    _interstitialAd!.show();
  }

  static void handleResultsBackButton({required VoidCallback onProceed}) async {
    if (AppConfig.isPremiumUser) {
      onProceed();
      return;
    }

    _resultsBackClickCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('adClickCount', _resultsBackClickCount);

    if (_resultsBackClickCount % 3 == 0) {
      showInterstitialAd(onAdDismissed: onProceed);
    } else {
      onProceed();
    }
  }

  /// Shows the rewarded interstitial ad if ready.
  /// Executes `onRewardEarned` if the user watches the ad.
  /// Executes `onAdDismissedWithoutReward` if they skip, close early, or if ad fails/is loading.
  static Future<void> showRewardedInterstitialAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdDismissedWithoutReward,
  }) async {
    if (AppConfig.isPremiumUser) {
      onRewardEarned();
      return;
    }

    if (_rewardedInterstitialAd == null) {
      debugPrint('Rewarded Interstitial Ad not ready yet. Attempting load/wait...');
      _loadRewardedInterstitialAd();
      
      // Wait up to 3 seconds for ad to finish loading
      int waitedMs = 0;
      while (_rewardedInterstitialAd == null && _isRewardedInterstitialAdLoading && waitedMs < 3000) {
        await Future.delayed(const Duration(milliseconds: 250));
        waitedMs += 250;
      }
    }

    if (_rewardedInterstitialAd == null) {
      debugPrint('Rewarded Interstitial Ad still not ready. Denying access without reward.');
      onAdDismissedWithoutReward();
      return;
    }

    bool earnedReward = false;

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Rewarded Ad showed fullscreen content.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded Ad dismissed fullscreen content. Earned reward: $earnedReward');
        ad.dispose();
        _rewardedInterstitialAd = null;
        _loadRewardedInterstitialAd(); // Pre-load next one
        
        if (earnedReward) {
          onRewardEarned();
        } else {
          onAdDismissedWithoutReward();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded Ad failed to show fullscreen content: $error');
        ad.dispose();
        _rewardedInterstitialAd = null;
        _loadRewardedInterstitialAd();
        onAdDismissedWithoutReward(); // Strict: Do NOT grant reward if ad failed to show
      },
    );

    _rewardedInterstitialAd!.setImmersiveMode(true);
    
    _rewardedInterstitialAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
      debugPrint('User earned reward: ${rewardItem.amount} ${rewardItem.type}');
      earnedReward = true;
    });
  }
}
