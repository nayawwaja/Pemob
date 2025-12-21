import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

/// Layar keranjang belanja untuk konfirmasi pesanan
/// FIXED VERSION - dengan null safety dan error handling yang lebih baik
class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();

  late List<Map<String, dynamic>> items;
  List<dynamic> _tables = [];

  // State Input
  int? _selectedTableId;
  final TextEditingController _customerNameController =
      TextEditingController(text: "Guest");
  bool _isLoading = false;
  bool _isTablesLoading = true;
  String? _tableError;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    // Deep copy items to avoid reference issues
    items = widget.cartItems.map((item) => Map<String, dynamic>.from(item)).toList();
    _initializeData();
  }

  // FIXED: Sequential initialization to avoid race conditions
  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadTables();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userId = prefs.getInt('userId') ?? 0);
    }
  }

  /// Memuat daftar meja dari API
  Future<void> _loadTables() async {
    if (!mounted) return;
    
    setState(() {
      _isTablesLoading = true;
      _tableError = null;
    });

    try {
      final res = await ApiService.get('tables.php?action=get_all');

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _tables = res['data'] as List? ?? [];
        });
      } else {
        setState(() => _tableError = res['message'] ?? "Gagal memuat meja.");
      }
    } catch (e) {
      print("Error load tables: $e");
      if (mounted) {
        setState(() => _tableError = "Koneksi Error. Cek Server.");
      }
    } finally {
      if (mounted) setState(() => _isTablesLoading = false);
    }
  }

  // ============================================
  // SAFE PARSING HELPERS
  // ============================================
  
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Menghitung subtotal pesanan - FIXED dengan safe parsing
  double get subtotal {
    return items.fold(0.0, (sum, item) {
      final price = _safeParseDouble(item['price']);
      final quantity = _safeParseInt(item['quantity']);
      return sum + (price * quantity);
    });
  }

  double get tax => subtotal * 0.1;
  double get serviceCharge => subtotal * 0.05;
  double get total => subtotal + tax + serviceCharge;

  /// Memperbarui jumlah item dalam keranjang - FIXED
  void _updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= items.length) return;
    
    if (newQuantity <= 0) {
      setState(() => items.removeAt(index));
    } else {
      int stock = _safeParseInt(items[index]['stock']);
      if (stock <= 0) stock = 999; // Default jika stock tidak ada
      
      if (newQuantity <= stock) {
        setState(() => items[index]['quantity'] = newQuantity);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Stok maksimal: $stock"),
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.orange));
      }
    }
  }

  /// Mengirim pesanan ke API - FIXED dengan better error handling
  Future<void> _submitOrder() async {
    // Validasi Form sebelum submit
    if (!_formKey.currentState!.validate()) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keranjang kosong!'), backgroundColor: Colors.red));
      return;
    }

    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap pilih nomor meja!'),
          backgroundColor: Colors.red));
      return;
    }

    // Validasi ulang meja yang dipilih
    final selectedTable = _tables.firstWhere(
      (t) => _safeParseInt(t['id']) == _selectedTableId,
      orElse: () => null,
    );
    
    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meja tidak valid!'),
          backgroundColor: Colors.red));
      return;
    }
    
    if (selectedTable['status']?.toString().toLowerCase() == 'dirty') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meja ini kotor! Pilih meja lain.'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format Data untuk API - FIXED dengan safe parsing
      final orderData = {
        'user_id': _userId,
        'table_id': _selectedTableId,
        'customer_name': _customerNameController.text.trim().isEmpty 
            ? 'Guest' 
            : _customerNameController.text.trim(),
        'items': items.map((i) => {
          'id': _safeParseInt(i['id']),
          'quantity': _safeParseInt(i['quantity']),
          'notes': i['notes']?.toString() ?? ''
        }).toList()
      };

      // Kirim ke API
      final res = await ApiService.post('orders.php?action=create_order', orderData);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? "Gagal membuat pesanan"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      print("Submit order error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Pesanan Berhasil Masuk Dapur!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan'),
        backgroundColor: Colors.black,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: "Kosongkan Keranjang",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF2A2A2A),
                    title: const Text("Kosongkan Keranjang?", 
                      style: TextStyle(color: Colors.white)),
                    content: const Text("Semua item akan dihapus.", 
                      style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => items.clear());
                        },
                        child: const Text("Hapus Semua"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
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
                    // Header & Pemilihan Meja
                    const Text("Informasi Pesanan",
                        style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Dropdown Meja
                    _isTablesLoading
                        ? const Center(
                            child: LinearProgressIndicator(
                                color: Color(0xFFD4AF37)))
                        : _buildTableSelectionWidget(),

                    const SizedBox(height: 12),

                    // Input Nama
                    TextFormField(
                      controller: _customerNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Nama Pelanggan (Opsional)",
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.person, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daftar Item
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Daftar Menu",
                            style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text("${items.length} item",
                            style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart_outlined, 
                                color: Colors.white24, size: 60),
                              SizedBox(height: 12),
                              Text("Keranjang Kosong",
                                  style: TextStyle(color: Colors.white38)),
                            ],
                          ),
                        ),
                      )
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

            // Ringkasan & Tombol
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  /// Widget dropdown pemilihan meja - FIXED
  Widget _buildTableSelectionWidget() {
    if (_tableError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
                child: Text(_tableError!,
                    style: const TextStyle(color: Colors.red))),
            IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadTables)
          ],
        ),
      );
    }

    if (_tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text("Tidak ada meja terdaftar di Database",
                  style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedTableId,
      dropdownColor: const Color(0xFF333333),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Pilih Nomor Meja *",
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.table_restaurant, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      items: _tables.map((t) {
        int tId = _safeParseInt(t['id']);
        String status = (t['status']?.toString() ?? 'unknown').toUpperCase();
        String tableNumber = t['table_number']?.toString() ?? 'Meja ?';
        bool isDirty = status == 'DIRTY';
        bool isReserved = status == 'RESERVED';
        bool isOccupied = status == 'OCCUPIED';

        Color textColor = Colors.white;
        if (isDirty) textColor = Colors.grey;
        else if (isReserved) textColor = Colors.blue;
        else if (isOccupied) textColor = Colors.orange;
        else textColor = Colors.green;

        return DropdownMenuItem<int>(
          value: tId,
          enabled: !isDirty, // Disable meja kotor
          child: Row(
            children: [
              Icon(
                isDirty ? Icons.cleaning_services : 
                isReserved ? Icons.bookmark :
                isOccupied ? Icons.people : Icons.check_circle,
                color: textColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "$tableNumber ($status)",
                style: TextStyle(
                  color: isDirty ? Colors.grey[600] : textColor,
                  fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                  decoration: isDirty ? TextDecoration.lineThrough : null,
                ),
              ),
              if (isOccupied) ...[
                const SizedBox(width: 4),
                const Text("+ tambah", style: TextStyle(color: Colors.orange, fontSize: 10)),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        
        final selectedTable = _tables.firstWhere(
          (t) => _safeParseInt(t['id']) == val,
          orElse: () => null,
        );
        
        if (selectedTable == null) return;
        
        String status = selectedTable['status']?.toString().toLowerCase() ?? '';
        
        if (status == 'dirty') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Meja ini kotor! Harap bersihkan terlebih dahulu."),
            backgroundColor: Colors.orange,
          ));
          return;
        }
        
        if (status == 'occupied') {
          // Tampilkan info bahwa ini akan menambah ke order existing
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Pesanan akan ditambahkan ke meja ${selectedTable['table_number']} yang sedang terisi."),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ));
        }
        
        setState(() => _selectedTableId = val);
      },
      validator: (value) {
        if (value == null) {
          return 'Wajib pilih meja';
        }
        
        final selectedTable = _tables.firstWhere(
          (t) => _safeParseInt(t['id']) == value,
          orElse: () => null,
        );
        
        if (selectedTable == null) {
          return 'Meja tidak valid';
        }
        
        if (selectedTable['status']?.toString().toLowerCase() == 'dirty') {
          return 'Meja ini kotor, tidak bisa dipilih';
        }
        
        return null;
      },
    );
  }

  /// Widget item keranjang - FIXED
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    double price = _safeParseDouble(item['price']);
    int quantity = _safeParseInt(item['quantity']);
    String name = item['name']?.toString() ?? 'Unknown Item';
    String? imageUrl = item['image_url']?.toString();
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Dismissible(
      key: Key('cart_item_${item['id']}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() => items.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$name dihapus"),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              setState(() => items.insert(index, item));
            },
          ),
        ));
      },
      child: Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800],
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                ),
                child: !hasImage
                    ? const Icon(Icons.fastfood, color: Colors.white24)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rp ${_formatCurrency(price)}",
                      style: const TextStyle(color: Color(0xFFD4AF37)),
                    ),
                    Text(
                      "Subtotal: Rp ${_formatCurrency(price * quantity)}",
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                      onPressed: () => _updateQuantity(index, quantity - 1),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "$quantity",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                      onPressed: () => _updateQuantity(index, quantity + 1),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Panel bawah untuk total dan tombol proses
  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
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
                const Text("TOTAL",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text("Rp ${_formatCurrency(total)}",
                    style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 24)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: items.isEmpty 
                      ? Colors.grey 
                      : const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[700],
                ),
                onPressed: (_isLoading || _isTablesLoading || items.isEmpty) 
                    ? null 
                    : _submitOrder,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send),
                          const SizedBox(width: 8),
                          Text(
                            items.isEmpty ? "KERANJANG KOSONG" : "PROSES ORDER",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Widget baris ringkasan harga
  Widget _buildRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text("Rp ${_formatCurrency(val)}",
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// Memformat angka ke format mata uang
  String _formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return "0";
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}