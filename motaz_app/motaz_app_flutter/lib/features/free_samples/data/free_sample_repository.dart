import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';
import '../../../core/utils/document_reference_formatter.dart';

class FreeSampleDraftLine {
  const FreeSampleDraftLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

class FreeSampleLineSummary {
  const FreeSampleLineSummary({
    required this.productName,
    required this.quantity,
  });

  final String productName;
  final int quantity;
}

class FreeSampleSummary {
  const FreeSampleSummary({
    required this.sample,
    required this.beneficiaryName,
    required this.lines,
  });

  final FreeSample sample;
  final String beneficiaryName;
  final List<FreeSampleLineSummary> lines;

  int get totalQuantity =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  String get title =>
      freeSampleDisplayRef(sample.localRef, officialNo: sample.officialNo);
}

class FreeSampleEditData {
  const FreeSampleEditData({
    required this.sample,
    required this.beneficiary,
    required this.lines,
  });

  final FreeSample sample;
  final Beneficiary? beneficiary;
  final List<FreeSampleDraftLine> lines;
}

class FreeSampleRepository {
  FreeSampleRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<FreeSampleSummary>> watchRecent({int limit = 10}) {
    final query = _db.select(_db.freeSamples)
      ..where((t) => t.status.equals(RecordStatus.ACTIVE.index))
      ..orderBy([
        (t) => OrderingTerm.desc(t.sampleDate),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit);
    return query.watch().asyncMap(_summariesFor);
  }

  Stream<List<FreeSampleSummary>> watchAllSummaries() {
    final query = _db.select(_db.freeSamples)
      ..where((t) => t.status.equals(RecordStatus.ACTIVE.index))
      ..orderBy([
        (t) => OrderingTerm.desc(t.sampleDate),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch().asyncMap(_summariesFor);
  }

  Future<FreeSample> create({
    required String beneficiaryId,
    required DateTime sampleDate,
    required List<FreeSampleDraftLine> lines,
    required String deviceId,
    String? note,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Free sample must have at least one line');
    }

    final device = await (_db.select(
      _db.devices,
    )..where((t) => t.id.equals(deviceId))).getSingle();
    final sequence = device.nextSampleSequence;
    final localRef =
        'SAM-${device.deviceCode}-${sequence.toString().padLeft(3, '0')}';
    final sampleId = _uuid.v4();
    final now = DateTime.now();
    final cleanNote = note?.trim();

    await _db.transaction(() async {
      await _db
          .into(_db.freeSamples)
          .insert(
            FreeSamplesCompanion.insert(
              id: sampleId,
              localRef: localRef,
              officialNo: const Value(null),
              beneficiaryId: beneficiaryId,
              sampleDate: sampleDate,
              note: Value(
                cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
              ),
              status: RecordStatus.ACTIVE,
              voidReason: const Value(null),
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              rowVersion: const Value(1),
              syncStatus: SyncStatus.PENDING,
            ),
          );

      await _enqueue(
        entityType: ParentEntityType.FREE_SAMPLE,
        entityId: sampleId,
        operation: AuditOperation.CREATE,
        payload: jsonEncode({
          'id': sampleId,
          'localRef': localRef,
          'officialNo': null,
          'beneficiaryId': beneficiaryId,
          'sampleDate': sampleDate.toIso8601String(),
          'note': cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
          'status': RecordStatus.ACTIVE.index,
          'voidReason': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'deviceId': deviceId,
          'rowVersion': 1,
          'syncStatus': SyncStatus.PENDING.index,
        }),
        rowVersion: 1,
        deviceId: deviceId,
        createdAt: now,
      );

      for (final (index, line) in lines.indexed) {
        final lineId = _uuid.v4();
        final lineCreatedAt = now.add(Duration(microseconds: index + 1));
        await _db
            .into(_db.freeSampleLines)
            .insert(
              FreeSampleLinesCompanion.insert(
                id: lineId,
                sampleId: sampleId,
                productId: line.product.id,
                quantity: line.quantity,
                createdAt: lineCreatedAt,
                updatedAt: lineCreatedAt,
                deviceId: deviceId,
                rowVersion: const Value(1),
                syncStatus: SyncStatus.PENDING,
              ),
            );

        await _enqueue(
          entityType: ParentEntityType.FREE_SAMPLE_LINE,
          entityId: lineId,
          operation: AuditOperation.CREATE,
          payload: jsonEncode({
            'id': lineId,
            'sampleId': sampleId,
            'productId': line.product.id,
            'quantity': line.quantity,
            'createdAt': lineCreatedAt.toIso8601String(),
            'updatedAt': lineCreatedAt.toIso8601String(),
            'deviceId': deviceId,
            'rowVersion': 1,
            'syncStatus': SyncStatus.PENDING.index,
          }),
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: lineCreatedAt,
        );
      }

      await (_db.update(
        _db.devices,
      )..where((t) => t.id.equals(deviceId))).write(
        DevicesCompanion(nextSampleSequence: Value(sequence + 1)),
      );
    });

    return (_db.select(
      _db.freeSamples,
    )..where((t) => t.id.equals(sampleId))).getSingle();
  }

  Future<FreeSampleEditData?> getForEdit(String sampleId) async {
    final sample =
        await (_db.select(_db.freeSamples)
              ..where((t) => t.id.equals(sampleId))
              ..limit(1))
            .getSingleOrNull();
    if (sample == null) return null;

    final beneficiary =
        await (_db.select(_db.beneficiaries)
              ..where((t) => t.id.equals(sample.beneficiaryId))
              ..limit(1))
            .getSingleOrNull();

    final rows = await (_db.select(
      _db.freeSampleLines,
    )..where((t) => t.sampleId.equals(sampleId))).get();
    final lines = <FreeSampleDraftLine>[];
    for (final row in rows) {
      if (row.quantity <= 0) continue;
      final product =
          await (_db.select(_db.products)
                ..where((t) => t.id.equals(row.productId))
                ..limit(1))
              .getSingleOrNull();
      if (product == null) continue;
      lines.add(FreeSampleDraftLine(product: product, quantity: row.quantity));
    }

    return FreeSampleEditData(
      sample: sample,
      beneficiary: beneficiary,
      lines: lines,
    );
  }

  Future<void> update({
    required String sampleId,
    required String beneficiaryId,
    required DateTime sampleDate,
    required List<FreeSampleDraftLine> lines,
    required String deviceId,
    String? note,
  }) async {
    final desiredLines = <String, FreeSampleDraftLine>{};
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      desiredLines[line.product.id] = line;
    }
    if (desiredLines.isEmpty) {
      throw ArgumentError('Free sample must have at least one line');
    }

    final sample =
        await (_db.select(_db.freeSamples)
              ..where((t) => t.id.equals(sampleId))
              ..limit(1))
            .getSingleOrNull();
    if (sample == null) {
      throw StateError('Free sample not found');
    }

    final now = DateTime.now();
    final cleanNote = note?.trim();
    final nextSampleVersion = sample.rowVersion + 1;

    await _db.transaction(() async {
      await (_db.update(
        _db.freeSamples,
      )..where((t) => t.id.equals(sampleId))).write(
        FreeSamplesCompanion(
          beneficiaryId: Value(beneficiaryId),
          sampleDate: Value(sampleDate),
          note: Value(
            cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
          ),
          updatedAt: Value(now),
          deviceId: Value(deviceId),
          rowVersion: Value(nextSampleVersion),
          syncStatus: const Value(SyncStatus.PENDING),
        ),
      );

      await _enqueue(
        entityType: ParentEntityType.FREE_SAMPLE,
        entityId: sampleId,
        operation: AuditOperation.UPDATE,
        payload: jsonEncode(
          _samplePayload(
            sample,
            beneficiaryId: beneficiaryId,
            sampleDate: sampleDate,
            note: cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
            updatedAt: now,
            deviceId: deviceId,
            rowVersion: nextSampleVersion,
            syncStatus: SyncStatus.PENDING,
          ),
        ),
        rowVersion: sample.rowVersion,
        deviceId: deviceId,
        createdAt: now,
      );

      final existingLines = await (_db.select(
        _db.freeSampleLines,
      )..where((t) => t.sampleId.equals(sampleId))).get();
      final existingByProduct = {
        for (final line in existingLines) line.productId: line,
      };

      var index = 0;
      for (final desired in desiredLines.values) {
        final existingLine = existingByProduct[desired.product.id];
        final lineUpdatedAt = now.add(Duration(microseconds: ++index));
        if (existingLine == null) {
          final lineId = _uuid.v4();
          await _db
              .into(_db.freeSampleLines)
              .insert(
                FreeSampleLinesCompanion.insert(
                  id: lineId,
                  sampleId: sampleId,
                  productId: desired.product.id,
                  quantity: desired.quantity,
                  createdAt: lineUpdatedAt,
                  updatedAt: lineUpdatedAt,
                  deviceId: deviceId,
                  rowVersion: const Value(1),
                  syncStatus: SyncStatus.PENDING,
                ),
              );
          await _enqueue(
            entityType: ParentEntityType.FREE_SAMPLE_LINE,
            entityId: lineId,
            operation: AuditOperation.CREATE,
            payload: jsonEncode({
              'id': lineId,
              'sampleId': sampleId,
              'productId': desired.product.id,
              'quantity': desired.quantity,
              'createdAt': lineUpdatedAt.toIso8601String(),
              'updatedAt': lineUpdatedAt.toIso8601String(),
              'deviceId': deviceId,
              'rowVersion': 1,
              'syncStatus': SyncStatus.PENDING.index,
            }),
            rowVersion: 1,
            deviceId: deviceId,
            createdAt: lineUpdatedAt,
          );
          continue;
        }

        final nextLineVersion = existingLine.rowVersion + 1;
        await (_db.update(
          _db.freeSampleLines,
        )..where((t) => t.id.equals(existingLine.id))).write(
          FreeSampleLinesCompanion(
            quantity: Value(desired.quantity),
            updatedAt: Value(lineUpdatedAt),
            deviceId: Value(deviceId),
            rowVersion: Value(nextLineVersion),
            syncStatus: const Value(SyncStatus.PENDING),
          ),
        );
        await _enqueue(
          entityType: ParentEntityType.FREE_SAMPLE_LINE,
          entityId: existingLine.id,
          operation: AuditOperation.UPDATE,
          payload: jsonEncode(
            _linePayload(
              existingLine,
              quantity: desired.quantity,
              updatedAt: lineUpdatedAt,
              deviceId: deviceId,
              rowVersion: nextLineVersion,
              syncStatus: SyncStatus.PENDING,
            ),
          ),
          rowVersion: existingLine.rowVersion,
          deviceId: deviceId,
          createdAt: lineUpdatedAt,
        );
      }

      for (final existingLine in existingLines) {
        if (desiredLines.containsKey(existingLine.productId) ||
            existingLine.quantity <= 0) {
          continue;
        }
        final lineUpdatedAt = now.add(Duration(microseconds: ++index));
        final nextLineVersion = existingLine.rowVersion + 1;
        await (_db.update(
          _db.freeSampleLines,
        )..where((t) => t.id.equals(existingLine.id))).write(
          FreeSampleLinesCompanion(
            quantity: const Value(0),
            updatedAt: Value(lineUpdatedAt),
            deviceId: Value(deviceId),
            rowVersion: Value(nextLineVersion),
            syncStatus: const Value(SyncStatus.PENDING),
          ),
        );
        await _enqueue(
          entityType: ParentEntityType.FREE_SAMPLE_LINE,
          entityId: existingLine.id,
          operation: AuditOperation.UPDATE,
          payload: jsonEncode(
            _linePayload(
              existingLine,
              quantity: 0,
              updatedAt: lineUpdatedAt,
              deviceId: deviceId,
              rowVersion: nextLineVersion,
              syncStatus: SyncStatus.PENDING,
            ),
          ),
          rowVersion: existingLine.rowVersion,
          deviceId: deviceId,
          createdAt: lineUpdatedAt,
        );
      }
    });
  }

  Future<void> voidSample({
    required String sampleId,
    required String deviceId,
    String? reason,
  }) async {
    final sample =
        await (_db.select(_db.freeSamples)
              ..where((t) => t.id.equals(sampleId))
              ..limit(1))
            .getSingleOrNull();
    if (sample == null) return;
    if (sample.status == RecordStatus.VOIDED) return;

    final now = DateTime.now();
    final nextVersion = sample.rowVersion + 1;
    final cleanReason = reason?.trim();
    await (_db.update(
      _db.freeSamples,
    )..where((t) => t.id.equals(sampleId))).write(
      FreeSamplesCompanion(
        status: const Value(RecordStatus.VOIDED),
        voidReason: Value(
          cleanReason == null || cleanReason.isEmpty ? null : cleanReason,
        ),
        updatedAt: Value(now),
        deviceId: Value(deviceId),
        rowVersion: Value(nextVersion),
        syncStatus: const Value(SyncStatus.PENDING),
      ),
    );

    await _enqueue(
      entityType: ParentEntityType.FREE_SAMPLE,
      entityId: sampleId,
      operation: AuditOperation.VOID,
      payload: jsonEncode(
        _samplePayload(
          sample,
          status: RecordStatus.VOIDED,
          voidReason: cleanReason == null || cleanReason.isEmpty
              ? null
              : cleanReason,
          updatedAt: now,
          deviceId: deviceId,
          rowVersion: nextVersion,
          syncStatus: SyncStatus.PENDING,
        ),
      ),
      rowVersion: nextVersion,
      deviceId: deviceId,
      createdAt: now,
    );
  }

  Future<List<FreeSampleSummary>> _summariesFor(
    List<FreeSample> samples,
  ) async {
    final result = <FreeSampleSummary>[];
    for (final sample in samples) {
      final beneficiary =
          await (_db.select(_db.beneficiaries)
                ..where((t) => t.id.equals(sample.beneficiaryId))
                ..limit(1))
              .getSingleOrNull();
      final rows = await _lineSummaries(sample.id);
      result.add(
        FreeSampleSummary(
          sample: sample,
          beneficiaryName: beneficiary?.displayName ?? 'مستفيد غير معروف',
          lines: rows,
        ),
      );
    }
    return result;
  }

  Future<List<FreeSampleLineSummary>> _lineSummaries(String sampleId) async {
    final lines = await (_db.select(
      _db.freeSampleLines,
    )..where((t) => t.sampleId.equals(sampleId))).get();
    final result = <FreeSampleLineSummary>[];
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final product =
          await (_db.select(_db.products)
                ..where((t) => t.id.equals(line.productId))
                ..limit(1))
              .getSingleOrNull();
      result.add(
        FreeSampleLineSummary(
          productName: product?.name ?? 'منتج غير معروف',
          quantity: line.quantity,
        ),
      );
    }
    return result;
  }

  Map<String, dynamic> _samplePayload(
    FreeSample sample, {
    String? beneficiaryId,
    DateTime? sampleDate,
    String? note,
    RecordStatus? status,
    String? voidReason,
    DateTime? updatedAt,
    String? deviceId,
    int? rowVersion,
    SyncStatus? syncStatus,
  }) {
    return {
      'id': sample.id,
      'localRef': sample.localRef,
      'officialNo': sample.officialNo,
      'beneficiaryId': beneficiaryId ?? sample.beneficiaryId,
      'sampleDate': (sampleDate ?? sample.sampleDate).toIso8601String(),
      'note': note ?? sample.note,
      'status': (status ?? sample.status).index,
      'voidReason': voidReason ?? sample.voidReason,
      'createdAt': sample.createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? sample.updatedAt).toIso8601String(),
      'deviceId': deviceId ?? sample.deviceId,
      'rowVersion': rowVersion ?? sample.rowVersion,
      'syncStatus': (syncStatus ?? sample.syncStatus).index,
    };
  }

  Map<String, dynamic> _linePayload(
    FreeSampleLine line, {
    int? quantity,
    DateTime? updatedAt,
    String? deviceId,
    int? rowVersion,
    SyncStatus? syncStatus,
  }) {
    return {
      'id': line.id,
      'sampleId': line.sampleId,
      'productId': line.productId,
      'quantity': quantity ?? line.quantity,
      'createdAt': line.createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? line.updatedAt).toIso8601String(),
      'deviceId': deviceId ?? line.deviceId,
      'rowVersion': rowVersion ?? line.rowVersion,
      'syncStatus': (syncStatus ?? line.syncStatus).index,
    };
  }

  Future<void> _enqueue({
    required ParentEntityType entityType,
    required String entityId,
    required AuditOperation operation,
    required String payload,
    required int rowVersion,
    required String deviceId,
    required DateTime createdAt,
  }) async {
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: _uuid.v4(),
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            rowVersion: rowVersion,
            deviceId: deviceId,
            createdAt: createdAt,
            status: Value(SyncOutboxStatus.PENDING),
          ),
        );
  }
}
