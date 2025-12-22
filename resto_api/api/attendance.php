<?php
// resto_api/api/attendance.php - FIXED VERSION
// - Added proper error handling
// - Added today's attendance summary for admin/manager
// - Added get_all_today endpoint

require_once '../utils/helpers.php';
require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true) ?? [];
$userId = $input['user_id'] ?? $_GET['user_id'] ?? 0;

// Route to the correct function
switch($action) {
    case 'clock_in':
        if (empty($userId)) {
            sendResponse(false, "User ID tidak ditemukan.", null, 400);
        }
        clockIn($db, $userId);
        break;
        
    case 'clock_out':
        if (empty($userId)) {
            sendResponse(false, "User ID tidak ditemukan.", null, 400);
        }
        clockOut($db, $userId);
        break;
        
    case 'get_my_status':
        if (empty($userId)) {
            sendResponse(false, "User ID tidak ditemukan.", null, 400);
        }
        getStaffAttendanceStatus($db, $userId);
        break;
        
    case 'get_attendance_records':
        getAttendanceRecords($db, $input);
        break;
        
    case 'get_staff_list':
        getStaffListForAttendance($db);
        break;
        
    case 'get_today_summary':
        getTodaySummary($db);
        break;
        
    case 'get_all_today':
        getAllTodayAttendance($db);
        break;
        
    default:
        sendResponse(false, "Invalid action for attendance API", null, 400);
}

// --- HELPER FUNCTION ---
function getUserRoleLocal($db, $userId) {
    try {
        $stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        return $stmt->fetchColumn();
    } catch (Exception $e) {
        return null;
    }
}

// --- CLOCK IN ---
function clockIn($db, $userId) {
    $role = getUserRoleLocal($db, $userId);
    
    if ($role === null) {
        sendResponse(false, "User tidak ditemukan.", null, 404);
        return;
    }
    
    if ($role === 'admin') {
        sendResponse(false, "Admin tidak memiliki sistem absensi.", null, 403);
        return;
    }

    // Check for an already open shift
    try {
        $checkStmt = $db->prepare("SELECT id FROM attendance WHERE user_id = ? AND clock_out IS NULL");
        $checkStmt->execute([$userId]);
        if ($checkStmt->fetch()) {
            sendResponse(false, "Anda sudah clock-in dan belum clock-out.");
            return;
        }

        $stmt = $db->prepare("INSERT INTO attendance (user_id, clock_in, status) VALUES (?, NOW(), 'present')");
        $stmt->execute([$userId]);
        
        // Log activity
        if (function_exists('logActivity')) {
            logActivity($db, $userId, 'CLOCK_IN', 'Staff memulai shift kerja');
        }
        
        sendResponse(true, "Clock-in berhasil! Selamat bekerja.", [
            'clock_in_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (PDOException $e) {
        // Check if table doesn't exist
        if (strpos($e->getMessage(), "doesn't exist") !== false) {
            sendResponse(false, "Tabel attendance belum dibuat. Hubungi administrator.", null, 500);
        } else {
            sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
        }
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage(), null, 500);
    }
}

// --- CLOCK OUT ---
function clockOut($db, $userId) {
    $role = getUserRoleLocal($db, $userId);
    
    if ($role === null) {
        sendResponse(false, "User tidak ditemukan.", null, 404);
        return;
    }
    
    if ($role === 'admin') {
        sendResponse(false, "Admin tidak memiliki sistem absensi.", null, 403);
        return;
    }

    try {
        // Find the open shift
        $findStmt = $db->prepare("SELECT id, clock_in FROM attendance WHERE user_id = ? AND clock_out IS NULL ORDER BY clock_in DESC LIMIT 1");
        $findStmt->execute([$userId]);
        $shift = $findStmt->fetch(PDO::FETCH_ASSOC);

        if (!$shift) {
            sendResponse(false, "Tidak ditemukan shift aktif untuk clock-out.");
            return;
        }

        $updateStmt = $db->prepare("UPDATE attendance SET clock_out = NOW(), duration_minutes = TIMESTAMPDIFF(MINUTE, clock_in, NOW()) WHERE id = ?");
        $updateStmt->execute([$shift['id']]);

        // Calculate duration for response
        $clockIn = new DateTime($shift['clock_in']);
        $clockOut = new DateTime();
        $duration = $clockIn->diff($clockOut);
        $durationStr = $duration->format('%h jam %i menit');

        // Log activity
        if (function_exists('logActivity')) {
            logActivity($db, $userId, 'CLOCK_OUT', "Staff mengakhiri shift kerja (Durasi: $durationStr)");
        }
        
        sendResponse(true, "Clock-out berhasil! Durasi kerja: $durationStr", [
            'clock_out_time' => date('Y-m-d H:i:s'),
            'duration' => $durationStr
        ]);
        
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), "doesn't exist") !== false) {
            sendResponse(false, "Tabel attendance belum dibuat. Hubungi administrator.", null, 500);
        } else {
            sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
        }
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage(), null, 500);
    }
}

