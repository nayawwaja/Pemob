<?php
require_once '../config/database.php';
$db = (new Database())->getConnection();

if (!function_exists('sendResponse')) {
    // Helper untuk mengirim response JSON
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
    default:
        sendResponse(false, "Invalid action for staff API", null, 400);
}

/**
 * --- FUNGSI UTAMA ---
 * Fungsi ini mengambil semua data pengguna yang bukan 'admin'.
 * Inilah yang menyediakan data untuk layar Manajemen SDM.
 */
function getAllStaff($db) {
    try {
        // Ambil semua user yang role-nya BUKAN 'admin'
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
        // Ambil hanya kode yang belum terpakai
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
    // Buat kode yang lebih mudah dibaca
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
        // Pengaman: tidak bisa menonaktifkan akun admin
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
        // Ambil 20 log aktivitas terakhir
        // Pastikan tabel activity_logs ada. Jika belum, buat tabelnya.
        // Struktur: id, user_id, action_type, description, created_at
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
        // Jika tabel belum ada, return array kosong agar tidak error di app
        sendResponse(true, "No logs (Table might be missing)", []);
    }
}

function getNotifications($db) {
    // Placeholder untuk notifikasi
    // Di sistem nyata, ini mengambil dari tabel notifications berdasarkan role/user_id
    $role = $_GET['role'] ?? '';
    $userId = $_GET['user_id'] ?? 0;
    
    // Return array kosong untuk saat ini agar tidak error 400
    sendResponse(true, "Notifications retrieved", []);
}
?>