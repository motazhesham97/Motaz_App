import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  late Future<String> _logFuture;

  @override
  void initState() {
    super.initState();
    _logFuture = AppLogger.getLogContents();
  }

  void _reload() {
    setState(() {
      _logFuture = AppLogger.getLogContents();
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
          onPressed: _goBack,
        ),
        title: const Text('سجل الأخطاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'مسح السجل',
            onPressed: () async {
              await AppLogger.clearLog();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح السجل')),
              );
              _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _logFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final content = snapshot.data ?? '';
          if (content.isEmpty) {
            return const Center(child: Text('لا توجد سجلات'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          );
        },
      ),
    );
  }
}
