import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/conflict_log.dart';
import '../generated/enums/conflict_status.dart';
import '../generated/pull_request.dart';
import '../generated/pull_response.dart';
import '../generated/push_request.dart';
import '../generated/push_response.dart';
import '../generated/conflict_resolution_request.dart';
import '../generated/conflict_resolution_response.dart';
import '../services/sync_service.dart';

class SyncEndpoint extends Endpoint {
  Future<PushResponse> push(
    Session session,
    PushRequest request,
  ) async {
    if (!session.isUserSignedIn) {
      return PushResponse(
        success: false,
        errorCode: 'UNAUTHENTICATED',
        errorMessage: 'Authentication required',
      );
    }

    final deviceValid = await SyncService.validateDeviceIdentity(
      session,
      request.deviceId,
    );
    if (!deviceValid) {
      return PushResponse(
        success: false,
        errorCode: 'UNKNOWN_DEVICE',
        errorMessage: 'Device not registered',
      );
    }

    final currentVersion = await SyncService.checkRowVersion(
      session,
      request.entityType,
      request.entityId,
    );

    if (currentVersion == null) {
      final payload = jsonDecode(request.payload) as Map<String, dynamic>;
      final newVersion = await SyncService.acceptMutation(
        session,
        request.entityType,
        request.entityId,
        payload,
        request.operation,
        request.deviceId,
      );
      return PushResponse(success: true, newRowVersion: newVersion);
    }

    if (request.rowVersion == currentVersion) {
      final payload = jsonDecode(request.payload) as Map<String, dynamic>;
      final newVersion = await SyncService.acceptMutation(
        session,
        request.entityType,
        request.entityId,
        payload,
        request.operation,
        request.deviceId,
      );
      return PushResponse(success: true, newRowVersion: newVersion);
    }

    final existingRow = await SyncService.loadEntityRow(
      session,
      request.entityType,
      request.entityId,
    );
    if (existingRow == null) {
      return PushResponse(
        success: false,
        errorCode: 'ENTITY_NOT_FOUND',
        errorMessage: 'Entity disappeared during processing',
      );
    }

    final incomingPayload = jsonDecode(request.payload) as Map<String, dynamic>;
    final changedFields = SyncService.classifyChangedFields(
      request.entityType,
      incomingPayload,
      existingRow,
    );

    if (SyncService.applyVoidWinsRule(
      incomingPayload['status']?.toString(),
      existingRow['status']?.toString(),
    )) {
      final merged = Map<String, dynamic>.from(existingRow);
      final localVoided = incomingPayload['status'] == 'VOIDED';
      if (localVoided) {
        merged['status'] = 'VOIDED';
        merged['voidReason'] = incomingPayload['voidReason'];
      }
      final newVersion = await SyncService.acceptMutation(
        session,
        request.entityType,
        request.entityId,
        merged,
        request.operation,
        request.deviceId,
      );
      return PushResponse(success: true, newRowVersion: newVersion);
    }

    if (!SyncService.hasConflictRequiredFieldChanges(
      request.entityType,
      changedFields,
    )) {
      final merged = await SyncService.applyAutoMerge(
        session,
        request.entityType,
        request.entityId,
        incomingPayload,
      );
      final newVersion = await SyncService.acceptMutation(
        session,
        request.entityType,
        request.entityId,
        merged,
        request.operation,
        request.deviceId,
      );
      return PushResponse(success: true, newRowVersion: newVersion);
    }

    final conflictId = await SyncService.emitConflict(
      session,
      request.entityType,
      request.entityId,
      request.payload,
      jsonEncode(existingRow),
      '${changedFields.first}_mismatch',
      request.deviceId,
    );
    return PushResponse(success: false, conflictId: conflictId);
  }

  Future<PullResponse> pull(
    Session session,
    PullRequest request,
  ) async {
    if (!session.isUserSignedIn) {
      return PullResponse(
        entityType: request.entityType,
        rows: [],
        hasMore: false,
        latestRowVersion: 0,
      );
    }

    final rows = await SyncService.queryChangedRows(
      session,
      request.entityType,
      request.sinceRowVersion,
      request.limit,
    );

    final totalAbove = await SyncService.countRowsAboveVersion(
      session,
      request.entityType,
      request.sinceRowVersion,
    );

    final hasMore = totalAbove > request.limit;

    final latestRowVersion = await SyncService.getLatestRowVersion(
      session,
      request.entityType,
    );

    return PullResponse(
      entityType: request.entityType,
      rows: rows,
      hasMore: hasMore,
      latestRowVersion: latestRowVersion,
    );
  }

  Future<ConflictResolutionResponse> resolveConflict(
    Session session,
    ConflictResolutionRequest request,
  ) async {
    if (!session.isUserSignedIn) {
      return ConflictResolutionResponse(
        success: false,
        errorMessage: 'Authentication required',
      );
    }

    final conflictId = UuidValue.fromString(request.conflictId);
    final conflict = await ConflictLog.db.findById(session, conflictId);

    if (conflict == null) {
      return ConflictResolutionResponse(
        success: false,
        errorMessage: 'Conflict not found',
      );
    }

    if (conflict.resolutionStatus == ConflictStatus.RESOLVED) {
      return ConflictResolutionResponse(
        success: true,
        newRowVersion: conflict.resolutionData != null
            ? int.tryParse(conflict.resolutionData!)
            : null,
      );
    }

    final chosenPayload = request.chosenVersion == 'local'
        ? conflict.localPayload
        : conflict.remotePayload;

    final payload = jsonDecode(chosenPayload) as Map<String, dynamic>;
    final newVersion = await SyncService.acceptMutation(
      session,
      conflict.entityType.name,
      conflict.entityId.toString(),
      payload,
      'UPDATE',
      conflict.deviceId.toString(),
    );

    await ConflictLog.db.updateRow(
      session,
      conflict.copyWith(
        resolutionStatus: ConflictStatus.RESOLVED,
        resolvedAt: DateTime.now().toUtc(),
        resolutionData: newVersion.toString(),
      ),
    );

    return ConflictResolutionResponse(
      success: true,
      newRowVersion: newVersion,
    );
  }
}
