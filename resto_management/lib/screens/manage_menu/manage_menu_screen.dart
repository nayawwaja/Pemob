import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_edit_menu_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> with SingleTickerProviderStateMixin {
  // Data
  List<dynamic> _allMenuItems = [];
  List<dynamic> _filteredItems = [];
  List<dynamic> _categories = [];
  
  // State Filter & Search
  int _selectedCategoryId = 0; // 0 = Semua
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load Categories & Menu secara paralel
      final results = await Future.wait([
        ApiService.get('menu.php?action=get_categories'),
        ApiService.get('menu.php?action=get_menu'),
      ]);

      final catRes = results[0];
      final menuRes = results[1];

      if (mounted) {
        setState(() {
          // Setup Kategori (Tambah opsi 'Semua' di awal)
          if (catRes['success'] == true) {
            _categories = [
              {'id': 0, 'name': 'Semua', 'icon': '🔥'},
              ...catRes['data']
            ];
          }
          
          // Setup Menu
          if (menuRes['success'] == true) {
            _allMenuItems = menuRes['data'];
            _applyFilter(); // Terapkan filter awal
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading management data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredItems = _allMenuItems.where((item) {
        // Filter by Category
        bool categoryMatch = _selectedCategoryId == 0 || 
            int.parse(item['category_id'].toString()) == _selectedCategoryId;
        
        // Filter by Search
        bool searchMatch = _searchQuery.isEmpty || 
            item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  // Quick Action: Ubah Status Ketersediaan (Available/Unavailable)
  Future<void> _toggleAvailability(int id, bool currentStatus) async {
    // Optimistic Update (Ubah UI duluan biar cepat)
    final index = _allMenuItems.indexWhere((i) => int.parse(i['id'].toString()) == id);
    if (index != -1) {
      setState(() {
        _allMenuItems[index]['is_available'] = currentStatus ? 0 : 1; // Balik status
        _applyFilter();
      });
    }

    // Kirim ke API (Gunakan endpoint update menu yang sudah ada, atau buat endpoint khusus toggle)
    // Disini kita gunakan asumsi update_menu support partial update atau kita kirim full data
    // Untuk efisiensi, idealnya ada API khusus toggle. Kita pakai logic sederhana update menu.
    final item = _allMenuItems[index];
    await ApiService.post('menu.php?action=update_menu', {
      'id': id,
      'category_id': item['category_id'],
      'name': item['name'],
      'price': item['price'],
      'stock': item['stock'],
      'is_available': currentStatus ? 0 : 1, // Status baru
      // field lain dikirim ulang agar tidak null
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Status ${item['name']} diperbarui"), 
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.blueAccent,
      )
    );
  }

  Future<void> _deleteMenu(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text("Hapus Menu?", style: TextStyle(color: Colors.redAccent)),
        content: Text("Menu '${item['name']}' akan dihapus dari daftar. Stok akan hilang.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus Permanen"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.post('menu.php?action=delete_menu&id=${item['id']}', {});
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menu berhasil dihapus"), backgroundColor: Colors.red));
          _loadData(); // Refresh full
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Manajemen Menu', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _loadData,
          )
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR & FILTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.05), offset: const Offset(0, 4), blurRadius: 10)],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari menu (Nasi, Ayam, Kopi...)',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Horizontal Category Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategoryId == int.parse(cat['id'].toString());
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat['name']),
                          avatar: Text(cat['icon'] ?? ''),
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
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                          checkmarkColor: Colors.black,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. MENU LIST
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fastfood_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          const Text("Menu tidak ditemukan", style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) => _buildMenuCard(_filteredItems[index]),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditMenuScreen()),
          );
          _loadData();
        },
        backgroundColor: const Color(0xFFD4AF37),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("TAMBAH MENU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item) {
    final stock = int.parse(item['stock'].toString());
    final price = double.parse(item['price'].toString());
    final isAvailable = (item['is_available'] == 1 || item['is_available'] == true);
    
    // Logic Status Stok
    Color stockColor = Colors.green;
    String stockText = "Stok: $stock";
    if (stock == 0) {
      stockColor = Colors.red;
      stockText = "HABIS";
    } else if (stock <= 5) {
      stockColor = Colors.orange;
      stockText = "Menipis ($stock)";
    }

    return Card(
      color: const Color(0xFF252525),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: stock == 0 ? Colors.red.withOpacity(0.5) : Colors.transparent, 
          width: 1
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Image Container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  image: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                      ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                      : null,
                ),
                child: item['image_url'] == null || item['image_url'].toString().isEmpty
                    ? const Icon(Icons.image_not_supported, color: Colors.white24, size: 40)
                    : null,
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'],
                              style: TextStyle(
                                color: isAvailable ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: isAvailable ? null : TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item['is_promo'] == 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text("PROMO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'] ?? 'Tidak ada deskripsi',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Rp ${_formatCurrency(price)}", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.1),
                              border: Border.all(color: stockColor.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(stockText, style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Action Bar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF202020),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle Switch Availability
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isAvailable,
                        activeColor: Colors.green,
                        inactiveTrackColor: Colors.grey[800],
                        onChanged: (val) => _toggleAvailability(int.parse(item['id'].toString()), isAvailable),
                      ),
                    ),
                    Text(
                      isAvailable ? "Aktif" : "Non-Aktif",
                      style: TextStyle(color: isAvailable ? Colors.green : Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                
                // Edit & Delete Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      tooltip: "Edit Menu",
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddEditMenuScreen(menuItem: item)),
                        );
                        _loadData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                      tooltip: "Hapus Menu",
                      onPressed: () => _deleteMenu(item),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}