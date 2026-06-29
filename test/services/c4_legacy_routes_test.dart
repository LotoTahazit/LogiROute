import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// C4: legacy companies/{id}/routes отключён; runtime → logistics/_root/routes.
void main() {
  final libRoot = Directory.current.path.contains('test')
      ? Directory('${Directory.current.path}/../lib')
      : Directory('${Directory.current.path}/lib');

  test('route_builder_service removed from runtime', () {
    expect(
      File('${libRoot.path}/services/route_builder_service.dart').existsSync(),
      isFalse,
    );
    final routeSrc =
        File('${libRoot.path}/services/route_service.dart').readAsStringSync();
    expect(routeSrc.contains('route_builder_service'), isFalse);
    expect(routeSrc.contains('RouteBuilderService'), isFalse);
  });

  test('no legacy companies/{id}/routes writes in lib/', () {
    final legacyPattern = RegExp(
      r"doc\(companyId\)\.collection\('routes'\)",
    );
    final hits = <String>[];
    for (final f in libRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final content = f.readAsStringSync();
      if (legacyPattern.hasMatch(content)) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: 'legacy routes path in: $hits');
  });

  test('FirestorePaths.routes uses logistics/_root/routes', () {
    final src =
        File('${libRoot.path}/services/firestore_paths.dart').readAsStringSync();
    expect(src, contains("collection('logistics')"));
    expect(src, contains("doc('_root')"));
    expect(src, contains("collection('routes')"));
    expect(
      src.contains("doc(companyId).collection('routes')"),
      isFalse,
      reason: 'must not use flat companies/{id}/routes',
    );
  });

  test('route_service writes via FirestorePaths.routes', () {
    final src =
        File('${libRoot.path}/services/route_service.dart').readAsStringSync();
    expect(src, contains('_paths.routes(companyId)'));
  });
}
