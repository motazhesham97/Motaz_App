import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../application/product_providers.dart';
import 'product_form_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
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
    final productsAsync = _searchQuery.isEmpty
        ? ref.watch(productListProvider)
        : ref.watch(productSearchProvider(_searchQuery));

    return AppDrawerScaffold(
      title: 'المنتجات',
      currentRoute: '/products',
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductFormScreen(),
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
                hintText: 'بحث عن منتج...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const Center(
                child: Text('لا توجد منتجات'),
              );
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final priceText =
                    '${(product.defaultSalePrice / 100).toStringAsFixed(2)} ر.ي.';
                final subtitle = product.unit != null
                    ? '$priceText • ${product.unit}'
                    : priceText;
                return Opacity(
                  opacity: product.isActive ? 1.0 : 0.6,
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Row(
                      children: [
                        Text(subtitle),
                        if (!product.isActive) ...[
                          const SizedBox(width: 8),
                          const Text('معطّل',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        final repo = ref.read(productRepositoryProvider);
                        repo.toggleActive(product.id, !product.isActive);
                      },
                      itemBuilder: (context) => [PopupMenuItem(value: 'toggle', child: Text(product.isActive ? 'تعطيل' : 'تفعيل'))],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(
                            existingProduct: product,
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
