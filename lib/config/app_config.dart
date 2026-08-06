import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/remote_config_service.dart';

class AppConfig {
  // When true, the app runs entirely offline with mocked data and skips all external API calls.
  static bool get kMockMode => RemoteConfigService.mockMode.value;

  static const String kProviderGemini = 'gemini';

  static String documentsPath = '';

  // Feature flag to quickly enable/disable the premium upgrade/payment UI
  static bool get kEnablePayment => RemoteConfigService.enablePayment.value;
  
  // Feature flag for the third-party vendor UPI intent inside results screen
  static bool get kEnableVendorPayment => RemoteConfigService.enableVendorPayment.value;

  // Whether the user has premium access (fetched remotely)
  static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);
  
  // Premium Plan and Expiration details
  static final ValueNotifier<String> premiumPlanNotifier = ValueNotifier<String>('');
  static final ValueNotifier<DateTime?> premiumExpiryNotifier = ValueNotifier<DateTime?>(null);

  static bool get isPremiumUser => isPremiumNotifier.value;
  static set isPremiumUser(bool value) {
    if (isPremiumNotifier.value != value) {
      isPremiumNotifier.value = value;
    }
  }

  /// Initialize offline state from SharedPreferences
  static Future<void> initOfflinePremiumState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final bool savedPremium = prefs.getBool('isPremium') ?? false;
    final String savedPlan = prefs.getString('premiumPlan') ?? '';
    final String? savedExpiryStr = prefs.getString('premiumExpiry');
    
    DateTime? savedExpiry;
    if (savedExpiryStr != null) {
      savedExpiry = DateTime.tryParse(savedExpiryStr);
    }

    if (savedPremium && savedExpiry != null) {
      if (savedExpiry.isAfter(DateTime.now())) {
        // Still valid
        isPremiumNotifier.value = true;
        premiumPlanNotifier.value = savedPlan;
        premiumExpiryNotifier.value = savedExpiry;
      } else {
        // Expired offline!
        isPremiumNotifier.value = false;
        prefs.setBool('isPremium', false); // downgrade local cache
      }
    } else {
      isPremiumNotifier.value = savedPremium;
    }
  }

  // Whether images should be uploaded to Firebase Storage
  // Useful for reducing storage costs or when Storage is not yet configured.
  static bool get kSyncImagesToCloud => RemoteConfigService.syncImagesToCloud.value;
}
