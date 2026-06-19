# motaz_app_flutter

A new Flutter project with Serverpod.

## Getting Started

This project is a starting point for a Flutter application that is using
Serverpod.

A great starting point for learning Serverpod is our documentation site at:
[https://docs.serverpod.dev](https://docs.serverpod.dev).

To run the project, first make sure that the server is running, then do:

    flutter run

## QA notes

- Home quick actions: the first quick action is "إضافة مصروف" and must route to
  `/expenses`.
- Dashboard net profit: the value is hidden by default behind `*****`; tapping
  the visibility button reveals the formatted amount.

Focused tests for the latest UI changes:

    flutter test test/features/home/presentation/home_screen_test.dart
    flutter test test/features/dashboard/presentation/dashboard_screen_test.dart

Release artifacts:

    flutter build windows --release
    flutter build apk --release

Windows output is under `build/windows/x64/runner/Release/`.
Android APK output is `build/app/outputs/flutter-apk/app-release.apk`.
