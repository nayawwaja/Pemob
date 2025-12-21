import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';

class AddEditCustomerScreen extends StatefulWidget {
  const AddEditCustomerScreen({super.key});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final res = await ApiService.post('customers.php?action=add_customer', {
        'name': _nameController.text,
        'phone': _phoneController.text,
      });

      if (mounted) {
        if (res['success'] == true && res['data'] != null) {
          final newCustomer = Customer.fromJson(res['data']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pelanggan ${newCustomer.name} berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
          // Kirim data customer baru kembali ke layar sebelumnya
          Navigator.pop(context, newCustomer);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal menyimpan pelanggan.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Pelanggan Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveCustomer,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'MENYIMPAN...' : 'SIMPAN PELANGGAN'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
