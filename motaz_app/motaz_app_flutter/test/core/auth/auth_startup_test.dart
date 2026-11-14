import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as api;
import 'package:motaz_app_flutter/core/auth/app_auth_session_manager.dart';
import 'package:motaz_app_flutter/core/auth/auth_provider.dart';
import 'package:motaz_app_flutter/core/auth/auth_state.dart';
import 'package:motaz_app_flutter/core/auth/shared_preferences_auth_storage.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _email = 'owner@example.test';

AuthSuccess _savedSession() => AuthSuccess(
  authStrategy: 'jwt',
  token: 'saved-access-token',
  tokenExpiresAt: DateTime.utc(2020),
  refreshToken: 'saved-refresh-token',
  authUserId: UuidValue.fromString('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  scopeNames: {},
);

class _ControlledSessionManager extends ClientAuthSessionManager {
  _ControlledSessionManager({required super.caller, required super.storage});

  final validation = Completer<bool>();
  int validationCalls = 0;

  @override
  Future<bool> validateAuthentication({Duration? timeout}) {
    validationCalls++;
    return validation.future;
  }
}

class _AuthBoundaryClient extends api.Client {
  _AuthBoundaryClient() : super('http://unused.invalid/');

  final refresh = Completer<AuthSuccess>();
  final status = Completer<bool>();
  final owner = Completer<bool>();
  final calls = <String>[];
  AuthSuccess? loginResult;

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    final call = '$endpoint.$method';
    calls.add(call);
    final Object? result;
    switch (call) {
      case 'jwtRefresh.refreshAccessToken':
        result = await refresh.future;
      case 'serverpod_auth_core.status.isSignedIn':
        result = await status.future;
      case 'auth.hasOwnerAccount':
        result = await owner.future;
      case 'serverpod_auth_core.status.signOutDevice':
        result = null;
      case 'emailIdp.login':
        result = loginResult ?? (throw StateError('Missing test login result'));
      default:
        throw StateError('Unexpected auth endpoint: $call');
    }
    return result as T;
  }
}

class _AuthHarness {
  _AuthHarness(this.prefs, this.client, this.manager, this.controller);

  final SharedPreferences prefs;
  final _AuthBoundaryClient client;
  final ClientAuthSessionManager manager;
  final AuthController controller;

  static Future<_AuthHarness> create({
    bool withSession = true,
    bool withEmail = true,
    bool hasAccount = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'motaz_has_account': hasAccount,
      if (withEmail) 'motaz_signed_in_email': _email,
      'local_data_marker': 'keep-local-data',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = CachedClientAuthSuccessStorage(
      delegate: KeyValueClientAuthSuccessStorage(
        keyValueStorage: SharedPreferencesAuthStorage(prefs),
      ),
    );
    if (withSession) {
      await storage.set(_savedSession());
    }
    final client = _AuthBoundaryClient();
    final manager = AppAuthSessionManager(
      caller: Caller(client),
      storage: storage,
    );
    client.authKeyProvider = manager;
    return _AuthHarness(
      prefs,
      client,
      manager,
      AuthController(client: client, sessionManager: manager),
    );
  }

  Future<void> close(WidgetTester tester) async {
    controller.dispose();
    if (!client.refresh.isCompleted) {
      client.refresh.complete(_savedSession());
    }
    if (!client.status.isCompleted) {
      client.status.complete(true);
    }
    if (!client.owner.isCompleted) {
      client.owner.complete(true);
    }
    await tester.pump();
    client.close();
  }
}

void main() {
  testWidgets(
    'restores saved local authentication without waiting for stalled network validation',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'motaz_has_account': true,
        'motaz_signed_in_email': _email,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = CachedClientAuthSuccessStorage(
        delegate: KeyValueClientAuthSuccessStorage(
          keyValueStorage: SharedPreferencesAuthStorage(prefs),
        ),
      );
      await storage.set(_savedSession());
      final client = api.Client('http://unused.invalid/');
      final manager = _ControlledSessionManager(
        caller: Caller(client),
        storage: storage,
      );
      client.authKeyProvider = manager;
      final controller = AuthController(
        client: client,
        sessionManager: manager,
      );
      var entryCompleted = false;
      final entry = controller.initialize().then((_) => entryCompleted = true);
      addTearDown(() {
        if (!manager.validation.isCompleted) {
          manager.validation.complete(true);
        }
        controller.dispose();
        client.close();
      });

      await tester.pump();

      expect(manager.validation.isCompleted, isFalse);
      expect(manager.validationCalls, 1);
      expect(entryCompleted, isTrue);
      expect(controller.state, isA<AuthAuthenticated>());
      expect((controller.state as AuthAuthenticated).email, _email);
      expect(manager.isAuthenticated, isTrue);
      expect(prefs.getString('motaz_signed_in_email'), _email);
      await entry;
    },
  );

