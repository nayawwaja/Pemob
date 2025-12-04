  import 'dart:io';
  import 'package:flutter/foundation.dart';

  class ApiConfig {
    static const String _folderName = 'resto_api'; 

    static String get baseUrl {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        return 'http://10.0.2.2/$_folderName';
      }
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2/$_folderName'; 
      }
      return 'http://10.0.2.2/$_folderName';
    }
  }