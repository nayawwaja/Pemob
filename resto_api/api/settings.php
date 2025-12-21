<?php
// api/settings.php
require_once '../utils/helpers.php';
require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$action = $_GET['action'] ?? '';

switch($action) {
    case 'get_settings':
        getSettings($db);
        break;
    default:
        sendResponse(false, "Invalid action for settings", null, 400);
}

function getSettings($db) {
    try {
        $stmt = $db->query("SELECT key_name, value FROM settings");
        $settingsRaw = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $settings = [];
        foreach ($settingsRaw as $row) {
            $settings[$row['key_name']] = $row['value'];
        }
        
        sendResponse(true, "Settings retrieved successfully.", $settings);
    } catch (Exception $e) {
        sendResponse(false, "Database error while fetching settings: " . $e->getMessage(), null, 500);
    }
}
?>