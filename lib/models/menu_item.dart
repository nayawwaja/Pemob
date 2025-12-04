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
  final bool isPromo;
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
    required this.isPromo,
    required this.isAvailable,
    required this.categoryName,
  });
  
  // Factory yang AMAN dari error tipe data PHP (String/Int/Null)
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    
    // Helper: Paksa jadi Boolean (True/False)
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == "1" || value == "true";
      return false;
    }

    // Helper: Paksa jadi Double (Angka Desimal)
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Helper: Paksa jadi Integer (Angka Bulat)
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
      discountPrice: json['discount_price'] != null ? parseDouble(json['discount_price']) : null,
      imageUrl: json['image_url'],
      stock: parseInt(json['stock']),
      ingredients: json['ingredients'],
      allergens: json['allergens'],
      isPromo: parseBool(json['is_promo']),         // Aman dari error
      isAvailable: parseBool(json['is_available']), // Aman dari error
      categoryName: json['category_name'] ?? '',
    );
  }

  // Method untuk mengubah Object kembali ke JSON/Map (Penting untuk Cart)
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
      'is_promo': isPromo ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'category_name': categoryName,
    };
  }
  
  bool get isLowStock => stock <= 5 && stock > 0;
  bool get isOutOfStock => stock == 0;
  double get finalPrice => discountPrice ?? price;
}