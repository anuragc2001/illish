import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:async/async.dart';
import '../config/app_config.dart';
import 'ai/ai_provider.dart';
import 'ai/hugging_face_provider.dart';
import 'ai/gemini_provider.dart';

class AIService {
  late final AIProvider _provider;

  AIService() {
    final preferredProvider = dotenv.env['AI_PROVIDER']?.toLowerCase();
    
    final huggingFaceApiKey = dotenv.env['HUGGINGFACE_API_KEY'];
    final hasValidHuggingFaceKey = huggingFaceApiKey != null &&
        huggingFaceApiKey.isNotEmpty &&
        huggingFaceApiKey != 'YOUR_HUGGINGFACE_API_KEY_HERE';

    if (preferredProvider == AppConfig.kProviderHuggingFace && hasValidHuggingFaceKey) {
      _provider = HuggingFaceProvider();
    } else {
      // Fallback to Gemini if huggingface is preferred but the key is missing/invalid, 
      // or if gemini is explicitly preferred in the .env file.
      _provider = GeminiProvider();
    }
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
      return {
        'englishName': 'Rohu',
        'localName': 'Rui (রুই)',
        'freshnessScore': 0.98,
        'freshnessStatus': 'Green / 98% Fresh',
        'freshnessEvidence':
            'Clear eyes • bright red gills • Caught within 24 hours',
        'bestCuts': ['Peti', 'Gada'],
        'idealFor': ['Authentic Bengali Shorshe Rui'],
        'vendorAlert': 'Vendor alert: weigh before adding ice',
        'isOffline': true,
      };
    }

    final connectivityResult = await (Connectivity().checkConnectivity());

    // OFFLINE MODE - fallback to error
    if (connectivityResult == ConnectivityResult.none) {
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
      };
    }
  }
}
