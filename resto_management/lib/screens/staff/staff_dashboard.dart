import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

// --- IMPORT FITUR ---
import '../menu/menu_list_screen.dart';
import '../order/order_list_screen.dart';
import '../booking/booking_screen.dart';
import '../payment/payment_screen.dart';
import '../kitchen_screen.dart';
import '../manage_menu/manage_menu_screen.dart';
import '../staff/staff_management_screen.dart';
import '../analytics/analytics_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../analytics/attendance_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  // --- STATE VARIABLES ---
  String _userName = 'Loading...';
  String _userRole = 'staff';
  int _userId = 0;
  
  bool _isLoading = true;
  bool _isShiftStarted = false;
  String _currentTime = '';
  Timer? _timer;
  
  Map<String, dynamic> _stats = {
    'total_revenue': 0,
    'total_orders': 0,
    'today_bookings': 0,
    'pending_orders': 0,
    'low_stock_count': 0,
    'cash_revenue': 0,
    'digital_revenue': 0,
  };
  
  List<dynamic> _activityLogs = [];
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'Staff';
      _userRole = prefs.getString('role') ?? 'cs';
      _userId = prefs.getInt('userId') ?? 0;
      _isShiftStarted = prefs.getBool('isShiftStarted') ?? false;
    });
    _refreshAllData();
  }

  Future<void> _refreshAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDashboardStats(),
      _loadActivityLogs(),
      _loadNotifications(),
      _checkAttendanceStatus(), // NEW: Check actual attendance status from server
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // --- HELPER: PARSING AMAN (ANTI CRASH) ---
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadDashboardStats() async {
    try {
      final res = await ApiService.get('booking.php?action=get_dashboard_stats');
      if (mounted && res['success'] == true) {
        setState(() {
          _stats = res['data'];
          // Gunakan Safe Parse untuk menghindari error
          double total = _safeParseDouble(_stats['total_revenue']);
          double orderRev = _safeParseDouble(_stats['order_revenue']);
          
          // Simulasi split revenue (karena API belum kirim detail)
          _stats['cash_revenue'] = orderRev; 
          _stats['digital_revenue'] = total - orderRev;
        });
      }
    } catch (e) {
      print("Error stats: $e");
    }
  }

  Future<void> _loadActivityLogs() async {
    try {
      final res = await ApiService.get('staff.php?action=get_activity_logs');
      if (mounted && res['success'] == true) {
        setState(() => _activityLogs = res['data'] ?? []);
      }
    } catch (e) {
      print("Error logs: $e");
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await ApiService.get('staff.php?action=get_notifications&role=$_userRole&user_id=$_userId');
      if (mounted && res['success'] == true) {
        setState(() => _notifications = res['data'] ?? []);
      }
    } catch (e) {
      print("Error notif: $e");
    }
  }

  // NEW: Check attendance status from server
  Future<void> _checkAttendanceStatus() async {
    if (_userRole == 'admin') return; // Admin tidak punya absensi
    
    try {
      final res = await ApiService.get('attendance.php?action=get_my_status&user_id=$_userId');
      if (mounted && res['success'] == true && res['data'] != null) {
        bool isClockedIn = res['data']['is_clocked_in'] ?? false;
        setState(() => _isShiftStarted = isClockedIn);
        
        // Sync ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isShiftStarted', isClockedIn);
      }
    } catch (e) {
      print("Error checking attendance status: $e");
    }
  }

  // FIXED: Use correct attendance.php endpoint
  Future<void> _toggleShift() async {
    String action = _isShiftStarted ? 'clock_out' : 'clock_in';
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memproses Absensi..."), duration: Duration(milliseconds: 800)));

    // FIXED: Call attendance.php instead of staff.php
    final res = await ApiService.post('attendance.php?action=$action', {
      'user_id': _userId,
    });

    if (res['success'] == true) {
      setState(() => _isShiftStarted = !_isShiftStarted);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isShiftStarted', _isShiftStarted);

      if (mounted) {
        _showAttendanceDialog(_isShiftStarted);
        _refreshAllData();
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal Absen"), backgroundColor: Colors.red));
    }
  }

  void _showAttendanceDialog(bool isClockIn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            Icon(isClockIn ? Icons.wb_sunny : Icons.nights_stay, color: const Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            Text(isClockIn ? "Selamat Bekerja!" : "Hati-hati di Jalan!", style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          isClockIn 
            ? "Shift dimulai pada $_currentTime.\nAkses menu telah dibuka."
            : "Shift berakhir pada $_currentTime.\nAkses menu dikunci.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _logout() async {
    if (_isShiftStarted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap CLOCK OUT sebelum logout!"), backgroundColor: Colors.orange));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Logout Sistem', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin keluar aplikasi?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateNow = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(dateNow),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Detail Notifikasi (Coming Soon)")));
                      },
                    ),
                    if (_notifications.isNotEmpty)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text("${_notifications.length}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)), onPressed: _refreshAllData),
                IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout),
              ],
            )
          ];
        },
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : RefreshIndicator(
              onRefresh: _refreshAllData,
              color: const Color(0xFFD4AF37),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_safeParseInt(_stats['low_stock_count']) > 0) 
                      _buildAlertBanner(),

                    if (_userRole == 'admin' || _userRole == 'cs' || _userRole == 'manager')
                      _buildRevenueCard(),
                    
                    const SizedBox(height: 16),
                    _buildQuickStatsRow(),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(Icons.apps, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 8),
                        const Text("Menu Aplikasi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (!_isShiftStarted && _userRole != 'admin')
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                         child: Column(
                           children: const [
                             Icon(Icons.lock_clock, size: 50, color: Colors.grey),
                             SizedBox(height: 10),
                             Text("MENU TERKUNCI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                             Text("Silakan tekan tombol 'CLOCK IN' di atas untuk memulai shift dan membuka akses.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                           ],
                         ),
                       )
                    else 
                      _buildMenuGrid(),
                    
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 8),
                        const Text("Log Aktivitas Terbaru", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildActivityFeed(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader(String dateNow) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _isShiftStarted ? Colors.green : Colors.grey, width: 2)),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFD4AF37),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Halo, $_userName", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _isShiftStarted ? Colors.green : Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(_isShiftStarted ? "Status: ON DUTY" : "Status: OFF DUTY", style: TextStyle(color: _isShiftStarted ? Colors.green : Colors.red, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              Visibility(
                visible: _userRole != 'admin',
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isShiftStarted ? Colors.red.withOpacity(0.2) : Colors.green,
                    foregroundColor: _isShiftStarted ? Colors.red : Colors.white,
                    side: BorderSide(color: _isShiftStarted ? Colors.red : Colors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _toggleShift,
                  icon: Icon(_isShiftStarted ? Icons.logout : Icons.login, size: 18),
                  label: Text(_isShiftStarted ? "CLOCK OUT" : "CLOCK IN", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateNow, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(_currentTime, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.2),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text("Perhatian: ${_stats['low_stock_count']} item stok menipis!", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
          if (_userRole == 'admin')
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageMenuScreen())),
              child: const Text("CEK"),
            )
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      color: const Color(0xFF252525),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pendapatan Hari Ini", style: TextStyle(color: Colors.white54)),
                Icon(Icons.monetization_on, color: Colors.green.withOpacity(0.8)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Rp ${_formatCurrency(_safeParseDouble(_stats['total_revenue']))}", 
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMiniStat("Cash", _stats['cash_revenue'], Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStat("Digital", _stats['digital_revenue'], Colors.purple)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          Text("Rp ${_formatCurrency(_safeParseDouble(value))}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildQuickStatCard("Order", "${_stats['total_orders']}", Icons.receipt_long, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickStatCard("Booking", "${_stats['today_bookings']}", Icons.event_seat, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickStatCard("Dapur", "${_stats['pending_orders']}", Icons.soup_kitchen, Colors.redAccent)),
      ],
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    // Definisi Menu Sesuai Role
    List<Map<String, dynamic>> menuItems = [
      {'title': 'Kasir & Bayar', 'icon': Icons.point_of_sale, 'color': Colors.green, 'page': const PaymentScreen()},
      {'title': 'Meja & Booking', 'icon': Icons.table_restaurant, 'color': Colors.blue, 'page': const BookingScreen()},
      {'title': 'Status Order', 'icon': Icons.monitor_heart, 'color': Colors.orange, 'page': const OrderListScreen()},
      {'title': 'Input Manual', 'icon': Icons.add_circle_outline, 'color': const Color(0xFFD4AF37), 'page': const MenuListScreen()},
      {'title': 'Member Loyalty', 'icon': Icons.card_membership, 'color': Colors.pink, 'page': const LoyaltyScreen()},
    ];

    if (_userRole == 'admin' || _userRole == 'manager') {
      menuItems.addAll([
        {'title': 'Menu & Stok', 'icon': Icons.inventory_2, 'color': Colors.purple, 'page': const ManageMenuScreen()},
        {'title': 'Staff HRD', 'icon': Icons.people_alt, 'color': Colors.teal, 'page': const StaffManagementScreen()},
        {'title': 'Monitor Dapur', 'icon': Icons.kitchen, 'color': Colors.redAccent, 'page': const KitchenScreen()},
        {'title': 'Laporan Bisnis', 'icon': Icons.insights, 'color': Colors.cyan, 'page': const AnalyticsScreen()},
        {'title': 'Riwayat Absensi', 'icon': Icons.calendar_month, 'color': Colors.indigo, 'page': const AttendanceScreen()},
      ]);
    }

    // Special case for Chef
    if (_userRole == 'chef') {
      menuItems = [
        {'title': 'Monitor Dapur', 'icon': Icons.kitchen, 'color': Colors.redAccent, 'page': const KitchenScreen()},
        {'title': 'Menu & Stok', 'icon': Icons.inventory_2, 'color': Colors.purple, 'page': const ManageMenuScreen()},
      ];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => item['page'])),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(item['icon'], color: item['color'], size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityFeed() {
    if (_activityLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("Belum ada aktivitas hari ini", style: TextStyle(color: Colors.white24))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activityLogs.length,
      itemBuilder: (context, index) {
        final log = _activityLogs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  log['time_ago'] ?? 'Now', 
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: _getActivityColor(log['action_type'] ?? ''), width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${log['user_name'] ?? 'System'} • ${log['action_type'] ?? 'ACTION'}",
                        style: TextStyle(color: _getActivityColor(log['action_type'] ?? ''), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(log['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getActivityColor(String type) {
    if (type.contains('LOGIN')) return Colors.blue;
    if (type.contains('CLOCK')) return Colors.green;
    if (type.contains('PAYMENT')) return Colors.amber;
    if (type.contains('ORDER')) return Colors.orange;
    if (type.contains('CANCEL')) return Colors.red;
    return Colors.grey;
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}