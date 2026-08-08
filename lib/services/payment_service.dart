import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/upi_app.dart';
import 'db_service.dart';
import 'sync_service.dart';
import '../config/app_config.dart';
import 'remote_config_service.dart';

class PaymentService {
  static const MethodChannel _channel = MethodChannel(
    'com.anuragchak.illish/upi',
  );

  static final List<UpiApp> _iosSupportedApps = [
    UpiApp(
      name: 'Google Pay',
      packageName: 'gpay',
      assetIcon: 'assets/icons/upi/gpay.png',
    ),
    UpiApp(
      name: 'PhonePe',
      packageName: 'phonepe',
      assetIcon: 'assets/icons/upi/phonepe.jpeg',
    ),
    UpiApp(
      name: 'Paytm',
      packageName: 'paytm',
      assetIcon: 'assets/icons/upi/paytm.png',
    ),
    UpiApp(
      name: 'Amazon Pay',
      packageName: 'amazonpay',
      assetIcon: 'assets/icons/upi/amazonpay.png',
    ),
    UpiApp(
      name: 'CRED',
      packageName: 'credpay',
      assetIcon: 'assets/icons/upi/cred.jpeg',
    ),
    UpiApp(
      name: 'BHIM',
      packageName: 'bhim',
      assetIcon: 'assets/icons/upi/bhim.jpg',
    ),
  ];

