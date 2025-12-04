import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Pastikan fl_chart ada di pubspec.yaml
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // State Data
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  
  // Data Laporan
  Map<String, dynamic> _reportData = {
    'summary': {'total': 0, 'count': 0},
    'by_method': [],
    'top_products': []
  };

  @override
  void initState() {
    super.initState();
    // Default: Bulan Ini
    DateTime now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0)
    );
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    
    String start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
    String end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);

    try {
      // Menggunakan Endpoint get_business_report yang sudah dibuat di orders.php
      final res = await ApiService.post('orders.php?action=get_business_report', {
        'start_date': start,
        'end_date': end
      });

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _reportData = res['data'];
          });
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Analytics Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Laporan Bisnis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Color(0xFFD4AF37)),
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Export PDF (Coming Soon)")));
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : RefreshIndicator(
              onRefresh: _loadReport,
              color: const Color(0xFFD4AF37),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER PERIODE
                    _buildPeriodHeader(),
                    const SizedBox(height: 24),

                    // 2. SUMMARY CARDS
                    _buildSummarySection(),
                    const SizedBox(height: 24),

                    // 3. PIE CHART (METODE PEMBAYARAN)
                    const Text("Metode Pembayaran", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPaymentMethodChart(),
                    const SizedBox(height: 24),

                    // 4. TOP PRODUK
                    const Text("Menu Terlaris", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildTopProductsList(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGETS ---

  Widget _buildPeriodHeader() {
    String start = DateFormat('d MMM yyyy', 'id_ID').format(_selectedDateRange!.start);
    String end = DateFormat('d MMM yyyy', 'id_ID').format(_selectedDateRange!.end);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text("Periode Laporan", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.date_range, color: Color(0xFFD4AF37), size: 18),
              const SizedBox(width: 8),
              Text("$start - $end", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    double total = double.tryParse(_reportData['summary']['total'].toString()) ?? 0;
    int count = int.tryParse(_reportData['summary']['count'].toString()) ?? 0;
    double avg = count > 0 ? total / count : 0;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard("Total Omset", "Rp ${_formatCompact(total)}", Icons.monetization_on, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard("Transaksi", "$count", Icons.receipt, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard("Rata-rata", "Rp ${_formatCompact(avg)}", Icons.pie_chart, Colors.orange),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChart() {
    List methods = _reportData['by_method'] as List;
    
    if (methods.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
        child: const Text("Belum ada data transaksi", style: TextStyle(color: Colors.white38)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Chart
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: methods.map((m) {
                  final double val = double.parse(m['total'].toString());
                  final String name = m['payment_method'];
                  return PieChartSectionData(
                    color: _getColorForMethod(name),
                    value: val,
                    title: '',
                    radius: 40,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: methods.map((m) {
                final double val = double.parse(m['total'].toString());
                final String name = m['payment_method'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForMethod(name), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(name.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(_formatCompact(val), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopProductsList() {
    List products = _reportData['top_products'] as List;

    if (products.isEmpty) {
      return const Center(child: Text("Data produk kosong", style: TextStyle(color: Colors.white38)));
    }

    // Cari max qty untuk progress bar
    double maxQty = 0;
    if (products.isNotEmpty) {
      maxQty = double.parse(products[0]['qty'].toString());
    }

    return Column(
      children: products.asMap().entries.map((entry) {
        int index = entry.key;
        var item = entry.value;
        double qty = double.parse(item['qty'].toString());
        double revenue = double.parse(item['revenue'].toString());
        double percent = maxQty > 0 ? qty / maxQty : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // Badge Ranking
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index == 0 ? const Color(0xFFD4AF37) : (index == 1 ? Colors.grey : (index == 2 ? Colors.brown : Colors.white10)),
                  shape: BoxShape.circle,
                ),
                child: Text("${index + 1}", style: TextStyle(color: index < 3 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("${qty.toInt()} Terjual", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Bar
                    Stack(
                      children: [
                        Container(height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(
                          widthFactor: percent,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == 0 ? const Color(0xFFD4AF37) : Colors.green,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("Rp ${_formatCurrency(revenue)}", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helpers
  Color _getColorForMethod(String method) {
    switch(method.toLowerCase()) {
      case 'cash': return Colors.green;
      case 'qris': return Colors.blue;
      case 'debit': return Colors.orange;
      case 'transfer': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) return "${(amount / 1000000).toStringAsFixed(1)}jt";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(0)}rb";
    return amount.toStringAsFixed(0);
  }
}