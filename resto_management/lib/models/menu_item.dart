/// Kelas model yang merepresentasikan item menu makanan/minuman
class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final String? imageUrl;
  final int stock;
  final String? ingredients;
  final String? allergens;
  final bool isFeatured;
  final bool isAvailable;
  final String categoryName;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    this.imageUrl,
    required this.stock,
    this.ingredients,
    this.allergens,
    required this.isFeatured,
    required this.isAvailable,
    required this.categoryName,
  });

  /// Factory method untuk membuat instance dari JSON, menangani tipe data yang tidak konsisten
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Fungsi bantuan: Konversi ke Boolean
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == "1" || value == "true";
      return false;
    }

    // Fungsi bantuan: Konversi ke Double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Fungsi bantuan: Konversi ke Integer
    int parseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    return MenuItem(
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      name: json['name'] ?? 'Tanpa Nama',
      description: json['description'],
      price: parseDouble(json['price']),
      discountPrice: json['discount_price'] != null
          ? parseDouble(json['discount_price'])
          : null,
      imageUrl: json['image_url'],
      stock: parseInt(json['stock']),
      ingredients: json['ingredients'],
      allergens: json['allergens'],
      isFeatured: parseBool(json['is_featured']),
      isAvailable: parseBool(json['is_available']),
      categoryName: json['category_name'] ?? '',
    );
  }

  /// Mengubah objek kembali ke Map JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'image_url': imageUrl,
      'stock': stock,
      'ingredients': ingredients,
      'allergens': allergens,
      'is_featured': isFeatured ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'category_name': categoryName,
    };
  }

  bool get isLowStock => stock <= 5 && stock > 0;
  bool get isOutOfStock => stock == 0;
  double get finalPrice => discountPrice ?? price;
}
