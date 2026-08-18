# Kebijakan Keamanan

MindSafe adalah aplikasi pemantauan aktivitas akses domain yang berjalan di
perangkat pengguna dan memerlukan izin sistem yang sensitif (`VpnService` dan
`AccessibilityService`). Karena itu, laporan keamanan kami tangani dengan
serius.

## Versi yang Didukung

Proyek ini merupakan hasil penelitian Tugas Akhir dan dikembangkan dengan
sumber daya terbatas. Hanya versi terbaru pada branch `master` yang menerima
perbaikan keamanan.

| Versi                | Status Dukungan   |
| -------------------- | ----------------- |
| `master` (terbaru)   | ✅ Didukung       |
| Rilis/tag sebelumnya | ❌ Tidak didukung |

## Cara Melaporkan Kerentanan

**Jangan melaporkan kerentanan keamanan melalui GitHub Issues publik.**

Gunakan kanal privat berikut:

1. Buka **[Security Advisory privat](https://github.com/alhifnywahid/mindsafe-app/security/advisories/new)**
   pada repositori ini, atau
2. Hubungi pengelola secara langsung melalui profil GitHub
   [@alhifnywahid](https://github.com/alhifnywahid).

Sertakan informasi berikut agar laporan dapat ditindaklanjuti dengan cepat:

- Jenis kerentanan (contoh: kebocoran data, _bypass_ aturan Firestore,
  eskalasi hak akses admin)
- Berkas dan baris kode yang terdampak, bila diketahui
- Langkah reproduksi yang jelas dan berurutan
- Dampak yang mungkin terjadi terhadap pengguna
- Versi Android, versi aplikasi, dan perangkat yang digunakan saat pengujian

### Target Waktu Tanggapan

| Tahap                              | Target           |
| ---------------------------------- | ---------------- |
| Konfirmasi laporan diterima        | 3 hari kerja     |
| Penilaian awal & tingkat keparahan | 7 hari kerja     |
| Perbaikan atau rencana mitigasi    | 30 hari kalender |

Proyek ini dikelola oleh satu orang, sehingga target di atas bersifat upaya
terbaik, bukan jaminan kontrak.

### Pengungkapan Terkoordinasi

Kami mengikuti prinsip _coordinated disclosure_. Mohon berikan waktu bagi
pengelola untuk menerbitkan perbaikan sebelum informasi kerentanan
dipublikasikan. Kontributor yang melaporkan dengan bertanggung jawab akan
dicantumkan pada catatan rilis apabila mereka setuju.

## Cakupan Laporan

### Termasuk dalam cakupan

- Kebocoran data pengguna melalui Cloud Firestore, termasuk aturan keamanan
  yang terlalu permisif
- Eskalasi hak akses menjadi administrator tanpa otorisasi
- Kebocoran nama domain, riwayat penelusuran, atau data pribadi ke pihak ketiga
- Penyalahgunaan `VpnService` atau `AccessibilityService` di luar tujuan
  pemantauan nama domain
- Penyimpanan kredensial, kunci API, atau token secara tidak aman di dalam
  repositori maupun artefak _build_
- Kerentanan pada mekanisme sinkronisasi antara penyimpanan lokal (Hive) dan
  Firestore

### Tidak termasuk dalam cakupan

- Isu yang membutuhkan perangkat yang sudah di-_root_ atau _bootloader_ yang
  sudah dibuka
- Isu yang membutuhkan akses fisik ke perangkat yang sudah tidak terkunci
- Serangan rekayasa sosial terhadap pengguna atau pengelola
- Kerentanan pada dependensi pihak ketiga yang sudah dipublikasikan dan belum
  tersedia versi perbaikannya - silakan laporkan ke proyek asalnya
- Tidak terdeteksinya suatu domain karena browser menggunakan _DNS over HTTPS_.
  Ini adalah batasan arsitektur yang sudah didokumentasikan, bukan kerentanan.
- Laporan hasil pemindai otomatis tanpa bukti dampak nyata

## Praktik Keamanan pada Repositori Ini

Kontributor wajib memperhatikan hal-hal berikut:

- **Berkas kredensial tidak pernah di-_commit_**. `android/app/google-services.json`,
  `lib/firebase_options.dart`, `*.jks`, `*.keystore`, `android/key.properties`,
  dan seluruh berkas `.env` sudah tercantum di `.gitignore`. Gunakan
  `android/app/google-services.json.example` sebagai acuan.
- **Email administrator tidak di-_hardcode_**. Nilai tersebut dibaca saat
  _build_ melalui `--dart-define=ADMIN_EMAIL=...` dan dibaca di kode melalui
  `lib/core/config/app_config.dart`. Jangan pernah menuliskan alamat surel
  nyata ke dalam kode, berkas uji, dokumentasi, maupun `firestore.rules`.
- **`firestore.rules` di repositori memakai email placeholder**. Sesuaikan
  secara lokal sebelum melakukan `firebase deploy`, dan jangan meng-_commit_
  hasil penyesuaian tersebut.
- **Data uji harus sintetis**. Jangan menyertakan riwayat penelusuran nyata,
  UID Firebase nyata, atau tangkapan layar yang memuat alamat surel pengguna.
- **Nama domain dewasa harus disensor** pada setiap laporan, dokumentasi, dan
  berkas uji.

## Catatan Riwayat Repositori

Repositori ini pernah menyertakan `android/app/google-services.json` pada
_commit_ awal. Berkas tersebut telah dikeluarkan dari pelacakan Git, namun
masih dapat ditemukan pada riwayat _commit_ lama. Kunci API Firebase Android
yang bersifat publik pada berkas tersebut wajib dibatasi melalui pengaturan
_API restrictions_ di Google Cloud Console dan/atau dirotasi. Keamanan data
tetap ditegakkan oleh Firestore Security Rules, bukan oleh kerahasiaan kunci
API klien.
