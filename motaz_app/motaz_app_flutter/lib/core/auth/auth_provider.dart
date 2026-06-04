import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motaz_app_client/motaz_app_client.dart';

import '../logging/app_logger.dart';
import '../server/local_server_launcher.dart';
import '../server/server_client_provider.dart';
import 'auth_state.dart';

const _hasAccountKey = 'motaz_has_account';
const _signedInEmailKey = 'motaz_signed_in_email';

class AuthController extends ChangeNotifier {
  AuthController({
    required dynamic client,
    required dynamic sessionManager,
    LocalServerLauncher? localServerLauncher,
  }) : _client = client,
       _sessionManager = sessionManager,
       _localServerLauncher = localServerLauncher;

  final dynamic _client;
  final dynamic _sessionManager;
  final LocalServerLauncher? _localServerLauncher;

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final cachedHasAccount = prefs.getBool(_hasAccountKey) ?? false;
    String? cachedSignedInEmail = prefs.getString(_signedInEmailKey);

    final initialCachedEmail = cachedSignedInEmail?.trim();
    if (initialCachedEmail != null && initialCachedEmail.isNotEmpty) {
      try {
        final sessionValid = await _tryInitializeSessionManager();
        if (sessionValid) {
          _state = AuthAuthenticated(initialCachedEmail);
          await prefs.setBool(_hasAccountKey, true);
          notifyListeners();
          return;
        }

        try {
          final hasAccount = await _client.auth.hasOwnerAccount();
          await prefs.setBool(_hasAccountKey, hasAccount);
          _state = AuthUnauthenticated(
            hasAccount: hasAccount,
            errorMessage:
                'انتهت جلسة الدخول. سجل الدخول مرة واحدة لتفعيل المزامنة.',
          );
          notifyListeners();
          return;
        } catch (_) {
          // Server is not reachable, keep the cached local session for offline use.
        }

        _state = AuthAuthenticated(initialCachedEmail);
        await prefs.setBool(_hasAccountKey, true);
        notifyListeners();
        return;
      } catch (error, stackTrace) {
        _logSessionInitializationFailure(
          error,
          stackTrace,
          hasCachedSession: true,
        );

        if (_isInvalidSessionError(error)) {
          await _clearLocalSession();
          cachedSignedInEmail = null;
        } else {
          final cachedEmail = cachedSignedInEmail?.trim();
          if (cachedEmail == null || cachedEmail.isEmpty) {
            await _clearLocalSession();
            cachedSignedInEmail = null;
          } else {
            _state = AuthAuthenticated(cachedEmail);
            await prefs.setBool(_hasAccountKey, true);
            notifyListeners();
            return;
          }
        }
      }
    } else {
      try {
        final sessionValid = await _tryInitializeSessionManager();

        if (!sessionValid) {
          await _clearLocalSession();
        }
      } catch (error, stackTrace) {
        _logSessionInitializationFailure(
          error,
          stackTrace,
          hasCachedSession: false,
        );

        if (_isInvalidSessionError(error)) {
          await _clearLocalSession();
        }
      }
    }

    try {
      final cachedEmail = cachedSignedInEmail?.trim();
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        _state = AuthAuthenticated(cachedEmail);
        await prefs.setBool(_hasAccountKey, true);
        notifyListeners();
        return;
      }
      final hasAccount = await _client.auth.hasOwnerAccount();

      await prefs.setBool(_hasAccountKey, hasAccount);

