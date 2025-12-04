// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; 
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'waiter', // Default ke waiter jika null
      token: json['token'], // Bisa null jika cuma update profil
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
    };
  }

  // --- Helpers untuk Logika Tampilan (Permissions) ---

  // Admin: Akses Penuh
  bool get isAdmin => role == 'admin';

  // CS: Reservasi, Pembayaran, Check-in
  bool get isCS => role == 'cs';

  // Waiter: Buat Order, Antar Makanan, Bersihkan Meja
  bool get isWaiter => role == 'waiter';

  // Chef: Melihat Order Masuk, Masak, Update Status Ready
  bool get isChef => role == 'chef';

  // String untuk tampilan di layar (Display Name)
  String get roleDisplay {
    switch (role) {
      case 'admin': return 'Owner / Admin';
      case 'cs': return 'Customer Service';
      case 'waiter': return 'Pelayan / Waiter';
      case 'chef': return 'Kepala Dapur';
      default: return 'Staff';
    }
  }
}