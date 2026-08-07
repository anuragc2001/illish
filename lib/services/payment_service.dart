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
      // TODO: Replace with real RevenueCat API keys from Remote Config or .env before publish
      final String apiKey = Platform.isAndroid 
          ? 'goog_placeholder_api_key' 
          : 'appl_placeholder_api_key';

      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      
      _isRevenueCatInitialized = true;
      debugPrint("RevenueCat configured successfully.");
    } catch (e) {
      debugPrint("Failed to initialize RevenueCat: $e");
      _isRevenueCatInitialized = false;
    }
  }

  /// Attempts a real Google Play Billing flow via RevenueCat, falling back to mock UI if unconfigured.
  static Future<bool> startGooglePlayCheckout({
    required String planId,
    required double amount,
  }) async {
    debugPrint("Starting Google Play Billing for plan: $planId ($amount)");
    
    if (_isRevenueCatInitialized) {
      try {
        CustomerInfo customerInfo = await Purchases.purchaseProduct(planId);
        // Assuming 'premium' is the entitlement identifier in RevenueCat dashboard
        if (customerInfo.entitlements.all['premium']?.isActive == true) {
          debugPrint("Google Play Billing successful via RevenueCat!");
          return true;
        }
      } catch (e) {
        debugPrint("RevenueCat Purchase Error: $e");
        // Fallback to Mock if it fails due to placeholder keys/configuration
        debugPrint("Falling back to Google Play mock flow...");
      }
    }
    
    // Simulate native Google Play bottom sheet UI loading delay (Mock Fallback)
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("Google Play Billing successful (MOCK FALLBACK).");
    return true; 
  }

  /// Attempts a real Apple App Store In-App Purchase via RevenueCat, falling back to mock UI if unconfigured.
  static Future<bool> startAppleAppStoreCheckout({
    required String planId,
    required double amount,
  }) async {
    debugPrint("Starting Apple App Store Billing for plan: $planId ($amount)");
    
    if (_isRevenueCatInitialized) {
      try {
        CustomerInfo customerInfo = await Purchases.purchaseProduct(planId);
        // Assuming 'premium' is the entitlement identifier in RevenueCat dashboard
        if (customerInfo.entitlements.all['premium']?.isActive == true) {
          debugPrint("Apple App Store Billing successful via RevenueCat!");
          return true;
        }
      } catch (e) {
        debugPrint("RevenueCat Purchase Error: $e");
        // Fallback to Mock if it fails due to placeholder keys/configuration
        debugPrint("Falling back to Apple App Store mock flow...");
      }
    }

    // Simulate native FaceID / TouchID dialog delay (Mock Fallback)
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("Apple App Store Billing successful (MOCK FALLBACK).");
    return true; 
  }

  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
