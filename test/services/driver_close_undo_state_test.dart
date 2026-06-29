import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/config/app_config.dart';
import 'package:logiroute/models/delivery_point.dart';
import 'package:logiroute/services/driver_close_undo_state.dart';

DeliveryPoint _point({
  String id = 'p1',
  String status = DeliveryPoint.statusInProgress,
  bool autoCompleted = true,
  DateTime? completedAt,
}) {
  return DeliveryPoint(
    id: id,
    companyId: 'c1',
    address: 'a',
    latitude: 32.08,
    longitude: 34.78,
    clientName: 'Client',
    urgency: 'n',
    pallets: 0,
    boxes: 0,
    status: status,
    autoCompleted: autoCompleted,
    completedAt: completedAt,
  );
}

void main() {
  final t0 = DateTime(2026, 6, 21, 12, 0, 0);

  test('undo доступен сразу после закрытия', () {
    final offer = createCloseUndoOffer(
      point: _point(),
      previousStatus: DeliveryPoint.statusInProgress,
      autoCompleted: true,
      now: t0,
    );
    expect(offer.canUndo('p1', t0), isTrue);
    expect(offer.remainingSeconds(t0), greaterThan(0));
  });

  test('undo исчезает после timeout', () {
    final offer = createCloseUndoOffer(
      point: _point(),
      previousStatus: DeliveryPoint.statusInProgress,
      autoCompleted: true,
      now: t0,
      uiDuration: const Duration(seconds: 5),
    );
    expect(offer.isExpired(t0.add(const Duration(seconds: 6))), isTrue);
    expect(offer.canUndo('p1', t0.add(const Duration(seconds: 6))), isFalse);
  });

  test('закрытие второй точки — undo только для последней', () {
    final first = createCloseUndoOffer(
      point: _point(id: 'p1'),
      previousStatus: DeliveryPoint.statusInProgress,
      autoCompleted: true,
      now: t0,
    );
    final second = createCloseUndoOffer(
      point: _point(id: 'p2'),
      previousStatus: DeliveryPoint.statusAssigned,
      autoCompleted: true,
      now: t0,
    );
    expect(first.pointId, 'p1');
    expect(second.pointId, 'p2');
    expect(second.canUndo('p1', t0), isFalse);
    expect(second.canUndo('p2', t0), isTrue);
  });

  test('undo не работает для чужой pointId', () {
    final offer = createCloseUndoOffer(
      point: _point(id: 'p1'),
      previousStatus: DeliveryPoint.statusInProgress,
      autoCompleted: true,
      now: t0,
    );
    expect(offer.canUndo('other', t0), isFalse);
  });

  test('closeUndoRemainingUi — ноль после окна', () {
    final completed = t0;
    final left = closeUndoRemainingUi(
      completed,
      t0.add(AppConfig.closeUndoUiDuration + const Duration(seconds: 1)),
    );
    expect(left, Duration.zero);
  });

  test('shouldOfferBackgroundUndo — только недавнее автозакрытие', () {
    final recent = _point(
      completedAt: t0,
      status: DeliveryPoint.statusCompleted,
    );
    expect(
      shouldOfferBackgroundUndo(point: recent, now: t0.add(const Duration(seconds: 5))),
      isTrue,
    );
    expect(
      shouldOfferBackgroundUndo(
        point: recent,
        now: t0.add(AppConfig.closeUndoUiDuration + const Duration(seconds: 1)),
      ),
      isFalse,
    );
  });
}
