import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'المنتجات',
      icon: Icons.inventory_2,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
