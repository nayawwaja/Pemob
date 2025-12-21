<?php
// api/orders.php - FIXED VERSION
// Changelog:
// - Fixed input sanitization
// - Fixed JSON validation
// - Fixed null check exceptions
// - Fixed merge logic for additional orders
// - Fixed N+1 query problem
// - Fixed SQL injection vulnerabilities
// - Improved order number generation

require_once '../utils/helpers.php';
require_once '../config/database.php';
$database = new Database();
$db = $database->getConnection();

// FIXED: Sanitize action input
$action = isset($_GET['action']) ? preg_replace('/[^a-z_]/', '', $_GET['action']) : '';

// FIXED: Validate JSON input with error handling
$rawInput = file_get_contents('php://input');
$input = [];
if (!empty($rawInput)) {
    $input = json_decode($rawInput, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        sendResponse(false, "Invalid JSON input: " . json_last_error_msg(), null, 400);
    }
}

switch($action) {
    case 'create_order':
        createOrder($db, $input);
        break;
        
    case 'get_order_detail':
        $orderId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        getOrderDetail($db, $orderId);
        break;
        
    case 'get_orders_by_role': 
        $role = isset($_GET['role']) ? preg_replace('/[^a-z_]/', '', $_GET['role']) : '';
        $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
        getOrdersByRole($db, $role, $userId);
        break;
        
    case 'update_status':
        updateOrderStatus($db, $input);
        break;

    case 'cancel_order':
        cancelOrder($db, $input);
        break;

    case 'process_payment':
        processPayment($db, $input);
        break;

    case 'make_payment':
        makePayment($db, $input);
        break;

    case 'get_sales_chart':
        getSalesChart($db);
        break;

    case 'get_business_report':
        getBusinessReport($db, $input);
        break;

    case 'get_transactions_by_order':
        $orderId = isset($_GET['order_id']) ? (int)$_GET['order_id'] : 0;
        getTransactionsByOrder($db, $orderId);
        break;

    case 'link_customer':
        linkCustomerToOrder($db, $input);
        break;
        
    case 'check_payment_eligibility':
        $orderId = isset($_GET['order_id']) ? (int)$_GET['order_id'] : 0;
        checkPaymentEligibility($db, $orderId);
        break;
    
    case 'get_booking_by_table':
        $tableId = isset($_GET['table_id']) ? (int)$_GET['table_id'] : 0;
        $date = isset($_GET['date']) ? preg_replace('/[^0-9\-]/', '', $_GET['date']) : '';
        getBookingByTable($db, $tableId, $date);
        break;

    default:
        sendResponse(false, "Invalid action", null, 400);
}


