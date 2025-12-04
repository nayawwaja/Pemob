import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _staffCodeController = TextEditingController(); // KUNCI UTAMA
  
  // State
  String _selectedRole = 'waiter'; 
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Daftar Role yang tersedia untuk pendaftaran via Aplikasi
  // Admin tidak ditaruh di sini demi keamanan (biasanya by database)
  final Map<String, String> _roles = {
    'waiter': 'Pelayan / Waiter',
    'chef': 'Chef / Koki',
    'cs': 'Customer Service (Kasir)',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _staffCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi Password Match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan Konfirmasi tidak cocok'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Kirim Data ke API
    final result = await ApiService.post('auth.php?action=register', {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'password': _passwordController.text,
      'role': _selectedRole, 
      'staff_code': _staffCodeController.text, // WAJIB DIKIRIM
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // Sukses
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Registrasi Berhasil', style: TextStyle(color: Color(0xFF4CAF50))),
          content: const Text(
            'Akun Anda berhasil dibuat. Silakan login sekarang.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              onPressed: () {
                Navigator.pop(ctx); // Tutup Dialog
                Navigator.pop(context); // Kembali ke Login Screen
              },
              child: const Text('Login Sekarang', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      // Gagal (Misal: Kode salah, Email duplikat)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal registrasi'),
          backgroundColor: const Color(0xFFD7263D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Gradient Hitam
      body: Container(
        height: double.infinity,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.app_registration, size: 60, color: Color(0xFFD4AF37)),
                    const SizedBox(height: 16),
                    const Text(
                      'Gabung Tim Resto',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan Kode Akses dari Admin/Manager',
                      style: TextStyle(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // 1. Pilihan Role
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      dropdownColor: const Color(0xFF333333),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Posisi Lamaran', Icons.badge),
                      items: _roles.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 20),

                    // 2. Kode Validasi (WAJIB)
                    TextFormField(
                      controller: _staffCodeController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      decoration: _inputDecoration('Kode Akses Staff', Icons.vpn_key).copyWith(
                        hintText: 'Contoh: CHEF-8821-1200',
                        hintStyle: TextStyle(color: Colors.white24, letterSpacing: 0),
                      ),
                      validator: (val) => val!.isEmpty ? 'Kode akses wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // 3. Form Data Diri
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Nama Lengkap', Icons.person),
                      validator: (val) => val!.isEmpty ? 'Nama harus diisi' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (val) => !val!.contains('@') ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Nomor HP', Icons.phone),
                    ),
                    const SizedBox(height: 20),
                    
                    // 4. Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Password', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white60),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val!.length < 6 ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Konfirmasi Password', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white60),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Konfirmasi password' : null,
                    ),
                    const SizedBox(height: 40),
                    
                    // Tombol Register
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'DAFTAR SEKARANG',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun? ", style: TextStyle(color: Colors.white60)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text("Login", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }
}