import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/notifications/notifications.dart';
import 'package:untitled/src/features/common/data/trusted_backend.dart';

void main() {
  test('order activity uses the latest persisted status update', () {
    final created = DateTime.utc(2026, 9, 25);
    final updated = DateTime.utc(2026, 9, 26);
    expect(
      orderUpdateTime({'createdAt': Timestamp.fromDate(created)}).toUtc(),
      created,
    );
    expect(
      orderUpdateTime({
        'createdAt': Timestamp.fromDate(created),
        'updatedAt': Timestamp.fromDate(updated),
      }).toUtc(),
      updated,
    );
  });

  test('undeployed push never pretends registration succeeded', () async {
    expect(HarvestNotifications.pushBackendEnabled, false);
    await expectLater(HarvestNotifications.register(), throwsStateError);
    // With no sender, startup does not request Firebase tokens or permissions.
    await HarvestNotifications.restore();
  }, skip: TrustedBackend.enabled);

  test('configured deployment enables the trusted push sender', () {
    expect(HarvestNotifications.pushBackendEnabled, true);
    expect(Uri.parse(TrustedBackend.url).host, 'script.google.com');
    expect(Uri.parse(TrustedBackend.url).scheme, 'https');
  }, skip: !TrustedBackend.enabled);
}
