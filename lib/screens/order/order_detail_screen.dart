import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../payment/payment_screen.dart'; 

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String _orderFetchError = '';

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  // --- FUNGSI LOAD DETAIL DARI API ---
  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _orderFetchError = '';
    });
    
    try {
      final res = await ApiService.get('orders.php?action=get_order_detail&id=${widget.orderId}');
      
      if (mounted) {
        if (res['success'] == true && res['data'] != null) {
          setState(() => _order = res['data']);
        } else {
          setState(() => _orderFetchError = res['message'] ?? 'Order tidak ditemukan.');
        }
      }
    } catch (e) {
      setState(() => _orderFetchError = "Gagal koneksi ke server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // --- Aksi Lanjutan ---
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.print, color: Colors.white),
            title: const Text('Cetak Struk', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _printReceipt(); // Memanggil fungsi yang didefinisikan di bawah
            },
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Colors.white), // FIX: Menggunakan Icons.message
            title: const Text('Kirim WhatsApp', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _sendWhatsApp(); // Memanggil fungsi yang didefinisikan di bawah
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text('Edit Order', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Edit Order belum diimplementasikan.")));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(title: const Text('Detail Order')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (_orderFetchError.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(title: const Text('Detail Order')),
        body: Center(
          child: Text(_orderFetchError, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(title: const Text('Detail Order')),
        body: const Center(
          child: Text('Order tidak ditemukan', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final status = _order!['status'].toString();
    final statusColor = _getStatusColor(status);
    final total = double.parse(_order!['total_amount'].toString());
    
    final subtotal = total / 1.15; 
    final tax = subtotal * 0.10;
    final serviceCharge = subtotal * 0.05;
    
    final isPaid = status == 'completed';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Detail Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Header Card
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_order!['order_number'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text(_getStatusLabel(status), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    _buildInfoRow(Icons.event_seat, 'Meja', _order!['table_number'] ?? '-'),
                    _buildInfoRow(Icons.person, 'Customer', _order!['customer_name'] ?? 'Walk-in'),
                    // Asumsi API mengirim phone dan notes
                    if (_order!['notes'] != null && _order!['notes'].isNotEmpty)
                      _buildInfoRow(Icons.note, 'Catatan', _order!['notes']),
                    _buildInfoRow(Icons.access_time, 'Waktu Masuk', _formatDateTime(_order!['created_at'])),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 2. Order Items
            const Text('Item Pesanan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ... (_order!['items'] as List).map<Widget>((item) => _buildItemCard(item)).toList(),
            
            const SizedBox(height: 16),
            
            // 3. Payment Summary
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Pembayaran', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Subtotal', subtotal),
                    _buildSummaryRow('Service Charge (5%)', serviceCharge),
                    _buildSummaryRow('Pajak (10%)', tax),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL HARUS DIBAYAR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Rp ${_formatCurrency(total)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isPaid)
                       _buildPaidStatus()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 4. Bottom Pay Button
      bottomNavigationBar: !isPaid && status != 'cancelled'
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigasi ke PaymentScreen (Kasir)
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengarahkan ke Kasir...'), backgroundColor: Colors.blue));
                    // Navigasi ke PaymentScreen
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                  child: const Text('PROSES PEMBAYARAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
    );
  }

  // --- HELPER WIDGETS ---
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final price = double.tryParse(item['price'].toString()) ?? 0.0;
    final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
    final totalPrice = price * quantity;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                // Asumsi image_url ada di item list
                image: item['image_url'] != null ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover) : null,
              ),
              child: item['image_url'] == null || item['image_url'] == 'placeholder' 
                  ? const Icon(Icons.restaurant, color: Colors.white38) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Rp ${_formatCurrency(price)} x $quantity', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  if (item['notes'] != null && item['notes'].isNotEmpty)
                    Text('Note: ${item['notes']}', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Text('Rp ${_formatCurrency(totalPrice)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('Rp ${_formatCurrency(amount)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPaidStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.paid, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Lunas via ${_order!['payment_method'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  void _printReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak struk...'), backgroundColor: Colors.blue));
  }

  void _sendWhatsApp() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengirim struk via WhatsApp...'), backgroundColor: Colors.green));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFF9800);
      case 'cooking': return const Color(0xFF2196F3);
      case 'ready': return const Color(0xFF4CAF50);
      case 'served': return Colors.cyan;
      case 'payment_pending': return Colors.purple;
      case 'completed': return Colors.grey;
      case 'cancelled': return Colors.red;
      default: return Colors.white;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'cooking': return 'Cooking';
      case 'ready': return 'Ready';
      case 'served': return 'Served';
      case 'payment_pending': return 'Minta Bayar';
      case 'completed': return 'Lunas';
      case 'cancelled': return 'Batal';
      default: return status;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('HH:mm, d MMM yyyy').format(date);
    } catch (e) {
      return dateTime;
    }
  }
}