// ==========================================
// 1. BUAT ORDER - FIXED VERSION
// ==========================================
function createOrder($db, $input) {
    // FIXED: Comprehensive validation
    if (!isset($input['items']) || !is_array($input['items']) || empty($input['items'])) {
        sendResponse(false, "Pilih menu terlebih dahulu!", null, 400);
        return;
    }
    if (empty($input['table_id'])) {
        sendResponse(false, "Pilih meja terlebih dahulu!", null, 400);
        return;
    }

    $tableId = (int)$input['table_id'];
    $userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;

    // Check table status
    $tableStmt = $db->prepare("SELECT status, current_order_id, table_number FROM tables WHERE id = ?");
    $tableStmt->execute([$tableId]);
    $table = $tableStmt->fetch(PDO::FETCH_ASSOC);

    if (!$table) {
        sendResponse(false, "Meja tidak ditemukan.", null, 404);
        return;
    }

    if ($table['status'] == 'dirty') {
        sendResponse(false, "Meja ini kotor dan harus dibersihkan terlebih dahulu.", null, 403);
        return;
    }

    try {
        $db->beginTransaction();

        $orderId = null;
        $isNewOrder = false;
        
        // Check for existing active order on this table
        $orderStmt = $db->prepare("
            SELECT id, status, order_number 
            FROM orders 
            WHERE table_id = ? AND status NOT IN ('completed', 'cancelled') 
            ORDER BY created_at DESC 
            LIMIT 1
        ");
        $orderStmt->execute([$tableId]);
        $existingOrder = $orderStmt->fetch(PDO::FETCH_ASSOC);

        if ($existingOrder) {
            // MERGE: Add items to existing order
            $orderId = $existingOrder['id'];
            $message = "Pesanan tambahan berhasil ditambahkan!";
            
            // FIXED: JANGAN ubah status order ke 'cooking' langsung
            // Item baru akan punya status 'pending' sendiri
            // Chef akan melihat item pending dari order ini
            
        } else {
            // CREATE new order
            $isNewOrder = true;
            
            // FIXED: Better order number generation (less collision)
            $orderNo = "ORD-" . date("ymdHis") . "-" . $tableId . "-" . rand(100, 999);
            
            $sql = "INSERT INTO orders (order_number, table_id, customer_name, waiter_id, total_amount, status, created_at) 
                    VALUES (?, ?, ?, ?, 0, 'pending', NOW())";
            $stmt = $db->prepare($sql);
            $stmt->execute([
                $orderNo,
                $tableId,
                $input['customer_name'] ?? 'Guest',
                $userId
            ]);
            $orderId = $db->lastInsertId();
            $message = "Pesanan Baru Berhasil Dibuat!";

            // Update table status
            $db->prepare("UPDATE tables SET status = 'occupied', current_order_id = ? WHERE id = ?")
               ->execute([$orderId, $tableId]);
            
            if (function_exists('logActivity')) {
                logActivity($db, $userId, 'CREATE_ORDER', "Order baru $orderNo (Meja {$table['table_number']})");
            }
        }
        
        // Process order items
        $newItemsTotal = 0;
        $sqlItem = "INSERT INTO order_items (order_id, menu_item_id, quantity, price, notes, status) 
                    VALUES (?, ?, ?, ?, ?, 'pending')";
        $stmtItem = $db->prepare($sqlItem);
        
        $newItemNames = [];

        foreach ($input['items'] as $item) {
            // FIXED: Validate item structure
            if (!isset($item['id']) || !isset($item['quantity'])) {
                throw new Exception("Format item tidak valid!");
            }
            
            $itemId = (int)$item['id'];
            $itemQty = (int)$item['quantity'];
            
            if ($itemQty <= 0) {
                throw new Exception("Jumlah item harus lebih dari 0!");
            }
            
            $menuStmt = $db->prepare("SELECT price, stock, name FROM menu_items WHERE id = ? FOR UPDATE");
            $menuStmt->execute([$itemId]);
            $menu = $menuStmt->fetch(PDO::FETCH_ASSOC);
            
            // FIXED: Null check before accessing properties
            if (!$menu) {
                throw new Exception("Menu dengan ID $itemId tidak ditemukan!");
            }
            
            if ($menu['stock'] < $itemQty) {
                throw new Exception("Stok '{$menu['name']}' tidak cukup! Tersisa: {$menu['stock']}");
            }
            
            $itemPrice = (float)$menu['price'];
            $newItemsTotal += ($itemPrice * $itemQty);
            
            // Deduct stock
            $db->prepare("UPDATE menu_items SET stock = stock - ? WHERE id = ?")
               ->execute([$itemQty, $itemId]);

            // Insert item with pending status
            $stmtItem->execute([
                $orderId, 
                $itemId, 
                $itemQty, 
                $itemPrice, 
                $item['notes'] ?? ''
            ]);
            
            $newItemNames[] = $menu['name'];
        }

        // Recalculate order totals
        $recalcStmt = $db->prepare("
            SELECT COALESCE(SUM(oi.quantity * oi.price), 0) 
            FROM order_items oi 
            WHERE oi.order_id = ?
        ");
        $recalcStmt->execute([$orderId]);
        $subtotal = (float)$recalcStmt->fetchColumn();
        
        // Get tax and service rates from settings
        $taxRate = 0.10;
        $serviceRate = 0.05;
        
        try {
            $settingsStmt = $db->query("SELECT key_name, value FROM settings WHERE key_name IN ('tax_percentage', 'service_charge_percentage')");
            while($setting = $settingsStmt->fetch(PDO::FETCH_ASSOC)) {
                if ($setting['key_name'] == 'tax_percentage') {
                    $taxRate = floatval($setting['value']) / 100;
                } else if ($setting['key_name'] == 'service_charge_percentage') {
                    $serviceRate = floatval($setting['value']) / 100;
                }
            }
        } catch(Exception $e) { 
            // Use defaults, but log error
            error_log("Failed to fetch settings: " . $e->getMessage());
        }
        
        $tax = $subtotal * $taxRate;
        $service = $subtotal * $serviceRate;
        $grandTotal = $subtotal + $tax + $service;

        $updateOrderSql = "UPDATE orders SET subtotal = ?, tax = ?, service_charge = ?, total_amount = ? WHERE id = ?";
        $db->prepare($updateOrderSql)->execute([$subtotal, $tax, $service, $grandTotal, $orderId]);

        // FIXED: Send notification for new/additional items
        if (function_exists('createNotification')) {
            $itemList = implode(', ', array_slice($newItemNames, 0, 3));
            if (count($newItemNames) > 3) $itemList .= ' +' . (count($newItemNames) - 3) . ' lainnya';
            
            $notifTitle = $isNewOrder ? 'Pesanan Baru' : 'Pesanan Tambahan';
            createNotification($db, 'chef', $notifTitle, "Meja {$table['table_number']}: $itemList");
        }

        $db->commit();
        sendResponse(true, $message, ['order_id' => $orderId]);

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Gagal Order: " . $e->getMessage(), null, 500);
    }
}

// ==========================================
// 2. GET ORDER DETAIL - FIXED
// ==========================================
function getOrderDetail($db, $orderId) {
    if ($orderId <= 0) {
        sendResponse(false, "Order ID tidak valid", null, 400);
        return;
    }

    try {
        // Get order details with table info
        $sql = "SELECT o.*, t.table_number, 
                COALESCE(c.name, o.customer_name) as customer_name, 
                c.phone as customer_phone
                FROM orders o 
                LEFT JOIN tables t ON o.table_id = t.id 
                LEFT JOIN customers c ON o.customer_id = c.id
                WHERE o.id = ?";
        $stmt = $db->prepare($sql);
        $stmt->execute([$orderId]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) {
            sendResponse(false, "Order tidak ditemukan", null, 404);
            return;
        }
        
        // Get items with individual status
        $sql_items = "SELECT oi.*, mi.name, mi.image_url, oi.status as item_status
                      FROM order_items oi 
                      JOIN menu_items mi ON oi.menu_item_id = mi.id 
                      WHERE oi.order_id = ?";
        $stmt_items = $db->prepare($sql_items);
        $stmt_items->execute([$orderId]);
        $items = $stmt_items->fetchAll(PDO::FETCH_ASSOC);

        // Format items with proper status
        foreach($items as &$item) {
            $item['status'] = $item['item_status'] ?? 'pending';
            $item['id'] = (int)$item['id'];
            $item['quantity'] = (int)$item['quantity'];
            $item['price'] = (float)$item['price'];
            unset($item['item_status']);
        }
        unset($item); // FIXED: Unset reference

        $order['items'] = $items;
        
        // Ensure proper types for Flutter
        $order['id'] = (int)$order['id'];
        $order['table_id'] = (int)$order['table_id'];
        $order['subtotal'] = (float)($order['subtotal'] ?? 0);
        $order['tax'] = (float)($order['tax'] ?? 0);
        $order['service_charge'] = (float)($order['service_charge'] ?? 0);
        $order['total_amount'] = (float)($order['total_amount'] ?? 0);
        
        if (isset($order['customer_id']) && $order['customer_id']) {
            $order['customer_id'] = (int)$order['customer_id'];
        } else {
            $order['customer_id'] = null;
        }

        sendResponse(true, "Success", $order);

    } catch (Exception $e) {
        sendResponse(false, "API Error: " . $e->getMessage(), null, 500);
    }
}

// ==========================================
// 3. GET ORDERS BY ROLE - FIXED
// ==========================================
function getOrdersByRole($db, $role, $userId) {
    // FIXED: Use parameterized queries and proper role validation
    $allowedRoles = ['chef', 'waiter', 'cs', 'admin', 'manager'];
    
    if (!in_array($role, $allowedRoles)) {
        sendResponse(false, "Role tidak valid", null, 400);
        return;
    }
    
    $sql = "SELECT o.*, t.table_number 
            FROM orders o 
            LEFT JOIN tables t ON o.table_id = t.id ";
    
    $params = [];
    
    if ($role == 'chef') {
        // FIXED: Chef sees orders that have pending/cooking items
        $sql .= "WHERE o.id IN (
            SELECT DISTINCT order_id FROM order_items 
            WHERE status IN ('pending', 'cooking')
        ) AND o.status NOT IN ('completed', 'cancelled')";
    } 
    else if ($role == 'waiter') {
        // FIXED: Waiter sees ready orders AND cooking orders (untuk tracking)
        $sql .= "WHERE o.status IN ('cooking', 'ready', 'served') 
                 AND o.status != 'completed'";
    } 
    else if ($role == 'cs') {
        // CS sees orders ready for payment
        $sql .= "WHERE o.status IN ('served', 'payment_pending', 'completed') 
                 AND DATE(o.created_at) = CURDATE()";
    } 
    else if ($role == 'admin' || $role == 'manager') {
        // Admin/Manager sees all active orders
        $sql .= "WHERE o.status NOT IN ('cancelled')";
    }
    
    $sql .= " ORDER BY o.created_at DESC";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Get items for each order
    if (!empty($orders)) {
        $itemStmt = $db->prepare("
            SELECT oi.id, oi.quantity, oi.notes, oi.status, 
                   m.name, m.image_url, oi.price 
            FROM order_items oi 
            JOIN menu_items m ON oi.menu_item_id = m.id 
            WHERE oi.order_id = ?
        ");
        
        foreach ($orders as &$order) {
            $itemStmt->execute([$order['id']]);
            $items = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Cast types
            foreach ($items as &$item) {
                $item['id'] = (int)$item['id'];
                $item['quantity'] = (int)$item['quantity'];
                $item['price'] = (float)$item['price'];
            }
            unset($item);
            
            $order['items'] = $items;
            $order['id'] = (int)$order['id'];
            $order['table_id'] = (int)$order['table_id'];
            $order['total_amount'] = (float)($order['total_amount'] ?? 0);
        }
        unset($order);
    }

    sendResponse(true, "Success", $orders);
}

// ==========================================
// 4. UPDATE STATUS - FIXED
// ==========================================
function updateOrderStatus($db, $input) {
    if (empty($input['order_id']) || empty($input['status'])) {
        sendResponse(false, "Data tidak lengkap", null, 400);
        return;
    }

    $oid = (int)$input['order_id'];
    $newStatus = preg_replace('/[^a-z_]/', '', $input['status']);
    $uid = isset($input['user_id']) ? (int)$input['user_id'] : 0;

    // Validate status
    $allowedStatuses = ['pending', 'cooking', 'ready', 'served', 'payment_pending', 'completed', 'cancelled'];
    if (!in_array($newStatus, $allowedStatuses)) {
        sendResponse(false, "Status tidak valid", null, 400);
        return;
    }

    try {
        $db->beginTransaction();
        
        // Update order status
        $stmt = $db->prepare("UPDATE orders SET status = ? WHERE id = ?");
        $stmt->execute([$newStatus, $oid]);
        
        // Update item statuses based on order status
        if ($newStatus == 'cooking') {
            // Update pending items to cooking
            $db->prepare("UPDATE order_items SET status = 'cooking' WHERE order_id = ? AND status = 'pending'")
               ->execute([$oid]);
        } 
        else if ($newStatus == 'ready') {
            // Update cooking items to ready
            $db->prepare("UPDATE order_items SET status = 'ready' WHERE order_id = ? AND status = 'cooking'")
               ->execute([$oid]);
        }
        else if ($newStatus == 'served') {
            // Update ready items to served
            $db->prepare("UPDATE order_items SET status = 'served' WHERE order_id = ? AND status IN ('ready', 'cooking', 'pending')")
               ->execute([$oid]);
        }
        
        $msg = "Status diperbarui";
        $notifRole = '';
        $notifMsg = '';

        switch ($newStatus) {
            case 'cooking':
                $msg = "Mulai memasak...";
                break;
            case 'ready':
                $msg = "Makanan Siap Saji!";
                $notifRole = 'waiter';
                $notifMsg = "Order #$oid siap diantar!";
                break;
            case 'served':
                $msg = "Makanan telah diantar.";
                break;
            case 'payment_pending':
                $msg = "Permintaan Bill dikirim ke Kasir.";
                $notifRole = 'cs';
                $notifMsg = "Order #$oid meminta bill/pembayaran.";
                break;
        }

        // Log & Notif
        if (function_exists('logActivity')) {
            logActivity($db, $uid, 'UPDATE_STATUS', "Order #$oid -> $newStatus");
        }
        if ($notifRole && function_exists('createNotification')) {
            createNotification($db, $notifRole, 'Update Status', $notifMsg);
        }
        
        $db->commit();
        sendResponse(true, $msg);
        
    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Gagal update status: " . $e->getMessage(), null, 500);
    }
}

// ==========================================
// 5. CANCEL ORDER
// ==========================================
function cancelOrder($db, $input) {
    $oid = isset($input['order_id']) ? (int)$input['order_id'] : 0;
    $uid = isset($input['user_id']) ? (int)$input['user_id'] : 0;
    $reason = $input['reason'] ?? 'Dibatalkan User';

    if ($oid <= 0) {
        sendResponse(false, "Order ID tidak valid", null, 400);
        return;
    }

    $chk = $db->prepare("SELECT status, table_id FROM orders WHERE id = ?");
    $chk->execute([$oid]);
    $order = $chk->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendResponse(false, "Order tidak ditemukan", null, 404);
        return;
    }
    
    if (in_array($order['status'], ['completed', 'cancelled'])) {
        sendResponse(false, "Order sudah selesai/dibatalkan!", null, 403);
        return;
    }

    try {
        $db->beginTransaction();

        // Update status
        $db->prepare("UPDATE orders SET status = 'cancelled', cancel_reason = ? WHERE id = ?")
           ->execute([$reason, $oid]);

        // Return stock
        $items = $db->prepare("SELECT menu_item_id, quantity FROM order_items WHERE order_id = ?");
        $items->execute([$oid]);
        while ($row = $items->fetch(PDO::FETCH_ASSOC)) {
            $db->prepare("UPDATE menu_items SET stock = stock + ? WHERE id = ?")
               ->execute([$row['quantity'], $row['menu_item_id']]);
        }

        // Free table
        $db->prepare("UPDATE tables SET status = 'available', current_order_id = NULL WHERE id = ?")
           ->execute([$order['table_id']]);

        if (function_exists('logActivity')) {
            logActivity($db, $uid, 'CANCEL_ORDER', "Order #$oid dibatalkan: $reason");
        }

        $db->commit();
        sendResponse(true, "Pesanan berhasil dibatalkan dan stok dikembalikan.");

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Gagal membatalkan: " . $e->getMessage(), null, 500);
    }
}

// ==========================================
// 6. PROCESS PAYMENT (Full Payment)
// ==========================================
function processPayment($db, $input) {
    if (empty($input['order_id']) || empty($input['payment_method'])) {
        sendResponse(false, "Metode pembayaran wajib dipilih!", null, 400);
        return;
    }

    try {
        $db->beginTransaction();
        
        $oid = (int)$input['order_id'];
        $userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;
        $method = preg_replace('/[^a-z_]/', '', $input['payment_method']);

        // Get order info
        $orderStmt = $db->prepare("SELECT table_id, total_amount, order_number FROM orders WHERE id = ? FOR UPDATE");
        $orderStmt->execute([$oid]);
        $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$order) {
            throw new Exception("Order tidak ditemukan");
        }

        // Finalize order
        $stmt = $db->prepare("UPDATE orders SET status = 'completed', payment_status = 'paid', payment_method = ?, cashier_id = ?, payment_time = NOW() WHERE id = ?");
        $stmt->execute([$method, $userId, $oid]);

        // Mark all items as completed
        $db->prepare("UPDATE order_items SET status = 'completed' WHERE order_id = ?")
           ->execute([$oid]);

        // Update loyalty points
        updateLoyaltyPoints($db, $oid);

        // Set table to dirty
        $db->prepare("UPDATE tables SET status = 'dirty', current_order_id = NULL WHERE id = ?")
           ->execute([$order['table_id']]);
        
        // Record transaction
        $transStmt = $db->prepare("INSERT INTO payment_transactions (order_id, transaction_type, amount, payment_method, status, cashier_id, created_at) VALUES (?, 'order_payment', ?, ?, 'success', ?, NOW())");
        $transStmt->execute([$oid, $order['total_amount'], $method, $userId]);
        
        if (function_exists('logActivity')) {
            $desc = "Terima Pembayaran {$order['order_number']} via " . strtoupper($method) . " (Rp " . number_format($order['total_amount']) . ")";
            logActivity($db, $userId, 'PAYMENT', $desc);
        }

        $db->commit();
        sendResponse(true, "Pembayaran Berhasil!");

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Error Payment: " . $e->getMessage(), null, 500);
    }
}

