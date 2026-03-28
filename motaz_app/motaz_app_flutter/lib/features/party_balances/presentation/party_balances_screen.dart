import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class PartyBalancesScreen extends StatelessWidget {
  const PartyBalancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'أرصدة الأطراف',
      icon: Icons.balance,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
