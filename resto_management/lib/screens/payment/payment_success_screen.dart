import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../staff/staff_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentSuccessScreen extends StatefulWidget {
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
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isPrinting = false;
  bool _isSendingWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    Widget nextScreen;
    switch (role) {
      case 'admin':
        nextScreen = const AdminDashboard();
        break;
      default:
        nextScreen = const StaffDashboard();
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => nextScreen),
        (route) => false,
      );
    }
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      // Simulasi proses cetak (2 detik)
      // Di implementasi nyata, panggil service printer di sini
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Tampilkan receipt preview
      await _showReceiptPreview();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Struk berhasil dicetak!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _showReceiptPreview() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preview Struk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Receipt Content
              SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildReceiptContent(),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)
                  ),
                ),
                child: Text(
                  'Struk ini sudah dikirim ke printer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    final items = widget.order['items'] as List;
    // FIX: Menggunakan data akurat dari order, bukan asumsi.
    final total = double.tryParse(widget.order['total_amount'].toString()) ?? 0.0;
    final subtotal = double.tryParse(widget.order['subtotal'].toString()) ?? 0.0;
    final tax = double.tryParse(widget.order['tax'].toString()) ?? 0.0;
    final service = double.tryParse(widget.order['service_charge'].toString()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo/Brand
        const Text(
          'RESTO PRO',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Terimakasih telah berberbelanja di Resto Pro',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const Divider(height: 24, thickness: 2),

        // Order Info
        _buildReceiptRow('No. Order', '#${widget.order['order_number']}', bold: true),
        _buildReceiptRow('Meja', widget.order['table_number'].toString()),
        _buildReceiptRow('Customer', widget.order['customer_name'] ?? 'Guest'),
        _buildReceiptRow('Tanggal', _formatDate(DateTime.now())),
        _buildReceiptRow('Waktu', _formatTime(DateTime.now())),
        
        const Divider(height: 24),

        // Items
        ...items.map((item) {
          final qty = int.parse(item['quantity'].toString());
          final price = double.parse(item['price'].toString());
          final lineTotal = qty * price;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${qty}x', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['name'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  formatCurrency(lineTotal),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),

        const Divider(height: 24),

        // Financial Summary
        _buildReceiptRow('Subtotal', formatCurrency(subtotal),),
        _buildReceiptRow('Service', formatCurrency(service)),
        _buildReceiptRow('Pajak (PB1)', formatCurrency(tax)),
        const Divider(height: 16),
        _buildReceiptRow(
          'TOTAL',
          formatCurrency(total),
          bold: true,
          large: true,
        ),

        const Divider(height: 24),

        // Payment Info
        _buildReceiptRow('Metode', getPaymentMethodName(widget.paymentMethod)),
        _buildReceiptRow('Status', 'LUNAS', bold: true),

        const SizedBox(height: 16),

        // Loyalty Points
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                '+${widget.pointsEarned} Loyalty Points',
                style: TextStyle(
                  color: Colors.amber[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Footer Message
        Text(
          'Terima kasih atas kunjungan Anda!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kami tunggu kedatangan Anda kembali',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 14 : 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 14 : 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp() async {
    setState(() => _isSendingWhatsApp = true);

    try {
      // Simulasi proses kirim WA (2 detik)
      // Di implementasi nyata, gunakan url_launcher untuk membuka WhatsApp
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Struk berhasil dikirim via WhatsApp!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingWhatsApp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Success Icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.green.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 3),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Animated Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        "Pembayaran Berhasil!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Transaksi telah dikonfirmasi",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Amount Display
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(0.2),
                          const Color(0xFFD4AF37).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total Pembayaran",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Rp ${formatCurrency(widget.order['total_amount'])}",
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Receipt Card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Order Details
                        _buildDetailRow(
                          Icons.receipt_long,
                          "No. Order",
                          "#${widget.order['order_number']}",
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.access_time,
                          "Waktu",
                          _formatTime(DateTime.now()),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.payment,
                          "Metode",
                          getPaymentMethodName(widget.paymentMethod),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.person_outline,
                          "Customer",
                          widget.order['customer_name'] ?? 'Guest',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.table_restaurant,
                          "Meja",
                          widget.order['table_number'].toString(),
                        ),
                        
                        const Divider(color: Colors.white24, height: 32),
                        
                        // Loyalty Points
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37).withOpacity(0.2),
                                const Color(0xFFD4AF37).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Loyalty Points Earned",
                                      style: TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "+${widget.pointsEarned} Poin",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFD4AF37),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              onPressed: _isPrinting ? null : _printReceipt,
                              icon: _isPrinting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.print, size: 20),
                              label: _isPrinting ? "Mencetak..." : "Cetak Struk",
                              backgroundColor: Colors.transparent,
                              borderColor: Colors.white54,
                              textColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              onPressed: _isSendingWhatsApp ? null : _sendWhatsApp,
                              icon: _isSendingWhatsApp
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.green,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(FontAwesomeIcons.whatsapp, size: 20),
                              label: _isSendingWhatsApp ? "Mengirim..." : "Kirim WA",
                              backgroundColor: Colors.transparent,
                              borderColor: Colors.green,
                              textColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Main Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.home_rounded, size: 20),
                              SizedBox(width: 12),
                              Text(
                                "KEMBALI KE MENU UTAMA",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String formatCurrency(dynamic amount) {
    double val = double.tryParse(amount.toString()) ?? 0.0;
    return val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String getPaymentMethodName(String code) {
    switch (code) {
      case 'cash':
        return 'Tunai (Cash)';
      case 'qris':
        return 'QRIS Scan';
      case 'debit':
        return 'Debit Card';
      case 'credit':
        return 'Credit Card';
      case 'transfer':
        return 'Bank Transfer';
      default:
        return code.toUpperCase();
    }
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}
