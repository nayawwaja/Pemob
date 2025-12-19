-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 19, 2025 at 03:31 AM
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
CREATE DATABASE IF NOT EXISTS `resto_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `resto_db`;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE IF NOT EXISTS `activity_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID log',
  `user_id` int(11) NOT NULL COMMENT 'FK ke users',
  `action_type` varchar(50) NOT NULL COMMENT 'Jenis aksi',
  `description` text NOT NULL COMMENT 'Deskripsi aktivitas',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP address',
  `user_agent` text DEFAULT NULL COMMENT 'Browser/device info',
  `old_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Data sebelum perubahan' CHECK (json_valid(`old_data`)),
  `new_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Data setelah perubahan' CHECK (json_valid(`new_data`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_log_user` (`user_id`),
  KEY `idx_action` (`action_type`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log aktivitas sistem';

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `user_id`, `action_type`, `description`, `ip_address`, `user_agent`, `old_data`, `new_data`, `created_at`) VALUES
(1, 1, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi occupied', NULL, NULL, NULL, NULL, '2025-12-19 01:09:28'),
(2, 1, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi available', NULL, NULL, NULL, NULL, '2025-12-19 01:09:31'),
(3, 1, 'CREATE_ORDER', 'Order baru ORD-190210-4 (Meja 4)', NULL, NULL, NULL, NULL, '2025-12-19 01:10:41'),
(4, 1, 'UPDATE_STATUS', 'Order #1 -> cooking', NULL, NULL, NULL, NULL, '2025-12-19 01:10:45'),
(5, 1, 'UPDATE_STATUS', 'Order #1 -> ready', NULL, NULL, NULL, NULL, '2025-12-19 01:10:46'),
(6, 4, 'LOGIN', 'User logged in', NULL, NULL, NULL, NULL, '2025-12-19 01:11:14'),
(7, 4, 'UPDATE_STATUS', 'Order #1 -> served', NULL, NULL, NULL, NULL, '2025-12-19 01:11:17'),
(8, 2, 'LOGIN', 'User logged in', NULL, NULL, NULL, NULL, '2025-12-19 01:11:33'),
(9, 2, 'CLOCK_IN', 'Staff memulai shift kerja', NULL, NULL, NULL, NULL, '2025-12-19 01:11:38'),
(10, 2, 'CREATE_BOOKING', 'Booking RES-5876 dibuat. DP: Rp 75,000', NULL, NULL, NULL, NULL, '2025-12-19 01:12:08'),
(11, 2, 'CHECK_IN', 'Tamu Check-in Kode: RES-5876', NULL, NULL, NULL, NULL, '2025-12-19 01:12:11'),
(12, 2, 'PAYMENT', 'Terima Pembayaran ORD-190210-4 via QRIS (Rp 40,250)', NULL, NULL, NULL, NULL, '2025-12-19 01:12:35'),
(13, 2, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', NULL, NULL, NULL, NULL, '2025-12-19 01:12:55');

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE IF NOT EXISTS `attendance` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID absensi',
  `user_id` int(11) NOT NULL COMMENT 'FK ke users',
  `clock_in` datetime NOT NULL COMMENT 'Waktu masuk',
  `clock_out` datetime DEFAULT NULL COMMENT 'Waktu keluar',
  `duration_minutes` int(11) DEFAULT 0 COMMENT 'Durasi kerja (menit)',
  `status` enum('present','late','absent','leave') DEFAULT 'present' COMMENT 'Status kehadiran',
  `notes` text DEFAULT NULL COMMENT 'Catatan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_attendance_user` (`user_id`),
  KEY `idx_date` (`clock_in`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data absensi staff';

--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`id`, `user_id`, `clock_in`, `clock_out`, `duration_minutes`, `status`, `notes`, `created_at`) VALUES
(1, 2, '2025-12-19 08:11:38', '2025-12-19 08:12:55', 0, 'present', NULL, '2025-12-19 01:11:38');

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE IF NOT EXISTS `bookings` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID booking',
  `booking_code` varchar(20) NOT NULL COMMENT 'Kode booking unik',
  `customer_id` int(11) DEFAULT NULL COMMENT 'FK ke customers',
  `customer_name` varchar(100) NOT NULL COMMENT 'Nama pemesan',
  `customer_phone` varchar(20) NOT NULL COMMENT 'No HP pemesan',
  `customer_email` varchar(100) DEFAULT NULL COMMENT 'Email pemesan',
  `table_id` int(11) NOT NULL COMMENT 'FK ke tables',
  `booking_date` date NOT NULL COMMENT 'Tanggal reservasi',
  `booking_time` time NOT NULL COMMENT 'Jam reservasi',
  `duration_hours` int(11) DEFAULT 2 COMMENT 'Estimasi durasi (jam)',
  `check_in_time` datetime DEFAULT NULL COMMENT 'Waktu check-in aktual',
  `check_out_time` datetime DEFAULT NULL COMMENT 'Waktu check-out',
  `guest_count` int(11) NOT NULL COMMENT 'Jumlah tamu',
  `down_payment` decimal(12,2) DEFAULT 0.00 COMMENT 'Uang muka/DP',
  `dp_payment_method` varchar(20) DEFAULT NULL COMMENT 'Metode bayar DP',
  `status` enum('pending','confirmed','checked_in','completed','cancelled','no_show') DEFAULT 'pending' COMMENT 'Status booking',
  `notes` text DEFAULT NULL COMMENT 'Catatan khusus',
  `special_request` text DEFAULT NULL COMMENT 'Permintaan khusus',
  `created_by` int(11) DEFAULT NULL COMMENT 'FK ke users (pembuat)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_booking_code` (`booking_code`),
  KEY `fk_booking_table` (`table_id`),
  KEY `fk_booking_creator` (`created_by`),
  KEY `idx_date` (`booking_date`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data reservasi';

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `booking_code`, `customer_id`, `customer_name`, `customer_phone`, `customer_email`, `table_id`, `booking_date`, `booking_time`, `duration_hours`, `check_in_time`, `check_out_time`, `guest_count`, `down_payment`, `dp_payment_method`, `status`, `notes`, `special_request`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'RES-5876', NULL, 'ayam', '1234', NULL, 4, '2025-12-19', '08:12:00', 2, '2025-12-19 08:12:11', NULL, 2, 75000.00, NULL, 'checked_in', '', NULL, NULL, '2025-12-19 01:12:08', '2025-12-19 01:12:11');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE IF NOT EXISTS `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID kategori',
  `name` varchar(100) NOT NULL COMMENT 'Nama kategori',
  `icon` varchar(50) DEFAULT '?️' COMMENT 'Emoji atau icon',
  `type` enum('food','drink','other') DEFAULT 'food' COMMENT 'Jenis kategori',
  `sort_order` int(11) DEFAULT 0 COMMENT 'Urutan tampilan',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'Status aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`),
  KEY `idx_active_order` (`is_active`,`sort_order`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Kategori menu';

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `icon`, `type`, `sort_order`, `is_active`, `created_at`) VALUES
(1, 'Makanan Berat', '🍛', 'food', 1, 1, '2025-12-19 00:27:16'),
(2, 'Makanan Ringan', '🍟', 'food', 2, 1, '2025-12-19 00:27:16'),
(3, 'Minuman Dingin', '🥤', 'drink', 3, 1, '2025-12-19 00:27:16'),
(4, 'Minuman Panas', '☕', 'drink', 4, 1, '2025-12-19 00:27:16'),
(5, 'Dessert', '🍰', 'other', 5, 1, '2025-12-19 00:27:16'),
(6, 'Paket Hemat', '📦', 'other', 6, 1, '2025-12-19 00:27:16');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE IF NOT EXISTS `customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID pelanggan',
  `name` varchar(100) NOT NULL COMMENT 'Nama lengkap',
  `phone` varchar(20) DEFAULT NULL COMMENT 'No HP',
  `email` varchar(100) DEFAULT NULL COMMENT 'Email',
  `birth_date` date DEFAULT NULL COMMENT 'Tanggal lahir',
  `loyalty_points` int(11) DEFAULT 0 COMMENT 'Poin loyalti',
  `total_spent` decimal(15,2) DEFAULT 0.00 COMMENT 'Total belanja',
  `visit_count` int(11) DEFAULT 0 COMMENT 'Jumlah kunjungan',
  `membership_tier` enum('bronze','silver','gold','platinum') DEFAULT 'bronze' COMMENT 'Tingkat member',
  `notes` text DEFAULT NULL COMMENT 'Catatan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_phone` (`phone`),
  KEY `idx_tier` (`membership_tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data pelanggan';

-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

CREATE TABLE IF NOT EXISTS `menu_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID menu',
  `category_id` int(11) NOT NULL COMMENT 'FK ke categories',
  `name` varchar(150) NOT NULL COMMENT 'Nama menu',
  `description` text DEFAULT NULL COMMENT 'Deskripsi menu',
  `price` decimal(12,2) NOT NULL COMMENT 'Harga normal',
  `discount_price` decimal(12,2) DEFAULT NULL COMMENT 'Harga diskon (opsional)',
  `image_url` text DEFAULT NULL COMMENT 'URL gambar menu',
  `stock` int(11) DEFAULT 0 COMMENT 'Jumlah stok tersedia',
  `min_stock_alert` int(11) DEFAULT 5 COMMENT 'Batas peringatan stok menipis',
  `ingredients` text DEFAULT NULL COMMENT 'Daftar bahan (untuk info alergi)',
  `allergens` text DEFAULT NULL COMMENT 'Informasi alergen',
  `preparation_time` int(11) DEFAULT 15 COMMENT 'Estimasi waktu masak (menit)',
  `is_available` tinyint(1) DEFAULT 1 COMMENT '1=Tersedia, 0=Habis',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '1=Aktif, 0=Dihapus',
  `is_featured` tinyint(1) DEFAULT 0 COMMENT '1=Menu unggulan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_menu_category` (`category_id`),
  KEY `idx_available` (`is_available`,`is_active`),
  KEY `idx_stock` (`stock`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daftar menu restoran';

--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`id`, `category_id`, `name`, `description`, `price`, `discount_price`, `image_url`, `stock`, `min_stock_alert`, `ingredients`, `allergens`, `preparation_time`, `is_available`, `is_active`, `is_featured`, `created_at`, `updated_at`) VALUES
(1, 1, 'Nasi Goreng Spesial', 'Nasi goreng dengan telur, ayam, dan sayuran segar', 25000.00, NULL, NULL, 100, 5, NULL, NULL, 10, 1, 1, 1, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(2, 1, 'Ayam Bakar Madu', 'Ayam kampung bakar dengan saus madu spesial', 35000.00, 20000.00, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRBVzIecyW45jTME4Z6faiZ_B62Qjk5AYFO-g&s', 49, 5, NULL, NULL, 20, 1, 1, 1, '2025-12-19 00:27:16', '2025-12-19 01:10:41'),
(3, 1, 'Mie Goreng Seafood', 'Mie goreng dengan udang, cumi, dan kerang', 30000.00, NULL, NULL, 80, 5, NULL, NULL, 15, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(4, 2, 'Kentang Goreng', 'Kentang goreng crispy dengan saus sambal', 15000.00, NULL, NULL, 100, 5, NULL, NULL, 8, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(5, 2, 'Pisang Goreng Keju', 'Pisang goreng dengan taburan keju dan coklat', 12000.00, NULL, NULL, 60, 5, NULL, NULL, 10, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(6, 3, 'Es Teh Manis', 'Teh manis dingin segar', 5000.00, NULL, NULL, 200, 5, NULL, NULL, 2, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(7, 3, 'Es Jeruk', 'Jeruk peras segar dengan es', 8000.00, NULL, NULL, 150, 5, NULL, NULL, 3, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(8, 4, 'Kopi Hitam', 'Kopi hitam tubruk premium', 8000.00, NULL, NULL, 100, 5, NULL, NULL, 5, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(9, 4, 'Teh Tarik', 'Teh tarik khas Malaysia', 12000.00, NULL, NULL, 80, 5, NULL, NULL, 5, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(10, 5, 'Es Krim Coklat', 'Es krim coklat premium 2 scoop', 15000.00, NULL, NULL, 50, 5, NULL, NULL, 3, 1, 1, 0, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(11, 6, 'Paket Hemat 1', 'Nasi + Ayam Goreng + Es Teh', 35000.00, NULL, NULL, 30, 5, NULL, NULL, 15, 1, 1, 1, '2025-12-19 00:27:16', '2025-12-19 00:27:16');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID notifikasi',
  `target_role` enum('admin','manager','cs','waiter','chef') DEFAULT NULL COMMENT 'Role penerima',
  `target_user_id` int(11) DEFAULT NULL COMMENT 'User spesifik penerima',
  `title` varchar(100) NOT NULL COMMENT 'Judul notifikasi',
  `message` text NOT NULL COMMENT 'Isi pesan',
  `type` enum('info','warning','success','error') DEFAULT 'info' COMMENT 'Jenis notifikasi',
  `action_url` varchar(255) DEFAULT NULL COMMENT 'Link aksi (opsional)',
  `is_read` tinyint(1) DEFAULT 0 COMMENT '0=Belum dibaca, 1=Sudah dibaca',
  `read_at` datetime DEFAULT NULL COMMENT 'Waktu dibaca',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_target_role` (`target_role`),
  KEY `idx_target_user` (`target_user_id`),
  KEY `idx_read` (`is_read`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notifikasi internal';

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `target_role`, `target_user_id`, `title`, `message`, `type`, `action_url`, `is_read`, `read_at`, `created_at`) VALUES
(1, 'chef', NULL, 'Order Baru', 'Meja 4 memesan makanan.', 'info', NULL, 0, NULL, '2025-12-19 01:10:41'),
(2, 'waiter', NULL, 'Update Status', 'Order #1 siap diantar!', 'info', NULL, 0, NULL, '2025-12-19 01:10:46');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE IF NOT EXISTS `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID order',
  `order_number` varchar(50) NOT NULL COMMENT 'Nomor order unik',
  `table_id` int(11) NOT NULL COMMENT 'FK ke tables',
  `customer_id` int(11) DEFAULT NULL COMMENT 'FK ke customers (opsional)',
  `customer_name` varchar(100) DEFAULT 'Guest' COMMENT 'Nama pelanggan',
  `customer_phone` varchar(20) DEFAULT NULL COMMENT 'No HP pelanggan',
  `waiter_id` int(11) DEFAULT NULL COMMENT 'FK ke users (waiter)',
  `subtotal` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Total sebelum pajak',
  `tax` decimal(12,2) DEFAULT 0.00 COMMENT 'Pajak (10%)',
  `service_charge` decimal(12,2) DEFAULT 0.00 COMMENT 'Service charge (5%)',
  `discount` decimal(12,2) DEFAULT 0.00 COMMENT 'Diskon',
  `total_amount` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Total akhir',
  `status` enum('pending','cooking','ready','served','payment_pending','completed','cancelled') DEFAULT 'pending' COMMENT 'Status order',
  `payment_method` varchar(20) DEFAULT NULL COMMENT 'Metode pembayaran',
  `payment_status` varchar(20) DEFAULT 'unpaid' COMMENT 'Status pembayaran',
  `payment_ref` varchar(100) DEFAULT NULL COMMENT 'Referensi pembayaran',
  `payment_time` datetime DEFAULT NULL COMMENT 'Waktu pembayaran',
  `cashier_id` int(11) DEFAULT NULL COMMENT 'FK ke users (kasir)',
  `notes` text DEFAULT NULL COMMENT 'Catatan order',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_order_number` (`order_number`),
  KEY `fk_order_table` (`table_id`),
  KEY `fk_order_waiter` (`waiter_id`),
  KEY `idx_status` (`status`),
  KEY `idx_payment` (`payment_status`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data pesanan';

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_number`, `table_id`, `customer_id`, `customer_name`, `customer_phone`, `waiter_id`, `subtotal`, `tax`, `service_charge`, `discount`, `total_amount`, `status`, `payment_method`, `payment_status`, `payment_ref`, `payment_time`, `cashier_id`, `notes`, `created_at`, `updated_at`) VALUES
(1, 'ORD-190210-4', 4, NULL, 'Guest', NULL, 1, 0.00, 0.00, 0.00, 0.00, 40250.00, 'completed', 'qris', 'paid', NULL, '2025-12-19 08:12:35', 2, NULL, '2025-12-19 01:10:41', '2025-12-19 01:12:35'),
(2, 'DP-251219-1', 4, NULL, 'ayam (Deposit Booking)', NULL, NULL, 0.00, 0.00, 0.00, 0.00, 75000.00, 'completed', 'transfer', 'paid', NULL, '2025-12-19 08:12:08', 2, NULL, '2025-12-19 01:12:08', '2025-12-19 01:12:08');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID item',
  `order_id` int(11) NOT NULL COMMENT 'FK ke orders',
  `menu_item_id` int(11) NOT NULL COMMENT 'FK ke menu_items',
  `quantity` int(11) NOT NULL COMMENT 'Jumlah pesanan',
  `price` decimal(12,2) NOT NULL COMMENT 'Harga satuan',
  `notes` text DEFAULT NULL COMMENT 'Catatan khusus item',
  `item_status` enum('pending','cooking','ready','served') DEFAULT 'pending' COMMENT 'Status item',
  PRIMARY KEY (`id`),
  KEY `fk_item_order` (`order_id`),
  KEY `fk_item_menu` (`menu_item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Detail item pesanan';

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `menu_item_id`, `quantity`, `price`, `notes`, `item_status`) VALUES
(1, 1, 2, 1, 35000.00, '', 'pending');

-- --------------------------------------------------------

--
-- Table structure for table `payment_transactions`
--

CREATE TABLE IF NOT EXISTS `payment_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID transaksi',
  `order_id` int(11) DEFAULT NULL COMMENT 'FK ke orders',
  `booking_id` int(11) DEFAULT NULL COMMENT 'FK ke bookings (untuk DP)',
  `transaction_type` enum('order_payment','dp_payment','refund') NOT NULL COMMENT 'Jenis transaksi',
  `amount` decimal(12,2) NOT NULL COMMENT 'Nominal',
  `payment_method` varchar(20) NOT NULL COMMENT 'Metode pembayaran',
  `reference_number` varchar(100) DEFAULT NULL COMMENT 'Nomor referensi',
  `status` enum('pending','success','failed','refunded') DEFAULT 'pending' COMMENT 'Status',
  `cashier_id` int(11) DEFAULT NULL COMMENT 'FK ke users (kasir)',
  `notes` text DEFAULT NULL COMMENT 'Catatan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_payment_order` (`order_id`),
  KEY `fk_payment_booking` (`booking_id`),
  KEY `idx_method` (`payment_method`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Riwayat transaksi pembayaran';

-- --------------------------------------------------------

--
-- Table structure for table `promo_codes`
--

CREATE TABLE IF NOT EXISTS `promo_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID promo',
  `code` varchar(30) NOT NULL COMMENT 'Kode promo',
  `name` varchar(100) NOT NULL COMMENT 'Nama promo',
  `description` text DEFAULT NULL COMMENT 'Deskripsi',
  `discount_type` enum('percentage','fixed') NOT NULL COMMENT 'Jenis diskon',
  `discount_value` decimal(12,2) NOT NULL COMMENT 'Nilai diskon',
  `min_order` decimal(12,2) DEFAULT 0.00 COMMENT 'Minimum order',
  `max_discount` decimal(12,2) DEFAULT NULL COMMENT 'Maksimum diskon (untuk %)',
  `usage_limit` int(11) DEFAULT NULL COMMENT 'Batas penggunaan',
  `used_count` int(11) DEFAULT 0 COMMENT 'Jumlah sudah digunakan',
  `start_date` date DEFAULT NULL COMMENT 'Tanggal mulai',
  `end_date` date DEFAULT NULL COMMENT 'Tanggal berakhir',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'Status aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_promo_code` (`code`),
  KEY `idx_active_date` (`is_active`,`start_date`,`end_date`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Kode promo';

--
-- Dumping data for table `promo_codes`
--

INSERT INTO `promo_codes` (`id`, `code`, `name`, `description`, `discount_type`, `discount_value`, `min_order`, `max_discount`, `usage_limit`, `used_count`, `start_date`, `end_date`, `is_active`, `created_at`) VALUES
(1, 'WELCOME10', 'Diskon Pelanggan Baru', NULL, 'percentage', 10.00, 50000.00, 25000.00, NULL, 0, '2025-12-19', '2026-01-18', 1, '2025-12-19 00:27:17'),
(2, 'HEMAT25K', 'Potongan Langsung 25rb', NULL, 'fixed', 25000.00, 100000.00, NULL, NULL, 0, '2025-12-19', '2026-01-02', 1, '2025-12-19 00:27:17');

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE IF NOT EXISTS `settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID setting',
  `key_name` varchar(50) NOT NULL COMMENT 'Nama key',
  `value` text NOT NULL COMMENT 'Nilai',
  `description` text DEFAULT NULL COMMENT 'Deskripsi',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key` (`key_name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pengaturan sistem';

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`id`, `key_name`, `value`, `description`, `updated_at`) VALUES
(1, 'restaurant_name', 'Resto Pro', 'Nama restoran', '2025-12-19 00:27:17'),
(2, 'restaurant_address', 'Jl. Contoh No. 123, Jakarta', 'Alamat restoran', '2025-12-19 00:27:17'),
(3, 'restaurant_phone', '021-1234567', 'Nomor telepon', '2025-12-19 00:27:17'),
(4, 'tax_percentage', '10', 'Persentase pajak (PB1)', '2025-12-19 00:27:17'),
(5, 'service_charge_percentage', '5', 'Persentase service charge', '2025-12-19 00:27:17'),
(6, 'currency', 'IDR', 'Mata uang', '2025-12-19 00:27:17'),
(7, 'timezone', 'Asia/Jakarta', 'Zona waktu', '2025-12-19 00:27:17'),
(8, 'opening_time', '10:00', 'Jam buka', '2025-12-19 00:27:17'),
(9, 'closing_time', '22:00', 'Jam tutup', '2025-12-19 00:27:17'),
(10, 'loyalty_points_per_thousand', '1', 'Poin per Rp 1000', '2025-12-19 00:27:17');

-- --------------------------------------------------------

--
-- Table structure for table `staff_access_codes`
--

CREATE TABLE IF NOT EXISTS `staff_access_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID kode',
  `code` varchar(30) NOT NULL COMMENT 'Kode akses unik',
  `target_role` enum('manager','cs','waiter','chef') NOT NULL COMMENT 'Role tujuan',
  `is_used` tinyint(1) DEFAULT 0 COMMENT '0=Belum dipakai, 1=Sudah dipakai',
  `used_by_user_id` int(11) DEFAULT NULL COMMENT 'FK ke users yang menggunakan',
  `used_at` datetime DEFAULT NULL COMMENT 'Waktu digunakan',
  `expires_at` datetime DEFAULT NULL COMMENT 'Waktu kadaluarsa',
  `created_by` int(11) NOT NULL COMMENT 'FK ke users (pembuat)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_code` (`code`),
  KEY `fk_code_creator` (`created_by`),
  KEY `idx_used` (`is_used`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Kode akses staff';

-- --------------------------------------------------------

--
-- Table structure for table `tables`
--

CREATE TABLE IF NOT EXISTS `tables` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID meja',
  `table_number` varchar(10) NOT NULL COMMENT 'Nomor meja (T-01, VIP-01)',
  `capacity` int(11) NOT NULL COMMENT 'Kapasitas orang',
  `status` enum('available','reserved','occupied','dirty') DEFAULT 'available' COMMENT 'Status meja',
  `location` varchar(50) DEFAULT 'Indoor' COMMENT 'Lokasi (Indoor/Outdoor/VIP Room)',
  `current_order_id` int(11) DEFAULT NULL COMMENT 'ID order aktif di meja ini',
  `min_dp` decimal(12,2) NOT NULL DEFAULT 100000.00 COMMENT 'Minimum DP untuk reservasi',
  `notes` text DEFAULT NULL COMMENT 'Catatan khusus meja',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_table_number` (`table_number`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data meja restoran';

--
-- Dumping data for table `tables`
--

INSERT INTO `tables` (`id`, `table_number`, `capacity`, `status`, `location`, `current_order_id`, `min_dp`, `notes`, `created_at`) VALUES
(1, 'T-01', 2, 'available', 'Indoor', NULL, 50000.00, NULL, '2025-12-19 00:27:16'),
(2, 'T-02', 2, 'available', 'Indoor', NULL, 50000.00, NULL, '2025-12-19 00:27:16'),
(3, 'T-03', 4, 'available', 'Indoor', NULL, 75000.00, NULL, '2025-12-19 00:27:16'),
(4, 'T-04', 4, 'dirty', 'Indoor', NULL, 75000.00, NULL, '2025-12-19 00:27:16'),
(5, 'T-05', 6, 'available', 'Indoor', NULL, 100000.00, NULL, '2025-12-19 00:27:16'),
(6, 'T-06', 6, 'available', 'Outdoor', NULL, 100000.00, NULL, '2025-12-19 00:27:16'),
(7, 'T-07', 4, 'available', 'Outdoor', NULL, 75000.00, NULL, '2025-12-19 00:27:16'),
(8, 'T-08', 4, 'available', 'Outdoor', NULL, 75000.00, NULL, '2025-12-19 00:27:16'),
(9, 'VIP-01', 10, 'available', 'VIP Room', NULL, 250000.00, NULL, '2025-12-19 00:27:16'),
(10, 'VIP-02', 12, 'available', 'VIP Room', NULL, 300000.00, NULL, '2025-12-19 00:27:16');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID unik pengguna',
  `name` varchar(100) NOT NULL COMMENT 'Nama lengkap',
  `email` varchar(100) NOT NULL COMMENT 'Email untuk login',
  `password` varchar(255) NOT NULL COMMENT 'Password terenkripsi MD5',
  `phone` varchar(20) DEFAULT NULL COMMENT 'Nomor telepon',
  `role` enum('admin','manager','cs','waiter','chef') NOT NULL DEFAULT 'waiter' COMMENT 'Peran pengguna',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '1=Aktif, 0=Nonaktif',
  `fcm_token` text DEFAULT NULL COMMENT 'Token untuk Firebase Push Notification',
  `avatar_url` varchar(255) DEFAULT NULL COMMENT 'URL foto profil',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Waktu dibuat',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Waktu diperbarui',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tabel pengguna sistem';

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`, `is_active`, `fcm_token`, `avatar_url`, `created_at`, `updated_at`) VALUES
(1, 'Super Admin', 'admin@resto.com', '0192023a7bbd73250516f069df18b500', NULL, 'admin', 1, NULL, NULL, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(2, 'Demo Manager', 'manager@resto.com', '0795151defba7a4b5dfa89170de46277', NULL, 'manager', 1, NULL, NULL, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(3, 'Demo CS', 'cs@resto.com', '8551e0027ff3a8de9662eb3b8a16c23e', NULL, 'cs', 1, NULL, NULL, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(4, 'Demo Waiter', 'waiter@resto.com', 'e82d611b52164e7474fd1f3b6d2c68db', NULL, 'waiter', 1, NULL, NULL, '2025-12-19 00:27:16', '2025-12-19 00:27:16'),
(5, 'Demo Chef', 'chef@resto.com', '677dbf3b047f16c7c5b5554a8259f2eb', NULL, 'chef', 1, NULL, NULL, '2025-12-19 00:27:16', '2025-12-19 00:27:16');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `fk_attendance_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_booking_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_booking_table` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`);

--
-- Constraints for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD CONSTRAINT `fk_menu_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_order_table` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`),
  ADD CONSTRAINT `fk_order_waiter` FOREIGN KEY (`waiter_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_item_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`),
  ADD CONSTRAINT `fk_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
