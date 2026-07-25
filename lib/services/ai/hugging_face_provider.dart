import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';

class HuggingFaceProvider implements AIProvider {
  final String apiKey;
  final String modelUrl;

  HuggingFaceProvider()
    : apiKey = dotenv.env['HUGGINGFACE_API_KEY'] ?? '',
      modelUrl =
          dotenv.env['HUGGINGFACE_MODEL_URL'] ??
          'https://api-inference.huggingface.co/models/meta-llama/Llama-3.2-11B-Vision-Instruct';

  @override
  Future<Map<String, dynamic>> analyzeFish(
    String imagePath,
    String location,
  ) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_HUGGINGFACE_API_KEY_HERE') {
      throw Exception('Missing Hugging Face API Key. Please add it to .env');
    }

    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final prompt =
        '''
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
''';

    final response = await http.post(
      Uri.parse(modelUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "inputs": {"image": base64Image, "text": prompt},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      String generatedText = '';
      if (result is List && result.isNotEmpty) {
        generatedText = result[0]['generated_text'] ?? '';
      } else if (result is Map) {
        generatedText = result['generated_text'] ?? '';
      }

      final cleanJson = generatedText
          .replaceAll(RegExp(r'```(?:json)?|```'), '')
          .trim();

      final jsonStartIndex = cleanJson.indexOf('{');
      final jsonEndIndex = cleanJson.lastIndexOf('}') + 1;

      if (jsonStartIndex == -1 || jsonEndIndex == 0) {
        throw Exception('Failed to parse JSON from Hugging Face response.');
      }

      final jsonStr = cleanJson.substring(jsonStartIndex, jsonEndIndex);
      final Map<String, dynamic> data = jsonDecode(jsonStr);

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
    } else {
      throw Exception(
        'HF API Error: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
