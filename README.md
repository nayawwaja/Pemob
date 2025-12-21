# RESTO PRO

## Tim Pengembang

| Nama | NIM |
| :--- | :--- |
| **Nadya Putri Anggina** | 241712040 |
| **Bernita Agustien P Habeahan** | 241712016 |
| **Rima Nazwa** | 241712004 |
| **Anggasana Simanullang** | 241712014 |
| **Muhammad Ihsan Al Munawar** | 241712007 |
| **Michael Deryl Aarron Matthew** | 241712042 |

---

## Deskripsi Singkat Aplikasi

**RESTO PRO** adalah aplikasi manajemen restoran terintegrasi (Point of Sales & Management System) yang dirancang untuk mendigitalkan operasional bisnis kuliner. Aplikasi ini menghubungkan berbagai peran dalam restoran mulai dari Pelayan (Waiter), Dapur (Chef), Kasir (CS), hingga Manajer dan Pemilik (Admin) dalam satu ekosistem.

Aplikasi ini menangani alur kerja lengkap mulai dari reservasi meja, pemesanan menu, manajemen antrian dapur, pembayaran, hingga pelaporan pendapatan dan absensi karyawan secara *real-time*.

---

## Daftar Fitur

1.  **Multi-Role Authentication**: Akses berbeda untuk Admin, Manager, Chef, Waiter, dan Customer Service (CS).
2.  **Dashboard Interaktif**:
    *   **Admin**: Grafik tren pendapatan, ringkasan pesanan, dan peringatan stok menipis.
    *   **Staff**: Fitur Clock-In/Clock-Out (Absensi) dan akses menu cepat sesuai peran.
3.  **Manajemen Pesanan (Ordering)**: Input pesanan pelanggan dan pelacakan status pesanan.
4.  **Reservasi Meja (Booking)**: Sistem booking meja dengan fitur pembayaran uang muka (DP) dan sinkronisasi status meja otomatis.
5.  **Kitchen Display System (KDS)**: Layar khusus koki untuk memantau antrian pesanan yang masuk ke dapur.
6.  **Point of Sales (Kasir)**: Pembayaran tagihan dengan dukungan perhitungan tunai dan non-tunai.
7.  **Manajemen Menu & Stok**: Pengelolaan daftar menu, harga, dan pemantauan stok bahan baku.
8.  **Manajemen SDM**: Pengelolaan data karyawan, kode akses registrasi, dan riwayat absensi.
9.  **Laporan & Analitik**: Laporan penjualan harian/bulanan dan performa restoran.

---

## Stack Technology

*   **Mobile Framework**: Flutter (Dart)
*   **Backend API**: PHP Native
*   **Database**: MySQL / MariaDB
*   **Architecture**: MVC (Model-View-Controller) pada Backend, MVVM/Clean Architecture pattern pada Mobile.

---

## Versi Perangkat Lunak

### Flutter Version
*   **Flutter SDK**: 3.0.0 atau lebih baru (Disarankan versi Stable terbaru 3.x)
*   **Dart SDK**: 2.17.0 atau lebih baru

### Android Version
*   **Minimum SDK**: Android 5.0 (API Level 21)
*   **Target SDK**: Android 13/14 (API Level 33/34)

---

## Library / Framework yang Digunakan

Berikut adalah *dependencies* utama yang digunakan dalam proyek Flutter:

*   **`flutter`**: Framework UI utama.
*   **`http`**: Untuk melakukan request API (GET, POST) ke backend PHP.
*   **`shared_preferences`**: Untuk penyimpanan data lokal sederhana (sesi login, data user).
*   **`intl`**: Untuk format tanggal, waktu, dan mata uang (Rupiah).
*   **`fl_chart`**: Untuk visualisasi data grafik pendapatan pada Dashboard Admin.

---

## Public / Private API

Aplikasi ini menggunakan **Private REST API** yang dibangun sendiri menggunakan PHP Native.
*   **Base URL**: `http://[IP_ADDRESS_SERVER]/resto_api/api/`
*   **Format Data**: JSON
*   **Endpoint Utama**: `auth.php`, `staff.php`, `booking.php`, `orders.php`, `dashboard.php`, `attendance.php`.

---

## Cara Menjalankan Aplikasi

### 1. Persiapan Backend (Server)
1.  Pastikan **XAMPP** atau web server sejenis (Apache + MySQL) sudah terinstall.
2.  Buat database baru di phpMyAdmin dengan nama `resto_db` (atau sesuaikan dengan `config/database.php`).
3.  Import file SQL database ke dalam `resto_db`.
4.  Salin folder `resto_api` ke dalam folder `htdocs` pada instalasi XAMPP.
5.  Pastikan server berjalan dan dapat diakses via browser (Cek IP Address komputer Anda, misal: `192.168.1.x`).

### 2. Persiapan Aplikasi Mobile (Flutter)
1.  Buka project Flutter di VS Code atau Android Studio.
2.  Buka file konfigurasi API (biasanya di `lib/config/api_config.dart` atau `lib/services/api_service.dart`).
3.  Ubah `baseUrl` agar mengarah ke IP Address komputer server backend (Contoh: `http://192.168.1.10/resto_api/api`). *Jangan gunakan `localhost` jika menjalankan di HP fisik.*
4.  Jalankan perintah `flutter pub get` di terminal untuk mengunduh library.
5.  Jalankan aplikasi dengan perintah `flutter run`.