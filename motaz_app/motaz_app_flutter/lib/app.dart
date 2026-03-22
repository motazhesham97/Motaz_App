import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';

class MotazApp extends StatelessWidget {
  const MotazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق معتز',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      locale: AppTheme.locale,
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      builder: (context, child) {
        return Directionality(
          textDirection: AppTheme.textDirection,
          child: child ?? const Scaffold(
            body: Center(
              child: Text('تطبيق معتز'),
            ),
          ),
        );
      },
      
      home: const Scaffold(
        body: Center(
          child: Text('تطبيق معتز - الأساس جاهز'),
        ),
      ),
    );
  }
}
