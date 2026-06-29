import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logiroute/services/driver_auto_close_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DriverAutoCloseState pending timer', () {
    test('save и load восстанавливают кандидата', () async {
      final started = DateTime(2026, 6, 29, 10, 0, 0);
      await DriverAutoCloseState.savePending(
        pointId: 'p1',
        startedAt: started,
      );

      final pending = await DriverAutoCloseState.loadPending();
      expect(pending?.pointId, 'p1');
      expect(pending?.startedAt, started);
    });

    test('clearPending удаляет сохранённый таймер', () async {
      await DriverAutoCloseState.savePending(
        pointId: 'p1',
        startedAt: DateTime.now(),
      );
      await DriverAutoCloseState.clearPending();
      expect(await DriverAutoCloseState.loadPending(), isNull);
    });
  });

  group('DriverAutoCloseState last location', () {
    test('save и load координат', () async {
      await DriverAutoCloseState.saveLastLocation(32.08, 34.78);
      final loc = await DriverAutoCloseState.loadLastLocation();
      expect(loc?.lat, 32.08);
      expect(loc?.lng, 34.78);
    });
  });

  group('DriverAutoCloseState system stopped', () {
    test('флаг остановки системой', () async {
      expect(await DriverAutoCloseState.wasSystemStoppedBg(), isFalse);
      await DriverAutoCloseState.markSystemStoppedBg(true);
      expect(await DriverAutoCloseState.wasSystemStoppedBg(), isTrue);
      await DriverAutoCloseState.clearSystemStoppedBg();
      expect(await DriverAutoCloseState.wasSystemStoppedBg(), isFalse);
    });
  });
}
