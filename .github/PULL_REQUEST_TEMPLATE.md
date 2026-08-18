## Ringkasan

<!-- Jelaskan apa yang berubah dan mengapa. -->

## Jenis Perubahan

<!-- Tandai yang sesuai dengan [x] -->

- [ ] Perbaikan bug (tidak mengubah perilaku lain)
- [ ] Fitur baru (tidak merusak perilaku yang ada)
- [ ] Perubahan yang berpotensi merusak kompatibilitas
- [ ] Dokumentasi saja
- [ ] Refactor / perbaikan format tanpa perubahan perilaku
- [ ] Penambahan atau perbaikan pengujian

## Issue Terkait

<!-- Contoh: Closes #12 -->

## Cara Pengujian

<!-- Jelaskan langkah verifikasi yang Anda lakukan. -->

- Perangkat uji:
- Versi Android:
- Langkah yang diuji:

## Tangkapan Layar

<!-- Wajib untuk perubahan antarmuka. Sertakan mode terang dan mode gelap. -->

| Sebelum | Sesudah |
|---------|---------|
|         |         |

## Checklist

- [ ] `dart format .` sudah dijalankan
- [ ] `flutter analyze` bersih, tanpa peringatan baru
- [ ] `flutter test` lulus seluruhnya
- [ ] Teks antarmuka baru sudah ditambahkan ke terjemahan **ID dan EN**
- [ ] Menggunakan token `AppColors` / `AppSpacing` / `AppTextStyles`, tanpa nilai literal
- [ ] Dokumentasi diperbarui bila perilaku yang terdokumentasi berubah
- [ ] Fitur tetap berfungsi tanpa koneksi internet (offline-first), bila relevan

## Checklist Data Sensitif

- [ ] Tidak ada `google-services.json`, `firebase_options.dart`, keystore, atau `.env` yang ikut ter-*commit*
- [ ] Tidak ada alamat surel nyata di kode, `firestore.rules`, pengujian, maupun dokumentasi
- [ ] Tidak ada nama domain dewasa yang utuh pada kode, pengujian, atau tangkapan layar
- [ ] Tangkapan layar tidak memperlihatkan data pengguna nyata

## Catatan Tambahan

<!-- Keputusan desain, kompromi, atau hal yang perlu diperhatikan peninjau. -->
