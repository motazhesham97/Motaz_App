import 'package:test/test.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'package:motaz_app_client/src/protocol/attachment_metadata.dart';
import 'package:motaz_app_client/src/protocol/audit_event.dart';
import 'package:motaz_app_client/src/protocol/conflict_log.dart';
import 'package:motaz_app_client/src/protocol/local_attachment_staging.dart';
import 'package:motaz_app_client/src/protocol/enums/sync_status.dart';
import 'package:motaz_app_client/src/protocol/enums/audit_operation.dart';
import 'package:motaz_app_client/src/protocol/enums/conflict_status.dart';
import 'package:motaz_app_client/src/protocol/enums/parent_entity_type.dart';

UuidValue _uuid(String s) => UuidValue.withoutValidation(s);

const _deviceId = '00000000-0000-0000-0000-000000000001';
const _entityId = '00000000-0000-0000-0000-000000000002';
const _parentId = '00000000-0000-0000-0000-000000000003';
const _otherId = '00000000-0000-0000-0000-000000000099';

final _now = DateTime.utc(2024, 6, 15, 12, 0, 0);
final _later = DateTime.utc(2024, 6, 15, 13, 0, 0);

void main() {
  group('AttachmentMetadata', () {
    AttachmentMetadata _makeAttachment({
      String? id,
      ParentEntityType parentEntityType = ParentEntityType.SALES_INVOICE,
      String parentEntityId = _parentId,
      String storageReference = 'storage/path/file.jpg',
      String? secureUrl,
      String fileType = 'image/jpeg',
      int? fileSize,
      int? rowVersion,
      SyncStatus? syncStatus,
      String deviceId = _deviceId,
    }) {
      return AttachmentMetadata(
        id: id != null ? _uuid(id) : null,
        parentEntityType: parentEntityType,
        parentEntityId: _uuid(parentEntityId),
        storageReference: storageReference,
        secureUrl: secureUrl,
        fileType: fileType,
        fileSize: fileSize,
        createdAt: _now,
        updatedAt: _later,
        deviceId: _uuid(deviceId),
        rowVersion: rowVersion,
        syncStatus: syncStatus,
      );
    }

    group('construction', () {
      test('creates attachment with required fields', () {
        final att = _makeAttachment(
          storageReference: 'some/ref.pdf',
          fileType: 'application/pdf',
        );
        expect(att.storageReference, 'some/ref.pdf');
        expect(att.fileType, 'application/pdf');
        expect(att.secureUrl, isNull);
        expect(att.fileSize, isNull);
        expect(att.device, isNull);
        expect(att.id, isNull);
      });

      test('rowVersion defaults to 1', () {
        expect(_makeAttachment().rowVersion, 1);
      });

      test('syncStatus defaults to PENDING', () {
        expect(_makeAttachment().syncStatus, SyncStatus.PENDING);
      });

      test('optional fields can be set', () {
        final att = _makeAttachment(
          secureUrl: 'https://cdn.example.com/file.jpg',
          fileSize: 204800,
        );
        expect(att.secureUrl, 'https://cdn.example.com/file.jpg');
        expect(att.fileSize, 204800);
      });

      test('supports all ParentEntityType values', () {
        for (final pet in ParentEntityType.values) {
          final att = _makeAttachment(parentEntityType: pet);
          expect(att.parentEntityType, pet);
        }
      });
    });

    group('toJson', () {
      test('includes __className__ = AttachmentMetadata', () {
        expect(_makeAttachment().toJson()['__className__'], 'AttachmentMetadata');
      });

      test('omits optional null fields', () {
        final json = _makeAttachment().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('secureUrl'), isFalse);
        expect(json.containsKey('fileSize'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes required fields', () {
        final json = _makeAttachment(
          storageReference: 'ref123',
          fileType: 'image/png',
        ).toJson();
        expect(json['storageReference'], 'ref123');
        expect(json['fileType'], 'image/png');
        expect(json['rowVersion'], 1);
        expect(json['syncStatus'], 'PENDING');
        expect(json.containsKey('parentEntityType'), isTrue);
        expect(json.containsKey('parentEntityId'), isTrue);
        expect(json.containsKey('deviceId'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('updatedAt'), isTrue);
      });

      test('includes secureUrl and fileSize when set', () {
        final json = _makeAttachment(
          secureUrl: 'https://example.com/file',
          fileSize: 1024,
        ).toJson();
        expect(json['secureUrl'], 'https://example.com/file');
        expect(json['fileSize'], 1024);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeAttachment(
          id: _otherId,
          parentEntityType: ParentEntityType.RECEIPT,
          storageReference: 'receipts/file.pdf',
          secureUrl: 'https://cdn.example.com/receipts/file.pdf',
          fileType: 'application/pdf',
          fileSize: 512000,
          rowVersion: 3,
          syncStatus: SyncStatus.SYNCED,
        );
        final restored = AttachmentMetadata.fromJson(original.toJson());
        expect(restored.parentEntityType, ParentEntityType.RECEIPT);
        expect(restored.storageReference, 'receipts/file.pdf');
        expect(restored.secureUrl, 'https://cdn.example.com/receipts/file.pdf');
        expect(restored.fileType, 'application/pdf');
        expect(restored.fileSize, 512000);
        expect(restored.rowVersion, 3);
        expect(restored.syncStatus, SyncStatus.SYNCED);
        expect(restored.id, original.id);
      });

      test('applies defaults when optional fields absent', () {
        final att = AttachmentMetadata.fromJson({
          'parentEntityType': 'PRODUCT',
          'parentEntityId': _parentId,
          'storageReference': 'products/img.jpg',
          'fileType': 'image/jpg',
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId,
          'rowVersion': 1,
        });
        expect(att.syncStatus, SyncStatus.PENDING);
        expect(att.secureUrl, isNull);
        expect(att.fileSize, isNull);
        expect(att.id, isNull);
      });
    });

    group('copyWith', () {
      test('updates storageReference', () {
        final original = _makeAttachment(storageReference: 'old/path');
        final copy = original.copyWith(storageReference: 'new/path');
        expect(copy.storageReference, 'new/path');
        expect(copy.fileType, original.fileType);
      });

      test('can set secureUrl to null', () {
        final original = _makeAttachment(secureUrl: 'https://cdn.com/file');
        final copy = original.copyWith(secureUrl: null);
        expect(copy.secureUrl, isNull);
      });

      test('can set fileSize to null', () {
        final original = _makeAttachment(fileSize: 1024);
        final copy = original.copyWith(fileSize: null);
        expect(copy.fileSize, isNull);
      });

      test('updates syncStatus', () {
        final original = _makeAttachment();
        final copy = original.copyWith(syncStatus: SyncStatus.SYNCED);
        expect(copy.syncStatus, SyncStatus.SYNCED);
      });

      test('updates parentEntityType', () {
        final original = _makeAttachment(parentEntityType: ParentEntityType.CLIENT);
        final copy = original.copyWith(
          parentEntityType: ParentEntityType.EXPENSE,
        );
        expect(copy.parentEntityType, ParentEntityType.EXPENSE);
        expect(copy.storageReference, original.storageReference);
      });

      test('preserves all fields when no args given', () {
        final original = _makeAttachment(
          storageReference: 'stable/path',
          fileType: 'image/gif',
          rowVersion: 7,
        );
        final copy = original.copyWith();
        expect(copy.storageReference, 'stable/path');
        expect(copy.fileType, 'image/gif');
        expect(copy.rowVersion, 7);
      });
    });
  });

  group('AuditEvent', () {
    AuditEvent _makeAuditEvent({
      String? id,
      ParentEntityType entityType = ParentEntityType.SALES_INVOICE,
      String entityId = _entityId,
      AuditOperation operation = AuditOperation.CREATE,
      String diffData = '{}',
      String deviceId = _deviceId,
    }) {
      return AuditEvent(
        id: id != null ? _uuid(id) : null,
        entityType: entityType,
        entityId: _uuid(entityId),
        operation: operation,
        diffData: diffData,
        deviceId: _uuid(deviceId),
        createdAt: _now,
      );
    }

    group('construction', () {
      test('creates audit event with required fields', () {
        final event = _makeAuditEvent(
          entityType: ParentEntityType.PRODUCT,
          operation: AuditOperation.UPDATE,
          diffData: '{"name":"new"}',
        );
        expect(event.entityType, ParentEntityType.PRODUCT);
        expect(event.operation, AuditOperation.UPDATE);
        expect(event.diffData, '{"name":"new"}');
        expect(event.id, isNull);
        expect(event.device, isNull);
      });

      test('has no default fields (all required)', () {
        // id is optional, device is optional — that's all
        final event = _makeAuditEvent();
        expect(event.id, isNull);
        expect(event.device, isNull);
        expect(event.operation, AuditOperation.CREATE);
        expect(event.diffData, '{}');
      });
    });

    group('toJson', () {
      test('includes __className__ = AuditEvent', () {
        expect(_makeAuditEvent().toJson()['__className__'], 'AuditEvent');
      });

      test('omits id and device when null', () {
        final json = _makeAuditEvent().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes all required fields', () {
        final json = _makeAuditEvent(
          entityType: ParentEntityType.CLIENT,
          operation: AuditOperation.VOID,
          diffData: '{"reason":"voided"}',
        ).toJson();
        expect(json['entityType'], 'CLIENT');
        expect(json['operation'], 'VOID');
        expect(json['diffData'], '{"reason":"voided"}');
        expect(json.containsKey('entityId'), isTrue);
        expect(json.containsKey('deviceId'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeAuditEvent(
          id: _otherId,
          entityType: ParentEntityType.EXPENSE,
          operation: AuditOperation.UPDATE,
          diffData: '{"amount":100}',
        );
        final restored = AuditEvent.fromJson(original.toJson());
        expect(restored.entityType, ParentEntityType.EXPENSE);
        expect(restored.operation, AuditOperation.UPDATE);
        expect(restored.diffData, '{"amount":100}');
        expect(restored.id, original.id);
        expect(restored.entityId, original.entityId);
        expect(restored.deviceId, original.deviceId);
      });

      test('device is null when absent from JSON', () {
        final event = AuditEvent.fromJson({
          'entityType': 'RECEIPT',
          'entityId': _entityId,
          'operation': 'CREATE',
          'diffData': '{}',
          'deviceId': _deviceId,
          'createdAt': _now.toIso8601String(),
        });
        expect(event.device, isNull);
        expect(event.id, isNull);
      });

      test('all AuditOperation values can be parsed', () {
        for (final op in AuditOperation.values) {
          final event = AuditEvent.fromJson({
            'entityType': 'PRODUCT',
            'entityId': _entityId,
            'operation': op.toJson(),
            'diffData': '{}',
            'deviceId': _deviceId,
            'createdAt': _now.toIso8601String(),
          });
          expect(event.operation, op);
        }
      });
    });

    group('copyWith', () {
      test('updates operation', () {
        final original = _makeAuditEvent(operation: AuditOperation.CREATE);
        final copy = original.copyWith(operation: AuditOperation.UPDATE);
        expect(copy.operation, AuditOperation.UPDATE);
        expect(copy.diffData, original.diffData);
      });

      test('updates diffData', () {
        final original = _makeAuditEvent(diffData: '{}');
        final copy = original.copyWith(diffData: '{"key":"value"}');
        expect(copy.diffData, '{"key":"value"}');
      });

      test('updates entityType', () {
        final original = _makeAuditEvent(entityType: ParentEntityType.CLIENT);
        final copy = original.copyWith(
          entityType: ParentEntityType.SALES_RETURN,
        );
        expect(copy.entityType, ParentEntityType.SALES_RETURN);
      });

      test('can set id via copyWith', () {
        final original = _makeAuditEvent();
        final copy = original.copyWith(id: _uuid(_otherId));
        expect(copy.id, _uuid(_otherId));
      });

      test('preserves fields when no args given', () {
        final original = _makeAuditEvent(
          operation: AuditOperation.VOID,
          diffData: '{"data":"stable"}',
        );
        final copy = original.copyWith();
        expect(copy.operation, AuditOperation.VOID);
        expect(copy.diffData, '{"data":"stable"}');
      });
    });
  });

  group('ConflictLog', () {
    ConflictLog _makeConflictLog({
      String? id,
      ParentEntityType entityType = ParentEntityType.SALES_INVOICE,
      String entityId = _entityId,
      String localPayload = '{"local":"data"}',
      String remotePayload = '{"remote":"data"}',
      String conflictType = 'UPDATE_CONFLICT',
      ConflictStatus? resolutionStatus,
      DateTime? resolvedAt,
      String? resolutionData,
      String deviceId = _deviceId,
    }) {
      return ConflictLog(
        id: id != null ? _uuid(id) : null,
        entityType: entityType,
        entityId: _uuid(entityId),
        localPayload: localPayload,
        remotePayload: remotePayload,
        conflictType: conflictType,
        resolutionStatus: resolutionStatus,
        resolvedAt: resolvedAt,
        resolutionData: resolutionData,
        createdAt: _now,
        deviceId: _uuid(deviceId),
      );
    }

    group('construction', () {
      test('creates conflict log with required fields', () {
        final log = _makeConflictLog(
          localPayload: '{"x":1}',
          remotePayload: '{"x":2}',
          conflictType: 'UPDATE',
        );
        expect(log.localPayload, '{"x":1}');
        expect(log.remotePayload, '{"x":2}');
        expect(log.conflictType, 'UPDATE');
        expect(log.id, isNull);
        expect(log.device, isNull);
        expect(log.resolvedAt, isNull);
        expect(log.resolutionData, isNull);
      });

      test('resolutionStatus defaults to PENDING', () {
        expect(_makeConflictLog().resolutionStatus, ConflictStatus.PENDING);
      });
    });

    group('toJson', () {
      test('includes __className__ = ConflictLog', () {
        expect(_makeConflictLog().toJson()['__className__'], 'ConflictLog');
      });

      test('omits optional null fields', () {
        final json = _makeConflictLog().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('resolvedAt'), isFalse);
        expect(json.containsKey('resolutionData'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes required fields', () {
        final json = _makeConflictLog(
          localPayload: '{"l":1}',
          remotePayload: '{"r":2}',
          conflictType: 'TYPE_MISMATCH',
        ).toJson();
        expect(json['localPayload'], '{"l":1}');
        expect(json['remotePayload'], '{"r":2}');
        expect(json['conflictType'], 'TYPE_MISMATCH');
        expect(json['resolutionStatus'], 'PENDING');
        expect(json.containsKey('entityType'), isTrue);
        expect(json.containsKey('entityId'), isTrue);
      });

      test('includes resolvedAt and resolutionData when set', () {
        final json = _makeConflictLog(
          resolutionStatus: ConflictStatus.RESOLVED,
          resolvedAt: _later,
          resolutionData: '{"winner":"remote"}',
        ).toJson();
        expect(json['resolutionStatus'], 'RESOLVED');
        expect(json.containsKey('resolvedAt'), isTrue);
        expect(json['resolutionData'], '{"winner":"remote"}');
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeConflictLog(
          id: _otherId,
          entityType: ParentEntityType.EXPENSE,
          localPayload: '{"amount":100}',
          remotePayload: '{"amount":200}',
          conflictType: 'AMOUNT_CONFLICT',
          resolutionStatus: ConflictStatus.RESOLVED,
          resolvedAt: _later,
          resolutionData: '{"winner":"local"}',
        );
        final restored = ConflictLog.fromJson(original.toJson());
        expect(restored.entityType, ParentEntityType.EXPENSE);
        expect(restored.localPayload, '{"amount":100}');
        expect(restored.remotePayload, '{"amount":200}');
        expect(restored.conflictType, 'AMOUNT_CONFLICT');
        expect(restored.resolutionStatus, ConflictStatus.RESOLVED);
        expect(restored.resolutionData, '{"winner":"local"}');
        expect(restored.id, original.id);
        expect(restored.resolvedAt, isNotNull);
      });

      test('applies default resolutionStatus when absent', () {
        final log = ConflictLog.fromJson({
          'entityType': 'CLIENT',
          'entityId': _entityId,
          'localPayload': '{}',
          'remotePayload': '{}',
          'conflictType': 'CONFLICT',
          'createdAt': _now.toIso8601String(),
          'deviceId': _deviceId,
        });
        expect(log.resolutionStatus, ConflictStatus.PENDING);
        expect(log.resolvedAt, isNull);
        expect(log.resolutionData, isNull);
      });
    });

    group('copyWith', () {
      test('updates resolutionStatus and resolutionData', () {
        final original = _makeConflictLog();
        final copy = original.copyWith(
          resolutionStatus: ConflictStatus.RESOLVED,
          resolutionData: '{"resolution":"data"}',
        );
        expect(copy.resolutionStatus, ConflictStatus.RESOLVED);
        expect(copy.resolutionData, '{"resolution":"data"}');
        expect(copy.localPayload, original.localPayload);
      });

      test('updates conflictType', () {
        final original = _makeConflictLog(conflictType: 'OLD_TYPE');
        final copy = original.copyWith(conflictType: 'NEW_TYPE');
        expect(copy.conflictType, 'NEW_TYPE');
      });

      test('can set resolvedAt', () {
        final original = _makeConflictLog();
        final copy = original.copyWith(resolvedAt: _later);
        expect(copy.resolvedAt, _later);
      });

      test('can set resolvedAt to null', () {
        final original = _makeConflictLog(resolvedAt: _later);
        final copy = original.copyWith(resolvedAt: null);
        expect(copy.resolvedAt, isNull);
      });

      test('can set resolutionData to null', () {
        final original = _makeConflictLog(resolutionData: '{"data":"here"}');
        final copy = original.copyWith(resolutionData: null);
        expect(copy.resolutionData, isNull);
      });

      test('preserves all fields when no args given', () {
        final original = _makeConflictLog(
          localPayload: '{"stable":true}',
          conflictType: 'STABLE',
        );
        final copy = original.copyWith();
        expect(copy.localPayload, '{"stable":true}');
        expect(copy.conflictType, 'STABLE');
        expect(copy.resolutionStatus, original.resolutionStatus);
      });
    });
  });

  group('LocalAttachmentStaging', () {
    LocalAttachmentStaging _makeStaging({
      String? id,
      ParentEntityType parentEntityType = ParentEntityType.RECEIPT,
      String parentEntityId = _parentId,
      String localFilePath = '/local/file.jpg',
      String fileType = 'image/jpeg',
      int? fileSize,
      String? uploadStatus,
    }) {
      return LocalAttachmentStaging(
        id: id != null ? _uuid(id) : null,
        parentEntityType: parentEntityType,
        parentEntityId: _uuid(parentEntityId),
        localFilePath: localFilePath,
        fileType: fileType,
        fileSize: fileSize,
        uploadStatus: uploadStatus,
        createdAt: _now,
        updatedAt: _later,
      );
    }

    group('construction', () {
      test('creates staging with required fields', () {
        final staging = _makeStaging(
          localFilePath: '/path/to/file.pdf',
          fileType: 'application/pdf',
        );
        expect(staging.localFilePath, '/path/to/file.pdf');
        expect(staging.fileType, 'application/pdf');
        expect(staging.fileSize, isNull);
        expect(staging.id, isNull);
      });

      test('uploadStatus defaults to PENDING', () {
        expect(_makeStaging().uploadStatus, 'PENDING');
      });

      test('uploadStatus can be set explicitly', () {
        final staging = _makeStaging(uploadStatus: 'UPLOADING');
        expect(staging.uploadStatus, 'UPLOADING');
      });

      test('supports all ParentEntityType values', () {
        for (final pet in ParentEntityType.values) {
          final staging = _makeStaging(parentEntityType: pet);
          expect(staging.parentEntityType, pet);
        }
      });
    });

    group('toJson', () {
      test('includes __className__ = LocalAttachmentStaging', () {
        expect(
          _makeStaging().toJson()['__className__'],
          'LocalAttachmentStaging',
        );
      });

      test('omits id when null', () {
        final json = _makeStaging().toJson();
        expect(json.containsKey('id'), isFalse);
      });

      test('omits fileSize when null', () {
        final json = _makeStaging().toJson();
        expect(json.containsKey('fileSize'), isFalse);
      });

      test('includes required fields', () {
        final json = _makeStaging(
          localFilePath: '/path/img.png',
          fileType: 'image/png',
        ).toJson();
        expect(json['localFilePath'], '/path/img.png');
        expect(json['fileType'], 'image/png');
        expect(json['uploadStatus'], 'PENDING');
        expect(json.containsKey('parentEntityType'), isTrue);
        expect(json.containsKey('parentEntityId'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('updatedAt'), isTrue);
      });

      test('includes fileSize when set', () {
        final json = _makeStaging(fileSize: 2048).toJson();
        expect(json['fileSize'], 2048);
      });

      test('includes id when set', () {
        final json = _makeStaging(id: _otherId).toJson();
        expect(json.containsKey('id'), isTrue);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeStaging(
          id: _otherId,
          parentEntityType: ParentEntityType.PRODUCT,
          localFilePath: '/data/product.jpg',
          fileType: 'image/jpg',
          fileSize: 102400,
          uploadStatus: 'COMPLETED',
        );
        final restored = LocalAttachmentStaging.fromJson(original.toJson());
        expect(restored.parentEntityType, ParentEntityType.PRODUCT);
        expect(restored.localFilePath, '/data/product.jpg');
        expect(restored.fileType, 'image/jpg');
        expect(restored.fileSize, 102400);
        expect(restored.uploadStatus, 'COMPLETED');
        expect(restored.id, original.id);
        expect(restored.parentEntityId, original.parentEntityId);
      });

      test('uses default uploadStatus PENDING when absent from JSON', () {
        final staging = LocalAttachmentStaging.fromJson({
          'parentEntityType': 'EXPENSE',
          'parentEntityId': _parentId,
          'localFilePath': '/local/expense.jpg',
          'fileType': 'image/jpg',
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
        });
        expect(staging.uploadStatus, 'PENDING');
        expect(staging.fileSize, isNull);
        expect(staging.id, isNull);
      });

      test('fileSize is null when absent from JSON', () {
        final staging = LocalAttachmentStaging.fromJson({
          'parentEntityType': 'CLIENT',
          'parentEntityId': _parentId,
          'localFilePath': '/path',
          'fileType': 'image/gif',
          'uploadStatus': 'PENDING',
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
        });
        expect(staging.fileSize, isNull);
      });
    });

    group('copyWith', () {
      test('updates localFilePath', () {
        final original = _makeStaging(localFilePath: '/old/path');
        final copy = original.copyWith(localFilePath: '/new/path');
        expect(copy.localFilePath, '/new/path');
        expect(copy.fileType, original.fileType);
      });

      test('updates uploadStatus', () {
        final original = _makeStaging(uploadStatus: 'PENDING');
        final copy = original.copyWith(uploadStatus: 'UPLOADING');
        expect(copy.uploadStatus, 'UPLOADING');
      });

      test('can set fileSize to null', () {
        final original = _makeStaging(fileSize: 1024);
        final copy = original.copyWith(fileSize: null);
        expect(copy.fileSize, isNull);
      });

      test('updates fileSize', () {
        final original = _makeStaging(fileSize: 500);
        final copy = original.copyWith(fileSize: 1000);
        expect(copy.fileSize, 1000);
      });

      test('updates parentEntityType', () {
        final original = _makeStaging(parentEntityType: ParentEntityType.RECEIPT);
        final copy = original.copyWith(
          parentEntityType: ParentEntityType.EXPENSE,
        );
        expect(copy.parentEntityType, ParentEntityType.EXPENSE);
      });

      test('preserves all fields when no args given', () {
        final original = _makeStaging(
          localFilePath: '/stable/path',
          fileType: 'video/mp4',
          fileSize: 8192,
          uploadStatus: 'FAILED',
        );
        final copy = original.copyWith();
        expect(copy.localFilePath, '/stable/path');
        expect(copy.fileType, 'video/mp4');
        expect(copy.fileSize, 8192);
        expect(copy.uploadStatus, 'FAILED');
      });

      test('boundary: empty string localFilePath', () {
        final original = _makeStaging(localFilePath: '/valid');
        final copy = original.copyWith(localFilePath: '');
        expect(copy.localFilePath, '');
      });
    });
  });
}