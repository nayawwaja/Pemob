import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddEditMenuScreen extends StatefulWidget {
  final Map<String, dynamic>? menuItem; // Jika null = Add Mode, Jika isi = Edit Mode

  const AddEditMenuScreen({super.key, this.menuItem});

  @override
  State<AddEditMenuScreen> createState() => _AddEditMenuScreenState();
}

class _AddEditMenuScreenState extends State<AddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  
  // State
  int? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isPromo = false;
  bool _isLoading = false;
  List<dynamic> _categories = [];

  // Focus Node untuk UX (Image Preview update saat kehilangan fokus)
  final FocusNode _imageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    
    // Inisialisasi Controller
    _nameController = TextEditingController(text: item?['name'] ?? '');
    _descController = TextEditingController(text: item?['description'] ?? '');
    _priceController = TextEditingController(text: item?['price'] != null ? double.parse(item!['price'].toString()).toInt().toString() : '');
    _discountController = TextEditingController(text: item?['discount_price'] != null ? double.parse(item!['discount_price'].toString()).toInt().toString() : '');
    _stockController = TextEditingController(text: item?['stock']?.toString() ?? '20');
    _imageController = TextEditingController(text: item?['image_url'] ?? '');
    
    // Inisialisasi State Tambahan
    if (item != null) {
      _selectedCategoryId = int.tryParse(item['category_id'].toString());
      _isAvailable = (item['is_available'] == 1 || item['is_available'] == true);
      _isPromo = (item['is_promo'] == 1 || item['is_promo'] == true);
    }
    
    // Listener untuk Image Preview
    _imageFocusNode.addListener(() {
      if (!_imageFocusNode.hasFocus) {
        setState(() {}); // Refresh UI untuk menampilkan gambar
      }
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _imageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final res = await ApiService.get('menu.php?action=get_categories');
    if (mounted && res['success'] == true) {
      setState(() {
        _categories = res['data'];
        // Jika Add Mode, set default category ke yang pertama
        if (widget.menuItem == null && _categories.isNotEmpty) {
          _selectedCategoryId = int.parse(_categories[0]['id'].toString());
        }
      });
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validasi Logika Bisnis
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih kategori menu!")));
      return;
    }

    double price = double.tryParse(_priceController.text) ?? 0;
    double discount = double.tryParse(_discountController.text) ?? 0;

    if (discount >= price && discount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harga diskon tidak boleh lebih besar dari harga asli!"), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Siapkan Body Data
    final body = {
      'category_id': _selectedCategoryId,
      'name': _nameController.text,
      'description': _descController.text,
      'price': price,
      'discount_price': _discountController.text.isEmpty ? null : discount,
      'stock': int.parse(_stockController.text),
      'image_url': _imageController.text,
      'is_available': _isAvailable ? 1 : 0,
      'is_promo': _isPromo ? 1 : 0,
    };

    String action = 'add_menu';
    if (widget.menuItem != null) {
      action = 'update_menu';
      body['id'] = widget.menuItem!['id'];
    }

    // Kirim ke API
    final res = await ApiService.post('menu.php?action=$action', body);
    
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menu berhasil disimpan!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Kembali ke layar sebelumnya
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal menyimpan"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menuItem != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(isEdit ? "Edit Menu" : "Tambah Menu Baru"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SECTION GAMBAR (LIVE PREVIEW)
              _buildImagePreview(),
              const SizedBox(height: 24),

              // 2. SECTION INFORMASI DASAR
              const Text("Informasi Dasar", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildTextField(_nameController, "Nama Menu", Icons.fastfood),
              const SizedBox(height: 16),
              _buildDropdownCategory(),
              const SizedBox(height: 16),
              _buildTextField(_descController, "Deskripsi Menu", Icons.description, maxLines: 3),
              const SizedBox(height: 24),

              // 3. SECTION HARGA & STOK
              const Text("Harga & Inventori", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceController, "Harga (Rp)", Icons.attach_money, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_stockController, "Stok Awal", Icons.inventory_2, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _discountController, 
                "Harga Diskon (Opsional)", 
                Icons.discount, 
                isNumber: true,
                hint: "Kosongkan jika tidak ada diskon"
              ),
              
              const SizedBox(height: 24),

              // 4. SECTION PENGATURAN
              const Text("Pengaturan Status", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Status Aktif (Tersedia)", style: TextStyle(color: Colors.white)),
                      subtitle: const Text("Menu akan tampil di aplikasi pelayan", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      value: _isAvailable,
                      activeColor: Colors.green,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    SwitchListTile(
                      title: const Text("Menu Promo", style: TextStyle(color: Colors.white)),
                      subtitle: const Text("Tandai sebagai menu spesial/promo", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      value: _isPromo,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (val) => setState(() => _isPromo = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveMenu,
                  icon: _isLoading ? const SizedBox() : const Icon(Icons.save),
                  label: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
              image: _imageController.text.isNotEmpty 
                ? DecorationImage(
                    image: NetworkImage(_imageController.text),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {}, // Handle jika link rusak
                  )
                : null,
            ),
            child: _imageController.text.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.white24),
                      SizedBox(height: 8),
                      Text("Preview Gambar", style: TextStyle(color: Colors.white24)),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _imageController,
          focusNode: _imageFocusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "URL Gambar",
            hintText: "https://contoh.com/gambar.jpg",
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.link, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1, String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (!isNumber && label.contains("Diskon")) return null; // Diskon opsional
        if (label.contains("Opsional")) return null;
        return val!.isEmpty ? '$label wajib diisi' : null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1)),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildDropdownCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          dropdownColor: const Color(0xFF333333),
          decoration: const InputDecoration(
            labelText: "Kategori Menu",
            labelStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.category, color: Colors.white54),
            border: InputBorder.none,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null ? 'Pilih kategori' : null,
          items: _categories.map((cat) {
            return DropdownMenuItem<int>(
              value: int.parse(cat['id'].toString()),
              child: Text(cat['name']),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategoryId = val!),
        ),
      ),
    );
  }
}