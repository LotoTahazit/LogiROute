/// Аудит смены адреса доставки (override) у точки.
String? normalizeDeliveryAddressOverride(String? value) {
  final t = value?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

/// Эффективный адрес доставки: override или адрес клиента/точки.
String effectiveDeliveryAddress({
  required String clientAddress,
  String? deliveryAddressOverride,
}) {
  return normalizeDeliveryAddressOverride(deliveryAddressOverride) ??
      clientAddress.trim();
}

/// null — override не менялся.
({String oldAddress, String newAddress})? deliveryAddressOverrideChange({
  required String clientAddress,
  String? oldOverride,
  String? newOverride,
}) {
  final oldO = normalizeDeliveryAddressOverride(oldOverride);
  final newO = normalizeDeliveryAddressOverride(newOverride);
  if (oldO == newO) return null;
  return (
    oldAddress: effectiveDeliveryAddress(
      clientAddress: clientAddress,
      deliveryAddressOverride: oldO,
    ),
    newAddress: effectiveDeliveryAddress(
      clientAddress: clientAddress,
      deliveryAddressOverride: newO,
    ),
  );
}
