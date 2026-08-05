import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import '../core/models/upi_app.dart';
import 'db_service.dart';
import '../config/app_config.dart';
import 'remote_config_service.dart';

class PaymentService {
  static const MethodChannel _channel = MethodChannel('com.anuragchak.illish/upi');

  static final List<UpiApp> _iosSupportedApps = [
    UpiApp(name: 'Google Pay', packageName: 'gpay', assetIcon: 'assets/icons/upi/gpay.png'),
    UpiApp(name: 'PhonePe', packageName: 'phonepe', assetIcon: 'assets/icons/upi/phonepe.jpeg'),
    UpiApp(name: 'Paytm', packageName: 'paytm', assetIcon: 'assets/icons/upi/paytm.png'),
    UpiApp(name: 'Amazon Pay', packageName: 'amazonpay', assetIcon: 'assets/icons/upi/amazonpay.png'),
    UpiApp(name: 'CRED', packageName: 'credpay', assetIcon: 'assets/icons/upi/cred.jpeg'),
    UpiApp(name: 'BHIM', packageName: 'bhim', assetIcon: 'assets/icons/upi/bhim.jpg'),
  ];

  static Future<List<UpiApp>> getAvailableUpiApps() async {
    List<UpiApp> apps = [];
    if (Platform.isAndroid) {
      try {
        final List<dynamic>? result = await _channel.invokeMethod('getInstalledUpiApps');
        if (result != null) {
          for (var item in result) {
            apps.add(UpiApp.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      } catch (e) {
        print("Error getting Android UPI apps: $e");
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
        print("Error launching Android UPI app: $e");
      }
    } else if (Platform.isIOS) {
      final Uri appUri = Uri(scheme: app.packageName);
      try {
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
        } else {
            final Uri baseUri = Uri(scheme: app.packageName);
            if (await canLaunchUrl(baseUri)) {
                await launchUrl(baseUri, mode: LaunchMode.externalApplication);
            }
        }
      } catch (e) {
        print("Error launching iOS UPI app: $e");
      }
    }
  }

  // PHONEPE SDK INTEGRATION
  static const String callbackUrl = "https://webhook.site/callback-url"; // Example callback

  static Future<void> initPhonePe() async {
    try {
      bool isInitialized = await PhonePePaymentSdk.init(
        RemoteConfigService.phonepeEnvironment,
        RemoteConfigService.phonepeMerchantId,
        RemoteConfigService.phonepeAppId.isEmpty ? 'transaction_flow' : RemoteConfigService.phonepeAppId,
        true
      );
      print("PhonePe SDK Init: $isInitialized");
    } catch (e) {
      print("Error initializing PhonePe: $e");
    }
  }


  static Future<bool> startPhonePeCheckout({required String planId, required double amount}) async {
    try {
      String transactionId = "TXN_${DateTime.now().millisecondsSinceEpoch}";
      
      Map<String, dynamic> requestBody = {
        "merchantId": RemoteConfigService.phonepeMerchantId,
        "merchantTransactionId": transactionId,
        "merchantUserId": "USER_${DateTime.now().millisecondsSinceEpoch}",
        "amount": (amount * 100).toInt(), // PhonePe expects amount in paise
        "redirectUrl": callbackUrl,
        "redirectMode": "REDIRECT",
        "callbackUrl": callbackUrl,
        "mobileNumber": "9999999999",
        "paymentInstrument": {
          "type": "PAY_PAGE"
        }
      };

      String base64Body = base64Encode(utf8.encode(jsonEncode(requestBody)));
      String checksum = sha256.convert(utf8.encode(base64Body + "/pg/v1/pay" + RemoteConfigService.phonepeSaltKey)).toString() + "###" + RemoteConfigService.phonepeSaltIndex;

      String requestJson = jsonEncode({
        "merchantId": RemoteConfigService.phonepeMerchantId,
        "orderId": transactionId,
        "token": base64Body,
        "checksum": checksum,
        "paymentMode": "PAY_PAGE",
      });

      var response = await PhonePePaymentSdk.startTransaction(requestJson, callbackUrl)
          .timeout(const Duration(seconds: 60), onTimeout: () {
        print("PhonePe transaction call timed out or was dismissed");
        return null;
      });
      
      if (response != null && response is Map) {
        String status = (response['status'] ?? response['error'] ?? '').toString().toUpperCase();
        print("PhonePe Checkout response status: $status, full payload: $response");
        if (status == 'SUCCESS') {
          // Grant Premium Access
          AppConfig.isPremiumUser = true;
          AppConfig.isPremiumNotifier.value = true;
          // Permanently unlock all previous scans
          await DBService.unlockAllScans();
          return true;
        }
      }
      return false;
    } catch (e, stack) {
      print("PhonePe Checkout Exception/Cancellation: $e\n$stack");
      return false;
    }
  }
}
