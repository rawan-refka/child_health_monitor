import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vital_reading.dart';

class Esp32VitalsClient {
  Esp32VitalsClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// عنوان الأساس مثل: `http://192.168.1.50` — يُطلب المسار `/vitals`.
  Future<VitalReading> fetchVitals(String baseUrl) async {
    final uri = _resolve(baseUrl, '/vitals').replace(
      queryParameters: <String, String>{
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await _http
        .get(
          uri,
          headers: const <String, String>{
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Esp32VitalsException('HTTP ${response.statusCode}');
    }
    final map = jsonDecode(response.body);
    if (map is! Map<String, dynamic>) {
      throw Esp32VitalsException('استجابة غير صالحة');
    }
    return VitalReading.fromJson(map);
  }

  Uri _resolve(String base, String path) {
    var b = base.trim();
    if (!b.startsWith('http://') && !b.startsWith('https://')) {
      b = 'http://$b';
    }
    b = b.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$b$path');
  }

  void close() => _http.close();
}

class Esp32VitalsException implements Exception {
  Esp32VitalsException(this.message);
  final String message;

  @override
  String toString() => message;
}
