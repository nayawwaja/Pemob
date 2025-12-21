-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 21, 2025 at 09:49 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `resto_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_recalculate_order` (IN `p_order_id` INT)   BEGIN
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_tax_rate DECIMAL(5,2);
    DECLARE v_service_rate DECIMAL(5,2);
    DECLARE v_tax DECIMAL(12,2);
    DECLARE v_service DECIMAL(12,2);
    DECLARE v_total DECIMAL(12,2);
    
    -- Get rates from settings
    SELECT COALESCE(CAST(value AS DECIMAL(5,2)), 10) / 100 INTO v_tax_rate 
    FROM settings WHERE key_name = 'tax_percentage';
    
    SELECT COALESCE(CAST(value AS DECIMAL(5,2)), 5) / 100 INTO v_service_rate 
    FROM settings WHERE key_name = 'service_charge_percentage';
    
    -- Calculate subtotal
    SELECT COALESCE(SUM(quantity * price), 0) INTO v_subtotal
    FROM order_items WHERE order_id = p_order_id;
    
    -- Calculate tax and service
    SET v_tax = v_subtotal * v_tax_rate;
    SET v_service = v_subtotal * v_service_rate;
    SET v_total = v_subtotal + v_tax + v_service;
    
    -- Update order
    UPDATE orders 
    SET subtotal = v_subtotal, 
        tax = v_tax, 
        service_charge = v_service, 
        total_amount = v_total,
        updated_at = NOW()
    WHERE id = p_order_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_sales_report` (IN `p_start_date` DATE, IN `p_end_date` DATE)   BEGIN
    SELECT 
        DATE(o.created_at) as sale_date,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(o.total_amount) as gross_sales,
        SUM(o.discount) as total_discounts,
        SUM(o.total_amount - o.discount) as net_sales,
        SUM(o.tax) as total_tax,
        SUM(o.service_charge) as total_service,
        o.payment_method,
        COUNT(DISTINCT o.customer_id) as unique_customers
    FROM orders o
    WHERE o.status = 'completed'
      AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
    GROUP BY DATE(o.created_at), o.payment_method
    ORDER BY sale_date DESC;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `action_type` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `table_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `customer_name` varchar(100) NOT NULL,
  `customer_phone` varchar(20) NOT NULL,
  `customer_email` varchar(100) DEFAULT NULL,
  `booking_code` varchar(20) DEFAULT NULL,
  `booking_date` date NOT NULL,
  `booking_time` time NOT NULL,
  `duration` int(11) DEFAULT 120 COMMENT 'Durasi dalam menit',
  `guest_count` int(11) DEFAULT 2,
  `status` enum('pending','confirmed','checked_in','completed','cancelled','no_show') DEFAULT 'pending',
  `special_request` text DEFAULT NULL,
  `confirmed_by` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dp_paid` tinyint(1) DEFAULT 0,
  `check_in_time` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `booking_payments`
--

CREATE TABLE `booking_payments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `status` enum('pending','paid','refunded') DEFAULT 'pending',
  `reference_number` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `cashier_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `description`, `icon`, `sort_order`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Makanan Utama', 'Hidangan utama nasi, mie, dan lauk', 'restaurant', 1, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(2, 'Appetizer', 'Hidangan pembuka', 'tapas', 2, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(3, 'Minuman', 'Berbagai minuman segar', 'local_cafe', 3, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(4, 'Dessert', 'Hidangan penutup manis', 'cake', 4, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(5, 'Snack', 'Makanan ringan dan gorengan', 'fastfood', 5, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(6, 'Paket Hemat', 'Paket combo hemat', 'savings', 6, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `loyalty_points` int(11) DEFAULT 0,
  `total_spent` decimal(15,2) DEFAULT 0.00,
  `visit_count` int(11) DEFAULT 0,
  `membership_tier` enum('bronze','silver','gold','platinum') DEFAULT 'bronze',
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `name`, `phone`, `email`, `address`, `birth_date`, `loyalty_points`, `total_spent`, `visit_count`, `membership_tier`, `notes`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Budi Santoso', '081111111111', 'budi@email.com', NULL, NULL, 150, 1500000.00, 12, 'silver', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(2, 'Siti Rahayu', '081222222222', 'siti@email.com', NULL, NULL, 320, 3200000.00, 25, 'gold', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(3, 'Ahmad Wijaya', '081333333333', 'ahmad@email.com', NULL, NULL, 50, 500000.00, 5, 'bronze', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(4, 'Dewi Lestari', '081444444444', 'dewi@email.com', NULL, NULL, 580, 5800000.00, 45, 'platinum', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(5, 'Rudi Hermawan', '081555555555', 'rudi@email.com', NULL, NULL, 200, 2000000.00, 18, 'silver', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(6, 'Maya Sari', '081666666666', 'maya@email.com', NULL, NULL, 80, 800000.00, 8, 'bronze', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(7, 'Eko Prasetyo', '081777777777', 'eko@email.com', NULL, NULL, 420, 4200000.00, 35, 'gold', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(8, 'Linda Kusuma', '081888888888', 'linda@email.com', NULL, NULL, 100, 1000000.00, 10, 'bronze', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(9, 'Hendra Gunawan', '081999999999', 'hendra@email.com', NULL, NULL, 250, 2500000.00, 20, 'gold', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(10, 'Rina Wati', '081000000000', 'rina@email.com', NULL, NULL, 30, 300000.00, 3, 'bronze', NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_logs`
--

