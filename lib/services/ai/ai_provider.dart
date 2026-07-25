abstract class AIProvider {
  /// Analyzes a fish image and returns a Map containing the extracted data.
  Future<Map<String, dynamic>> analyzeFish(String imagePath, String location);
}
