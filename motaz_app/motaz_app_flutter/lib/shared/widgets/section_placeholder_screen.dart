import 'package:flutter/material.dart';

import 'app_drawer.dart';

class SectionPlaceholderScreen extends StatelessWidget {
  const SectionPlaceholderScreen({
    super.key,
    required this.title,
    required this.routePath,
  });

  final String title;
  final String routePath;

  @override
  Widget build(BuildContext context) {
    return AppDrawerScaffold(
      title: title,
      currentRoute: routePath,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_rounded, size: 48),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'هذه الشاشة قيد التنفيذ وستكون جاهزة في المرحلة القادمة.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
