
class AppConfig {
  static const String baseUrl =
      'http://172.20.13.167:3000'; // Đây là base URL cho API endpoints (có thể bao gồm /api hoặc không)
  static const String _fileServerBaseUrl = 'http://172.20.13.167:3000';

  static String getApiUrl(String endpoint) {
    // Giả sử endpoint bạn truyền vào không có dấu / ở đầu, ví dụ: 'products/getAll'
    // Hoặc nếu endpoint luôn có / ở đầu (ví dụ: '/products/getAll'), thì không cần dấu / sau baseUrl
    return baseUrl + (endpoint.startsWith('/') ? endpoint : '/$endpoint');
  }

  static String getBaseUrlForFiles() {
    return _fileServerBaseUrl;
  }
}
