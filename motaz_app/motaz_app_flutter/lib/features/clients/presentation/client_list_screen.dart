import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../application/client_providers.dart';
import 'client_form_screen.dart';
import 'client_summary_screen.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
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
    final clientsAsync = _searchQuery.isEmpty
        ? ref.watch(clientListProvider)
        : ref.watch(clientSearchProvider(_searchQuery));

    return AppDrawerScaffold(
      title: 'العملاء',
      currentRoute: '/clients',
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClientFormScreen(),
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
                hintText: 'بحث عن عميل...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: clientsAsync.when(
          data: (clients) {
            if (clients.isEmpty) {
              return const Center(
                child: Text('لا يوجد عملاء'),
              );
            }
            return ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final subtitle = client.phone ??
                    client.clientCode ??
                    client.email ??
                    '';
                return ListTile(
                  title: Text(client.displayName),
                  subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientSummaryScreen(
                          client: client,
                        ),
                      ),
                    );
                  },
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
