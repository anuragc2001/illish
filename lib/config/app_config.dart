import 'package:flutter/foundation.dart';
import '../services/remote_config_service.dart';

class AppConfig {
  // When true, the app runs entirely offline with mocked data and skips all external API calls.
  static bool get kMockMode => RemoteConfigService.mockMode;

  static const String kProviderGemini = 'gemini';

  static String documentsPath = '';

  // Feature flag to quickly enable/disable the UPI payment trigger UI
  static bool get kEnableUpiPayments => RemoteConfigService.enableUpiPayments;

  // Whether the user has premium access (fetched remotely)
  static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);

  static bool get isPremiumUser => isPremiumNotifier.value;
  static set isPremiumUser(bool value) {
    if (isPremiumNotifier.value != value) {
      isPremiumNotifier.value = value;
    }
  }

  // Whether images should be uploaded to Firebase Storage
  // Useful for reducing storage costs or when Storage is not yet configured.
  static bool get kSyncImagesToCloud => RemoteConfigService.syncImagesToCloud;
}
