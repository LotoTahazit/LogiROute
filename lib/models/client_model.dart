class ClientModel {
  final String id;
  final String clientNumber; // 6-digit client number
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? contactPerson;
  final String?
      vatId; // ח.פ לקוח — VAT ID (опционально пока, обязательно при выходе на рынок)
  final String companyId; // ID компании

  ClientModel({
    required this.id,
    required this.clientNumber,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.contactPerson,
    this.vatId,
    required this.companyId,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      clientNumber: map['clientNumber'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      phone: map['phone'],
      contactPerson: map['contactPerson'],
      vatId: map['vatId'],
      companyId: map['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientNumber': clientNumber,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (vatId != null && vatId!.isNotEmpty) 'vatId': vatId,
      'companyId': companyId,
    };
  }
}
