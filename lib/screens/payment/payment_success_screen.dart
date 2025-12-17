import 'package:flutter/material.dart';
import '../staff/staff_dashboard.dart'; // Untuk navigasi balik

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final String paymentMethod;
  final int pointsEarned;

  const PaymentSuccessScreen({
    super.key,
    required this.order,
    required this.paymentMethod,
    required this.pointsEarned,
  });

  @override
  Widget build(BuildContext context) {
    // Format mata uang manual
    String formatCurrency(dynamic amount) {
      double val = double.tryParse(amount.toString()) ?? 0.0;
      return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    String getPaymentMethodName(String code) {
      switch (code) {
        case 'cash': return 'Tunai (Cash)';
        case 'qris': return 'QRIS Scan';
        case 'debit': return 'Debit Card';
        case 'credit': return 'Credit Card';
        case 'transfer': return 'Bank Transfer';
        default: return code.toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Success Icon Animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 80, color: Colors.green),
                ),
                const SizedBox(height: 32),

                // 2. Title & Amount
                const Text("Pembayaran Berhasil!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  "Rp ${formatCurrency(order['total_amount'])}",
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // 3. Receipt Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("No. Order", "#${order['order_number']}"),
                      _buildDetailRow("Waktu", _formatTime(DateTime.now())),
                      _buildDetailRow("Metode", getPaymentMethodName(paymentMethod)),
                      _buildDetailRow("Customer", order['customer_name'] ?? 'Guest'),
                      const Divider(color: Colors.white24, height: 30),
                      // Loyalty Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Loyalty Points", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text("+$pointsEarned Poin Ditambahkan", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // 4. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Sedang mencetak struk..."), backgroundColor: Colors.blue)
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.print),
                        label: const Text("Cetak Struk"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mengirim struk via WhatsApp..."), backgroundColor: Colors.green)
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text("Kirim WA"),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Kembali ke Dashboard dan hapus semua stack history
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const StaffDashboard()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("KEMBALI KE MENU UTAMA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
} 