import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'المرتجعات',
      icon: Icons.assignment_return,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
