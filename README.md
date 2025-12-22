Berikut adalah file **README.md** yang didesain secara profesional, interaktif, dan modern untuk repositori GitHub Anda. File ini mencakup semua detail teknis dari kode sumber yang Anda berikan, termasuk sistem multi-role, manajemen database, dan integrasi API.

---

# 🍽️ RESTO PRO - Ultimate Build v2.0

> **Sistem Manajemen Restoran Terintegrasi Berbasis Flutter & PHP**

**Resto Pro** adalah solusi manajemen restoran *all-in-one* yang menghubungkan operasional dapur, pelayan, kasir, hingga pemilik dalam satu ekosistem digital. Aplikasi ini dirancang untuk meningkatkan efisiensi pelayanan, akurasi pesanan, dan analitik bisnis secara real-time.

---

## 👥 Kelompok 4 - Kontributor

Dibuat dengan ❤️ oleh mahasiswa hebat dari tim kami:

<table align="center">
<tr>
<td align="center">
<a href="[https://github.com/nadya](https://github.com/nadya)">
<img src="[https://github.com/nadya.png](https://www.google.com/search?q=https://github.com/nadya.png)" width="100px;" alt="Nadya Putri"/><br />
<sub><b>Nadya Putri Anggina</b></sub>
</a><br />
<sub>241712040</sub>
</td>
<td align="center">
<a href="[https://github.com/bernita](https://www.google.com/search?q=https://github.com/bernita)">
<img src="[https://github.com/bernita.png](https://www.google.com/search?q=https://github.com/bernita.png)" width="100px;" alt="Bernita"/><br />
<sub><b>Bernita Agustien P H</b></sub>
</a><br />
<sub>241712016</sub>
</td>
<td align="center">
<a href="[https://github.com/rima](https://www.google.com/search?q=https://github.com/rima)">
<img src="[https://github.com/rima.png](https://www.google.com/search?q=https://github.com/rima.png)" width="100px;" alt="Rima"/><br />
<sub><b>Rima Nazwa</b></sub>
</a><br />
<sub>241712004</sub>
</td>
</tr>
<tr>
<td align="center">
<a href="[https://github.com/anggasana](https://www.google.com/search?q=https://github.com/anggasana)">
<img src="[https://github.com/anggasana.png](https://www.google.com/search?q=https://github.com/anggasana.png)" width="100px;" alt="Anggasana"/><br />
<sub><b>Anggasana Simanullang</b></sub>
</a><br />
<sub>241712014</sub>
</td>
<td align="center">
<a href="[https://github.com/ihsan](https://www.google.com/search?q=https://github.com/ihsan)">
<img src="[https://github.com/ihsan.png](https://www.google.com/search?q=https://github.com/ihsan.png)" width="100px;" alt="Muhammad Ihsan"/><br />
<sub><b>Muhammad Ihsan Al Munawar</b></sub>
</a><br />
<sub>241712007</sub>
</td>
<td align="center">
<a href="[https://github.com/michael](https://github.com/michael)">
<img src="[https://github.com/michael.png](https://www.google.com/search?q=https://github.com/michael.png)" width="100px;" alt="Michael"/><br />
<sub><b>Michael Deryl A M M</b></sub>
</a><br />
<sub>241712042</sub>
</td>
</tr>
</table>

---

## 🚀 Fitur Unggulan

### 🔐 Multi-Role Access Control

Navigasi dashboard otomatis menyesuaikan peran pengguna:

* 
**Admin/Owner**: Akses penuh ke laporan bisnis, manajemen stok, dan HRD.


* 
**Chef (Dapur)**: Monitor antrian masak secara real-time.


* 
**Waiter (Pelayan)**: Input pesanan pelanggan dan monitor meja kotor.


* 
**Cashier (Kasir)**: Proses pembayaran (Tunai, QRIS, Debit, Transfer) & Split Bill.



### 📅 Manajemen Meja & Reservasi Pintar

* 
**Sistem Booking & DP**: Menangani uang muka (Down Payment) untuk reservasi.


* 
**Auto-Cleaning System**: Status meja 'Reserved' otomatis aktif 1 jam sebelum tamu datang.


* 
**QR Check-In**: Verifikasi kedatangan tamu melalui kode booking.



### 📊 Analitik & Laporan Real-time

* 
**Grafik Pendapatan**: Visualisasi tren penjualan 7 hari terakhir.


* 
**Menu Terlaris**: Pantau item mana yang memberikan keuntungan maksimal.


* 
**Loyalty Points**: Sistem poin member berdasarkan nominal belanja untuk meningkatkan *customer retention*.



### ⏰ Sistem Kehadiran (Attendance)

* 
**Clock In/Out**: Fitur absensi harian staf untuk keamanan akses menu aplikasi.


* 
**Work Duration**: Perhitungan otomatis durasi kerja staf per shift.



---

## 🛠️ Stack Teknologi

| Komponen | Teknologi |
| --- | --- |
| **Frontend** | Flutter 3.x (Dart) |
| **Backend** | PHP 8.x (RESTful API) |
| **Database** | MySQL / MariaDB |
| **Tools** | XAMPP, VS Code, Android Studio |
| **Design System** | Custom Dark Theme (Elegant Gold & Obsidian) 

 |

### Library Utama (Flutter)

* 
`http`: Komunikasi data API.


* 
`fl_chart`: Grafik analitik interaktif.


* 
`intl`: Format mata uang dan tanggal Indonesia.


* 
`shared_preferences`: Manajemen sesi login dan status shift.


* 
`table_calendar`: Kalender riwayat absensi.



---

## ⚙️ Cara Menjalankan Aplikasi

### 1. Persiapan Database

1. Buka **phpMyAdmin**.
2. Buat database baru dengan nama `resto_db`.


3. Import file `resto_db.sql` yang tersedia di folder root project.



### 2. Persiapan API (Backend)

1. Copy folder `resto_api` ke direktori `htdocs` (XAMPP).
2. Pastikan konfigurasi di `resto_api/config/database.php` sudah sesuai dengan kredensial MySQL Anda.



### 3. Konfigurasi Flutter

1. Buka file `lib/config/api_config.dart`.
2. Ganti `baseUrl` dengan alamat IP komputer Anda jika menggunakan HP fisik, atau tetap gunakan `10.0.2.2` untuk Emulator Android.



```dart
static String get baseUrl => "http://ALAMAT_IP_ANDA/resto_api/api";

```

### 4. Running

```bash
flutter pub get
flutter run

```

---

## 🔑 Akun Uji Coba (Default)

> 
> **Password semua akun:** `password` 
> 
> 

| Role | Username | Email |
| --- | --- | --- |
| **Admin** | `admin` | `admin@resto.com` |
| **Manager** | `manager` | `manager@resto.com` |
| **Chef** | `chef1` | `chef1@resto.com` |
| **Waiter** | `waiter1` | `waiter1@resto.com` |
| **Cashier** | `kasir1` | `kasir1@resto.com` |

---

## 📄 Lisensi

Project ini berada di bawah lisensi **MIT**. Anda bebas menggunakannya untuk tujuan edukasi.

---

> 
> **Note:** Aplikasi ini adalah versi **v2.0 Ultimate Build** dengan optimasi keamanan JSON parsing dan sinkronisasi status meja secara *real-time*.
> 
> 

Apakah Anda ingin saya menambahkan bagian video demo atau dokumentasi API yang lebih mendalam ke dalam file README ini?
