import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../clients/application/client_providers.dart';
import '../application/invoice_providers.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() =>
      _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = _searchQuery.isEmpty
        ? ref.watch(invoiceListProvider)
        : ref.watch(invoiceSearchProvider(_searchQuery));
    final clientsAsync = ref.watch(clientListProvider);

    return AppDrawerScaffold(
      title: 'الفواتير',
      currentRoute: '/invoices',
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InvoiceFormScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText:
                      'بحث عن فاتورة...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: invoicesAsync.when(
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return const Center(
                      child: Text('لا توجد فاتورات'),
                    );
                  }

                  final clientMap = <String, Client>{};
                  clientsAsync.whenData(
                    (clients) {
                      for (final c in clients) {
                        clientMap[c.id] = c;
                      }
                    },
                  );

                  return ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      final clientName =
                          clientMap[invoice.clientId]?.displayName ??
                              'عميل محذوف';
                      final totalText =
                          '${(invoice.total / 100).toStringAsFixed(2)} ر.ي.';
                      final isVoided = invoice.status.index == 1;

return Opacity(
                         opacity: isVoided ? 0.6 : 1.0,
                         child: ListTile(
                           title: Text(invoice.localRef),
                           subtitle: Row(
                             children: [
                               Text('$clientName • $totalText'),
                               if (isVoided) ...[
                                 const SizedBox(width: 8),
                                 const Text('ملغية',
                                     style: TextStyle(color: Colors.red)),
                               ],
                             ],
                           ),
                           trailing: invoice.status == RecordStatus.ACTIVE
                               ? PopupMenuButton<String>(
                                   icon: const Icon(Icons.more_vert),
                                   onSelected: (value) {
                                     if (value == 'return') {
                                       context.go(
                                           '/returns/create?invoiceId=${invoice.id}');
                                     }
                                   },
                                   itemBuilder: (context) => [
                                     const PopupMenuItem(
                                       value: 'return',
                                       child: Text('إنشاء مرتجع'),
                                     ),
                                   ],
                                 )
                               : null,
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (_) => InvoiceDetailScreen(
                                   invoiceId: invoice.id,
                                 ),
                               ),
                             );
                           },
                         ),
                       );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text(e.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
