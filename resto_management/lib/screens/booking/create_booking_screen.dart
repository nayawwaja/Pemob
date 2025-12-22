import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../payment/payment_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tables;
  final Map<String, dynamic>? selectedTable;

  const CreateBookingScreen({
    super.key,
    required this.tables,
    this.selectedTable,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _dpController = TextEditingController(text: '0');

  Map<String, dynamic>? _selectedTable;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _guestCount = 2;
  bool _isLoading = false;
  int _userId = 0;

  double _minDp = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.selectedTable != null) {
      final freshTable = widget.tables.firstWhere(
          (t) => t['id'].toString() == widget.selectedTable!['id'].toString(),
          orElse: () => widget.selectedTable!);
      _selectTable(freshTable);
    }
  }

  void _selectTable(Map<String, dynamic> table) {
    setState(() {
      _selectedTable = table;
      _minDp = double.tryParse(table['min_dp'].toString()) ?? 50000;
      _dpController.text = _formatNumber(_minDp);
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getInt('userId') ?? 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _dpController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            onPrimary: Colors.black,
            surface: Color(0xFF2A2A2A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            onPrimary: Colors.black,
            surface: Color(0xFF2A2A2A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Pilih meja terlebih dahulu!"),
          backgroundColor: Colors.red));
      return;
    }

    String cleanDp = _dpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double dpAmount = double.tryParse(cleanDp) ?? 0;

    if (dpAmount < _minDp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("DP Kurang! Minimum: Rp ${_formatNumber(_minDp)}"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    setState(() => _isLoading = true);

    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00";

    try {
      final res = await ApiService.post('booking.php?action=create_booking', {
        'table_id': _selectedTable!['id'],
        'customer_name': _nameController.text,
        'customer_phone': _phoneController.text,
        'date': dateStr,
        'time': timeStr,
        'guest_count': _guestCount,
        'down_payment': dpAmount,
        'notes': _notesController.text,
        'user_id': _userId
      });

      if (res['success'] == true) {
        if (mounted) {
          _showSuccessDialog(res['data'] ?? {}, dpAmount);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res['message'] ?? "Gagal booking"),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> bookingData, double dpAmount) {
    String code = bookingData['booking_code'] ?? 'N/A';
    String tableNumber = bookingData['table_number'] ?? _selectedTable?['table_number'] ?? '';
    String customerName = bookingData['customer_name'] ?? _nameController.text;
    String bookingDate = bookingData['booking_date'] ?? DateFormat('yyyy-MM-dd').format(_selectedDate);
    String bookingTime = bookingData['booking_time'] ?? "${_selectedTime.hour.toString().padLeft(2,'0')}:${_selectedTime.minute.toString().padLeft(2,'0')}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Booking Berhasil!', style: TextStyle(color: Color(0xFFD4AF37)))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Column(
                  children: [
                    const Text("Kode Booking", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(code, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Booking Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, customerName),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.table_restaurant, "Meja $tableNumber"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, bookingDate),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time, bookingTime),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("DP DITERIMA", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("Rp ${_formatNumber(dpAmount)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: const [
                    Icon(Icons.timer, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tamu harus check-in dalam 10 MENIT dari waktu booking, atau meja otomatis dikosongkan.",
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.point_of_sale, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
                  },
                  label: const Text('LIHAT DI KASIR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('SELESAI', style: TextStyle(color: Colors.white54)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }

  String _formatNumber(double num) {
    return NumberFormat("#,###", "id_ID").format(num);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(title: const Text("Reservasi & DP"), backgroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("DP adalah UANG MUKA. Tamu harus check-in dalam 10 menit dari waktu booking.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              _buildHeader("Data Pelanggan", Icons.person),
              _buildTextField(_nameController, "Nama Pemesan"),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, "WhatsApp / HP", inputType: TextInputType.phone),
              const SizedBox(height: 24),

              _buildHeader("Waktu & Meja", Icons.event),
              Row(
                children: [
                  Expanded(child: _buildPicker("Tanggal", DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate), Icons.calendar_today, _selectDate)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPicker("Jam", _selectedTime.format(context), Icons.access_time, _selectTime)),
                ],
              ),
              const SizedBox(height: 16),

              // Guest Count
              Row(
                children: [
                  const Text("Jumlah Tamu:", style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      if (_guestCount > 1) setState(() => _guestCount--);
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
                    child: Text("$_guestCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _guestCount++),
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown Meja
              DropdownButtonFormField<int>(
                value: _selectedTable != null ? int.tryParse(_selectedTable!['id'].toString()) : null,
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Pilih Meja",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.chair, color: Colors.white54),
                ),
                items: widget.tables.map((t) {
                  double tableMinDp = double.tryParse(t['min_dp'].toString()) ?? 0;
                  return DropdownMenuItem<int>(
                    value: int.parse(t['id'].toString()),
                    child: Text("${t['table_number']} (${t['capacity']} Pax) - Min DP: Rp ${_formatNumber(tableMinDp)}"),
                  );
                }).toList(),
                onChanged: (val) {
                  final t = widget.tables.firstWhere((tbl) => int.parse(tbl['id'].toString()) == val);
                  _selectTable(t);
                },
                validator: (val) => val == null ? "Wajib pilih meja" : null,
              ),
              const SizedBox(height: 24),

              // 3. PEMBAYARAN DP
              _buildHeader("Down Payment (DP)", Icons.monetization_on),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                          child: const Text("UANG MUKA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Text("Min: Rp ${_formatNumber(_minDp)}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 24),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        prefixText: "Rp ",
                        labelText: "Nominal DP Diterima",
                        labelStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Wajib diisi";
                        double amount = double.tryParse(val) ?? 0;
                        if (amount < _minDp) return "Minimum Rp ${_formatNumber(_minDp)}";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "DP TIDAK DAPAT DIKEMBALIKAN jika booking dibatalkan!",
                              style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(_notesController, "Catatan (Opsional)", inputType: TextInputType.multiline),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitBooking,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("PROSES BOOKING & TERIMA DP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: inputType == TextInputType.multiline ? 3 : 1,
      style: const TextStyle(color: Colors.white),
      validator: label.contains("Opsional") ? null : (val) => val!.isEmpty ? "Wajib diisi" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }

  Widget _buildPicker(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}