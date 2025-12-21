<?php
require_once '../utils/helpers.php';
require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);
$userId = $input['user_id'] ?? $_GET['user_id'] ?? 0;

// Validate user ID exists for most actions
if (in_array($action, ['clock_in', 'clock_out', 'get_my_status']) && empty($userId)) {
    sendResponse(false, "User ID tidak ditemukan.", null, 400);
    exit;
}

// Get user role function
function getUserRole($db, $userId) {
    $stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    return $stmt->fetchColumn();
}

$role = getUserRole($db, $userId);

// Route to the correct function
switch($action) {
    case 'clock_in':
        clockIn($db, $userId, $role);
        break;
    case 'clock_out':
        clockOut($db, $userId, $role);
        break;
    case 'get_my_status':
        getStaffAttendanceStatus($db, $userId);
        break;
    case 'get_attendance_records':
        getAttendanceRecords($db, $input);
        break;
    case 'get_staff_list':
        getStaffListForAttendance($db);
        break;
    default:
        sendResponse(false, "Invalid action for attendance", null, 400);
}

// --- LOGIC FUNCTIONS ---

function clockIn($db, $userId, $role) {
    if ($role === 'admin') {
        sendResponse(false, "Admin tidak memiliki sistem absensi.");
        return;
    }

    // Check for an already open shift
    $checkStmt = $db->prepare("SELECT id FROM attendance WHERE user_id = ? AND clock_out IS NULL");
    $checkStmt->execute([$userId]);
    if ($checkStmt->fetch()) {
        sendResponse(false, "Anda sudah clock-in dan belum clock-out.");
        return;
    }

    try {
        $stmt = $db->prepare("INSERT INTO attendance (user_id, clock_in, status) VALUES (?, NOW(), 'present')");
        $stmt->execute([$userId]);
        
        logActivity($db, $userId, 'CLOCK_IN', 'Staff memulai shift kerja');
        sendResponse(true, "Clock-in berhasil! Selamat bekerja.");
    } catch (Exception $e) {
        sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
    }
}

function clockOut($db, $userId, $role) {
    if ($role === 'admin') {
        sendResponse(false, "Admin tidak memiliki sistem absensi.");
        return;
    }

    // Find the open shift
    $findStmt = $db->prepare("SELECT id, clock_in FROM attendance WHERE user_id = ? AND clock_out IS NULL ORDER BY clock_in DESC LIMIT 1");
    $findStmt->execute([$userId]);
    $shift = $findStmt->fetch(PDO::FETCH_ASSOC);

    if (!$shift) {
        sendResponse(false, "Tidak ditemukan shift aktif untuk clock-out.");
        return;
    }

    try {
        $updateStmt = $db->prepare("UPDATE attendance SET clock_out = NOW(), duration_minutes = TIMESTAMPDIFF(MINUTE, clock_in, NOW()) WHERE id = ?");
        $updateStmt->execute([$shift['id']]);

        logActivity($db, $userId, 'CLOCK_OUT', 'Staff mengakhiri shift kerja');
        sendResponse(true, "Clock-out berhasil! Terima kasih.");
    } catch (Exception $e) {
        sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
    }
}

function getStaffAttendanceStatus($db, $userId) {
    $stmt = $db->prepare("SELECT id, clock_in FROM attendance WHERE user_id = ? AND clock_out IS NULL ORDER BY clock_in DESC LIMIT 1");
    $stmt->execute([$userId]);
    $shift = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($shift) {
        sendResponse(true, "Shift aktif.", ['is_clocked_in' => true, 'clock_in_time' => $shift['clock_in']]);
    } else {
        sendResponse(true, "Tidak ada shift aktif.", ['is_clocked_in' => false]);
    }
}

function getStaffListForAttendance($db) {
    // Only get roles that have attendance
    $stmt = $db->query("SELECT id, name, role FROM users WHERE role NOT IN ('admin') ORDER BY name ASC");
    $staff = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Success", $staff);
}

function getAttendanceRecords($db, $input) {
    $requestingUserId = $input['requesting_user_id'] ?? 0;
    $targetUserId = $input['target_user_id'] ?? null;
    $month = $input['month'] ?? date('m');
    $year = $input['year'] ?? date('Y');

    $requestingRole = getUserRole($db, $requestingUserId);

    if (!in_array($requestingRole, ['admin', 'manager'])) {
        // If not admin/manager, they can only see their own data
        $targetUserId = $requestingUserId;
    }
    
    $sql = "SELECT id, user_id, clock_in, clock_out, duration_minutes, status, notes 
            FROM attendance 
            WHERE MONTH(clock_in) = ? AND YEAR(clock_in) = ?";
    
    $params = [$month, $year];

    if ($targetUserId) {
        $sql .= " AND user_id = ?";
        $params[] = $targetUserId;
    }
    
    $sql .= " ORDER BY clock_in ASC";

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
    } catch (Exception $e) {
        sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
    }
}
?>