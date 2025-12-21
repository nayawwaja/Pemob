class Category {
  final int id;
  final String name;
  final String? icon;
  final int displayOrder;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.displayOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Tanpa Nama',
      icon: json['icon'],
      displayOrder: int.tryParse(json['sort_order'].toString()) ??
          0, // FIX: column name is sort_order
    );
  }
}
