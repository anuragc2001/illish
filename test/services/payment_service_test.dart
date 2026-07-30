import 'package:flutter_test/flutter_test.dart';
import 'package:illish/core/models/upi_app.dart';

void main() {
  group('UpiResponse parsing', () {
    test('Parses successful Android UPI response string', () {
      final data = {
        'Status': 'SUCCESS',
        'txnId': 'AXI123456789',
        'txnRef': 'REF987654321',
        'responseCode': '00',
      };
      
      final response = UpiResponse.fromMap(data);
      
      expect(response.status, 'SUCCESS');
      expect(response.isSuccess, isTrue);
      expect(response.isFailed, isFalse);
      expect(response.txnId, 'AXI123456789');
      expect(response.txnRef, 'REF987654321');
    });

    test('Parses failed Android UPI response string', () {
      final data = {
        'status': 'FAILURE',
        'txnId': null,
        'responseCode': 'U30',
      };
      
      final response = UpiResponse.fromMap(data);
      
      expect(response.status, 'FAILURE');
      expect(response.isSuccess, isFalse);
      expect(response.isFailed, isTrue);
    });

    test('Parses submitted Android UPI response string', () {
      final data = {
        'Status': 'SUBMITTED',
        'txnId': 'AXI999',
      };
      
      final response = UpiResponse.fromMap(data);
      
      expect(response.status, 'SUBMITTED');
      expect(response.isSuccess, isFalse);
      expect(response.isSubmitted, isTrue);
    });

    test('Parses iOS generic return state', () {
      final data = {
        'status': 'UNKNOWN',
        'rawResponse': 'Returned from iOS app',
      };
      
      final response = UpiResponse.fromMap(data);
      
      expect(response.status, 'UNKNOWN');
      expect(response.isSuccess, isFalse);
      expect(response.isFailed, isFalse);
    });
  });
}
