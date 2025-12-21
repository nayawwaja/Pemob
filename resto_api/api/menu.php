<?php
require_once '../utils/helpers.php';
require_once '../config/database.php';
$db = (new Database())->getConnection();

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

switch($action) {
    // --- FITUR CLIENT (Menu Digital) ---
    case 'get_categories':
        getCategories($db);
        break;
        
    case 'get_menu':
        getMenu($db);
        break;

    case 'get_menu_by_category':
        $categoryId = $_GET['category_id'] ?? 0;
        getMenuByCategory($db, $categoryId);
        break;
        
    case 'get_menu_detail':
        $menuId = $_GET['id'] ?? 0;
        getMenuDetail($db, $menuId);
        break;

    // --- FITUR MANAJEMEN (Admin/Manager/Chef) ---
    case 'add_menu':
        if ($method != 'POST') sendResponse(false, "Method not allowed", null, 405);
        addMenu($db, $input);
        break;
        
    case 'update_menu':
        if ($method != 'POST') sendResponse(false, "Method not allowed", null, 405);
        updateMenu($db, $input);
        break;
        
    case 'delete_menu':
        if ($method != 'POST') sendResponse(false, "Method not allowed", null, 405);
        $menuId = $_GET['id'] ?? 0;
        deleteMenu($db, $menuId);
        break;

    case 'update_stock': // Owner & Manager bisa update stok
        if ($method != 'POST') sendResponse(false, "Method not allowed", null, 405);
        updateStock($db, $input);
        break;
        
    default:
        sendResponse(false, "Invalid action: Parameter 'action' tidak ditemukan", null, 400);
}

// ==========================================
// FUNCTIONS
// ==========================================

function getCategories($db) {
    $query = "SELECT * FROM categories WHERE is_active = 1 ORDER BY id";
    $stmt = $db->prepare($query);
    $stmt->execute();
    sendResponse(true, "Success", $stmt->fetchAll(PDO::FETCH_ASSOC));
}

function getMenu($db) {
    $query = "SELECT m.*, c.name as category_name 
              FROM menu_items m 
              LEFT JOIN categories c ON m.category_id = c.id 
              WHERE m.is_active = 1 
              ORDER BY m.category_id, m.name";
    
    $stmt = $db->prepare($query);
    $stmt->execute();
    $menu = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // FIX: Handle Null Values agar tidak Warning di PHP
    foreach ($menu as &$item) {
        $item['price'] = (double)$item['price'];
        $item['stock'] = (int)$item['stock'];
        
        // Cek apakah key discount_price ada dan tidak null
        $discount = isset($item['discount_price']) ? $item['discount_price'] : null;
        $item['discount_price'] = $discount ? (double)$discount : null;
        
        $item['is_low_stock'] = $item['stock'] <= 5 && $item['stock'] > 0;
        $item['is_out_of_stock'] = $item['stock'] == 0;
    }
    
    sendResponse(true, "Success", $menu);
}

function getMenuByCategory($db, $categoryId) {
    $query = "SELECT m.*, c.name as category_name 
              FROM menu_items m 
              LEFT JOIN categories c ON m.category_id = c.id 
              WHERE m.is_active = 1 AND m.category_id = ? 
              ORDER BY m.name";
              
    $stmt = $db->prepare($query);
    $stmt->execute([$categoryId]);
    $menu = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($menu as &$item) {
        $item['price'] = (double)$item['price'];
        $item['stock'] = (int)$item['stock'];
        // Fix Discount
        $discount = isset($item['discount_price']) ? $item['discount_price'] : null;
        $item['discount_price'] = $discount ? (double)$discount : null;
    }
    
    sendResponse(true, "Success", $menu);
}

