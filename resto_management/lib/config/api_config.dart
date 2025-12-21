  import 'dart:io';
  import 'package:flutter/foundation.dart';

  class ApiConfig {
    static const String _folderName = 'resto_api'; 

    static String get baseUrl {
      // Untuk development di emulator Android, IP 10.0.2.2 adalah alias untuk localhost komputer.
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2/$_folderName/api'; 
      }
      // Untuk development di web, iOS simulator, atau desktop, gunakan localhost.
      // Jika menggunakan HP fisik, ganti 'localhost' dengan IP address komputer Anda di jaringan WiFi yang sama (misal: '192.168.1.10').
      return 'http://localhost/$_folderName/api';
    }
  }