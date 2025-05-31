class AppConfig {
  static const String baseUrl = 'http://172.20.10.13:3000';

  static String getApiUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}
