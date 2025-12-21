import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'payment_detail_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  
  bool _isLoading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrders();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getInt('userId') ?? 0);
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.get('orders.php?action=get_orders_by_role&role=cs');
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _allOrders = res['data'];
            _filteredOrders = _allOrders;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data: $e"),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterOrders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders.where((order) {
          final table = order['table_number'].toString().toLowerCase();
          final customer = order['customer_name'].toString().toLowerCase();
          return table.contains(query.toLowerCase()) || 
                 customer.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToPaymentDetail(Map<String, dynamic> order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailScreen(
          order: order,
          userId: _userId,
        ),
      ),
    );

    // Reload orders jika pembayaran berhasil
    if (result == true) {
      _loadOrders();
    }
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Kasir & Pembayaran'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _loadOrders,
            tooltip: 'Refresh Data',
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37)
                    )
                  )
                : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF252525),
      child: TextField(
        onChanged: _filterOrders,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari Meja / Nama Customer...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              "Tidak ada tagihan",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w500
              )
            ),
            SizedBox(height: 8),
            Text(
              "Semua pesanan sudah dibayar",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12
              )
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String status = order['status'].toString();
    Color badgeColor = Colors.grey;
    String badgeText = status.toUpperCase();
    IconData statusIcon = Icons.schedule;

    // Determine status styling
    if (status == 'served') {
      badgeColor = Colors.blue;
      badgeText = "BELUM BAYAR";
      statusIcon = Icons.pending_actions;
    } else if (status == 'payment_pending') {
      badgeColor = Colors.purple;
      badgeText = "MINTA BILL";
      statusIcon = Icons.receipt;
    } else if (status == 'completed') {
      badgeColor = Colors.green;
      badgeText = "LUNAS";
      statusIcon = Icons.check_circle;
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToPaymentDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Table Number Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badgeColor.withOpacity(0.5),
                    width: 2
                  )
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'MEJA',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            order['table_number'] ?? '?',
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['customer_name'] ?? 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "#${order['order_number']}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: badgeColor,
                          size: 14
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: badgeColor.withOpacity(0.5)
                            )
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount & Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Rp ${_formatCurrency(order['total_amount'])}",
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      shape: BoxShape.circle
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFFD4AF37),
                      size: 14
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    return double.parse(amount.toString())
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.'
        );
  }
}
