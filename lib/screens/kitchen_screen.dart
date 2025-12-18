import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import '../../services/api_service.dart';
import 'auth/login_screen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  List<dynamic> _pendingOrders = [];
  List<dynamic> _cookingOrders = [];
  bool _isLoading = true;
  String _chefName = 'Chef';
  int _userId = 0;
  Timer? _refreshTimer;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _fetchOrders();
    
    // Auto Refresh Data Server setiap 10 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (t) => _fetchOrders(silent: true));
    
    // Update tampilan durasi setiap 1 menit
    _durationTimer = Timer.periodic(const Duration(minutes: 1), (t) {
      if(mounted) setState(() {}); 
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _durationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _chefName = prefs.getString('name') ?? 'Chef';
    });
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    try {
      final res = await ApiService.get('orders.php?action=get_orders_by_role&role=chef');
      
      if (mounted) {
        setState(() {
          if (res['success'] == true) {
            final allOrders = res['data'] as List;
            _pendingOrders = allOrders.where((o) => o['status'] == 'pending').toList();
            _cookingOrders = allOrders.where((o) => o['status'] == 'cooking').toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Kitchen Error: $e");
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    // Optimistic Update
    setState(() {
      if (status == 'cooking') {
        final item = _pendingOrders.firstWhere((o) => o['id'] == orderId, orElse: () => null);
        if (item != null) {
          _pendingOrders.removeWhere((o) => o['id'] == orderId);
          _cookingOrders.add(item); 
        }
      } else if (status == 'ready') {
        _cookingOrders.removeWhere((o) => o['id'] == orderId);
      }
    });

    final res = await ApiService.post('orders.php?action=update_status', {
      'order_id': orderId,
      'status': status,
      'user_id': _userId
    });

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'cooking' ? "Mulai memasak..." : "Order Selesai! Waiter dipanggil."),
          backgroundColor: status == 'cooking' ? Colors.blue : Colors.green,
          duration: const Duration(seconds: 1),
        )
      );
      _fetchOrders(silent: true);
    } else {
      _fetchOrders(); // Revert jika gagal
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update status"), backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              title: const Text("Dapur / Kitchen", style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)), onPressed: _fetchOrders),
                IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFD4AF37),
                labelColor: const Color(0xFFD4AF37),
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long),
                        const SizedBox(width: 8),
                        Text("Baru Masuk (${_pendingOrders.length})"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.soup_kitchen),
                        const SizedBox(width: 8),
                        Text("Sedang Dimasak (${_cookingOrders.length})"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_pendingOrders, 'pending'),
                _buildOrderList(_cookingOrders, 'cooking'),
              ],
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFFD4AF37),
            child: const Icon(Icons.kitchen, size: 35, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Chef $_chefName", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("Kitchen Display System (KDS)", style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type == 'pending' ? Icons.check_circle : Icons.fireplace, size: 80, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              type == 'pending' ? "Tidak ada pesanan baru" : "Kompor sedang kosong",
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final items = order['items'] as List? ?? [];
        
        // Hitung durasi tunggu (Realtime Timer Logic)
        DateTime created;
        try {
          created = DateTime.parse(order['created_at']);
        } catch (e) {
          created = DateTime.now();
        }
        
        final diff = DateTime.now().difference(created).inMinutes;
        
        // Warna Indikator Waktu
        Color timeColor = Colors.green; // < 15 menit
        if (diff > 30) timeColor = Colors.red; // > 30 menit (Telat)
        else if (diff > 15) timeColor = Colors.orange; // 15-30 menit (Warning)

        final borderColor = type == 'pending' ? const Color(0xFFD4AF37) : Colors.blueAccent;

        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: diff > 30 ? Colors.red : borderColor, width: diff > 30 ? 2 : 1),
          ),
          child: Column(
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: diff > 30 ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order['table_number'] ?? '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("MEJA ${order['table_number']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("#${order['order_number']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    // Jam Masuk + Timer Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // FIX: MENGGUNAKAN INTL UNTUK MEMFORMAT JAM
                        Text(
                          DateFormat('HH:mm').format(created),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: timeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: timeColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 14, color: timeColor),
                              const SizedBox(width: 4),
                              Text("$diff mnt", style: TextStyle(color: timeColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, color: Colors.white10),
              
              // Items List
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final hasNote = item['notes'] != null && item['notes'].toString().isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item['quantity']}x", style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                if (hasNote)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.withOpacity(0.2), // Highlight Note
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.pink.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      "Note: ${item['notes']}",
                                      style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'pending' ? const Color(0xFFD4AF37) : Colors.green,
                      foregroundColor: type == 'pending' ? Colors.black : Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (type == 'pending') {
                        _updateStatus(int.parse(order['id'].toString()), 'cooking');
                      } else {
                        _updateStatus(int.parse(order['id'].toString()), 'ready');
                      }
                    },
                    icon: Icon(type == 'pending' ? Icons.soup_kitchen : Icons.notifications_active),
                    label: Text(
                      type == 'pending' ? "TERIMA & MASAK" : "SAJIKAN (PANGGIL WAITER)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}