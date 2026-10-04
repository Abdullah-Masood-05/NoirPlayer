// The one-time notification-permission prompt decision (pure logic, no
// platform plugins).

import 'package:flutter_test/flutter_test.dart';
import 'package:noir_player/core/services/notification_permission.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  bool decide(
    PermissionStatus status, {
    bool android = true,
    bool asked = false,
  }) => NotificationPermission.shouldRequest(
    isAndroid: android,
    status: status,
    alreadyAsked: asked,
  );

  test('asks on Android when denied and not asked before', () {
    expect(decide(PermissionStatus.denied), isTrue);
  });

  test('never asks twice automatically', () {
    expect(decide(PermissionStatus.denied, asked: true), isFalse);
  });

  test('does not ask when already granted', () {
    expect(decide(PermissionStatus.granted), isFalse);
    expect(decide(PermissionStatus.limited), isFalse);
    expect(decide(PermissionStatus.provisional), isFalse);
  });

  test('does not ask when the system will not show a dialog', () {
    expect(decide(PermissionStatus.permanentlyDenied), isFalse);
    expect(decide(PermissionStatus.restricted), isFalse);
  });

  test('does not ask off Android', () {
    expect(decide(PermissionStatus.denied, android: false), isFalse);
  });
}
