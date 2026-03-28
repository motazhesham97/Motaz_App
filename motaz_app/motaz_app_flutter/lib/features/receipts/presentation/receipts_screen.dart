import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'الإيصالات',
      icon: Icons.receipt,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
