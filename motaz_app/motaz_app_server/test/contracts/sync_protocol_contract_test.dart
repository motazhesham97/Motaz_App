import 'package:motaz_app_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Sync protocol contract', () {
    test('PushRequest protocol JSON keeps every outbox field', () {
      final request = PushRequest(
        outboxId: 'outbox-1',
        entityType: 'CLIENT',
        entityId: 'client-1',
        operation: 'CREATE',
        payload: '{"displayName":"Ali"}',
        rowVersion: 7,
        deviceId: 'device-1',
      );

      expect(request.toJsonForProtocol(), {
        '__className__': 'PushRequest',
        'outboxId': 'outbox-1',
        'entityType': 'CLIENT',
        'entityId': 'client-1',
        'operation': 'CREATE',
        'payload': '{"displayName":"Ali"}',
        'rowVersion': 7,
        'deviceId': 'device-1',
      });

      final roundTrip = PushRequest.fromJson(request.toJsonForProtocol());
      expect(roundTrip.outboxId, request.outboxId);
      expect(roundTrip.entityType, request.entityType);
      expect(roundTrip.entityId, request.entityId);
      expect(roundTrip.operation, request.operation);
      expect(roundTrip.payload, request.payload);
      expect(roundTrip.rowVersion, request.rowVersion);
      expect(roundTrip.deviceId, request.deviceId);
    });

    test('PushResponse protocol JSON omits null optional fields', () {
      final successJson = PushResponse(
        success: true,
        newRowVersion: 8,
      ).toJsonForProtocol();

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
      ).toJsonForProtocol();

      expect(conflictJson, {
        '__className__': 'PushResponse',
        'success': false,
        'conflictId': 'conflict-1',
        'errorCode': 'CONFLICT',
        'errorMessage': 'Remote row version is newer.',
      });
    });

    test('PullRequest protocol JSON keeps cursor fields', () {
      final request = PullRequest(
        entityType: 'PRODUCT',
        sinceRowVersion: 42,
        deviceId: 'device-1',
        limit: 100,
      );

      expect(request.toJsonForProtocol(), {
        '__className__': 'PullRequest',
        'entityType': 'PRODUCT',
        'sinceRowVersion': 42,
        'deviceId': 'device-1',
        'limit': 100,
      });

      final roundTrip = PullRequest.fromJson(request.toJsonForProtocol());
      expect(roundTrip.entityType, request.entityType);
      expect(roundTrip.sinceRowVersion, request.sinceRowVersion);
      expect(roundTrip.deviceId, request.deviceId);
      expect(roundTrip.limit, request.limit);
    });

    test('PullResponse protocol JSON keeps rows and pagination metadata', () {
      final response = PullResponse(
        entityType: 'SALES_INVOICE',
        rows: const ['{"id":"invoice-1"}', '{"id":"invoice-2"}'],
        hasMore: true,
        latestRowVersion: 104,
      );

      expect(response.toJsonForProtocol(), {
        '__className__': 'PullResponse',
        'entityType': 'SALES_INVOICE',
        'rows': ['{"id":"invoice-1"}', '{"id":"invoice-2"}'],
        'hasMore': true,
        'latestRowVersion': 104,
      });

      final roundTrip = PullResponse.fromJson(response.toJsonForProtocol());
      expect(roundTrip.entityType, response.entityType);
      expect(roundTrip.rows, response.rows);
      expect(roundTrip.hasMore, isTrue);
      expect(roundTrip.latestRowVersion, response.latestRowVersion);
    });
  });
}
