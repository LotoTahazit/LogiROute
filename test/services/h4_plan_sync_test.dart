import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H4: plan/modules/limits — только через applyPlan / applyPlanToCompany.
void main() {
  final libRoot = Directory.current.path.contains('test')
      ? Directory('${Directory.current.path}/../lib')
      : Directory('${Directory.current.path}/lib');

  test('subscription and module_toggle use applyPlan', () {
    for (final path in [
      'screens/admin/subscription_screen.dart',
      'screens/admin/module_toggle_screen.dart',
      'services/company_provision_service.dart',
    ]) {
      final src = File('${libRoot.path}/$path').readAsStringSync();
      expect(src.contains('applyPlan'), isTrue, reason: path);
    }
  });

  test('no bare plan-only root writes in lib services/screens', () {
    final bad = RegExp(
      r"\.set\(\{[^}]*'plan'\s*:",
      dotAll: true,
    );
    final hits = <String>[];
    for (final f in libRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.contains('company_modules_service.dart')) continue;
      if (f.path.contains('company_settings.dart')) continue;
      if (f.path.contains('billing_helpers.dart')) continue;
      final content = f.readAsStringSync();
      if (bad.hasMatch(content) &&
          !content.contains('applyPlan') &&
          !content.contains('rootEntitlementsPatch')) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: 'plan-only writes: $hits');
  });
}
