import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TextEditingController _codeController = TextEditingController();
  
  // State Data
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;
  String? _errorMessage;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getInt('userId') ?? 0);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- 1. VERIFIKASI KODE ---
  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _bookingData = null;
      _errorMessage = null;
    });

    // Panggil API verify_booking
    final res = await ApiService.get('booking.php?action=verify_booking&booking_code=${_codeController.text}');

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _bookingData = res['data'];
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? "Kode tidak ditemukan atau kadaluarsa.";
      });
    }
  }

  // --- 2. PROSES CHECK-IN ---
  Future<void> _processCheckIn() async {
    if (_bookingData == null) return;

    setState(() => _isLoading = true);

    final res = await ApiService.post('booking.php?action=check_in', {
      'booking_id': _bookingData!['id'],
      'user_id': _userId
    });

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        // Tampilkan Dialog Sukses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: Column(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 12),
                Text("Check-In Berhasil!", style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              "Tamu a.n ${_bookingData!['customer_name']} sudah check-in.\nMeja ${_bookingData!['table_number']} sekarang statusnya TERISI.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup Dialog
                  Navigator.pop(context, true); // Kembali ke BookingScreen (Refresh)
                },
                child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Verifikasi Tamu"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan Kode Booking",
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Input Kode
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.bold),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'CONTOH: RES-1234',
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 1),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.qr_code, color: Color(0xFFD4AF37)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.search, color: Colors.black),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ERROR MESSAGE
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),

            // BOOKING DETAIL CARD (Muncul jika valid)
            if (_bookingData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Detail Reservasi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Kode", _bookingData!['booking_code'], isBold: true),
                        const Divider(color: Colors.white24),
                        _buildDetailRow("Nama Tamu", _bookingData!['customer_name']),
                        _buildDetailRow("Nomor HP", _bookingData!['customer_phone']),
                        _buildDetailRow("Meja", "No. ${_bookingData!['table_number']}"),
                        _buildDetailRow("Jumlah", "${_bookingData!['guest_count']} Orang"),
                        _buildDetailRow("Jam", _bookingData!['booking_time'].toString().substring(0, 5)),
                        _buildDetailRow("Status", _bookingData!['status'].toString().toUpperCase(), color: Colors.green),
                        
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _processCheckIn,
                            icon: const Icon(Icons.check_circle),
                            label: const Text("KONFIRMASI KEDATANGAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}