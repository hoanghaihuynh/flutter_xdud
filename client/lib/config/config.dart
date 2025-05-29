class AppConfig {
  static const String baseUrl = 'http://172.20.13.167:3000';

  static String getApiUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}
