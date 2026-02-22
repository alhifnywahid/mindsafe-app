import 'package:hive/hive.dart';

part 'domain_rule.g.dart';

@HiveType(typeId: 2)
class DomainRule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String pattern; // Regex pattern or exact domain

  @HiveField(2)
  String category; // adult, safe, gambling, phishing, etc.

  @HiveField(3)
  int priority; // Higher priority rules checked first

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  bool isRegex; // true if pattern is regex, false if exact match

  DomainRule({
    required this.id,
    required this.pattern,
    required this.category,
    this.priority = 0,
    this.isActive = true,
    this.isRegex = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pattern': pattern,
      'category': category,
      'priority': priority,
      'isActive': isActive,
      'isRegex': isRegex,
    };
  }

  factory DomainRule.fromMap(Map<String, dynamic> map) {
    return DomainRule(
      id: map['id'] ?? '',
      pattern: map['pattern'] ?? '',
      category: map['category'] ?? 'safe',
      priority: map['priority'] ?? 0,
      isActive: map['isActive'] ?? true,
      isRegex: map['isRegex'] ?? false,
    );
  }
}
