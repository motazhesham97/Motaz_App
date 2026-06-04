import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/follow_up_task.dart';

class FollowUpNotificationService {
  FollowUpNotificationService._();

  static const MethodChannel _channel = MethodChannel('fastika/notifications');
  static const _seenTaskKeys = 'fastika_seen_follow_up_task_keys';
  static const _lastDailyReminderKey = 'fastika_last_follow_up_daily_reminder';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('initialize');
    }
    _initialized = true;
  }

  static Future<void> notifyForTasks(List<FollowUpTask> tasks) async {
    if (!_initialized || tasks.isEmpty || !Platform.isAndroid) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentKeys = tasks.map(_taskKey).toSet();
    final seenKeys = prefs.getStringList(_seenTaskKeys)?.toSet() ?? <String>{};
    final hasNewTask = currentKeys.any((key) => !seenKeys.contains(key));

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastDailyReminder = prefs.getString(_lastDailyReminderKey);

    if (hasNewTask) {
      await _show(
        id: 4101,
        title: 'مهام متابعة جديدة',
        body: 'لديك ${tasks.length} مهمة تحتاج متابعة.',
      );
      await prefs.setStringList(_seenTaskKeys, currentKeys.toList());
      await prefs.setString(_lastDailyReminderKey, todayKey);
      return;
    }

    if (lastDailyReminder != todayKey) {
      await _show(
        id: 4102,
        title: 'تذكير مهام المتابعة',
        body: 'لديك ${tasks.length} مهمة متابعة معلقة.',
      );
      await prefs.setString(_lastDailyReminderKey, todayKey);
    }
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _channel.invokeMethod<void>('show', {
      'id': id,
      'title': title,
      'body': body,
    });
  }

  static String _taskKey(FollowUpTask task) {
    return [
      task.type.name,
      task.clientId,
      task.invoiceId ?? '',
      task.invoiceLineId ?? '',
      task.productId ?? '',
    ].join('|');
  }
}
