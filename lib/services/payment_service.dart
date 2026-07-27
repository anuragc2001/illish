import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/upi_app.dart';

class PaymentService {
  static const MethodChannel _channel = MethodChannel('com.anuragchak.illish/upi');

  static final List<UpiApp> _iosSupportedApps = [
    UpiApp(name: 'Google Pay', packageName: 'gpay', assetIcon: 'assets/icons/upi/gpay.png'),
    UpiApp(name: 'PhonePe', packageName: 'phonepe', assetIcon: 'assets/icons/upi/phonepe.png'),
    UpiApp(name: 'Paytm', packageName: 'paytm', assetIcon: 'assets/icons/upi/paytm.png'),
    UpiApp(name: 'CRED', packageName: 'credpay', assetIcon: 'assets/icons/upi/cred.png'),
    UpiApp(name: 'BHIM', packageName: 'bhim', assetIcon: 'assets/icons/upi/bhim.png'),
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
        // Check if we can launch the app's base scheme
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
      // For iOS, just launch the scheme to open the app (e.g. gpay://)
      final Uri appUri = Uri(scheme: app.packageName, host: 'pay');
      
      try {
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
        } else {
            // fallback if host is not needed
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
}
