import 'dart:convert';

import 'package:motaz_app_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/local_test_config.dart';

const deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const januaryId = '00000000-0000-4000-8000-000000202501';

Map<String, dynamic> lossPayload() => {
  'id': januaryId,
  'year': 2025,
  'month': 1,
  'netSales': 1000000,
  'operationalExpenses': 1500000,
  'productionExpenses': 0,
  'profitBeforeCarry': -500000,
  'currentMonthLoss': -500000,
  'carriedLossIn': 0,
  'carriedLossOut': -500000,
  'netProfit': -500000,
  'ownerShare': 0,
  'partnerShare': 0,
  'marginShare': 0,
  'status': 'ACTIVE',
  'voidReason': null,
  'deviceId': deviceId,
  'createdAt': DateTime.utc(2025, 2).toIso8601String(),
  'updatedAt': DateTime.utc(2025, 2).toIso8601String(),
  'rowVersion': 1,
  'syncStatus': 'PENDING',
};

PushRequest request(
  Map<String, dynamic> payload, {
  String operation = 'CREATE',
  int version = 1,
}) => PushRequest(
  outboxId: 'test-outbox',
  entityType: 'MONTHLY_DISTRIBUTION',
  entityId: payload['id'] as String,
  operation: operation,
  payload: jsonEncode(payload),
  rowVersion: version,
  deviceId: deviceId,
);

