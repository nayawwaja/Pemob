import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard.dart';   
import 'staff/staff_dashboard.dart';  
import 'kitchen_screen.dart';          
import 'waiter_screen.dart';           

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Tunggu animasi selesai (3 detik)
    await Future.delayed(const Duration(seconds: 3));
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userRole = prefs.getString('role');
    
    if (!mounted) return;
    
    if (token != null && userRole != null) {
      // --- LOGIKA ROUTING BERDASARKAN ROLE ---
      Widget nextScreen;

      switch (userRole) {
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
          nextScreen = const StaffDashboard();
          break;
        default:
          // Fallback jika role tidak dikenali
          nextScreen = const StaffDashboard();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } else {
      // Jika belum login, ke Login Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pastikan background hitam total
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu, // Ikon lebih relevan
                      size: 80,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'RESTO PRO',
                    style: TextStyle(
                      fontSize: 40, // Sedikit diperkecil agar pas
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      letterSpacing: 6,
                    ),
                  ),
                  const Text(
                    'Management System',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(
                    color: Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}