import 'package:flutter_test/flutter_test.dart';
import 'package:illish/services/remote_config_service.dart';

void main() {
  group('RemoteConfigService Tests', () {
    test('ValueNotifiers have expected default values', () {
      expect(RemoteConfigService.geminiModel.value, 'gemini-3.6-flash');
      expect(RemoteConfigService.mockMode.value, true);
      expect(RemoteConfigService.enablePayment.value, true);
      expect(RemoteConfigService.syncImagesToCloud.value, false);
      expect(RemoteConfigService.priceWeekly.value, '₹29');
    });

    test('configUpdateNotifier starts at 0', () {
      expect(RemoteConfigService.configUpdateNotifier.value, 0);
    });
  });
}
