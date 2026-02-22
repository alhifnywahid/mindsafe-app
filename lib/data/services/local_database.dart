import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';
import 'package:mindsafe_flutter/data/models/app_settings.dart';
import 'package:mindsafe_flutter/data/models/domain_rule.dart';
import 'package:get/get.dart';

class LocalDatabase extends GetxService {
  static const String domainAccessBox = 'domain_access';
  static const String settingsBox = 'settings';
  static const String domainRulesBox = 'domain_rules';
  static const String skipDomainsBox = 'skip_domains';

  late Box<DomainAccess> _domainAccess;
  late Box<AppSettings> _settings;
  late Box<DomainRule> _domainRules;
  late Box<String> _skipDomains;

  Box<DomainAccess> get domainAccess => _domainAccess;
  Box<AppSettings> get settings => _settings;
  Box<DomainRule> get domainRules => _domainRules;
  Box<String> get skipDomains => _skipDomains;

  /// Get domain access records filtered by the given userId.
  List<DomainAccess> userDomainAccess(String userId) {
    if (userId.isEmpty) return [];
    return _domainAccess.values.where((a) => a.userId == userId).toList();
  }

  Future<LocalDatabase> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DomainAccessAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DomainRuleAdapter());
    }

    // Open boxes
    _domainAccess = await Hive.openBox<DomainAccess>(domainAccessBox);
    _settings = await Hive.openBox<AppSettings>(settingsBox);
    _domainRules = await Hive.openBox<DomainRule>(domainRulesBox);
    _skipDomains = await Hive.openBox<String>(skipDomainsBox);

    // Initialize default settings if not exists
    if (_settings.isEmpty) {
      await _settings.put('default', AppSettings());
    }

    // Initialize default domain rules
    await _initializeDefaultRules();

    return this;
  }

  Future<void> _initializeDefaultRules() async {
    // No default rules — admin adds rules manually
  }

  Future<void> clearAll() async {
    await _domainAccess.clear();
    await _settings.clear();
    await _domainRules.clear();
    await _skipDomains.clear();
  }

  Future<void> close() async {
    await _domainAccess.close();
    await _settings.close();
    await _domainRules.close();
    await _skipDomains.close();
  }
}
