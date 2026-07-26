import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';

class GeminiProvider implements AIProvider {
  late final GenerativeModel? _cloudModel;

  GeminiProvider() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
    if (apiKey != null && apiKey.isNotEmpty) {
      _cloudModel = GenerativeModel(model: modelName, apiKey: apiKey);
    } else {
      _cloudModel = null;
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeFish(
    String imagePath,
    String location,
  ) async {
    if (_cloudModel == null) {
      throw Exception('Gemini API Key is missing or invalid.');
    }

    final imageBytes = await File(imagePath).readAsBytes();

    final prompt = TextPart('''
Analyze this image of a fish found in $location. Return a raw JSON object (no markdown, no backticks) with exactly this structure:
{
  "englishName": "Common english name",
  "localName": "Regional name based on $location (include native script if applicable)",
  "freshnessScore": 0.95, // float between 0.0 and 1.0 based on eye cloudiness, gill color, skin texture
  "freshnessStatus": "Green / 95% Fresh", // e.g., Green/Yellow/Red
  "freshnessEvidence": "Clear eyes • bright red gills", // bullet points separated by ' • '. Keep each point extremely short (under 5 words).
  "bestCuts": ["List of 3 authentic local fishmonger cuts commonly used in $location markets (e.g. if in West Bengal, use real Bengali terms like 'Peti', 'Gada', etc. instead of generic 'steaks'). Format strictly as: LocalName (English translation). Keep under 8 words per item."],
  "idealFor": ["List of authentic local recipes based on $location. Format strictly as: LocalName (English translation). Keep under 8 words per item."],
  "trickeryTips": ["List of 1 to 6 vendor trickery alerts or general buying tips.Keep ALL tips extremely concise and short (under 10 words each). Keep the very first tip short with 'Vendor trickery:' and punchy so it acts as a catchy preview and so one so forth. Example: 'Vendor trickery: weigh before ice is added', 'Press the flesh - it should bounce back immediately', etc."]
}
''');

    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await _cloudModel!.generateContent([
      Content.multi([prompt, imagePart]),
    ]); // Let AIService handle the timeout

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      final Map<String, dynamic> data = jsonDecode(jsonMatch.group(0)!);

      // Attempt to format "Rui (রুই)" into englishName="Rui (Rohu)", localName="রুই"
      final english = data['englishName']?.toString();
      final local = data['localName']?.toString();

      if (english != null &&
          local != null &&
          local.contains('(') &&
          local.contains(')')) {
        final parts = local.split('(');
        String part1 = parts[0].trim();
        String part2 = parts[1].replaceAll(')', '').trim();

        bool part2IsEnglish = RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(part2);

        String trans;
        String native;

        if (part2IsEnglish) {
          trans = part2;
          native = part1;
        } else {
          trans = part1;
          native = part2;
        }

        data['englishName'] = '$trans ($english)';
        data['localName'] = native;
      }

      data['isOffline'] = false;
      return data;
    }
    throw Exception('Failed to parse JSON from Gemini response');
  }
}
