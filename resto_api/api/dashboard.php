<?php
require_once '../utils/helpers.php';
require_once '../config/database.php';

$db = (new Database())->getConnection();

$action = $_GET['action'] ?? '';

switch ($action) {
    case 'get_admin_dashboard':
        getAdminDashboard($db);
        break;
    default:
        sendResponse(false, "Invalid action for dashboard API", null, 400);
}

function getAdminDashboard($db) {
    try {
        $today = date('Y-m-d');

        // Main Dashboard Stats
        $stmtOrders = $db->prepare("SELECT COUNT(id) AS total_orders, SUM(total_amount) AS total_revenue FROM orders WHERE DATE(created_at) = CURDATE() AND status = 'completed'");
        $stmtOrders->execute();
        $todayStats = $stmtOrders->fetch(PDO::FETCH_ASSOC);

        $totalBookings = $db->query("SELECT COUNT(*) FROM bookings WHERE booking_date = '$today' AND status != 'cancelled'")->fetchColumn();
        $lowStockCount = $db->query("SELECT COUNT(*) FROM menu_items WHERE stock <= 5 AND is_active = 1")->fetchColumn();
        $pendingOrders = $db->query("SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'cooking')")->fetchColumn();

        $mainStats = [
            'total_revenue' => (double)$todayStats['total_revenue'],
            'total_orders' => (int)$todayStats['total_orders'],
            'today_bookings' => (int)$totalBookings,
            'low_stock_count' => (int)$lowStockCount,
            'pending_orders' => (int)$pendingOrders,
        ];

        // Low Stock Items
        $stmtLowStock = $db->prepare("SELECT id, name, stock FROM menu_items WHERE stock <= 5 AND is_active = 1 ORDER BY stock ASC, name ASC LIMIT 10");
        $stmtLowStock->execute();
        $lowStockItems = $stmtLowStock->fetchAll(PDO::FETCH_ASSOC);

        // Sales Chart Data (Last 7 Days)
        $salesChartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = date('Y-m-d', strtotime("-$i days"));
            $dayName = date('D', strtotime($date)); // e.g., Mon, Tue

            $stmtDailySales = $db->prepare("SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = ? AND status = 'completed'");
            $stmtDailySales->execute([$date]);
            $dailyRevenue = $stmtDailySales->fetchColumn();

            $salesChartData[] = [
                'day' => $dayName,
                'date' => $date,
                'amount' => (double)$dailyRevenue
            ];
        }
        
        $dashboardData = [
            'stats' => $mainStats,
            'low_stock_items' => $lowStockItems,
            'sales_chart_data' => $salesChartData,
        ];

        sendResponse(true, "Admin dashboard data retrieved successfully", $dashboardData);

    } catch (Exception $e) {
        sendResponse(false, "API Error: " . $e->getMessage(), null, 500);
    }
}
?>