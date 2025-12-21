<?php
// api/booking.php - ULTIMATE (Min DP Check, Auto Transaction, No Refund)
require_once '../utils/helpers.php';
require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

// --- 1. JALANKAN AUTO CLEANUP (Hapus booking gantung > 1 jam) ---
cleanUpExpiredBookings($db);

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

switch($action) {
    case 'create_booking':
        createBooking($db, $input);
        break;
        
    case 'verify_booking':
        verifyBookingCode($db, $input);
        break;
        
    case 'check_in':
        checkInGuest($db, $input);
        break;
        
    case 'get_tables_status':
        getTablesStatus($db);
        break;
        
    case 'get_bookings':
        getBookings($db);
        break;
        
    case 'cancel_booking':
        cancelBooking($db, $input);
        break;
        
    case 'get_dashboard_stats':
        getDashboardStats($db);
        break;
        
    case 'get_tables':
        getTables($db);
        break;
        
    default:
        sendResponse(false, "Invalid action", null, 400);
}

// ==========================================
// 1. FUNGSI LOGIKA BOOKING CANGGIH
// ==========================================

function createBooking($db, $input) {
    if (empty($input['table_id']) || empty($input['date']) || empty($input['time'])) {
        sendResponse(false, "Data booking tidak lengkap");
    }

    // A. CEK MINIMUM DP MEJA
    // Pastikan kolom min_dp sudah dibuat di database (ALTER TABLE tables ADD min_dp DECIMAL(10,2) DEFAULT 0;)
    $tmt = $db->prepare("SELECT min_dp, table_number FROM tables WHERE id = ?");
    $tmt->execute([$input['table_id']]);
    $table = $tmt->fetch(PDO::FETCH_ASSOC);

    $inputDP = $input['down_payment'] ?? 0;
    
    // Validasi DP
    if ($table && $inputDP < $table['min_dp']) {
        sendResponse(false, "DP Kurang! Minimum DP untuk Meja {$table['table_number']} adalah Rp " . number_format($table['min_dp']));
        return;
    }

    // B. Cek Bentrok Jadwal
    $check = $db->prepare("SELECT id FROM bookings WHERE table_id = ? AND booking_date = ? AND status IN ('confirmed', 'checked_in')");
    $check->execute([$input['table_id'], $input['date']]);
    if ($check->rowCount() > 0) {
        sendResponse(false, "Meja ini sudah penuh di tanggal tersebut!");
        return;
    }

    try {
        $db->beginTransaction();
        $bookingCode = "RES-" . rand(1000, 9999);

        // C. Insert ke Tabel BOOKINGS
        $sql = "INSERT INTO bookings (booking_code, table_id, customer_name, customer_phone, booking_date, booking_time, guest_count, down_payment, status, notes) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'confirmed', ?)";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([
            $bookingCode,
            $input['table_id'],
            $input['customer_name'],
            $input['customer_phone'],
            $input['date'],
            $input['time'],
            $input['guest_count'],
            $inputDP,
            $input['notes'] ?? ''
        ]);
        
        $bookingId = $db->lastInsertId();

        // D. OTOMATIS INSERT KE TABEL ORDERS (Agar Uang Masuk Laporan & Riwayat Transaksi)
        // Kita anggap ini adalah transaksi "Deposit" yang sudah lunas (Paid)
        if ($inputDP > 0) {
            $orderNo = "DP-" . date("ymd") . "-" . $bookingId;
            $customerName = $input['customer_name'] . " (Deposit Booking)";
            $userId = $input['user_id'] ?? 0; // ID Staff yang memproses

            // Simpan sebagai 'completed' order agar uangnya dihitung di laporan
            $sqlOrder = "INSERT INTO orders (order_number, table_id, customer_name, total_amount, payment_method, payment_status, status, created_at, payment_time, cashier_id) 
                         VALUES (?, ?, ?, ?, 'transfer', 'paid', 'completed', NOW(), NOW(), ?)";
            
            $stmtOrder = $db->prepare($sqlOrder);
            $stmtOrder->execute([
                $orderNo,
                $input['table_id'],
                $customerName,
                $inputDP, // Nominal DP masuk sebagai total_amount order
                $userId
            ]);
        }

        // E. Update Status Meja (Hanya jika booking untuk HARI INI)
        $today = date('Y-m-d');
        if ($input['date'] == $today) {
            $db->prepare("UPDATE tables SET status = 'reserved' WHERE id = ?")->execute([$input['table_id']]);
        }

        // F. Log Activity
        if (function_exists('logActivity')) {
            logActivity($db, $input['user_id'] ?? 0, 'CREATE_BOOKING', "Booking $bookingCode dibuat. DP: Rp " . number_format($inputDP));
        }

        $db->commit();
        sendResponse(true, "Booking Berhasil! Kode: $bookingCode", ['booking_code' => $bookingCode]);

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Error Database: " . $e->getMessage());
    }
}

