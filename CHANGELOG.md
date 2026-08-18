# Catatan Perubahan

Seluruh perubahan penting pada proyek ini didokumentasikan di berkas ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/)
dan proyek ini menggunakan [Semantic Versioning](https://semver.org/lang/id/).

## [Belum Dirilis]

### Ditambahkan

- Berkas kesehatan komunitas untuk keperluan sumber terbuka:
  `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`,
  `CITATION.cff`, dan `CHANGELOG.md`
- Templat *issue* (bug, usulan fitur, dokumentasi) dan templat Pull Request
- Alur kerja CI GitHub Actions: pemeriksaan format, analisis statis, pengujian
  unit, pemeriksaan berkas sensitif, dan *build* APK debug
- Konfigurasi Dependabot untuk pembaruan dependensi pub, Gradle, dan Actions
- `lib/core/config/app_config.dart` untuk membaca konfigurasi saat *build*
  melalui `--dart-define`
- `android/app/google-services.json.example` sebagai acuan konfigurasi Firebase
- Logo aplikasi (`assets/icons/mindsafe-logo.svg` dan `.png`)
- Halaman pengalihan GitHub Pages di `docs/index.html`
- Panduan folder blocklist di `assets/blocklists/README.md`

### Diubah

- Email administrator tidak lagi ditulis langsung di kode. Nilai dibaca saat
  *build* melalui `--dart-define=ADMIN_EMAIL=...`; bila tidak diisi, panel
  admin tidak aktif untuk akun mana pun
- `firestore.rules` memakai email placeholder, dilengkapi catatan penyesuaian
  sebelum *deploy*
- README ditulis ulang: nama paket Android diperbaiki menjadi
  `com.gopret.mindsafe`, alur konfigurasi baru didokumentasikan
- `.gitignore` diperketat untuk konfigurasi Firebase, *keystore*, berkas `.env`,
  dan direktori catatan pribadi

### Dihapus

- `android/app/google-services.json` dikeluarkan dari pelacakan Git
- Berkas kerja pribadi yang sebelumnya ikut terlacak

### Keamanan

- Alamat surel administrator yang sebelumnya terekspos di kode sumber,
  `firestore.rules`, dan berkas pengujian telah diganti placeholder
- Konfigurasi Firebase tidak lagi ikut di-*commit*

## [0.1.0] - 2026-03-08

### Ditambahkan

- Pemantauan DNS berbasis `VpnService` lokal tanpa memerlukan akses *root*
- Penangkapan URL browser melalui `AccessibilityService`
- Klasifikasi domain tiga tahap: aturan kustom, daftar domain diabaikan,
  lalu UT1 Blocklist (11 kategori)
- Penyimpanan lokal Hive dengan pendekatan *offline-first*
- Autentikasi Google Sign-In melalui Firebase Auth
- Sinkronisasi opsional ke Cloud Firestore
- Beranda dengan kartu pemantauan dan statistik harian
- Halaman Riwayat dengan tab Ringkasan dan Kalender beserta grafik
  harian, mingguan, dan bulanan
- Halaman Analisis berisi pola penelusuran dan rekomendasi
- Notifikasi lokal saat domain berbahaya terdeteksi
- Pengaturan tema terang, gelap, dan mengikuti sistem
- Dukungan dua bahasa: Indonesia dan Inggris
- Pengaturan retensi data 7, 30, atau 90 hari
- Panel admin: dasbor agregat, pengelolaan aturan domain, daftar domain
  diabaikan, dan pengiriman notifikasi global
- Migrasi antarmuka ke ForUI beserta perbaikan *toast* dan tampilan pemantauan
- Aturan keamanan Cloud Firestore
- Onboarding pengguna baru dan halaman *splash*
- Lisensi MIT

[Belum Dirilis]: https://github.com/alhifnywahid/mindsafe-app/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/alhifnywahid/mindsafe-app/releases/tag/v0.1.0
