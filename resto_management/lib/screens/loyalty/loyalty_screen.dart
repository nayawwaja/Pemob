import 'package:flutter/material.dart';
// import '../../services/api_service.dart'; // Dihapus karena tidak dipakai di simulasi
import 'package:intl/intl.dart'; 
// import dart:async; // Tidak diperlukan karena kita pakai Future.delayed

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final TextEditingController _phoneController = TextEditingController();
  
  // Data State
  Map<String, dynamic>? _memberData;
  List<dynamic> _history = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage; 
  final GlobalKey<State> _keyLoader = GlobalKey<State>(); 

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchMember() async {
    if (_phoneController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _memberData = null;
      _history = [];
      _errorMessage = null; 
    });

    // --- SIMULASI RESPONSE API ---
    await Future.delayed(const Duration(seconds: 1)); // Simulasi network
    
    if (mounted) {
      if (_phoneController.text.contains('123') && _phoneController.text.length > 5) {
        // Simulasi Data Ditemukan
        setState(() {
          _memberData = {
            'name': 'Budi Santoso (Gold Tier)',
            'phone': _phoneController.text,
            'points': 450,
            'total_spent': 4500000.0,
            'visit_count': 22,
            'tier': 'Gold',
          };
          _history = [
            {'date': '2025-11-28', 'points': 50, 'type': 'earned', 'desc': 'Pembelian Order #ORD-882'},
            {'date': '2025-11-20', 'points': -100, 'type': 'redeemed', 'desc': 'Tukar Voucher Diskon 100K'},
            {'date': '2025-11-15', 'points': 200, 'type': 'earned', 'desc': 'Pembelian Order #ORD-791'},
          ];
          _isLoading = false;
        });
      } else {
        // Data tidak ditemukan
        setState(() {
          _errorMessage = "Nomor HP tidak terdaftar sebagai member.";
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIC: REDEEM POIN ---
  Future<void> _redeemPoints() async {
    final points = _memberData!['points'] as int;
    if (points < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Poin tidak cukup untuk redeem! (Min 100)"), backgroundColor: Colors.red));
      return;
    }
    
    // FIX: Menggunakan Dialogs.showLoadingDialog yang sudah dimodifikasi
    Dialogs.showLoadingDialog(context, _keyLoader, "Redeeming..."); 
    
    await Future.delayed(const Duration(seconds: 1)); 
    Navigator.of(_keyLoader.currentContext!).pop(); // Tutup dialog

    // Update lokal
    if(mounted) {
      setState(() {
        _memberData!['points'] -= 100;
        _history.insert(0, {'date': DateFormat('yyyy-MM-dd').format(DateTime.now()), 'points': -100, 'type': 'redeemed', 'desc': 'Diskon 100K (Redeem)'});
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Poin berhasil ditukar menjadi Diskon!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Loyalty Points'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Search Bar
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Nomor HP Customer',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.phone, color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                        : const Icon(Icons.search, color: Color(0xFFD4AF37)),
                      onPressed: _searchMember,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Result Area
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                  : _memberData != null 
                    ? _buildMemberInfo()
                    : _buildInitialState(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildInitialState() {
    if (_hasSearched && _memberData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 80, color: Colors.white10),
            const SizedBox(height: 16),
            Text(_errorMessage ?? "Member tidak ditemukan.", style: const TextStyle(color: Colors.redAccent, fontSize: 16)), 
          ],
        ),
      );
    }
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.card_membership, size: 80, color: Colors.white10),
            SizedBox(height: 16),
            Text("Cari member untuk melihat poin", style: TextStyle(color: Colors.white30)),
          ],
        ),
      );
  }

  Widget _buildMemberInfo() {
    final points = _memberData!['points'] as int;
    final spent = _memberData!['total_spent'] as double;
    final visits = _memberData!['visit_count'] as int;
    final tier = _memberData!['tier'] as String;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Card Member
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFD4AF37).withOpacity(0.8), const Color(0xFF8B7500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Loyalty Card", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(tier, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(_memberData!['name'], style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(_memberData!['phone'], style: const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 20),
                const Text("Total Poin", style: TextStyle(color: Colors.black54, fontSize: 12)),
                Text("$points Pts", style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats & Actions
          Row(
            children: [
              Expanded(child: _buildStatBox("Total Spent", "Rp ${NumberFormat('#,##0', 'id_ID').format(spent)}", Icons.attach_money)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox("Total Kunjungan", "${visits}x", Icons.calendar_month)),
            ],
          ),
          const SizedBox(height: 24),

          // Redeem Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: points >= 100 ? _redeemPoints : null,
              icon: const Icon(Icons.card_giftcard),
              label: Text(points >= 100 ? "TUKAR 100 POIN (Diskon)" : "Poin Kurang (Min 100 Pts)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: points >= 100 ? Colors.pink : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // History List
          const Align(alignment: Alignment.centerLeft, child: Text("Riwayat Poin", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          ... _history.map((item) => Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                item['points'] > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: item['points'] > 0 ? Colors.green : Colors.red,
              ),
              title: Text(item['desc'], style: const TextStyle(color: Colors.white)),
              subtitle: Text(item['date'], style: const TextStyle(color: Colors.white54)),
              trailing: Text(
                "${item['points'] > 0 ? '+' : ''}${item['points']} Pts",
                style: TextStyle(color: item['points'] > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

// FIX: Pindahkan helper Dialogs ke luar class utama (seperti di bawah)
// Anda harus memastikan kode ini ditempatkan setelah penutup class _LoyaltyScreenState
class Dialogs {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: SimpleDialog(
            key: key,
            backgroundColor: const Color(0xFF2A2A2A),
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white70),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}