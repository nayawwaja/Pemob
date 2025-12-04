// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

// --- IMPORT DASHBOARDS ---
import '../admin/admin_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../kitchen_screen.dart';
import '../waiter_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    // 1. Panggil API Login
    final result = await ApiService.post('auth.php?action=login', {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // 2. Ambil Data User & Token
      final userData = result['data']['user'];
      final token = result['data']['token'];
      
      // Gunakan Model User (pastikan model sesuai dengan respons JSON)
      // Jika model belum update, kita bisa akses map langsung:
      int userId = int.parse(userData['id'].toString());
      String name = userData['name'];
      String role = userData['role'];
      String email = userData['email'];

      // 3. Simpan Sesi (PENTING untuk Absensi & Order)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('userId', userId);
      await prefs.setString('name', name);
      await prefs.setString('role', role);
      await prefs.setString('email', email);
      
      // Reset status shift saat login baru (keamanan)
      await prefs.setBool('isShiftStarted', false); 

      if (!mounted) return;

      // 4. Routing Berdasarkan Role
      Widget nextScreen;
      switch (role) {
        case 'admin':
          nextScreen = const AdminDashboard();
          break;
        case 'chef':
          nextScreen = const KitchenScreen();
          break;
        case 'waiter':
          nextScreen = const WaiterScreen();
          break;
        case 'cs':
        case 'manager':
          // CS dan Manager masuk ke Staff Dashboard (Pusat Operasional)
          nextScreen = const StaffDashboard(); 
          break;
        default:
          nextScreen = const StaffDashboard(); // Fallback
      }

      // Pindah Halaman & Hapus History Login (agar tidak bisa back)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => nextScreen),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selamat Datang, $name ($role)"), 
          backgroundColor: Colors.green
        )
      );

    } else {
      // Tampilkan Error Login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login gagal'),
          backgroundColor: const Color(0xFFD7263D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Hitam Elegan dengan Gradient Halus
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO & JUDUL
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37), // Emas
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.restaurant_menu, size: 50, color: Colors.black),
                    ),
                    const SizedBox(height: 30),
                    
                    const Text(
                      'RESTO PRO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistem Manajemen Restoran Terintegrasi',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 40),

                    // INPUT EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email Staff',
                        prefixIcon: Icon(Icons.email, color: Color(0xFFD4AF37)),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                      ),
                      validator: (val) => val!.isEmpty ? 'Email wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // INPUT PASSWORD
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFD4AF37)),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white60,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Password wajib diisi' : null,
                    ),
                    const SizedBox(height: 30),

                    // TOMBOL LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'MASUK SISTEM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OPSI LAIN (Lupa Password & Register)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                          },
                          child: const Text('Lupa Password?', style: TextStyle(color: Colors.white54)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: const Text('Daftar Akun Baru', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    const Text("v2.0 Ultimate Build", style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}