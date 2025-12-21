import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

/// Staff Management Screen - FIXED VERSION
/// Changelog:
/// - Added null safety parsing
/// - Better error handling
/// - Fixed Switch logic
/// - Added loading states
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
  bool _isGenerating = false;
  String? _errorMessage;
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
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // FIXED: Sequential initialization
  Future<void> _initData() async {
    await _loadAdminData();
    await _refreshData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _adminId = prefs.getInt('userId') ?? 0);
    }
  }

  // ============================================
  // SAFE PARSING HELPERS
  // ============================================
  
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

  bool _safeParseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('staff.php?action=get_all_staff'),
        ApiService.get('staff.php?action=get_access_codes'),
      ], eagerError: false);

      if (!mounted) return;

      final staffRes = results[0];
      final codeRes = results[1];

      setState(() {
        if (staffRes['success'] == true && staffRes['data'] != null) {
          _staffList = staffRes['data'] as List? ?? [];
        } else if (staffRes['success'] == false) {
          // Handle error tapi jangan stop loading
          print("Staff Error: ${staffRes['message']}");
        }

        if (codeRes['success'] == true && codeRes['data'] != null) {
          _accessCodes = codeRes['data'] as List? ?? [];
        } else if (codeRes['success'] == false) {
          // Kemungkinan tabel belum ada
          print("Code Error: ${codeRes['message']}");
          // Tidak set error karena mungkin tabel belum dibuat
        }

        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat data: $e";
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIC 1: GENERATE KODE BARU ---
  Future<void> _generateCode() async {
    if (_adminId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Admin ID tidak valid. Silakan login ulang."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    
    try {
      final res = await ApiService.post('staff.php?action=generate_code', {
        'role': _selectedRoleForCode,
        'created_by': _adminId
      });

      if (!mounted) return;

      if (res['success'] == true) {
        final code = res['data']?['code'] ?? 'Unknown';
        
        // Show dialog with copy option
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text("Kode Berhasil Dibuat", style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Kode disalin!")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Kode untuk posisi: ${_roles[_selectedRoleForCode] ?? _selectedRoleForCode}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Kode berlaku 7 hari dan hanya bisa digunakan sekali.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
        
        _refreshData();
      } else {
        String errorMsg = res['message'] ?? "Gagal membuat kode";
        
        // Check jika error karena tabel tidak ada
        if (errorMsg.contains("staff_access_codes") || errorMsg.contains("doesn't exist")) {
          errorMsg = "Tabel kode akses belum dibuat di database. Hubungi administrator.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Generate code error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- LOGIC 2: AKTIF/NONAKTIF STAFF ---
  Future<void> _toggleStaffStatus(int userId, bool currentlyActive) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          currentlyActive ? "Nonaktifkan Akun?" : "Aktifkan Akun?",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          currentlyActive 
            ? "Staff tidak akan bisa login sampai diaktifkan kembali."
            : "Staff akan bisa login kembali.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyActive ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(currentlyActive ? "Nonaktifkan" : "Aktifkan"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // FIXED: Correct status logic
    int newStatus = currentlyActive ? 0 : 1;
    
    try {
      final res = await ApiService.post('staff.php?action=toggle_status', {
        'user_id': userId,
        'status': newStatus
      });

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 1 ? "Akun diaktifkan kembali" : "Akun dinonaktifkan"),
            backgroundColor: newStatus == 1 ? Colors.green : Colors.orange,
          ),
        );
        _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? "Gagal mengubah status"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Toggle status error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen SDM'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: "Daftar Staff (${_staffList.length})",
            ),
            Tab(
              icon: const Icon(Icons.vpn_key),
              text: "Kode Akses (${_accessCodes.length})",
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFF1A1A1A),
        child: _buildBody(),
      ),
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
              onPressed: _refreshData,
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

    return TabBarView(
      controller: _tabController,
      children: [
        _buildStaffListTab(),
        _buildAccessCodeTab(),
      ],
    );
  }

  // --- TAB 1: DAFTAR KARYAWAN ---
  Widget _buildStaffListTab() {
    if (_staffList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              "Belum ada staff terdaftar",
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            const Text(
              "Buat kode akses di tab 'Kode Akses' untuk\nmendaftarkan staff baru",
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFD4AF37),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staffList.length,
        itemBuilder: (context, index) {
          final staff = _staffList[index];
          
          // FIXED: Safe parsing
          final int staffId = _safeParseInt(staff['id']);
          final bool isActive = _safeParseBool(staff['is_active']);
          final String name = staff['name']?.toString() ?? 'Unknown';
          final String email = staff['email']?.toString() ?? '-';
          final String role = staff['role']?.toString() ?? 'unknown';
          
          return Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive ? Colors.transparent : Colors.red.withOpacity(0.5),
                width: isActive ? 0 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isActive ? _getRoleColor(role) : Colors.grey,
                child: Icon(
                  _getRoleIcon(role), 
                  color: Colors.white, 
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name, 
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey, 
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "NONAKTIF",
                        style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role.toUpperCase(), 
                      style: TextStyle(
                        color: _getRoleColor(role), 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email, 
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Switch(
                value: isActive,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.withOpacity(0.3),
                onChanged: (val) => _toggleStaffStatus(staffId, isActive),
              ),
            ),
          );
        },
      ),
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
              const Row(
                children: [
                  Icon(Icons.add_circle, color: Color(0xFFD4AF37), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Buat Kode Pendaftaran Baru", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Staff baru bisa daftar menggunakan kode ini",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRoleForCode,
                          dropdownColor: const Color(0xFF333333),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: _roles.entries.map((e) => DropdownMenuItem(
                            value: e.key, 
                            child: Text(e.value),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRoleForCode = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    icon: _isGenerating 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.add),
                    label: Text(_isGenerating ? "..." : "GENERATE"),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List Kode
        Expanded(
          child: _accessCodes.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.vpn_key_off, size: 60, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      "Belum ada kode aktif",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Buat kode baru dengan tombol di atas",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color(0xFFD4AF37),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accessCodes.length,
                  itemBuilder: (context, index) {
                    final code = _accessCodes[index];
                    final String codeStr = code['code']?.toString() ?? 'ERROR';
                    final String targetRole = code['target_role']?.toString() ?? 'unknown';
                    final String expiresAt = code['expires_at']?.toString() ?? '';
                    
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getRoleColor(targetRole).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.vpn_key, 
                                color: _getRoleColor(targetRole),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    codeStr, 
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 18, 
                                      fontFamily: 'monospace', 
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(targetRole).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          targetRole.toUpperCase(),
                                          style: TextStyle(
                                            color: _getRoleColor(targetRole),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (expiresAt.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          "Exp: ${expiresAt.substring(0, 10)}",
                                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Color(0xFFD4AF37)),
                              tooltip: "Salin Kode",
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: codeStr));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Kode disalin ke clipboard!"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }

  // Helpers
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'chef': return Colors.redAccent;
      case 'waiter': return Colors.orange;
      case 'cs': return Colors.blue;
      case 'manager': return Colors.purple;
      case 'admin': return const Color(0xFFD4AF37);
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'chef': return Icons.soup_kitchen;
      case 'waiter': return Icons.room_service;
      case 'cs': return Icons.support_agent;
      case 'manager': return Icons.manage_accounts;
      case 'admin': return Icons.admin_panel_settings;
      default: return Icons.person;
    }
  }
}