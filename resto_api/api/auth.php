<?php
require_once '../utils/helpers.php';
require_once '../config/database.php';
$db = (new Database())->getConnection();

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

switch($action) {
    case 'login':
        login($db, $input);
        break;
    case 'register':
        register($db, $input);
        break;
    case 'get_profile': // Untuk refresh data user di app
        getProfile($db, $_GET['id'] ?? 0);
        break;
    default:
        sendResponse(false, "Invalid action", null, 400);
}

function login($db, $input) {
    if (!isset($input['email'], $input['password'])) {
        sendResponse(false, "Email dan password wajib diisi", null, 400);
    }

    // 1. Ambil user berdasarkan email saja
    $stmt = $db->prepare("SELECT * FROM users WHERE LOWER(email) = LOWER(?)");
    $stmt->execute([$input['email']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // 2. Jika user ada DAN password cocok (menggunakan password_verify untuk Bcrypt)
    if ($user && password_verify($input['password'], $user['password'])) {
        if ($user['is_active'] == 0) {
            sendResponse(false, "Akun dinonaktifkan. Hubungi Admin.", null, 403);
        }
        
        // Update FCM Token jika dikirim (untuk notifikasi HP nanti)
        if (isset($input['fcm_token'])) {
            $upd = $db->prepare("UPDATE users SET fcm_token = ? WHERE id = ?");
            $upd->execute([$input['fcm_token'], $user['id']]);
        }

        // Token Sederhana (ID_MD5(Waktu))
        $token = $user['id'] . "_" . md5(time() . $user['email']);
        
        // Hapus password dari response
        unset($user['password']);
        unset($user['fcm_token']);

        logActivity($db, $user['id'], 'LOGIN', 'User logged in');
        sendResponse(true, "Login berhasil", ["user" => $user, "token" => $token]);
    } else {
        // Jika user tidak ditemukan atau password salah
        sendResponse(false, "Email atau password salah", null, 401);
    }
}

function register($db, $input) {
    // Validasi input
    if (empty($input['name']) || empty($input['email']) || empty($input['password']) || empty($input['role'])) {
        sendResponse(false, "Data tidak lengkap", null, 400);
    }

    $role = $input['role'];

    // LOGIKA BARU: Jika bukan Admin, WAJIB punya Staff Code yang valid
    if ($role != 'admin') {
        if (empty($input['staff_code'])) {
            sendResponse(false, "Kode Staff wajib diisi!", null, 400);
        }

        // Cek Kode di Database
        $stmtCode = $db->prepare("SELECT * FROM staff_access_codes WHERE code = ? AND is_used = 0 AND target_role = ?");
        $stmtCode->execute([$input['staff_code'], $role]);
        $validCode = $stmtCode->fetch(PDO::FETCH_ASSOC);

        if (!$validCode) {
            sendResponse(false, "Kode Staff salah, sudah terpakai, atau tidak sesuai role!", null, 403);
        }
    } else {
        // Mencegah register admin sembarangan lewat API (Hanya bisa lewat database langsung utk keamanan super admin)
        sendResponse(false, "Pendaftaran Admin ditutup. Hubungi IT.", null, 403);
    }

    // Cek Email Duplikat
    $check = $db->prepare("SELECT id FROM users WHERE email = ?");
    $check->execute([$input['email']]);
    if ($check->rowCount() > 0) {
        sendResponse(false, "Email sudah terdaftar", null, 409);
    }

    try {
        $db->beginTransaction();

        // Insert User
        $sql = "INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, ?)";
        $stmt = $db->prepare($sql);
        // Gunakan password_hash() untuk keamanan, sesuai standar modern dan DB
        $hashedPassword = password_hash($input['password'], PASSWORD_BCRYPT);
        $stmt->execute([
            $input['name'], 
            $input['email'], 
            $hashedPassword, 
            $input['phone'] ?? '', 
            $role
        ]);
        $newUserId = $db->lastInsertId();

        // Tandai Kode sudah dipakai
        if ($role != 'admin') {
            $updCode = $db->prepare("UPDATE staff_access_codes SET is_used = 1, used_by_user_id = ? WHERE id = ?");
            $updCode->execute([$newUserId, $validCode['id']]);
        }

        $db->commit();
        sendResponse(true, "Registrasi berhasil. Silakan Login.");

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Gagal register: " . $e->getMessage(), null, 500);
    }
}

function getProfile($db, $id) {
    $stmt = $db->prepare("SELECT id, name, email, role, phone FROM users WHERE id = ?");
    $stmt->execute([$id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($user) sendResponse(true, "Success", $user);
    else sendResponse(false, "User not found", null, 404);
}
?>