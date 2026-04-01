import 'package:dio/dio.dart';

class NetworkConfig {
  static Dio createDioWithProxy() {
    // Try different configurations to bypass network restrictions
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      // Try different user agents
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      },
    ));
  }
  
  static Future<bool> testConnection(String url) async {
    try {
      final dio = createDioWithProxy();
      final response = await dio.get(url, options: Options(
        receiveTimeout: const Duration(seconds: 5),
      ));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed for $url: $e');
      return false;
    }
  }
}