  static Future<List<UpiApp>> getAvailableUpiApps() async {
    List<UpiApp> apps = [];
    if (Platform.isAndroid) {
      try {
        final List<dynamic>? result = await _channel.invokeMethod(
          'getInstalledUpiApps',
        );
        if (result != null) {
          for (var item in result) {
            apps.add(UpiApp.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      } catch (e) {
        debugPrint("Error getting Android UPI apps: $e");
      }
    } else if (Platform.isIOS) {
      for (var app in _iosSupportedApps) {
        final Uri schemeUri = Uri(scheme: app.packageName);
        if (await canLaunchUrl(schemeUri)) {
          apps.add(app);
        }
      }
    }
    return apps;
  }

  static Future<void> launchAppOnly({required UpiApp app}) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('launchUpiApp', {
          'packageName': app.packageName,
        });
      } catch (e) {
        debugPrint("Error launching Android UPI app: $e");
      }
    } else if (Platform.isIOS) {
      final Uri appUri = Uri(scheme: app.packageName);
      try {
        if (await canLaunchUrl(appUri)) {
          await launchUrl(
            appUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } else {
          final Uri baseUri = Uri(scheme: app.packageName);
          if (await canLaunchUrl(baseUri)) {
            await launchUrl(
              baseUri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          }
        }
      } catch (e) {
        debugPrint("Error launching iOS UPI app: $e");
      }
    }
  }

  // RAZORPAY SDK INTEGRATION
  static Razorpay? _razorpay;
  static Completer<bool>? _paymentCompleter;
  static String _currentPlanId = '';

  static Future<bool> startRazorpayCheckout({
    required String planId,
    required double amount,
  }) async {
    _paymentCompleter = Completer<bool>();
    _currentPlanId = planId;

    _razorpay?.clear();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final keyId = RemoteConfigService.razorpayKeyId.value.trim();
    final logoUrl = RemoteConfigService.razorpayLogoUrl.value.trim();

    var options = {
      'key': keyId.isNotEmpty ? keyId : 'rzp_test_your_key_here',
      'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
      'name': 'Illish Pro',
      'description': 'AI Freshness Scanner Premium',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      if (logoUrl.isNotEmpty) 'image': logoUrl,
      'prefill': {'contact': '9876543210', 'email': 'customer@example.com'},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint("Error launching Razorpay: $e");
      if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
        _paymentCompleter!.complete(false);
      }
      return false;
    }

    return _paymentCompleter!.future;
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("Razorpay Success: ${response.paymentId}");
    // Grant Premium Access
    AppConfig.isPremiumUser = true;
    AppConfig.isPremiumNotifier.value = true;
    // Update Firestore via SyncService
    await SyncService.upgradeUserToPremium(_currentPlanId);
    // Permanently unlock all previous scans
    await DBService.unlockAllScans();

    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(true);
    }
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Razorpay Error: ${response.code} - ${response.message}");
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(false);
    }
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("Razorpay External Wallet: ${response.walletName}");
  }

  // --- REVENUECAT (NATIVE BILLING) IMPLEMENTATION ---
  static bool _isRevenueCatInitialized = false;

  /// Initialize RevenueCat with placeholder API keys until production keys are ready.
  static Future<void> initRevenueCat() async {
    try {
      final String apiKey = RemoteConfigService.revenuecatApiKey.value;

      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      _isRevenueCatInitialized = true;
      debugPrint(
        "✅ [REVENUECAT INIT SUCCESS] Configured with API key: ${apiKey.isNotEmpty ? apiKey.substring(0, 8) : ''}...",
      );
    } catch (e) {
      debugPrint("❌ [REVENUECAT INIT ERROR] Failed to initialize: $e");
      _isRevenueCatInitialized = false;
    }
  }

  static String _mapPlanIdToProductId(String planId) {
    if (planId == 'weekly') return 'illish_weekly_29';
    if (planId == 'monthly') return 'illish_monthly_99';
    if (planId == 'annual') return 'illish_annual_499';
    return planId;
  }

  static Future<bool> startGooglePlayCheckout({
    required String planId,
    required double amount,
  }) async {
    final productId = _mapPlanIdToProductId(planId);
    debugPrint(
      "🛒 [REVENUECAT GOOGLE PLAY] Attempting purchase for plan: $planId (Product ID: $productId, Amount: ₹$amount)",
    );

    if (_isRevenueCatInitialized) {
      try {
        CustomerInfo customerInfo = await Purchases.purchaseProduct(productId);

        if (customerInfo.entitlements.all['premium']?.isActive == true) {
          debugPrint(
            "🎉 [REVENUECAT REAL PURCHASE SUCCESS] Product $productId purchased successfully via Google Play!",
          );
          // Grant Premium Access
          AppConfig.isPremiumUser = true;
          AppConfig.isPremiumNotifier.value = true;
          await SyncService.upgradeUserToPremium(planId);
          await DBService.unlockAllScans();
          return true;
        } else {
          debugPrint(
            "⚠️ [REVENUECAT PURCHASE INACTIVE] Purchase completed but 'premium' entitlement is not active. Check entitlement ID in RevenueCat dashboard.",
          );
        }
      } on PlatformException catch (e) {
        var errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint("ℹ️ [REVENUECAT] User cancelled Google Play purchase.");
          return false;
        } else {
          debugPrint(
            "❌ [REVENUECAT ERROR] Google Play purchase failed (Error Code ${e.code}): ${e.message}",
          );
        }
      } catch (e) {
        debugPrint("❌ [REVENUECAT EXCEPTION] $e");
      }
    } else {
      debugPrint("⚠️ [REVENUECAT] SDK not initialized.");
    }

    // MOCK FALLBACK for development/testing when products are unconfigured in Google Play Console
    if (kDebugMode || AppConfig.kMockMode) {
      debugPrint(
        "🧪 [REVENUECAT MOCK FALLBACK] Store product unconfigured or dev mode active. Simulating successful test checkout...",
      );
      await Future.delayed(const Duration(seconds: 1));
      AppConfig.isPremiumUser = true;
      AppConfig.isPremiumNotifier.value = true;
      await SyncService.upgradeUserToPremium(planId);
      await DBService.unlockAllScans();
      return true;
    }

    return false;
  }

  /// Attempts a real Apple App Store In-App Purchase via RevenueCat, falling back to mock UI if unconfigured.
  static Future<bool> startAppleAppStoreCheckout({
    required String planId,
    required double amount,
  }) async {
    final productId = _mapPlanIdToProductId(planId);
    debugPrint(
      "🛒 [REVENUECAT APP STORE] Attempting purchase for plan: $planId (Product ID: $productId, Amount: ₹$amount)",
    );

    if (_isRevenueCatInitialized) {
      try {
        CustomerInfo customerInfo = await Purchases.purchaseProduct(productId);

        if (customerInfo.entitlements.all['premium']?.isActive == true) {
          debugPrint(
            "🎉 [REVENUECAT REAL PURCHASE SUCCESS] Product $productId purchased successfully via Apple App Store!",
          );
          // Grant Premium Access
          AppConfig.isPremiumUser = true;
          AppConfig.isPremiumNotifier.value = true;
          await SyncService.upgradeUserToPremium(planId);
          await DBService.unlockAllScans();
          return true;
        } else {
          debugPrint(
            "⚠️ [REVENUECAT PURCHASE INACTIVE] Purchase completed but 'premium' entitlement is not active. Check entitlement ID in RevenueCat dashboard.",
          );
        }
      } on PlatformException catch (e) {
        var errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint("ℹ️ [REVENUECAT] User cancelled App Store purchase.");
          return false;
        } else {
          debugPrint(
            "❌ [REVENUECAT ERROR] App Store purchase failed (Error Code ${e.code}): ${e.message}",
          );
        }
      } catch (e) {
        debugPrint("❌ [REVENUECAT EXCEPTION] $e");
      }
    } else {
      debugPrint("⚠️ [REVENUECAT] SDK not initialized.");
    }

    // MOCK FALLBACK for development/testing when products are unconfigured in App Store Connect
    if (kDebugMode || AppConfig.kMockMode) {
      debugPrint(
        "🧪 [REVENUECAT MOCK FALLBACK] Store product unconfigured or dev mode active. Simulating successful test checkout...",
      );
      await Future.delayed(const Duration(seconds: 1));
      AppConfig.isPremiumUser = true;
      AppConfig.isPremiumNotifier.value = true;
      await SyncService.upgradeUserToPremium(planId);
      await DBService.unlockAllScans();
      return true;
    }

    return false;
  }

  /// Launch native subscription management center URL
  static Future<void> launchSubscriptionManagement() async {
    final String url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch subscription management URL");
    }
  }

  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
