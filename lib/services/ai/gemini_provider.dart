import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';

class GeminiProvider implements AIProvider {
  late final GenerativeModel? _cloudModel;

  GeminiProvider() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.6-flash';
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

    final now = DateTime.now();
    
    final dayStr = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][now.weekday - 1];
    
    String timeOfDay;
    if (now.hour >= 4 && now.hour < 11) timeOfDay = "Morning";
    else if (now.hour >= 11 && now.hour < 16) timeOfDay = "Afternoon";
    else if (now.hour >= 16 && now.hour < 21) timeOfDay = "Evening";
    else timeOfDay = "Night";
    
    String season;
    if (now.month == 12 || now.month <= 2) season = "Winter";
    else if (now.month >= 3 && now.month <= 5) season = "Summer";
    else if (now.month >= 6 && now.month <= 9) season = "Monsoon";
    else season = "Autumn";

    final timeContext = "Current Day: $dayStr\nTime of Day: $timeOfDay\nCurrent Season: $season";

    final prompt = TextPart('''
Analyze this image of a fish found in $location. 
$timeContext

IMPORTANT INSTRUCTION: If the image is NOT of a fish/aquatic life, or is too blurry to identify, return EXACTLY this JSON:
{
  "error": true,
  "errorType": "invalid_image",
  "errorReason": "The image doesn't appear to be aquatic life or is too blurry. Please make sure the subject is clear and centered."
}

Otherwise, if it is a valid fish image, return a raw JSON object (no markdown, no backticks) with exactly this structure:
{
  "englishName": "Common english name",
  "localName": "Regional name based on $location (include native script if applicable)",
  "freshnessScore": 0.95, // float between 0.0 and 1.0 based on eye cloudiness, gill color, skin texture
  "freshnessStatus": "Green / 95% Fresh", // e.g., Green/Yellow/Red
  "freshnessEvidence": "Clear eyes • bright red gills", // bullet points separated by ' • '. Keep each point extremely short (under 5 words).
  "bestCuts": ["List of 3 hyper-local authentic fishmonger cuts commonly used in $location markets. Do NOT use generic Hindi words like 'Sabut' if the location is West Bengal. Use hyper-local terms (e.g., 'Peti', 'Gada' for Bengal). Format STRICTLY as: LocalName (Extremely brief English equivalent, max 2 words). Example: Peti (Belly)."],
  "idealFor": ["List of authentic local recipes based on $location. Format strictly as: LocalName (Extremely brief English equivalent, max 2 words). Example: Rui Posto (Poppy Seed Curry)."],
  "trickeryTips": ["List of 1 to 6 vendor trickery alerts or buying tips. MUST STRICTLY follow this format: 'Short Title - Brief description'. Example: 'Ice Weight - Vendor may weigh before ice is removed', 'Flesh Test - Press flesh to see if it bounces back'. Keep under 10 words each."],
  "suggestedPrice": "300 - 320", // string, numerical range representing fair price in local currency. CALCULATE THIS strictly based on the fish type, freshness evidence from the image, location ($location), and the current time/day/season.
  "marketAvgPrice": "340", // string, numerical value representing market average for this fish type and location until a DB is available.
  "priceExplanation": "Calculated based on [Freshness %] freshness, [Time/Day/Season] demand, and current $location market rates.",
  "marketAvgExplanation": "Market average is fetched from historical market data and local crowdsourcing."
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
