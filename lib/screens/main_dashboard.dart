import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kitchen_screen.dart';
import 'waiter_screen.dart';
import 'admin/admin_dashboard.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  String role = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == 'admin' || role == 'manager') return const AdminDashboard();
    if (role == 'chef') return const KitchenScreen();
    if (role == 'waiter') return const WaiterScreen();
    
    return const Scaffold(body: Center(child: Text("Role tidak dikenali")));
  }
}