// --- GET MY STATUS ---
function getStaffAttendanceStatus($db, $userId) {
    try {
        $stmt = $db->prepare("SELECT id, clock_in FROM attendance WHERE user_id = ? AND clock_out IS NULL ORDER BY clock_in DESC LIMIT 1");
        $stmt->execute([$userId]);
        $shift = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($shift) {
            sendResponse(true, "Shift aktif.", [
                'is_clocked_in' => true, 
                'clock_in_time' => $shift['clock_in']
            ]);
        } else {
            sendResponse(true, "Tidak ada shift aktif.", [
                'is_clocked_in' => false
            ]);
        }
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), "doesn't exist") !== false) {
            sendResponse(true, "Tidak ada shift aktif.", ['is_clocked_in' => false]);
        } else {
            sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
        }
    }
}

// --- GET STAFF LIST (for dropdown) ---
function getStaffListForAttendance($db) {
    try {
        $stmt = $db->query("SELECT id, name, role FROM users WHERE role NOT IN ('admin') AND is_active = 1 ORDER BY name ASC");
        $staff = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(true, "Success", $staff);
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage(), null, 500);
    }
}

// --- GET ATTENDANCE RECORDS (Calendar view) ---
function getAttendanceRecords($db, $input) {
    $requestingUserId = $input['requesting_user_id'] ?? 0;
    $targetUserId = $input['target_user_id'] ?? null;
    $month = $input['month'] ?? date('m');
    $year = $input['year'] ?? date('Y');

    // Check permission
    $requestingRole = getUserRoleLocal($db, $requestingUserId);

    if (!in_array($requestingRole, ['admin', 'manager'])) {
        // If not admin/manager, they can only see their own data
        $targetUserId = $requestingUserId;
    }
    
    $sql = "SELECT a.id, a.user_id, a.clock_in, a.clock_out, a.duration_minutes, a.status, a.notes,
                   u.name as user_name, u.role as user_role
            FROM attendance a
            JOIN users u ON a.user_id = u.id
            WHERE MONTH(a.clock_in) = ? AND YEAR(a.clock_in) = ?";
    
    $params = [$month, $year];

    if ($targetUserId) {
        $sql .= " AND a.user_id = ?";
        $params[] = $targetUserId;
    }
    
    $sql .= " ORDER BY a.clock_in DESC";

    try {
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $records = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Group records by date
        $events = [];
        foreach($records as $record) {
            $date = date('Y-m-d', strtotime($record['clock_in']));
            if (!isset($events[$date])) {
                $events[$date] = [];
            }
            $events[$date][] = $record;
        }

        sendResponse(true, "Data absensi berhasil diambil.", $events);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), "doesn't exist") !== false) {
            sendResponse(true, "Data absensi berhasil diambil.", []);
        } else {
            sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
        }
    }
}

