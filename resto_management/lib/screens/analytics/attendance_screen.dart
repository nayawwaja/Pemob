import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  // User & Role
  int _userId = 0;
  String _userRole = '';

  // Tab Controller
  late TabController _tabController;

  // Staff List (for Admin/Manager)
  List<dynamic> _staffList = [];
  int? _selectedStaffId;
  bool _isStaffLoading = true;

  // Calendar State
  Map<DateTime, List<dynamic>> _attendanceData = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarLoading = true;

  // Today's Attendance (for Admin/Manager)
  List<dynamic> _todayAttendance = [];
  Map<String, dynamic> _todaySummary = {};
  bool _isTodayLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadUserData();
    
    if (_userRole == 'admin' || _userRole == 'manager') {
      await Future.wait([
        _fetchStaffList(),
        _fetchTodayAttendance(),
        _fetchTodaySummary(),
      ]);
    } else {
      setState(() {
        _selectedStaffId = _userId;
        _isStaffLoading = false;
        _isTodayLoading = false;
      });
    }
    
    _fetchAttendanceRecords(_focusedDay);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _userRole = prefs.getString('role') ?? '';
    });
  }

  Future<void> _fetchStaffList() async {
    setState(() => _isStaffLoading = true);
    try {
      final res = await ApiService.get('attendance.php?action=get_staff_list');
      if (mounted && res['success'] == true) {
        setState(() => _staffList = res['data'] ?? []);
      }
    } catch (e) {
      print("Error fetching staff list: $e");
    } finally {
      if (mounted) setState(() => _isStaffLoading = false);
    }
  }

  Future<void> _fetchTodayAttendance() async {
    setState(() => _isTodayLoading = true);
    try {
      final res = await ApiService.get('attendance.php?action=get_all_today');
      if (mounted && res['success'] == true) {
        setState(() => _todayAttendance = res['data'] ?? []);
      }
    } catch (e) {
      print("Error fetching today attendance: $e");
    } finally {
      if (mounted) setState(() => _isTodayLoading = false);
    }
  }

  Future<void> _fetchTodaySummary() async {
    try {
      final res = await ApiService.get('attendance.php?action=get_today_summary');
      if (mounted && res['success'] == true) {
        setState(() => _todaySummary = res['data'] ?? {});
      }
    } catch (e) {
      print("Error fetching summary: $e");
    }
  }

  Future<void> _fetchAttendanceRecords(DateTime date) async {
    if (_selectedStaffId == null && (_userRole == 'admin' || _userRole == 'manager')) {
      setState(() => _isCalendarLoading = false);
      return;
    }
    
    setState(() => _isCalendarLoading = true);
    
    try {
      final res = await ApiService.post('attendance.php?action=get_attendance_records', {
        'requesting_user_id': _userId,
        'target_user_id': _selectedStaffId,
        'month': date.month,
        'year': date.year,
      });

      if (mounted && res['success'] == true && res['data'] != null) {
        final Map<DateTime, List<dynamic>> events = {};
        (res['data'] as Map).forEach((key, value) {
          final eventDate = DateTime.parse(key);
          final normalizedDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
          events[normalizedDate] = List<dynamic>.from(value);
        });
        setState(() => _attendanceData = events);
      } else {
        setState(() => _attendanceData.clear());
      }
    } catch (e) {
      print("Error fetching records: $e");
      setState(() => _attendanceData.clear());
    } finally {
      if (mounted) setState(() => _isCalendarLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    return _attendanceData[dateOnly] ?? [];
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchTodayAttendance(),
      _fetchTodaySummary(),
    ]);
    _fetchAttendanceRecords(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole == 'admin' || _userRole == 'manager';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _refreshAll,
          ),
        ],
        bottom: isAdmin ? TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: "Hari Ini"),
            Tab(icon: Icon(Icons.calendar_month), text: "Riwayat"),
          ],
        ) : null,
      ),
      body: isAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildHistoryTab(),
              ],
            )
          : _buildHistoryTab(),
    );
  }

  // ==================== TODAY TAB (Admin/Manager) ====================
  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 24),
            
            // Today's Attendance List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Status Kehadiran Hari Ini",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _isTodayLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _buildTodayAttendanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(
          "On Duty",
          "${_todaySummary['currently_on_duty'] ?? 0}",
          Icons.work,
          Colors.green,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(
          "Sudah Absen",
          "${_todaySummary['clocked_in_today'] ?? 0}",
          Icons.check_circle,
          Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(
          "Belum Absen",
          "${_todaySummary['not_clocked_in'] ?? 0}",
          Icons.warning,
          Colors.orange,
        )),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceList() {
    if (_todayAttendance.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text("Belum ada data absensi", style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todayAttendance.length,
      itemBuilder: (context, index) {
        final staff = _todayAttendance[index];
        return _buildStaffAttendanceCard(staff);
      },
    );
  }

  Widget _buildStaffAttendanceCard(Map<String, dynamic> staff) {
    final shiftStatus = staff['shift_status'] ?? 'not_clocked_in';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (shiftStatus) {
      case 'on_duty':
        statusColor = Colors.green;
        statusText = 'ON DUTY';
        statusIcon = Icons.play_circle;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'SELESAI';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'BELUM ABSEN';
        statusIcon = Icons.access_time;
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            staff['name']?.substring(0, 1).toUpperCase() ?? '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          staff['name'] ?? 'Unknown',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (staff['role'] ?? '').toUpperCase(),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ),
            if (staff['clock_in_formatted'] != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.login, size: 12, color: Colors.green.shade300),
              const SizedBox(width: 4),
              Text(staff['clock_in_formatted'], style: TextStyle(color: Colors.green.shade300, fontSize: 12)),
            ],
            if (staff['clock_out_formatted'] != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.logout, size: 12, color: Colors.red.shade300),
              const SizedBox(width: 4),
              Text(staff['clock_out_formatted'], style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab() {
    final bool canSelectStaff = _userRole == 'admin' || _userRole == 'manager';

    return Column(
      children: [
        // Staff Selector for Admin/Manager
        if (canSelectStaff)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStaffSelector(),
          ),

        // Calendar
        _buildCalendar(),
        
        const Divider(color: Colors.white10),

        // Selected Day's Events
        Expanded(
          child: _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildStaffSelector() {
    if (_isStaffLoading) {
      return const Center(child: LinearProgressIndicator(color: Color(0xFFD4AF37)));
    }
    
    return DropdownButtonFormField<int>(
      value: _selectedStaffId,
      dropdownColor: const Color(0xFF333333),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Pilih Staff untuk Lihat Riwayat",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.person, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text("Pilih staff...", style: TextStyle(color: Colors.white38)),
      items: _staffList.map((s) {
        return DropdownMenuItem<int>(
          value: int.parse(s['id'].toString()),
          child: Text("${s['name']} (${s['role']})"),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedStaffId = val;
            _selectedDay = null;
            _attendanceData.clear();
          });
          _fetchAttendanceRecords(_focusedDay);
        }
      },
    );
  }
  
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
        leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFD4AF37)),
        rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white70),
        weekendTextStyle: const TextStyle(color: Colors.white),
        outsideTextStyle: const TextStyle(color: Colors.white24),
        todayDecoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFFD4AF37),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      eventLoader: _getEventsForDay,
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
        _fetchAttendanceRecords(focusedDay);
      },
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildEventList() {
    if (_isCalendarLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    if (_selectedStaffId == null && (_userRole == 'admin' || _userRole == 'manager')) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text("Pilih staff untuk melihat riwayat absensi", style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedDay != null ? Icons.event_busy : Icons.touch_app,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedDay != null 
                  ? "Tidak ada data absensi di tanggal ini" 
                  : "Pilih tanggal untuk melihat detail",
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final clockIn = DateTime.parse(event['clock_in']);
        final clockOut = event['clock_out'] != null ? DateTime.parse(event['clock_out']) : null;

        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event['user_name'] ?? "Shift #${event['id']}", 
                      style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: clockOut != null ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        clockOut != null ? "Selesai" : "Aktif",
                        style: TextStyle(
                          color: clockOut != null ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTimeColumn("Clock In", DateFormat('HH:mm').format(clockIn.toLocal()), Colors.green),
                    if (clockOut != null)
                      _buildTimeColumn("Clock Out", DateFormat('HH:mm').format(clockOut.toLocal()), Colors.red),
                  ],
                ),
                if (event['duration_minutes'] != null && int.parse(event['duration_minutes'].toString()) > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Durasi: ${_formatDuration(int.parse(event['duration_minutes'].toString()))}",
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(String title, String time, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              title == "Clock In" ? Icons.login : Icons.logout,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              time, 
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    if (hours > 0) {
      return "$hours jam $mins menit";
    }
    return "$mins menit";
  }
}