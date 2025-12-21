import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/menu_item.dart'; // Pastikan file model ini ada
import '../order/cart_screen.dart'; // Kita butuh CartScreen
import 'menu_detail_screen.dart'; // Kita butuh MenuDetailScreen

/// Layar untuk menampilkan daftar menu dan membuat pesanan
class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  // Data
  List<MenuItem> _menuItems = [];
  List<MenuItem> _filteredItems = [];
  List<dynamic> _categories = [];

  // Cart Local
  List<Map<String, dynamic>> _cart = [];

  // UI State
  int _selectedCategoryId = 0; // 0 = Semua
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  /// Mengambil data kategori dan menu dari API
  Future<void> _loadMenuData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get('menu.php?action=get_categories'),
        ApiService.get('menu.php?action=get_menu'),
      ]);

      if (mounted) {
        setState(() {
          // 1. Categories
          if (results[0]['success'] == true) {
            _categories = [
              {'id': 0, 'name': 'Semua', 'icon': '🍽️'},
              ...results[0]['data']
            ];
          }

          // 2. Menu Items
          if (results[1]['success'] == true) {
            final List rawData = results[1]['data'];
            // Pastikan model MenuItem.fromJson() Anda sudah benar menangani tipe data
            _menuItems =
                rawData.map((json) => MenuItem.fromJson(json)).toList();
            _applyFilter();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading menu: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menyaring item menu berdasarkan kategori dan pencarian
  void _applyFilter() {
    setState(() {
      _filteredItems = _menuItems.where((item) {
        bool catMatch =
            _selectedCategoryId == 0 || item.categoryId == _selectedCategoryId;
        bool searchMatch = _searchQuery.isEmpty ||
            item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return catMatch && searchMatch;
      }).toList();
    });
  }

  /// Menambahkan item ke keranjang lokal
  void _addToCart(MenuItem item, {int quantity = 1, String notes = ''}) {
    setState(() {
      // Cek apakah item dengan ID dan notes yang SAMA sudah ada di cart
      int index =
          _cart.indexWhere((c) => c['id'] == item.id && c['notes'] == notes);

      if (index != -1) {
        // Jika ada, tambahkan quantity-nya
        int newQuantity = _cart[index]['quantity'] + quantity;
        if (newQuantity <= item.stock) {
          _cart[index]['quantity'] = newQuantity;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("${item.name} +$quantity"),
              duration: const Duration(milliseconds: 500)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Stok tidak mencukupi!"),
              backgroundColor: Colors.red));
        }
      } else {
        // Jika belum ada, tambah item baru
        if (item.stock >= quantity) {
          _cart.add({
            'id': item.id,
            'name': item.name,
            'price': item.finalPrice,
            'quantity': quantity,
            'image_url': item.imageUrl,
            'stock': item.stock,
            'notes': notes
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("${item.name} ditambahkan"),
              duration: const Duration(milliseconds: 500)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Stok tidak mencukupi!"),
              backgroundColor: Colors.red));
        }
      }
    });
  }

  /// Membuka layar keranjang belanja
  void _openCart() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Keranjang kosong")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen(cartItems: _cart)),
    );

    // Jika order sukses (return true), kosongkan cart & refresh stok
    if (result == true) {
      setState(() => _cart.clear());
      _loadMenuData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Color(0xFFD4AF37)),
                onPressed: _openCart,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                        "${_cart.fold(0, (sum, item) => sum + (item['quantity'] as int))}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                _searchQuery = val;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: 'Cari menu...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
          ),

          // Categories
          Container(
            height: 50,
            color: Colors.black,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected =
                    _selectedCategoryId == int.parse(cat['id'].toString());
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(cat['name']),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategoryId = int.parse(cat['id'].toString());
                        _applyFilter();
                      });
                    },
                    backgroundColor: const Color(0xFF2A2A2A),
                    selectedColor: const Color(0xFFD4AF37),
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

          // Menu Grid
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFD4AF37),
              backgroundColor: const Color(0xFF2A2A2A),
              onRefresh: _loadMenuData,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                  : _filteredItems.isEmpty
                      ? const Center(
                          child: Text("Menu tidak ditemukan",
                              style: TextStyle(color: Colors.white38)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) =>
                            _buildMenuItem(_filteredItems[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun widget kartu untuk setiap item menu
  Widget _buildMenuItem(MenuItem item) {
    bool isOutOfStock = item.isOutOfStock; // Getter dari Model

    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Menu untuk tambah opsi/notes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuDetailScreen(
              menuItem: item,
              // FIX: Menyesuaikan callback agar bisa menerima qty dan notes dari detail screen
              onAddToCart: (qty, notes) =>
                  _addToCart(item, quantity: qty, notes: notes),
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF2A2A2A),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (item.imageUrl == null || item.imageUrl!.isEmpty)
                      const Center(
                          child: Icon(Icons.fastfood,
                              size: 40, color: Colors.white24)),
                    if (isOutOfStock)
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16))),
                        alignment: Alignment.center,
                        child: const Text("HABIS",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("Rp ${_formatCurrency(item.finalPrice)}",
                      style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? Colors.grey
                            : const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: isOutOfStock ? null : () => _addToCart(item),
                      child: const Text("TAMBAH",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Memformat angka menjadi format mata uang Rupiah
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