  testWidgets(
    'retains saved session and local preferences when SDK validation times out',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      final savedAuth = harness.prefs.getString('serverpod_auth_success_key');
      var notifications = 0;
      harness.controller.addListener(() => notifications++);

      await harness.controller.initialize();
      await tester.pump();
      expect(harness.client.calls, ['jwtRefresh.refreshAccessToken']);
      expect(harness.controller.state, isA<AuthAuthenticated>());
      expect(harness.client.refresh.isCompleted, isFalse);

      await tester.pump(const Duration(seconds: 8));

      expect(harness.controller.state, isA<AuthAuthenticated>());
      expect(harness.manager.isAuthenticated, isTrue);
      expect(harness.prefs.getString('motaz_signed_in_email'), _email);
      expect(harness.prefs.getString('serverpod_auth_success_key'), savedAuth);
      expect(harness.prefs.getString('local_data_marker'), 'keep-local-data');
      expect(harness.client.calls, ['jwtRefresh.refreshAccessToken']);
      expect(notifications, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps local access when the server status request fails transiently',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      final savedAuth = harness.prefs.getString('serverpod_auth_success_key');

      await harness.controller.initialize();
      await tester.pump();
      harness.client.refresh.complete(_savedSession());
      await tester.pump();
      expect(
        harness.client.calls.last,
        'serverpod_auth_core.status.isSignedIn',
      );
      harness.client.status.completeError(
        TimeoutException('Connection stalled'),
      );
      await tester.pump();

      expect(harness.controller.state, isA<AuthAuthenticated>());
      expect(harness.manager.isAuthenticated, isTrue);
      expect(harness.prefs.getString('motaz_signed_in_email'), _email);
      expect(harness.prefs.getString('serverpod_auth_success_key'), savedAuth);
      expect(harness.prefs.getString('local_data_marker'), 'keep-local-data');
      expect(harness.client.calls, [
        'jwtRefresh.refreshAccessToken',
        'serverpod_auth_core.status.isSignedIn',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'validates once in the background and saves refreshed tokens without rebuilding auth state',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      var notifications = 0;
      harness.controller.addListener(() => notifications++);
      final firstEntry = harness.controller.initialize();
      final secondEntry = harness.controller.initialize();
      expect(identical(firstEntry, secondEntry), isTrue);
      await firstEntry;
      await tester.pump();
      final localState = harness.controller.state;
      final refreshed = _savedSession().copyWith(
        token: 'refreshed-access-token',
        refreshToken: 'rotated-refresh-token',
      );

      harness.client.refresh.complete(refreshed);
      await tester.pump();
      harness.client.status.complete(true);
      await tester.pump();
      await harness.controller.initialize();

      expect(harness.controller.state, same(localState));
      expect(harness.manager.authInfo?.token, refreshed.token);
      expect(
        (await harness.manager.storage.get())?.refreshToken,
        refreshed.refreshToken,
      );
      expect(harness.client.calls, [
        'jwtRefresh.refreshAccessToken',
        'serverpod_auth_core.status.isSignedIn',
      ]);
      expect(notifications, 1);
    },
  );

  testWidgets(
    'requires sign-in only after the SDK confirms the saved session was revoked',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));

      await harness.controller.initialize();
      await tester.pump();
      expect(harness.controller.state, isA<AuthAuthenticated>());
      harness.client.refresh.completeError(RefreshTokenNotFoundException());
      await tester.pump();

      expect(harness.controller.state, isA<AuthUnauthenticated>());
      final state = harness.controller.state as AuthUnauthenticated;
      expect(state.hasAccount, isTrue);
      expect(state.errorMessage, isNotEmpty);
      expect(harness.manager.isAuthenticated, isFalse);
      expect(harness.prefs.getString('serverpod_auth_success_key'), isNull);
      expect(harness.prefs.getString('motaz_signed_in_email'), isNull);
      expect(harness.prefs.getString('local_data_marker'), 'keep-local-data');
      expect(harness.client.calls, [
        'jwtRefresh.refreshAccessToken',
        'serverpod_auth_core.status.signOutDevice',
      ]);
    },
  );

  testWidgets(
    'opens first-use auth immediately while owner-account discovery is stalled',
    (tester) async {
      final harness = await _AuthHarness.create(
        withSession: false,
        withEmail: false,
        hasAccount: false,
      );
      addTearDown(() => harness.close(tester));

      await harness.controller.initialize();
      await tester.pump();

      expect(harness.controller.state, isA<AuthUnauthenticated>());
      expect(
        (harness.controller.state as AuthUnauthenticated).hasAccount,
        isFalse,
      );
      expect(harness.client.owner.isCompleted, isFalse);
      expect(harness.client.calls, ['auth.hasOwnerAccount']);

      harness.client.owner.complete(true);
      await tester.pump();

      expect(
        (harness.controller.state as AuthUnauthenticated).hasAccount,
        isTrue,
      );
      expect(harness.prefs.getBool('motaz_has_account'), isTrue);
      expect(harness.manager.isAuthenticated, isFalse);
    },
  );

  testWidgets(
    'a late startup refresh cannot restore credentials after explicit sign-out',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      await harness.controller.initialize();
      await tester.pump();

      final signOut = harness.controller.signOut();
      await tester.pump();
      await signOut;
      expect(harness.manager.isAuthenticated, isFalse);

      harness.client.refresh.complete(
        _savedSession().copyWith(token: 'late-refresh-token'),
      );
      await tester.pump();
      harness.client.status.complete(true);
      await tester.pump();

      expect(harness.controller.state, isA<AuthUnauthenticated>());
      expect(harness.manager.isAuthenticated, isFalse);
      expect(harness.prefs.getString('serverpod_auth_success_key'), isNull);
      expect(harness.prefs.getString('motaz_signed_in_email'), isNull);
      expect(harness.prefs.getString('local_data_marker'), 'keep-local-data');
    },
  );

  testWidgets(
    'a late rejection of the previous session cannot sign out a newly signed-in user',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      await harness.controller.initialize();
      await tester.pump();
      final newSession = _savedSession().copyWith(
        authUserId: UuidValue.fromString(
          'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
        ),
        token: 'new-user-access-token',
        refreshToken: 'new-user-refresh-token',
      );
      harness.client.loginResult = newSession;

      final signIn = harness.controller.signIn(
        'new@example.test',
        'test-password',
      );
      await tester.pump();
      expect(await signIn, isTrue);
      harness.client.refresh.completeError(RefreshTokenNotFoundException());
      await tester.pump();

      expect(
        (harness.controller.state as AuthAuthenticated).email,
        'new@example.test',
      );
      expect(harness.manager.authInfo?.authUserId, newSession.authUserId);
      expect((await harness.manager.storage.get())?.token, newSession.token);
      expect(
        harness.prefs.getString('motaz_signed_in_email'),
        'new@example.test',
      );
      expect(harness.client.calls, [
        'jwtRefresh.refreshAccessToken',
        'emailIdp.login',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a cached email alone does not authenticate a device without saved credentials',
    (tester) async {
      final harness = await _AuthHarness.create(withSession: false);
      addTearDown(() => harness.close(tester));

      await harness.controller.initialize();
      await tester.pump();

      expect(harness.controller.state, isA<AuthUnauthenticated>());
      expect(
        (harness.controller.state as AuthUnauthenticated).hasAccount,
        isTrue,
      );
      expect(harness.manager.isAuthenticated, isFalse);
      expect(harness.client.calls, ['auth.hasOwnerAccount']);
      expect(harness.client.owner.isCompleted, isFalse);
      expect(harness.prefs.getString('local_data_marker'), 'keep-local-data');
      harness.client.owner.complete(true);
      await tester.pump();
    },
  );

  testWidgets(
    'ignores owner discovery after the user signs in during startup',
    (tester) async {
      final harness = await _AuthHarness.create(
        withSession: false,
        withEmail: false,
        hasAccount: false,
      );
      addTearDown(() => harness.close(tester));
      await harness.controller.initialize();
      await tester.pump();
      harness.client.loginResult = _savedSession();

      final signIn = harness.controller.signIn(_email, 'test-password');
      await tester.pump();
      expect(await signIn, isTrue);
      harness.client.owner.complete(false);
      await tester.pump();

      expect(harness.controller.state, isA<AuthAuthenticated>());
      expect(harness.prefs.getBool('motaz_has_account'), isTrue);
      expect(harness.prefs.getString('motaz_signed_in_email'), _email);
      expect(harness.manager.isAuthenticated, isTrue);
      expect(harness.client.calls, ['auth.hasOwnerAccount', 'emailIdp.login']);
    },
  );

  testWidgets(
    'does not notify a disposed auth controller when validation finishes later',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(harness.client.close);
      await harness.controller.initialize();
      await tester.pump();
      var notifications = 0;
      harness.controller.addListener(() => notifications++);

      harness.controller.dispose();
      harness.client.refresh.completeError(RefreshTokenNotFoundException());
      await tester.pump();

      expect(notifications, 0);
      expect(tester.takeException(), isNull);
      expect(harness.prefs.getString('local_data_marker'), 'keep-local-data');
    },
  );

  testWidgets(
    'SDK restore used before runApp loads expired saved tokens without any endpoint call',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      expect(harness.manager.isAuthenticated, isFalse);

      await harness.manager.restore();

      expect(harness.manager.isAuthenticated, isTrue);
      expect(harness.manager.authInfo?.token, 'saved-access-token');
      expect(harness.manager.authInfo?.tokenExpiresAt, DateTime.utc(2020));
      expect(harness.manager.authInfo?.refreshToken, 'saved-refresh-token');
      expect(harness.client.calls, isEmpty);
      expect(harness.client.refresh.isCompleted, isFalse);
    },
  );

  testWidgets(
    'transient refresh failure does not check stale access tokens or sign out',
    (tester) async {
      final harness = await _AuthHarness.create();
      addTearDown(() => harness.close(tester));
      await harness.controller.initialize();
      await tester.pump();
      harness.client.status.complete(false);

      harness.client.refresh.completeError(
        ServerpodClientInternalServerError(),
      );
      await tester.pump();

      expect(harness.controller.state, isA<AuthAuthenticated>());
      expect(harness.manager.isAuthenticated, isTrue);
      expect(
        (await harness.manager.storage.get())?.refreshToken,
        'saved-refresh-token',
      );
      expect(harness.prefs.getString('motaz_signed_in_email'), _email);
      expect(harness.client.calls, ['jwtRefresh.refreshAccessToken']);
    },
  );
}
