# 🛡️ MindSafe

**MindSafe** adalah aplikasi mobile berbasis **Flutter** yang dirancang untuk memantau dan mengklasifikasikan aktivitas browsing internet secara real-time menggunakan teknologi **Local VPN** dan **Accessibility Service**. Aplikasi ini dikembangkan sebagai bagian dari **penelitian Tugas Akhir (Skripsi)**.

> *"Menjaga pikiran tetap aman dari konten berbahaya di internet"*

---

## 📋 Daftar Isi

- [Tentang Proyek](#-tentang-proyek)
- [Fitur Utama](#-fitur-utama)
- [Tech Stack](#-tech-stack)
- [Arsitektur Proyek](#-arsitektur-proyek)
- [Cara Kerja](#-cara-kerja)
- [Instalasi](#-instalasi)
- [Konfigurasi Firebase](#-konfigurasi-firebase)
- [Blocklist Assets](#-blocklist-assets)
- [Firestore Security Rules](#-firestore-security-rules)
- [FAQ](#-faq)
- [Troubleshooting](#-troubleshooting)
- [Lisensi](#-lisensi)

---

## 📖 Tentang Proyek

MindSafe merupakan aplikasi **internet safety monitoring** yang bertujuan untuk:

1. **Memantau aktivitas browsing** pengguna melalui DNS query interception (Local VPN) dan URL capture (Accessibility Service)
2. **Mengklasifikasikan domain** yang diakses ke dalam kategori: safe, adult, gambling, phishing, malware, cryptojacking, hacking, dating, warez, DDoS, dan dangerous
3. **Memberikan insight** dan statistik tentang kebiasaan browsing pengguna
4. **Mengirim notifikasi** ketika domain berbahaya terdeteksi

Aplikasi ini dikembangkan untuk keperluan **penelitian Tugas Akhir** di bidang keamanan internet dan kesadaran digital.

---

## ✨ Fitur Utama

### 👤 Fitur User

| Fitur | Deskripsi |
|-------|-----------|
| 🔒 **VPN Monitoring** | Monitoring DNS query secara real-time menggunakan Local VPN |
| 🌐 **URL Capture** | Menangkap URL lengkap dari browser menggunakan Accessibility Service |
| 📊 **Dashboard** | Tampilan statistik harian, mingguan, dan tren aktivitas browsing |
| 📈 **History** | Riwayat browsing dengan chart (daily/weekly/monthly) dan kalender interaktif |
| 💡 **Insights** | Analisis pola browsing dan rekomendasi kebiasaan digital sehat |
| 🔔 **Notifikasi** | Peringatan lokal saat domain berbahaya terdeteksi |
| 🎨 **Tema** | Light mode, dark mode, atau mengikuti sistem |
| 🌍 **Multi-bahasa** | Dukungan Bahasa Indonesia dan English |
| ☁️ **Cloud Sync** | Sinkronisasi data ke Firebase Firestore |
| 🗑️ **Data Retention** | Pengaturan retensi data (7, 30, atau 90 hari) |
| 📤 **Share & Feedback** | Bagikan aplikasi dan kirim masukan |
| 📱 **Onboarding** | Panduan awal penggunaan aplikasi |

### 🔧 Fitur Admin

| Fitur | Deskripsi |
|-------|-----------|
| 📊 **Dashboard Admin** | Statistik sistem: total user, total domain, aktivitas hari ini, breakdown kategori |
| 📝 **Domain Rules** | Kelola aturan klasifikasi domain secara kustom (tambah, edit, hapus rule) |
| 🚫 **Skip Domains** | Daftar domain yang diabaikan saat monitoring (termasuk semua subdomain) |
| 📢 **Push Notification** | Kirim notifikasi global ke semua pengguna (info, update, warning, promo) |
| 📋 **Audit Log** | Catatan aktivitas admin |
| 🔄 **Version Management** | Kelola versi aplikasi dan force update |

---

## 🛠️ Tech Stack

| Teknologi | Fungsi |
|-----------|--------|
| **Flutter** & **Dart** | Framework UI cross-platform |
| **Kotlin** | Android native VPN Service & Accessibility Service |
| **GetX** | State management, routing, dependency injection, dan lokalisasi |
| **Firebase Auth** | Autentikasi via Google Sign-In |
| **Cloud Firestore** | Database cloud untuk sync data dan admin panel |
| **Hive** | Local database (NoSQL) untuk penyimpanan offline |
| **ForUI** | UI component library |
| **fl_chart** | Visualisasi chart dan statistik |
| **table_calendar** | Widget kalender interaktif |
| **flutter_local_notifications** | Notifikasi lokal |
| **UT1 Blocklist** | Dataset klasifikasi domain dari Université Toulouse 1 Capitole |

---

## 🏗️ Arsitektur Proyek

```
lib/
├── app/
│   ├── bindings/              # Dependency injection (GetX)
│   └── controllers/           # Business logic controllers (VPN, dll)
├── core/
│   ├── constants/             # Warna, spacing, text styles
│   ├── localization/          # Terjemahan EN & ID
│   ├── theme/                 # Light & dark theme
│   ├── utils/                 # Utility functions
│   └── widgets/               # Reusable widgets (AppCard, AppBottomSheet, dll)
├── data/
│   ├── models/                # Model data (Hive adapters)
│   ├── repositories/          # Firestore repository
│   └── services/              # Auth, VPN, Database, Classifier, Sync, Notification
├── routes/                    # App routing & navigation
├── screens/
│   ├── admin/                 # Admin panel (Dashboard, Rules, Audit, Notif)
│   ├── auth/                  # Login & registrasi
│   ├── history/               # Riwayat browsing (Overview & Calendar)
│   ├── home/                  # Home screen dengan monitoring card
│   ├── insights/              # Analisis dan insight browsing
│   ├── navigation/            # Bottom navigation
│   ├── onboarding/            # Onboarding pengguna baru
│   ├── settings/              # Pengaturan & about
│   └── splash/                # Splash screen
├── widgets/                   # Shared widgets
└── main.dart                  # Entry point aplikasi

android/app/src/main/kotlin/com/example/mindsafe_flutter/
├── LocalVpnService.kt         # Implementasi VPN untuk intercept DNS query
├── BrowserMonitorService.kt   # Accessibility Service untuk capture URL
└── MainActivity.kt            # Platform channel bridge (Flutter ↔ Kotlin)
```

---

## ⚙️ Cara Kerja

### VPN-Based DNS Monitoring

```
User browsing → LocalVpnService intercept paket →
Ekstraksi DNS query → Kirim ke Flutter via EventChannel →
DomainClassifier klasifikasi domain → Simpan ke Hive →
Update statistik → (Opsional) Sync ke Firestore
```

1. **LocalVpnService.kt** membuat koneksi VPN lokal menggunakan Android VpnService API
2. **Packet Capture** menangkap paket jaringan untuk mengekstrak DNS query
3. **Domain Classification** menggunakan UT1 blocklist dan custom rules dari admin
4. **Event Streaming** mengirim data domain ke Flutter melalui EventChannel

### URL Capture (Accessibility Service)

1. **BrowserMonitorService.kt** membaca URL dari address bar browser
2. Mendukung Chrome, Firefox, Edge, Opera, Brave, dan browser lainnya
3. Memberikan tracking yang lebih detail di level halaman

### Klasifikasi Domain

Domain diklasifikasikan melalui 3 tahap:
1. **Custom Rules** — Aturan kustom dari admin (prioritas tertinggi)
2. **Skip Domains** — Domain yang diabaikan
3. **UT1 Blocklist** — Dataset dari Université Toulouse 1 (adult, gambling, phishing, malware, dll)

> **Privasi**: Aplikasi TIDAK mendekripsi traffic HTTPS. Hanya menangkap nama domain, bukan konten halaman.

---

## 🚀 Instalasi

### Prasyarat

- **Flutter SDK** ≥ 3.11.0
- **Dart SDK** ≥ 3.11.0
- **Android Studio** atau VS Code dengan Flutter extension
- **Firebase Project** yang sudah dikonfigurasi
- **Android Device/Emulator** (API 21+ / Android 5.0+)

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/alhifnywahid/mindsafe-app.git
   cd mindsafe-app
   ```

2. **Download blocklist assets** (lihat bagian [Blocklist Assets](#-blocklist-assets))

3. **Setup Firebase** (lihat bagian [Konfigurasi Firebase](#-konfigurasi-firebase))

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Generate Hive adapters**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

---

## 🔥 Konfigurasi Firebase

### 1. Buat Firebase Project

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Buat project baru (contoh: "MindSafe")
3. Tambahkan aplikasi Android dengan package name: `com.example.mindsafe_flutter`
4. Download `google-services.json`
5. Letakkan di: `android/app/google-services.json` (replace file yang ada)

### 2. Aktifkan Firebase Services

- **Authentication** → Aktifkan **Google Sign-In** provider
- **Cloud Firestore** → Buat database (production mode)

### 3. Setup Admin

Admin ditentukan berdasarkan email yang di-hardcode. Untuk mengubah akun admin:

1. Buka `lib/data/services/auth_service.dart`
2. Cari properti `isAdmin` dan ubah email admin sesuai kebutuhan
3. Update juga Firestore Security Rules agar sesuai dengan email admin baru

---

## 📦 Blocklist Assets

File blocklist **tidak disertakan** di repository karena ukurannya yang besar (>100MB). Anda perlu mendownload dan meletakkannya secara manual.

### Download

📥 **[Download Blocklist Assets (Google Drive)](https://drive.google.com/drive/folders/1S767PcZlFrobctX16bQ7zK2IH0gySHKm?usp=sharing)**

### Sumber Asli

Blocklist yang digunakan bersumber dari **[UT1 Blocklist - Université Toulouse 1 Capitole](https://dsi.ut-capitole.fr/blacklists/)**. Dataset ini merupakan salah satu referensi klasifikasi domain yang banyak digunakan dalam penelitian keamanan internet.

### Struktur

Letakkan semua file `.txt` ke dalam folder `assets/blocklists/`:

```
assets/blocklists/
├── adult.txt          # Domain konten dewasa (~119 MB)
├── cryptojacking.txt  # Domain cryptojacking
├── dangerius.txt      # Domain berbahaya
├── dating.txt         # Domain dating
├── ddos.txt           # Domain DDoS
├── gambling.txt       # Domain judi online
├── hacking.txt        # Domain hacking
├── malware.txt        # Domain malware
├── phishing.txt       # Domain phishing
└── warez.txt          # Domain warez/piracy
```

---

## 🔐 Firestore Security Rules

Berikut adalah konfigurasi Firestore Security Rules yang digunakan. Sesuaikan email admin (`admin@example.com`) dengan email Google yang ingin dijadikan admin.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - hanya bisa diakses oleh user yang bersangkutan
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /domain_accesses/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Admin bisa membaca data semua user
    match /users/{userId} {
      allow read: if request.auth != null &&
        request.auth.token.email == 'admin@example.com';
    }

    // Domain rules - semua user bisa baca, hanya admin bisa tulis
    match /domain_rules/{ruleId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.token.email == 'admin@example.com';
    }

    // Skip domains - semua user bisa baca, hanya admin bisa tulis
    match /skip_domains/{domainId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.token.email == 'admin@example.com';
    }

    // App config - semua user bisa baca, hanya admin bisa tulis
    match /app_config/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.token.email == 'admin@example.com';
    }
  }
}
```

> ⚠️ **Penting**: Ganti `admin@example.com` dengan email Google yang ingin dijadikan admin baik di Firestore Rules maupun di kode aplikasi.

---

## ❓ FAQ

### Bagaimana cara kerja monitoring?

MindSafe menggunakan dua metode:
- **VPN Service**: Membuat VPN lokal untuk menangkap DNS query dari semua aplikasi
- **Accessibility Service**: Membaca URL dari address bar browser untuk tracking yang lebih detail

Kedua metode bekerja sepenuhnya di perangkat — tidak ada data yang keluar tanpa izin pengguna.

### Apakah aplikasi membaca pesan atau konten saya?

**Tidak.** MindSafe hanya memantau nama domain (contoh: "google.com") dan URL browser. Aplikasi tidak membaca, mencegat, atau menyimpan konten halaman, pesan, password, foto, atau data pribadi lainnya.

### Mengapa menggunakan Local VPN?

Local VPN adalah metode teknis untuk menangkap DNS query tanpa memerlukan root access. Berbeda dengan VPN tradisional:
- Tidak merutekan traffic melalui server eksternal
- Tidak memperlambat koneksi internet
- Berjalan sepenuhnya di perangkat
- Hanya melihat DNS request

### Mengapa beberapa website tidak terdeteksi?

Jika browser menggunakan **Secure DNS (DNS over HTTPS)**, DNS query akan melewati VPN lokal. Untuk mengatasinya, nonaktifkan Secure DNS di pengaturan browser:
- **Chrome**: Settings → Privacy and Security → Use Secure DNS → OFF
- **Firefox**: Settings → Enhanced DNS Privacy → Off
- **Edge**: Settings → Privacy and Security → Use Secure DNS → OFF

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| **App tidak bisa build** | Pastikan `google-services.json` sudah benar. Jalankan `flutter clean && flutter pub get` |
| **VPN permission denied** | Android butuh persetujuan eksplisit. Restart VPN dari aplikasi |
| **Domain tidak terdeteksi** | Pastikan VPN aktif, cek notifikasi "VPN Active", nonaktifkan Secure DNS di browser |
| **Build error Hive** | Jalankan `dart run build_runner clean` lalu `dart run build_runner build --delete-conflicting-outputs` |
| **Blocklist tidak termuat** | Pastikan file blocklist sudah diletakkan di `assets/blocklists/` |

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE). Lihat file `LICENSE` untuk detail lengkap.

---

## 👨‍💻 Developer

Dikembangkan oleh **Alhifny Wahid** sebagai bagian dari penelitian Tugas Akhir.

---

> **Catatan Privasi**: MindSafe dirancang dengan mengutamakan privasi. Aplikasi HANYA memantau nama domain dan URL, tidak pernah konten halaman atau data pribadi. Semua data disimpan secara lokal dan pengguna memiliki kontrol penuh atas datanya.
