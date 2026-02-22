import 'package:get/get.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/notification_service.dart';
import 'package:mindsafe_flutter/data/services/vpn_service.dart';
import 'package:mindsafe_flutter/data/services/domain_classifier.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize services asynchronously
    Get.putAsync(() => LocalDatabase().init(), permanent: true);
    Get.putAsync(() => AuthService().init(), permanent: true);
    Get.putAsync(() => VpnService().init(), permanent: true);
    Get.putAsync(() => DomainClassifier().init(), permanent: true);
    Get.putAsync(() => NotificationService().init(), permanent: true);
  }
}