      _state = AuthUnauthenticated(hasAccount: hasAccount);
    } catch (error, stackTrace) {
      AppLogger.auth.warning(
        'Falling back to cached auth state: $error\n$stackTrace',
      );

      final cachedEmail = cachedSignedInEmail?.trim();
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        _state = AuthAuthenticated(cachedEmail);
        await prefs.setBool(_hasAccountKey, true);
        notifyListeners();
        return;
      }

      _state = AuthUnauthenticated(
        hasAccount: cachedHasAccount,
        errorMessage: cachedHasAccount
            ? 'تعذر الوصول إلى الخادم حالياً'
            : _userFacingError(error),
      );
    }

    notifyListeners();
  }

  Future<bool> register(String email, String password) async {
    final normalizedEmail = email.trim();

    try {
      await _client.auth.registerOwner(
        email: normalizedEmail,
        password: password,
      );

      final success = await signIn(normalizedEmail, password);

      if (!success) {
        _state = const AuthUnauthenticated(
          hasAccount: true,
          errorMessage: 'تم إنشاء الحساب لكن تعذر تسجيل الدخول',
        );
        notifyListeners();
      }

      return success;
    } catch (error, stackTrace) {
      AppLogger.auth.warning(
        'Registration failed: $error\n$stackTrace',
      );

      if (_isOwnerAlreadyExistsError(error)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_hasAccountKey, true);

        _state = const AuthUnauthenticated(
          hasAccount: true,
          errorMessage: 'يوجد حساب مالك بالفعل',
        );
        notifyListeners();
        return false;
      }

      _state = AuthUnauthenticated(
        hasAccount: false,
        errorMessage: _userFacingError(error),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    final normalizedEmail = email.trim();

    try {
      final authSuccess = await _client.emailIdp.login(
        email: normalizedEmail,
        password: password,
      );

      await _storeSignedInSession(authSuccess);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasAccountKey, true);
      await prefs.setString(_signedInEmailKey, normalizedEmail);

      final signedInEmail =
          _emailFromAuthSuccess(authSuccess) ??
          _signedInUserEmail() ??
          normalizedEmail;

      _state = AuthAuthenticated(signedInEmail);
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      AppLogger.auth.warning(
        'Sign-in failed: $error\n$stackTrace',
      );

      _state = AuthUnauthenticated(
        hasAccount: true,
        errorMessage: _userFacingError(
          error,
          fallback: 'فشل تسجيل الدخول',
        ),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _sessionManager.signOutDevice();
    } catch (error, stackTrace) {
      AppLogger.auth.warning(
        'Sign-out failed: $error\n$stackTrace',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAccountKey, true);
    await prefs.remove(_signedInEmailKey);

    await _removeStoredAuthKey();

    _state = const AuthUnauthenticated(hasAccount: true);
    notifyListeners();
  }

  Future<bool> _tryInitializeSessionManager() async {
    try {
      await _waitForLocalServerIfNeeded();

      final result = _sessionManager.initialize(
        timeout: const Duration(seconds: 12),
      );
      bool initialized;
      if (result is Future) {
        final value = await result.timeout(const Duration(seconds: 14));
        initialized = value != false;
      } else if (result is bool) {
        initialized = result;
      } else {
        initialized = true;
      }

      final hasStoredAuthSession = _storedAuthSessionState();
      if (hasStoredAuthSession != null) {
        if (!hasStoredAuthSession) return false;
      }

      final serverValidated = await _validateServerAuthentication();
      return serverValidated ?? initialized;
    } on NoSuchMethodError {
      // Some SessionManager implementations are initialized elsewhere.
      return true;
    }
  }

  Future<void> _waitForLocalServerIfNeeded() async {
    final launcher = _localServerLauncher;
    if (launcher == null || !launcher.shouldAutoStart) return;

    final ready = await launcher.ensureReady(
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(milliseconds: 500),
    );
    if (!ready) {
      AppLogger.auth.info(
        'Local Serverpod was not ready before auth session initialization.',
      );
    }
  }

  void _logSessionInitializationFailure(
    Object error,
    StackTrace stackTrace, {
    required bool hasCachedSession,
  }) {
    final message = 'Session initialization failed: $error\n$stackTrace';
    if (hasCachedSession && error is TimeoutException) {
      AppLogger.auth.info(message);
      return;
    }
    AppLogger.auth.warning(message);
  }

  Future<bool?> _validateServerAuthentication() async {
    try {
      final result = _sessionManager.validateAuthentication();
      if (result is Future) {
        final value = await result.timeout(const Duration(seconds: 8));
        if (value is bool) return value;
        return true;
      }
      if (result is bool) return result;
      return true;
    } on NoSuchMethodError {
      return null;
    } on TimeoutException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.auth.warning(
        'Server auth validation failed: $error\n$stackTrace',
      );
      return false;
    }
  }

  bool? _storedAuthSessionState() {
    try {
      final isAuthenticated = _sessionManager.isAuthenticated;
      if (isAuthenticated is bool) {
        return isAuthenticated;
      }
      return null;
    } on NoSuchMethodError {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeSignedInSession(dynamic authSuccess) async {
    try {
      final result = _sessionManager.updateSignedInUser(authSuccess);
      if (result is Future) {
        await result;
      }
      return;
    } on NoSuchMethodError {
      // Older SessionManager API fallback below.
    }

    final userInfo = authSuccess.userInfo;
    final keyId = authSuccess.keyId;
    final key = authSuccess.key;

    if (userInfo == null || keyId == null || key == null) {
      throw StateError(
        'Sign-in response missing required session data.',
      );
    }

    await _sessionManager.registerSignedInUser(
      userInfo,
      keyId,
      key,
    );
  }

  Future<void> _removeStoredAuthKey() async {
    try {
      final result = _sessionManager.updateSignedInUser(null);
      if (result is Future) {
        await result;
      }
    } catch (error, stackTrace) {
      AppLogger.auth.warning(
        'Removing auth key failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInEmailKey);
    await _removeStoredAuthKey();
  }

  String? _signedInUserEmail() {
    try {
      final signedInUser = _sessionManager.signedInUser;
      final email = signedInUser?.email as String?;

      if (email == null || email.trim().isEmpty) {
        return null;
      }

      return email.trim();
    } catch (_) {
      return null;
    }
  }

  String? _emailFromAuthSuccess(dynamic authSuccess) {
    try {
      final email = authSuccess.userInfo?.email as String?;

      if (email == null || email.trim().isEmpty) {
        return null;
      }

      return email.trim();
    } catch (_) {
      return null;
    }
  }

  bool _isOwnerAlreadyExistsError(Object error) {
    final message = error.toString().toLowerCase();

    return message.contains('owner_already_exists') ||
        message.contains('owner already exists') ||
        message.contains('يوجد حساب مالك');
  }

  bool _isInvalidSessionError(Object error) {
    final message = error.toString().toLowerCase();

    return message.contains('refreshtokeninvalidsecret') ||
        message.contains('refreshtokennotfound') ||
        message.contains('refreshtokenexpired') ||
        message.contains('jwt expired') ||
        message.contains('failedunauthorized');
  }

  String _userFacingError(
    Object error, {
    String fallback = 'فشل إنشاء الحساب',
  }) {
    if (error is ServerpodClientBadRequest) {
      return 'الطلب غير صالح: ${error.message}';
    }

    if (error is ServerpodClientUnauthorized) {
      return 'فشل التحقق من الجلسة';
    }

    if (error is ServerpodClientForbidden) {
      return 'ليس لديك صلاحية لإجراء هذه العملية';
    }

    if (error is ServerpodClientNotFound) {
      return 'تعذر العثور على مسار الخادم المطلوب';
    }

    if (error is ServerpodClientInternalServerError) {
      return 'حدث خطأ داخلي في الخادم أثناء تنفيذ الطلب';
    }

    if (error is ServerpodClientException) {
      return 'فشل الطلب من الخادم: ${error.message}';
    }

    final message = error.toString().toLowerCase();

    if (message.contains('invalidcredentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }

    if (message.contains('timeout')) {
      final host = _clientHost();

      return host == null
          ? 'استغرق الخادم وقتا طويلا للرد. اترك Serverpod يعمل ثم أعد المحاولة.'
          : 'استغرق الخادم وقتا طويلا للرد: $host\nاترك Serverpod يعمل ثم أعد المحاولة.';
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('connection closed') ||
        message.contains('timeout')) {
      final host = _clientHost();

      return host == null
          ? 'تعذر الوصول إلى الخادم. تحقق من تشغيل Serverpod أو من ملف config.json بجانب التطبيق.'
          : 'تعذر الوصول إلى الخادم: $host\nتحقق من تشغيل Serverpod أو من ملف config.json بجانب التطبيق.';
    }

    if (message.contains('no such method')) {
      return 'حدث خطأ في إدارة جلسة تسجيل الدخول داخل التطبيق';
    }

    return fallback;
  }

  String? _clientHost() {
    try {
      final host = (_client.host as String?)?.trim();

      if (host == null || host.isEmpty) {
        return null;
      }

      return host;
    } catch (_) {
      return null;
    }
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    client: ref.watch(serverpodClientProvider),
    sessionManager: ref.watch(sessionManagerProvider),
    localServerLauncher: ref.watch(localServerLauncherProvider),
  );

  controller.initialize();

  return controller;
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider).state;
});