// ==========================================
// 7. MAKE PAYMENT (Split Payment by Item)
// ==========================================
function makePayment($db, $input) {
    if (empty($input['order_id']) || empty($input['payment_method'])) {
        sendResponse(false, "Data pembayaran tidak lengkap!", null, 400);
        return;
    }

    $orderId = (int)$input['order_id'];
    $itemIds = isset($input['item_ids']) && is_array($input['item_ids']) ? $input['item_ids'] : [];
    $method = preg_replace('/[^a-z_]/', '', $input['payment_method']);
    $userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;
    $notesJson = null;
    $amount = 0;

    try {
        $db->beginTransaction();

        $orderStmt = $db->prepare("SELECT total_amount, payment_status, status, table_id FROM orders WHERE id = ? FOR UPDATE");
        $orderStmt->execute([$orderId]);
        $order = $orderStmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) {
            throw new Exception("Order tidak ditemukan.");
        }

        if ($order['status'] == 'completed') {
            throw new Exception("Order ini sudah lunas.");
        }

        if (empty($itemIds)) {
            throw new Exception("Pilih item yang akan dibayar.");
        }

        // Get already paid items
        $paidItemsResult = $db->prepare("SELECT notes FROM payment_transactions WHERE order_id = ? AND notes IS NOT NULL");
        $paidItemsResult->execute([$orderId]);
        $paidItemIds = [];
        while($row = $paidItemsResult->fetch(PDO::FETCH_ASSOC)) {
            $noteData = json_decode($row['notes'], true);
            if (isset($noteData['item_ids']) && is_array($noteData['item_ids'])) {
                // FIXED: Ensure type consistency
                foreach ($noteData['item_ids'] as $id) {
                    $paidItemIds[] = (int)$id;
                }
            }
        }

        // FIXED: Ensure type consistency for comparison
        $itemIdsInt = array_map('intval', $itemIds);
        $itemsToPay = array_diff($itemIdsInt, $paidItemIds);
        
        if (empty($itemsToPay)) {
            throw new Exception("Semua item yang dipilih sudah dibayar.");
        }

        // Calculate amount for selected items
        $placeholders = implode(',', array_fill(0, count($itemsToPay), '?'));
        $itemQuery = "SELECT id, price, quantity FROM order_items 
                      WHERE order_id = ? AND id IN ($placeholders) 
                      AND status IN ('served', 'ready', 'completed')";
        $itemStmt = $db->prepare($itemQuery);
        $params = array_merge([$orderId], array_values($itemsToPay));
        $itemStmt->execute($params);
        $fetchedItems = $itemStmt->fetchAll(PDO::FETCH_ASSOC);

        if (count($fetchedItems) != count($itemsToPay)) {
            throw new Exception("Beberapa item belum siap atau tidak valid.");
        }

        foreach($fetchedItems as $item) {
            $amount += (float)$item['price'] * (int)$item['quantity'];
        }
        
        // Mark items as completed
        $updateItemsStmt = $db->prepare("UPDATE order_items SET status = 'completed' WHERE order_id = ? AND id IN ($placeholders)");
        $updateItemsStmt->execute($params);
        
        $notesJson = json_encode(['item_ids' => array_values($itemsToPay)]);

        // Record transaction
        $transStmt = $db->prepare("INSERT INTO payment_transactions (order_id, transaction_type, amount, payment_method, status, cashier_id, notes, created_at) VALUES (?, 'partial_payment', ?, ?, 'success', ?, ?, NOW())");
        $transStmt->execute([$orderId, $amount, $method, $userId, $notesJson]);
        
        // Check if fully paid
        $paidStmt = $db->prepare("SELECT COALESCE(SUM(amount), 0) FROM payment_transactions WHERE order_id = ?");
        $paidStmt->execute([$orderId]);
        $totalPaid = (float)$paidStmt->fetchColumn();

        $totalAmount = (float)$order['total_amount'];
        
        // FIXED: Documented threshold for rounding
        $paymentThreshold = 0.999; // Allow 0.1% difference for rounding
        
        if ($totalPaid >= $totalAmount * $paymentThreshold) {
            // Fully paid
            $updateOrderStmt = $db->prepare("UPDATE orders SET status = 'completed', payment_status = 'paid', payment_method = 'split', cashier_id = ?, payment_time = NOW() WHERE id = ?");
            $updateOrderStmt->execute([$userId, $orderId]);
            
            updateLoyaltyPoints($db, $orderId);

            $db->prepare("UPDATE tables SET status = 'dirty', current_order_id = NULL WHERE id = ?")
               ->execute([$order['table_id']]);
               
            $message = "Pembayaran Lunas!";
        } else {
            // Partial payment
            $updateOrderStmt = $db->prepare("UPDATE orders SET payment_status = 'partial' WHERE id = ?");
            $updateOrderStmt->execute([$orderId]);
            $message = "Pembayaran sebagian berhasil (Rp " . number_format($amount) . "). Sisa: Rp " . number_format($totalAmount - $totalPaid);
        }
        
        if (function_exists('logActivity')) {
            $desc = "Terima Pembayaran (Split) Order #$orderId via ".strtoupper($method)." (Rp ".number_format($amount).")";
            logActivity($db, $userId, 'PAYMENT', $desc);
        }

        $db->commit();
        sendResponse(true, $message, ['total_paid' => $totalPaid, 'total_amount' => $totalAmount]);

    } catch (Exception $e) {
        $db->rollBack();
        sendResponse(false, "Gagal memproses pembayaran: " . $e->getMessage(), null, 500);
    }
}

