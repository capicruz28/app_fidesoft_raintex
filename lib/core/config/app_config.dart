class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // URL fija del servidor central (NUNCA cambia, hardcodeada aquí y solo aquí)
  static const String urlCentral = 'https://fidesoft.stnsoluciones.pe/api/v1';

  String? _baseUrl;

  String get baseUrl {
    if (_baseUrl == null) {
      throw Exception(
        'AppConfig no inicializado. Debes obtener la conexión primero.',
      );
    }
    return _baseUrl!;
  }

  void setBaseUrl(String url) => _baseUrl = url;
  bool get isInitialized => _baseUrl != null;
}

