/// Kelas yang merepresentasikan data pengguna dalam sistem
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
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'waiter',
      token: json['token'],
    );
  }

  /// Mengubah objek User menjadi Map JSON
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

  /// Mengecek apakah pengguna adalah Admin
  bool get isAdmin => role == 'admin';

  /// Mengecek apakah pengguna adalah Customer Service
  bool get isCS => role == 'cs';

  /// Mengecek apakah pengguna adalah Pelayan
  bool get isWaiter => role == 'waiter';

  /// Mengecek apakah pengguna adalah Koki
  bool get isChef => role == 'chef';

  /// Fitur Loyalti: Dapat diakses oleh Admin dan Manager
  bool get canManageLoyalty => role == 'admin' || role == 'manager';

  /// Mendapatkan nama tampilan peran pengguna dalam Bahasa Indonesia
  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Pemilik / Admin';
      case 'cs':
        return 'Layanan Pelanggan';
      case 'waiter':
        return 'Pelayan / Waiter';
      case 'chef':
        return 'Kepala Dapur';
      default:
        return 'Staf';
    }
  }
}
