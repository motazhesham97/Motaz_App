class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.runMode,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiUrl: json['apiUrl'] as String? ?? 'http://localhost:8080',
      runMode: json['runMode'] as String? ?? 'development',
    );
  }

  final String apiUrl;
  final String runMode;
}
