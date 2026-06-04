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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'attachment_confirm_request.dart' as _i2;
import 'attachment_confirm_response.dart' as _i3;
import 'attachment_metadata.dart' as _i4;
import 'attachment_upload_approval.dart' as _i5;
import 'attachment_upload_request.dart' as _i6;
import 'audit_event.dart' as _i7;
import 'beneficiary.dart' as _i8;
import 'client_record.dart' as _i9;
import 'conflict_log.dart' as _i10;
import 'conflict_payload.dart' as _i11;
import 'conflict_resolution_request.dart' as _i12;
import 'conflict_resolution_response.dart' as _i13;
import 'device.dart' as _i14;
import 'device_registration_request.dart' as _i15;
import 'device_registration_response.dart' as _i16;
import 'enums/audit_operation.dart' as _i17;
import 'enums/conflict_status.dart' as _i18;
import 'enums/device_platform.dart' as _i19;
import 'enums/expense_category.dart' as _i20;
import 'enums/parent_entity_type.dart' as _i21;
import 'enums/party_account.dart' as _i22;
import 'enums/receipt_type.dart' as _i23;
import 'enums/record_status.dart' as _i24;
import 'enums/sync_outbox_status.dart' as _i25;
import 'enums/sync_status.dart' as _i26;
import 'expense.dart' as _i27;
import 'free_sample.dart' as _i28;
import 'free_sample_line.dart' as _i29;
import 'greetings/greeting.dart' as _i30;
import 'local_attachment_staging.dart' as _i31;
import 'monthly_distribution.dart' as _i32;
import 'owner_account.dart' as _i33;
import 'party_adjustment.dart' as _i34;
import 'product.dart' as _i35;
import 'pull_request.dart' as _i36;
import 'pull_response.dart' as _i37;
import 'push_request.dart' as _i38;
import 'push_response.dart' as _i39;
import 'receipt.dart' as _i40;
import 'receipt_allocation.dart' as _i41;
import 'sales_invoice.dart' as _i42;
import 'sales_invoice_line.dart' as _i43;
import 'sales_return.dart' as _i44;
import 'sales_return_line.dart' as _i45;
import 'sync_cursor.dart' as _i46;
import 'sync_outbox.dart' as _i47;
import 'package:motaz_app_client/src/protocol/conflict_log.dart' as _i48;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i49;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i50;
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
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

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

    if (t == _i2.AttachmentConfirmRequest) {
      return _i2.AttachmentConfirmRequest.fromJson(data) as T;
    }
    if (t == _i3.AttachmentConfirmResponse) {
      return _i3.AttachmentConfirmResponse.fromJson(data) as T;
    }
    if (t == _i4.AttachmentMetadata) {
      return _i4.AttachmentMetadata.fromJson(data) as T;
    }
    if (t == _i5.AttachmentUploadApproval) {
      return _i5.AttachmentUploadApproval.fromJson(data) as T;
    }
    if (t == _i6.AttachmentUploadRequest) {
      return _i6.AttachmentUploadRequest.fromJson(data) as T;
    }
    if (t == _i7.AuditEvent) {
      return _i7.AuditEvent.fromJson(data) as T;
    }
    if (t == _i8.Beneficiary) {
      return _i8.Beneficiary.fromJson(data) as T;
    }
    if (t == _i9.ClientRecord) {
      return _i9.ClientRecord.fromJson(data) as T;
    }
    if (t == _i10.ConflictLog) {
      return _i10.ConflictLog.fromJson(data) as T;
    }
    if (t == _i11.ConflictPayload) {
      return _i11.ConflictPayload.fromJson(data) as T;
    }
    if (t == _i12.ConflictResolutionRequest) {
      return _i12.ConflictResolutionRequest.fromJson(data) as T;
    }
    if (t == _i13.ConflictResolutionResponse) {
      return _i13.ConflictResolutionResponse.fromJson(data) as T;
    }
    if (t == _i14.Device) {
      return _i14.Device.fromJson(data) as T;
    }
    if (t == _i15.DeviceRegistrationRequest) {
      return _i15.DeviceRegistrationRequest.fromJson(data) as T;
    }
    if (t == _i16.DeviceRegistrationResponse) {
      return _i16.DeviceRegistrationResponse.fromJson(data) as T;
    }
    if (t == _i17.AuditOperation) {
      return _i17.AuditOperation.fromJson(data) as T;
    }
    if (t == _i18.ConflictStatus) {
      return _i18.ConflictStatus.fromJson(data) as T;
    }
    if (t == _i19.DevicePlatform) {
      return _i19.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i20.ExpenseCategory) {
      return _i20.ExpenseCategory.fromJson(data) as T;
    }
    if (t == _i21.ParentEntityType) {
      return _i21.ParentEntityType.fromJson(data) as T;
    }
    if (t == _i22.PartyAccount) {
      return _i22.PartyAccount.fromJson(data) as T;
    }
    if (t == _i23.ReceiptType) {
      return _i23.ReceiptType.fromJson(data) as T;
    }
    if (t == _i24.RecordStatus) {
      return _i24.RecordStatus.fromJson(data) as T;
    }
    if (t == _i25.SyncOutboxStatus) {
      return _i25.SyncOutboxStatus.fromJson(data) as T;
    }
    if (t == _i26.SyncStatus) {
      return _i26.SyncStatus.fromJson(data) as T;
    }
    if (t == _i27.Expense) {
      return _i27.Expense.fromJson(data) as T;
    }
    if (t == _i28.FreeSample) {
      return _i28.FreeSample.fromJson(data) as T;
    }
    if (t == _i29.FreeSampleLine) {
      return _i29.FreeSampleLine.fromJson(data) as T;
    }
    if (t == _i30.Greeting) {
      return _i30.Greeting.fromJson(data) as T;
    }
    if (t == _i31.LocalAttachmentStaging) {
      return _i31.LocalAttachmentStaging.fromJson(data) as T;
    }
    if (t == _i32.MonthlyDistribution) {
      return _i32.MonthlyDistribution.fromJson(data) as T;
    }
    if (t == _i33.OwnerAccount) {
      return _i33.OwnerAccount.fromJson(data) as T;
    }
    if (t == _i34.PartyAdjustment) {
      return _i34.PartyAdjustment.fromJson(data) as T;
    }
    if (t == _i35.Product) {
      return _i35.Product.fromJson(data) as T;
    }
    if (t == _i36.PullRequest) {
      return _i36.PullRequest.fromJson(data) as T;
    }
    if (t == _i37.PullResponse) {
      return _i37.PullResponse.fromJson(data) as T;
    }
    if (t == _i38.PushRequest) {
      return _i38.PushRequest.fromJson(data) as T;
    }
    if (t == _i39.PushResponse) {
      return _i39.PushResponse.fromJson(data) as T;
    }
    if (t == _i40.Receipt) {
      return _i40.Receipt.fromJson(data) as T;
    }
    if (t == _i41.ReceiptAllocation) {
      return _i41.ReceiptAllocation.fromJson(data) as T;
    }
    if (t == _i42.SalesInvoice) {
      return _i42.SalesInvoice.fromJson(data) as T;
    }
    if (t == _i43.SalesInvoiceLine) {
      return _i43.SalesInvoiceLine.fromJson(data) as T;
    }
    if (t == _i44.SalesReturn) {
      return _i44.SalesReturn.fromJson(data) as T;
    }
    if (t == _i45.SalesReturnLine) {
      return _i45.SalesReturnLine.fromJson(data) as T;
    }
    if (t == _i46.SyncCursor) {
      return _i46.SyncCursor.fromJson(data) as T;
    }
    if (t == _i47.SyncOutbox) {
      return _i47.SyncOutbox.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AttachmentConfirmRequest?>()) {
      return (data != null ? _i2.AttachmentConfirmRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.AttachmentConfirmResponse?>()) {
      return (data != null
              ? _i3.AttachmentConfirmResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i4.AttachmentMetadata?>()) {
      return (data != null ? _i4.AttachmentMetadata.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AttachmentUploadApproval?>()) {
      return (data != null ? _i5.AttachmentUploadApproval.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.AttachmentUploadRequest?>()) {
      return (data != null ? _i6.AttachmentUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.AuditEvent?>()) {
      return (data != null ? _i7.AuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Beneficiary?>()) {
      return (data != null ? _i8.Beneficiary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ClientRecord?>()) {
      return (data != null ? _i9.ClientRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ConflictLog?>()) {
      return (data != null ? _i10.ConflictLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.ConflictPayload?>()) {
      return (data != null ? _i11.ConflictPayload.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ConflictResolutionRequest?>()) {
      return (data != null
              ? _i12.ConflictResolutionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i13.ConflictResolutionResponse?>()) {
      return (data != null
              ? _i13.ConflictResolutionResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.Device?>()) {
      return (data != null ? _i14.Device.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.DeviceRegistrationRequest?>()) {
      return (data != null
              ? _i15.DeviceRegistrationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i16.DeviceRegistrationResponse?>()) {
      return (data != null
              ? _i16.DeviceRegistrationResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i17.AuditOperation?>()) {
      return (data != null ? _i17.AuditOperation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ConflictStatus?>()) {
      return (data != null ? _i18.ConflictStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.DevicePlatform?>()) {
      return (data != null ? _i19.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ExpenseCategory?>()) {
      return (data != null ? _i20.ExpenseCategory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ParentEntityType?>()) {
      return (data != null ? _i21.ParentEntityType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.PartyAccount?>()) {
      return (data != null ? _i22.PartyAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ReceiptType?>()) {
      return (data != null ? _i23.ReceiptType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.RecordStatus?>()) {
      return (data != null ? _i24.RecordStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.SyncOutboxStatus?>()) {
      return (data != null ? _i25.SyncOutboxStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.SyncStatus?>()) {
      return (data != null ? _i26.SyncStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.Expense?>()) {
      return (data != null ? _i27.Expense.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.FreeSample?>()) {
      return (data != null ? _i28.FreeSample.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.FreeSampleLine?>()) {
      return (data != null ? _i29.FreeSampleLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.Greeting?>()) {
      return (data != null ? _i30.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.LocalAttachmentStaging?>()) {
      return (data != null ? _i31.LocalAttachmentStaging.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.MonthlyDistribution?>()) {
      return (data != null ? _i32.MonthlyDistribution.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i33.OwnerAccount?>()) {
      return (data != null ? _i33.OwnerAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.PartyAdjustment?>()) {
      return (data != null ? _i34.PartyAdjustment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.Product?>()) {
      return (data != null ? _i35.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.PullRequest?>()) {
      return (data != null ? _i36.PullRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.PullResponse?>()) {
      return (data != null ? _i37.PullResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.PushRequest?>()) {
      return (data != null ? _i38.PushRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.PushResponse?>()) {
      return (data != null ? _i39.PushResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.Receipt?>()) {
      return (data != null ? _i40.Receipt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.ReceiptAllocation?>()) {
      return (data != null ? _i41.ReceiptAllocation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.SalesInvoice?>()) {
      return (data != null ? _i42.SalesInvoice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.SalesInvoiceLine?>()) {
      return (data != null ? _i43.SalesInvoiceLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.SalesReturn?>()) {
      return (data != null ? _i44.SalesReturn.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.SalesReturnLine?>()) {
      return (data != null ? _i45.SalesReturnLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.SyncCursor?>()) {
      return (data != null ? _i46.SyncCursor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.SyncOutbox?>()) {
      return (data != null ? _i47.SyncOutbox.fromJson(data) : null) as T;
    }
    if (t == List<_i47.SyncOutbox>) {
      return (data as List).map((e) => deserialize<_i47.SyncOutbox>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i47.SyncOutbox>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i47.SyncOutbox>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i48.ConflictLog>) {
      return (data as List)
              .map((e) => deserialize<_i48.ConflictLog>(e))
              .toList()
          as T;
    }
    try {
      return _i49.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i50.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AttachmentConfirmRequest => 'AttachmentConfirmRequest',
      _i3.AttachmentConfirmResponse => 'AttachmentConfirmResponse',
      _i4.AttachmentMetadata => 'AttachmentMetadata',
      _i5.AttachmentUploadApproval => 'AttachmentUploadApproval',
      _i6.AttachmentUploadRequest => 'AttachmentUploadRequest',
      _i7.AuditEvent => 'AuditEvent',
      _i8.Beneficiary => 'Beneficiary',
      _i9.ClientRecord => 'ClientRecord',
      _i10.ConflictLog => 'ConflictLog',
      _i11.ConflictPayload => 'ConflictPayload',
      _i12.ConflictResolutionRequest => 'ConflictResolutionRequest',
      _i13.ConflictResolutionResponse => 'ConflictResolutionResponse',
      _i14.Device => 'Device',
      _i15.DeviceRegistrationRequest => 'DeviceRegistrationRequest',
      _i16.DeviceRegistrationResponse => 'DeviceRegistrationResponse',
      _i17.AuditOperation => 'AuditOperation',
      _i18.ConflictStatus => 'ConflictStatus',
      _i19.DevicePlatform => 'DevicePlatform',
      _i20.ExpenseCategory => 'ExpenseCategory',
      _i21.ParentEntityType => 'ParentEntityType',
      _i22.PartyAccount => 'PartyAccount',
      _i23.ReceiptType => 'ReceiptType',
      _i24.RecordStatus => 'RecordStatus',
      _i25.SyncOutboxStatus => 'SyncOutboxStatus',
      _i26.SyncStatus => 'SyncStatus',
      _i27.Expense => 'Expense',
      _i28.FreeSample => 'FreeSample',
      _i29.FreeSampleLine => 'FreeSampleLine',
      _i30.Greeting => 'Greeting',
      _i31.LocalAttachmentStaging => 'LocalAttachmentStaging',
      _i32.MonthlyDistribution => 'MonthlyDistribution',
      _i33.OwnerAccount => 'OwnerAccount',
      _i34.PartyAdjustment => 'PartyAdjustment',
      _i35.Product => 'Product',
      _i36.PullRequest => 'PullRequest',
      _i37.PullResponse => 'PullResponse',
      _i38.PushRequest => 'PushRequest',
      _i39.PushResponse => 'PushResponse',
      _i40.Receipt => 'Receipt',
      _i41.ReceiptAllocation => 'ReceiptAllocation',
      _i42.SalesInvoice => 'SalesInvoice',
      _i43.SalesInvoiceLine => 'SalesInvoiceLine',
      _i44.SalesReturn => 'SalesReturn',
      _i45.SalesReturnLine => 'SalesReturnLine',
      _i46.SyncCursor => 'SyncCursor',
      _i47.SyncOutbox => 'SyncOutbox',
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
      case _i2.AttachmentConfirmRequest():
        return 'AttachmentConfirmRequest';
      case _i3.AttachmentConfirmResponse():
        return 'AttachmentConfirmResponse';
      case _i4.AttachmentMetadata():
        return 'AttachmentMetadata';
      case _i5.AttachmentUploadApproval():
        return 'AttachmentUploadApproval';
      case _i6.AttachmentUploadRequest():
        return 'AttachmentUploadRequest';
      case _i7.AuditEvent():
        return 'AuditEvent';
      case _i8.Beneficiary():
        return 'Beneficiary';
      case _i9.ClientRecord():
        return 'ClientRecord';
      case _i10.ConflictLog():
        return 'ConflictLog';
      case _i11.ConflictPayload():
        return 'ConflictPayload';
      case _i12.ConflictResolutionRequest():
        return 'ConflictResolutionRequest';
      case _i13.ConflictResolutionResponse():
        return 'ConflictResolutionResponse';
      case _i14.Device():
        return 'Device';
      case _i15.DeviceRegistrationRequest():
        return 'DeviceRegistrationRequest';
      case _i16.DeviceRegistrationResponse():
        return 'DeviceRegistrationResponse';
      case _i17.AuditOperation():
        return 'AuditOperation';
      case _i18.ConflictStatus():
        return 'ConflictStatus';
      case _i19.DevicePlatform():
        return 'DevicePlatform';
      case _i20.ExpenseCategory():
        return 'ExpenseCategory';
      case _i21.ParentEntityType():
        return 'ParentEntityType';
      case _i22.PartyAccount():
        return 'PartyAccount';
      case _i23.ReceiptType():
        return 'ReceiptType';
      case _i24.RecordStatus():
        return 'RecordStatus';
      case _i25.SyncOutboxStatus():
        return 'SyncOutboxStatus';
      case _i26.SyncStatus():
        return 'SyncStatus';
      case _i27.Expense():
        return 'Expense';
      case _i28.FreeSample():
        return 'FreeSample';
      case _i29.FreeSampleLine():
        return 'FreeSampleLine';
      case _i30.Greeting():
        return 'Greeting';
      case _i31.LocalAttachmentStaging():
        return 'LocalAttachmentStaging';
      case _i32.MonthlyDistribution():
        return 'MonthlyDistribution';
      case _i33.OwnerAccount():
        return 'OwnerAccount';
      case _i34.PartyAdjustment():
        return 'PartyAdjustment';
      case _i35.Product():
        return 'Product';
      case _i36.PullRequest():
        return 'PullRequest';
      case _i37.PullResponse():
        return 'PullResponse';
      case _i38.PushRequest():
        return 'PushRequest';
      case _i39.PushResponse():
        return 'PushResponse';
      case _i40.Receipt():
        return 'Receipt';
      case _i41.ReceiptAllocation():
        return 'ReceiptAllocation';
      case _i42.SalesInvoice():
        return 'SalesInvoice';
      case _i43.SalesInvoiceLine():
        return 'SalesInvoiceLine';
      case _i44.SalesReturn():
        return 'SalesReturn';
      case _i45.SalesReturnLine():
        return 'SalesReturnLine';
      case _i46.SyncCursor():
        return 'SyncCursor';
      case _i47.SyncOutbox():
        return 'SyncOutbox';
    }
    className = _i49.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i50.Protocol().getClassNameForObject(data);
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
      return deserialize<_i2.AttachmentConfirmRequest>(data['data']);
    }
    if (dataClassName == 'AttachmentConfirmResponse') {
      return deserialize<_i3.AttachmentConfirmResponse>(data['data']);
    }
    if (dataClassName == 'AttachmentMetadata') {
      return deserialize<_i4.AttachmentMetadata>(data['data']);
    }
    if (dataClassName == 'AttachmentUploadApproval') {
      return deserialize<_i5.AttachmentUploadApproval>(data['data']);
    }
    if (dataClassName == 'AttachmentUploadRequest') {
      return deserialize<_i6.AttachmentUploadRequest>(data['data']);
    }
    if (dataClassName == 'AuditEvent') {
      return deserialize<_i7.AuditEvent>(data['data']);
    }
    if (dataClassName == 'Beneficiary') {
      return deserialize<_i8.Beneficiary>(data['data']);
    }
    if (dataClassName == 'ClientRecord') {
      return deserialize<_i9.ClientRecord>(data['data']);
    }
    if (dataClassName == 'ConflictLog') {
      return deserialize<_i10.ConflictLog>(data['data']);
    }
    if (dataClassName == 'ConflictPayload') {
      return deserialize<_i11.ConflictPayload>(data['data']);
    }
    if (dataClassName == 'ConflictResolutionRequest') {
      return deserialize<_i12.ConflictResolutionRequest>(data['data']);
    }
    if (dataClassName == 'ConflictResolutionResponse') {
      return deserialize<_i13.ConflictResolutionResponse>(data['data']);
    }
    if (dataClassName == 'Device') {
      return deserialize<_i14.Device>(data['data']);
    }
    if (dataClassName == 'DeviceRegistrationRequest') {
      return deserialize<_i15.DeviceRegistrationRequest>(data['data']);
    }
    if (dataClassName == 'DeviceRegistrationResponse') {
      return deserialize<_i16.DeviceRegistrationResponse>(data['data']);
    }
    if (dataClassName == 'AuditOperation') {
      return deserialize<_i17.AuditOperation>(data['data']);
    }
    if (dataClassName == 'ConflictStatus') {
      return deserialize<_i18.ConflictStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i19.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'ExpenseCategory') {
      return deserialize<_i20.ExpenseCategory>(data['data']);
    }
    if (dataClassName == 'ParentEntityType') {
      return deserialize<_i21.ParentEntityType>(data['data']);
    }
    if (dataClassName == 'PartyAccount') {
      return deserialize<_i22.PartyAccount>(data['data']);
    }
    if (dataClassName == 'ReceiptType') {
      return deserialize<_i23.ReceiptType>(data['data']);
    }
    if (dataClassName == 'RecordStatus') {
      return deserialize<_i24.RecordStatus>(data['data']);
    }
    if (dataClassName == 'SyncOutboxStatus') {
      return deserialize<_i25.SyncOutboxStatus>(data['data']);
    }
    if (dataClassName == 'SyncStatus') {
      return deserialize<_i26.SyncStatus>(data['data']);
    }
    if (dataClassName == 'Expense') {
      return deserialize<_i27.Expense>(data['data']);
    }
    if (dataClassName == 'FreeSample') {
      return deserialize<_i28.FreeSample>(data['data']);
    }
    if (dataClassName == 'FreeSampleLine') {
      return deserialize<_i29.FreeSampleLine>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i30.Greeting>(data['data']);
    }
    if (dataClassName == 'LocalAttachmentStaging') {
      return deserialize<_i31.LocalAttachmentStaging>(data['data']);
    }
    if (dataClassName == 'MonthlyDistribution') {
      return deserialize<_i32.MonthlyDistribution>(data['data']);
    }
    if (dataClassName == 'OwnerAccount') {
      return deserialize<_i33.OwnerAccount>(data['data']);
    }
    if (dataClassName == 'PartyAdjustment') {
      return deserialize<_i34.PartyAdjustment>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i35.Product>(data['data']);
    }
    if (dataClassName == 'PullRequest') {
      return deserialize<_i36.PullRequest>(data['data']);
    }
    if (dataClassName == 'PullResponse') {
      return deserialize<_i37.PullResponse>(data['data']);
    }
    if (dataClassName == 'PushRequest') {
      return deserialize<_i38.PushRequest>(data['data']);
    }
    if (dataClassName == 'PushResponse') {
      return deserialize<_i39.PushResponse>(data['data']);
    }
    if (dataClassName == 'Receipt') {
      return deserialize<_i40.Receipt>(data['data']);
    }
    if (dataClassName == 'ReceiptAllocation') {
      return deserialize<_i41.ReceiptAllocation>(data['data']);
    }
    if (dataClassName == 'SalesInvoice') {
      return deserialize<_i42.SalesInvoice>(data['data']);
    }
    if (dataClassName == 'SalesInvoiceLine') {
      return deserialize<_i43.SalesInvoiceLine>(data['data']);
    }
    if (dataClassName == 'SalesReturn') {
      return deserialize<_i44.SalesReturn>(data['data']);
    }
    if (dataClassName == 'SalesReturnLine') {
      return deserialize<_i45.SalesReturnLine>(data['data']);
    }
    if (dataClassName == 'SyncCursor') {
      return deserialize<_i46.SyncCursor>(data['data']);
    }
    if (dataClassName == 'SyncOutbox') {
      return deserialize<_i47.SyncOutbox>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i49.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i50.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

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
      return _i49.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i50.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
