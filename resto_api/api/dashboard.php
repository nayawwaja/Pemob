<?php
require_once '../utils/helpers.php';
require_once '../config/database.php';

$db = (new Database())->getConnection();

$action = $_GET['action'] ?? '';

switch ($action) {
    case 'get_admin_dashboard':
        getAdminDashboard($db);
        break;
    case 'get_sales_chart':
        getSalesChartData($db);
        break;
    default:
        sendResponse(false, "Invalid action for dashboard API", null, 400);
}

function getAdminDashboard($db) {
    try {
        $today = date('Y-m-d');

        // Main Dashboard Stats - FIXED: Only count PAID orders
        $stmtOrders = $db->prepare("SELECT COUNT(id) AS total_orders, COALESCE(SUM(total_amount), 0) AS total_revenue FROM orders WHERE DATE(created_at) = CURDATE() AND status = 'completed' AND payment_status = 'paid'");
        $stmtOrders->execute();
        $todayStats = $stmtOrders->fetch(PDO::FETCH_ASSOC);

        $totalBookings = $db->query("SELECT COUNT(*) FROM bookings WHERE booking_date = '$today' AND status != 'cancelled'")->fetchColumn();
        $lowStockCount = $db->query("SELECT COUNT(*) FROM menu_items WHERE stock <= 5 AND is_available = 1")->fetchColumn();
        $pendingOrders = $db->query("SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'cooking')")->fetchColumn();

        $mainStats = [
            'total_revenue' => (double)$todayStats['total_revenue'],
            'total_orders' => (int)$todayStats['total_orders'],
            'today_bookings' => (int)$totalBookings,
            'low_stock_count' => (int)$lowStockCount,
            'pending_orders' => (int)$pendingOrders,
        ];

        // Low Stock Items
        $stmtLowStock = $db->prepare("SELECT id, name, stock FROM menu_items WHERE stock <= 5 AND is_available = 1 ORDER BY stock ASC, name ASC LIMIT 10");
        $stmtLowStock->execute();
        $lowStockItems = $stmtLowStock->fetchAll(PDO::FETCH_ASSOC);

        // Sales Chart Data (Last 7 Days) - FIXED: Include all revenue types
        $salesChartData = getSalesChartDataInternal($db);
        
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

// Fungsi internal untuk sales chart
function getSalesChartDataInternal($db) {
    $salesChartData = [];
    
    for ($i = 6; $i >= 0; $i--) {
        $date = date('Y-m-d', strtotime("-$i days"));
        $dayName = date('D', strtotime($date)); // e.g., Mon, Tue

        // FIXED: Sum ALL completed and paid orders (termasuk DP yang sudah lunas)
        $stmtDailySales = $db->prepare("
            SELECT COALESCE(SUM(total_amount), 0) as revenue
            FROM orders 
            WHERE DATE(created_at) = ? 
            AND status = 'completed' 
            AND payment_status = 'paid'
        ");
        $stmtDailySales->execute([$date]);
        $dailyRevenue = $stmtDailySales->fetchColumn();

        $salesChartData[] = [
            'day' => $dayName,
            'date' => $date,
            'amount' => (double)$dailyRevenue
        ];
    }
    
    return $salesChartData;
}

// Endpoint terpisah untuk sales chart (dipanggil dari admin_dashboard.dart)
function getSalesChartData($db) {
    try {
        $salesChartData = getSalesChartDataInternal($db);
        sendResponse(true, "Sales chart data retrieved", $salesChartData);
    } catch (Exception $e) {
        sendResponse(false, "API Error: " . $e->getMessage(), null, 500);
    }
}
?>