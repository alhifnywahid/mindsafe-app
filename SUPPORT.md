# Dukungan

Terima kasih sudah menggunakan **MindSafe**. Halaman ini menjelaskan ke mana
harus bertanya sesuai jenis kebutuhan Anda.

## Pilih Kanal yang Tepat

| Kebutuhan                              | Kanal                                                                                                                            |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Aplikasi tidak berjalan sesuai harapan | [Buat issue bug](https://github.com/alhifnywahid/mindsafe-app/issues/new?template=bug_report.yml)                                |
| Punya ide fitur                        | [Buat issue usulan fitur](https://github.com/alhifnywahid/mindsafe-app/issues/new?template=feature_request.yml)                  |
| Dokumentasi salah atau membingungkan   | [Buat issue dokumentasi](https://github.com/alhifnywahid/mindsafe-app/issues/new?template=docs_issue.yml)                        |
| Pertanyaan penggunaan atau instalasi   | [Diskusi](https://github.com/alhifnywahid/mindsafe-app/discussions)                                                              |
| Menemukan kerentanan keamanan          | [Security Advisory privat](https://github.com/alhifnywahid/mindsafe-app/security/advisories/new) - **jangan** lewat issue publik |
| Ingin berkontribusi kode               | Baca [CONTRIBUTING.md](CONTRIBUTING.md)                                                                                          |

## Sebelum Bertanya

Sebagian besar kendala sudah terjawab di dokumentasi:

1. **Domain tidak terdeteksi** - penyebab paling sering adalah _Secure DNS
   (DNS over HTTPS)_ yang aktif di browser. Matikan dahulu, lalu coba lagi.
   Lihat bagian Troubleshooting pada [README](README.md).
2. **Gagal _build_** - pastikan `android/app/google-services.json` sudah dibuat
   dari berkas `.example` dan diisi dengan konfigurasi Firebase Anda sendiri.
3. **Klasifikasi selalu `safe`** - berkas blocklist belum diletakkan di
   `assets/blocklists/`. Lihat [panduan folder blocklist](assets/blocklists/README.md).
4. **Panel admin tidak muncul** - aplikasi harus dijalankan dengan
   `--dart-define=ADMIN_EMAIL=surel.anda@gmail.com` dan email tersebut wajib
   sama dengan yang ada di `firestore.rules`.

## Ekspektasi Waktu Tanggapan

Proyek ini merupakan penelitian Tugas Akhir yang dikelola oleh satu orang.
Tanggapan biasanya diberikan dalam beberapa hari kerja, namun tidak ada
jaminan waktu. Laporan yang lengkap dan mudah direproduksi akan ditangani
lebih cepat.

## Yang Tidak Termasuk Dukungan

- Bantuan menyiapkan proyek Firebase pribadi Anda - silakan ikuti
  [dokumentasi resmi Firebase](https://firebase.google.com/docs/android/setup).
- Permintaan menambahkan kategori blocklist di luar dataset UT1.
- Konsultasi psikologis, medis, atau penanganan adiksi. MindSafe adalah alat
  pemantauan teknis, bukan alat diagnosis maupun terapi. Bila Anda atau orang
  terdekat membutuhkan bantuan profesional, hubungi tenaga kesehatan yang
  berkompeten.