function getMenuDetail($db, $menuId) {
    $query = "SELECT m.*, c.name as category_name 
              FROM menu_items m 
              LEFT JOIN categories c ON m.category_id = c.id 
              WHERE m.id = ?";
              
    $stmt = $db->prepare($query);
    $stmt->execute([$menuId]);
    
    if ($stmt->rowCount() > 0) {
        $item = $stmt->fetch(PDO::FETCH_ASSOC);
        $item['price'] = (double)$item['price'];
        $item['stock'] = (int)$item['stock'];
        // Fix Discount
        $discount = isset($item['discount_price']) ? $item['discount_price'] : null;
        $item['discount_price'] = $discount ? (double)$discount : null;
        
        sendResponse(true, "Success", $item);
    } else {
        sendResponse(false, "Menu tidak ditemukan", null, 404);
    }
}

function addMenu($db, $input) {
    if (empty($input['name']) || empty($input['price']) || empty($input['category_id'])) {
        sendResponse(false, "Nama, Harga, dan Kategori wajib diisi", null, 400);
    }
    
    // Query dengan discount_price
    $query = "INSERT INTO menu_items 
              (category_id, name, description, price, discount_price, stock, image_url, is_active) 
              VALUES 
              (:category_id, :name, :description, :price, :discount_price, :stock, :image_url, :is_active)";
    
    try {
        $stmt = $db->prepare($query);
        $params = [
            ':category_id' => $input['category_id'],
            ':name' => $input['name'],
            ':description' => $input['description'] ?? '',
            ':price' => $input['price'],
            ':discount_price' => !empty($input['discount_price']) ? $input['discount_price'] : null,
            ':stock' => $input['stock'] ?? 0,
            ':image_url' => $input['image_url'] ?? '',
            ':is_active' => isset($input['is_active']) ? $input['is_active'] : 1
        ];
        
        if ($stmt->execute($params)) {
            sendResponse(true, "Menu berhasil ditambahkan", ["id" => $db->lastInsertId()], 201);
        } else {
            sendResponse(false, "Gagal menambahkan menu", null, 500);
        }
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage());
    }
}

function updateMenu($db, $input) {
    if (empty($input['id'])) {
        sendResponse(false, "ID menu harus ada", null, 400);
    }
    
    $query = "UPDATE menu_items SET 
              category_id = :category_id,
              name = :name,
              description = :description,
              price = :price,
              discount_price = :discount_price,
              stock = :stock,
              is_active = :is_active,
              image_url = :image_url
              WHERE id = :id";
    
    try {
        $stmt = $db->prepare($query);
        $params = [
            ':id' => $input['id'],
            ':category_id' => $input['category_id'],
            ':name' => $input['name'],
            ':description' => $input['description'] ?? '',
            ':price' => $input['price'],
            ':discount_price' => !empty($input['discount_price']) ? $input['discount_price'] : null,
            ':stock' => $input['stock'] ?? 0,
            ':is_active' => isset($input['is_active']) ? $input['is_active'] : 1,
            ':image_url' => $input['image_url'] ?? ''
        ];
        
        if ($stmt->execute($params)) {
            sendResponse(true, "Menu berhasil diupdate");
        } else {
            sendResponse(false, "Gagal mengupdate menu", null, 500);
        }
    } catch (Exception $e) {
        sendResponse(false, "Error: " . $e->getMessage());
    }
}

function deleteMenu($db, $menuId) {
    $query = "UPDATE menu_items SET is_active = 0 WHERE id = ?";
    $stmt = $db->prepare($query);
    
    if ($stmt->execute([$menuId])) {
        sendResponse(true, "Menu berhasil dihapus (soft delete)");
    } else {
        sendResponse(false, "Gagal menghapus menu", null, 500);
    }
}

function updateStock($db, $input) {
    if (empty($input['id'])) {
        sendResponse(false, "ID dan Stock wajib diisi", null, 400);
    }
    
    // Perbaikan: Gunakan parameter binding yang benar
    $query = "UPDATE menu_items SET stock = :stock WHERE id = :id";
    $stmt = $db->prepare($query);
    
    // Pastikan stock tidak negatif
    $stock = max(0, intval($input['stock']));

    if ($stmt->execute([':stock' => $stock, ':id' => $input['id']])) {
        sendResponse(true, "Stok berhasil diupdate");
    } else {
        sendResponse(false, "Gagal mengupdate stok", null, 500);
    }
}?>