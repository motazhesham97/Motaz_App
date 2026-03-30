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
import 'attachment_metadata.dart' as _i2;
import 'audit_event.dart' as _i3;
import 'client_record.dart' as _i4;
import 'conflict_log.dart' as _i5;
import 'device.dart' as _i6;
import 'enums/audit_operation.dart' as _i7;
import 'enums/conflict_status.dart' as _i8;
import 'enums/device_platform.dart' as _i9;
import 'enums/expense_category.dart' as _i10;
import 'enums/parent_entity_type.dart' as _i11;
import 'enums/receipt_type.dart' as _i12;
import 'enums/record_status.dart' as _i13;
import 'enums/sync_outbox_status.dart' as _i14;
import 'enums/sync_status.dart' as _i15;
import 'expense.dart' as _i16;
import 'greetings/greeting.dart' as _i17;
import 'local_attachment_staging.dart' as _i18;
import 'product.dart' as _i19;
import 'receipt.dart' as _i20;
import 'receipt_allocation.dart' as _i21;
import 'sales_invoice.dart' as _i22;
import 'sales_invoice_line.dart' as _i23;
import 'sales_return.dart' as _i24;
import 'sales_return_line.dart' as _i25;
import 'sync_cursor.dart' as _i26;
import 'sync_outbox.dart' as _i27;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i28;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i29;
export 'attachment_metadata.dart';
export 'audit_event.dart';
export 'client_record.dart';
export 'conflict_log.dart';
export 'device.dart';
export 'enums/audit_operation.dart';
export 'enums/conflict_status.dart';
export 'enums/device_platform.dart';
export 'enums/expense_category.dart';
export 'enums/parent_entity_type.dart';
export 'enums/receipt_type.dart';
export 'enums/record_status.dart';
export 'enums/sync_outbox_status.dart';
export 'enums/sync_status.dart';
export 'expense.dart';
export 'greetings/greeting.dart';
export 'local_attachment_staging.dart';
export 'product.dart';
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

    if (t == _i2.AttachmentMetadata) {
      return _i2.AttachmentMetadata.fromJson(data) as T;
    }
    if (t == _i3.AuditEvent) {
      return _i3.AuditEvent.fromJson(data) as T;
    }
    if (t == _i4.ClientRecord) {
      return _i4.ClientRecord.fromJson(data) as T;
    }
    if (t == _i5.ConflictLog) {
      return _i5.ConflictLog.fromJson(data) as T;
    }
    if (t == _i6.Device) {
      return _i6.Device.fromJson(data) as T;
    }
    if (t == _i7.AuditOperation) {
      return _i7.AuditOperation.fromJson(data) as T;
    }
    if (t == _i8.ConflictStatus) {
      return _i8.ConflictStatus.fromJson(data) as T;
    }
    if (t == _i9.DevicePlatform) {
      return _i9.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i10.ExpenseCategory) {
      return _i10.ExpenseCategory.fromJson(data) as T;
    }
    if (t == _i11.ParentEntityType) {
      return _i11.ParentEntityType.fromJson(data) as T;
    }
    if (t == _i12.ReceiptType) {
      return _i12.ReceiptType.fromJson(data) as T;
    }
    if (t == _i13.RecordStatus) {
      return _i13.RecordStatus.fromJson(data) as T;
    }
    if (t == _i14.SyncOutboxStatus) {
      return _i14.SyncOutboxStatus.fromJson(data) as T;
    }
    if (t == _i15.SyncStatus) {
      return _i15.SyncStatus.fromJson(data) as T;
    }
    if (t == _i16.Expense) {
      return _i16.Expense.fromJson(data) as T;
    }
    if (t == _i17.Greeting) {
      return _i17.Greeting.fromJson(data) as T;
    }
    if (t == _i18.LocalAttachmentStaging) {
      return _i18.LocalAttachmentStaging.fromJson(data) as T;
    }
    if (t == _i19.Product) {
      return _i19.Product.fromJson(data) as T;
    }
    if (t == _i20.Receipt) {
      return _i20.Receipt.fromJson(data) as T;
    }
    if (t == _i21.ReceiptAllocation) {
      return _i21.ReceiptAllocation.fromJson(data) as T;
    }
    if (t == _i22.SalesInvoice) {
      return _i22.SalesInvoice.fromJson(data) as T;
    }
    if (t == _i23.SalesInvoiceLine) {
      return _i23.SalesInvoiceLine.fromJson(data) as T;
    }
    if (t == _i24.SalesReturn) {
      return _i24.SalesReturn.fromJson(data) as T;
    }
    if (t == _i25.SalesReturnLine) {
      return _i25.SalesReturnLine.fromJson(data) as T;
    }
    if (t == _i26.SyncCursor) {
      return _i26.SyncCursor.fromJson(data) as T;
    }
    if (t == _i27.SyncOutbox) {
      return _i27.SyncOutbox.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AttachmentMetadata?>()) {
      return (data != null ? _i2.AttachmentMetadata.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AuditEvent?>()) {
      return (data != null ? _i3.AuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ClientRecord?>()) {
      return (data != null ? _i4.ClientRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ConflictLog?>()) {
      return (data != null ? _i5.ConflictLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Device?>()) {
      return (data != null ? _i6.Device.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AuditOperation?>()) {
      return (data != null ? _i7.AuditOperation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ConflictStatus?>()) {
      return (data != null ? _i8.ConflictStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.DevicePlatform?>()) {
      return (data != null ? _i9.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ExpenseCategory?>()) {
      return (data != null ? _i10.ExpenseCategory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.ParentEntityType?>()) {
      return (data != null ? _i11.ParentEntityType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ReceiptType?>()) {
      return (data != null ? _i12.ReceiptType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.RecordStatus?>()) {
      return (data != null ? _i13.RecordStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.SyncOutboxStatus?>()) {
      return (data != null ? _i14.SyncOutboxStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.SyncStatus?>()) {
      return (data != null ? _i15.SyncStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Expense?>()) {
      return (data != null ? _i16.Expense.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.Greeting?>()) {
      return (data != null ? _i17.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.LocalAttachmentStaging?>()) {
      return (data != null ? _i18.LocalAttachmentStaging.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.Product?>()) {
      return (data != null ? _i19.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.Receipt?>()) {
      return (data != null ? _i20.Receipt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ReceiptAllocation?>()) {
      return (data != null ? _i21.ReceiptAllocation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.SalesInvoice?>()) {
      return (data != null ? _i22.SalesInvoice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.SalesInvoiceLine?>()) {
      return (data != null ? _i23.SalesInvoiceLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.SalesReturn?>()) {
      return (data != null ? _i24.SalesReturn.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.SalesReturnLine?>()) {
      return (data != null ? _i25.SalesReturnLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.SyncCursor?>()) {
      return (data != null ? _i26.SyncCursor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.SyncOutbox?>()) {
      return (data != null ? _i27.SyncOutbox.fromJson(data) : null) as T;
    }
    if (t == List<_i27.SyncOutbox>) {
      return (data as List).map((e) => deserialize<_i27.SyncOutbox>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i27.SyncOutbox>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i27.SyncOutbox>(e))
                    .toList()
              : null)
          as T;
    }
    try {
      return _i28.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i29.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AttachmentMetadata => 'AttachmentMetadata',
      _i3.AuditEvent => 'AuditEvent',
      _i4.ClientRecord => 'ClientRecord',
      _i5.ConflictLog => 'ConflictLog',
      _i6.Device => 'Device',
      _i7.AuditOperation => 'AuditOperation',
      _i8.ConflictStatus => 'ConflictStatus',
      _i9.DevicePlatform => 'DevicePlatform',
      _i10.ExpenseCategory => 'ExpenseCategory',
      _i11.ParentEntityType => 'ParentEntityType',
      _i12.ReceiptType => 'ReceiptType',
      _i13.RecordStatus => 'RecordStatus',
      _i14.SyncOutboxStatus => 'SyncOutboxStatus',
      _i15.SyncStatus => 'SyncStatus',
      _i16.Expense => 'Expense',
      _i17.Greeting => 'Greeting',
      _i18.LocalAttachmentStaging => 'LocalAttachmentStaging',
      _i19.Product => 'Product',
      _i20.Receipt => 'Receipt',
      _i21.ReceiptAllocation => 'ReceiptAllocation',
      _i22.SalesInvoice => 'SalesInvoice',
      _i23.SalesInvoiceLine => 'SalesInvoiceLine',
      _i24.SalesReturn => 'SalesReturn',
      _i25.SalesReturnLine => 'SalesReturnLine',
      _i26.SyncCursor => 'SyncCursor',
      _i27.SyncOutbox => 'SyncOutbox',
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
      case _i2.AttachmentMetadata():
        return 'AttachmentMetadata';
      case _i3.AuditEvent():
        return 'AuditEvent';
      case _i4.ClientRecord():
        return 'ClientRecord';
      case _i5.ConflictLog():
        return 'ConflictLog';
      case _i6.Device():
        return 'Device';
      case _i7.AuditOperation():
        return 'AuditOperation';
      case _i8.ConflictStatus():
        return 'ConflictStatus';
      case _i9.DevicePlatform():
        return 'DevicePlatform';
      case _i10.ExpenseCategory():
        return 'ExpenseCategory';
      case _i11.ParentEntityType():
        return 'ParentEntityType';
      case _i12.ReceiptType():
        return 'ReceiptType';
      case _i13.RecordStatus():
        return 'RecordStatus';
      case _i14.SyncOutboxStatus():
        return 'SyncOutboxStatus';
      case _i15.SyncStatus():
        return 'SyncStatus';
      case _i16.Expense():
        return 'Expense';
      case _i17.Greeting():
        return 'Greeting';
      case _i18.LocalAttachmentStaging():
        return 'LocalAttachmentStaging';
      case _i19.Product():
        return 'Product';
      case _i20.Receipt():
        return 'Receipt';
      case _i21.ReceiptAllocation():
        return 'ReceiptAllocation';
      case _i22.SalesInvoice():
        return 'SalesInvoice';
      case _i23.SalesInvoiceLine():
        return 'SalesInvoiceLine';
      case _i24.SalesReturn():
        return 'SalesReturn';
      case _i25.SalesReturnLine():
        return 'SalesReturnLine';
      case _i26.SyncCursor():
        return 'SyncCursor';
      case _i27.SyncOutbox():
        return 'SyncOutbox';
    }
    className = _i28.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i29.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'AttachmentMetadata') {
      return deserialize<_i2.AttachmentMetadata>(data['data']);
    }
    if (dataClassName == 'AuditEvent') {
      return deserialize<_i3.AuditEvent>(data['data']);
    }
    if (dataClassName == 'ClientRecord') {
      return deserialize<_i4.ClientRecord>(data['data']);
    }
    if (dataClassName == 'ConflictLog') {
      return deserialize<_i5.ConflictLog>(data['data']);
    }
    if (dataClassName == 'Device') {
      return deserialize<_i6.Device>(data['data']);
    }
    if (dataClassName == 'AuditOperation') {
      return deserialize<_i7.AuditOperation>(data['data']);
    }
    if (dataClassName == 'ConflictStatus') {
      return deserialize<_i8.ConflictStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i9.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'ExpenseCategory') {
      return deserialize<_i10.ExpenseCategory>(data['data']);
    }
    if (dataClassName == 'ParentEntityType') {
      return deserialize<_i11.ParentEntityType>(data['data']);
    }
    if (dataClassName == 'ReceiptType') {
      return deserialize<_i12.ReceiptType>(data['data']);
    }
    if (dataClassName == 'RecordStatus') {
      return deserialize<_i13.RecordStatus>(data['data']);
    }
    if (dataClassName == 'SyncOutboxStatus') {
      return deserialize<_i14.SyncOutboxStatus>(data['data']);
    }
    if (dataClassName == 'SyncStatus') {
      return deserialize<_i15.SyncStatus>(data['data']);
    }
    if (dataClassName == 'Expense') {
      return deserialize<_i16.Expense>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i17.Greeting>(data['data']);
    }
    if (dataClassName == 'LocalAttachmentStaging') {
      return deserialize<_i18.LocalAttachmentStaging>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i19.Product>(data['data']);
    }
    if (dataClassName == 'Receipt') {
      return deserialize<_i20.Receipt>(data['data']);
    }
    if (dataClassName == 'ReceiptAllocation') {
      return deserialize<_i21.ReceiptAllocation>(data['data']);
    }
    if (dataClassName == 'SalesInvoice') {
      return deserialize<_i22.SalesInvoice>(data['data']);
    }
    if (dataClassName == 'SalesInvoiceLine') {
      return deserialize<_i23.SalesInvoiceLine>(data['data']);
    }
    if (dataClassName == 'SalesReturn') {
      return deserialize<_i24.SalesReturn>(data['data']);
    }
    if (dataClassName == 'SalesReturnLine') {
      return deserialize<_i25.SalesReturnLine>(data['data']);
    }
    if (dataClassName == 'SyncCursor') {
      return deserialize<_i26.SyncCursor>(data['data']);
    }
    if (dataClassName == 'SyncOutbox') {
      return deserialize<_i27.SyncOutbox>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i28.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i29.Protocol().deserializeByClassName(data);
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
      return _i28.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i29.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