// ==========================================
// 8. CHECK PAYMENT ELIGIBILITY
// ==========================================
function checkPaymentEligibility($db, $orderId) {
    if ($orderId <= 0) {
        sendResponse(false, "Order ID tidak valid", null, 400);
        return;
    }
    
    $stmt = $db->prepare("
        SELECT 
            o.id,
            o.status,
            COUNT(DISTINCT oi.id) as total_items,
            SUM(CASE WHEN oi.status IN ('served', 'completed') THEN 1 ELSE 0 END) as served_items
        FROM orders o
        LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.id = ?
        GROUP BY o.id
    ");
    $stmt->execute([$orderId]);
    $data = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($data) {
        $canPay = ((int)$data['served_items'] > 0) || 
                  in_array($data['status'], ['served', 'payment_pending', 'ready', 'completed']);
        
        sendResponse(true, "Success", [
            'can_pay' => $canPay,
            'data' => $data
        ]);
    } else {
        sendResponse(false, 'Order tidak ditemukan', null, 404);
    }
}

// ==========================================
// 9. UPDATE LOYALTY POINTS
// ==========================================
function updateLoyaltyPoints($db, $orderId) {
    $orderStmt = $db->prepare("SELECT customer_id, total_amount FROM orders WHERE id = ?");
    $orderStmt->execute([$orderId]);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order || empty($order['customer_id'])) {
        return;
    }

    $customerId = (int)$order['customer_id'];
    $totalAmount = (float)$order['total_amount'];

    // Get settings
    $pointsPerThousand = 1;
    try {
        $settingsStmt = $db->query("SELECT value FROM settings WHERE key_name = 'loyalty_points_per_thousand'");
        if ($settingsStmt) {
            $setting = $settingsStmt->fetch(PDO::FETCH_ASSOC);
            if ($setting) $pointsPerThousand = (int)$setting['value'];
        }
    } catch(Exception $e) { 
        error_log("Failed to get loyalty settings: " . $e->getMessage());
    }

    $pointsEarned = floor($totalAmount / 1000) * $pointsPerThousand;

    if ($pointsEarned <= 0) return;

    // Get customer stats
    $customerStmt = $db->prepare("SELECT total_spent FROM customers WHERE id = ?");
    $customerStmt->execute([$customerId]);
    $customer = $customerStmt->fetch(PDO::FETCH_ASSOC);

    if (!$customer) {
        error_log("Customer ID $customerId not found for loyalty update");
        return;
    }

    $newTotalSpent = (float)$customer['total_spent'] + $totalAmount;
    
    // Calculate tier
    $newTier = 'bronze';
    if ($newTotalSpent > 5000000) {
        $newTier = 'platinum';
    } else if ($newTotalSpent > 2000000) {
        $newTier = 'gold';
    } else if ($newTotalSpent > 500000) {
        $newTier = 'silver';
    }

    $updateStmt = $db->prepare(
        "UPDATE customers 
         SET loyalty_points = loyalty_points + ?, 
             total_spent = ?, 
             visit_count = visit_count + 1,
             membership_tier = ?
         WHERE id = ?"
    );
    $updateStmt->execute([$pointsEarned, $newTotalSpent, $newTier, $customerId]);
}

