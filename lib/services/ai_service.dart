import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:async/async.dart';
import '../config/app_config.dart';

class AIService {
  late final GenerativeModel? _cloudModel;

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _cloudModel = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);
    } else {
      _cloudModel = null;
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

    // OFFLINE MODE - fallback to mock/basic info for now (simulate TFLite)
    if (connectivityResult == ConnectivityResult.none || _cloudModel == null) {
      return {
        'englishName': 'Rohu (Offline Guess)',
        'localName': 'Unknown',
        'freshnessScore': 0.85,
        'freshnessStatus': 'Good (Requires Internet for deep check)',
        'freshnessEvidence': 'Basic offline scan',
        'bestCuts': ['Standard cut'],
        'idealFor': ['Curry'],
        'isOffline': true,
      };
    }

    // ONLINE MODE - Real Gemini API
    try {
      final imageBytes = await File(imagePath).readAsBytes();

      final prompt = TextPart('''
Analyze this image of a fish found in $location. Return a raw JSON object (no markdown, no backticks) with exactly this structure:
{
  "englishName": "Common english name",
  "localName": "Regional name based on $location (include native script if applicable)",
  "freshnessScore": 0.95, // float between 0.0 and 1.0 based on eye cloudiness, gill color, skin texture
  "freshnessStatus": "Green / 95% Fresh", // e.g., Green/Yellow/Red
  "freshnessEvidence": "Clear eyes • bright red gills", // bullet points separated by ' • '
  "bestCuts": ["List of 3 authentic local fishmonger cuts commonly used in $location markets (e.g. if in West Bengal, use real Bengali terms like 'Peti', 'Gada', etc. instead of generic 'steaks'). Format strictly as: LocalName (English translation)"],
  "idealFor": ["List of authentic local recipes based on $location. Format strictly as: LocalName (English translation)"]
}
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _cloudModel!.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final responseText = response.text ?? '{}';

      // Clean up markdown code blocks if gemini included them despite instructions
      final cleanJson = responseText
          .replaceAll(RegExp(r'```(?:json)?|```'), '')
          .trim();

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      data['isOffline'] = false;
      return data;
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return {
        'englishName': 'Unknown Fish',
        'localName': 'Unknown',
        'freshnessScore': 0.0,
        'freshnessStatus': 'Analysis Failed',
        'freshnessEvidence': 'Network or API error occurred',
        'bestCuts': [],
        'idealFor': [],
        'isOffline': false,
        'error': true,
      };
    }
  }
}
