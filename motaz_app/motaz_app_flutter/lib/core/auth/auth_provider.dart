import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart';
import 'package:riverpod/legacy.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import '../connectivity/server_service.dart';
import '../logging/app_logger.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Client client;
  final ServerService serverService;
  late final void Function() _authListener;

  AuthNotifier(this.client, this.serverService) : super(const AuthInitial()) {
    _authListener = () {
      unawaited(_syncAuthState());
    };
    client.auth.authInfoListenable.addListener(_authListener);
    unawaited(_init());
  }

  Future<void> _init() async {
    AppLog.auth('Initializing cached auth session');
    await client.auth.initialize();
    await _syncAuthState();
  }

  Future<void> _syncAuthState() async {
    if (client.auth.isAuthenticated) {
      AppLog.auth('Session restored from local cache');
      state = Authenticated(email: await _loadCurrentEmail());
      return;
    }

    AppLog.auth('No active cached session found');
    state = Unauthenticated(hasAccount: await _loadHasAccount());
  }

  Future<String?> _loadCurrentEmail() async {
    try {
      final userProfile = await client
          .modules
          .serverpod_auth_core
          .userProfileInfo
          .get();
      return userProfile.email;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _loadHasAccount() async {
    try {
      return await client.emailIdp.hasAccount();
    } catch (_) {
      return true;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    try {
      AppLog.auth('Attempting registration for $email');
      final connection = await serverService.checkConnection();
      if (!connection.isConnected) {
        AppLog.warning('Registration blocked because server is unavailable');
        state = Unauthenticated(hasAccount: await _loadHasAccount());
        return false;
      }

      final authSuccess = await client.emailIdp.register(
        email: email,
        password: password,
      );
      await client.auth.updateSignedInUser(authSuccess);
      AppLog.auth('Registration succeeded for $email');
      state = Authenticated(email: email);
      return true;
    } catch (e, stackTrace) {
      AppLog.error('Registration failed for $email', e, stackTrace);
      state = Unauthenticated(hasAccount: await _loadHasAccount());
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLog.auth('Attempting sign-in for $email');
      final connection = await serverService.checkConnection();
      if (!connection.isConnected) {
        AppLog.warning('Sign-in blocked because server is unavailable');
        state = const Unauthenticated(hasAccount: true);
        return false;
      }

      final authSuccess = await client.emailIdp.login(
        email: email,
        password: password,
      );
      if ((authSuccess.token.isNotEmpty) ||
          (authSuccess.refreshToken?.isNotEmpty ?? false)) {
        await client.auth.updateSignedInUser(authSuccess);
        AppLog.auth('Sign-in succeeded for $email');
        state = Authenticated(email: email);
        return true;
      }
      AppLog.warning('Sign-in returned empty auth tokens for $email');
      return false;
    } catch (e, stackTrace) {
      AppLog.error('Sign-in failed for $email', e, stackTrace);
      state = const Unauthenticated(hasAccount: true);
      return false;
    }
  }

  Future<void> signOut() async {
    AppLog.auth('Signing out current device');
    await client.auth.signOutDevice();
    state = const Unauthenticated(hasAccount: true);
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_authListener);
    super.dispose();
  }
}

Client buildClient(String serverUrl) {
  return Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();
}

final clientProvider = Provider<Client>((ref) {
  throw UnimplementedError('clientProvider must be overridden at app startup.');
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(clientProvider);
  final serverService = ref.watch(serverServiceProvider);
  return AuthNotifier(client, serverService);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authProvider);
  return state is Authenticated;
});

final currentUserProvider = Provider<Authenticated?>((ref) {
  final state = ref.watch(authProvider);
  return state is Authenticated ? state : null;
});
