import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String _userRole = 'admin';
  int _userId = 0;
  
  // FIX: Tambahkan Timer untuk auto-refresh
  Timer? _timer; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _fetchOrders();
    
    // FIX: Auto Refresh setiap 10 detik
    _timer = Timer.periodic(const Duration(seconds: 10), (t) => _fetchOrders(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dicancel
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'admin';
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    // Panggil API get_orders_by_role dengan role 'admin' agar dapat semua order aktif
    final res = await ApiService.get('orders.php?action=get_orders_by_role&role=admin');
    
    if (mounted) {
      setState(() {
        if (res['success'] == true) {
          _allOrders = res['data'];
        }
        _isLoading = false;
      });
    }
  }

  // --- ADMIN FORCE UPDATE STATUS ---
  Future<void> _forceUpdateStatus(int orderId, String currentStatus) async {
    if (_userRole != 'admin' && _userRole != 'manager') return;

    final String? newStatus = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Admin Override Status", style: TextStyle(color: Color(0xFFD4AF37))),
        backgroundColor: const Color(0xFF2A2A2A),
        children: [
          _buildStatusOption(ctx, 'pending', "Pending (Masuk Dapur)"),
          _buildStatusOption(ctx, 'cooking', "Cooking (Sedang Masak)"),
          _buildStatusOption(ctx, 'ready', "Ready (Siap Saji)"),
          _buildStatusOption(ctx, 'served', "Served (Diantar)"),
          _buildStatusOption(ctx, 'payment_pending', "Minta Bill"),
          _buildStatusOption(ctx, 'completed', "Completed (Lunas)"),
          _buildStatusOption(ctx, 'cancelled', "Cancel (Batal)", isDestructive: true),
        ],
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      final res = await ApiService.post('orders.php?action=update_status', {
        'order_id': orderId,
        'status': newStatus,
        'user_id': _userId
      });

      if (res['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status diubah ke $newStatus")));
        _fetchOrders(silent: true);
      }
    }
  }

  SimpleDialogOption _buildStatusOption(BuildContext ctx, String value, String label, {bool isDestructive = false}) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label, 
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white, 
            fontSize: 16,
            fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Monitoring Order"),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _fetchOrders()),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "AKTIF"),
            Tab(text: "SELESAI"),
            Tab(text: "BATAL"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('active'),
                _buildOrderList('completed'),
                _buildOrderList('cancelled'),
              ],
            ),
    );
  }

  Widget _buildOrderList(String type) {
    List<dynamic> filtered;
    
    if (type == 'active') {
      filtered = _allOrders.where((o) => o['status'] != 'completed' && o['status'] != 'cancelled').toList();
    } else {
      filtered = _allOrders.where((o) => o['status'] == type).toList();
    }

    if (filtered.isEmpty) {
      return const Center(child: Text("Tidak ada data", style: TextStyle(color: Colors.white38)));
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String status = order['status'];
    Color statusColor = _getStatusColor(status);
    bool isAdmin = _userRole == 'admin' || _userRole == 'manager';

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), shape: BoxShape.circle),
          child: Text(
            order['table_number'] ?? '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          "Order #${order['order_number']}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Tamu: ${order['customer_name'] ?? 'Guest'}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 2),
            Text(
              "Total: Rp ${_formatCurrency(order['total_amount'])}",
              style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            if (isAdmin)
              const SizedBox(height: 4),
            if (isAdmin)
              InkWell(
                onTap: () => _forceUpdateStatus(int.parse(order['id'].toString()), status),
                child: const Icon(Icons.edit, size: 16, color: Colors.white54),
              )
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Rincian Pesanan:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                // List Item (Perlu safe cast)
                if (order['items'] != null)
                  ... (order['items'] as List).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${item['quantity']}x ${item['name']}", style: const TextStyle(color: Colors.white)),
                        if (item['notes'] != null && item['notes'] != '')
                          Text("(${item['notes']})", style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                      ],
                    ),
                  )),
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch(status) {
      case 'pending': return Colors.orange;
      case 'cooking': return Colors.blue;
      case 'ready': return Colors.green;
      case 'served': return Colors.cyan;
      case 'payment_pending': return Colors.purple;
      case 'completed': return Colors.grey;
      case 'cancelled': return Colors.red;
      default: return Colors.white;
    }
  }

  String _formatCurrency(dynamic amount) {
    return double.parse(amount.toString()).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}