import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'auth/login_screen.dart';
import 'menu/menu_list_screen.dart';

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key});

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  List<dynamic> _readyOrders = [];
  List<dynamic> _tables = [];
  bool _isLoading = true;
  
  // User Info
  String _userName = 'Waiter';
  int _userId = 0;
  
  // Statistik Lokal
  int _dirtyTableCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _refreshData();
    
    // Auto-refresh setiap 10 detik (Silent Refresh) agar data selalu update
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _refreshData(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _userName = prefs.getString('name') ?? 'Staff';
    });
  }

  Future<void> _refreshData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    try {
      // Parallel Request agar lebih cepat
      final results = await Future.wait([
        ApiService.get('orders.php?action=get_orders_by_role&role=waiter'),
        ApiService.get('tables.php?action=get_all'),
      ]);

      if (mounted) {
        setState(() {
          // 1. Proses Orders
          if (results[0]['success'] == true) {
            final allOrders = results[0]['data'] as List;
            // Filter hanya yang statusnya 'ready' (Siap Antar)
            _readyOrders = allOrders.where((o) => o['status'] == 'ready').toList();
          }
          
          // 2. Proses Tables
          if (results[1]['success'] == true) {
            _tables = results[1]['data'];
            // Hitung meja kotor untuk badge notifikasi
            _dirtyTableCount = _tables.where((t) => t['status'] == 'dirty').length;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error Waiter Sync: $e");
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _deliverOrder(Map<String, dynamic> order) async {
    // Konfirmasi dulu agar tidak kepencet
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text("Konfirmasi Antar", style: TextStyle(color: Colors.white)),
        content: Text("Makanan untuk Meja ${order['table_number']} sudah diantar?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Ya, Selesai"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.post('orders.php?action=update_status', {
      'order_id': order['id'],
      'status': 'served',
      'user_id': _userId
    });

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan selesai diantar!"), backgroundColor: Colors.green));
      _refreshData();
    }
  }

  Future<void> _cleanTable(int tableId) async {
    final res = await ApiService.post('tables.php?action=update_status', {
      'id': tableId,
      'status': 'available',
      'user_id': _userId
    });

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meja bersih & siap digunakan!"), backgroundColor: Colors.blue));
      _refreshData();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  // --- UI BUILD ---

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
                background: _buildHeaderProfile(),
              ),
              title: const Text("Waiter Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)), onPressed: _refreshData),
                IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFD4AF37),
                labelColor: const Color(0xFFD4AF37),
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: "Siap Antar (${_readyOrders.length})"),
                  Tab(text: "Meja Kotor ($_dirtyTableCount)"),
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
                  _buildReadyListTab(),
                  _buildTableGridTab(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuListScreen()));
        },
        backgroundColor: const Color(0xFFD4AF37),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("PESANAN BARU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeaderProfile() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD4AF37),
            child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'W', 
              style: const TextStyle(fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Halo, $_userName", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("Semangat melayani!", style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: LIST SIAP ANTAR ---
  Widget _buildReadyListTab() {
    if (_readyOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("Tidak ada antrian antar.", style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _readyOrders.length,
      itemBuilder: (context, index) {
        final order = _readyOrders[index];
        final items = order['items'] as List? ?? []; // Safe cast

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF2A2A2A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.green, width: 1.5),
          ),
          child: InkWell(
            onTap: () => _showOrderDetail(order),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.room_service, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Meja ${order['table_number']}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("#${order['order_number']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                        child: const Text("SIAP ANTAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  
                  // Preview Items
                  ... items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text("${item['quantity']}x", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  )),
                  
                  if (items.length > 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text("+ item lainnya...", style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic)),
                    ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _deliverOrder(order),
                      icon: const Icon(Icons.check),
                      label: const Text("ANTAR KE MEJA"),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: DENAH MEJA ---
  Widget _buildTableGridTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(Colors.grey[800]!, "Kosong"),
              _buildLegend(Colors.red[900]!, "Terisi"),
              _buildLegend(Colors.brown[600]!, "Kotor"),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];
                final status = table['status'];
                
                Color bg;
                IconData icon;
                String label;
                bool isClickable = false;

                if (status == 'dirty') {
                  bg = Colors.brown[600]!;
                  icon = Icons.cleaning_services;
                  label = "BERSIHKAN";
                  isClickable = true;
                } else if (status == 'occupied') {
                  bg = Colors.red[900]!;
                  icon = Icons.people;
                  label = table['guest_name'] ?? "Tamu";
                } else if (status == 'reserved') {
                  bg = Colors.blue[900]!;
                  icon = Icons.bookmark;
                  label = "Booked";
                } else {
                  bg = Colors.grey[800]!;
                  icon = Icons.check_box_outline_blank;
                  label = "Kosong";
                }

                return InkWell(
                  onTap: isClickable ? () => _cleanTable(int.parse(table['id'].toString())) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [if (isClickable) BoxShadow(color: Colors.brown.withOpacity(0.6), blurRadius: 8)],
                      border: isClickable ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(table['table_number'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Icon(icon, color: Colors.white70, size: 28),
                        const SizedBox(height: 8),
                        Text(label, 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: isClickable ? FontWeight.bold : FontWeight.normal),
                          maxLines: 1, overflow: TextOverflow.ellipsis
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final items = order['items'] as List? ?? [];
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Meja ${order['table_number']}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text("${item['quantity']}x", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                    if (item['notes'] != null && item['notes'].isNotEmpty)
                                      Text("Note: ${item['notes']}", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(context);
                        _deliverOrder(order);
                      },
                      child: const Text("ANTAR SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}