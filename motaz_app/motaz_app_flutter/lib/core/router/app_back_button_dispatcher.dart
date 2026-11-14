import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  AppBackButtonDispatcher({
    required this.router,
    required this.rootNavigatorKey,
    required this.shellNavigatorKey,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    router.routerDelegate.addListener(_resetExitRequest);
  }

  static const exitWindow = Duration(seconds: 2);

  final GoRouter router;
  final GlobalKey<NavigatorState> rootNavigatorKey;
  final GlobalKey<NavigatorState> shellNavigatorKey;
  final DateTime Function() _now;

  DateTime? _lastHomeBack;
  OverlayEntry? _hint;
  Timer? _hintTimer;
  bool _handlingBack = false;
  bool _dialogVisible = false;
  bool _disposed = false;

  bool onNavigationNotification(NavigationNotification notification) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.detached) {
      // Android predictive back must reach Flutter even on the shell's first
      // page, where a Navigator alone reports that it has nothing to pop.
      unawaited(
        SystemNavigator.setFrameworkHandlesBack(
          shellNavigatorKey.currentState != null || notification.canHandlePop,
        ),
      );
    }
    return true;
  }

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) async {
    if (_handlingBack || _disposed) {
      return true;
    }
    _handlingBack = true;
    try {
      // Let dialogs, pushed pages and their pop guards handle back first.
      if (await super.invokeCallback(defaultValue)) {
        _resetExitRequest();
        return true;
      }

      // go_router skips a shell's first route when it cannot pop. Its form
      // guards and local history must still get a chance to consume back.
      if (await shellNavigatorKey.currentState?.maybePop() ?? false) {
        _resetExitRequest();
        return true;
      }
      if (_disposed || shellNavigatorKey.currentState == null) {
        return false;
      }

      if (router.routerDelegate.currentConfiguration.uri.path != '/home') {
        _resetExitRequest();
        router.go('/home');
        return true;
      }
      if (_dialogVisible) {
        return true;
      }

      final context = rootNavigatorKey.currentState?.overlay?.context;
      if (context == null || !context.mounted) {
        return true;
      }
      final now = _now();
      final elapsed = _lastHomeBack == null
          ? null
          : now.difference(_lastHomeBack!);
      if (elapsed != null && !elapsed.isNegative && elapsed <= exitWindow) {
        _resetExitRequest();
        unawaited(_confirmExit(context));
      } else {
        _lastHomeBack = now;
        _hideHint();
        _hint = OverlayEntry(
          builder: (context) => Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              child: Center(
                child: Material(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(4),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'اضغط رجوع مرة أخرى لطلب الخروج',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        rootNavigatorKey.currentState!.overlay!.insert(_hint!);
        _hintTimer = Timer(exitWindow, _hideHint);
      }
      return true;
    } finally {
      _handlingBack = false;
    }
  }

  Future<void> _confirmExit(BuildContext context) async {
    _dialogVisible = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('هل تريد الخروج من التطبيق؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (confirmed == true &&
          !_disposed &&
          router.routerDelegate.currentConfiguration.uri.path == '/home') {
        await SystemNavigator.pop();
      }
    } finally {
      _dialogVisible = false;
      _lastHomeBack = null;
    }
  }

  void _resetExitRequest() {
    _lastHomeBack = null;
    _hideHint();
  }

  void _hideHint() {
    _hintTimer?.cancel();
    _hintTimer = null;
    _hint?.remove();
    _hint?.dispose();
    _hint = null;
  }

  void dispose() {
    _disposed = true;
    _hideHint();
    router.routerDelegate.removeListener(_resetExitRequest);
  }
}
