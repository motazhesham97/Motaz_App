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
import 'enums/device_platform.dart' as _i2;
import 'sync_outbox.dart' as _i3;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i4;

abstract class Device implements _i1.SerializableModel {
  Device._({
    this.id,
    required this.deviceName,
    required this.platform,
    required this.deviceCode,
    int? nextInvoiceSequence,
    required this.createdAt,
    required this.lastActiveAt,
    this.syncOutboxItems,
  }) : nextInvoiceSequence = nextInvoiceSequence ?? 1;

  factory Device({
    _i1.UuidValue? id,
    required String deviceName,
    required _i2.DevicePlatform platform,
    required String deviceCode,
    int? nextInvoiceSequence,
    required DateTime createdAt,
    required DateTime lastActiveAt,
    List<_i3.SyncOutbox>? syncOutboxItems,
  }) = _DeviceImpl;

  factory Device.fromJson(Map<String, dynamic> jsonSerialization) {
    return Device(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      deviceName: jsonSerialization['deviceName'] as String,
      platform: _i2.DevicePlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      deviceCode: jsonSerialization['deviceCode'] as String,
      nextInvoiceSequence: jsonSerialization['nextInvoiceSequence'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastActiveAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastActiveAt'],
      ),
      syncOutboxItems: jsonSerialization['syncOutboxItems'] == null
          ? null
          : _i4.Protocol().deserialize<List<_i3.SyncOutbox>>(
              jsonSerialization['syncOutboxItems'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  String deviceName;

  _i2.DevicePlatform platform;

  String deviceCode;

  int nextInvoiceSequence;

  DateTime createdAt;

  DateTime lastActiveAt;

  List<_i3.SyncOutbox>? syncOutboxItems;

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Device copyWith({
    _i1.UuidValue? id,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? deviceCode,
    int? nextInvoiceSequence,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    List<_i3.SyncOutbox>? syncOutboxItems,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'deviceName': deviceName,
      'platform': platform.toJson(),
      'deviceCode': deviceCode,
      'nextInvoiceSequence': nextInvoiceSequence,
      'createdAt': createdAt.toJson(),
      'lastActiveAt': lastActiveAt.toJson(),
      if (syncOutboxItems != null)
        'syncOutboxItems': syncOutboxItems?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceImpl extends Device {
  _DeviceImpl({
    _i1.UuidValue? id,
    required String deviceName,
    required _i2.DevicePlatform platform,
    required String deviceCode,
    int? nextInvoiceSequence,
    required DateTime createdAt,
    required DateTime lastActiveAt,
    List<_i3.SyncOutbox>? syncOutboxItems,
  }) : super._(
         id: id,
         deviceName: deviceName,
         platform: platform,
         deviceCode: deviceCode,
         nextInvoiceSequence: nextInvoiceSequence,
         createdAt: createdAt,
         lastActiveAt: lastActiveAt,
         syncOutboxItems: syncOutboxItems,
       );

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Device copyWith({
    Object? id = _Undefined,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? deviceCode,
    int? nextInvoiceSequence,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Object? syncOutboxItems = _Undefined,
  }) {
    return Device(
      id: id is _i1.UuidValue? ? id : this.id,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      deviceCode: deviceCode ?? this.deviceCode,
      nextInvoiceSequence: nextInvoiceSequence ?? this.nextInvoiceSequence,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      syncOutboxItems: syncOutboxItems is List<_i3.SyncOutbox>?
          ? syncOutboxItems
          : this.syncOutboxItems?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
