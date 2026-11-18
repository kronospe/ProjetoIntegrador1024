class AppConfig {
  /// URL base do backend Django (sem /api no final).
  ///
  /// Emulador Android:  http://10.0.2.2:8000   (padrão)
  /// Simulador iOS/web: http://localhost:8000
  /// Celular físico:    http://IP_DO_SEU_PC:8000
  /// Produção:          https://seu-dominio.com
  ///
  /// Troque sem mexer no código:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