// ==========================================
// 2. PEMBATALAN BOOKING (NO REFUND)
// ==========================================
function cancelBooking($db, $input) {
    // Logika: Hanya ubah status booking jadi 'cancelled'.
    // JANGAN hapus data di tabel 'orders' agar uang DP tetap tercatat sebagai pemasukan (Hangus).

    $q = $db->prepare("SELECT table_id, customer_name, booking_date FROM bookings WHERE id = ?");
    $q->execute([$input['booking_id']]);
    $book = $q->fetch(PDO::FETCH_ASSOC);

    if ($book) {
        // 1. Ubah Status Booking
        $db->prepare("UPDATE bookings SET status = 'cancelled' WHERE id = ?")->execute([$input['booking_id']]);
        
        // 2. Kosongkan Meja (Jika booking tanggal hari ini)
        if ($book['booking_date'] == date('Y-m-d')) {
            $db->prepare("UPDATE tables SET status = 'available' WHERE id = ?")->execute([$book['table_id']]);
        }
        
        // 3. Log
        if (function_exists('logActivity')) {
            logActivity($db, $input['user_id'] ?? 0, 'CANCEL_BOOKING', "Cancel booking a.n " . $book['customer_name'] . " (DP Hangus)");
        }
        
        sendResponse(true, "Booking Dibatalkan. Meja Available.");
    } else {
        sendResponse(false, "Data booking tidak ditemukan");
    }
}

// ==========================================
// 3. FUNGSI PENDUKUNG LAINNYA
// ==========================================

function cleanUpExpiredBookings($db) {
    // Cari booking yang statusnya masih 'confirmed' tapi jamnya sudah lewat 1 jam
    $sqlFind = "SELECT id, table_id, booking_code FROM bookings 
                WHERE status = 'confirmed' 
                AND CONCAT(booking_date, ' ', booking_time) < DATE_SUB(NOW(), INTERVAL 1 HOUR)";
    
    $stmt = $db->prepare($sqlFind);
    $stmt->execute();
    $expiredBookings = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($expiredBookings) > 0) {
        foreach ($expiredBookings as $booking) {
            // Ubah jadi cancelled (Auto)
            $db->prepare("UPDATE bookings SET status = 'cancelled', notes = CONCAT(notes, ' [Auto-Cancel by System]') WHERE id = ?")
               ->execute([$booking['id']]);
            
            // Meja jadi available
            $db->prepare("UPDATE tables SET status = 'available' WHERE id = ?")
               ->execute([$booking['table_id']]);
               
            // Log System
            if (function_exists('logActivity')) {
                logActivity($db, 0, 'SYSTEM_AUTO_CANCEL', "Booking {$booking['booking_code']} hangus otomatis.");
            }
        }
    }
}

