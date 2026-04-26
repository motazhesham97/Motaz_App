import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الأخطاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          );
        },
      ),
    );
  }
}
