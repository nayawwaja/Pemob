import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../menu/menu_list_screen.dart';
import '../order/order_list_screen.dart';
import '../booking/booking_screen.dart';
import '../payment/payment_screen.dart';
import '../analytics/analytics_screen.dart';
import '../manage_menu/manage_menu_screen.dart';
import '../staff/staff_management_screen.dart';
import '../kitchen_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // --- STATE VARIABLES ---
  String _userName = 'Admin';
  String _currentTime = '';
  bool _isLoading = true;
  Timer? _timer;

  // Data Dashboard
  Map<String, dynamic> _stats = {
    'total_revenue': 0,
    'total_orders': 0,
    'today_bookings': 0,
    'low_stock_count': 0,
    'pending_orders': 0,
  };
  
  List<dynamic> _lowStockItems = [];
  List<dynamic> _salesChartData = []; // Data Grafik

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadUserData();
    _loadAllData();
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
      _userName = prefs.getString('name') ?? 'Owner';
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    // Panggil 3 API sekaligus secara paralel agar cepat
    try {
      final results = await Future.wait([
        ApiService.get('booking.php?action=get_dashboard_stats'), // Statistik Angka
        ApiService.get('booking.php?action=get_low_stock'),       // Stok Menipis
        ApiService.get('orders.php?action=get_sales_chart'),      // Data Grafik
      ]);

      if (mounted) {
        setState(() {
          // 1. Stats
          if (results[0]['success'] == true) {
            _stats = results[0]['data'];
          }
          
          // 2. Low Stock
          if (results[1]['success'] == true) {
            _lowStockItems = results[1]['data'] ?? [];
          }

          // 3. Grafik Penjualan
          if (results[2]['success'] == true) {
            _salesChartData = results[2]['data'];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Dashboard Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Logout Sistem', style: TextStyle(color: Colors.white)),
        content: const Text('Keluar dari Panel Admin?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: const Color(0xFFD4AF37),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WELCOME CARD
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  
                  // 2. STATISTIK UTAMA (GRID)
                  const Text("Ringkasan Hari Ini", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildMainStatsGrid(),
                  const SizedBox(height: 24),

                  // 3. GRAFIK PENJUALAN (REAL DATA)
                  const Text("Tren Pendapatan (7 Hari)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSalesChartCard(),
                  const SizedBox(height: 24),

                  // 4. STOCK ALERT
                  if (_lowStockItems.isNotEmpty) ...[
                    _buildLowStockAlert(),
                    const SizedBox(height: 24),
                  ],

                  // 5. QUICK ACTIONS
                  const Text("Manajemen & Kontrol", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildControlGrid(), 
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting = 'Selamat Pagi';
    if (hour >= 12 && hour < 15) greeting = 'Selamat Siang';
    else if (hour >= 15 && hour < 18) greeting = 'Selamat Sore';
    else if (hour >= 18) greeting = 'Selamat Malam';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFD4AF37).withOpacity(0.8), const Color(0xFF8B7500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.black,
              child: Icon(Icons.admin_panel_settings, size: 35, color: Color(0xFFD4AF37)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(_userName, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Last update: $_currentTime", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      // UBAH DARI 1.4 MENJADI 1.25 AGAR KARTU LEBIH TINGGI
      childAspectRatio: 1.25, 
      children: [
        _buildStatCard(
          "Total Pendapatan", 
          "Rp ${_formatCurrency(_stats['total_revenue'])}", 
          Icons.monetization_on, 
          Colors.green
        ),
        _buildStatCard(
          "Total Order", 
          "${_stats['total_orders']}", 
          Icons.shopping_cart, 
          Colors.blue
        ),
        _buildStatCard(
          "Booking / Reservasi", 
          "${_stats['today_bookings']}", 
          Icons.event_seat, 
          Colors.orange
        ),
        _buildStatCard(
          "Antrian Dapur", 
          "${_stats['pending_orders']}", 
          Icons.soup_kitchen, 
          Colors.redAccent
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      // UBAH PADDING DARI 16 MENJADI 12
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          // UBAH HEIGHT DARI 12 MENJADI 8
          const SizedBox(height: 8), 
          
          // Tambahkan FittedBox agar teks mengecil otomatis jika terlalu panjang
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), 
              maxLines: 1, 
            ),
          ),
          
          Text(
            title, 
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  // --- GRAFIK FL_CHART ---
  Widget _buildSalesChartCard() {
    if (_salesChartData.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: const Text("Belum ada data penjualan minggu ini", style: TextStyle(color: Colors.white38)),
      );
    }

    // Cari nilai max untuk skala Y
    double maxY = 0;
    for (var d in _salesChartData) {
      double val = double.parse(d['amount'].toString());
      if (val > maxY) maxY = val;
    }
    maxY = maxY == 0 ? 100000 : maxY * 1.2; // Buffer atas

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // FIX: Menggunakan tooltipBgColor (kompatibel versi lama & stabil)
              tooltipBgColor: Colors.blueGrey, 
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _formatCurrency(rod.toY),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < _salesChartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _salesChartData[index]['day'],
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _salesChartData.asMap().entries.map((entry) {
            int index = entry.key;
            double val = double.parse(entry.value['amount'].toString());
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: const Color(0xFFD4AF37),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY, 
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.redAccent),
                const SizedBox(width: 12),
                Text("Peringatan Stok (${_lowStockItems.length} Item)", 
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.redAccent),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lowStockItems.length > 3 ? 3 : _lowStockItems.length,
            itemBuilder: (context, index) {
              final item = _lowStockItems[index];
              return ListTile(
                title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: Text("Sisa: ${item['stock']}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              );
            },
          ),
          if (_lowStockItems.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageMenuScreen()));
                  },
                  child: const Text("Lihat Semua Stok", style: TextStyle(color: Colors.white70)),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildControlGrid() {
    final List<Map<String, dynamic>> controls = [
      {
        'title': 'Manajemen Staff',
        'subtitle': 'HRD & Akses',
        'icon': Icons.badge,
        'color': Colors.blue,
        'page': const StaffManagementScreen(),
      },
      {
        'title': 'Kelola Menu',
        'subtitle': 'Stok & Harga',
        'icon': Icons.restaurant_menu,
        'color': Colors.orange,
        'page': const ManageMenuScreen(),
      },
      {
        'title': 'Laporan Bisnis',
        'subtitle': 'Analitik Detail',
        'icon': Icons.insights,
        'color': Colors.purple,
        'page': const AnalyticsScreen(),
      },
      {
        'title': 'Monitor Dapur',
        'subtitle': 'Antrian Masak',
        'icon': Icons.kitchen,
        'color': Colors.redAccent,
        'page': const KitchenScreen(),
      },
      {
        'title': 'Input Order', 
        'subtitle': 'Buat Pesanan',
        'icon': Icons.add_circle_outline,
        'color': const Color(0xFFD4AF37),
        'page': const MenuListScreen(),
      },
      {
        'title': 'Riwayat Order',
        'subtitle': 'Semua Transaksi',
        'icon': Icons.history,
        'color': Colors.blueGrey,
        'page': const OrderListScreen(),
      },
      {
        'title': 'Manajemen Meja',
        'subtitle': 'Denah & Booking',
        'icon': Icons.table_restaurant,
        'color': Colors.teal,
        'page': const BookingScreen(),
      },
      {
        'title': 'Kasir & Bayar',
        'subtitle': 'Pembayaran',
        'icon': Icons.point_of_sale,
        'color': Colors.green,
        'page': const PaymentScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controls.length,
      itemBuilder: (context, index) {
        final item = controls[index];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => item['page'])),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: item['color'].withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(item['icon'], color: item['color'], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(item['subtitle'], style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(dynamic amount) {
    double val = double.tryParse(amount.toString()) ?? 0.0;
    return val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}