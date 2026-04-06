import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(appDatabaseProvider));
});

final productListProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

final productSearchProvider =
    StreamProvider.family<List<Product>, String>((ref, query) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)
        ..where((t) => t.name.like('%$query%'))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

final activeProductSearchProvider =
    StreamProvider.family<List<Product>, String>((ref, query) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)
        ..where((t) => t.name.like('%$query%') & t.isActive.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});
