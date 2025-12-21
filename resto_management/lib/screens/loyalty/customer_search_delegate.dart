import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';
import 'add_edit_customer_screen.dart';

class CustomerSearchDelegate extends SearchDelegate<Customer?> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarTextStyle: theme.textTheme.bodyMedium,
        titleTextStyle: theme.textTheme.titleMedium,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleMedium: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  String? get searchFieldLabel => 'Cari Nama atau No. HP Customer...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      // Tombol untuk membuat customer baru
      TextButton.icon(
        onPressed: () async {
          // Buka layar AddEditCustomerScreen
          final newCustomer = await Navigator.push<Customer>(
            context,
            MaterialPageRoute(
                builder: (context) => const AddEditCustomerScreen()),
          );
          // Jika customer baru berhasil dibuat dan dikembalikan, tutup pencarian
          // dan kirim customer baru tersebut sebagai hasil.
          if (newCustomer != null) {
            close(context, newCustomer);
          }
        },
        icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
        label: const Text("Daftar Baru",
            style: TextStyle(color: Color(0xFFD4AF37))),
      ),

      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: const Color(0xFF1A1A1A));
    }
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: const Color(0xFF1A1A1A));
    }
    return _buildSearchResults(query);
  }

  Widget _buildSearchResults(String query) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: FutureBuilder<List<Customer>>(
        future: _searchCustomers(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Customer tidak ditemukan.',
                    style: TextStyle(color: Colors.white54)));
          }

          final customers = snapshot.data!;
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                title: Text(customer.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(customer.phone ?? '',
                    style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  close(context, customer);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Customer>> _searchCustomers(String query) async {
    try {
      final res =
          await ApiService.get('customers.php?action=search&query=$query');
      if (res['success'] == true && res['data'] != null) {
        return (res['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      }
    } catch (e) {
      print("Error searching customers: $e");
    }
    return [];
  }
}
