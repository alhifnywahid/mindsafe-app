import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mindsafe_flutter/data/models/browser_app.dart';

class VpnService extends GetxService {
  static const platform = MethodChannel('com.mindsafe/vpn');
  static const vpnEventChannel = EventChannel('com.mindsafe/vpn_events');
  static const urlEventChannel = EventChannel('com.mindsafe/url_events');

  // VPN domain events stream
  final _vpnEventStream = Rx<Stream<dynamic>?>(null);
  Stream<dynamic>? get vpnEventStream => _vpnEventStream.value;

  // Browser URL events stream
  final _urlEventStream = Rx<Stream<dynamic>?>(null);
  Stream<dynamic>? get urlEventStream => _urlEventStream.value;

  Future<VpnService> init() async {
    _vpnEventStream.value = vpnEventChannel.receiveBroadcastStream();
    _urlEventStream.value = urlEventChannel.receiveBroadcastStream();
    return this;
  }

  Future<bool> startVpn({List<String>? allowedPackages}) async {
    try {
      final result = await platform.invokeMethod('startVpn', {
        if (allowedPackages != null) 'allowedPackages': allowedPackages,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to start VPN: ${e.message}');
      return false;
    }
  }

  Future<List<BrowserApp>> getBrowserApps() async {
    try {
      final result = await platform.invokeMethod('getBrowserApps');
      if (result is List) {
        return result
            .cast<Map<dynamic, dynamic>>()
            .map((m) => BrowserApp.fromMap(m))
            .toList();
      }
      return [];
    } on PlatformException catch (e) {
      debugPrint('Failed to get browser apps: ${e.message}');
      return [];
    }
  }

  Future<bool> stopVpn() async {
    try {
      final result = await platform.invokeMethod('stopVpn');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop VPN: ${e.message}');
      return false;
    }
  }

  Future<String> getStatus() async {
    try {
      final result = await platform.invokeMethod('getStatus');
      return result.toString();
    } on PlatformException catch (e) {
      debugPrint('Failed to get VPN status: ${e.message}');
      return 'error';
    }
  }

  /// Check if Accessibility Service is enabled
  Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await platform.invokeMethod('isAccessibilityEnabled');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Open Android Accessibility Settings for user to enable the service
  Future<void> openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open accessibility settings: ${e.message}');
    }
  }

  void debugPrint(String msg) {
    // ignore: avoid_print
    print(msg);
  }
}
