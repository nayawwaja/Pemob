import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import '../../services/api_service.dart';
import 'auth/login_screen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Status Data
  List<dynamic> _pendingOrders = [];
  List<dynamic> _cookingOrders = [];
  bool _isLoading = true;
  String _chefName = 'Koki';
  int _userId = 0;
  Timer? _refreshTimer;
  Timer? _durationTimer;

  // NEW: Clock In/Out System
  bool _isShiftStarted = false;
  String _currentTime = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startClock();
    _loadUserData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _durationTimer?.cancel();
    _clockTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // NEW: Start real-time clock
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _chefName = prefs.getString('name') ?? 'Koki';
      _isShiftStarted = prefs.getBool('isShiftStarted') ?? false;
    });
    
    // Check actual attendance status from server
    await _checkAttendanceStatus();
    
    // Only fetch orders if shift started
    if (_isShiftStarted) {
      _fetchOrders();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (t) => _fetchOrders(silent: true));
      _durationTimer = Timer.periodic(const Duration(minutes: 1), (t) {
        if(mounted) setState(() {}); 
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Check attendance status from server
  Future<void> _checkAttendanceStatus() async {
    try {
      final res = await ApiService.get('attendance.php?action=get_my_status&user_id=$_userId');
      if (mounted && res['success'] == true && res['data'] != null) {
        bool isClockedIn = res['data']['is_clocked_in'] ?? false;
        setState(() => _isShiftStarted = isClockedIn);
        
        // Sync to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isShiftStarted', isClockedIn);
      }
    } catch (e) {
      print("Error checking attendance status: $e");
    }
  }

  // NEW: Toggle Clock In/Out
  Future<void> _toggleShift() async {
    String action = _isShiftStarted ? 'clock_out' : 'clock_in';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Memproses Absensi..."), duration: Duration(milliseconds: 800))
    );

    final res = await ApiService.post('attendance.php?action=$action', {
      'user_id': _userId,
    });

    if (res['success'] == true) {
      setState(() => _isShiftStarted = !_isShiftStarted);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isShiftStarted', _isShiftStarted);

      if (mounted) {
        _showAttendanceDialog(_isShiftStarted);
        
        // Start/Stop timers based on shift status
        if (_isShiftStarted) {
          _fetchOrders();
          _refreshTimer = Timer.periodic(const Duration(seconds: 10), (t) => _fetchOrders(silent: true));
          _durationTimer = Timer.periodic(const Duration(minutes: 1), (t) {
            if(mounted) setState(() {}); 
          });
        } else {
          _refreshTimer?.cancel();
          _durationTimer?.cancel();
          setState(() {
            _pendingOrders = [];
            _cookingOrders = [];
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Gagal Absen"), backgroundColor: Colors.red)
        );
      }
    }
  }

  // NEW: Show attendance dialog
  void _showAttendanceDialog(bool isClockIn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            Icon(isClockIn ? Icons.wb_sunny : Icons.nights_stay, color: const Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            Text(isClockIn ? "Selamat Bekerja!" : "Hati-hati di Jalan!", 
              style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          isClockIn 
            ? "Shift dimulai pada $_currentTime.\nDapur siap beroperasi!"
            : "Shift berakhir pada $_currentTime.\nDapur dikunci.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!_isShiftStarted) return; // Don't fetch if not clocked in
    
    if (!silent) setState(() => _isLoading = true);
    
    try {
      final res = await ApiService.get('orders.php?action=get_orders_by_role&role=chef');
      
      if (mounted) {
        setState(() {
          if (res['success'] == true) {
            final allOrders = res['data'] as List;
            _pendingOrders = allOrders.where((o) => o['status'] == 'pending').toList();
            _cookingOrders = allOrders.where((o) => o['status'] == 'cooking').toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Kesalahan Dapur: $e");
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    setState(() {
      if (status == 'cooking') {
        final item = _pendingOrders.firstWhere((o) => o['id'] == orderId, orElse: () => null);
        if (item != null) {
          _pendingOrders.removeWhere((o) => o['id'] == orderId);
          _cookingOrders.add(item); 
        }
      } else if (status == 'ready') {
        _cookingOrders.removeWhere((o) => o['id'] == orderId);
      }
    });

    final res = await ApiService.post('orders.php?action=update_status', {
      'order_id': orderId,
      'status': status,
      'user_id': _userId
    });

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'cooking' ? "Mulai memasak..." : "Pesanan Selesai! Pelayan dipanggil."),
          backgroundColor: status == 'cooking' ? Colors.blue : Colors.green,
          duration: const Duration(seconds: 1),
        )
      );
      _fetchOrders(silent: true);
    } else {
      _fetchOrders();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui status"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _logout() async {
    if (_isShiftStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap CLOCK OUT sebelum logout!"), backgroundColor: Colors.orange)
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Logout Sistem', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin keluar aplikasi?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateNow = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(dateNow),
              ),
              actions: [
                if (_isShiftStarted)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)), 
                    onPressed: _fetchOrders
                  ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red), 
                  onPressed: _logout
                ),
              ],
              bottom: _isShiftStarted ? TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFD4AF37),
                labelColor: const Color(0xFFD4AF37),
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long),
                        const SizedBox(width: 8),
                        Text("Baru Masuk (${_pendingOrders.length})"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.soup_kitchen),
                        const SizedBox(width: 8),
                        Text("Sedang Dimasak (${_cookingOrders.length})"),
                      ],
                    ),
                  ),
                ],
              ) : null,
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }

  Widget _buildHeader(String dateNow) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  border: Border.all(
                    color: _isShiftStarted ? Colors.green : Colors.grey, 
                    width: 2
                  )
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFD4AF37),
                  child: const Icon(Icons.kitchen, size: 30, color: Colors.black),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Koki $_chefName", 
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(
                          width: 8, 
                          height: 8, 
                          decoration: BoxDecoration(
                            color: _isShiftStarted ? Colors.green : Colors.red, 
                            shape: BoxShape.circle
                          )
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isShiftStarted ? "Status: ON DUTY" : "Status: OFF DUTY", 
                          style: TextStyle(
                            color: _isShiftStarted ? Colors.green : Colors.red, 
                            fontSize: 12
                          )
                        ),
                      ],
                    )
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isShiftStarted ? Colors.red.withOpacity(0.2) : Colors.green,
                  foregroundColor: _isShiftStarted ? Colors.red : Colors.white,
                  side: BorderSide(color: _isShiftStarted ? Colors.red : Colors.green),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _toggleShift,
                icon: Icon(_isShiftStarted ? Icons.logout : Icons.login, size: 18),
                label: Text(
                  _isShiftStarted ? "CLOCK OUT" : "CLOCK IN", 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateNow, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(_currentTime, 
                  style: const TextStyle(
                    color: Color(0xFFD4AF37), 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'monospace'
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_isShiftStarted) {
      return _buildLockedScreen();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrderList(_pendingOrders, 'pending'),
        _buildOrderList(_cookingOrders, 'cooking'),
      ],
    );
  }

  Widget _buildLockedScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_clock, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "DAPUR TERKUNCI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Silakan tekan tombol 'CLOCK IN' di atas\nuntuk memulai shift dan membuka akses dapur.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending' ? Icons.check_circle : Icons.fireplace, 
              size: 80, 
              color: Colors.white10
            ),
            const SizedBox(height: 16),
            Text(
              type == 'pending' ? "Tidak ada pesanan baru" : "Kompor sedang kosong",
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final items = order['items'] as List? ?? [];
        
        DateTime created;
        try {
          created = DateTime.parse(order['created_at']);
        } catch (e) {
          created = DateTime.now();
        }
        
        final diff = DateTime.now().difference(created).inMinutes;
        
        Color timeColor = Colors.green;
        if (diff > 30) timeColor = Colors.red;
        else if (diff > 15) timeColor = Colors.orange;

        final borderColor = type == 'pending' ? const Color(0xFFD4AF37) : Colors.blueAccent;

        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: diff > 30 ? Colors.red : borderColor, 
              width: diff > 30 ? 2 : 1
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: diff > 30 ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order['table_number'] ?? '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Colors.black, 
                              fontSize: 20
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("MEJA ${order['table_number']}", 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("#${order['order_number']}", 
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(created),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: timeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: timeColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 14, color: timeColor),
                              const SizedBox(width: 4),
                              Text("$diff mnt", 
                                style: TextStyle(color: timeColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, color: Colors.white10),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final hasNote = item['notes'] != null && item['notes'].toString().isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item['quantity']}x", 
                            style: TextStyle(
                              color: borderColor, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 18
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], 
                                  style: const TextStyle(color: Colors.white, fontSize: 16)),
                                if (hasNote)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.pink.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      "Catatan: ${item['notes']}",
                                      style: const TextStyle(
                                        color: Colors.pinkAccent, 
                                        fontSize: 12, 
                                        fontStyle: FontStyle.italic, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'pending' ? const Color(0xFFD4AF37) : Colors.green,
                      foregroundColor: type == 'pending' ? Colors.black : Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (type == 'pending') {
                        _updateStatus(int.parse(order['id'].toString()), 'cooking');
                      } else {
                        _updateStatus(int.parse(order['id'].toString()), 'ready');
                      }
                    },
                    icon: Icon(type == 'pending' ? Icons.soup_kitchen : Icons.notifications_active),
                    label: Text(
                      type == 'pending' ? "TERIMA & MASAK" : "SAJIKAN (PANGGIL PELAYAN)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}