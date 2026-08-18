/// Konfigurasi aplikasi yang bersifat spesifik per-deployment.
///
/// Nilai-nilai di sini TIDAK di-hardcode agar tidak ikut terekspos ketika
/// repositori dibuka secara publik. Semua nilai dibaca melalui `--dart-define`
/// saat proses build, dengan fallback kosong yang aman.
///
/// Contoh penggunaan:
/// ```bash
/// flutter run --dart-define=ADMIN_EMAIL=email.admin@gmail.com
/// flutter build apk --release --dart-define=ADMIN_EMAIL=email.admin@gmail.com
/// ```
///
/// Bila `ADMIN_EMAIL` tidak diisi, panel admin tidak akan pernah aktif untuk
/// akun apa pun. Aplikasi tetap berjalan normal sebagai aplikasi pengguna biasa.
class AppConfig {
  const AppConfig._();

  /// Email Google yang berhak mengakses panel administrator.
  ///
  /// Nilai ini harus sama dengan email pada Firestore Security Rules
  /// (lihat `firestore.rules`), jika tidak, panel admin akan tampil di
  /// aplikasi tetapi seluruh operasi tulisnya ditolak oleh server.
  static const String adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: '',
  );

  /// `true` bila email administrator sudah dikonfigurasi saat build.
  static bool get hasAdminEmail => adminEmail.trim().isNotEmpty;
}
