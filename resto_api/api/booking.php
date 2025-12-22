<?php
// api/booking.php - FIXED: DP as partial payment, not fully paid
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

    case 'complete_booking_payment':
        completeBookingPayment($db, $input);
        break;
        
    default:
        sendResponse(false, "Invalid action", null, 400);
}

// ==========================================
// 1. FUNGSI LOGIKA BOOKING - FIXED DP LOGIC
// ==========================================

function createBooking($db, $input) {
    if (empty($input['table_id']) || empty($input['date']) || empty($input['time'])) {
        sendResponse(false, "Data booking tidak lengkap");
    }

    // A. CEK MINIMUM DP MEJA
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

        // C. Insert ke Tabel BOOKINGS dengan down_payment
        $sql = "INSERT INTO bookings (booking_code, table_id, customer_name, customer_phone, booking_date, booking_time, guest_count, down_payment, status, notes, dp_paid) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'confirmed', ?, 1)";
        
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

        // D. FIXED: Insert ke ORDERS sebagai PARTIAL PAYMENT (Bukan Completed!)
        // Ini hanya mencatat DP, bukan transaksi final
        if ($inputDP > 0) {
            $orderNo = "DP-" . date("ymd") . "-" . $bookingId;
            $customerName = $input['customer_name'] . " (DP Booking #{$bookingCode})";
            $userId = $input['user_id'] ?? 0;

            // CHANGED: Status 'pending' dan payment_status 'partial' 
            // Artinya transaksi ini belum selesai, masih menunggu pelunasan
            $sqlOrder = "INSERT INTO orders (order_number, table_id, customer_name, subtotal, total_amount, payment_method, payment_status, status, created_at, cashier_id, notes) 
                         VALUES (?, ?, ?, ?, ?, 'transfer', 'partial', 'pending', NOW(), ?, ?)";
            
            $stmtOrder = $db->prepare($sqlOrder);
            $stmtOrder->execute([
                $orderNo,
                $input['table_id'],
                $customerName,
                $inputDP,
                $inputDP, // Total sementara = DP
                $userId,
                "DP Booking: $bookingCode. Sisa pembayaran saat checkout."
            ]);

            // Simpan order_id ke booking untuk referensi pelunasan nanti
            $orderId = $db->lastInsertId();
            $db->prepare("UPDATE bookings SET confirmed_by = ? WHERE id = ?")->execute([$orderId, $bookingId]);
        }

        // E. Update Status Meja (Hanya jika booking untuk HARI INI)
        $today = date('Y-m-d');
        if ($input['date'] == $today) {
            $db->prepare("UPDATE tables SET status = 'reserved' WHERE id = ?")->execute([$input['table_id']]);
        }

        // F. Log Activity
        if (function_exists('logActivity')) {
            logActivity($db, $input['user_id'] ?? 0, 'CREATE_BOOKING', "Booking $bookingCode dibuat. DP: Rp " . number_format($inputDP) . " (Belum Lunas)");
        }

        $db->commit();
        sendResponse(true, "Booking Berhasil! Kode: $bookingCode. Status: DP Diterima (Belum Lunas)", [
            'booking_code' => $bookingCode,
            'booking_id' => $bookingId,
            'dp_amount' => $inputDP,
            'payment_status' => 'partial'
        ]);

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Error Database: " . $e->getMessage());
    }
}

// ==========================================
// 2. FUNGSI PELUNASAN BOOKING (NEW!)
// ==========================================
function completeBookingPayment($db, $input) {
    $bookingId = $input['booking_id'] ?? 0;
    $additionalAmount = $input['additional_amount'] ?? 0;
    $paymentMethod = $input['payment_method'] ?? 'cash';
    $userId = $input['user_id'] ?? 0;

    if (empty($bookingId)) {
        sendResponse(false, "Booking ID diperlukan");
        return;
    }

    try {
        // Ambil data booking
        $stmt = $db->prepare("SELECT b.*, b.confirmed_by as order_id FROM bookings b WHERE b.id = ?");
        $stmt->execute([$bookingId]);
        $booking = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$booking) {
            sendResponse(false, "Booking tidak ditemukan");
            return;
        }

        $db->beginTransaction();

        // Update order yang ada (dari DP) menjadi completed
        if ($booking['order_id']) {
            $newTotal = $booking['down_payment'] + $additionalAmount;
            
            $updateOrder = $db->prepare("UPDATE orders SET 
                total_amount = ?, 
                payment_status = 'paid', 
                status = 'completed', 
                payment_method = ?,
                payment_time = NOW(),
                cashier_id = ?,
                notes = CONCAT(COALESCE(notes, ''), ' | Pelunasan: Rp " . number_format($additionalAmount) . "')
                WHERE id = ?");
            $updateOrder->execute([$newTotal, $paymentMethod, $userId, $booking['order_id']]);
        }

        // Update booking status
        $db->prepare("UPDATE bookings SET status = 'completed' WHERE id = ?")->execute([$bookingId]);

        // Log
        if (function_exists('logActivity')) {
            logActivity($db, $userId, 'COMPLETE_BOOKING_PAYMENT', "Pelunasan booking #{$booking['booking_code']}. Total: Rp " . number_format($booking['down_payment'] + $additionalAmount));
        }

        $db->commit();
        sendResponse(true, "Pembayaran booking berhasil dilunasi!", [
            'booking_code' => $booking['booking_code'],
            'total_paid' => $booking['down_payment'] + $additionalAmount
        ]);

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Error: " . $e->getMessage());
    }
}