CREATE TABLE `inventory_logs` (
  `id` int(11) NOT NULL,
  `menu_item_id` int(11) NOT NULL,
  `quantity_change` int(11) NOT NULL COMMENT 'Positif = masuk, Negatif = keluar',
  `quantity_before` int(11) NOT NULL,
  `quantity_after` int(11) NOT NULL,
  `reason` varchar(100) NOT NULL COMMENT 'order, restock, adjustment, waste',
  `reference_id` int(11) DEFAULT NULL COMMENT 'ID order atau adjustment',
  `user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

CREATE TABLE `menu_items` (
  `id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(12,2) NOT NULL DEFAULT 0.00,
  `discount_price` decimal(12,2) DEFAULT NULL,
  `stock` int(11) NOT NULL DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT 1,
  `is_featured` tinyint(1) DEFAULT 0,
  `preparation_time` int(11) DEFAULT NULL COMMENT 'Waktu persiapan dalam menit',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`id`, `category_id`, `name`, `description`, `price`, `stock`, `image_url`, `is_available`, `is_featured`, `preparation_time`, `created_at`, `updated_at`) VALUES
(1, 1, 'Nasi Goreng Spesial', 'Nasi goreng dengan telur, ayam, dan sayuran', 35000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(2, 1, 'Nasi Goreng Seafood', 'Nasi goreng dengan udang, cumi, dan kerang', 45000.00, 80, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(3, 1, 'Mie Goreng Jawa', 'Mie goreng dengan bumbu khas Jawa', 32000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(4, 1, 'Mie Ayam Bakso', 'Mie ayam dengan bakso sapi', 30000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(5, 1, 'Nasi Campur Bali', 'Nasi dengan lauk khas Bali lengkap', 55000.00, 50, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(6, 1, 'Ayam Bakar Madu', 'Ayam bakar dengan saus madu spesial', 48000.00, 60, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(7, 1, 'Ayam Geprek Sambal Matah', 'Ayam geprek dengan sambal matah Bali', 35000.00, 80, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(8, 1, 'Ikan Bakar Rica-Rica', 'Ikan bakar dengan bumbu rica-rica pedas', 52000.00, 40, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(9, 1, 'Sate Ayam (10 tusuk)', 'Sate ayam dengan bumbu kacang', 38000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(10, 1, 'Sate Kambing (10 tusuk)', 'Sate kambing muda empuk', 55000.00, 50, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(11, 1, 'Rendang Sapi', 'Rendang sapi Padang asli', 58000.00, 40, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(12, 1, 'Gulai Kambing', 'Gulai kambing dengan kuah kental', 52000.00, 35, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(13, 2, 'Lumpia Goreng (5 pcs)', 'Lumpia isi sayuran dan ayam', 25000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(14, 2, 'Tahu Crispy', 'Tahu goreng crispy dengan saus', 18000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(15, 2, 'Tempe Mendoan (5 pcs)', 'Tempe tipis goreng tepung', 15000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(16, 2, 'Sop Buntut', 'Sop buntut sapi dengan kuah bening', 65000.00, 30, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(17, 2, 'Soto Ayam', 'Soto ayam dengan nasi dan pelengkap', 32000.00, 80, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(18, 2, 'Gado-Gado', 'Sayuran dengan bumbu kacang', 28000.00, 80, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(19, 3, 'Es Teh Manis', 'Teh manis dingin segar', 8000.00, 200, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(20, 3, 'Es Jeruk', 'Jeruk peras segar dengan es', 12000.00, 200, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(21, 3, 'Jus Alpukat', 'Jus alpukat dengan susu coklat', 18000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(22, 3, 'Jus Mangga', 'Jus mangga segar', 15000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(23, 3, 'Es Kelapa Muda', 'Kelapa muda dengan es', 15000.00, 80, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(24, 3, 'Kopi Hitam', 'Kopi tubruk tradisional', 10000.00, 200, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(25, 3, 'Cappuccino', 'Cappuccino dengan foam susu', 22000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(26, 3, 'Latte', 'Kopi latte creamy', 25000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(27, 3, 'Matcha Latte', 'Green tea latte', 28000.00, 80, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(28, 3, 'Air Mineral', 'Air mineral botol', 6000.00, 300, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(29, 4, 'Es Cendol', 'Cendol dengan santan dan gula merah', 15000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(30, 4, 'Es Campur', 'Es campur dengan aneka topping', 18000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(31, 4, 'Pisang Goreng Keju', 'Pisang goreng dengan keju dan coklat', 20000.00, 80, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(32, 4, 'Kolak Pisang', 'Kolak pisang dengan santan', 15000.00, 80, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(33, 4, 'Puding Coklat', 'Puding coklat dengan vla', 18000.00, 60, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(34, 4, 'Es Krim Vanilla', 'Es krim vanilla 2 scoop', 20000.00, 50, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(35, 5, 'Kentang Goreng', 'French fries crispy', 22000.00, 100, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(36, 5, 'Onion Ring', 'Onion ring crispy', 20000.00, 80, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(37, 5, 'Chicken Wings (6 pcs)', 'Sayap ayam goreng crispy', 35000.00, 60, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(38, 5, 'Cireng (5 pcs)', 'Aci goreng dengan bumbu rujak', 12000.00, 100, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(39, 5, 'Pisang Keju', 'Pisang bakar dengan keju', 18000.00, 80, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(40, 6, 'Paket Nasi Ayam Geprek + Es Teh', 'Nasi ayam geprek dengan es teh manis', 40000.00, 50, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(41, 6, 'Paket Mie Ayam + Jus Jeruk', 'Mie ayam bakso dengan jus jeruk', 38000.00, 50, NULL, 1, 0, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(42, 6, 'Paket Nasi Goreng + Es Teh', 'Nasi goreng spesial dengan es teh', 40000.00, 50, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(43, 6, 'Paket Keluarga (4 orang)', 'Nasi goreng 4 + ayam bakar 4 + es teh 4', 150000.00, 20, NULL, 1, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43');

--
-- Triggers `menu_items`
--
DELIMITER $$
CREATE TRIGGER `tr_menu_stock_change` AFTER UPDATE ON `menu_items` FOR EACH ROW BEGIN
    IF OLD.stock != NEW.stock THEN
        INSERT INTO inventory_logs (menu_item_id, quantity_change, quantity_before, quantity_after, reason)
        VALUES (NEW.id, NEW.stock - OLD.stock, OLD.stock, NEW.stock, 'system_update');
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `target_role` varchar(50) DEFAULT NULL COMMENT 'Role yang ditarget (chef, waiter, cs, admin)',
  `target_user_id` int(11) DEFAULT NULL COMMENT 'User spesifik yang ditarget',
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `type` enum('info','warning','success','error') DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` datetime DEFAULT NULL,
  `reference_type` varchar(50) DEFAULT NULL COMMENT 'order, booking, etc',
  `reference_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `order_number` varchar(50) NOT NULL,
  `table_id` int(11) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `customer_name` varchar(100) DEFAULT 'Guest',
  `customer_phone` varchar(20) DEFAULT NULL,
  `waiter_id` int(11) DEFAULT NULL,
  `cashier_id` int(11) DEFAULT NULL,
  `subtotal` decimal(12,2) DEFAULT 0.00,
  `tax` decimal(12,2) DEFAULT 0.00,
  `service_charge` decimal(12,2) DEFAULT 0.00,
  `discount` decimal(12,2) DEFAULT 0.00,
  `total_amount` decimal(12,2) DEFAULT 0.00,
  `status` enum('pending','cooking','ready','served','payment_pending','completed','cancelled') DEFAULT 'pending',
  `payment_status` enum('unpaid','partial','paid') DEFAULT 'unpaid',
  `payment_method` varchar(50) DEFAULT NULL,
  `payment_time` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `cancel_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_number`, `table_id`, `customer_id`, `customer_name`, `customer_phone`, `waiter_id`, `cashier_id`, `subtotal`, `tax`, `service_charge`, `discount`, `total_amount`, `status`, `payment_status`, `payment_method`, `payment_time`, `notes`, `cancel_reason`, `created_at`, `updated_at`) VALUES
(1, 'ORD-221201-A3-01', 3, 1, 'Budi Santoso', '081111111111', 5, NULL, 100000.00, 10000.00, 5000.00, 0.00, 115000.00, 'served', 'unpaid', NULL, NULL, NULL, NULL, '2025-12-21 18:45:43', '2025-12-21 19:45:43'),
(2, 'ORD-221201-B2-02', 7, 2, 'Siti Rahayu', '081222222222', 6, NULL, 150000.00, 15000.00, 7500.00, 0.00, 172500.00, 'payment_pending', 'unpaid', NULL, NULL, NULL, NULL, '2025-12-21 19:15:43', '2025-12-21 19:45:43'),
(3, 'ORD-221201-A5-03', 5, NULL, 'Guest', NULL, 5, NULL, 80000.00, 8000.00, 4000.00, 0.00, 92000.00, 'cooking', 'unpaid', NULL, NULL, NULL, NULL, '2025-12-21 19:30:43', '2025-12-21 19:45:43');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `menu_item_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `price` decimal(12,2) NOT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('pending','cooking','ready','served','completed','cancelled') DEFAULT 'pending',
  `cooked_by` int(11) DEFAULT NULL COMMENT 'Chef yang memasak',
  `cooked_at` datetime DEFAULT NULL,
  `served_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `menu_item_id`, `quantity`, `price`, `notes`, `status`, `cooked_by`, `cooked_at`, `served_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 2, 35000.00, 'Pedas level 2', 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(2, 1, 19, 2, 8000.00, 'Tanpa es', 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(3, 1, 37, 1, 22000.00, NULL, 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(4, 2, 6, 2, 48000.00, 'Extra sambal', 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(5, 2, 9, 1, 38000.00, NULL, 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(6, 2, 21, 2, 18000.00, NULL, 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(7, 2, 25, 1, 22000.00, 'Less sugar', 'served', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(8, 3, 4, 2, 30000.00, 'Mie extra', 'cooking', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(9, 3, 20, 2, 12000.00, NULL, 'pending', NULL, NULL, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43');

-- --------------------------------------------------------

--
-- Table structure for table `payment_transactions`
--

CREATE TABLE `payment_transactions` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `transaction_type` enum('order_payment','partial_payment','refund','void') DEFAULT 'order_payment',
  `amount` decimal(12,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `status` enum('pending','success','failed','refunded') DEFAULT 'pending',
  `cashier_id` int(11) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL COMMENT 'Nomor referensi dari payment gateway',
  `notes` text DEFAULT NULL COMMENT 'JSON data untuk split payment item_ids',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `id` int(11) NOT NULL,
  `key_name` varchar(100) NOT NULL,
  `value` text NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `data_type` enum('string','integer','decimal','boolean','json') DEFAULT 'string',
  `is_public` tinyint(1) DEFAULT 0 COMMENT 'Bisa diakses frontend',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`id`, `key_name`, `value`, `description`, `data_type`, `is_public`, `created_at`, `updated_at`) VALUES
(1, 'restaurant_name', 'Resto Nusantara', 'Nama restoran', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(2, 'restaurant_address', 'Jl. Merdeka No. 123, Jakarta', 'Alamat restoran', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(3, 'restaurant_phone', '021-12345678', 'Nomor telepon restoran', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(4, 'restaurant_email', 'info@restonusantara.com', 'Email restoran', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(5, 'tax_percentage', '10', 'Persentase pajak PB1', 'decimal', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(6, 'service_charge_percentage', '5', 'Persentase service charge', 'decimal', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(7, 'loyalty_points_per_thousand', '1', 'Poin loyalty per Rp 1000', 'integer', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(8, 'min_points_redeem', '100', 'Minimum poin untuk redeem', 'integer', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(9, 'point_value', '100', 'Nilai 1 poin dalam Rupiah', 'integer', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(10, 'opening_time', '10:00', 'Jam buka', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(11, 'closing_time', '22:00', 'Jam tutup', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(12, 'currency', 'IDR', 'Mata uang', 'string', 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(13, 'timezone', 'Asia/Jakarta', 'Timezone', 'string', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(14, 'receipt_footer', 'Terima kasih atas kunjungan Anda!', 'Footer struk', 'string', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(15, 'allow_split_payment', '1', 'Izinkan split payment', 'boolean', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(16, 'require_customer_for_dine_in', '0', 'Wajib input customer untuk dine-in', 'boolean', 0, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(17, 'bank_bca_account', '1234567890', 'Nomor rekening BCA', 'string', 0, '2025-12-21 20:15:16', '2025-12-21 20:15:16'),
(18, 'bank_bca_name', 'RESTO NUSANTARA', 'Nama rekening BCA', 'string', 0, '2025-12-21 20:15:16', '2025-12-21 20:15:16'),
(19, 'bank_mandiri_account', '0987654321', 'Nomor rekening Mandiri', 'string', 0, '2025-12-21 20:15:16', '2025-12-21 20:15:16'),
(20, 'bank_mandiri_name', 'RESTO NUSANTARA', 'Nama rekening Mandiri', 'string', 0, '2025-12-21 20:15:16', '2025-12-21 20:15:16'),
(21, 'qris_merchant_id', 'RESTONU001', 'Merchant ID QRIS', 'string', 0, '2025-12-21 20:15:16', '2025-12-21 20:15:16');

-- --------------------------------------------------------

--
-- Table structure for table `staff_access_codes`
--

CREATE TABLE `staff_access_codes` (
  `id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `target_role` varchar(50) NOT NULL,
  `is_used` tinyint(1) DEFAULT 0,
  `used_by` int(11) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tables`
--

CREATE TABLE `tables` (
  `id` int(11) NOT NULL,
  `table_number` varchar(20) NOT NULL,
  `capacity` int(11) DEFAULT 4,
  `location` varchar(50) DEFAULT NULL COMMENT 'indoor, outdoor, vip, etc',
  `status` enum('available','occupied','reserved','dirty') DEFAULT 'available',
  `current_order_id` int(11) DEFAULT NULL,
  `qr_code` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `min_dp` decimal(12,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tables`
--

INSERT INTO `tables` (`id`, `table_number`, `capacity`, `location`, `status`, `current_order_id`, `qr_code`, `is_active`, `created_at`, `updated_at`, `min_dp`) VALUES
(1, 'A1', 2, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(2, 'A2', 2, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(3, 'A3', 4, 'indoor', 'occupied', 1, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(4, 'A4', 4, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(5, 'A5', 4, 'indoor', 'occupied', 3, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(6, 'B1', 4, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(7, 'B2', 4, 'indoor', 'occupied', 2, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(8, 'B3', 6, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(9, 'B4', 6, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(10, 'B5', 8, 'indoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 19:45:43', 0.00),
(11, 'C1', 2, 'outdoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 50000.00),
(12, 'C2', 2, 'outdoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 50000.00),
(13, 'C3', 4, 'outdoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 50000.00),
(14, 'C4', 4, 'outdoor', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 50000.00),
(15, 'V1', 8, 'vip', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 100000.00),
(16, 'V2', 10, 'vip', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 100000.00),
(17, 'V3', 12, 'vip', 'available', NULL, NULL, 1, '2025-12-21 19:45:43', '2025-12-21 20:15:16', 100000.00);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `role` enum('admin','manager','chef','waiter','cs') NOT NULL DEFAULT 'waiter',
  `avatar_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `name`, `email`, `phone`, `role`, `avatar_url`, `is_active`, `last_login`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator', 'admin@resto.com', '081234567890', 'admin', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(2, 'manager', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Manager Resto', 'manager@resto.com', '081234567891', 'manager', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(3, 'chef1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Chef Budi', 'chef1@resto.com', '081234567892', 'chef', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(4, 'chef2', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Chef Ani', 'chef2@resto.com', '081234567893', 'chef', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(5, 'waiter1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Waiter Dimas', 'waiter1@resto.com', '081234567894', 'waiter', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(6, 'waiter2', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Waiter Sari', 'waiter2@resto.com', '081234567895', 'waiter', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(7, 'waiter3', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Waiter Rudi', 'waiter3@resto.com', '081234567896', 'waiter', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(8, 'kasir1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Kasir Maya', 'kasir1@resto.com', '081234567897', 'cs', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43'),
(9, 'kasir2', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Kasir Dewi', 'kasir2@resto.com', '081234567898', 'cs', NULL, 1, NULL, '2025-12-21 19:45:43', '2025-12-21 19:45:43');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_daily_sales`
-- (See below for the actual view)
--
CREATE TABLE `v_daily_sales` (
`sale_date` date
,`total_orders` bigint(21)
,`total_revenue` decimal(34,2)
,`total_tax` decimal(34,2)
,`total_service` decimal(34,2)
,`avg_order_value` decimal(16,6)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_kitchen_orders`
-- (See below for the actual view)
--
CREATE TABLE `v_kitchen_orders` (
`order_id` int(11)
,`order_number` varchar(50)
,`table_number` varchar(20)
,`order_status` enum('pending','cooking','ready','served','payment_pending','completed','cancelled')
,`item_id` int(11)
,`menu_name` varchar(150)
,`quantity` int(11)
,`notes` text
,`item_status` enum('pending','cooking','ready','served','completed','cancelled')
,`created_at` timestamp
,`waiting_minutes` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_menu_performance`
-- (See below for the actual view)
--
CREATE TABLE `v_menu_performance` (
`id` int(11)
,`name` varchar(150)
,`category` varchar(100)
,`price` decimal(12,2)
,`total_sold` decimal(32,0)
,`total_revenue` decimal(44,2)
);

-- --------------------------------------------------------

--
-- Structure for view `v_daily_sales`
--
DROP TABLE IF EXISTS `v_daily_sales`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_daily_sales`  AS SELECT cast(`orders`.`created_at` as date) AS `sale_date`, count(0) AS `total_orders`, sum(`orders`.`total_amount`) AS `total_revenue`, sum(`orders`.`tax`) AS `total_tax`, sum(`orders`.`service_charge`) AS `total_service`, avg(`orders`.`total_amount`) AS `avg_order_value` FROM `orders` WHERE `orders`.`status` = 'completed' GROUP BY cast(`orders`.`created_at` as date) ORDER BY cast(`orders`.`created_at` as date) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_kitchen_orders`
--
DROP TABLE IF EXISTS `v_kitchen_orders`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_kitchen_orders`  AS SELECT `o`.`id` AS `order_id`, `o`.`order_number` AS `order_number`, `t`.`table_number` AS `table_number`, `o`.`status` AS `order_status`, `oi`.`id` AS `item_id`, `m`.`name` AS `menu_name`, `oi`.`quantity` AS `quantity`, `oi`.`notes` AS `notes`, `oi`.`status` AS `item_status`, `o`.`created_at` AS `created_at`, timestampdiff(MINUTE,`o`.`created_at`,current_timestamp()) AS `waiting_minutes` FROM (((`orders` `o` join `tables` `t` on(`o`.`table_id` = `t`.`id`)) join `order_items` `oi` on(`o`.`id` = `oi`.`order_id`)) join `menu_items` `m` on(`oi`.`menu_item_id` = `m`.`id`)) WHERE `o`.`status` in ('pending','cooking') ORDER BY `o`.`created_at` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_menu_performance`
--
DROP TABLE IF EXISTS `v_menu_performance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_menu_performance`  AS SELECT `m`.`id` AS `id`, `m`.`name` AS `name`, `c`.`name` AS `category`, `m`.`price` AS `price`, coalesce(sum(`oi`.`quantity`),0) AS `total_sold`, coalesce(sum(`oi`.`quantity` * `oi`.`price`),0) AS `total_revenue` FROM (((`menu_items` `m` left join `categories` `c` on(`m`.`category_id` = `c`.`id`)) left join `order_items` `oi` on(`m`.`id` = `oi`.`menu_item_id`)) left join `orders` `o` on(`oi`.`order_id` = `o`.`id` and `o`.`status` = 'completed')) GROUP BY `m`.`id`, `m`.`name`, `c`.`name`, `m`.`price` ORDER BY coalesce(sum(`oi`.`quantity`),0) DESC ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_table_id` (`table_id`),
  ADD KEY `idx_booking_date` (`booking_date`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_customer_phone` (`customer_phone`),
  ADD KEY `idx_table_date_status` (`table_id`,`booking_date`,`status`),
  ADD KEY `fk_booking_customer` (`customer_id`),
  ADD KEY `fk_booking_confirmer` (`confirmed_by`),
  ADD KEY `idx_bookings_table_date` (`table_id`,`booking_date`,`status`);

--
-- Indexes for table `booking_payments`
--
ALTER TABLE `booking_payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `fk_bookingpayment_cashier` (`cashier_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_sort_order` (`sort_order`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD KEY `idx_phone` (`phone`),
  ADD KEY `idx_membership_tier` (`membership_tier`),
  ADD KEY `idx_loyalty_points` (`loyalty_points`);

--
-- Indexes for table `inventory_logs`
--
ALTER TABLE `inventory_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_menu_item` (`menu_item_id`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_reason` (`reason`),
  ADD KEY `fk_invlog_user` (`user_id`);

--
-- Indexes for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_category` (`category_id`),
  ADD KEY `idx_is_available` (`is_available`),
  ADD KEY `idx_price` (`price`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_target_role` (`target_role`),
  ADD KEY `idx_target_user` (`target_user_id`),
  ADD KEY `idx_is_read` (`is_read`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_number` (`order_number`),
  ADD KEY `idx_order_number` (`order_number`),
  ADD KEY `idx_table_id` (`table_id`),
  ADD KEY `idx_customer_id` (`customer_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_payment_status` (`payment_status`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_waiter_id` (`waiter_id`),
  ADD KEY `idx_status_date` (`status`,`created_at`),
  ADD KEY `fk_order_cashier` (`cashier_id`),
  ADD KEY `idx_orders_role_query` (`status`,`created_at`,`table_id`),
  ADD KEY `idx_orders_table_status` (`table_id`,`status`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_order_id` (`order_id`),
  ADD KEY `idx_menu_item_id` (`menu_item_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `fk_orderitem_chef` (`cooked_by`),
  ADD KEY `idx_order_items_order_status` (`order_id`,`status`);

--
-- Indexes for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_order_id` (`order_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_payment_method` (`payment_method`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `fk_transaction_cashier` (`cashier_id`),
  ADD KEY `idx_transactions_order_type` (`order_id`,`transaction_type`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key_name` (`key_name`),
  ADD KEY `idx_key_name` (`key_name`);

--
-- Indexes for table `staff_access_codes`
--
ALTER TABLE `staff_access_codes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_code` (`code`),
  ADD KEY `idx_is_used` (`is_used`),
  ADD KEY `idx_expires` (`expires_at`),
  ADD KEY `idx_target_role` (`target_role`),
  ADD KEY `fk_code_creator` (`created_by`),
  ADD KEY `fk_code_used_by` (`used_by`);

--
-- Indexes for table `tables`
--
ALTER TABLE `tables`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `table_number` (`table_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_table_number` (`table_number`),
  ADD KEY `idx_current_order` (`current_order_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_role` (`role`),
  ADD KEY `idx_is_active` (`is_active`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `booking_payments`
--
ALTER TABLE `booking_payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `inventory_logs`
--
ALTER TABLE `inventory_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `menu_items`
--
ALTER TABLE `menu_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `staff_access_codes`
--
ALTER TABLE `staff_access_codes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tables`
--
ALTER TABLE `tables`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_booking_confirmer` FOREIGN KEY (`confirmed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_table` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `booking_payments`
--
ALTER TABLE `booking_payments`
  ADD CONSTRAINT `fk_bookingpayment_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookingpayment_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `inventory_logs`
--
ALTER TABLE `inventory_logs`
  ADD CONSTRAINT `fk_invlog_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_invlog_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD CONSTRAINT `fk_menu_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_user` FOREIGN KEY (`target_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_order_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_order_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_order_table` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_order_waiter` FOREIGN KEY (`waiter_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_orderitem_chef` FOREIGN KEY (`cooked_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orderitem_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orderitem_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  ADD CONSTRAINT `fk_transaction_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transaction_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `staff_access_codes`
--
ALTER TABLE `staff_access_codes`
  ADD CONSTRAINT `fk_code_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_code_used_by` FOREIGN KEY (`used_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
