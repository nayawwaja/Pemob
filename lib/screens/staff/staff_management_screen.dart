import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data Lists
  List<dynamic> _staffList = [];
  List<dynamic> _accessCodes = [];
  
  bool _isLoading = true;
  int _adminId = 0;
  String _selectedRoleForCode = 'waiter'; // Default dropdown

  final Map<String, String> _roles = {
    'waiter': 'Pelayan / Waiter',
    'chef': 'Chef / Koki',
    'cs': 'Customer Service',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
    _refreshData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _adminId = prefs.getInt('userId') ?? 0);
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final staffRes = await ApiService.get('staff.php?action=get_all_staff');
      final codeRes = await ApiService.get('staff.php?action=get_access_codes');

      if (mounted) {
        setState(() {
          if (staffRes['success'] == true) _staffList = staffRes['data'];
          if (codeRes['success'] == true) _accessCodes = codeRes['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC 1: GENERATE KODE BARU ---
  Future<void> _generateCode() async {
    setState(() => _isLoading = true);
    
    final res = await ApiService.post('staff.php?action=generate_code', {
      'role': _selectedRoleForCode,
      'created_by': _adminId
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kode berhasil dibuat: ${res['data']['code']}"),
          backgroundColor: Colors.green,
        )
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuat kode"), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC 2: AKTIF/NONAKTIF STAFF ---
  Future<void> _toggleStaffStatus(int userId, int currentStatus) async {
    // 1 = Aktif, 0 = Nonaktif. Kita balik nilainya.
    int newStatus = currentStatus == 1 ? 0 : 1;
    
    final res = await ApiService.post('staff.php?action=toggle_status', {
      'user_id': userId,
      'status': newStatus
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 1 ? "Akun diaktifkan kembali" : "Akun dinonaktifkan (Banned)"),
          backgroundColor: newStatus == 1 ? Colors.green : Colors.red,
        )
      );
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen SDM'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Daftar Staff"),
            Tab(icon: Icon(Icons.vpn_key), text: "Kode Akses"),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFF1A1A1A),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStaffListTab(),
                  _buildAccessCodeTab(),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: DAFTAR KARYAWAN ---
  Widget _buildStaffListTab() {
    if (_staffList.isEmpty) {
      return const Center(child: Text("Belum ada staff terdaftar", style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staffList.length,
      itemBuilder: (context, index) {
        final staff = _staffList[index];
        final isActive = staff['is_active'] == 1 || staff['is_active'] == '1';
        
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isActive ? Colors.transparent : Colors.red.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(staff['role']),
              child: Icon(_getRoleIcon(staff['role']), color: Colors.white, size: 20),
            ),
            title: Text(staff['name'], style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff['role'].toString().toUpperCase(), style: TextStyle(color: _getRoleColor(staff['role']), fontSize: 12, fontWeight: FontWeight.bold)),
                Text(staff['email'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            trailing: Switch(
              value: isActive,
              activeColor: Colors.green,
              inactiveTrackColor: Colors.red.withOpacity(0.3),
              thumbIcon: MaterialStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(MaterialState.selected)) return const Icon(Icons.check, color: Colors.white);
                return const Icon(Icons.close, color: Colors.white);
              }),
              onChanged: (val) => _toggleStaffStatus(int.parse(staff['id'].toString()), isActive ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: GENERATOR KODE ---
  Widget _buildAccessCodeTab() {
    return Column(
      children: [
        // Form Generator
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Buat Kode Pendaftaran Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRoleForCode,
                          dropdownColor: const Color(0xFF333333),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                          onChanged: (val) => setState(() => _selectedRoleForCode = val!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("GENERATE"),
                  )
                ],
              ),
            ],
          ),
        ),

        // List Kode
        Expanded(
          child: _accessCodes.isEmpty 
            ? const Center(child: Text("Belum ada kode aktif. Buat baru di atas.", style: TextStyle(color: Colors.white38)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _accessCodes.length,
                itemBuilder: (context, index) {
                  final code = _accessCodes[index];
                  return Card(
                    color: const Color(0xFF2A2A2A),
                    child: ListTile(
                      leading: const Icon(Icons.vpn_key, color: Colors.white54),
                      title: Text(code['code'], style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      subtitle: Text("Untuk Posisi: ${code['target_role'].toString().toUpperCase()}", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        tooltip: "Salin Kode",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code['code']));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode disalin ke clipboard!")));
                        },
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  // Helpers
  Color _getRoleColor(String role) {
    switch (role) {
      case 'chef': return Colors.redAccent;
      case 'waiter': return Colors.orange;
      case 'cs': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'chef': return Icons.soup_kitchen;
      case 'waiter': return Icons.room_service;
      case 'cs': return Icons.support_agent;
      default: return Icons.person;
    }
  }
}