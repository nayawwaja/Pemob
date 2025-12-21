import 'package:flutter/material.dart';
import '../../models/menu_item.dart';

/// Layar detail untuk menampilkan informasi lengkap menu dan menambah ke keranjang
class MenuDetailScreen extends StatefulWidget {
  final MenuItem menuItem;
  final Function(int quantity, String notes) onAddToCart;

  const MenuDetailScreen({
    super.key,
    required this.menuItem,
    required this.onAddToCart,
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  int quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.menuItem;
    final double finalPrice = item.discountPrice ?? item.price;
    final bool isOutOfStock = item.stock == 0;
    final bool isLowStock = item.isLowStock;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          // Bagian Scrollable (Header + Konten)
          Expanded(
            child: CustomScrollView(
              slivers: [
                // HEADER MEWAH (SLIVER APP BAR)
                SliverAppBar(
                  expandedHeight: 300.0,
                  pinned: true, // AppBar tetap nempel saat scroll
                  backgroundColor: Colors.black,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gambar Menu
                        item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, error, stackTrace) =>
                                    Container(
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.broken_image,
                                            size: 60, color: Colors.white24)),
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.fastfood,
                                    size: 80, color: Colors.white24),
                              ),

                        // Gradient Gelap di Bawah Gambar (Supaya teks terlihat)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF1A1A1A)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Isi Konten Detail
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Kategori & Stok
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.categoryName.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            if (isOutOfStock)
                              _buildBadge("HABIS", Colors.red)
                            else if (isLowStock)
                              _buildBadge("SISA ${item.stock}", Colors.orange)
                            else
                              _buildBadge("TERSEDIA", Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Nama Menu
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Harga & Diskon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Rp ${_formatCurrency(finalPrice)}",
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.discountPrice != null) ...[
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "Rp ${_formatCurrency(item.price)}",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4)),
                                child: const Text("PROMO",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 24),

                        // Deskripsi
                        const Text("Deskripsi",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          item.description ??
                              "Belum ada deskripsi untuk menu ini.",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14, height: 1.6),
                        ),

                        const SizedBox(height: 24),

                        // Komposisi (Jika ada)
                        if (item.ingredients != null &&
                            item.ingredients!.isNotEmpty) ...[
                          const Text("Komposisi",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            item.ingredients!,
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Peringatan Alergi (Jika ada)
                        if (item.allergens != null &&
                            item.allergens!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFFFF9800).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFFF9800)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Informasi Alergi",
                                          style: TextStyle(
                                              color: Color(0xFFFF9800),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(item.allergens!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Input Catatan
                        const Text("Catatan Pesanan",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Contoh: Jangan pedas, pisahkan saus...",
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.edit_note,
                                color: Colors.white54),
                          ),
                        ),

                        const SizedBox(
                            height:
                                80), // Spasi agar tidak tertutup tombol bawah
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bar Bawah (Sticky)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity Counter
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            "$quantity",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: quantity < item.stock
                              ? () => setState(() => quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Add Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              widget.onAddToCart(
                                  quantity, _notesController.text);
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? Colors.grey
                            : const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey[800],
                        elevation: isOutOfStock ? 0 : 5,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isOutOfStock ? "STOK HABIS" : "TAMBAH PESANAN",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (!isOutOfStock)
                            Text(
                              "Rp ${_formatCurrency(finalPrice * quantity)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.black87),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Widget untuk menampilkan badge status stok
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Memformat angka ke format mata uang
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
