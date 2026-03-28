import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'لوحة التحكم',
      icon: Icons.dashboard,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
