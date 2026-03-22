import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  container.read(appDatabaseProvider);
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MotazApp(),
    ),
  );
}
