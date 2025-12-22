Berikut adalah file **README.md** yang dirancang dengan desain modern, stylish, dan interaktif. Dokumentasi ini mencakup identitas visual aplikasi sesuai dengan *Splash Screen*  dan teknis lengkap berdasarkan kode sumber yang disediakan.

---

# <img src="[https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Food%20and%20Drink/Cooking.png](https://www.google.com/search?q=https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Food%2520and%2520Drink/Cooking.png)" width="45" /> RESTO PRO - Ultimate Build v2.0

> **Sistem Manajemen Restoran Terintegrasi** | Menghubungkan Dapur, Pelayan, Kasir, dan Pemilik dalam satu ekosistem digital *real-time* .
> 
> 

---

## 👥 Tim Pengembang (Kelompok 4)

| Kontributor | NIM |
| --- | --- | --- |
| <img src="[[https://github.com/nadya.png](https://www.google.com/search?q=https://github.com/nadya.png](https://avatars.githubusercontent.com/u/238160000?v=4))" width="50" style="border-radius:50%"/> **Nadya Putri Anggina** | `241712040` |
| <img src="[https://github.com/bernita.png](https://www.google.com/search?q=https://github.com/bernita.png)" width="50" style="border-radius:50%"/> **Bernita Agustien P H** | `241712016` | 
| <img src="[https://github.com/rima.png](https://www.google.com/search?q=https://github.com/rima.png)" width="50" style="border-radius:50%"/> **Rima Nazwa** | `241712004` |
| <img src="[https://github.com/anggasana.png](https://www.google.com/search?q=https://github.com/anggasana.png)" width="50" style="border-radius:50%"/> **Anggasana Simanullang** | `241712014` |
| <img src="[https://github.com/ihsan.png](https://www.google.com/search?q=https://github.com/ihsan.png)" width="50" style="border-radius:50%"/> **M. Ihsan Al Munawar** | `241712007` |
| <img src="[https://github.com/michael.png](https://www.google.com/search?q=https://github.com/michael.png)" width="50" style="border-radius:50%"/> **Michael Deryl A M M** | `241712042` |

---

## 📝 Deskripsi Singkat

**Resto Pro** adalah solusi digital *end-to-end* untuk operasional restoran modern yang mengusung tema **Obsidian Gold Dark Mode** . Aplikasi ini mengintegrasikan sistem autentikasi cerdas untuk mengarahkan pengguna ke dashboard yang sesuai dengan peran mereka (Admin, Chef, Waiter, CS) secara otomatis .

---

## 🚀 Daftar Fitur pada Aplikasi

* 
**🛡️ Role-Based Ecosystem**: Navigasi dashboard otomatis yang membedakan hak akses Admin, Koki, Pelayan, dan Kasir .


* 
**📊 Business Intelligence**: Grafik analitik pendapatan 7 hari dan monitoring menu terlaris untuk pemilik .


* 
**👨‍🍳 Kitchen Control**: Manajemen antrian masak *real-time* dengan indikator durasi tunggu pesanan .


* 
**🤵 Waiter Station**: Denah meja interaktif untuk memantau meja tersedia, terisi, atau kotor .


* 
**💰 Cashier & Loyalty**: Mendukung multi-metode pembayaran, fitur *Split Bill* per item, dan poin member otomatis .


* 
**📅 Reservation System**: Booking meja dengan sistem Uang Muka (DP) yang terintegrasi dengan laporan keuangan .


* 
**⏰ Smart Attendance**: Keamanan operasional yang mewajibkan staf melakukan *Clock-In* sebelum fitur aplikasi dapat diakses .



---

## 🛠️ Stack Technology yang Digunakan

* 
**Frontend**: Flutter (Dart) dengan arsitektur *Clean UI*.


* 
**Backend**: PHP 8.2 menggunakan arsitektur RESTful API.


* 
**Database**: MySQL 10.4 (MariaDB) dengan optimasi *Triggers* dan *Stored Procedures* .


* **Web Server**: Apache via XAMPP.

---

## 📱 Versioning

* **Flutter Version**: `3.x` (Channel Stable).
* **Android Version**:
* Minimum SDK: `21` (Android 5.0 Lollipop).
* Target SDK: `34` (Android 14).



---

## 📦 Library / Framework yang Digunakan

Aplikasi ini memanfaatkan ekosistem library terbaik untuk performa maksimal:

* 
`fl_chart`: Visualisasi data statistik dan pendapatan.


* 
`intl`: Standarisasi format mata uang Rupiah (IDR) dan tanggal lokal.


* 
`table_calendar`: Kalender interaktif untuk manajemen riwayat kehadiran staf .


* 
`shared_preferences`: Manajemen sesi login, token keamanan, dan status shift .


* 
`http`: Integrasi API backend yang responsif.



---

## 🔌 Public / Private API yang Digunakan

Sistem menggunakan **Private REST API** dengan konfigurasi **Auto-IP Detection** . Fitur ini memungkinkan aplikasi berjalan di Android Emulator maupun Web tanpa perlu mengubah alamat IP secara manual:

```dart
// lib/config/api_config.dart
if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2/resto_api/api'; [cite_start]// Otomatis untuk Android Emulator [cite: 3]
}
return 'http://localhost/resto_api/api'; [cite_start]// Otomatis untuk Web/iOS/Desktop [cite: 6]

```

---

## ⚙️ Cara Menjalankan Aplikasi

### 1. Persiapan Database

1. Buka **phpMyAdmin** di `localhost/phpmyadmin`.
2. Buat database baru bernama `resto_db`.


3. Import file `resto_db.sql` ke dalam database tersebut .



### 2. Persiapan Backend

1. Pindahkan folder `resto_api` ke direktori `htdocs` (XAMPP).
2. Pastikan konfigurasi database di `resto_api/config/database.php` sudah sesuai .



### 3. Persiapan Frontend (VS Code / Android Studio)

1. Buka terminal di folder project dan jalankan:
```bash
flutter pub get

```


2. **VS Code**: Buka *Command Palette* (`Ctrl+Shift+P`), pilih `Flutter: Select Device`, lalu tekan `F5` untuk *Debug*.
3. **Android Studio**: Klik tombol `Run` (Segitiga hijau) pada toolbar utama.

---

## 🔐 Akun Akses Demo

> **Password semua akun:** `password`

| Peran | Email Login |
| --- | --- |
| **Admin** | `admin@resto.com` |
| **Chef (Koki)** | `chef1@resto.com` |
| **Waiter (Pelayan)** | `waiter1@resto.com` |
| **Kasir (CS)** | `kasir1@resto.com` |

---

> **Kelompok 4 © 2025** | Dibuat untuk Efisiensi Bisnis Kuliner Anda.
