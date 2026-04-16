import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motaz_app_client/motaz_app_client.dart';

import '../logging/app_logger.dart';
import '../server/server_client_provider.dart';
import 'auth_state.dart';

const _hasAccountKey = 'motaz_has_account';

class AuthController extends ChangeNotifier {
  AuthController({
    required dynamic client,
    required dynamic sessionManager,
  }) : _client = client,
       _sessionManager = sessionManager;

  final dynamic _client;
  final dynamic _sessionManager;

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final cachedHasAccount = prefs.getBool(_hasAccountKey) ?? false;

    if (_sessionManager.signedInUser != null) {
      final email = _sessionManager.signedInUser?.email ?? 'owner@local';
      _state = AuthAuthenticated(email);
      await prefs.setBool(_hasAccountKey, true);
      notifyListeners();
      return;
    }

    try {
      final hasAccount = await _client.auth.hasOwnerAccount();
      await prefs.setBool(_hasAccountKey, hasAccount);
      _state = AuthUnauthenticated(hasAccount: hasAccount);
    } catch (error) {
      AppLogger.auth.warning('Falling back to cached auth state: $error');
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
    try {
      await _client.auth.registerOwner(email: email, password: password);
      final success = await signIn(email, password);
      if (!success) {
        _state = const AuthUnauthenticated(
          hasAccount: true,
          errorMessage: 'تم إنشاء الحساب لكن تعذر تسجيل الدخول',
        );
        notifyListeners();
      }
      return success;
    } on OwnerAlreadyExistsException {
      _state = const AuthUnauthenticated(
        hasAccount: true,
        errorMessage: 'يوجد حساب مالك بالفعل',
      );
      notifyListeners();
      return false;
    } catch (error) {
      AppLogger.auth.warning('Registration failed: $error');
      _state = AuthUnauthenticated(
        hasAccount: false,
        errorMessage: _userFacingError(error),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final authSuccess = await _client.emailIdp.login(
        email: email,
        password: password,
      );
      final userInfo = authSuccess.userInfo;
      final keyId = authSuccess.keyId;
      final key = authSuccess.key;

      if (userInfo == null || keyId == null || key == null) {
        AppLogger.auth.warning(
          'Sign-in response missing required session data.',
        );
        _state = const AuthUnauthenticated(
          hasAccount: true,
          errorMessage: 'استجابة تسجيل الدخول غير مكتملة',
        );
        notifyListeners();
        return false;
      }

      await _sessionManager.registerSignedInUser(
        userInfo,
        keyId,
        key,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasAccountKey, true);
      _state = AuthAuthenticated(userInfo.email ?? email);
      notifyListeners();
      return true;
    } catch (error) {
      AppLogger.auth.warning('Sign-in failed: $error');
      _state = AuthUnauthenticated(
        hasAccount: true,
        errorMessage: _userFacingError(error, fallback: 'فشل تسجيل الدخول'),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _sessionManager.signOutDevice();
    _state = const AuthUnauthenticated(hasAccount: true);
    notifyListeners();
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
  );
  controller.initialize();
  return controller;
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider).state;
});
