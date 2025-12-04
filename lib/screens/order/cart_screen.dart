import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // FIX: Global Key sekarang digunakan di widget Form
  final _formKey = GlobalKey<FormState>();

  late List<Map<String, dynamic>> items;
  List<dynamic> _tables = [];
  
  // State Input
  int? _selectedTableId;
  final TextEditingController _customerNameController = TextEditingController(text: "Guest");
  bool _isLoading = false;
  bool _isTablesLoading = true;
  String? _tableError; 
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.cartItems);
    _loadUserData();
    _loadTables();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getInt('userId') ?? 0);
  }

  Future<void> _loadTables() async {
    setState(() {
      _isTablesLoading = true;
      _tableError = null;
    });

    try {
      // Memanggil tables.php untuk mendapatkan semua meja
      final res = await ApiService.get('tables.php?action=get_all');
      
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _tables = res['data']; 
          });
        } else {
          setState(() => _tableError = res['message'] ?? "Gagal memuat meja.");
        }
      }
    } catch (e) {
      print("Error load tables: $e");
      setState(() => _tableError = "Koneksi Error. Cek Server.");
    } finally {
      if (mounted) setState(() => _isTablesLoading = false);
    }
  }

  // --- KALKULASI HARGA ---
  double get subtotal {
    return items.fold(0, (sum, item) {
      final price = double.parse(item['price'].toString());
      return sum + (price * int.parse(item['quantity'].toString()));
    });
  }

  double get tax => subtotal * 0.1;
  double get serviceCharge => subtotal * 0.05;
  double get total => subtotal + tax + serviceCharge;

  // --- LOGIC ---
  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() => items.removeAt(index));
    } else {
      int stock = int.parse(items[index]['stock'].toString());
      if (newQuantity <= stock) {
        setState(() => items[index]['quantity'] = newQuantity);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok Maksimal!"), duration: Duration(milliseconds: 500)));
      }
    }
  }

  Future<void> _submitOrder() async {
    // Validasi Form sebelum submit
    if (!_formKey.currentState!.validate()) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang kosong!'), backgroundColor: Colors.red));
      return;
    }
    
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih nomor meja!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    // Format Data untuk API
    final orderData = {
      'user_id': _userId,
      'table_id': _selectedTableId,
      'customer_name': _customerNameController.text,
      'total': total, // Mengirim Total Harga (sudah termasuk pajak/service)
      'items': items.map((i) => {
        'id': i['id'],
        'quantity': i['quantity'],
        'notes': i['notes'] ?? ''
      }).toList()
    };

    // Kirim ke API
    final res = await ApiService.post('orders.php?action=create_order', orderData);

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: const Text("Pesanan Berhasil Masuk Dapur!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true); 
                },
                child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal Order"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(title: const Text('Konfirmasi Pesanan'), backgroundColor: Colors.black),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER & MEJA
                    const Text("Informasi Pesanan", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // Dropdown Meja
                    _isTablesLoading
                      ? const Center(child: LinearProgressIndicator(color: Color(0xFFD4AF37)))
                      : _buildTableSelectionWidget(),
                    
                    const SizedBox(height: 12),

                    // Input Nama
                    TextFormField(
                      controller: _customerNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Nama Pelanggan (Opsional)",
                        prefixIcon: const Icon(Icons.person, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. LIST ITEM
                    const Text("Daftar Menu", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    if (items.isEmpty)
                      const Center(child: Text("Keranjang Kosong", style: TextStyle(color: Colors.white38)))
                    else
                      ...items.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var item = entry.value;
                        return _buildCartItem(item, idx);
                      }),
                  ],
                ),
              ),
            ),

            // 3. SUMMARY & BUTTON
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSelectionWidget() {
    if (_tableError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(_tableError!, style: const TextStyle(color: Colors.red))),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadTables)
          ],
        ),
      );
    }
    
    if (_tables.isEmpty) {
      return const Text("Tidak ada meja terdaftar di Database", style: TextStyle(color: Colors.redAccent));
    }
    
    return DropdownButtonFormField<int>(
      value: _selectedTableId,
      dropdownColor: const Color(0xFF333333),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Pilih Nomor Meja",
        prefixIcon: const Icon(Icons.table_restaurant, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _tables.map((t) {
        int tId = int.parse(t['id'].toString());
        String status = t['status'].toString().toUpperCase();
        
        return DropdownMenuItem<int>(
          value: tId,
          child: Text(
            "${t['table_number']} ($status)",
            style: TextStyle(
              color: status == 'OCCUPIED' ? Colors.orangeAccent : Colors.white,
              fontWeight: status == 'OCCUPIED' ? FontWeight.bold : FontWeight.normal
            ),
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedTableId = val),
      validator: (value) => value == null ? 'Wajib pilih meja' : null,
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    double price = double.parse(item['price'].toString());

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
                image: item['image_url'] != null && item['image_url'] != ''
                  ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover) 
                  : null,
              ),
              child: (item['image_url'] == null || item['image_url'] == '') 
                  ? const Icon(Icons.fastfood, color: Colors.white24) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Rp ${_formatCurrency(price)}", style: const TextStyle(color: Color(0xFFD4AF37))),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _updateQuantity(index, int.parse(item['quantity'].toString()) - 1)),
                Text("${item['quantity']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)), onPressed: () => _updateQuantity(index, int.parse(item['quantity'].toString()) + 1)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow("Subtotal", subtotal),
            _buildRow("Pajak (10%)", tax),
            _buildRow("Service (5%)", serviceCharge),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Rp ${_formatCurrency(total)}", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                onPressed: _isLoading || _isTablesLoading ? null : _submitOrder,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("PROSES ORDER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text("Rp ${_formatCurrency(val)}", style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}