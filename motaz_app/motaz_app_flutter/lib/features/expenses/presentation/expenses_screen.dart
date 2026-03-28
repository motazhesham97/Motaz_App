import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'المصروفات',
      icon: Icons.money_off,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
