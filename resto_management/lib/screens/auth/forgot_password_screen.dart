import 'package:flutter/material.dart';

/// Layar informasi untuk reset password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF000000),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildInfoContent(),
          ),
        ),
      ),
    );
  }

  /// Membangun konten informasi kontak admin
  Widget _buildInfoContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            size: 60,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Hubungi Admin',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Untuk alasan keamanan, reset password hanya dapat dilakukan oleh Administrator.\n\nSilakan hubungi Admin atau Manager Restoran untuk mendapatkan password baru.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white60,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'KEMBALI KE LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
