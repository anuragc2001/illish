import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:async/async.dart';
import '../config/app_config.dart';
import 'ai/ai_provider.dart';
import 'ai/gemini_provider.dart';

class AIService {
  late final AIProvider _provider;
  static int _mockCycle = 0;

  AIService() {
    _provider = GeminiProvider();
  }

  CancelableOperation<Map<String, dynamic>> analyzeFish(
    String imagePath,
    String location,
  ) {
    return CancelableOperation.fromFuture(
      _analyzeFishInternal(imagePath, location),
    );
  }

  Future<Map<String, dynamic>> _analyzeFishInternal(
    String imagePath,
    String location,
  ) async {
    if (AppConfig.kMockMode) {
      await Future.delayed(const Duration(seconds: 1)); // simulate latency
      
      _mockCycle++;
      double testScore;
      if (_mockCycle % 3 == 1) {
        testScore = 0.90; // Green (>75%)
      } else if (_mockCycle % 3 == 2) {
        testScore = 0.55; // Yellow (40-75%)
      } else {
        testScore = 0.20; // Red (<40%)
      }

      return {
        'englishName': 'Rohu',
        'localName': 'Rui (রুই)',
        'freshnessScore': testScore,
        'freshnessStatus': 'Mocked Status',
        'freshnessEvidence':
            'Clear eyes • bright red gills • Caught within 24 hours',
        'bestCuts': [
          'Peti (Belly)',
          'Gada (Back)',
          'Mura (Head)',
          'Laja (Tail)',
          'Peti-Gada (Belly and Back)',
        ],
        'idealFor': [
          'Authentic Bengali Shorshe Rui',
          'Rui Macher Kalia',
          'Macher Jhol (Light Stew)',
          'Rui Posto',
          'Doi Mach',
          'Macher Matha Diye Moong Dal',
          'Rui Macher Vaja',
        ],
        'trickeryTips': [
          'Vendor trickery: weigh before ice is added',
          'Press the flesh - it should bounce back immediately if fresh.',
          'Check the gills - Ensure they are bright red, not brown or grey.',
          'Smell test - It should smell like the ocean, not ammonia.',
          'Look at the eyes - Avoid fish with cloudy, sunken eyes.',
          'Beware of artificial coloring on the skin or gills.',
        ],
        'suggestedPrice': '300 - 320',
        'marketAvgPrice': '340',
        'priceExplanation': 'Calculated based on 90% freshness, early morning catch premium, and current wholesale rates in Kolkata.',
        'marketAvgExplanation': 'The market average price is compiled from regional crowdsourced reports and wholesale benchmark data from the past week.',
        'isOffline': true,
        'location': location,
      };
    }

    final connectivityResult = await (Connectivity().checkConnectivity());

    // OFFLINE MODE - fallback to error
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return {
        'error': true,
        'errorType': 'offline',
        'message': 'Seems you are offline',
        'isOffline': true,
      };
    }

    // ONLINE MODE - Use selected AI Provider
    try {
      final response = await _provider
          .analyzeFish(imagePath, location)
          .timeout(const Duration(seconds: 15));
      return response;
    } on TimeoutException catch (_) {
      return {
        'error': true,
        'errorType': 'low_network',
        'message': 'Network connection is too slow',
        'isOffline': false,
      };
    } on SocketException catch (_) {
      return {
        'error': true,
        'errorType': 'low_network',
        'message': 'Network connection is too slow',
        'isOffline': false,
      };
    } catch (e) {
      debugPrint('AI Provider Error: $e');
      return {
        'englishName': 'Unknown Fish',
        'localName': 'Unknown',
        'freshnessScore': 0.0,
        'freshnessStatus': 'Analysis Failed',
        'freshnessEvidence': 'API error occurred',
        'bestCuts': [],
        'idealFor': [],
        'isOffline': false,
        'error': true,
        'errorType': 'api_error',
      };
    }
  }
}
