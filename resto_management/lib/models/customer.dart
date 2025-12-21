class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final int loyaltyPoints;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.loyaltyPoints = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Tanpa Nama',
      phone: json['phone'],
      email: json['email'],
      loyaltyPoints:
          int.tryParse(json['loyalty_points']?.toString() ?? '0') ?? 0,
    );
  }
}
