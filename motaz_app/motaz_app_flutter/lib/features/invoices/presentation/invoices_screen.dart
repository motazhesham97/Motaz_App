import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'الفواتير',
      icon: Icons.receipt_long,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