void main() {
  withServerpod(
    'Monthly settlement PostgreSQL boundary',
    (builder, endpoints) {
      late TestSessionBuilder authenticated;
      setUp(() async {
        authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'test-owner',
            {},
          ),
        );
        await Device.db.insertRow(
          builder.build(),
          Device(
            id: UuidValue.fromString(deviceId),
            deviceName: 'Test only',
            platform: DevicePlatform.ANDROID,
            deviceCode: 'test-loss',
            createdAt: DateTime.utc(2025, 2),
            lastActiveAt: DateTime.utc(2025, 2),
          ),
        );
      });

      test(
        'persists signed loss and zero shares, replays identical create and conflicts on different create',
        () async {
          // Arrange / Act: actual endpoint, ORM and PostgreSQL after migrations.
          final payload = lossPayload();
          final created = await endpoints.sync.push(
            authenticated,
            request(payload),
          );
          expect(created.success, isTrue, reason: created.errorMessage);
          final saved = await MonthlyDistribution.db.findById(
            builder.build(),
            UuidValue.fromString(januaryId),
          );

          // Assert: signed fields survive storage and a retry is idempotent.
          expect(saved!.carriedLossOut, -500000);
          expect(saved.currentMonthLoss, -500000);
          expect(
            [saved.ownerShare, saved.partnerShare, saved.marginShare],
            [0, 0, 0],
          );
          final replay = await endpoints.sync.push(
            authenticated,
            request({...payload, 'deviceId': deviceId}),
          );
          expect(replay.success, isTrue, reason: replay.errorMessage);
          expect(replay.newRowVersion, created.newRowVersion);
          final different = {
            ...payload,
            'netSales': 900000,
            'profitBeforeCarry': -600000,
            'currentMonthLoss': -600000,
            'carriedLossOut': -600000,
            'netProfit': -600000,
          };
          final conflict = await endpoints.sync.push(
            authenticated,
            request(different),
          );
          expect(conflict.success, isFalse);
          expect(conflict.errorCode, 'CONFLICT');
          expect(conflict.conflictId, isNotNull);
          expect(await MonthlyDistribution.db.count(builder.build()), 1);
          expect(await AuditEvent.db.count(builder.build()), 1);
          expect(
            (await MonthlyDistribution.db.findById(
              builder.build(),
              saved.id!,
            ))!.netProfit,
            -500000,
          );
        },
      );

      test(
        'rejects a missing or mismatched predecessor without partial writes and accepts chronological recovery',
        () async {
          // Arrange: February has operating profit that exactly covers January's loss.
          final january = lossPayload();
          final february = {
            ...january,
            'id': '00000000-0000-4000-8000-000000202502',
            'month': 2,
            'netSales': 2000000,
            'profitBeforeCarry': 500000,
            'currentMonthLoss': 0,
            'carriedLossIn': -500000,
            'carriedLossOut': 0,
            'netProfit': 0,
          };

          // Act / Assert: no predecessor means no settlement or audit can persist.
          final premature = await endpoints.sync.push(
            authenticated,
            request(february),
          );
          expect(premature.success, isFalse);
          expect(
            premature.errorMessage,
            contains('Missing previous loss settlement'),
          );
          expect(await MonthlyDistribution.db.count(builder.build()), 0);
          expect(await AuditEvent.db.count(builder.build()), 0);

          final first = await endpoints.sync.push(
            authenticated,
            request(january),
          );
          expect(first.success, isTrue, reason: first.errorMessage);
          final wrongCarry = {
            ...february,
            'carriedLossIn': -400000,
            'netProfit': 100000,
            'ownerShare': 33000,
            'partnerShare': 33000,
            'marginShare': 34000,
          };
          final rejected = await endpoints.sync.push(
            authenticated,
            request(wrongCarry),
          );
          expect(rejected.success, isFalse);
          expect(
            rejected.errorMessage,
            contains('Previous settlement must be approved first'),
          );
          expect(await MonthlyDistribution.db.count(builder.build()), 1);
          expect(await AuditEvent.db.count(builder.build()), 1);

          final recovered = await endpoints.sync.push(
            authenticated,
            request(february),
          );
          expect(recovered.success, isTrue, reason: recovered.errorMessage);
          final saved = await MonthlyDistribution.db.findById(
            builder.build(),
            UuidValue.fromString(february['id'] as String),
          );
          expect(saved!.netProfit, 0);
          expect(saved.carriedLossOut, 0);
          expect(saved.carriedLossIn, -500000);
          expect(
            [saved.ownerShare, saved.partnerShare, saved.marginShare],
            [0, 0, 0],
          );
          expect(await AuditEvent.db.count(builder.build()), 2);
        },
      );

      test('rolls back a settlement when its audit insert fails', () async {
        // Arrange: force an actual PostgreSQL failure at the last transaction step.
        final session = builder.build();
        await session.db.unsafeExecute(r'''
CREATE FUNCTION test_reject_settlement_audit() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'test audit unavailable';
END;
$$ LANGUAGE plpgsql
''');
        await session.db.unsafeExecute('''
CREATE TRIGGER test_reject_settlement_audit
BEFORE INSERT ON audit_event
FOR EACH ROW EXECUTE FUNCTION test_reject_settlement_audit()
''');

        // Act: the row insert succeeds first, but audit must abort the entire write.
        final response = await endpoints.sync.push(
          authenticated,
          request(lossPayload()),
        );

        // Assert: there is no partially saved month and existing device data remains.
        expect(response.success, isFalse);
        expect(response.errorMessage, contains('test audit unavailable'));
        expect(await MonthlyDistribution.db.count(session), 0);
        expect(await AuditEvent.db.count(session), 0);
        expect(await Device.db.count(session), 1);
      });

      test(
        'requires authentication and rejects inconsistent arithmetic without persisting financial data',
        () async {
          final payload = lossPayload();
          final unauthenticated = await endpoints.sync.push(
            builder,
            request(payload),
          );
          expect(unauthenticated.success, isFalse);
          expect(unauthenticated.errorCode, 'UNAUTHENTICATED');
          final invalid = await endpoints.sync.push(
            authenticated,
            request({...payload, 'netProfit': -1}),
          );
          expect(invalid.success, isFalse);
          expect(
            invalid.errorMessage,
            contains('Inconsistent settlement field'),
          );
          expect(await MonthlyDistribution.db.count(builder.build()), 0);
          expect(await AuditEvent.db.count(builder.build()), 0);
        },
      );
    },
    runMode: 'test',
    applyMigrations: true,
    configOverride: localTestConfig,
  );
}
