import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'التقارير',
      icon: Icons.assessment,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
