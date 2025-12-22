<?php
require_once '../config/database.php';
$db = (new Database())->getConnection();

if (!function_exists('sendResponse')) {
    function sendResponse($success, $message, $data = null, $httpCode = 200) {
        http_response_code($httpCode);
        header('Content-Type: application/json');
        echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
        exit;
    }
}

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

switch($action) {
    case 'get_all_staff':
        getAllStaff($db);
        break;
    case 'get_access_codes':
        getAccessCodes($db);
        break;
    case 'generate_code':
        generateCode($db, $input);
        break;
    case 'toggle_status':
        toggleStatus($db, $input);
        break;
    case 'get_activity_logs':
        getActivityLogs($db);
        break;
    case 'get_notifications':
        getNotifications($db);
        break;
    // === TAMBAHAN: Handler untuk attendance dari staff dashboard ===
    case 'attendance':
        handleAttendance($db, $input);
        break;
    default:
        sendResponse(false, "Invalid action for staff API", null, 400);
}

/**
 * TAMBAHAN: Handler attendance untuk kompatibilitas dengan staff_dashboard.dart
 * Sebenarnya sebaiknya panggil langsung ke attendance.php, 
 * tapi ini sebagai fallback/redirect
 */
function handleAttendance($db, $input) {
    $userId = $input['user_id'] ?? 0;
    $type = $input['type'] ?? 'in'; // 'in' atau 'out'
    
    if (empty($userId)) {
        sendResponse(false, "User ID tidak ditemukan.", null, 400);
        return;
    }
    
    // Cek role user (admin tidak bisa absen)
    $stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $role = $stmt->fetchColumn();
    
    if ($role === 'admin') {
        sendResponse(false, "Admin tidak memiliki sistem absensi.");
        return;
    }
    
    if ($type === 'in') {
        // Clock In
        $checkStmt = $db->prepare("SELECT id FROM attendance WHERE user_id = ? AND clock_out IS NULL");
        $checkStmt->execute([$userId]);
        if ($checkStmt->fetch()) {
            sendResponse(false, "Anda sudah clock-in dan belum clock-out.");
            return;
        }
        
        try {
            $stmt = $db->prepare("INSERT INTO attendance (user_id, clock_in, status) VALUES (?, NOW(), 'present')");
            $stmt->execute([$userId]);
            
            // Log activity
            logActivityInternal($db, $userId, 'CLOCK_IN', 'Staff memulai shift kerja');
            
            sendResponse(true, "Clock-in berhasil! Selamat bekerja.");
        } catch (Exception $e) {
            sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
        }
    } else {
        // Clock Out
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
            
            logActivityInternal($db, $userId, 'CLOCK_OUT', 'Staff mengakhiri shift kerja');
            
            sendResponse(true, "Clock-out berhasil! Terima kasih.");
        } catch (Exception $e) {
            sendResponse(false, "Database error: " . $e->getMessage(), null, 500);
        }
    }
}

// Internal log activity function
function logActivityInternal($db, $userId, $actionType, $description) {
    try {
        $stmt = $db->prepare("INSERT INTO activity_logs (user_id, action_type, description, created_at) VALUES (?, ?, ?, NOW())");
        $stmt->execute([$userId, $actionType, $description]);
    } catch (Exception $e) {
        // Jika tabel belum ada, abaikan saja
    }
}

function getAllStaff($db) {
    try {
        $stmt = $db->prepare("SELECT id, name, email, role, is_active FROM users WHERE role != 'admin' ORDER BY name ASC");
        $stmt->execute();
        $staff = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(true, "Staff list retrieved successfully.", $staff);
    } catch (Exception $e) {
        sendResponse(false, "API Error: " . $e->getMessage(), null, 500);
    }
}

function getAccessCodes($db) {
    try {
        $stmt = $db->prepare("SELECT * FROM staff_access_codes WHERE is_used = 0 ORDER BY created_at DESC");
        $stmt->execute();
        $codes = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(true, "Access codes retrieved.", $codes);
    } catch (Exception $e) {
        sendResponse(false, "API Error: " . $e->getMessage(), null, 500);
    }
}

function generateCode($db, $input) {
    if (empty($input['role']) || empty($input['created_by'])) {
        sendResponse(false, "Role dan ID pembuat kode wajib diisi.", null, 400);
        return;
    }

    $role = $input['role'];
    $createdBy = $input['created_by'];
    $code = strtoupper(substr($role, 0, 3)) . '-' . substr(str_shuffle('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'), 0, 6);

    try {
        $stmt = $db->prepare("INSERT INTO staff_access_codes (code, target_role, created_by, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 7 DAY))");
        $stmt->execute([$code, $role, $createdBy]);
        
        sendResponse(true, "Code generated successfully.", ['code' => $code], 201);
    } catch (Exception $e) {
        sendResponse(false, "Gagal membuat kode: " . $e->getMessage(), null, 500);
    }
}

function toggleStatus($db, $input) {
    if (!isset($input['user_id']) || !isset($input['status'])) {
        sendResponse(false, "User ID dan status wajib diisi.", null, 400);
        return;
    }

    $userId = $input['user_id'];
    $status = $input['status'];

    try {
        $checkStmt = $db->prepare("SELECT role FROM users WHERE id = ?");
        $checkStmt->execute([$userId]);
        $user = $checkStmt->fetch(PDO::FETCH_ASSOC);

        if ($user && $user['role'] == 'admin') {
            sendResponse(false, "Tidak dapat mengubah status akun Admin.", null, 403);
            return;
        }

        $stmt = $db->prepare("UPDATE users SET is_active = ? WHERE id = ?");
        $stmt->execute([$status, $userId]);
        sendResponse(true, "Status staff berhasil diperbarui.");
    } catch (Exception $e) {
        sendResponse(false, "Gagal memperbarui status: " . $e->getMessage(), null, 500);
    }
}

function getActivityLogs($db) {
    try {
        $sql = "SELECT l.*, u.name as user_name, 
                CASE 
                    WHEN TIMESTAMPDIFF(MINUTE, l.created_at, NOW()) < 60 THEN CONCAT(TIMESTAMPDIFF(MINUTE, l.created_at, NOW()), 'm ago')
                    WHEN TIMESTAMPDIFF(HOUR, l.created_at, NOW()) < 24 THEN CONCAT(TIMESTAMPDIFF(HOUR, l.created_at, NOW()), 'h ago')
                    ELSE DATE_FORMAT(l.created_at, '%d/%m')
                END as time_ago
                FROM activity_logs l
                LEFT JOIN users u ON l.user_id = u.id
                ORDER BY l.created_at DESC LIMIT 20";
        
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(true, "Logs retrieved", $logs);
    } catch (Exception $e) {
        sendResponse(true, "No logs available", []);
    }
}

function getNotifications($db) {
    $role = $_GET['role'] ?? '';
    $userId = $_GET['user_id'] ?? 0;
    
    try {
        // Ambil notifikasi yang belum dibaca untuk role atau user tertentu
        $sql = "SELECT * FROM notifications 
                WHERE (target_role = ? OR target_user_id = ?) 
                AND is_read = 0 
                ORDER BY created_at DESC LIMIT 10";
        $stmt = $db->prepare($sql);
        $stmt->execute([$role, $userId]);
        $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(true, "Notifications retrieved", $notifications);
    } catch (Exception $e) {
        // Jika tabel belum ada, return array kosong
        sendResponse(true, "Notifications retrieved", []);
    }
}
?>