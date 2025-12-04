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
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      displayOrder: json['display_order'],
    );
  }
}