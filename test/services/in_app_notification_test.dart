import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/in_app_notification_service.dart';

void main() {
  group('InAppNotification', () {
    test('fromMap creates notification correctly', () {
      final map = {
        'type': 'billing_grace',
        'title': 'Grace Period',
        'body': 'Your account is in grace period',
        'severity': 'warning',
        'read': false,
        'metadata': {'daysLeft': 3},
      };

      final notif = InAppNotification.fromMap(map, 'test-id');
      expect(notif.id, 'test-id');
      expect(notif.type, 'billing_grace');
      expect(notif.title, 'Grace Period');
      expect(notif.body, 'Your account is in grace period');
      expect(notif.severity, 'warning');
      expect(notif.read, false);
      expect(notif.metadata?['daysLeft'], 3);
    });

    test('fromMap handles missing fields gracefully', () {
      final notif = InAppNotification.fromMap({}, 'empty-id');
      expect(notif.id, 'empty-id');
      expect(notif.type, '');
      expect(notif.title, '');
      expect(notif.body, '');
      expect(notif.severity, 'info');
      expect(notif.read, false);
      expect(notif.createdAt, isNull);
    });

    test('iconInfo returns correct colors for severity', () {
      final critical = InAppNotification(
        id: '1',
        type: 'test',
        title: '',
        body: '',
        severity: 'critical',
      );
      expect(critical.iconInfo.colorValue, 0xFFD32F2F); // red

      final warning = InAppNotification(
        id: '2',
        type: 'test',
        title: '',
        body: '',
        severity: 'warning',
      );
      expect(warning.iconInfo.colorValue, 0xFFF57C00); // orange

      final info = InAppNotification(
        id: '3',
        type: 'test',
        title: '',
        body: '',
        severity: 'info',
      );
      expect(info.iconInfo.colorValue, 0xFF1976D2); // blue
    });
  });
}
