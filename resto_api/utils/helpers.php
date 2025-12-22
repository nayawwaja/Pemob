<?php
// resto_api/utils/helpers.php

if (!function_exists('sendResponse')) {
    /**
     * Helper function to send JSON responses.
     *
     * @param bool $success Indicates if the operation was successful.
     * @param string $message A descriptive message for the response.
     * @param mixed $data Optional data to include in the response.
     * @param int $httpCode The HTTP status code to send.
     */
    function sendResponse($success, $message, $data = null, $httpCode = 200) {
        http_response_code($httpCode);
        header('Content-Type: application/json');
        echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
        exit;
    }
}

if (!function_exists('logActivity')) {
    /**
     * Log activity to activity_logs table
     *
     * @param PDO $db Database connection
     * @param int $userId User ID who performed the action
     * @param string $actionType Type of action (LOGIN, CLOCK_IN, CLOCK_OUT, etc.)
     * @param string $description Description of the activity
     */
    function logActivity($db, $userId, $actionType, $description) {
        try {
            $stmt = $db->prepare("INSERT INTO activity_logs (user_id, action_type, description, created_at) VALUES (?, ?, ?, NOW())");
            $stmt->execute([$userId, $actionType, $description]);
        } catch (Exception $e) {
            // Silently fail - logging should not break the main operation
            error_log("Failed to log activity: " . $e->getMessage());
        }
    }
}

if (!function_exists('createNotification')) {
    /**
     * Create notification for specific role or user
     *
     * @param PDO $db Database connection
     * @param string $targetRole Target role (chef, waiter, cs, admin)
     * @param string $title Notification title
     * @param string $message Notification message
     * @param int|null $targetUserId Specific user ID (optional)
     */
    function createNotification($db, $targetRole, $title, $message, $targetUserId = null) {
        try {
            $stmt = $db->prepare("INSERT INTO notifications (target_role, target_user_id, title, message, type, created_at) VALUES (?, ?, ?, ?, 'info', NOW())");
            $stmt->execute([$targetRole, $targetUserId, $title, $message]);
        } catch (Exception $e) {
            error_log("Failed to create notification: " . $e->getMessage());
        }
    }
}

if (!function_exists('formatCurrency')) {
    /**
     * Format number as Indonesian currency
     *
     * @param float $amount Amount to format
     * @return string Formatted currency string
     */
    function formatCurrency($amount) {
        return 'Rp ' . number_format($amount, 0, ',', '.');
    }
}

if (!function_exists('getUserRole')) {
    /**
     * Get user role by user ID
     *
     * @param PDO $db Database connection
     * @param int $userId User ID
     * @return string|false User role or false if not found
     */
    function getUserRole($db, $userId) {
        try {
            $stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            return $stmt->fetchColumn();
        } catch (Exception $e) {
            return false;
        }
    }
}
?>