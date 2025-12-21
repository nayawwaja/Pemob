import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // WAJIB: Untuk format tanggal Indonesia
import 'screens/splash_screen.dart'; 

void main() async {
  // 1. Pastikan binding Flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi format tanggal (id_ID) untuk Dashboard & Laporan
  await initializeDateFormatting('id_ID', null);

  runApp(const RestoManagementApp());
}

class RestoManagementApp extends StatelessWidget {
  const RestoManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manajemen Restoran Ultimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Set default ke Dark Mode
        primaryColor: const Color(0xFFD4AF37), // Gold
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Dark Grey
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFD7263D), // Accent Red
          surface: Color(0xFF2A2A2A), // Card Color
          background: Color(0xFF1A1A1A),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 20
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIconColor: const Color(0xFFD4AF37),
        ),

        cardTheme: const CardThemeData(
          color: Color(0xFF2A2A2A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}