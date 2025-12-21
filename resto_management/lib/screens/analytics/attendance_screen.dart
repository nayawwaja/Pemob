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

class _AttendanceScreenState extends State<AttendanceScreen> {
  // User & Role
  int _userId = 0;
  String _userRole = '';

  // Staff List (for Admin/Manager)
  List<dynamic> _staffList = [];
  int? _selectedStaffId;
  bool _isStaffLoading = true;

  // Calendar State
  Map<DateTime, List<dynamic>> _attendanceData = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserData();
    if (_userRole == 'admin' || _userRole == 'manager') {
      await _fetchStaffList();
    } else {
      // For regular staff, view their own attendance by default
      setState(() {
        _selectedStaffId = _userId;
        _isStaffLoading = false;
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
        setState(() => _staffList = res['data']);
      }
    } catch (e) {
      print("Error fetching staff list: $e");
    } finally {
      if (mounted) setState(() => _isStaffLoading = false);
    }
  }

  Future<void> _fetchAttendanceRecords(DateTime date) async {
    if (_selectedStaffId == null && (_userRole == 'admin' || _userRole == 'manager')) {
      // Don't fetch if no staff is selected for admin/manager
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

      if (mounted && res['success'] == true) {
        final Map<DateTime, List<dynamic>> events = {};
        (res['data'] as Map).forEach((key, value) {
          final eventDate = DateTime.parse(key);
          events[eventDate] = value as List;
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
    // Normalize date to ignore time
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    return _attendanceData[dateOnly] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final bool canSelectStaff = _userRole == 'admin' || _userRole == 'manager';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: Colors.black,
      ),
      body: Column(
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
      ),
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
        labelText: "Pilih Staff",
        prefixIcon: const Icon(Icons.person, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _staffList.map((s) {
        return DropdownMenuItem<int>(
          value: int.parse(s['id'].toString()),
          child: Text(s['name']),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedStaffId = val;
            _selectedDay = null; // Reset selection
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

    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    
    if (events.isEmpty) {
      return Center(
        child: Text(
          _selectedDay != null ? "Tidak ada data absensi di tanggal ini" : "Pilih tanggal untuk melihat detail",
          style: const TextStyle(color: Colors.white38)
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
                Text(
                  "Shift #${event['id']}", 
                  style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeColumn("Clock In", DateFormat.jm().format(clockIn.toLocal())),
                    if (clockOut != null)
                      _buildTimeColumn("Clock Out", DateFormat.jm().format(clockOut.toLocal())),
                  ],
                ),
                if (event['duration_minutes'] != null && int.parse(event['duration_minutes'].toString()) > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Durasi: ${event['duration_minutes']} Menit",
                        style: const TextStyle(color: Colors.blueAccent, fontStyle: FontStyle.italic)
                      )
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(String title, String time) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}