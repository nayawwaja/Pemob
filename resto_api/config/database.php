<?php
// config/database.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

class Database {
    private $host = "localhost";
    private $db_name = "resto_db";
    private $username = "root";
    private $password = "";
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username,
                $this->password
            );
            $this->conn->exec("set names utf8");
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $exception) {
            echo json_encode(["success" => false, "message" => "DB Error: " . $exception->getMessage()]);
            exit();
        }
        return $this->conn;
    }
}

// --- HELPER FUNCTIONS ---

// Fungsi mencatat aktivitas (Audit Trail)
function logActivity($db, $userId, $action, $description) {
    try {
        $stmt = $db->prepare("INSERT INTO activity_logs (user_id, action_type, description) VALUES (?, ?, ?)");
        $stmt->execute([$userId, $action, $description]);
    } catch (Exception $e) {
        // Silent fail agar tidak mengganggu flow utama
    }
}

// Fungsi membuat notifikasi internal
function createNotification($db, $targetRole, $title, $message, $targetUserId = null) {
    try {
        $sql = "INSERT INTO notifications (target_role, target_user_id, title, message) VALUES (?, ?, ?, ?)";
        $stmt = $db->prepare($sql);
        $stmt->execute([$targetRole, $targetUserId, $title, $message]);
    } catch (Exception $e) {
        // Silent fail
    }
}
?>