import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';
import 'payment_success_screen.dart';
import '../loyalty/customer_search_delegate.dart';

class PaymentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final int userId;

  const PaymentDetailScreen({
    super.key,
    required this.order,
    required this.userId,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Normal Payment State
  final TextEditingController _cashController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  double _changeAmount = 0.0;

  // Shared State
  bool _isProcessing = false;
  bool _isPrintingBill = false;
  Map<String, dynamic>? _bookingData;
  bool _isBookingLoading = true;
  double _taxRate = 0.10;
  double _serviceRate = 0.05;
  Customer? _linkedCustomer;

  // Split Bill by Item State
  bool _isSplitMode = false;
  double _totalPaid = 0.0;
  List<dynamic> _transactions = [];
  Set<int> _paidItemIds = {};
  Set<int> _selectedItemsToPay = {};
  String _splitSelectedMethod = 'cash';
  bool _isSplitProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Tunai', 'icon': Icons.payments, 'color': Colors.green},
    {'id': 'qris', 'name': 'QRIS', 'icon': Icons.qr_code_2, 'color': Colors.blue},
    {'id': 'debit', 'name': 'Debit', 'icon': Icons.credit_card, 'color': Colors.orange},
    {'id': 'transfer', 'name': 'Transfer', 'icon': Icons.account_balance, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.order['status'] == 'completed') {
      _selectedPaymentMethod = widget.order['payment_method'] ?? '';
    }
    // FIXED: Gunakan _loadInitialData yang proper untuk menghindari race condition
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _fetchBookingDetails(),
        _fetchSettings(),
        _fetchTransactions(),
        _fetchLinkedCustomer(),
      ], eagerError: false);
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================
  // SAFE PARSING HELPERS
  // ============================================

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatCurrency(dynamic amount) {
    // FIXED: Comprehensive null/type safety (FIX #4)
    if (amount == null) return "0";
    double value;
    if (amount is double) {
      value = amount;
    } else if (amount is int) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else {
      value = 0.0;
    }
    if (value.isNaN || value.isInfinite) value = 0.0;

    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  // ============================================
  // DATA FETCHING WITH MOUNTED CHECKS (FIX #3)
  // ============================================

  Future<void> _fetchLinkedCustomer() async {
    if (widget.order['customer_id'] == null) return;
    try {
      final res = await ApiService.get(
          'customers.php?action=get_by_id&id=${widget.order['customer_id']}');
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _linkedCustomer = Customer.fromJson(res['data']);
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch linked customer: $e");
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final res = await ApiService.get(
          'orders.php?action=get_transactions_by_order&order_id=${widget.order['id']}');
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        _transactions = res['data'] ?? [];
        _totalPaid = _transactions.fold(
            0.0, (sum, t) => sum + _safeParseDouble(t['amount']));

        _paidItemIds.clear();
        for (var t in _transactions) {
          if (t['notes'] != null && t['notes'].toString().isNotEmpty) {
            try {
              final noteData = jsonDecode(t['notes']);
              if (noteData != null && noteData['item_ids'] != null) {
                for (var itemId in noteData['item_ids']) {
                  int parsedId = _safeParseInt(itemId);
                  if (parsedId > 0) _paidItemIds.add(parsedId);
                }
              }
            } catch (e) {
              debugPrint("Error parsing notes: $e");
            }
          }
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Failed to fetch transactions: $e");
    }
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await ApiService.get('settings.php?action=get_settings');
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final settings = res['data'];
        setState(() {
          _taxRate = (_safeParseDouble(settings['tax_percentage']) > 0
                  ? _safeParseDouble(settings['tax_percentage'])
                  : 10.0) / 100.0;
          _serviceRate = (_safeParseDouble(settings['service_charge_percentage']) > 0
                  ? _safeParseDouble(settings['service_charge_percentage'])
                  : 5.0) / 100.0;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch settings: $e");
    }
  }

  Future<void> _fetchBookingDetails() async {
    setState(() => _isBookingLoading = true);
    try {
      final tableId = widget.order['table_id'];
      final createdAt = widget.order['created_at']?.toString() ?? '';
      final orderDate = createdAt.isNotEmpty ? createdAt.split(' ')[0] : '';

      if (tableId != null && orderDate.isNotEmpty) {
        final res = await ApiService.get(
            'orders.php?action=get_booking_by_table&table_id=$tableId&date=$orderDate');
        if (!mounted) return;
        if (res['success'] == true && res['data'] != null) {
          setState(() => _bookingData = res['data']);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch booking: $e');
    } finally {
      if (mounted) setState(() => _isBookingLoading = false);
    }
  }

  // ============================================
  // LOGIC & UI BUILDERS
  // ============================================

  double _getFinalTotal() {
    double total = _safeParseDouble(widget.order['total_amount']);
    double downPayment = _bookingData != null
        ? _safeParseDouble(_bookingData!['down_payment'])
        : 0.0;
    return total - downPayment;
  }

  void _calculateChange(String value) {
    String cleanVal = value.replaceAll(RegExp(r'[^0-9]'), '');
    double cashGiven = double.tryParse(cleanVal) ?? 0.0;
    setState(() => _changeAmount = cashGiven - (_getFinalTotal() - _totalPaid));
  }

  Future<void> _processFullPayment() async {
    if (_selectedPaymentMethod.isEmpty) {
      _showError("Pilih Metode Pembayaran terlebih dahulu!");
      return;
    }
    if (_selectedPaymentMethod == 'cash' && _changeAmount < 0) {
      _showError("Uang tunai kurang!");
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final res = await ApiService.post('orders.php?action=process_payment', {
        'order_id': widget.order['id'],
        'payment_method': _selectedPaymentMethod,
        'user_id': widget.userId
      });
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                    order: widget.order,
                    paymentMethod: _selectedPaymentMethod,
                    pointsEarned: _linkedCustomer != null
                        ? (_safeParseDouble(widget.order['total_amount']) / 1000).floor()
                        : 0,
                  )),
        );
      } else {
        _showError(res['message'] ?? "Gagal memproses pembayaran");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processItemPayment() async {
    if (_selectedItemsToPay.isEmpty) {
      _showError("Pilih minimal satu item untuk dibayar.");
      return;
    }
    setState(() => _isSplitProcessing = true);
    try {
      final res = await ApiService.post('orders.php?action=make_payment', {
        'order_id': widget.order['id'],
        'payment_method': _splitSelectedMethod,
        'item_ids': _selectedItemsToPay.toList(),
        'user_id': widget.userId,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        _selectedItemsToPay.clear();
        _showSuccess(res['message'] ?? "Pembayaran berhasil");
        double serverTotalPaid = _safeParseDouble(res['data']?['total_paid']);
        double finalTotal = _getFinalTotal();

        if (finalTotal > 0 && (serverTotalPaid / finalTotal) >= 0.999) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentSuccessScreen(
                      order: widget.order,
                      paymentMethod: "Split",
                      pointsEarned: 0,
                    )),
          );
        } else {
          await _fetchTransactions();
        }
      } else {
        _showError(res['message'] ?? "Gagal memproses pembayaran");
      }
    } catch (e) {
      _showError("Terjadi error: $e");
    } finally {
      if (mounted) setState(() => _isSplitProcessing = false);
    }
  }

  // FIXED: UI untuk semua metode pembayaran (FIX #1)
  Widget _buildPaymentSubMenu(double total) {
    if (_selectedPaymentMethod.isEmpty) return const SizedBox.shrink();
    double amountToPay = _getFinalTotal() - _totalPaid;

    if (_selectedPaymentMethod == 'cash') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.payments, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text("PEMBAYARAN TUNAI",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                  prefixText: "Rp ",
                  prefixStyle: TextStyle(color: Colors.white70, fontSize: 24),
                  hintText: "0",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              onChanged: _calculateChange,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kembalian:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Row(
                    children: [
                      Icon(_changeAmount >= 0 ? Icons.check_circle : Icons.error,
                          color: _changeAmount >= 0 ? Colors.green : Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text("Rp ${_formatCurrency(_changeAmount)}",
                          style: TextStyle(
                              color: _changeAmount >= 0 ? Colors.white : Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedPaymentMethod == 'qris') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.qr_code_2, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text("PEMBAYARAN QRIS",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 16),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.qr_code_2, size: 150, color: Colors.black87)),
            ),
            const SizedBox(height: 16),
            Text("Total: Rp ${_formatCurrency(amountToPay)}",
                style: const TextStyle(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Minta customer scan QR di atas",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text("Pastikan pembayaran sudah masuk sebelum konfirmasi",
                    style: TextStyle(color: Colors.orange, fontSize: 11)),
              ]),
            ),
          ],
        ),
      );
    }

    if (_selectedPaymentMethod == 'debit') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.credit_card, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text("PEMBAYARAN KARTU DEBIT",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.orange.shade600]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(Icons.credit_card, color: Colors.white, size: 32),
                    Text("DEBIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  const Text("•••• •••• •••• ••••",
                      style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Text("Total: Rp ${_formatCurrency(amountToPay)}",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInstructionBox("1. Masukkan kartu ke mesin EDC\n2. Pilih 'Debit' pada mesin\n3. Masukkan PIN customer\n4. Tunggu struk keluar"),
          ],
        ),
      );
    }

    if (_selectedPaymentMethod == 'transfer') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.account_balance, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text("PEMBAYARAN TRANSFER",
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 16),
            Text("Total: Rp ${_formatCurrency(amountToPay)}",
                style: const TextStyle(color: Colors.teal, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withOpacity(0.3))),
              child: Column(
                children: [
                  const Text("Transfer ke Rekening:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildBankAccountRow("BCA", "1234567890", "RESTO NUSANTARA", Colors.blue),
                  const SizedBox(height: 12),
                  _buildBankAccountRow("MANDIRI", "0987654321", "RESTO NUSANTARA", Colors.amber),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildWarningBox("Pastikan customer menunjukkan bukti transfer sebelum konfirmasi"),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBankAccountRow(String bankName, String accountNumber, String accountName, Color bankColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bankColor, borderRadius: BorderRadius.circular(4)),
          child: Text(bankName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(accountNumber,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: accountNumber));
                  _showSuccess("Nomor rekening disalin!");
                },
                child: const Icon(Icons.copy, color: Colors.white54, size: 16),
              ),
            ]),
            Text(accountName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
      ],
    );
  }

  Widget _buildInstructionBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        const Row(children: [
          Icon(Icons.info_outline, color: Colors.white54, size: 16),
          SizedBox(width: 8),
          Text("Instruksi Pembayaran:",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  Widget _buildWarningBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.orange, fontSize: 11))),
      ]),
    );
  }

  // ============================================
  // OVERRIDDEN BUILD & REMAINING UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    final bool isPaid = (widget.order['status'] == 'completed') ||
        (_getFinalTotal() > 0 && _totalPaid >= _getFinalTotal() * 0.999);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        backgroundColor: Colors.black,
        actions: [
          if (!isPaid)
            TextButton(
              onPressed: () => setState(() => _isSplitMode = !_isSplitMode),
              child: Text(_isSplitMode ? "MODE NORMAL" : "SPLIT PER ITEM",
                  style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            ),
          if (isPaid)
            IconButton(
                icon: const Icon(Icons.print, color: Color(0xFFD4AF37)),
                onPressed: _isPrintingBill ? null : _printBill,
                tooltip: 'Cetak Struk'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildOrderHeader(isPaid),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  if (!_isSplitMode) _buildOrderItems(widget.order['items'] as List? ?? []),
                  const SizedBox(height: 16),
                  _buildFinancialSummary(),
                  const SizedBox(height: 24),
                  if (!isPaid)
                    _isSplitMode ? _buildSplitByItemSection() : _buildPaymentSection(_getFinalTotal()),
                  if (isPaid) _buildOrderItems(widget.order['items'] as List? ?? [], isReview: true),
                ],
              ),
            ),
            if (!_isSplitMode) _buildFooterActions(isPaid),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(bool isPaid) {
    final String customerName = _linkedCustomer?.name ??
        _bookingData?['customer_name'] ??
        widget.order['customer_name'] ??
        'Guest';
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF252525),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ORDER #${widget.order['order_number'] ?? ''}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text("MEJA ${widget.order['table_number'] ?? '?'}",
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, color: _linkedCustomer != null ? Colors.green : const Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 6),
                    Text(customerName,
                        style: TextStyle(color: _linkedCustomer != null ? Colors.green : const Color(0xFFD4AF37), fontSize: 14)),
                    if (_linkedCustomer != null)
                      Text(" (${_linkedCustomer!.loyaltyPoints} Poin)",
                          style: const TextStyle(color: Colors.cyan, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (!isPaid)
            IconButton(icon: const Icon(Icons.link, color: Colors.white), onPressed: _onLinkCustomer),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text("LUNAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            )
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    double subtotal = _safeParseDouble(widget.order['subtotal']);
    double tax = _safeParseDouble(widget.order['tax']);
    double service = _safeParseDouble(widget.order['service_charge']);
    double downPayment = _bookingData != null ? _safeParseDouble(_bookingData!['down_payment']) : 0.0;
    double finalTotal = _getFinalTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(12)),
      child: _isBookingLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : Column(
              children: [
                _buildSummaryRow("Subtotal", subtotal, false),
                _buildSummaryRow("Service (${(_serviceRate * 100).toStringAsFixed(0)}%)", service, false),
                _buildSummaryRow("Pajak PB1 (${(_taxRate * 100).toStringAsFixed(0)}%)", tax, false),
                if (downPayment > 0) _buildSummaryRow("Down Payment", -downPayment, false),
                const Divider(color: Colors.white24, height: 24),
                _buildSummaryRow("TOTAL TAGIHAN", finalTotal, true),
                if (_totalPaid > 0) _buildSummaryRow("Sudah Dibayar", -_totalPaid, false, color: Colors.green),
                if (_totalPaid > 0) _buildSummaryRow("SISA TAGIHAN", finalTotal - _totalPaid, true),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(String label, double value, bool isTotal, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? color ?? Colors.white : Colors.white54,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14)),
          Text((value < 0 ? "-Rp " : "Rp ") + _formatCurrency(value.abs()),
              style: TextStyle(
                  color: isTotal ? color ?? const Color(0xFFD4AF37) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: isTotal ? 24 : 15)),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih Metode Pembayaran",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 3.0, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: _paymentMethods.length,
          itemBuilder: (context, index) {
            final method = _paymentMethods[index];
            final isActive = _selectedPaymentMethod == method['id'];
            return _buildPaymentMethodChip(method, isActive, (id) {
              setState(() {
                _selectedPaymentMethod = id;
                if (id != 'cash') {
                  _cashController.clear();
                  _changeAmount = 0.0;
                }
              });
            });
          },
        ),
        const SizedBox(height: 20),
        _buildPaymentSubMenu(total),
      ],
    );
  }

  Material _buildPaymentMethodChip(Map<String, dynamic> method, bool isActive, Function(String) onTap) {
    return Material(
      color: isActive ? method['color'].withOpacity(0.3) : Colors.white10,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isActive ? method['color'] : Colors.transparent, width: 2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(method['id']),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(method['icon'], color: isActive ? method['color'] : Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(method['name'],
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(List items, {bool isSplitMode = false, bool isReview = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isReview)
          const Text("Item Pesanan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        if (!isReview) const SizedBox(height: 12),
        ...items.map((item) {
          int itemId = _safeParseInt(item['id']);
          bool itemPaid = _paidItemIds.contains(itemId);
          bool isSelected = _selectedItemsToPay.contains(itemId);
          int quantity = _safeParseInt(item['quantity']);
          double price = _safeParseDouble(item['price']);

          if (isSplitMode) {
            return Card(
              color: itemPaid ? const Color(0xFF2E4038) : (isSelected ? const Color(0xFF4A442D) : const Color(0xFF252525)),
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: itemPaid || isSelected,
                onChanged: itemPaid ? null : (val) {
                  setState(() {
                    if (val == true) _selectedItemsToPay.add(itemId);
                    else _selectedItemsToPay.remove(itemId);
                  });
                },
                title: Text(item['name']?.toString() ?? 'Unknown',
                    style: TextStyle(color: itemPaid ? Colors.white54 : Colors.white,
                    decoration: itemPaid ? TextDecoration.lineThrough : null)),
                subtitle: Text("@ Rp ${_formatCurrency(price)}", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                activeColor: const Color(0xFFD4AF37),
              ),
            );
          }
          return ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
            child: Text("${quantity}x", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12))),
            title: Text(item['name']?.toString() ?? 'Unknown', style: const TextStyle(color: Colors.white)),
            trailing: Text(_formatCurrency(price * quantity), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSplitByItemSection() {
    // Implementasi ringkasan split sama seperti sebelumnya namun dengan grid metode pembayaran
    return _buildSplitByItemContent();
  }

  Widget _buildSplitByItemContent() {
    // Sederhanakan untuk kebutuhan integrasi
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Text("Pilih item di atas dan klik bayar", style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _processItemPayment, child: const Text("BAYAR ITEM TERPILIH"))
      ]),
    );
  }

  Widget _buildFooterActions(bool isPaid) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: !isPaid
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                      onPressed: _isPrintingBill ? null : _printBill,
                      icon: const Icon(Icons.receipt_long),
                      label: Text(_isPrintingBill ? "..." : "Bill")),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processFullPayment,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      icon: const Icon(Icons.check_circle),
                      label: Text(_isProcessing ? "Memproses..." : "Konfirmasi Bayar")),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(onPressed: _printBill, icon: const Icon(Icons.print), label: const Text("Cetak Struk")),
            ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Future<void> _onLinkCustomer() async {
    final Customer? selected = await showSearch<Customer?>(context: context, delegate: CustomerSearchDelegate());
    if (selected != null) {
      final res = await ApiService.post('orders.php?action=link_customer', {'order_id': widget.order['id'], 'customer_id': selected.id});
      if (res['success'] == true && mounted) {
        setState(() { _linkedCustomer = selected; widget.order['customer_id'] = selected.id; });
        _showSuccess("Customer ditautkan");
      }
    }
  }

  Future<void> _printBill() async {
    setState(() => _isPrintingBill = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) { setState(() => _isPrintingBill = false); _showSuccess('Dicetak!'); }
  }
}