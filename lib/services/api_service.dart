// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // IP 10.0.2.2 adalah IP localhost komputer jika diakses dari Emulator Android Studio.
  // Jika pakai HP fisik, ganti dengan IP Address Laptop (misal: 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2/resto_api/api';

  /// Method POST untuk mengirim data (Login, Create Order, Update Status)
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    
    // Debugging Logs
    print('------------------------------------------------');
    print('🔵 POST Request: $url');
    print('📦 Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10)); // Timeout 10 detik

      print('🟢 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('------------------------------------------------');

      return _handleResponse(response);
    } on SocketException {
      return _errorResponse('Tidak ada koneksi internet / Server tidak dapat dijangkau');
    } on http.ClientException {
      return _errorResponse('Terjadi kesalahan pada Client HTTP');
    } catch (e) {
      return _errorResponse('Error tidak dikenal: $e');
    }
  }

  /// Method GET untuk mengambil data (List Menu, List Order, Status Meja)
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    // Debugging Logs
    print('------------------------------------------------');
    print('🔵 GET Request: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('🟢 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('------------------------------------------------');

      return _handleResponse(response);
    } on SocketException {
      return _errorResponse('Tidak ada koneksi internet / Server tidak dapat dijangkau');
    } catch (e) {
      return _errorResponse('Error: $e');
    }
  }

  /// Helper untuk menghandle response dari PHP
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      // Jika PHP mengembalikan status 200/201 tapi flag success false
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'success': true, 'data': data};
      } else {
        // Jika server error (400, 404, 500)
        return {
          'success': false,
          'message': data['message'] ?? 'Terjadi kesalahan pada server (${response.statusCode})',
        };
      }
    } catch (e) {
      // Jika response bukan JSON valid (misal Error PHP HTML)
      print('🔴 JSON Decode Error: $e');
      return {
        'success': false,
        'message': 'Respon server tidak valid. Cek log server.',
      };
    }
  }

  /// Helper untuk membuat pesan error standar
  static Map<String, dynamic> _errorResponse(String message) {
    print('🔴 Error: $message');
    return {
      'success': false,
      'message': message,
    };
  }
}