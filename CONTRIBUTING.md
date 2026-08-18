# Panduan Kontribusi

Terima kasih atas minat Anda untuk berkontribusi pada **MindSafe**. Dokumen ini
menjelaskan cara menyiapkan lingkungan pengembangan, konvensi yang berlaku, dan
alur kerja yang kami gunakan.

Dengan berkontribusi, Anda dianggap menyetujui [Kode Etik](CODE_OF_CONDUCT.md)
proyek ini.

## Daftar Isi

- [Konteks Proyek](#konteks-proyek)
- [Bentuk Kontribusi](#bentuk-kontribusi)
- [Menyiapkan Lingkungan Pengembangan](#menyiapkan-lingkungan-pengembangan)
- [Struktur Kode](#struktur-kode)
- [Konvensi Penulisan Kode](#konvensi-penulisan-kode)
- [Pengujian](#pengujian)
- [Konvensi Commit](#konvensi-commit)
- [Alur Pull Request](#alur-pull-request)
- [Aturan Khusus: Data Sensitif](#aturan-khusus-data-sensitif)
- [Melaporkan Bug](#melaporkan-bug)
- [Mengusulkan Fitur](#mengusulkan-fitur)
- [Lisensi Kontribusi](#lisensi-kontribusi)

## Konteks Proyek

MindSafe dikembangkan sebagai bagian dari penelitian Tugas Akhir di Program
Studi Teknik Informatika, Universitas Dr. Soetomo. Konsekuensinya:

- Cakupan fitur mengikuti batasan penelitian yang sudah ditetapkan. Usulan yang
  mengubah arah penelitian mungkin ditolak, walaupun secara teknis baik.
- Aplikasi ini **bukan** alat terapi, diagnosis, maupun asesmen adiksi.
  Kontribusi yang menambahkan klaim kesehatan atau psikologis tidak akan
  diterima.
- Pemantauan dibatasi pada **nama domain dan URL**. Kontribusi yang mencoba
  mendekripsi lalu lintas HTTPS atau membaca konten halaman berada di luar
  cakupan proyek dan akan ditolak.

## Bentuk Kontribusi

Semua bentuk berikut sangat dihargai:

| Bentuk | Keterangan |
|--------|------------|
| Laporan bug | Gunakan templat *issue* yang tersedia |
| Perbaikan bug | Sertakan langkah reproduksi pada deskripsi PR |
| Perbaikan dokumentasi | Termasuk perbaikan ejaan dan tautan rusak |
| Penerjemahan | Menambah atau memperbaiki terjemahan di `lib/core/localization/` |
| Peningkatan aksesibilitas | Kontras warna, ukuran sentuh, label *screen reader* |
| Optimasi performa | Sertakan pengukuran sebelum dan sesudah |
| Penambahan pengujian | Menaikkan cakupan pengujian unit |

## Menyiapkan Lingkungan Pengembangan

### Prasyarat

| Kebutuhan | Versi minimum |
|-----------|---------------|
| Flutter SDK | 3.11.0 |
| Dart SDK | 3.11.0 |
| Android SDK | API 21 (Android 5.0) |
| JDK | 17 |
| Perangkat uji | Perangkat Android fisik (disarankan) |

> `VpnService` dan `AccessibilityService` berperilaku tidak konsisten pada
> emulator. Verifikasi fitur pemantauan sebaiknya dilakukan di perangkat fisik.

### Langkah

```bash
# 1. Fork lalu clone repositori
git clone https://github.com/<username-anda>/mindsafe-app.git
cd mindsafe-app

# 2. Pasang dependensi
flutter pub get

# 3. Hasilkan adapter Hive
dart run build_runner build --delete-conflicting-outputs

# 4. Siapkan konfigurasi Firebase Anda sendiri
cp android/app/google-services.json.example android/app/google-services.json
# lalu isi dengan nilai dari Firebase Console milik Anda

# 5. Unduh berkas blocklist ke assets/blocklists/
#    (lihat bagian Blocklist pada README)

# 6. Jalankan aplikasi
flutter run --dart-define=ADMIN_EMAIL=surel.admin.anda@gmail.com
```

### Menjalankan tanpa panel admin

Jika Anda tidak membutuhkan panel administrator, jalankan tanpa `--dart-define`.
Aplikasi tetap berfungsi penuh sebagai aplikasi pengguna dan panel admin
otomatis tidak aktif.

```bash
flutter run
```

## Struktur Kode

```
lib/
├── app/
│   ├── bindings/       Dependency injection GetX
│   ├── controllers/    Controller (state + orkestrasi)
│   └── services/       Layanan level aplikasi (background tracking)
├── core/
│   ├── config/         Konfigurasi build-time (--dart-define)
│   ├── constants/      Warna, spacing, text style
│   ├── localization/   Terjemahan ID & EN
│   ├── theme/          Tema terang & gelap
│   ├── utils/          Fungsi pembantu
│   └── widgets/        Widget dasar yang dipakai bersama
├── data/
│   ├── models/         Model data + adapter Hive
│   ├── repositories/   Akses Firestore
│   └── services/       Auth, VPN, Database, Classifier, Sync, Notification
├── routes/             Definisi rute
├── screens/            Halaman aplikasi, satu folder per fitur
└── widgets/            Widget lintas halaman

android/app/src/main/kotlin/com/gopret/mindsafe/
├── LocalVpnService.kt        Proxy DNS lokal berbasis VpnService
├── BrowserMonitorService.kt  AccessibilityService untuk membaca URL
└── MainActivity.kt           Jembatan MethodChannel & EventChannel
```

### Prinsip yang berlaku

- **Pemisahan lapisan**: `screens/` tidak mengakses `data/services/` secara
  langsung; gunakan controller pada `app/controllers/`.
- **Offline-first**: Hive adalah sumber kebenaran utama; Firestore hanya
  cadangan dan agregasi. Fitur baru harus tetap berjalan tanpa koneksi.
- **Tanpa nilai sensitif di kode**: gunakan `AppConfig` dan `--dart-define`.

## Konvensi Penulisan Kode

- Jalankan `dart format .` sebelum melakukan *commit*.
- Pastikan `flutter analyze` bersih; aturan mengikuti `analysis_options.yaml`.
- Gunakan `lowerCamelCase` untuk variabel dan fungsi, `UpperCamelCase` untuk
  kelas, dan `snake_case` untuk nama berkas.
- Tambahkan komentar dokumentasi (`///`) pada API publik yang tidak jelas dari
  namanya. Ikuti kerapatan komentar yang sudah ada, jangan berlebihan.
- Semua teks yang tampil di antarmuka harus melalui sistem lokalisasi GetX dan
  ditambahkan pada berkas terjemahan ID maupun EN.
- Gunakan token dari `AppColors`, `AppSpacing`, dan `AppTextStyles`, jangan
  menuliskan nilai warna atau ukuran secara langsung.

## Pengujian

Pengujian unit berada di `test/` dan mencerminkan struktur `lib/`.

```bash
# seluruh pengujian
flutter test

# satu berkas
flutter test test/services/domain_classifier_logic_test.dart

# dengan laporan cakupan
flutter test --coverage
```

Ketentuan:

- Setiap perbaikan bug sebaiknya disertai pengujian yang gagal sebelum
  perbaikan dan lulus sesudahnya.
- Logika klasifikasi domain, retensi data, dan perhitungan statistik wajib
  memiliki pengujian unit.
- Gunakan domain fiktif pada data uji (`contoh.test`, `domain-a.test`), bukan
  domain nyata, dan jangan pernah domain dewasa nyata.

## Konvensi Commit

Gunakan format [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipe>(<cakupan opsional>): <ringkasan singkat>
```

| Tipe | Penggunaan |
|------|------------|
| `feat` | Fitur baru |
| `fix` | Perbaikan bug |
| `docs` | Perubahan dokumentasi saja |
| `style` | Format kode tanpa perubahan perilaku |
| `refactor` | Restrukturisasi tanpa perubahan perilaku |
| `perf` | Peningkatan performa |
| `test` | Penambahan atau perbaikan pengujian |
| `build` | Perubahan konfigurasi *build* atau dependensi |
| `chore` | Pekerjaan pemeliharaan lain |

Contoh:

```
fix(classifier): tangani domain dengan trailing dot
feat(history): tambahkan filter kategori pada tab Ringkasan
docs(readme): perbaiki nama paket Android
```

Tulis ringkasan dalam bentuk kalimat perintah, huruf kecil, tanpa titik di
akhir, maksimal 72 karakter.

## Alur Pull Request

1. Buat branch dari `master` dengan nama deskriptif:
   `fix/classifier-trailing-dot` atau `feat/history-category-filter`.
2. Kerjakan perubahan dalam *commit* yang fokus dan mudah dibaca.
3. Pastikan seluruh perintah berikut lulus:

   ```bash
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   ```

4. Perbarui dokumentasi bila perilaku yang terdokumentasi berubah.
5. Buka Pull Request menggunakan templat yang tersedia, jelaskan **apa** yang
   berubah dan **mengapa**.
6. Sertakan tangkapan layar atau rekaman untuk setiap perubahan antarmuka,
   dalam mode terang maupun gelap.
7. Tanggapi ulasan dengan *commit* tambahan; hindari `force push` setelah
   proses ulasan dimulai agar riwayat diskusi tetap dapat diikuti.

Pull Request akan digabungkan setelah pemeriksaan otomatis lulus dan pengelola
menyetujui.

## Aturan Khusus: Data Sensitif

Aturan ini bersifat mutlak dan pelanggaran akan menyebabkan PR ditolak:

- **Jangan** meng-*commit* `android/app/google-services.json`,
  `lib/firebase_options.dart`, `*.jks`, `*.keystore`,
  `android/key.properties`, atau berkas `.env` apa pun.
- **Jangan** menuliskan alamat surel nyata di kode, `firestore.rules`,
  pengujian, atau dokumentasi. Gunakan `admin@example.com`.
- **Jangan** menyertakan nama domain dewasa yang utuh. Gunakan
  `contoh-domain.tld` atau penyensoran serupa.
- **Jangan** melampirkan riwayat penelusuran nyata, UID Firebase nyata, atau
  tangkapan layar yang memperlihatkan data pengguna.
- Sebelum *commit*, periksa perubahan Anda dengan `git diff --cached`.

Kerentanan keamanan tidak dilaporkan melalui *issue* publik. Ikuti
[SECURITY.md](SECURITY.md).

## Melaporkan Bug

Gunakan templat *Laporan Bug*. Laporan yang baik memuat:

- Perilaku yang diharapkan dan perilaku yang terjadi
- Langkah reproduksi yang berurutan
- Versi Android, model perangkat, dan versi aplikasi
- Nama browser bila terkait pemantauan URL
- Status *Secure DNS (DNS over HTTPS)* pada browser, karena hal ini sering
  menjadi penyebab domain tidak terdeteksi
- Log dari `flutter logs` atau `adb logcat`, dengan data pribadi disensor

## Mengusulkan Fitur

Buka *issue* dengan templat *Usulan Fitur* dan jelaskan masalah yang ingin
diselesaikan, bukan hanya solusi yang diinginkan. Karena proyek ini terikat
pada batasan penelitian, mohon tunggu tanggapan pengelola sebelum mulai
mengerjakan fitur besar agar pekerjaan Anda tidak terbuang.

## Lisensi Kontribusi

Dengan mengirimkan kontribusi, Anda menyetujui bahwa kontribusi tersebut
dilisensikan di bawah [MIT License](LICENSE) yang sama dengan proyek ini.
