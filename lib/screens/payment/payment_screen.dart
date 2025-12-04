import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  Map<String, dynamic>? _selectedOrder;
  
  // State Input Pembayaran
  String _selectedPaymentMethod = '';
  final TextEditingController _cashController = TextEditingController();
  double _changeAmount = 0.0;
  
  bool _isLoading = true;
  bool _isProcessing = false;
  int _userId = 0;

  // Konfigurasi
  final double _taxRate = 0.10;
  final double _serviceRate = 0.05;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Tunai', 'icon': Icons.payments, 'color': Colors.green},
    {'id': 'qris', 'name': 'QRIS', 'icon': Icons.qr_code_2, 'color': Colors.blue},
    {'id': 'debit', 'name': 'Debit', 'icon': Icons.credit_card, 'color': Colors.orange},
    {'id': 'transfer', 'name': 'Transfer', 'icon': Icons.account_balance, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrders();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getInt('userId') ?? 0);
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _selectedOrder = null;
      _selectedPaymentMethod = '';
      _cashController.clear();
      _changeAmount = 0.0;
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
          return table.contains(query.toLowerCase()) || customer.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _onOrderSelected(Map<String, dynamic> order, bool isMobile) {
    bool isCompleted = order['status'] == 'completed';
    setState(() {
      _selectedOrder = order;
      // Reset input jika order baru dipilih dan belum lunas
      if (!isCompleted) {
        _selectedPaymentMethod = '';
        _cashController.clear();
        _changeAmount = 0.0;
      } else {
        _selectedPaymentMethod = order['payment_method'] ?? '';
      }
    });

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, 
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => _buildDetailPanel(scrollController: controller),
        ),
      );
    }
  }

  void _calculateChange(String value) {
    if (_selectedOrder == null) return;
    String cleanVal = value.replaceAll(RegExp(r'[^0-9]'), '');
    double cashGiven = double.tryParse(cleanVal) ?? 0.0;
    double totalBill = double.parse(_selectedOrder!['total_amount'].toString());
    setState(() => _changeAmount = cashGiven - totalBill);
  }

  Future<void> _processPayment() async {
    if (_selectedOrder == null) return;
    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Metode Pembayaran!"), backgroundColor: Colors.red));
      return;
    }
    if (_selectedPaymentMethod == 'cash') {
       if (_changeAmount < 0) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uang tunai kurang!"), backgroundColor: Colors.red));
         return;
       }
    }

    setState(() => _isProcessing = true);

    try {
      final res = await ApiService.post('orders.php?action=process_payment', {
        'order_id': _selectedOrder!['id'],
        'payment_method': _selectedPaymentMethod,
        'user_id': _userId
      });

      if (res['success'] == true) {
        int points = (double.parse(_selectedOrder!['total_amount'].toString()) / 10000).floor();
        if (!mounted) return;
        Navigator.pop(context); // Tutup BottomSheet
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaymentSuccessScreen(
            order: _selectedOrder!,
            paymentMethod: _selectedPaymentMethod,
            pointsEarned: points,
          )),
        ).then((_) => _loadOrders());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal"), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Kasir & Pembayaran'),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)), onPressed: _loadOrders)],
      ),
      body: isMobile 
        ? _buildMobileLayout() 
        : _buildTabletLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : _buildOrderList(isMobile: true),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                  : _buildOrderList(isMobile: false),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(color: Colors.black26, border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1)))),
            child: _selectedOrder == null 
                ? const Center(child: Text("Pilih Pesanan", style: TextStyle(color: Colors.white38)))
                : _buildDetailPanel(),
          ),
        ),
      ],
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
          hintText: 'Cari Meja / Nama...',
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildOrderList({required bool isMobile}) {
    if (_filteredOrders.isEmpty) {
      return const Center(child: Text("Tidak ada tagihan", style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        bool isSelected = !isMobile && _selectedOrder?['id'] == order['id'];
        
        String status = order['status'].toString();
        Color badgeColor = Colors.grey;
        String badgeText = status.toUpperCase();
        
        if (status == 'served') { badgeColor = Colors.blue; badgeText = "BELUM BAYAR"; }
        else if (status == 'payment_pending') { badgeColor = Colors.purple; badgeText = "MINTA BILL"; }
        else if (status == 'completed') { badgeColor = Colors.green; badgeText = "LUNAS"; }

        return Card(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent),
          ),
          child: ListTile(
            onTap: () => _onOrderSelected(order, isMobile),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), shape: BoxShape.circle),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      order['table_number'] ?? '?',
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            title: Text(order['customer_name'] ?? 'Guest', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("#${order['order_number']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Rp ${_formatCurrency(order['total_amount'])}", 
                  style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPanel({ScrollController? scrollController}) {
    final order = _selectedOrder!;
    final bool isPaid = order['status'] == 'completed';
    
    double total = double.parse(order['total_amount'].toString());
    double subtotal = total / (1 + _taxRate + _serviceRate);
    double tax = subtotal * _taxRate;
    double service = subtotal * _serviceRate;
    List items = order['items'] as List;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (scrollController != null) 
              Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ORDER #${order['order_number']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text("MEJA ${order['table_number']}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (isPaid)
                    const Chip(label: Text("LUNAS", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green)
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  ...items.map((item) {
                    double lineTotal = double.parse(item['price'].toString()) * int.parse(item['quantity'].toString());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text("${item['quantity']}x ", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                          Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white70))),
                          Text(_formatCurrency(lineTotal), style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const Divider(color: Colors.white24, height: 24),
                  _buildSummaryRow("Subtotal", subtotal),
                  _buildSummaryRow("Service (5%)", service),
                  _buildSummaryRow("Pajak PB1 (10%)", tax),
                  const Divider(color: Colors.white24, height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text("TOTAL TAGIHAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      FittedBox(fit: BoxFit.scaleDown, child: Text("Rp ${_formatCurrency(total)}", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 24))),
                    ],
                  ),
                  
                  if (!isPaid) ...[
                    const SizedBox(height: 32),
                    const Text("Pilih Metode Pembayaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // --- GRID TOMBOL (YANG SUDAH DIPERBAIKI) ---
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 3.0, crossAxisSpacing: 10, mainAxisSpacing: 10
                      ),
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final m = _paymentMethods[index];
                        bool selected = _selectedPaymentMethod == m['id'];
                        
                        return Material(
                          // Logika warna background saat dipilih
                          color: selected ? m['color'].withOpacity(0.3) : Colors.white10,
                          
                          // [FIX] Pindahkan borderRadius ke dalam shape
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: selected ? m['color'] : Colors.transparent, 
                              width: selected ? 2 : 0
                            )
                          ),
                          clipBehavior: Clip.antiAlias,
                          
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = m['id'];
                                if (_selectedPaymentMethod != 'cash') {
                                  _cashController.clear(); 
                                  _changeAmount = 0.0;
                                }
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(m['icon'], color: selected ? m['color'] : Colors.white54, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown, 
                                      child: Text(m['name'], 
                                        style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))
                                    )
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.check_circle, color: m['color'], size: 16)
                                  ]
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // --- LOGIKA TAMPILAN SESUAI PILIHAN ---
                    const SizedBox(height: 20),

                    if (_selectedPaymentMethod == 'cash') 
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.5))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("INPUT UANG TUNAI:", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cashController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                prefixText: "Rp ", hintText: "0", border: OutlineInputBorder(),
                                filled: true, fillColor: Colors.black26,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                              ),
                              onChanged: _calculateChange,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Kembalian:", style: TextStyle(color: Colors.white70)),
                                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text("Rp ${_formatCurrency(_changeAmount)}", style: TextStyle(color: _changeAmount >= 0 ? Colors.white : Colors.red, fontSize: 18, fontWeight: FontWeight.bold)))),
                              ],
                            )
                          ],
                        ),
                      )
                    
                    else if (_selectedPaymentMethod == 'qris')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            const Text("SCAN QRIS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            const Icon(Icons.qr_code_2, size: 120, color: Colors.black),
                            const SizedBox(height: 8),
                            Text("Total: Rp ${_formatCurrency(total)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      )

                    else if (_selectedPaymentMethod == 'transfer')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal)),
                        child: Column(
                          children: const [
                            Icon(Icons.account_balance, size: 40, color: Colors.teal),
                            SizedBox(height: 8),
                            Text("Silakan Transfer ke:", style: TextStyle(color: Colors.white70)),
                            Text("BCA 123-456-7890", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("a.n Resto Pro Corporate", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      )
                      
                    else if (_selectedPaymentMethod == 'debit')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange)),
                        child: Row(
                          children: const [
                            Icon(Icons.credit_card, size: 40, color: Colors.orange),
                            SizedBox(width: 16),
                            Expanded(child: Text("Silakan gesek kartu pada mesin EDC.", style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      )
                  ]
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: !isPaid 
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mencetak Bill Sementara...")));
                        }, 
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        child: const Text("Cetak Bill", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50), 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        child: _isProcessing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Konfirmasi Bayar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {}, icon: const Icon(Icons.print), label: const Text("Cetak Struk Lunas"),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white54), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text("Rp ${_formatCurrency(val)}", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    return double.parse(amount.toString()).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}