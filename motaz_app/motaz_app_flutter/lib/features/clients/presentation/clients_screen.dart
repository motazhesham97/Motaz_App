import 'package:flutter/material.dart';

import '../../../shared/widgets/section_scaffold.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'العملاء',
      icon: Icons.people,
      message: 'هذه الشاشة قيد التجهيز وستتوفر قريباً.',
    );
  }
}
