import 'dart:async';

import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class AppAuthSessionManager extends ClientAuthSessionManager {
  AppAuthSessionManager({required super.caller, required super.storage});

  final Object _validationRevisionKey = Object();
  int _sessionRevision = 0;

  bool get _isStaleValidation {
    final revision = Zone.current[_validationRevisionKey];
    return revision is int && revision != _sessionRevision;
  }

  @override
  Future<bool> validateAuthentication({Duration? timeout}) {
    // Future.timeout does not cancel SDK requests. Keep their later callbacks
    // tied to the session that started them, including after sign-out/sign-in.
    return runZoned(
      () => super.validateAuthentication(timeout: timeout),
      zoneValues: {_validationRevisionKey: _sessionRevision},
    );
  }

  @override
  Future<RefreshAuthKeyResult> refreshAuthKey({bool force = false}) async {
    final result = await super.refreshAuthKey(force: force);
    if (Zone.current[_validationRevisionKey] != null &&
        result == RefreshAuthKeyResult.failedOther) {
      // A stale access token cannot prove revocation after a temporary refresh
      // failure. Defer validation instead of letting the SDK sign out locally.
      throw Exception('Auth validation deferred: token refresh unavailable.');
    }
    return result;
  }

  @override
  Future<void> updateSignedInUser(AuthSuccess? authInfo) async {
    if (_isStaleValidation) return;
    if (Zone.current[_validationRevisionKey] == null) {
      _sessionRevision++;
    }
    await super.updateSignedInUser(authInfo);
  }

  @override
  Future<bool> signOutDevice() {
    if (_isStaleValidation) return Future.value(false);
    if (Zone.current[_validationRevisionKey] == null) {
      _sessionRevision++;
    }
    return super.signOutDevice();
  }

  @override
  Future<bool> signOutAllDevices() {
    if (_isStaleValidation) return Future.value(false);
    if (Zone.current[_validationRevisionKey] == null) {
      _sessionRevision++;
    }
    return super.signOutAllDevices();
  }
}
