import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks once for the Android 13+ notification permission (POST_NOTIFICATIONS).
///
/// Apps targeting Android 13+ start with notifications OFF on a fresh install
/// until they ask. The media-session notification is nominally exempt, but OEM
/// surfaces built on top of it (OxygenOS Live Alerts / Fluid Cloud pill,
/// HyperOS island, One UI Now Bar) and the per-app notification settings they
/// hang off can stay hidden while the app's notifications are disabled.
class NotificationPermission {
  NotificationPermission._();

  static const prefsKey = 'permissions.notificationAsked';

  /// Shared by concurrent callers (e.g. both song tabs) so only one system
  /// dialog is ever in flight — permission_handler rejects parallel requests.
  static Future<PermissionStatus?>? _inFlight;

  /// Pure decision: should we show the system notification-permission dialog?
  ///
  /// Only on Android, only when the permission is plainly denied (not
  /// granted, not permanently denied / restricted by policy), and only if we
  /// have not already asked once automatically.
  @visibleForTesting
  static bool shouldRequest({
    required bool isAndroid,
    required PermissionStatus status,
    required bool alreadyAsked,
  }) {
    if (!isAndroid || alreadyAsked) return false;
    return status == PermissionStatus.denied;
  }

  /// Requests the permission if [shouldRequest] says so. Returns the resulting
  /// status when a dialog was shown, or null when nothing was asked (already
  /// granted, already asked before, not Android, or the request failed).
  static Future<PermissionStatus?> maybeRequest() {
    return _inFlight ??= _maybeRequest().whenComplete(() => _inFlight = null);
  }

  static Future<PermissionStatus?> _maybeRequest() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = await Permission.notification.status;
      if (!shouldRequest(
        isAndroid: true,
        status: status,
        alreadyAsked: prefs.getBool(prefsKey) ?? false,
      )) {
        return null;
      }
      final result = await Permission.notification.request();
      await prefs.setBool(prefsKey, true);
      return result;
    } catch (e) {
      // e.g. another permission dialog was already showing; try next launch.
      debugPrint('Notification permission request failed: $e');
      return null;
    }
  }
}