// ==========================================
// 10. SALES CHART (7 Days) - FIXED N+1 Query
// ==========================================
function getSalesChart($db) {
    // FIXED: Single query instead of N+1
    $sql = "SELECT 
                DATE(created_at) as sale_date,
                COALESCE(SUM(total_amount), 0) as amount
            FROM orders 
            WHERE status = 'completed' 
            AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
            GROUP BY DATE(created_at)";
    
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Create lookup map
    $salesByDate = [];
    foreach ($results as $row) {
        $salesByDate[$row['sale_date']] = (float)$row['amount'];
    }
    
    // Build 7-day data
    $daysIndo = ['Sun'=>'Min', 'Mon'=>'Sen', 'Tue'=>'Sel', 'Wed'=>'Rab', 'Thu'=>'Kam', 'Fri'=>'Jum', 'Sat'=>'Sab'];
    $data = [];
    
    for ($i = 6; $i >= 0; $i--) {
        $date = date('Y-m-d', strtotime("-$i days"));
        $dayName = date('D', strtotime($date));
        
        $data[] = [
            'day' => $daysIndo[$dayName],
            'amount' => $salesByDate[$date] ?? 0.0,
            'date' => $date
        ];
    }
    
    sendResponse(true, "Success", $data);
}

// ==========================================
// 11. BUSINESS REPORT
// ==========================================
function getBusinessReport($db, $input) {
    $startDate = isset($input['start_date']) ? preg_replace('/[^0-9\-]/', '', $input['start_date']) : date('Y-m-01');
    $endDate = isset($input['end_date']) ? preg_replace('/[^0-9\-]/', '', $input['end_date']) : date('Y-m-d');

    // Validate dates
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $startDate) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $endDate)) {
        sendResponse(false, "Format tanggal tidak valid", null, 400);
        return;
    }

    // Total Revenue
    $qTotal = "SELECT COALESCE(SUM(total_amount),0) as total, COUNT(*) as count 
               FROM orders 
               WHERE status='completed' AND DATE(created_at) BETWEEN ? AND ?";
    $stmtTotal = $db->prepare($qTotal);
    $stmtTotal->execute([$startDate, $endDate]);
    $total = $stmtTotal->fetch(PDO::FETCH_ASSOC);

    // By Payment Method
    $qMethods = "SELECT payment_method, COALESCE(SUM(total_amount),0) as total, COUNT(*) as count 
                 FROM orders 
                 WHERE status='completed' AND DATE(created_at) BETWEEN ? AND ?
                 GROUP BY payment_method";
    $stmtMethods = $db->prepare($qMethods);
    $stmtMethods->execute([$startDate, $endDate]);
    $methods = $stmtMethods->fetchAll(PDO::FETCH_ASSOC);

    // Top Menu
    $qMenu = "SELECT m.name, SUM(oi.quantity) as qty, SUM(oi.quantity * oi.price) as revenue
              FROM order_items oi
              JOIN orders o ON oi.order_id = o.id
              JOIN menu_items m ON oi.menu_item_id = m.id
              WHERE o.status='completed' AND DATE(o.created_at) BETWEEN ? AND ?
              GROUP BY m.id, m.name
              ORDER BY qty DESC LIMIT 5";
    $stmtMenu = $db->prepare($qMenu);
    $stmtMenu->execute([$startDate, $endDate]);
    $topMenu = $stmtMenu->fetchAll(PDO::FETCH_ASSOC);

    // Cast types
    $total['total'] = (float)($total['total'] ?? 0);
    $total['count'] = (int)($total['count'] ?? 0);
    
    foreach ($methods as &$m) {
        $m['total'] = (float)($m['total'] ?? 0);
        $m['count'] = (int)($m['count'] ?? 0);
    }
    unset($m);
    
    foreach ($topMenu as &$item) {
        $item['qty'] = (int)($item['qty'] ?? 0);
        $item['revenue'] = (float)($item['revenue'] ?? 0);
    }
    unset($item);

    $data = [
        'period' => "$startDate s/d $endDate",
        'summary' => $total,
        'by_method' => $methods,
        'top_products' => $topMenu
    ];
    
    sendResponse(true, "Laporan Siap", $data);
}

