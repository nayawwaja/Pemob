<p align="center">
  <img src="https://img.icons8.com/fluent/100/000000/restaurant.png" alt="Resto Pro Logo" width="100"/>
</p>

<h1 align="center">🏆 RESTO PRO</h1>

<p align="center">
  <strong>Sistem Manajemen Restoran Terintegrasi Ultimate v2.0</strong><br>
  <em>Solusi all-in-one untuk efisiensi operasional dapur, pelayan, hingga kasir.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white" alt="PHP">
  <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL">
</p>

---

### 📝 Deskripsi Singkat
**RESTO PRO** adalah aplikasi manajemen restoran berbasis mobile yang dirancang untuk menyinkronkan seluruh departemen dalam sebuah restoran secara *real-time*. Mulai dari reservasi meja dengan sistem Down Payment (DP), pemesanan menu digital, monitoring antrean dapur, hingga pelaporan keuangan mendetail untuk pemilik bisnis.

---

### 🚀 Fitur Utama

| Fitur | Deskripsi |
| :--- | :--- |
| **Multi-Role Access** | Akses khusus untuk Admin, Manager, Chef, Waiter, dan Customer Service. |
| **Real-time Kitchen** | Monitor antrean masak yang terbagi antara pesanan baru dan sedang dimasak. |
| **Smart Booking** | Sistem reservasi meja otomatis dengan validasi kode dan pembayaran DP. |
| **Interactive Floor Plan** | Visualisasi denah meja (Tersedia, Terisi, Dipesan, atau Kotor). |
| **Split Bill System** | Mendukung pembayaran per-item (split payment) untuk tamu rombongan. |
| **Loyalty Program** | Pencatatan poin member berdasarkan nominal belanja untuk *tiering* (Gold, Silver, dsb). |
| **Business Analytics** | Grafik tren pendapatan 7 hari terakhir dan laporan menu terlaris. |
| **Attendance System** | Sistem Clock-In/Clock-Out staff untuk keamanan akses menu aplikasi. |

---

### 🛠️ Stack Teknologi

* **Frontend:** Flutter Framework (Dart)
* **Backend:** PHP (Native API dengan PDO Security)
* **Database:** MySQL
* **Libraries:** * `fl_chart` (Data Visualization)
    * `intl` (Localization & Currency)
    * `table_calendar` (Attendance Tracker)
    * `shared_preferences` (Session Management)
* **API:** Private REST API dikelola di folder `/resto_api`.

---

### 👥 Kontributor Tim

Kami adalah tim pengembang di balik RESTO PRO:

<table align="center">
  <tr>
    <td align="center"><a href="https://github.com/nayawwaja"><img src="https://github.com/nayawwaja.png?size=100" width="100px;" alt="Nadya"/><br /><sub><b>Nadya Putri A.</b></sub></a><br />241712040</td>
    <td align="center"><a href="https://github.com/nitagustienpH"><img src="https://github.com/nitagustienpH.png?size=100" width="100px;" alt="Bernita"/><br /><sub><b>Bernita Agustien</b></sub></a><br />241712016</td>
    <td align="center"><img src="https://ui-avatars.com/api/?name=Rima+Nazwa&background=random&size=100" width="100px;" alt="Rima"/><br /><sub><b>Rima Nazwa</b></sub><br />241712004</td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/Anggasana-11"><img src="https://github.com/Anggasana-11.png?size=100" width="100px;" alt="Anggasana"/><br /><sub><b>Anggasana S.</b></sub></a><br />241712014</td>
    <td align="center"><img src="https://ui-avatars.com/api/?name=Ihsan+Al+Munawar&background=random&size=100" width="100px;" alt="Ihsan"/><br /><sub><b>M. Ihsan Al M.</b></sub><br />241712007</td>
    <td align="center"><a href="https://github.com/K1rigayakun"><img src="https://github.com/K1rigayakun.png?size=100" width="100px;" alt="Michael"/><br /><sub><b>Michael Deryl A.</b></sub></a><br />241712042</td>
  </tr>
</table>

---

### 💻 Cara Menjalankan Aplikasi

1.  **Persiapan Database:**
    * Import file `resto_db.sql` ke dalam MySQL/XAMPP Anda.
    * Pastikan konfigurasi di `resto_api/config/database.php` sesuai dengan kredensial lokal Anda.

2.  **Konfigurasi API:**
    * Ubah file `lib/config/api_config.dart`.
    * Tapi jika anda menggunakan Emulator android studio atau melalui jaringan laptop anda(Localhost) tidak perlu mengganti API.

3.  **Jalankan Flutter:**
    ```bash
    flutter pub get
    flutter run
    ```

4.  **Akses Login (Default):**
    * **Email:** `admin@resto.com`
                 `manager@resto.com`
                 `chef1@resto.com`
                 `chef2@resto.com`
                 `waiter1@resto.com`
                 `waiter2@resto.com`
                 `waiter3@resto.com`
                 `kasir1@resto.com`
                 `kasir2@resto.com`
    * **Password:** `password`

---

<p align="center">
  Built with ❤️ by Team Resto Pro
</p>
