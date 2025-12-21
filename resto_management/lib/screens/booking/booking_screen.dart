import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'create_booking_screen.dart';
import 'check_in_screen.dart'; 

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  List<dynamic> _tables = [];
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  int _userId = 0;
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _refreshData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    try {
      final results = await Future.wait([
        ApiService.get('tables.php?action=get_tables'), // Status Meja Terkini
        ApiService.get('booking.php?action=get_bookings&date=$dateStr'), // List Booking
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['success'] == true) _tables = results[0]['data'];
          if (results[1]['success'] == true) _bookings = results[1]['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error booking data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: UPDATE STATUS MEJA MANUAL ---
  Future<void> _updateTableStatus(int tableId, String newStatus) async {
    // Optimistic Update
    setState(() {
      final index = _tables.indexWhere((t) => int.parse(t['id'].toString()) == tableId);
      if (index != -1) _tables[index]['status'] = newStatus;
    });

    final res = await ApiService.post('tables.php?action=update_status', {
      'id': tableId,
      'status': newStatus,
      'user_id': _userId
    });

    if (res['success'] != true) {
      _refreshData(); // Revert jika gagal
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update status"), backgroundColor: Colors.red));
    }
  }

  // --- LOGIC: BATALKAN BOOKING ---
  Future<void> _cancelBooking(int bookingId, String guestName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text("Batalkan Reservasi?", style: TextStyle(color: Colors.redAccent)),
        content: Text("Reservasi a.n $guestName akan dibatalkan dan meja akan dikosongkan.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Kembali")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Batalkan"),
          )
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await ApiService.post('booking.php?action=cancel_booking', {
        'booking_id': bookingId,
        'user_id': _userId
      });
      
      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking berhasil dibatalkan"), backgroundColor: Colors.green));
          _refreshData();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Gagal batal"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Meja & Reservasi'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: "Denah Meja"),
            Tab(icon: Icon(Icons.calendar_today), text: "Daftar Booking"),
          ],
        ),
        actions: [
          // Tombol Verifikasi Kode (Check In Cepat)
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD4AF37)),
            tooltip: "Verifikasi Kode Tamu",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckInScreen()),
              );
              if (result == true) _refreshData();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTableMap(),
                _buildBookingList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("BOOKING BARU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateBookingScreen(tables: List<Map<String, dynamic>>.from(_tables))),
          );
          _refreshData();
        },
      ),
    );
  }

  // --- TAB 1: DENAH MEJA ---
  Widget _buildTableMap() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(Colors.grey[800]!, "Kosong"),
              _buildLegend(Colors.blue[900]!, "Reserved"),
              _buildLegend(Colors.red[900]!, "Terisi"),
              _buildLegend(Colors.brown[600]!, "Kotor"),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];
                final status = table['status'].toString().toLowerCase();
                
                Color bg;
                IconData icon;
                String labelStatus;
                
                switch (status) {
                  case 'occupied':
                    bg = Colors.red[900]!;
                    icon = Icons.people;
                    labelStatus = "TERISI";
                    break;
                  case 'reserved':
                    bg = Colors.blue[900]!;
                    icon = Icons.bookmark;
                    labelStatus = "BOOKED";
                    break;
                  case 'dirty':
                    bg = Colors.brown[600]!;
                    icon = Icons.cleaning_services;
                    labelStatus = "KOTOR";
                    break;
                  default:
                    bg = Colors.grey[800]!;
                    icon = Icons.check_box_outline_blank;
                    labelStatus = "KOSONG";
                }

                return InkWell(
                  onTap: () => _showTableOptions(table),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(table['table_number'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Icon(icon, color: Colors.white70),
                        const SizedBox(height: 4),
                        Text(labelStatus, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: DAFTAR BOOKING ---
  Widget _buildBookingList() {
    return Column(
      children: [
        // Date Selector
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF252525),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 16),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  _refreshData();
                },
              ),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  _refreshData();
                },
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _bookings.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.event_busy, size: 60, color: Colors.white24),
                    SizedBox(height: 12),
                    Text("Tidak ada booking pada tanggal ini", style: TextStyle(color: Colors.white38)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == booking['booking_date'];
                    final status = booking['status'];

                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    booking['booking_time'].toString().substring(0, 5),
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(booking['customer_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("Meja ${booking['table_number']} • ${booking['guest_count']} Orang", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      if (booking['booking_code'] != null)
                                        Text("Kode: ${booking['booking_code']}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                if (status == 'checked_in')
                                  const Icon(Icons.check_circle, color: Colors.green)
                              ],
                            ),
                            
                            // Action Buttons (Hanya jika belum check-in & tanggal hari ini)
                            if (status == 'confirmed') ...[
                              const Divider(color: Colors.white10, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _cancelBooking(int.parse(booking['id'].toString()), booking['customer_name']),
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                                    label: const Text("Batalkan", style: TextStyle(color: Colors.redAccent)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isToday)
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        // Auto Check-In tanpa scan (Manual via list)
                                        setState(() => _isLoading = true);
                                        await ApiService.post('booking.php?action=check_in', {
                                          'booking_id': booking['id'],
                                          'user_id': _userId
                                        });
                                        _refreshData();
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      icon: const Icon(Icons.login, size: 18),
                                      label: const Text("Check In"),
                                    ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- MODAL UBAH STATUS MEJA ---
  Future<void> _showTableOptions(Map<String, dynamic> table) async {
    String currentStatus = table['status'];
    int tableId = int.parse(table['id'].toString());
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Meja ${table['table_number']}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              if (table['guest_name'] != null)
                Text("Tamu: ${table['guest_name']}", style: const TextStyle(color: Color(0xFFD4AF37))),
              const SizedBox(height: 24),
              const Text("Ubah Status Manual:", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatusButton("KOSONG", 'available', Colors.grey, currentStatus, tableId),
                  _buildStatusButton("TERISI", 'occupied', Colors.red, currentStatus, tableId),
                  _buildStatusButton("RESERVED", 'reserved', Colors.blue, currentStatus, tableId),
                  _buildStatusButton("KOTOR", 'dirty', Colors.brown, currentStatus, tableId),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(String label, String statusValue, Color color, String currentStatus, int tableId) {
    bool isSelected = statusValue == currentStatus;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : const Color(0xFF333333),
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        side: BorderSide(color: isSelected ? Colors.white : color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        Navigator.pop(context); 
        _updateTableStatus(tableId, statusValue);
      },
      child: Text(label),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}