import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart' hide Client;
import '../../core/database/database_provider.dart';
import '../../core/database/enums/audit_operation.dart';
import '../../core/database/enums/parent_entity_type.dart';

Future<void> showAuditTrailSheet(
  BuildContext context,
  WidgetRef ref,
  ParentEntityType entityType,
  String entityId,
) async {
  final db = ref.read(appDatabaseProvider);
  final events = await (db.select(db.auditEvents)
        ..where((t) => t.entityType.equals(entityType.index))
        ..where((t) => t.entityId.equals(entityId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'سجل التعديلات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: events.isEmpty
                    ? const Center(
                        child: Text('لا يوجد سجل تعديلات'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _AuditEventListTile(event: event, db: db);
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _AuditEventListTile extends StatefulWidget {
  const _AuditEventListTile({required this.event, required this.db});

  final AuditEvent event;
  final AppDatabase db;

  @override
  State<_AuditEventListTile> createState() => _AuditEventListTileState();
}

class _AuditEventListTileState extends State<_AuditEventListTile> {
  late Future<String> _deviceNameFuture;

  @override
  void initState() {
    super.initState();
    _deviceNameFuture = _resolveDeviceName();
  }

  Future<String> _resolveDeviceName() async {
    try {
      final device = await (widget.db.select(widget.db.devices)
            ..where((t) => t.id.equals(widget.event.deviceId)))
          .getSingleOrNull();
      return device?.deviceName ?? 'جهاز غير معروف';
    } catch (_) {
      return 'جهاز غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final iconData = switch (event.operation) {
      AuditOperation.CREATE => Icons.add_circle,
      AuditOperation.UPDATE => Icons.edit,
      AuditOperation.VOID => Icons.cancel,
    };
    final iconColor = switch (event.operation) {
      AuditOperation.CREATE => Colors.green,
      AuditOperation.UPDATE => Colors.blue,
      AuditOperation.VOID => Colors.red,
    };
    final operationLabel = switch (event.operation) {
      AuditOperation.CREATE => 'إنشاء',
      AuditOperation.UPDATE => 'تعديل',
      AuditOperation.VOID => 'إلغاء',
    };
    final timestamp =
        '${event.createdAt.year}-${event.createdAt.month.toString().padLeft(2, '0')}-${event.createdAt.day.toString().padLeft(2, '0')} ${event.createdAt.hour.toString().padLeft(2, '0')}:${event.createdAt.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: Icon(iconData, color: iconColor),
      title: Text(operationLabel),
      subtitle: FutureBuilder<String>(
        future: _deviceNameFuture,
        builder: (context, snapshot) {
          final deviceName = snapshot.data ?? '...';
          return Text('$timestamp\n$deviceName');
        },
      ),
    );
  }
}
