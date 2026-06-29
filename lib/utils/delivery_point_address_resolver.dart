import '../models/delivery_point.dart';

/// Источник координат/адреса для навигации и карты.
enum DeliveryAddressSource {
  deliveryAddressOverrideCoordinates,
  pointCoordinates,
  deliveryAddressOverrideText,
  clientAddress,
}

/// Результат единого правила адреса точки доставки.
class ResolvedDeliveryPointAddress {
  final String clientAddress;
  final String displayAddress;
  final String? deliveryAddressOverride;
  final double? navLat;
  final double? navLng;
  final DeliveryAddressSource source;
  final bool hasOverride;
  final bool overrideMissingCoordinates;

  const ResolvedDeliveryPointAddress({
    required this.clientAddress,
    required this.displayAddress,
    this.deliveryAddressOverride,
    this.navLat,
    this.navLng,
    required this.source,
    required this.hasOverride,
    this.overrideMissingCoordinates = false,
  });
}

ResolvedDeliveryPointAddress resolveDeliveryPointAddress(DeliveryPoint point) {
  final clientAddress = point.address.trim();
  final override = point.deliveryAddressOverride?.trim();
  final hasOverride = override != null && override.isNotEmpty;

  if (hasOverride) {
    final oLat = point.deliveryAddressOverrideLat;
    final oLng = point.deliveryAddressOverrideLng;
    if (oLat != null &&
        oLng != null &&
        DeliveryPoint.isValidCoordinates(oLat, oLng)) {
      return ResolvedDeliveryPointAddress(
        clientAddress: clientAddress,
        displayAddress: override,
        deliveryAddressOverride: override,
        navLat: oLat,
        navLng: oLng,
        source: DeliveryAddressSource.deliveryAddressOverrideCoordinates,
        hasOverride: true,
      );
    }
    if (DeliveryPoint.isValidCoordinates(point.latitude, point.longitude)) {
      return ResolvedDeliveryPointAddress(
        clientAddress: clientAddress,
        displayAddress: override,
        deliveryAddressOverride: override,
        navLat: point.latitude,
        navLng: point.longitude,
        source: DeliveryAddressSource.pointCoordinates,
        hasOverride: true,
        overrideMissingCoordinates: oLat == null && oLng == null,
      );
    }
    return ResolvedDeliveryPointAddress(
      clientAddress: clientAddress,
      displayAddress: override,
      deliveryAddressOverride: override,
      source: DeliveryAddressSource.deliveryAddressOverrideText,
      hasOverride: true,
      overrideMissingCoordinates: true,
    );
  }

  if (DeliveryPoint.isValidCoordinates(point.latitude, point.longitude)) {
    return ResolvedDeliveryPointAddress(
      clientAddress: clientAddress,
      displayAddress: clientAddress,
      navLat: point.latitude,
      navLng: point.longitude,
      source: DeliveryAddressSource.pointCoordinates,
      hasOverride: false,
    );
  }

  return ResolvedDeliveryPointAddress(
    clientAddress: clientAddress,
    displayAddress: clientAddress,
    source: DeliveryAddressSource.clientAddress,
    hasOverride: false,
    overrideMissingCoordinates: clientAddress.isEmpty,
  );
}

String deliveryAddressSourceKey(DeliveryAddressSource source) {
  switch (source) {
    case DeliveryAddressSource.deliveryAddressOverrideCoordinates:
      return 'deliveryAddressOverrideCoordinates';
    case DeliveryAddressSource.pointCoordinates:
      return 'pointCoordinates';
    case DeliveryAddressSource.deliveryAddressOverrideText:
      return 'deliveryAddressOverrideText';
    case DeliveryAddressSource.clientAddress:
      return 'clientAddress';
  }
}

/// Импорт: адрес строки ≠ адрес клиента → override, client.address не трогаем.
({String pointAddress, String? deliveryAddressOverride}) resolveImportPointAddresses({
  required String importedAddress,
  required String clientAddress,
}) {
  final rowAddr = importedAddress.trim();
  final clientAddr = clientAddress.trim();
  if (rowAddr.isNotEmpty && clientAddr.isNotEmpty && rowAddr != clientAddr) {
    return (pointAddress: clientAddr, deliveryAddressOverride: rowAddr);
  }
  return (
    pointAddress: clientAddr.isNotEmpty ? clientAddr : rowAddr,
    deliveryAddressOverride: null,
  );
}