function verifyBookingCode($db, $input) {
    $code = $input['booking_code'] ?? '';
    
    $stmt = $db->prepare("SELECT b.*, t.table_number 
                          FROM bookings b 
                          JOIN tables t ON b.table_id = t.id 
                          WHERE b.booking_code = ? AND b.status = 'confirmed'");
    $stmt->execute([$code]);
    $booking = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($booking) {
        $today = date('Y-m-d');
        if ($booking['booking_date'] != $today) {
            sendResponse(false, "Booking ini untuk tanggal " . $booking['booking_date'] . " (Bukan Hari Ini)");
        } else {
            sendResponse(true, "Kode Valid! Tamu a.n " . $booking['customer_name'], $booking);
        }
    } else {
        sendResponse(false, "Kode Booking Tidak Ditemukan atau Sudah Check-in/Batal.");
    }
}

function checkInGuest($db, $input) {
    if (empty($input['booking_id'])) sendResponse(false, "ID Booking Missing");

    try {
        $db->beginTransaction();

        // Update status booking
        $stmt = $db->prepare("UPDATE bookings SET status = 'checked_in', check_in_time = NOW() WHERE id = ?");
        $stmt->execute([$input['booking_id']]);

        // Ambil info meja untuk diupdate
        $getInfo = $db->prepare("SELECT table_id, booking_code FROM bookings WHERE id = ?");
        $getInfo->execute([$input['booking_id']]);
        $info = $getInfo->fetch(PDO::FETCH_ASSOC);

        if ($info) {
            // Update status meja jadi OCCUPIED
            $db->prepare("UPDATE tables SET status = 'occupied' WHERE id = ?")->execute([$info['table_id']]);
        }

        if (function_exists('logActivity')) {
            logActivity($db, $input['user_id'] ?? 0, 'CHECK_IN', "Tamu Check-in Kode: " . $info['booking_code']);
        }

        $db->commit();
        sendResponse(true, "Tamu Berhasil Check-in. Meja Terisi.");

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Error: " . $e->getMessage());
    }
}

function getTablesStatus($db) {
    $today = date('Y-m-d');
    
    $query = "SELECT t.*, 
              (SELECT customer_name FROM bookings b WHERE b.table_id = t.id AND b.booking_date = '$today' AND b.status IN ('confirmed','checked_in') LIMIT 1) as guest_name,
              (SELECT booking_code FROM bookings b WHERE b.table_id = t.id AND b.booking_date = '$today' AND b.status IN ('confirmed','checked_in') LIMIT 1) as code
              FROM tables t ORDER BY t.table_number";
              
    $stmt = $db->prepare($query);
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($data as &$row) {
        $row['capacity'] = (int)$row['capacity'];
        if ($row['guest_name']) {
            $row['is_booked'] = true;
        } else {
            $row['is_booked'] = false;
        }
    }
    
    sendResponse(true, "Success", $data);
}

function getDashboardStats($db) {
    $today = date('Y-m-d');
    
    // Total Revenue (Order Biasa + DP Booking yang sudah masuk tabel orders)
    // Karena DP sekarang dimasukkan ke tabel 'orders' saat createBooking,
    // kita cukup sum tabel orders saja.
    $qTotal = "SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = ? AND status = 'completed'";
    $stmt = $db->prepare($qTotal);
    $stmt->execute([$today]);
    $totalRevenue = $stmt->fetchColumn();

    // Hitung Order & Booking
    $totalOrders = $db->query("SELECT COUNT(*) FROM orders WHERE DATE(created_at) = '$today'")->fetchColumn();
    $totalBookings = $db->query("SELECT COUNT(*) FROM bookings WHERE booking_date = '$today' AND status != 'cancelled'")->fetchColumn();
    $lowStock = $db->query("SELECT COUNT(*) FROM menu_items WHERE stock <= 5 AND is_active = 1")->fetchColumn();
    $pendingOrders = $db->query("SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'cooking')")->fetchColumn();

    $data = [
        'total_revenue' => $totalRevenue,
        'total_orders' => $totalOrders,
        'today_bookings' => $totalBookings,
        'low_stock_count' => $lowStock,
        'pending_orders' => $pendingOrders
    ];

    sendResponse(true, "Success", $data);
}

function getBookings($db) {
    $date = $_GET['date'] ?? date('Y-m-d');
    $sql = "SELECT b.*, t.table_number 
            FROM bookings b 
            JOIN tables t ON b.table_id = t.id 
            WHERE b.booking_date = ? AND b.status != 'cancelled' 
            ORDER BY b.booking_time ASC";
    $stmt = $db->prepare($sql);
    $stmt->execute([$date]);
    sendResponse(true, "Success", $stmt->fetchAll(PDO::FETCH_ASSOC));
}

function getTables($db) {
    $stmt = $db->query("SELECT * FROM tables ORDER BY table_number");
    sendResponse(true, "Success", $stmt->fetchAll(PDO::FETCH_ASSOC));
}
?>