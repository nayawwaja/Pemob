-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 18, 2025 at 11:47 PM
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
CREATE DATABASE IF NOT EXISTS `resto_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `resto_db`;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
CREATE TABLE IF NOT EXISTS `activity_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `action_type` varchar(50) NOT NULL,
  `description` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=187 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `activity_logs`
--

TRUNCATE TABLE `activity_logs`;
--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `user_id`, `action_type`, `description`, `created_at`) VALUES
(1, 2, 'LOGIN', 'User logged in', '2025-12-01 00:08:56'),
(2, 1, 'LOGIN', 'User logged in', '2025-12-01 00:28:09'),
(3, 3, 'LOGIN', 'User logged in', '2025-12-01 00:35:54'),
(4, 4, 'LOGIN', 'User logged in', '2025-12-01 00:36:50'),
(5, 1, 'LOGIN', 'User logged in', '2025-12-01 00:59:49'),
(6, 4, 'LOGIN', 'User logged in', '2025-12-01 01:01:20'),
(7, 3, 'LOGIN', 'User logged in', '2025-12-01 01:01:45'),
(8, 2, 'LOGIN', 'User logged in', '2025-12-01 01:02:23'),
(9, 2, 'UPDATE_TABLE', 'Mengubah status meja ID 6 menjadi dirty', '2025-12-01 01:03:56'),
(10, 4, 'LOGIN', 'User logged in', '2025-12-01 01:04:10'),
(11, 4, 'UPDATE_TABLE', 'Mengubah status meja ID 6 menjadi available', '2025-12-01 01:04:12'),
(12, 4, 'LOGIN', 'User logged in', '2025-12-01 01:12:41'),
(13, 2, 'LOGIN', 'User logged in', '2025-12-01 02:48:44'),
(14, 2, 'UPDATE_TABLE', 'Mengubah status meja ID 6 menjadi reserved', '2025-12-01 03:04:14'),
(15, 2, 'UPDATE_TABLE', 'Mengubah status meja ID 6 menjadi available', '2025-12-01 03:04:17'),
(16, 1, 'LOGIN', 'User logged in', '2025-12-01 03:06:47'),
(18, 1, 'CREATE_BOOKING', 'Booking RES-1384 dibuat (DP: 200)', '2025-12-01 03:48:19'),
(19, 1, 'UPDATE_TABLE', 'Mengubah status meja ID 2 menjadi available', '2025-12-01 03:48:40'),
(20, 1, 'UPDATE_TABLE', 'Mengubah status meja ID 2 menjadi occupied', '2025-12-01 04:39:51'),
(22, 1, 'CREATE_ORDER', 'Order baru ORD-0548-5 di Meja ID 5', '2025-12-01 04:48:15'),
(23, 3, 'LOGIN', 'User logged in', '2025-12-01 04:52:01'),
(24, 3, 'UPDATE_STATUS', 'Order #1 status -> cooking', '2025-12-01 04:52:04'),
(25, 3, 'UPDATE_STATUS', 'Order #1 status -> ready', '2025-12-01 04:52:07'),
(26, 4, 'LOGIN', 'User logged in', '2025-12-01 04:52:15'),
(27, 4, 'UPDATE_STATUS', 'Order #1 status -> served', '2025-12-01 04:52:19'),
(28, 2, 'LOGIN', 'User logged in', '2025-12-01 04:52:43'),
(29, 2, 'CREATE_BOOKING', 'Booking RES-6341 dibuat (DP: 20)', '2025-12-01 04:57:13'),
(30, 2, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi reserved', '2025-12-01 04:57:21'),
(31, 2, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi available', '2025-12-01 04:57:26'),
(32, 2, 'CREATE_BOOKING', 'Booking RES-8530 dibuat (DP: 21314)', '2025-12-01 04:57:55'),
(33, 2, 'UPDATE_TABLE', 'Ubah status meja ID 6 jadi occupied', '2025-12-01 04:58:06'),
(34, 2, 'UPDATE_TABLE', 'Ubah status meja ID 6 jadi available', '2025-12-01 04:58:08'),
(35, 2, 'LOGIN', 'User logged in', '2025-12-01 05:39:08'),
(36, 2, 'CREATE_ORDER', 'Order baru ORD-0640-7 di Meja ID 7', '2025-12-01 05:40:28'),
(37, 2, 'CREATE_BOOKING', 'Booking RES-4559 dibuat (DP: 12)', '2025-12-01 05:41:09'),
(38, 2, 'UPDATE_TABLE', 'Ubah status meja ID 3 jadi available', '2025-12-01 05:41:17'),
(41, 1, 'LOGIN', 'User logged in', '2025-12-01 06:24:04'),
(42, 1, 'UPDATE_TABLE', 'Ubah status meja ID 7 jadi available', '2025-12-01 06:27:48'),
(43, 1, 'UPDATE_TABLE', 'Ubah status meja ID 5 jadi available', '2025-12-01 06:27:49'),
(45, 1, 'UPDATE_STATUS', 'Order #2 status -> cooking', '2025-12-01 09:19:10'),
(46, 1, 'UPDATE_STATUS', 'Order #2 status -> ready', '2025-12-01 09:19:14'),
(47, 1, 'UPDATE_STATUS', 'Order #2 status -> served', '2025-12-01 09:19:32'),
(48, 1, 'CREATE_BOOKING', 'Booking RES-9392 dibuat (DP: 21)', '2025-12-01 09:41:08'),
(49, 2, 'LOGIN', 'User logged in', '2025-12-01 09:41:36'),
(50, 2, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-01 09:41:40'),
(51, 2, 'CREATE_ORDER', 'Order baru ORD-011042-9 (Meja 9)', '2025-12-01 09:42:09'),
(52, 2, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-01 09:42:39'),
(53, 3, 'LOGIN', 'User logged in', '2025-12-01 09:42:50'),
(54, 3, 'UPDATE_STATUS', 'Order #3 -> cooking', '2025-12-01 09:42:54'),
(55, 3, 'UPDATE_STATUS', 'Order #3 -> ready', '2025-12-01 09:42:58'),
(56, 4, 'LOGIN', 'User logged in', '2025-12-01 09:43:07'),
(57, 4, 'UPDATE_STATUS', 'Order #3 -> served', '2025-12-01 09:43:10'),
(58, 2, 'LOGIN', 'User logged in', '2025-12-01 09:43:59'),
(59, 2, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-01 09:44:05'),
(60, 2, 'UPDATE_TABLE', 'Ubah status meja ID 9 jadi dirty', '2025-12-01 09:44:15'),
(61, 2, 'UPDATE_TABLE', 'Ubah status meja ID 6 jadi available', '2025-12-01 09:45:15'),
(62, 2, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-01 09:45:58'),
(63, 1, 'LOGIN', 'User logged in', '2025-12-01 09:46:29'),
(65, 1, 'UPDATE_STATUS', 'Order #1 -> payment_pending', '2025-12-01 10:55:18'),
(66, 1, 'PAYMENT', 'Terima Pembayaran ORD-0548-5 via DEBIT (Rp 60,000)', '2025-12-01 11:30:18'),
(67, 1, 'PAYMENT', 'Terima Pembayaran ORD-0640-7 via CASH (Rp 20,000)', '2025-12-01 11:30:48'),
(68, 4, 'LOGIN', 'User logged in', '2025-12-01 11:38:43'),
(69, 4, 'UPDATE_TABLE', 'Ubah status meja ID 5 jadi available', '2025-12-01 11:38:47'),
(70, 4, 'UPDATE_TABLE', 'Ubah status meja ID 7 jadi available', '2025-12-01 11:38:47'),
(71, 4, 'UPDATE_TABLE', 'Ubah status meja ID 9 jadi available', '2025-12-01 11:38:49'),
(72, 4, 'CREATE_ORDER', 'Order baru ORD-011239-9 (Meja 9)', '2025-12-01 11:39:05'),
(73, 1, 'LOGIN', 'User logged in', '2025-12-01 11:39:27'),
(74, 1, 'UPDATE_STATUS', 'Order #4 -> served', '2025-12-01 11:39:47'),
(75, 1, 'CREATE_BOOKING', 'Booking RES-8723 dibuat (DP: 1)', '2025-12-01 11:51:55'),
(76, 1, 'UPDATE_TABLE', 'Ubah status meja ID 8 jadi available', '2025-12-01 11:52:03'),
(77, 1, 'CANCEL_BOOKING', 'Cancel booking a.n 121311', '2025-12-01 11:52:07'),
(78, 1, 'CREATE_BOOKING', 'Booking RES-1078 dibuat (DP: 0)', '2025-12-01 11:53:54'),
(79, 1, 'CHECK_IN', 'Tamu Check-in Kode: RES-1078', '2025-12-01 11:53:59'),
(80, 1, 'UPDATE_TABLE', 'Ubah status meja ID 8 jadi available', '2025-12-01 11:54:07'),
(81, 1, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi reserved', '2025-12-01 12:10:25'),
(82, 1, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi reserved', '2025-12-01 12:10:27'),
(83, 1, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi available', '2025-12-01 12:10:31'),
(84, 1, 'CREATE_BOOKING', 'Booking RES-7315 dibuat. DP: Rp 100,000', '2025-12-01 12:10:52'),
(85, 1, 'CHECK_IN', 'Tamu Check-in Kode: RES-7315', '2025-12-01 12:10:57'),
(86, 1, 'PAYMENT', 'Terima Pembayaran ORD-011042-9 via QRIS (Rp 120,750)', '2025-12-01 12:26:52'),
(87, 1, 'PAYMENT', 'Terima Pembayaran ORD-011239-9 via DEBIT (Rp 103,500)', '2025-12-01 12:40:06'),
(88, 1, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-01 12:40:10'),
(89, 1, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-01 12:40:15'),
(90, 1, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-01 12:40:19'),
(91, 1, 'CREATE_ORDER', 'Order baru ORD-011340-5 (Meja 5)', '2025-12-01 12:40:39'),
(92, 1, 'CREATE_ORDER', 'Order baru ORD-011340-9 (Meja 9)', '2025-12-01 12:40:58'),
(93, 1, 'UPDATE_STATUS', 'Order #8 -> cooking', '2025-12-01 12:41:30'),
(94, 1, 'UPDATE_STATUS', 'Order #6 -> cooking', '2025-12-01 12:41:30'),
(95, 1, 'UPDATE_STATUS', 'Order #8 -> ready', '2025-12-01 12:41:32'),
(96, 1, 'UPDATE_STATUS', 'Order #6 -> ready', '2025-12-01 12:41:32'),
(97, 1, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-01 12:41:40'),
(98, 4, 'LOGIN', 'User logged in', '2025-12-01 12:41:59'),
(99, 4, 'UPDATE_STATUS', 'Order #6 -> served', '2025-12-01 12:42:01'),
(100, 4, 'UPDATE_STATUS', 'Order #8 -> served', '2025-12-01 12:42:02'),
(101, 1, 'LOGIN', 'User logged in', '2025-12-01 12:42:25'),
(102, 1, 'CREATE_ORDER', 'Order baru ORD-040220-8 (Meja 8)', '2025-12-04 01:20:31'),
(103, 1, 'UPDATE_STATUS', 'Order #9 -> cooking', '2025-12-04 01:20:39'),
(104, 1, 'UPDATE_STATUS', 'Order #9 -> ready', '2025-12-04 01:20:41'),
(105, 1, 'UPDATE_STATUS', 'Order #9 -> payment_pending', '2025-12-04 01:20:51'),
(106, 1, 'PAYMENT', 'Terima Pembayaran ORD-040220-8 via CASH (Rp 23,000)', '2025-12-04 01:21:00'),
(107, 1, 'LOGIN', 'User logged in', '2025-12-05 02:05:19'),
(108, 1, 'CREATE_ORDER', 'Order baru ORD-050308-10 (Meja 10)', '2025-12-05 02:08:19'),
(109, 1, 'UPDATE_STATUS', 'Order #10 -> cooking', '2025-12-05 02:08:35'),
(110, 1, 'UPDATE_STATUS', 'Order #10 -> ready', '2025-12-05 02:08:48'),
(111, 2, 'LOGIN', 'User logged in', '2025-12-05 02:09:34'),
(112, 3, 'LOGIN', 'User logged in', '2025-12-05 02:10:04'),
(113, 4, 'LOGIN', 'User logged in', '2025-12-05 02:10:18'),
(114, 4, 'UPDATE_STATUS', 'Order #10 -> served', '2025-12-05 02:10:27'),
(115, 4, 'UPDATE_TABLE', 'Ubah status meja ID 8 jadi available', '2025-12-05 02:10:36'),
(116, 1, 'LOGIN', 'User logged in', '2025-12-05 03:00:52'),
(117, 2, 'LOGIN', 'User logged in', '2025-12-05 03:02:11'),
(118, 3, 'LOGIN', 'User logged in', '2025-12-05 03:02:39'),
(119, 3, 'LOGIN', 'User logged in', '2025-12-05 03:10:24'),
(120, 4, 'LOGIN', 'User logged in', '2025-12-05 03:10:39'),
(121, 1, 'LOGIN', 'User logged in', '2025-12-17 04:19:55'),
(122, 1, 'GENERATE_CODE', 'Membuat kode akses untuk WAITER', '2025-12-17 04:22:27'),
(123, 1, 'CREATE_ORDER', 'Order baru ORD-170523-6 (Meja 6)', '2025-12-17 04:23:43'),
(124, 1, 'UPDATE_STATUS', 'Order #11 -> cooking', '2025-12-17 04:24:05'),
(125, 1, 'UPDATE_STATUS', 'Order #11 -> ready', '2025-12-17 04:24:09'),
(126, 1, 'LOGIN', 'User logged in', '2025-12-17 04:26:09'),
(127, 5, 'LOGIN', 'User logged in', '2025-12-17 04:27:49'),
(128, 5, 'UPDATE_STATUS', 'Order #11 -> served', '2025-12-17 04:28:02'),
(129, 2, 'LOGIN', 'User logged in', '2025-12-17 04:28:25'),
(130, 2, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-17 04:28:33'),
(131, 2, 'PAYMENT', 'Terima Pembayaran ORD-170523-6 via QRIS (Rp 40,250)', '2025-12-17 04:29:29'),
(132, 2, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-17 04:30:12'),
(133, 2, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-17 04:30:19'),
(134, 2, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-17 04:31:46'),
(135, 1, 'LOGIN', 'User logged in', '2025-12-17 04:32:34'),
(136, 1, 'GENERATE_CODE', 'Membuat kode akses untuk WAITER', '2025-12-17 04:33:31'),
(137, 1, 'CREATE_ORDER', 'Order baru ORD-170537-8 (Meja 8)', '2025-12-17 04:37:00'),
(138, 1, 'UPDATE_STATUS', 'Order #12 -> cooking', '2025-12-17 04:37:18'),
(139, 1, 'UPDATE_STATUS', 'Order #12 -> ready', '2025-12-17 04:37:23'),
(140, 1, 'CREATE_BOOKING', 'Booking RES-8023 dibuat. DP: Rp 100,000', '2025-12-17 04:38:28'),
(141, 1, 'CHECK_IN', 'Tamu Check-in Kode: RES-8023', '2025-12-17 04:38:52'),
(142, 4, 'LOGIN', 'User logged in', '2025-12-17 04:39:26'),
(143, 4, 'UPDATE_STATUS', 'Order #12 -> served', '2025-12-17 04:39:36'),
(144, 4, 'UPDATE_TABLE', 'Ubah status meja ID 6 jadi available', '2025-12-17 04:39:41'),
(145, 2, 'LOGIN', 'User logged in', '2025-12-17 04:40:11'),
(146, 2, 'CLOCK_IN', 'Staff memulai shift kerja', '2025-12-17 04:40:31'),
(147, 2, 'PAYMENT', 'Terima Pembayaran ORD-170537-8 via DEBIT (Rp 23,000)', '2025-12-17 04:40:49'),
(148, 2, 'CLOCK_OUT', 'Staff mengakhiri shift kerja', '2025-12-17 04:41:26'),
(149, 1, 'LOGIN', 'User logged in', '2025-12-18 21:36:37'),
(150, 1, 'CREATE_ORDER', 'Order baru ORD-182238-9 (Meja 9)', '2025-12-18 21:38:18'),
(151, 1, 'UPDATE_STATUS', 'Order #14 -> cooking', '2025-12-18 21:38:29'),
(152, 1, 'UPDATE_STATUS', 'Order #14 -> ready', '2025-12-18 21:38:31'),
(153, 4, 'LOGIN', 'User logged in', '2025-12-18 21:39:00'),
(154, 4, 'UPDATE_STATUS', 'Order #14 -> served', '2025-12-18 21:39:03'),
(155, 4, 'UPDATE_TABLE', 'Ubah status meja ID 8 jadi available', '2025-12-18 21:39:05'),
(156, 1, 'LOGIN', 'User logged in', '2025-12-18 21:39:25'),
(157, 1, 'PAYMENT', 'Terima Pembayaran ORD-182238-9 via TRANSFER (Rp 23,000)', '2025-12-18 21:39:53'),
(158, 1, 'LOGIN', 'User logged in', '2025-12-18 21:40:38'),
(159, 1, 'UPDATE_STATUS', 'Order #10 -> payment_pending', '2025-12-18 21:41:07'),
(160, 1, 'UPDATE_STATUS', 'Order #8 -> payment_pending', '2025-12-18 21:41:09'),
(161, 1, 'UPDATE_STATUS', 'Order #6 -> payment_pending', '2025-12-18 21:41:12'),
(162, 1, 'UPDATE_STATUS', 'Order #10 -> completed', '2025-12-18 21:41:32'),
(163, 1, 'UPDATE_STATUS', 'Order #8 -> completed', '2025-12-18 21:41:35'),
(164, 1, 'UPDATE_STATUS', 'Order #6 -> completed', '2025-12-18 21:41:37'),
(165, 1, 'UPDATE_TABLE', 'Ubah status meja ID 9 jadi dirty', '2025-12-18 21:41:47'),
(166, 1, 'UPDATE_TABLE', 'Ubah status meja ID 9 jadi available', '2025-12-18 21:41:48'),
(167, 1, 'UPDATE_TABLE', 'Ubah status meja ID 10 jadi available', '2025-12-18 21:41:50'),
(168, 1, 'UPDATE_TABLE', 'Ubah status meja ID 5 jadi available', '2025-12-18 21:41:51'),
(169, 1, 'UPDATE_TABLE', 'Ubah status meja ID 1 jadi available', '2025-12-18 21:41:52'),
(170, 1, 'CREATE_ORDER', 'Order baru ORD-182302-4 (Meja 4)', '2025-12-18 22:02:03'),
(171, 1, 'UPDATE_STATUS', 'Order #15 -> cooking', '2025-12-18 22:02:09'),
(172, 1, 'UPDATE_STATUS', 'Order #15 -> ready', '2025-12-18 22:02:10'),
(173, 4, 'LOGIN', 'User logged in', '2025-12-18 22:02:23'),
(174, 4, 'UPDATE_STATUS', 'Order #15 -> served', '2025-12-18 22:02:25'),
(175, 1, 'LOGIN', 'User logged in', '2025-12-18 22:02:43'),
(176, 1, 'CREATE_BOOKING', 'Booking RES-8319 dibuat. DP: Rp 100,000', '2025-12-18 22:21:21'),
(177, 1, 'CHECK_IN', 'Tamu Check-in Kode: RES-8319', '2025-12-18 22:21:29'),
(178, 1, 'PAYMENT', 'Terima Pembayaran ORD-182302-4 via CASH (Rp 23,000)', '2025-12-18 22:35:54'),
(179, 1, 'CREATE_ORDER', 'Order baru ORD-182344-7 (Meja 7)', '2025-12-18 22:44:05'),
(180, 1, 'UPDATE_STATUS', 'Order #17 -> cooking', '2025-12-18 22:44:11'),
(181, 1, 'UPDATE_STATUS', 'Order #17 -> ready', '2025-12-18 22:44:13'),
(182, 4, 'LOGIN', 'User logged in', '2025-12-18 22:44:55'),
(183, 4, 'UPDATE_STATUS', 'Order #17 -> served', '2025-12-18 22:44:57'),
(184, 4, 'UPDATE_TABLE', 'Ubah status meja ID 4 jadi available', '2025-12-18 22:45:00'),
(185, 1, 'LOGIN', 'User logged in', '2025-12-18 22:45:15'),
(186, 1, 'PAYMENT', 'Terima Pembayaran ORD-182344-7 via TRANSFER (Rp 40,250)', '2025-12-18 22:45:31');

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

DROP TABLE IF EXISTS `attendance`;
CREATE TABLE IF NOT EXISTS `attendance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `clock_in` datetime DEFAULT NULL,
  `clock_out` datetime DEFAULT NULL,
  `status` varchar(20) DEFAULT 'present',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `attendance`
--

TRUNCATE TABLE `attendance`;
--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`id`, `user_id`, `clock_in`, `clock_out`, `status`, `created_at`) VALUES
(1, 2, '2025-12-01 16:41:40', '2025-12-01 16:42:39', 'present', '2025-12-01 09:41:40'),
(2, 2, '2025-12-01 16:44:05', '2025-12-01 16:45:58', 'present', '2025-12-01 09:44:05'),
(3, 1, '2025-12-01 19:40:10', '2025-12-01 19:40:15', 'present', '2025-12-01 12:40:10'),
(4, 1, '2025-12-01 19:40:19', '2025-12-01 19:41:40', 'present', '2025-12-01 12:40:19'),
(5, 2, '2025-12-17 11:28:33', '2025-12-17 11:30:12', 'present', '2025-12-17 04:28:33'),
(6, 2, '2025-12-17 11:30:19', '2025-12-17 11:31:46', 'present', '2025-12-17 04:30:19'),
(7, 2, '2025-12-17 11:40:31', '2025-12-17 11:41:26', 'present', '2025-12-17 04:40:31');

-- --------------------------------------------------------

--
-- Table structure for table `attendance_logs`
--

DROP TABLE IF EXISTS `attendance_logs`;
CREATE TABLE IF NOT EXISTS `attendance_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `clock_in` datetime NOT NULL,
  `clock_out` datetime DEFAULT NULL,
  `duration_hours` decimal(5,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `attendance_logs`
--

TRUNCATE TABLE `attendance_logs`;
-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

DROP TABLE IF EXISTS `bookings`;
CREATE TABLE IF NOT EXISTS `bookings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_code` varchar(10) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `customer_name` varchar(100) NOT NULL,
  `customer_phone` varchar(20) NOT NULL,
  `table_id` int(11) NOT NULL,
  `booking_date` date NOT NULL,
  `booking_time` time NOT NULL,
  `check_in_time` datetime DEFAULT NULL,
  `guest_count` int(11) NOT NULL,
  `down_payment` decimal(10,2) DEFAULT 0.00,
  `status` enum('pending','confirmed','checked_in','cancelled','completed') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `table_id` (`table_id`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `bookings`
--

TRUNCATE TABLE `bookings`;
--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `booking_code`, `customer_id`, `customer_name`, `customer_phone`, `table_id`, `booking_date`, `booking_time`, `check_in_time`, `guest_count`, `down_payment`, `status`, `notes`, `created_by`, `created_at`) VALUES
(1, NULL, NULL, 'ya', '083524124293', 6, '2025-12-01', '07:24:00', NULL, 5, 0.00, 'cancelled', ' [Auto-Cancel by System]', NULL, '2025-12-01 00:25:21'),
(2, 'RES-1384', NULL, '123', '123456789090', 2, '2025-12-01', '10:48:00', NULL, 2, 200.00, 'cancelled', ' [Auto-Cancel by System]', NULL, '2025-12-01 03:48:19'),
(3, 'RES-6341', NULL, '123', 'adada', 10, '2025-12-01', '11:56:00', NULL, 2, 20.00, 'cancelled', ' [Auto-Cancel by System]', NULL, '2025-12-01 04:57:13'),
(4, 'RES-8530', NULL, 'ada', 'faf23', 6, '2025-12-01', '11:57:00', NULL, 2, 21314.00, 'cancelled', ' [Auto-Cancel by System]', NULL, '2025-12-01 04:57:55'),
(5, 'RES-4559', NULL, 'dada', 'adad22313', 3, '2025-12-01', '12:40:00', NULL, 2, 12.00, 'cancelled', ' [Auto-Cancel by System]', NULL, '2025-12-01 05:41:09'),
(6, 'RES-9392', NULL, 'a', 'dad', 6, '2025-12-01', '16:40:00', NULL, 6, 21.00, 'cancelled', ' [Auto-Cancel by System]', NULL, '2025-12-01 09:41:08'),
(7, 'RES-8723', NULL, '121311', '13214', 8, '2025-12-01', '18:51:00', NULL, 4, 1.00, 'cancelled', '', NULL, '2025-12-01 11:51:55'),
(8, 'RES-1078', NULL, 'ad', 'ada', 8, '2025-12-01', '18:53:00', '2025-12-01 18:53:59', 2, 0.00, 'checked_in', '', NULL, '2025-12-01 11:53:54'),
(9, 'RES-7315', NULL, '12', '123', 5, '2025-12-01', '19:10:00', '2025-12-01 19:10:57', 2, 100000.00, 'checked_in', '', NULL, '2025-12-01 12:10:52'),
(10, 'RES-8023', NULL, 'm', '098', 1, '2025-12-17', '11:37:00', '2025-12-17 11:38:52', 2, 100000.00, 'checked_in', '', NULL, '2025-12-17 04:38:28'),
(11, 'RES-8319', NULL, 'ayam', '1234567890', 7, '2025-12-19', '05:21:00', '2025-12-19 05:21:29', 2, 100000.00, 'checked_in', '', NULL, '2025-12-18 22:21:21');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
CREATE TABLE IF NOT EXISTS `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `type` enum('food','drink','other') DEFAULT 'food',
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `categories`
--

TRUNCATE TABLE `categories`;
--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `icon`, `type`, `is_active`) VALUES
(1, 'Makanan Berat', '🍽️', 'food', 1),
(2, 'Minuman', '🥤', 'drink', 1),
(3, 'Cemilan', '🍟', 'food', 1);

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
CREATE TABLE IF NOT EXISTS `customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `loyalty_points` int(11) DEFAULT 0,
  `total_spent` decimal(15,2) DEFAULT 0.00,
  `visit_count` int(11) DEFAULT 0,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `customers`
--

TRUNCATE TABLE `customers`;
-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

DROP TABLE IF EXISTS `menu_items`;
CREATE TABLE IF NOT EXISTS `menu_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(12,2) NOT NULL,
  `discount_price` decimal(10,2) DEFAULT NULL,
  `image_url` text DEFAULT NULL,
  `stock` int(11) DEFAULT 0,
  `is_available` tinyint(1) DEFAULT 1,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `menu_items`
--

TRUNCATE TABLE `menu_items`;
--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`id`, `category_id`, `name`, `description`, `price`, `discount_price`, `image_url`, `stock`, `is_available`, `is_active`, `created_at`) VALUES
(1, 1, 'Nasi Goreng Spesial', NULL, 25000.00, NULL, NULL, 100, 1, 1, '2025-11-30 20:05:16'),
(2, 1, 'Ayam Bakar Madu', 'ayamm', 35000.00, NULL, 'https://img-global.cpcdn.com/recipes/0820c8cf5a5e18aa/1200x630cq80/photo.jpg', 41, 1, 1, '2025-11-30 20:05:16'),
(3, 2, 'Es Teh Manis', NULL, 5000.00, NULL, NULL, 200, 1, 1, '2025-11-30 20:05:16'),
(4, 3, 'Kentang Goreng', NULL, 15000.00, NULL, NULL, 50, 1, 1, '2025-11-30 20:05:16'),
(5, 1, 'Nasgor', 'nasigoreng kampung', 20000.00, NULL, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTjijY_85bgwtpHgp2knp6aLWUcEq1l-hs1FhEmNBAS80cfsk0GNhSqJo46Cb9kId7UXnE&usqp=CAU', 10, 1, 1, '2025-12-01 03:07:44');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `target_role` enum('admin','cs','waiter','chef') DEFAULT NULL,
  `target_user_id` int(11) DEFAULT NULL,
  `title` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `notifications`
--

TRUNCATE TABLE `notifications`;
--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `target_role`, `target_user_id`, `title`, `message`, `is_read`, `created_at`) VALUES
(1, 'waiter', NULL, 'Meja Kotor', 'Meja ID 6 perlu dibersihkan.', 0, '2025-12-01 01:03:56'),
(2, 'chef', NULL, 'Order Baru', 'Meja 9 memesan makanan.', 0, '2025-12-01 09:42:09'),
(3, 'waiter', NULL, 'Update Status', 'Order #3 siap diantar!', 0, '2025-12-01 09:42:58'),
(4, 'cs', NULL, 'Update Status', 'Order #1 meminta bill/pembayaran.', 0, '2025-12-01 10:55:18'),
(5, 'chef', NULL, 'Order Baru', 'Meja 9 memesan makanan.', 0, '2025-12-01 11:39:05'),
(6, 'chef', NULL, 'Order Baru', 'Meja 5 memesan makanan.', 0, '2025-12-01 12:40:39'),
(7, 'chef', NULL, 'Order Baru', 'Meja 9 memesan makanan.', 0, '2025-12-01 12:40:58'),
(8, 'waiter', NULL, 'Update Status', 'Order #8 siap diantar!', 0, '2025-12-01 12:41:32'),
(9, 'waiter', NULL, 'Update Status', 'Order #6 siap diantar!', 0, '2025-12-01 12:41:32'),
(10, 'chef', NULL, 'Order Baru', 'Meja 8 memesan makanan.', 0, '2025-12-04 01:20:31'),
(11, 'waiter', NULL, 'Update Status', 'Order #9 siap diantar!', 0, '2025-12-04 01:20:41'),
(12, 'cs', NULL, 'Update Status', 'Order #9 meminta bill/pembayaran.', 0, '2025-12-04 01:20:51'),
(13, 'chef', NULL, 'Order Baru', 'Meja 10 memesan makanan.', 0, '2025-12-05 02:08:19'),
(14, 'waiter', NULL, 'Update Status', 'Order #10 siap diantar!', 0, '2025-12-05 02:08:48'),
(15, 'chef', NULL, 'Order Baru', 'Meja 6 memesan makanan.', 0, '2025-12-17 04:23:43'),
(16, 'waiter', NULL, 'Update Status', 'Order #11 siap diantar!', 0, '2025-12-17 04:24:09'),
(17, 'chef', NULL, 'Order Baru', 'Meja 8 memesan makanan.', 0, '2025-12-17 04:37:00'),
(18, 'waiter', NULL, 'Update Status', 'Order #12 siap diantar!', 0, '2025-12-17 04:37:23'),
(19, 'chef', NULL, 'Order Baru', 'Meja 9 memesan makanan.', 0, '2025-12-18 21:38:18'),
(20, 'waiter', NULL, 'Update Status', 'Order #14 siap diantar!', 0, '2025-12-18 21:38:31'),
(21, 'cs', NULL, 'Update Status', 'Order #10 meminta bill/pembayaran.', 0, '2025-12-18 21:41:07'),
(22, 'cs', NULL, 'Update Status', 'Order #8 meminta bill/pembayaran.', 0, '2025-12-18 21:41:09'),
(23, 'cs', NULL, 'Update Status', 'Order #6 meminta bill/pembayaran.', 0, '2025-12-18 21:41:12'),
(24, 'chef', NULL, 'Order Baru', 'Meja 4 memesan makanan.', 0, '2025-12-18 22:02:03'),
(25, 'waiter', NULL, 'Update Status', 'Order #15 siap diantar!', 0, '2025-12-18 22:02:10'),
(26, 'chef', NULL, 'Order Baru', 'Meja 7 memesan makanan.', 0, '2025-12-18 22:44:05'),
(27, 'waiter', NULL, 'Update Status', 'Order #17 siap diantar!', 0, '2025-12-18 22:44:13');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE IF NOT EXISTS `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_number` varchar(50) NOT NULL,
  `table_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `customer_name` varchar(100) DEFAULT 'Guest',
  `waiter_id` int(11) DEFAULT NULL,
  `subtotal` decimal(12,2) NOT NULL DEFAULT 0.00,
  `tax` decimal(12,2) DEFAULT 0.00,
  `service_charge` decimal(12,2) DEFAULT 0.00,
  `discount` decimal(12,2) DEFAULT 0.00,
  `total_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `status` enum('pending','cooking','ready','served','payment_pending','completed','cancelled') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `payment_ref` varchar(100) DEFAULT NULL COMMENT 'No Referensi QRIS/Struk',
  `payment_method` varchar(20) DEFAULT NULL,
  `payment_status` varchar(20) DEFAULT 'unpaid',
  `payment_time` datetime DEFAULT NULL,
  `cashier_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_number` (`order_number`),
  KEY `table_id` (`table_id`),
  KEY `waiter_id` (`waiter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `orders`
--

TRUNCATE TABLE `orders`;
--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_number`, `table_id`, `customer_id`, `customer_name`, `waiter_id`, `subtotal`, `tax`, `service_charge`, `discount`, `total_amount`, `status`, `notes`, `created_at`, `updated_at`, `payment_ref`, `payment_method`, `payment_status`, `payment_time`, `cashier_id`) VALUES
(15, 'ORD-182302-4', 4, NULL, 'Jamal', 1, 0.00, 0.00, 0.00, 0.00, 23000.00, 'completed', NULL, '2025-12-18 22:02:03', '2025-12-18 22:35:54', NULL, 'cash', 'paid', '2025-12-19 05:35:54', 1),
(16, 'DP-251218-11', 7, NULL, 'ayam (Deposit Booking)', NULL, 0.00, 0.00, 0.00, 0.00, 100000.00, 'completed', NULL, '2025-12-18 22:21:21', '2025-12-18 22:21:21', NULL, 'transfer', 'paid', '2025-12-19 05:21:21', 1),
(17, 'ORD-182344-7', 7, NULL, 'Guest', 1, 0.00, 0.00, 0.00, 0.00, 40250.00, 'completed', NULL, '2025-12-18 22:44:05', '2025-12-18 22:45:31', NULL, 'transfer', 'paid', '2025-12-19 05:45:31', 1);

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
CREATE TABLE IF NOT EXISTS `order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `menu_item_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `notes` text DEFAULT NULL,
  `item_status` enum('pending','cooking','ready','served') DEFAULT 'pending',
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `menu_item_id` (`menu_item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `order_items`
--

TRUNCATE TABLE `order_items`;
--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `menu_item_id`, `quantity`, `price`, `notes`, `item_status`) VALUES
(13, 15, 5, 1, 20000.00, '', 'pending'),
(14, 17, 2, 1, 35000.00, '', 'pending');

-- --------------------------------------------------------

--
-- Table structure for table `staff_access_codes`
--

DROP TABLE IF EXISTS `staff_access_codes`;
CREATE TABLE IF NOT EXISTS `staff_access_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `target_role` enum('manager','cs','waiter','chef') NOT NULL,
  `is_used` tinyint(1) DEFAULT 0,
  `used_by_user_id` int(11) DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `staff_access_codes`
--

TRUNCATE TABLE `staff_access_codes`;
--
-- Dumping data for table `staff_access_codes`
--

INSERT INTO `staff_access_codes` (`id`, `code`, `target_role`, `is_used`, `used_by_user_id`, `created_by`, `created_at`) VALUES
(1, 'CS-001', 'cs', 1, 2, 1, '2025-11-30 20:05:15'),
(2, 'WAIT-001', 'waiter', 1, 4, 1, '2025-11-30 20:05:15'),
(3, 'CHEF-001', 'chef', 1, 3, 1, '2025-11-30 20:05:15'),
(4, 'WAITER-192', 'waiter', 0, NULL, 1, '2025-12-01 00:34:06'),
(5, 'WAITER-750-0522', 'waiter', 1, 5, 1, '2025-12-17 04:22:27'),
(6, 'WAITER-754-0533', 'waiter', 0, NULL, 1, '2025-12-17 04:33:31');

-- --------------------------------------------------------

--
-- Table structure for table `tables`
--

DROP TABLE IF EXISTS `tables`;
CREATE TABLE IF NOT EXISTS `tables` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_number` varchar(10) NOT NULL,
  `capacity` int(11) NOT NULL,
  `status` enum('available','reserved','occupied','dirty') DEFAULT 'available',
  `current_order_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `min_dp` decimal(10,2) NOT NULL DEFAULT 100000.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `table_number` (`table_number`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `tables`
--

TRUNCATE TABLE `tables`;
--
-- Dumping data for table `tables`
--

INSERT INTO `tables` (`id`, `table_number`, `capacity`, `status`, `current_order_id`, `created_at`, `min_dp`) VALUES
(1, 'T-01', 2, 'available', NULL, '2025-11-30 20:05:16', 100000.00),
(2, 'T-02', 2, 'available', NULL, '2025-11-30 20:05:16', 100000.00),
(3, 'T-03', 4, 'available', NULL, '2025-11-30 20:05:16', 100000.00),
(4, 'T-04', 4, 'available', NULL, '2025-11-30 20:05:16', 100000.00),
(5, 'T-05', 6, 'available', NULL, '2025-11-30 20:05:16', 100000.00),
(6, 'VIP-01', 10, 'available', NULL, '2025-11-30 20:05:16', 250000.00),
(7, 'T-07', 4, 'dirty', NULL, '2025-12-01 03:27:28', 100000.00),
(8, 'T-08', 4, 'available', NULL, '2025-12-01 03:27:28', 100000.00),
(9, 'VIP-02', 10, 'available', NULL, '2025-12-01 03:27:28', 250000.00),
(10, 'VIP-03', 12, 'available', NULL, '2025-12-01 03:27:28', 250000.00);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `role` enum('admin','manager','cs','waiter','chef') NOT NULL DEFAULT 'waiter',
  `is_active` tinyint(1) DEFAULT 1,
  `fcm_token` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `users`
--

TRUNCATE TABLE `users`;
--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`, `is_active`, `fcm_token`, `created_at`, `updated_at`) VALUES
(1, 'Super Admin', 'admin@resto.com', '0192023a7bbd73250516f069df18b500', NULL, 'admin', 1, NULL, '2025-11-30 20:05:15', '2025-11-30 20:05:15'),
(2, 'Michael', 'Cs@gmail.com', '6c93d69333f488685100a7e6d6c9f300', '08123456789', 'cs', 1, NULL, '2025-12-01 00:08:49', '2025-12-01 00:08:49'),
(3, 'CHEF-001', 'CHEF-001@gmail.com', '64d5c602d141cb850ad874bc1fdff58a', '081234567890', 'chef', 1, NULL, '2025-12-01 00:35:42', '2025-12-01 00:35:42'),
(4, 'WAIT-001', 'WAIT-001@s.com', '677c9e7b9fab29aa8095837c73108cae', '08123456789', 'waiter', 1, NULL, '2025-12-01 00:36:45', '2025-12-01 00:36:45'),
(5, 'nama', 'wait02@gmail.com', '142d151f19bfb9ce8af6fb9aa41ea836', '0123123123', 'waiter', 1, NULL, '2025-12-17 04:27:30', '2025-12-17 04:27:30');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `activity_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `attendance_logs`
--
ALTER TABLE `attendance_logs`
  ADD CONSTRAINT `attendance_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`),
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD CONSTRAINT `menu_items_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`waiter_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
