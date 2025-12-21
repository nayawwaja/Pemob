import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tables;
  final Map<String, dynamic>? selectedTable; // Opsional (jika dari denah)

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

  // Helper: Min DP Table
  double _minDp = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Jika ada meja yang dipilih dari screen sebelumnya
    if (widget.selectedTable != null) {
      // Cari data meja yang fresh dari list tables agar data min_dp akurat
      final freshTable = widget.tables.firstWhere(
          (t) => t['id'].toString() == widget.selectedTable!['id'].toString(),
          orElse: () => widget.selectedTable!);
      _selectTable(freshTable);
    }
  }

  void _selectTable(Map<String, dynamic> table) {
    setState(() {
      _selectedTable = table;
      // Ambil min_dp dari data tabel, default 50rb jika null atau error parse
      _minDp = double.tryParse(table['min_dp'].toString()) ?? 50000;

      // Auto isi controller dengan min DP (UX Improvement)
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

  // --- DATE & TIME PICKER ---
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

  // --- SUBMIT LOGIC ---
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Pilih meja terlebih dahulu!"),
          backgroundColor: Colors.red));
      return;
    }

    // Validasi DP
    String cleanDp = _dpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double dpAmount = double.tryParse(cleanDp) ?? 0;

    // Cek apakah DP kurang dari minimum
    if (dpAmount < _minDp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "DP Kurang! Minimum untuk meja ini: Rp ${_formatNumber(_minDp)}"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    setState(() => _isLoading = true);

    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String timeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00";

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
        if (mounted) _showSuccessDialog(res['data']['booking_code']);
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res['message'] ?? "Gagal booking"),
              backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Booking Dibuat',
            style: TextStyle(color: Color(0xFFD4AF37))),
        content: const Text(
          'Reservasi berhasil dibuat. Status: DP Diterima (Belum Lunas). Silakan selesaikan sisa pembayaran saat tamu check-out.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () {
              Navigator.pop(ctx); // Tutup Dialog
              Navigator.pop(context); // Kembali ke BookingScreen
            },
            child: const Text('OK, Mengerti',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  String _formatNumber(double num) {
    return NumberFormat("#,###", "id_ID").format(num);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
          title: const Text("Reservasi & DP"),
          backgroundColor: Colors.black,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DATA PELANGGAN
              _buildHeader("Data Pelanggan", Icons.person),
              _buildTextField(_nameController, "Nama Pemesan"),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, "WhatsApp / HP",
                  inputType: TextInputType.phone),
              const SizedBox(height: 24),

              // 2. WAKTU & MEJA
              _buildHeader("Waktu & Meja", Icons.event),
              Row(
                children: [
                  Expanded(
                      child: _buildPicker(
                          "Tanggal",
                          DateFormat('dd MMM yyyy', 'id_ID')
                              .format(_selectedDate),
                          Icons.calendar_today,
                          _selectDate)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildPicker("Jam", _selectedTime.format(context),
                          Icons.access_time, _selectTime)),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown Meja
              DropdownButtonFormField<int>(
                value: _selectedTable?['id'],
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Pilih Meja",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.chair, color: Colors.white54),
                ),
                items: widget.tables.map((t) {
                  return DropdownMenuItem<int>(
                    value: int.parse(t['id'].toString()),
                    child: Text("${t['table_number']} (${t['capacity']} Pax)"),
                  );
                }).toList(),
                onChanged: (val) {
                  final t = widget.tables.firstWhere(
                      (tbl) => int.parse(tbl['id'].toString()) == val);
                  _selectTable(t);
                },
                validator: (val) => val == null ? "Wajib pilih meja" : null,
              ),

              const SizedBox(height: 24),

              // 3. PEMBAYARAN DP
              _buildHeader("Pembayaran (DP)", Icons.monetization_on),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        Text("Minimum DP: Rp ${_formatNumber(_minDp)}",
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                      decoration: const InputDecoration(
                        prefixText: "Rp ",
                        labelText: "Nominal DP Diterima",
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "⚠️ Note: DP akan langsung dicatat sebagai pemasukan (Transaksi). Jika booking batal, uang TIDAK dikembalikan (Hangus).",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. BUTTON SUBMIT
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _submitBooking,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("PROSES BOOKING & DP",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFD4AF37))),
      ),
    );
  }

  Widget _buildPicker(
      String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12))
            ]),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
