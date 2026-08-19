# Catatan Perubahan

Seluruh perubahan penting pada proyek ini didokumentasikan di berkas ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/)
dan proyek ini menggunakan [Semantic Versioning](https://semver.org/lang/id/).

## [Belum Dirilis]

## [1.1.0] - 2026-08-19

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
- Konfigurasi penandatanganan rilis: `android/key.properties` dibaca oleh
  `android/app/build.gradle.kts`, dengan `android/key.properties.example`
  sebagai templat. Build rilis tanpa keystore tetap berjalan memakai kunci
  debug agar kontributor tidak terhalang
- Bagian "Menandatangani Build Rilis" di README beserta panduan singkatnya
  di `CONTRIBUTING.md`

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
- Versi Flutter pada alur kerja CI disematkan ke `3.41.1` agar cocok dengan
  Gradle wrapper `8.12`. Tanpa penyematan, `channel: stable` memasang Flutter
  `3.47` yang mensyaratkan Gradle `8.14.0` ke atas dan menggagalkan *build* APK
- Prasyarat versi Flutter di README dan `CONTRIBUTING.md` dipertegas menjadi
  `3.41.x` beserta penjelasan keterkaitannya dengan versi Gradle
- Langkah `build_runner` dihapus dari CI, README, dan `CONTRIBUTING.md` karena
  adapter Hive (`lib/data/models/*.g.dart`) sudah ikut terlacak dan
  `hive_generator` belum kompatibel dengan `analyzer` yang dibutuhkan `forui`
- Nomor versi diselaraskan menjadi `1.1.0` di `pubspec.yaml` (`1.1.0+2`) dan
  `CITATION.cff`. Sebelumnya berkas proyek menuliskan `0.1.0` sementara rilis
  publik sudah bertag `v1.0.0`
- APK rilis tidak lagi ditandatangani kunci debug

### Dihapus

- `android/app/google-services.json` dikeluarkan dari pelacakan Git
- Berkas kerja pribadi yang sebelumnya ikut terlacak

### Diperbaiki

- Tiga asersi pengujian di `test/models/` yang mengharapkan kategori `unknown`
  disesuaikan menjadi `safe`, mengikuti perilaku `domain_classifier.dart`
- Tautan *troubleshooting* pada `.github/ISSUE_TEMPLATE/config.yml` menunjuk
  jangkar README yang benar
- Tautan pembanding versi di kaki berkas ini: `[0.1.0]` yang mengarah ke tag
  `v0.1.0` (tidak pernah ada, menghasilkan 404) diganti menjadi `[1.0.0]`

### Keamanan

- Alamat surel administrator yang sebelumnya terekspos di kode sumber,
  `firestore.rules`, dan berkas pengujian telah diganti placeholder
- Konfigurasi Firebase tidak lagi ikut di-*commit*

## [1.0.0] - 2026-02-22

Rilis publik pertama. Tag `v1.0.0` di GitHub menunjuk ke rilis ini. Berkas
proyek sebelumnya masih menuliskan `0.1.0`; ketidaksesuaian tersebut
diselaraskan pada 1.1.0.

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

[Belum Dirilis]: https://github.com/alhifnywahid/mindsafe-app/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/alhifnywahid/mindsafe-app/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/alhifnywahid/mindsafe-app/releases/tag/v1.0.0
