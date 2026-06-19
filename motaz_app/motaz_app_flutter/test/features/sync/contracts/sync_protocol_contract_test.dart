import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart';

void main() {
  group('Sync protocol contract', () {
    test('PushRequest keeps the backend field names and round-trips', () {
      final request = PushRequest(
        outboxId: 'outbox-1',
        entityType: 'CLIENT',
        entityId: 'client-1',
        operation: 'CREATE',
        payload: '{"displayName":"Ali"}',
        rowVersion: 7,
        deviceId: 'device-1',
      );

      final json = request.toJson();

      expect(json, {
        '__className__': 'PushRequest',
        'outboxId': 'outbox-1',
        'entityType': 'CLIENT',
        'entityId': 'client-1',
        'operation': 'CREATE',
        'payload': '{"displayName":"Ali"}',
        'rowVersion': 7,
        'deviceId': 'device-1',
      });

      final roundTrip = PushRequest.fromJson(json);
      expect(roundTrip.outboxId, request.outboxId);
      expect(roundTrip.entityType, request.entityType);
      expect(roundTrip.entityId, request.entityId);
      expect(roundTrip.operation, request.operation);
      expect(roundTrip.payload, request.payload);
      expect(roundTrip.rowVersion, request.rowVersion);
      expect(roundTrip.deviceId, request.deviceId);
    });

    test('PushResponse preserves success and conflict response shapes', () {
      final successJson = PushResponse(
        success: true,
        newRowVersion: 8,
      ).toJson();

      expect(successJson, {
        '__className__': 'PushResponse',
        'success': true,
        'newRowVersion': 8,
      });
      expect(successJson, isNot(contains('conflictId')));
      expect(successJson, isNot(contains('errorCode')));
      expect(successJson, isNot(contains('errorMessage')));

      final conflictJson = PushResponse(
        success: false,
        conflictId: 'conflict-1',
        errorCode: 'CONFLICT',
        errorMessage: 'Remote row version is newer.',
      ).toJson();

      expect(conflictJson, {
        '__className__': 'PushResponse',
        'success': false,
        'conflictId': 'conflict-1',
        'errorCode': 'CONFLICT',
        'errorMessage': 'Remote row version is newer.',
      });

      final roundTrip = PushResponse.fromJson(conflictJson);
      expect(roundTrip.success, isFalse);
      expect(roundTrip.newRowVersion, isNull);
      expect(roundTrip.conflictId, 'conflict-1');
      expect(roundTrip.errorCode, 'CONFLICT');
      expect(roundTrip.errorMessage, 'Remote row version is newer.');
    });

    test('PullRequest keeps cursor fields required for incremental sync', () {
      final request = PullRequest(
        entityType: 'PRODUCT',
        sinceRowVersion: 42,
        deviceId: 'device-1',
        limit: 100,
      );

      final json = request.toJson();

      expect(json, {
        '__className__': 'PullRequest',
        'entityType': 'PRODUCT',
        'sinceRowVersion': 42,
        'deviceId': 'device-1',
        'limit': 100,
      });

      final roundTrip = PullRequest.fromJson(json);
      expect(roundTrip.entityType, request.entityType);
      expect(roundTrip.sinceRowVersion, request.sinceRowVersion);
      expect(roundTrip.deviceId, request.deviceId);
      expect(roundTrip.limit, request.limit);
    });

    test('PullResponse round-trips rows and pagination metadata', () {
      final response = PullResponse(
        entityType: 'SALES_INVOICE',
        rows: const ['{"id":"invoice-1"}', '{"id":"invoice-2"}'],
        hasMore: true,
        latestRowVersion: 104,
      );

      final json = response.toJson();

      expect(json, {
        '__className__': 'PullResponse',
        'entityType': 'SALES_INVOICE',
        'rows': ['{"id":"invoice-1"}', '{"id":"invoice-2"}'],
        'hasMore': true,
        'latestRowVersion': 104,
      });

      final roundTrip = PullResponse.fromJson(json);
      expect(roundTrip.entityType, response.entityType);
      expect(roundTrip.rows, response.rows);
      expect(roundTrip.hasMore, isTrue);
      expect(roundTrip.latestRowVersion, response.latestRowVersion);
    });
  });
}