// ==========================================
// 12. GET TRANSACTIONS BY ORDER
// ==========================================
function getTransactionsByOrder($db, $orderId) {
    if ($orderId <= 0) {
        sendResponse(false, "Order ID tidak valid", null, 400);
        return;
    }
    $stmt = $db->prepare("SELECT * FROM payment_transactions WHERE order_id = ? ORDER BY created_at ASC");
    $stmt->execute([$orderId]);
    $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Cast types
    foreach ($transactions as &$t) {
        $t['id'] = (int)$t['id'];
        $t['order_id'] = (int)$t['order_id'];
        $t['amount'] = (float)($t['amount'] ?? 0);
    }
    unset($t);
    
    sendResponse(true, "Success", $transactions);
}

// ==========================================
// 13. LINK CUSTOMER TO ORDER
// ==========================================
function linkCustomerToOrder($db, $input) {
    if (empty($input['order_id'])) {
        sendResponse(false, "Order ID tidak valid", null, 400);
        return;
    }
    
    // FIXED: Allow customer_id = null to unlink
    $orderId = (int)$input['order_id'];
    $customerId = isset($input['customer_id']) ? 
        ($input['customer_id'] === null ? null : (int)$input['customer_id']) : null;

    $customerName = 'Guest';
    $customerPhone = null;
    
    if ($customerId !== null && $customerId > 0) {
        $custStmt = $db->prepare("SELECT name, phone FROM customers WHERE id = ?");
        $custStmt->execute([$customerId]);
        $customer = $custStmt->fetch(PDO::FETCH_ASSOC);
        if ($customer) {
            $customerName = $customer['name'];
            $customerPhone = $customer['phone'];
        }
    }
    
    $stmt = $db->prepare("UPDATE orders SET customer_id = ?, customer_name = ?, customer_phone = ? WHERE id = ?");
    if ($stmt->execute([$customerId, $customerName, $customerPhone, $orderId])) {
        sendResponse(true, "Customer berhasil ditautkan ke order.");
    } else {
        sendResponse(false, "Gagal menautkan customer.", null, 500);
    }
}

// ==========================================
// 14. GET BOOKING BY TABLE
// ==========================================
function getBookingByTable($db, $tableId, $date) {
    if ($tableId <= 0 || empty($date)) {
        sendResponse(false, "Table ID dan tanggal diperlukan.", null, 400);
        return;
    }

    try {
        $stmt = $db->prepare("
            SELECT * FROM bookings 
            WHERE table_id = ? 
            AND booking_date = ? 
            AND status IN ('confirmed', 'checked_in')
            LIMIT 1
        ");
        $stmt->execute([$tableId, $date]);
        $booking = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($booking) {
            // Cast types
            $booking['id'] = (int)$booking['id'];
            $booking['table_id'] = (int)$booking['table_id'];
            $booking['down_payment'] = (float)($booking['down_payment'] ?? 0);
            $booking['guest_count'] = (int)($booking['guest_count'] ?? 0);
            
            sendResponse(true, "Booking found", $booking);
        } else {
            sendResponse(true, "No active booking found for this table and date", null);
        }
    } catch (Exception $e) {
        sendResponse(false, "API Error: " . $e->getMessage(), null, 500);
    }
}
?>