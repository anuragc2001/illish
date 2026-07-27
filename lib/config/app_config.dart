class AppConfig {
  // When true, the app runs entirely offline with mocked data and skips all external API calls.
  static const bool kMockMode = true;

  static const String kProviderGemini = 'gemini';

  static String documentsPath = '';

  // Feature flag to quickly enable/disable the UPI payment trigger UI
  static const bool kEnableUpiPayments = true;
}
