import 'dart:typed_data';

/// Represents an installed browser app discovered on the device.
class BrowserApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;

  const BrowserApp({
    required this.packageName,
    required this.appName,
    this.icon,
  });

  factory BrowserApp.fromMap(Map<dynamic, dynamic> map) {
    return BrowserApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      icon: map['icon'] is Uint8List
          ? map['icon'] as Uint8List
          : (map['icon'] != null
                ? Uint8List.fromList(List<int>.from(map['icon']))
                : null),
    );
  }
}
