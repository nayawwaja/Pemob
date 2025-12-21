<?php
header("Content-Type: application/json");
require_once '../utils/helpers.php';
require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

switch($action) {
    case 'search':
        searchCustomers($db, $_GET['query'] ?? '');
        break;
    case 'get_by_id':
        getCustomerById($db, $_GET['id'] ?? 0);
        break;
    case 'add_customer':
        addCustomer($db, $input);
        break;
    default:
        sendResponse(false, "Invalid action for customers API", null, 400);
}

function searchCustomers($db, $query) {
    if (empty($query)) {
        sendResponse(true, "Success", []);
        return;
    }
    $stmt = $db->prepare("SELECT * FROM customers WHERE name LIKE ? OR phone LIKE ? LIMIT 10");
    $stmt->execute(["%$query%", "%$query%"]);
    $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(true, "Success", $customers);
}

function getCustomerById($db, $id) {
    if (!$id) {
        sendResponse(false, "Customer ID is required", null, 400);
        return;
    }
    $stmt = $db->prepare("SELECT * FROM customers WHERE id = ?");
    $stmt->execute([$id]);
    $customer = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($customer) {
        sendResponse(true, "Success", $customer);
    } else {
        sendResponse(false, "Customer not found", null, 404);
    }
}

function addCustomer($db, $input) {
    if (empty($input['name']) || empty($input['phone'])) {
        sendResponse(false, "Nama dan Telepon wajib diisi.", null, 400);
        return;
    }

    // Cek apakah nomor telepon sudah ada
    $checkStmt = $db->prepare("SELECT id FROM customers WHERE phone = ?");
    $checkStmt->execute([$input['phone']]);
    if ($checkStmt->fetch()) {
        sendResponse(false, "Nomor telepon sudah terdaftar.", null, 409); // 409 Conflict
        return;
    }

    try {
        $stmt = $db->prepare("INSERT INTO customers (name, phone, created_at) VALUES (?, ?, NOW())");
        $stmt->execute([$input['name'], $input['phone']]);
        $newId = $db->lastInsertId();

        // Ambil data customer yang baru dibuat untuk dikirim kembali ke Flutter
        $newCustomerStmt = $db->prepare("SELECT * FROM customers WHERE id = ?");
        $newCustomerStmt->execute([$newId]);
        $newCustomerData = $newCustomerStmt->fetch(PDO::FETCH_ASSOC);

        sendResponse(true, "Pelanggan berhasil ditambahkan", $newCustomerData, 201); // 201 Created
    } catch (Exception $e) {
        sendResponse(false, "Gagal menambahkan pelanggan: " . $e->getMessage(), null, 500);
    }
}
?>