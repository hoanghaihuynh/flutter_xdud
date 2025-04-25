class AppConfig {
  static const String baseUrl = 'http://192.168.1.150:3000';

  static String getApiUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}
