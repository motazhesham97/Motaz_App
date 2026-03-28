import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'الإعدادات',
      icon: Icons.settings,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