// ==========================================
// 3. PEMBATALAN BOOKING (NO REFUND)
// ==========================================
function cancelBooking($db, $input) {
    $q = $db->prepare("SELECT table_id, customer_name, booking_date, confirmed_by as order_id FROM bookings WHERE id = ?");
    $q->execute([$input['booking_id']]);
    $book = $q->fetch(PDO::FETCH_ASSOC);

    if ($book) {
        // 1. Ubah Status Booking
        $db->prepare("UPDATE bookings SET status = 'cancelled' WHERE id = ?")->execute([$input['booking_id']]);
        
        // 2. Update order menjadi cancelled tapi uang tetap tercatat (hangus)
        if ($book['order_id']) {
            $db->prepare("UPDATE orders SET status = 'completed', notes = CONCAT(COALESCE(notes, ''), ' | CANCELLED - DP Hangus') WHERE id = ?")
               ->execute([$book['order_id']]);
        }
        
        // 3. Kosongkan Meja (Jika booking tanggal hari ini)
        if ($book['booking_date'] == date('Y-m-d')) {
            $db->prepare("UPDATE tables SET status = 'available' WHERE id = ?")->execute([$book['table_id']]);
        }
        
        // 4. Log
        if (function_exists('logActivity')) {
            logActivity($db, $input['user_id'] ?? 0, 'CANCEL_BOOKING', "Cancel booking a.n " . $book['customer_name'] . " (DP Hangus)");
        }
        
        sendResponse(true, "Booking Dibatalkan. DP Hangus. Meja Available.");
    } else {
        sendResponse(false, "Data booking tidak ditemukan");
    }
}

// ==========================================
// 4. FUNGSI PENDUKUNG LAINNYA
// ==========================================

function cleanUpExpiredBookings($db) {
    $sqlFind = "SELECT id, table_id, booking_code FROM bookings 
                WHERE status = 'confirmed' 
                AND CONCAT(booking_date, ' ', booking_time) < DATE_SUB(NOW(), INTERVAL 1 HOUR)";
    
    $stmt = $db->prepare($sqlFind);
    $stmt->execute();
    $expiredBookings = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($expiredBookings) > 0) {
        foreach ($expiredBookings as $booking) {
            $db->prepare("UPDATE bookings SET status = 'cancelled', notes = CONCAT(COALESCE(notes, ''), ' [Auto-Cancel by System]') WHERE id = ?")
               ->execute([$booking['id']]);
            
            $db->prepare("UPDATE tables SET status = 'available' WHERE id = ?")
               ->execute([$booking['table_id']]);
               
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

        $stmt = $db->prepare("UPDATE bookings SET status = 'checked_in', check_in_time = NOW() WHERE id = ?");
        $stmt->execute([$input['booking_id']]);

        $getInfo = $db->prepare("SELECT table_id, booking_code FROM bookings WHERE id = ?");
        $getInfo->execute([$input['booking_id']]);
        $info = $getInfo->fetch(PDO::FETCH_ASSOC);

        if ($info) {
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
    
    // FIXED: Total Revenue hanya dari order COMPLETED dan PAID
    // Tidak termasuk partial payment (DP yang belum lunas)
    $qTotal = "SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = ? AND status = 'completed' AND payment_status = 'paid'";
    $stmt = $db->prepare($qTotal);
    $stmt->execute([$today]);
    $totalRevenue = $stmt->fetchColumn();

    // Hitung Order & Booking
    $totalOrders = $db->query("SELECT COUNT(*) FROM orders WHERE DATE(created_at) = '$today' AND status = 'completed'")->fetchColumn();
    $totalBookings = $db->query("SELECT COUNT(*) FROM bookings WHERE booking_date = '$today' AND status != 'cancelled'")->fetchColumn();
    $lowStock = $db->query("SELECT COUNT(*) FROM menu_items WHERE stock <= 5 AND is_available = 1")->fetchColumn();
    $pendingOrders = $db->query("SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'cooking')")->fetchColumn();

    // Pending DP (booking dengan pembayaran partial)
    $pendingDP = $db->query("SELECT COUNT(*) FROM orders WHERE payment_status = 'partial' AND status = 'pending'")->fetchColumn();

    $data = [
        'total_revenue' => $totalRevenue,
        'total_orders' => $totalOrders,
        'today_bookings' => $totalBookings,
        'low_stock_count' => $lowStock,
        'pending_orders' => $pendingOrders,
        'pending_dp' => $pendingDP
    ];

    sendResponse(true, "Success", $data);
}

function getBookings($db) {
    $date = $_GET['date'] ?? date('Y-m-d');
    $sql = "SELECT b.*, t.table_number,
            CASE 
                WHEN b.dp_paid = 1 AND EXISTS(SELECT 1 FROM orders o WHERE o.id = b.confirmed_by AND o.payment_status = 'partial') THEN 'DP Diterima'
                WHEN b.dp_paid = 1 AND EXISTS(SELECT 1 FROM orders o WHERE o.id = b.confirmed_by AND o.payment_status = 'paid') THEN 'Lunas'
                ELSE 'Belum Bayar'
            END as payment_info
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