import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isar/isar.dart';
import 'package:illish/services/db_service.dart';

class MockIsar extends Mock implements Isar {}

void main() {
  group('DBService Tests', () {
    test('isInitialized checks Isar.instanceNames', () {
      expect(DBService.isInitialized, Isar.instanceNames.contains(Isar.defaultName));
    });

    test('lastError is null initially', () {
      expect(DBService.lastError, null);
    });
  });
}
