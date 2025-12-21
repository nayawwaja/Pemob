<?php
// api/tables.php - SMART STATUS UPDATE & RESERVATION SYNC
require_once '../utils/helpers.php';
require_once '../config/database.php';
$database = new Database();
$db = $database->getConnection();

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

switch($action) {
    case 'get_tables': // Dipakai oleh CartScreen & BookingScreen
    case 'get_all':    // Dipakai oleh WaiterScreen (Denah)
        getTables($db);
        break;
        
    case 'update_status':
        updateTableStatus($db, $input);
        break;
        
    default:
        sendResponse(false, "Invalid action: $action", null, 400);
}

function getTables($db) {
    try {
        // Ambil data meja + Nama Tamu (jika sedang makan) + Min DP
        $sql = "SELECT t.*, 
                (SELECT customer_name FROM orders WHERE id = t.current_order_id LIMIT 1) as guest_name
                FROM tables t 
                ORDER BY t.table_number ASC";
                
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $tables = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // FIX TIPE DATA (PENTING UNTUK FLUTTER)
        foreach ($tables as &$t) {
            $t['id'] = (int)$t['id'];
            $t['capacity'] = (int)$t['capacity'];
            $t['min_dp'] = isset($t['min_dp']) ? (double)$t['min_dp'] : 0.0;
            $t['status'] = strtolower($t['status']); 

            // LOGIKA BARU: Cek reservasi dalam 1 jam ke depan
            // Jika meja kosong, cek apakah ada reservasi yang akan mulai.
            // Ini membuat status 'reserved' dinamis tanpa cron job.
            if ($t['status'] == 'available') {
                $now = new DateTime();
                $oneHourLater = (new DateTime())->add(new DateInterval('PT1H'));

                $bookingSql = "SELECT id FROM bookings 
                               WHERE table_id = ? 
                               AND status = 'confirmed' 
                               AND booking_date = CURDATE() 
                               AND booking_time BETWEEN ? AND ? 
                               LIMIT 1";
                               
                $bookingStmt = $db->prepare($bookingSql);
                $bookingStmt->execute([
                    $t['id'], 
                    $now->format('H:i:s'), 
                    $oneHourLater->format('H:i:s')
                ]);

                // Jika ditemukan booking dalam 1 jam, ubah statusnya di response jadi 'reserved'
                if ($bookingStmt->rowCount() > 0) {
                    $t['status'] = 'reserved';
                }
            }
        }
        
        sendResponse(true, "Success", $tables);
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage());
    }
}

function updateTableStatus($db, $input) {
    // Flow Manual Update: 
    // Jika Waiter/CS ubah status manual di denah, Reservasi harus ikut update statusnya
    // agar tidak 'menggantung' atau dianggap batal.

    if (empty($input['id']) || empty($input['status'])) {
        sendResponse(false, "Data ID/Status tidak lengkap");
    }

    $status = $input['status'];
    $id = $input['id'];
    $userId = $input['user_id'] ?? 0;
    $today = date('Y-m-d');

    try {
        $db->beginTransaction();

        // 1. Update Status Meja di Database
        $stmt = $db->prepare("UPDATE tables SET status = ? WHERE id = ?");
        $stmt->execute([$status, $id]);

        // 2. LOGIKA PINTAR: Sinkronisasi Status Booking
        if ($status == 'occupied') {
            // Skenario: Tamu Reservasi datang, Staff ubah status meja jadi "Terisi" manual (tanpa scan QR)
            // Aksi: Cari booking 'confirmed' di meja ini hari ini -> Ubah jadi 'checked_in'
            $sql = "UPDATE bookings SET status = 'checked_in', check_in_time = NOW() 
                    WHERE table_id = ? AND booking_date = ? AND status = 'confirmed'";
            $db->prepare($sql)->execute([$id, $today]);
        } 
        else if ($status == 'available') {
            // Skenario: Tamu pulang, Staff ubah status meja jadi "Kosong"
            // Aksi: Cari booking 'checked_in' di meja ini hari ini -> Ubah jadi 'completed'
            $sql = "UPDATE bookings SET status = 'completed' 
                    WHERE table_id = ? AND booking_date = ? AND status = 'checked_in'";
            $db->prepare($sql)->execute([$id, $today]);
            
            // Bersihkan current_order_id di meja jika ada
            $db->prepare("UPDATE tables SET current_order_id = NULL WHERE id = ?")->execute([$id]);
        }

        // 3. Catat Log Aktivitas
        if ($userId != 0 && function_exists('logActivity')) {
            logActivity($db, $userId, 'UPDATE_TABLE', "Ubah status meja ID $id jadi $status");
        }

        $db->commit();
        sendResponse(true, "Status meja berhasil diubah & Reservasi disinkronisasi");

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Gagal update database: " . $e->getMessage());
    }
}
?>