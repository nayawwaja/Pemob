// ============================================
// ANALYTICS SCREEN - FIXED VERSION
// ============================================
// File: lib/screens/analytics/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  String? _errorMessage;
  DateTimeRange? _selectedDateRange;
  
  // Data Laporan
  Map<String, dynamic> _reportData = {
    'summary': {'total': 0.0, 'count': 0},
    'by_method': [],
    'top_products': []
  };

  @override
  void initState() {
    super.initState();
    // FIXED: Safe date range initialization
    _initializeDateRange();
    _loadReport();
  }

  // FIXED: Separate method for date initialization
  void _initializeDateRange() {
    DateTime now = DateTime.now();
    
    // FIXED: Safe calculation for end of month
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth;
    
    // Handle December (month 12) correctly
    if (now.month == 12) {
      endOfMonth = DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1));
    } else {
      endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    }
    
    _selectedDateRange = DateTimeRange(
      start: startOfMonth,
      end: endOfMonth,
    );
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    if (_selectedDateRange == null) {
      _initializeDateRange();
    }
    
    // FIXED: Use simple date format without locale for API
    String start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
    String end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);

    try {
      final res = await ApiService.post('orders.php?action=get_business_report', {
        'start_date': start,
        'end_date': end
      });

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        
        setState(() {
          _reportData = {
            // FIXED: Safe parsing with null checks
            'summary': {
              'total': _safeParseDouble(data['summary']?['total']),
              'count': _safeParseInt(data['summary']?['count']),
            },
            'by_method': data['by_method'] ?? [],
            'top_products': data['top_products'] ?? []
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Analytics Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  // FIXED: Safe parsing helpers
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodHeader(),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 24),
            const Text("Metode Pembayaran", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentMethodChart(),
            const SizedBox(height: 24),
            const Text("Menu Terlaris", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTopProductsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodHeader() {
    if (_selectedDateRange == null) return const SizedBox.shrink();
    
    // FIXED: Use simple format without locale that might not be initialized
    String start = _formatDateSimple(_selectedDateRange!.start);
    String end = _formatDateSimple(_selectedDateRange!.end);

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
              Text("$start - $end", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: Simple date format without locale dependency
  String _formatDateSimple(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Widget _buildSummarySection() {
    double total = _safeParseDouble(_reportData['summary']?['total']);
    int count = _safeParseInt(_reportData['summary']?['count']);
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
    List methods = (_reportData['by_method'] as List?) ?? [];
    
    if (methods.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text("Belum ada data transaksi", style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    // FIXED: Calculate total and validate data
    double chartTotal = 0;
    List<Map<String, dynamic>> validMethods = [];
    
    for (var m in methods) {
      double val = _safeParseDouble(m['total']);
      if (val > 0) {
        validMethods.add({
          'payment_method': m['payment_method']?.toString() ?? 'unknown',
          'total': val,
          'count': _safeParseInt(m['count']),
        });
        chartTotal += val;
      }
    }

    if (validMethods.isEmpty || chartTotal == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("Tidak ada data valid", style: TextStyle(color: Colors.white38)),
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
                sections: validMethods.map((m) {
                  final double val = m['total'];
                  final String name = m['payment_method'];
                  final double percentage = (val / chartTotal) * 100;
                  
                  return PieChartSectionData(
                    color: _getColorForMethod(name),
                    value: val,
                    title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
              children: validMethods.map((m) {
                final double val = m['total'];
                final String name = m['payment_method'];
                final int count = m['count'];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12, 
                        height: 12, 
                        decoration: BoxDecoration(
                          color: _getColorForMethod(name), 
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name.toUpperCase(), 
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatCompact(val), 
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Text("$count trx", 
                            style: const TextStyle(color: Colors.white38, fontSize: 9)),
                        ],
                      ),
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
    List products = (_reportData['top_products'] as List?) ?? [];

    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.white24, size: 48),
              SizedBox(height: 12),
              Text("Belum ada data produk", style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    // FIXED: Safe max qty calculation
    double maxQty = 0;
    for (var p in products) {
      double qty = _safeParseDouble(p['qty']);
      if (qty > maxQty) maxQty = qty;
    }

    return Column(
      children: products.asMap().entries.map((entry) {
        int index = entry.key;
        var item = entry.value;
        
        // FIXED: Safe parsing
        double qty = _safeParseDouble(item['qty']);
        double revenue = _safeParseDouble(item['revenue']);
        String name = item['name']?.toString() ?? 'Unknown';
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
                  color: _getRankColor(index),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${index + 1}", 
                  style: TextStyle(
                    color: index < 3 ? Colors.black : Colors.white, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text("${qty.toInt()} Terjual", 
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == 0 ? const Color(0xFFD4AF37) : Colors.green,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Rp ${_formatCurrency(revenue)}", 
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10),
                      ),
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
  Color _getRankColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFD4AF37); // Gold
      case 1: return Colors.grey.shade400; // Silver
      case 2: return Colors.brown.shade400; // Bronze
      default: return Colors.white10;
    }
  }

  Color _getColorForMethod(String method) {
    switch(method.toLowerCase()) {
      case 'cash': return Colors.green;
      case 'qris': return Colors.blue;
      case 'debit': return Colors.orange;
      case 'transfer': return Colors.purple;
      case 'split': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return "0";
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.',
    );
  }

  String _formatCompact(double amount) {
    if (amount.isNaN || amount.isInfinite) return "0";
    if (amount >= 1000000000) return "${(amount / 1000000000).toStringAsFixed(1)}M";
    if (amount >= 1000000) return "${(amount / 1000000).toStringAsFixed(1)}jt";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(0)}rb";
    return amount.toStringAsFixed(0);
  }
}