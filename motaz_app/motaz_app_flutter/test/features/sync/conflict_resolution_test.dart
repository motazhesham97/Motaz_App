import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart';

void main() {
  group('Conflict resolution protocol contract', () {
    test('request keeps conflict id and chosen version fields', () {
      final request = ConflictResolutionRequest(
        conflictId: 'conflict-1',
        chosenVersion: 'local',
      );

      final json = request.toJson();

      expect(json, {
        '__className__': 'ConflictResolutionRequest',
        'conflictId': 'conflict-1',
        'chosenVersion': 'local',
      });

      final roundTrip = ConflictResolutionRequest.fromJson(json);
      expect(roundTrip.conflictId, request.conflictId);
      expect(roundTrip.chosenVersion, request.chosenVersion);
    });

    test('success response includes new row version and omits error', () {
      final json = ConflictResolutionResponse(
        success: true,
        newRowVersion: 12,
      ).toJson();

      expect(json, {
        '__className__': 'ConflictResolutionResponse',
        'success': true,
        'newRowVersion': 12,
      });
      expect(json, isNot(contains('errorMessage')));

      final roundTrip = ConflictResolutionResponse.fromJson(json);
      expect(roundTrip.success, isTrue);
      expect(roundTrip.newRowVersion, 12);
      expect(roundTrip.errorMessage, isNull);
    });

    test('failure response includes error and omits row version', () {
      final json = ConflictResolutionResponse(
        success: false,
        errorMessage: 'Conflict not found',
      ).toJson();

      expect(json, {
        '__className__': 'ConflictResolutionResponse',
        'success': false,
        'errorMessage': 'Conflict not found',
      });
      expect(json, isNot(contains('newRowVersion')));

      final roundTrip = ConflictResolutionResponse.fromJson(json);
      expect(roundTrip.success, isFalse);
      expect(roundTrip.errorMessage, 'Conflict not found');
      expect(roundTrip.newRowVersion, isNull);
    });
  });
}
