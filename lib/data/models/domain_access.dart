import 'package:hive/hive.dart';

part 'domain_access.g.dart';

@HiveType(typeId: 0)
class DomainAccess extends HiveObject {
  @HiveField(0)
  String domain; // Raw domain name

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  int durationSeconds;

  @HiveField(3)
  String category; // adult, safe, gambling, phishing, etc.

  @HiveField(4)
  bool synced;

  @HiveField(5)
  String userId;

  DomainAccess({
    required this.domain,
    required this.timestamp,
    this.durationSeconds = 0,
    this.category = 'safe',
    this.synced = false,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'domain': domain,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'category': category,
      'synced': synced,
      'userId': userId,
    };
  }

  factory DomainAccess.fromMap(Map<String, dynamic> map) {
    return DomainAccess(
      domain: map['domain'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      durationSeconds: map['durationSeconds'] ?? 0,
      category: map['category'] ?? 'safe',
      synced: map['synced'] ?? false,
      userId: map['userId'] ?? '',
    );
  }
}