// --- GET TODAY SUMMARY (for admin dashboard) ---
function getTodaySummary($db) {
    try {
        $today = date('Y-m-d');
        
        // Count staff who clocked in today
        $clockedIn = $db->prepare("SELECT COUNT(DISTINCT user_id) FROM attendance WHERE DATE(clock_in) = ?");
        $clockedIn->execute([$today]);
        $totalClockedIn = $clockedIn->fetchColumn();
        
        // Count staff currently on duty (clocked in but not out)
        $onDuty = $db->prepare("SELECT COUNT(*) FROM attendance WHERE DATE(clock_in) = ? AND clock_out IS NULL");
        $onDuty->execute([$today]);
        $totalOnDuty = $onDuty->fetchColumn();
        
        // Total active staff (excluding admin)
        $totalStaff = $db->query("SELECT COUNT(*) FROM users WHERE role != 'admin' AND is_active = 1")->fetchColumn();
        
        sendResponse(true, "Success", [
            'total_staff' => (int)$totalStaff,
            'clocked_in_today' => (int)$totalClockedIn,
            'currently_on_duty' => (int)$totalOnDuty,
            'not_clocked_in' => (int)$totalStaff - (int)$totalClockedIn
        ]);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), "doesn't exist") !== false) {
            sendResponse(true, "Success", [
                'total_staff' => 0,
                'clocked_in_today' => 0,
                'currently_on_duty' => 0,
                'not_clocked_in' => 0
            ]);
        } else {
            sendResponse(false, "Error: " . $e->getMessage(), null, 500);
        }
    }
}

// --- GET ALL TODAY ATTENDANCE (for admin/manager view) ---
function getAllTodayAttendance($db) {
    try {
        $today = date('Y-m-d');
        
        // Get all staff with their attendance status today
        $sql = "SELECT u.id, u.name, u.role,
                       a.id as attendance_id, a.clock_in, a.clock_out, a.duration_minutes, a.status,
                       CASE 
                           WHEN a.clock_in IS NOT NULL AND a.clock_out IS NULL THEN 'on_duty'
                           WHEN a.clock_in IS NOT NULL AND a.clock_out IS NOT NULL THEN 'completed'
                           ELSE 'not_clocked_in'
                       END as shift_status
                FROM users u
                LEFT JOIN attendance a ON u.id = a.user_id AND DATE(a.clock_in) = ?
                WHERE u.role != 'admin' AND u.is_active = 1
                ORDER BY 
                    CASE 
                        WHEN a.clock_in IS NOT NULL AND a.clock_out IS NULL THEN 1
                        WHEN a.clock_in IS NOT NULL THEN 2
                        ELSE 3
                    END,
                    u.name ASC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$today]);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format clock times
        foreach ($data as &$row) {
            if ($row['clock_in']) {
                $row['clock_in_formatted'] = date('H:i', strtotime($row['clock_in']));
            }
            if ($row['clock_out']) {
                $row['clock_out_formatted'] = date('H:i', strtotime($row['clock_out']));
            }
            if ($row['duration_minutes']) {
                $hours = floor($row['duration_minutes'] / 60);
                $mins = $row['duration_minutes'] % 60;
                $row['duration_formatted'] = "{$hours}j {$mins}m";
            }
        }
        
        sendResponse(true, "Success", $data);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), "doesn't exist") !== false) {
            // Return staff list without attendance data
            $stmt = $db->query("SELECT id, name, role, NULL as attendance_id, NULL as clock_in, NULL as clock_out, NULL as duration_minutes, 'not_clocked_in' as shift_status FROM users WHERE role != 'admin' AND is_active = 1 ORDER BY name");
            sendResponse(true, "Success", $stmt->fetchAll(PDO::FETCH_ASSOC));
        } else {
            sendResponse(false, "Error: " . $e->getMessage(), null, 500);
        }
    }
}
?>