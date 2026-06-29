import '../config/app_config.dart';
import '../models/delivery_point.dart';
/// Одно активное предложение «Отменить» после закрытия точки.
class DriverCloseUndoOffer {
  final String pointId;
  final String clientName;
  final String previousStatus;
  final bool autoCompleted;
  final DateTime offeredAt;
  final DateTime expiresAt;

  const DriverCloseUndoOffer({
    required this.pointId,
    required this.clientName,
    required this.previousStatus,
    required this.autoCompleted,
    required this.offeredAt,
    required this.expiresAt,
  });

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  bool canUndo(String? attemptPointId, DateTime now) =>
      attemptPointId == pointId && !isExpired(now);

  int remainingSeconds(DateTime now) {
    final left = expiresAt.difference(now).inSeconds;
    return left > 0 ? left : 0;
  }
}

/// Сколько ещё показывать undo после [completedAt].
Duration closeUndoRemainingUi(
  DateTime completedAt,
  DateTime now, {
  Duration maxUi = AppConfig.closeUndoUiDuration,
}) {
  final deadline = completedAt.add(maxUi);
  if (!now.isBefore(deadline)) return Duration.zero;
  return deadline.difference(now);
}

/// Новое закрытие заменяет предыдущий undo.
DriverCloseUndoOffer createCloseUndoOffer({
  required DeliveryPoint point,
  required String previousStatus,
  required bool autoCompleted,
  required DateTime now,
  Duration? uiDuration,
}) {
  final duration = uiDuration ?? AppConfig.closeUndoUiDuration;
  final prev = DeliveryPoint.normalizeStatus(previousStatus);
  final restore = prev == DeliveryPoint.statusAssigned ||
          prev == DeliveryPoint.statusInProgress
      ? prev
      : DeliveryPoint.statusInProgress;
  return DriverCloseUndoOffer(
    pointId: point.id,
    clientName: point.clientName,
    previousStatus: restore,
    autoCompleted: autoCompleted,
    offeredAt: now,
    expiresAt: now.add(duration),
  );
}

/// Можно ли предложить undo для точки из потока (фоновое автозакрытие).
bool shouldOfferBackgroundUndo({
  required DeliveryPoint point,
  required DateTime now,
  DriverCloseUndoOffer? activeOffer,
}) {
  if (activeOffer != null) return false;
  if (!point.autoCompleted) return false;
  if (DeliveryPoint.normalizeStatus(point.status) !=
      DeliveryPoint.statusCompleted) {
    return false;
  }
  final completedAt = point.completedAt;
  if (completedAt == null) return false;
  return closeUndoRemainingUi(completedAt, now) > Duration.zero;
}
