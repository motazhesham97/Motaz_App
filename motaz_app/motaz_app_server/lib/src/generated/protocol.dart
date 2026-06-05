/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i3;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i4;
import 'attachment_confirm_request.dart' as _i5;
import 'attachment_confirm_response.dart' as _i6;
import 'attachment_metadata.dart' as _i7;
import 'attachment_upload_approval.dart' as _i8;
import 'attachment_upload_request.dart' as _i9;
import 'audit_event.dart' as _i10;
import 'beneficiary.dart' as _i11;
import 'client_record.dart' as _i12;
import 'conflict_log.dart' as _i13;
import 'conflict_payload.dart' as _i14;
import 'conflict_resolution_request.dart' as _i15;
import 'conflict_resolution_response.dart' as _i16;
import 'device.dart' as _i17;
import 'device_registration_request.dart' as _i18;
import 'device_registration_response.dart' as _i19;
import 'enums/audit_operation.dart' as _i20;
import 'enums/conflict_status.dart' as _i21;
import 'enums/device_platform.dart' as _i22;
import 'enums/expense_category.dart' as _i23;
import 'enums/parent_entity_type.dart' as _i24;
import 'enums/party_account.dart' as _i25;
import 'enums/receipt_type.dart' as _i26;
import 'enums/record_status.dart' as _i27;
import 'enums/sync_outbox_status.dart' as _i28;
import 'enums/sync_status.dart' as _i29;
import 'expense.dart' as _i30;
import 'free_sample.dart' as _i31;
import 'free_sample_line.dart' as _i32;
import 'greetings/greeting.dart' as _i33;
import 'local_attachment_staging.dart' as _i34;
import 'monthly_distribution.dart' as _i35;
import 'owner_account.dart' as _i36;
import 'party_adjustment.dart' as _i37;
import 'product.dart' as _i38;
import 'pull_request.dart' as _i39;
import 'pull_response.dart' as _i40;
import 'push_request.dart' as _i41;
import 'push_response.dart' as _i42;
import 'receipt.dart' as _i43;
import 'receipt_allocation.dart' as _i44;
import 'sales_invoice.dart' as _i45;
import 'sales_invoice_line.dart' as _i46;
import 'sales_return.dart' as _i47;
import 'sales_return_line.dart' as _i48;
import 'sync_cursor.dart' as _i49;
import 'sync_outbox.dart' as _i50;
import 'package:motaz_app_server/src/generated/conflict_log.dart' as _i51;
export 'attachment_confirm_request.dart';
export 'attachment_confirm_response.dart';
export 'attachment_metadata.dart';
export 'attachment_upload_approval.dart';
export 'attachment_upload_request.dart';
export 'audit_event.dart';
export 'beneficiary.dart';
export 'client_record.dart';
export 'conflict_log.dart';
export 'conflict_payload.dart';
export 'conflict_resolution_request.dart';
export 'conflict_resolution_response.dart';
export 'device.dart';
export 'device_registration_request.dart';
export 'device_registration_response.dart';
export 'enums/audit_operation.dart';
export 'enums/conflict_status.dart';
export 'enums/device_platform.dart';
export 'enums/expense_category.dart';
export 'enums/parent_entity_type.dart';
export 'enums/party_account.dart';
export 'enums/receipt_type.dart';
export 'enums/record_status.dart';
export 'enums/sync_outbox_status.dart';
export 'enums/sync_status.dart';
export 'expense.dart';
export 'free_sample.dart';
export 'free_sample_line.dart';
export 'greetings/greeting.dart';
export 'local_attachment_staging.dart';
export 'monthly_distribution.dart';
export 'owner_account.dart';
export 'party_adjustment.dart';
export 'product.dart';
export 'pull_request.dart';
export 'pull_response.dart';
export 'push_request.dart';
export 'push_response.dart';
export 'receipt.dart';
export 'receipt_allocation.dart';
export 'sales_invoice.dart';
export 'sales_invoice_line.dart';
export 'sales_return.dart';
export 'sales_return_line.dart';
export 'sync_cursor.dart';
export 'sync_outbox.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'attachment_metadata',
      dartName: 'AttachmentMetadata',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'parentEntityType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ParentEntityType',
        ),
        _i2.ColumnDefinition(
          name: 'parentEntityId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'storageReference',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'secureUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'fileType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fileSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'attachment_metadata_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'attachment_metadata_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'attachment_parent_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'parentEntityType',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'parentEntityId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'audit_event',
      dartName: 'AuditEvent',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'entityType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ParentEntityType',
        ),
        _i2.ColumnDefinition(
          name: 'entityId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'operation',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AuditOperation',
        ),
        _i2.ColumnDefinition(
          name: 'diffData',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'audit_event_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'audit_event_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'audit_entity_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'entityType',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'entityId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'audit_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'beneficiary',
      dartName: 'Beneficiary',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'phone',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sourceClientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'beneficiary_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'beneficiary_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'beneficiary_display_name_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'displayName',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'beneficiary_source_client_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sourceClientId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'client',
      dartName: 'ClientRecord',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'phone',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'address',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'clientCode',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'creditLimit',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceCheckIntervalDays',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'client_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'client_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'client_display_name_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'displayName',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'conflict_log',
      dartName: 'ConflictLog',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'entityType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ParentEntityType',
        ),
        _i2.ColumnDefinition(
          name: 'entityId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'localPayload',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'remotePayload',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'conflictType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'resolutionStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ConflictStatus',
          columnDefault: '\'PENDING\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'resolvedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'resolutionData',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'conflict_log_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'conflict_log_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'conflict_entity_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'entityType',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'entityId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'conflict_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'resolutionStatus',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'device',
      dartName: 'Device',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'deviceName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'platform',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DevicePlatform',
        ),
        _i2.ColumnDefinition(
          name: 'deviceCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'nextInvoiceSequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'nextReceiptSequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'nextReturnSequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'nextSampleSequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastActiveAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'device_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'device_code_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'deviceCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'expense',
      dartName: 'Expense',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ExpenseCategory',
        ),
        _i2.ColumnDefinition(
          name: 'amount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'expenseDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'expense_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'expense_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'expense_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expenseDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'expense_category_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'category',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'expense_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'free_sample',
      dartName: 'FreeSample',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'localRef',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'officialNo',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'beneficiaryId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'sampleDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'free_sample_fk_0',
          columns: ['beneficiaryId'],
          referenceTable: 'beneficiary',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'free_sample_fk_1',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'free_sample_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_local_ref_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'localRef',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_official_no_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'officialNo',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_beneficiary_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'beneficiaryId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sampleDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'free_sample_line',
      dartName: 'FreeSampleLine',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'sampleId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'productId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'quantity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'free_sample_line_fk_0',
          columns: ['sampleId'],
          referenceTable: 'free_sample',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'free_sample_line_fk_1',
          columns: ['productId'],
          referenceTable: 'product',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'free_sample_line_fk_2',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'free_sample_line_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_line_sample_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sampleId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'free_sample_line_product_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'productId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'local_attachment_staging',
      dartName: 'LocalAttachmentStaging',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'parentEntityType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ParentEntityType',
        ),
        _i2.ColumnDefinition(
          name: 'parentEntityId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'localFilePath',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fileType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fileSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'uploadStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'PENDING\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'local_attachment_staging_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'staging_upload_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'uploadStatus',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'monthly_distribution',
      dartName: 'MonthlyDistribution',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'year',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'month',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'netProfit',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'ownerShare',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'partnerShare',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'marginShare',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'monthly_distribution_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'monthly_distribution_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'monthly_distribution_year_month_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'year',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'month',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'monthly_distribution_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'owner_account',
      dartName: 'OwnerAccount',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'singletonKey',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'owner_account_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'owner_singleton_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'singletonKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'owner_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'party_adjustment',
      dartName: 'PartyAdjustment',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'party',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:PartyAccount',
        ),
        _i2.ColumnDefinition(
          name: 'amount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'adjustmentDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'party_adjustment_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'party_adjustment_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'party_adjustment_party_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'party',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'party_adjustment_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'adjustmentDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'party_adjustment_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'product',
      dartName: 'Product',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'defaultSalePrice',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'unit',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sku',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'shelfLifeDays',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'product_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'product_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'product_name_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'receipt',
      dartName: 'Receipt',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'localRef',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'officialNo',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'receiptType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReceiptType',
        ),
        _i2.ColumnDefinition(
          name: 'clientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'amount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'receiptDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'receipt_fk_0',
          columns: ['clientId'],
          referenceTable: 'client',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'receipt_fk_1',
          columns: ['invoiceId'],
          referenceTable: 'sales_invoice',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'receipt_fk_2',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'receipt_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'receipt_client_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'receipt_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'receiptDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'receipt_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'receipt_official_no_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'officialNo',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'receipt_allocation',
      dartName: 'ReceiptAllocation',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'receiptId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'allocatedAmount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'receipt_allocation_fk_0',
          columns: ['receiptId'],
          referenceTable: 'receipt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'receipt_allocation_fk_1',
          columns: ['invoiceId'],
          referenceTable: 'sales_invoice',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'receipt_allocation_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'allocation_receipt_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'receiptId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'allocation_invoice_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'invoiceId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sales_invoice',
      dartName: 'SalesInvoice',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'localRef',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'officialNo',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'clientId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'discount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'total',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_invoice_fk_0',
          columns: ['clientId'],
          referenceTable: 'client',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_invoice_fk_1',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sales_invoice_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'invoice_local_ref_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'localRef',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'invoice_official_no_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'officialNo',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'invoice_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'invoiceDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'invoice_client_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'invoice_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sales_invoice_line',
      dartName: 'SalesInvoiceLine',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'productId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'quantity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'unitPrice',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'lineTotal',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'productionDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_invoice_line_fk_0',
          columns: ['invoiceId'],
          referenceTable: 'sales_invoice',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_invoice_line_fk_1',
          columns: ['productId'],
          referenceTable: 'product',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sales_invoice_line_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'invoice_line_invoice_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'invoiceId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sales_return',
      dartName: 'SalesReturn',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'localRef',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'officialNo',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'returnDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'totalReturnedAmount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecordStatus',
          columnDefault: '\'ACTIVE\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'voidReason',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncStatus',
          columnDefault: '\'PENDING\'::text',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_return_fk_0',
          columns: ['invoiceId'],
          referenceTable: 'sales_invoice',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_return_fk_1',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sales_return_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'return_invoice_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'invoiceId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'return_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'returnDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'return_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'return_official_no_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'officialNo',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sales_return_line',
      dartName: 'SalesReturnLine',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'returnId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'invoiceLineId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'returnedQuantity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'returnedAmount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_return_line_fk_0',
          columns: ['returnId'],
          referenceTable: 'sales_return',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'sales_return_line_fk_1',
          columns: ['invoiceLineId'],
          referenceTable: 'sales_invoice_line',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sales_return_line_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'return_line_return_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'returnId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sync_cursor',
      dartName: 'SyncCursor',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'entityType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ParentEntityType',
        ),
        _i2.ColumnDefinition(
          name: 'lastPulledAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'lastRowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sync_cursor_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'cursor_entity_type_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'entityType',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'sync_outbox',
      dartName: 'SyncOutbox',
      schema: 'public',
      module: 'motaz_app',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid()',
        ),
        _i2.ColumnDefinition(
          name: 'entityType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ParentEntityType',
        ),
        _i2.ColumnDefinition(
          name: 'entityId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'operation',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AuditOperation',
        ),
        _i2.ColumnDefinition(
          name: 'payload',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'rowVersion',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'deviceId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'retryCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SyncOutboxStatus',
          columnDefault: '\'PENDING\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'sync_outbox_fk_0',
          columns: ['deviceId'],
          referenceTable: 'device',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'sync_outbox_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'outbox_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'outbox_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.AttachmentConfirmRequest) {
      return _i5.AttachmentConfirmRequest.fromJson(data) as T;
    }
    if (t == _i6.AttachmentConfirmResponse) {
      return _i6.AttachmentConfirmResponse.fromJson(data) as T;
    }
    if (t == _i7.AttachmentMetadata) {
      return _i7.AttachmentMetadata.fromJson(data) as T;
    }
    if (t == _i8.AttachmentUploadApproval) {
      return _i8.AttachmentUploadApproval.fromJson(data) as T;
    }
    if (t == _i9.AttachmentUploadRequest) {
      return _i9.AttachmentUploadRequest.fromJson(data) as T;
    }
    if (t == _i10.AuditEvent) {
      return _i10.AuditEvent.fromJson(data) as T;
    }
    if (t == _i11.Beneficiary) {
      return _i11.Beneficiary.fromJson(data) as T;
    }
    if (t == _i12.ClientRecord) {
      return _i12.ClientRecord.fromJson(data) as T;
    }
    if (t == _i13.ConflictLog) {
      return _i13.ConflictLog.fromJson(data) as T;
    }
    if (t == _i14.ConflictPayload) {
      return _i14.ConflictPayload.fromJson(data) as T;
    }
    if (t == _i15.ConflictResolutionRequest) {
      return _i15.ConflictResolutionRequest.fromJson(data) as T;
    }
    if (t == _i16.ConflictResolutionResponse) {
      return _i16.ConflictResolutionResponse.fromJson(data) as T;
    }
    if (t == _i17.Device) {
      return _i17.Device.fromJson(data) as T;
    }
    if (t == _i18.DeviceRegistrationRequest) {
      return _i18.DeviceRegistrationRequest.fromJson(data) as T;
    }
    if (t == _i19.DeviceRegistrationResponse) {
      return _i19.DeviceRegistrationResponse.fromJson(data) as T;
    }
    if (t == _i20.AuditOperation) {
      return _i20.AuditOperation.fromJson(data) as T;
    }
    if (t == _i21.ConflictStatus) {
      return _i21.ConflictStatus.fromJson(data) as T;
    }
    if (t == _i22.DevicePlatform) {
      return _i22.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i23.ExpenseCategory) {
      return _i23.ExpenseCategory.fromJson(data) as T;
    }
    if (t == _i24.ParentEntityType) {
      return _i24.ParentEntityType.fromJson(data) as T;
    }
    if (t == _i25.PartyAccount) {
      return _i25.PartyAccount.fromJson(data) as T;
    }
    if (t == _i26.ReceiptType) {
      return _i26.ReceiptType.fromJson(data) as T;
    }
    if (t == _i27.RecordStatus) {
      return _i27.RecordStatus.fromJson(data) as T;
    }
    if (t == _i28.SyncOutboxStatus) {
      return _i28.SyncOutboxStatus.fromJson(data) as T;
    }
    if (t == _i29.SyncStatus) {
      return _i29.SyncStatus.fromJson(data) as T;
    }
    if (t == _i30.Expense) {
      return _i30.Expense.fromJson(data) as T;
    }
    if (t == _i31.FreeSample) {
      return _i31.FreeSample.fromJson(data) as T;
    }
    if (t == _i32.FreeSampleLine) {
      return _i32.FreeSampleLine.fromJson(data) as T;
    }
    if (t == _i33.Greeting) {
      return _i33.Greeting.fromJson(data) as T;
    }
    if (t == _i34.LocalAttachmentStaging) {
      return _i34.LocalAttachmentStaging.fromJson(data) as T;
    }
    if (t == _i35.MonthlyDistribution) {
      return _i35.MonthlyDistribution.fromJson(data) as T;
    }
    if (t == _i36.OwnerAccount) {
      return _i36.OwnerAccount.fromJson(data) as T;
    }
    if (t == _i37.PartyAdjustment) {
      return _i37.PartyAdjustment.fromJson(data) as T;
    }
    if (t == _i38.Product) {
      return _i38.Product.fromJson(data) as T;
    }
    if (t == _i39.PullRequest) {
      return _i39.PullRequest.fromJson(data) as T;
    }
    if (t == _i40.PullResponse) {
      return _i40.PullResponse.fromJson(data) as T;
    }
    if (t == _i41.PushRequest) {
      return _i41.PushRequest.fromJson(data) as T;
    }
    if (t == _i42.PushResponse) {
      return _i42.PushResponse.fromJson(data) as T;
    }
    if (t == _i43.Receipt) {
      return _i43.Receipt.fromJson(data) as T;
    }
    if (t == _i44.ReceiptAllocation) {
      return _i44.ReceiptAllocation.fromJson(data) as T;
    }
    if (t == _i45.SalesInvoice) {
      return _i45.SalesInvoice.fromJson(data) as T;
    }
    if (t == _i46.SalesInvoiceLine) {
      return _i46.SalesInvoiceLine.fromJson(data) as T;
    }
    if (t == _i47.SalesReturn) {
      return _i47.SalesReturn.fromJson(data) as T;
    }
    if (t == _i48.SalesReturnLine) {
      return _i48.SalesReturnLine.fromJson(data) as T;
    }
    if (t == _i49.SyncCursor) {
      return _i49.SyncCursor.fromJson(data) as T;
    }
    if (t == _i50.SyncOutbox) {
      return _i50.SyncOutbox.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AttachmentConfirmRequest?>()) {
      return (data != null ? _i5.AttachmentConfirmRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.AttachmentConfirmResponse?>()) {
      return (data != null
              ? _i6.AttachmentConfirmResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i7.AttachmentMetadata?>()) {
      return (data != null ? _i7.AttachmentMetadata.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AttachmentUploadApproval?>()) {
      return (data != null ? _i8.AttachmentUploadApproval.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.AttachmentUploadRequest?>()) {
      return (data != null ? _i9.AttachmentUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.AuditEvent?>()) {
      return (data != null ? _i10.AuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Beneficiary?>()) {
      return (data != null ? _i11.Beneficiary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ClientRecord?>()) {
      return (data != null ? _i12.ClientRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ConflictLog?>()) {
      return (data != null ? _i13.ConflictLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ConflictPayload?>()) {
      return (data != null ? _i14.ConflictPayload.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ConflictResolutionRequest?>()) {
      return (data != null
              ? _i15.ConflictResolutionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i16.ConflictResolutionResponse?>()) {
      return (data != null
              ? _i16.ConflictResolutionResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.Device?>()) {
      return (data != null ? _i17.Device.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.DeviceRegistrationRequest?>()) {
      return (data != null
              ? _i18.DeviceRegistrationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i19.DeviceRegistrationResponse?>()) {
      return (data != null
              ? _i19.DeviceRegistrationResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.AuditOperation?>()) {
      return (data != null ? _i20.AuditOperation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ConflictStatus?>()) {
      return (data != null ? _i21.ConflictStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.DevicePlatform?>()) {
      return (data != null ? _i22.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ExpenseCategory?>()) {
      return (data != null ? _i23.ExpenseCategory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ParentEntityType?>()) {
      return (data != null ? _i24.ParentEntityType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.PartyAccount?>()) {
      return (data != null ? _i25.PartyAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ReceiptType?>()) {
      return (data != null ? _i26.ReceiptType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.RecordStatus?>()) {
      return (data != null ? _i27.RecordStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.SyncOutboxStatus?>()) {
      return (data != null ? _i28.SyncOutboxStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.SyncStatus?>()) {
      return (data != null ? _i29.SyncStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.Expense?>()) {
      return (data != null ? _i30.Expense.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.FreeSample?>()) {
      return (data != null ? _i31.FreeSample.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.FreeSampleLine?>()) {
      return (data != null ? _i32.FreeSampleLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.Greeting?>()) {
      return (data != null ? _i33.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.LocalAttachmentStaging?>()) {
      return (data != null ? _i34.LocalAttachmentStaging.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i35.MonthlyDistribution?>()) {
      return (data != null ? _i35.MonthlyDistribution.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i36.OwnerAccount?>()) {
      return (data != null ? _i36.OwnerAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.PartyAdjustment?>()) {
      return (data != null ? _i37.PartyAdjustment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.Product?>()) {
      return (data != null ? _i38.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.PullRequest?>()) {
      return (data != null ? _i39.PullRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.PullResponse?>()) {
      return (data != null ? _i40.PullResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.PushRequest?>()) {
      return (data != null ? _i41.PushRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.PushResponse?>()) {
      return (data != null ? _i42.PushResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.Receipt?>()) {
      return (data != null ? _i43.Receipt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.ReceiptAllocation?>()) {
      return (data != null ? _i44.ReceiptAllocation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.SalesInvoice?>()) {
      return (data != null ? _i45.SalesInvoice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.SalesInvoiceLine?>()) {
      return (data != null ? _i46.SalesInvoiceLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.SalesReturn?>()) {
      return (data != null ? _i47.SalesReturn.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.SalesReturnLine?>()) {
      return (data != null ? _i48.SalesReturnLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i49.SyncCursor?>()) {
      return (data != null ? _i49.SyncCursor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i50.SyncOutbox?>()) {
      return (data != null ? _i50.SyncOutbox.fromJson(data) : null) as T;
    }
    if (t == List<_i50.SyncOutbox>) {
      return (data as List).map((e) => deserialize<_i50.SyncOutbox>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i50.SyncOutbox>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i50.SyncOutbox>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i51.ConflictLog>) {
      return (data as List)
              .map((e) => deserialize<_i51.ConflictLog>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.AttachmentConfirmRequest => 'AttachmentConfirmRequest',
      _i6.AttachmentConfirmResponse => 'AttachmentConfirmResponse',
      _i7.AttachmentMetadata => 'AttachmentMetadata',
      _i8.AttachmentUploadApproval => 'AttachmentUploadApproval',
      _i9.AttachmentUploadRequest => 'AttachmentUploadRequest',
      _i10.AuditEvent => 'AuditEvent',
      _i11.Beneficiary => 'Beneficiary',
      _i12.ClientRecord => 'ClientRecord',
      _i13.ConflictLog => 'ConflictLog',
      _i14.ConflictPayload => 'ConflictPayload',
      _i15.ConflictResolutionRequest => 'ConflictResolutionRequest',
      _i16.ConflictResolutionResponse => 'ConflictResolutionResponse',
      _i17.Device => 'Device',
      _i18.DeviceRegistrationRequest => 'DeviceRegistrationRequest',
      _i19.DeviceRegistrationResponse => 'DeviceRegistrationResponse',
      _i20.AuditOperation => 'AuditOperation',
      _i21.ConflictStatus => 'ConflictStatus',
      _i22.DevicePlatform => 'DevicePlatform',
      _i23.ExpenseCategory => 'ExpenseCategory',
      _i24.ParentEntityType => 'ParentEntityType',
      _i25.PartyAccount => 'PartyAccount',
      _i26.ReceiptType => 'ReceiptType',
      _i27.RecordStatus => 'RecordStatus',
      _i28.SyncOutboxStatus => 'SyncOutboxStatus',
      _i29.SyncStatus => 'SyncStatus',
      _i30.Expense => 'Expense',
      _i31.FreeSample => 'FreeSample',
      _i32.FreeSampleLine => 'FreeSampleLine',
      _i33.Greeting => 'Greeting',
      _i34.LocalAttachmentStaging => 'LocalAttachmentStaging',
      _i35.MonthlyDistribution => 'MonthlyDistribution',
      _i36.OwnerAccount => 'OwnerAccount',
      _i37.PartyAdjustment => 'PartyAdjustment',
      _i38.Product => 'Product',
      _i39.PullRequest => 'PullRequest',
      _i40.PullResponse => 'PullResponse',
      _i41.PushRequest => 'PushRequest',
      _i42.PushResponse => 'PushResponse',
      _i43.Receipt => 'Receipt',
      _i44.ReceiptAllocation => 'ReceiptAllocation',
      _i45.SalesInvoice => 'SalesInvoice',
      _i46.SalesInvoiceLine => 'SalesInvoiceLine',
      _i47.SalesReturn => 'SalesReturn',
      _i48.SalesReturnLine => 'SalesReturnLine',
      _i49.SyncCursor => 'SyncCursor',
      _i50.SyncOutbox => 'SyncOutbox',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('motaz_app.', '');
    }

    switch (data) {
      case _i5.AttachmentConfirmRequest():
        return 'AttachmentConfirmRequest';
      case _i6.AttachmentConfirmResponse():
        return 'AttachmentConfirmResponse';
      case _i7.AttachmentMetadata():
        return 'AttachmentMetadata';
      case _i8.AttachmentUploadApproval():
        return 'AttachmentUploadApproval';
      case _i9.AttachmentUploadRequest():
        return 'AttachmentUploadRequest';
      case _i10.AuditEvent():
        return 'AuditEvent';
      case _i11.Beneficiary():
        return 'Beneficiary';
      case _i12.ClientRecord():
        return 'ClientRecord';
      case _i13.ConflictLog():
        return 'ConflictLog';
      case _i14.ConflictPayload():
        return 'ConflictPayload';
      case _i15.ConflictResolutionRequest():
        return 'ConflictResolutionRequest';
      case _i16.ConflictResolutionResponse():
        return 'ConflictResolutionResponse';
      case _i17.Device():
        return 'Device';
      case _i18.DeviceRegistrationRequest():
        return 'DeviceRegistrationRequest';
      case _i19.DeviceRegistrationResponse():
        return 'DeviceRegistrationResponse';
      case _i20.AuditOperation():
        return 'AuditOperation';
      case _i21.ConflictStatus():
        return 'ConflictStatus';
      case _i22.DevicePlatform():
        return 'DevicePlatform';
      case _i23.ExpenseCategory():
        return 'ExpenseCategory';
      case _i24.ParentEntityType():
        return 'ParentEntityType';
      case _i25.PartyAccount():
        return 'PartyAccount';
      case _i26.ReceiptType():
        return 'ReceiptType';
      case _i27.RecordStatus():
        return 'RecordStatus';
      case _i28.SyncOutboxStatus():
        return 'SyncOutboxStatus';
      case _i29.SyncStatus():
        return 'SyncStatus';
      case _i30.Expense():
        return 'Expense';
      case _i31.FreeSample():
        return 'FreeSample';
      case _i32.FreeSampleLine():
        return 'FreeSampleLine';
      case _i33.Greeting():
        return 'Greeting';
      case _i34.LocalAttachmentStaging():
        return 'LocalAttachmentStaging';
      case _i35.MonthlyDistribution():
        return 'MonthlyDistribution';
      case _i36.OwnerAccount():
        return 'OwnerAccount';
      case _i37.PartyAdjustment():
        return 'PartyAdjustment';
      case _i38.Product():
        return 'Product';
      case _i39.PullRequest():
        return 'PullRequest';
      case _i40.PullResponse():
        return 'PullResponse';
      case _i41.PushRequest():
        return 'PushRequest';
      case _i42.PushResponse():
        return 'PushResponse';
      case _i43.Receipt():
        return 'Receipt';
      case _i44.ReceiptAllocation():
        return 'ReceiptAllocation';
      case _i45.SalesInvoice():
        return 'SalesInvoice';
      case _i46.SalesInvoiceLine():
        return 'SalesInvoiceLine';
      case _i47.SalesReturn():
        return 'SalesReturn';
      case _i48.SalesReturnLine():
        return 'SalesReturnLine';
      case _i49.SyncCursor():
        return 'SyncCursor';
      case _i50.SyncOutbox():
        return 'SyncOutbox';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AttachmentConfirmRequest') {
      return deserialize<_i5.AttachmentConfirmRequest>(data['data']);
    }
    if (dataClassName == 'AttachmentConfirmResponse') {
      return deserialize<_i6.AttachmentConfirmResponse>(data['data']);
    }
    if (dataClassName == 'AttachmentMetadata') {
      return deserialize<_i7.AttachmentMetadata>(data['data']);
    }
    if (dataClassName == 'AttachmentUploadApproval') {
      return deserialize<_i8.AttachmentUploadApproval>(data['data']);
    }
    if (dataClassName == 'AttachmentUploadRequest') {
      return deserialize<_i9.AttachmentUploadRequest>(data['data']);
    }
    if (dataClassName == 'AuditEvent') {
      return deserialize<_i10.AuditEvent>(data['data']);
    }
    if (dataClassName == 'Beneficiary') {
      return deserialize<_i11.Beneficiary>(data['data']);
    }
    if (dataClassName == 'ClientRecord') {
      return deserialize<_i12.ClientRecord>(data['data']);
    }
    if (dataClassName == 'ConflictLog') {
      return deserialize<_i13.ConflictLog>(data['data']);
    }
    if (dataClassName == 'ConflictPayload') {
      return deserialize<_i14.ConflictPayload>(data['data']);
    }
    if (dataClassName == 'ConflictResolutionRequest') {
      return deserialize<_i15.ConflictResolutionRequest>(data['data']);
    }
    if (dataClassName == 'ConflictResolutionResponse') {
      return deserialize<_i16.ConflictResolutionResponse>(data['data']);
    }
    if (dataClassName == 'Device') {
      return deserialize<_i17.Device>(data['data']);
    }
    if (dataClassName == 'DeviceRegistrationRequest') {
      return deserialize<_i18.DeviceRegistrationRequest>(data['data']);
    }
    if (dataClassName == 'DeviceRegistrationResponse') {
      return deserialize<_i19.DeviceRegistrationResponse>(data['data']);
    }
    if (dataClassName == 'AuditOperation') {
      return deserialize<_i20.AuditOperation>(data['data']);
    }
    if (dataClassName == 'ConflictStatus') {
      return deserialize<_i21.ConflictStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i22.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'ExpenseCategory') {
      return deserialize<_i23.ExpenseCategory>(data['data']);
    }
    if (dataClassName == 'ParentEntityType') {
      return deserialize<_i24.ParentEntityType>(data['data']);
    }
    if (dataClassName == 'PartyAccount') {
      return deserialize<_i25.PartyAccount>(data['data']);
    }
    if (dataClassName == 'ReceiptType') {
      return deserialize<_i26.ReceiptType>(data['data']);
    }
    if (dataClassName == 'RecordStatus') {
      return deserialize<_i27.RecordStatus>(data['data']);
    }
    if (dataClassName == 'SyncOutboxStatus') {
      return deserialize<_i28.SyncOutboxStatus>(data['data']);
    }
    if (dataClassName == 'SyncStatus') {
      return deserialize<_i29.SyncStatus>(data['data']);
    }
    if (dataClassName == 'Expense') {
      return deserialize<_i30.Expense>(data['data']);
    }
    if (dataClassName == 'FreeSample') {
      return deserialize<_i31.FreeSample>(data['data']);
    }
    if (dataClassName == 'FreeSampleLine') {
      return deserialize<_i32.FreeSampleLine>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i33.Greeting>(data['data']);
    }
    if (dataClassName == 'LocalAttachmentStaging') {
      return deserialize<_i34.LocalAttachmentStaging>(data['data']);
    }
    if (dataClassName == 'MonthlyDistribution') {
      return deserialize<_i35.MonthlyDistribution>(data['data']);
    }
    if (dataClassName == 'OwnerAccount') {
      return deserialize<_i36.OwnerAccount>(data['data']);
    }
    if (dataClassName == 'PartyAdjustment') {
      return deserialize<_i37.PartyAdjustment>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i38.Product>(data['data']);
    }
    if (dataClassName == 'PullRequest') {
      return deserialize<_i39.PullRequest>(data['data']);
    }
    if (dataClassName == 'PullResponse') {
      return deserialize<_i40.PullResponse>(data['data']);
    }
    if (dataClassName == 'PushRequest') {
      return deserialize<_i41.PushRequest>(data['data']);
    }
    if (dataClassName == 'PushResponse') {
      return deserialize<_i42.PushResponse>(data['data']);
    }
    if (dataClassName == 'Receipt') {
      return deserialize<_i43.Receipt>(data['data']);
    }
    if (dataClassName == 'ReceiptAllocation') {
      return deserialize<_i44.ReceiptAllocation>(data['data']);
    }
    if (dataClassName == 'SalesInvoice') {
      return deserialize<_i45.SalesInvoice>(data['data']);
    }
    if (dataClassName == 'SalesInvoiceLine') {
      return deserialize<_i46.SalesInvoiceLine>(data['data']);
    }
    if (dataClassName == 'SalesReturn') {
      return deserialize<_i47.SalesReturn>(data['data']);
    }
    if (dataClassName == 'SalesReturnLine') {
      return deserialize<_i48.SalesReturnLine>(data['data']);
    }
    if (dataClassName == 'SyncCursor') {
      return deserialize<_i49.SyncCursor>(data['data']);
    }
    if (dataClassName == 'SyncOutbox') {
      return deserialize<_i50.SyncOutbox>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i7.AttachmentMetadata:
        return _i7.AttachmentMetadata.t;
      case _i10.AuditEvent:
        return _i10.AuditEvent.t;
      case _i11.Beneficiary:
        return _i11.Beneficiary.t;
      case _i12.ClientRecord:
        return _i12.ClientRecord.t;
      case _i13.ConflictLog:
        return _i13.ConflictLog.t;
      case _i17.Device:
        return _i17.Device.t;
      case _i30.Expense:
        return _i30.Expense.t;
      case _i31.FreeSample:
        return _i31.FreeSample.t;
      case _i32.FreeSampleLine:
        return _i32.FreeSampleLine.t;
      case _i34.LocalAttachmentStaging:
        return _i34.LocalAttachmentStaging.t;
      case _i35.MonthlyDistribution:
        return _i35.MonthlyDistribution.t;
      case _i36.OwnerAccount:
        return _i36.OwnerAccount.t;
      case _i37.PartyAdjustment:
        return _i37.PartyAdjustment.t;
      case _i38.Product:
        return _i38.Product.t;
      case _i43.Receipt:
        return _i43.Receipt.t;
      case _i44.ReceiptAllocation:
        return _i44.ReceiptAllocation.t;
      case _i45.SalesInvoice:
        return _i45.SalesInvoice.t;
      case _i46.SalesInvoiceLine:
        return _i46.SalesInvoiceLine.t;
      case _i47.SalesReturn:
        return _i47.SalesReturn.t;
      case _i48.SalesReturnLine:
        return _i48.SalesReturnLine.t;
      case _i49.SyncCursor:
        return _i49.SyncCursor.t;
      case _i50.SyncOutbox:
        return _i50.SyncOutbox.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'motaz_app';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
