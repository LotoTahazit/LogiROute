class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? companyId;
  final int? palletCapacity;
  final double? truckWeight; // Тоннаж грузовика в тоннах
  final String? vehicleNumber; // Номер машины (только для водителей)

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.companyId,
    this.palletCapacity,
    this.truckWeight,
    this.vehicleNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'driver',
      companyId: map['companyId'],
      palletCapacity: map['palletCapacity'] is String
          ? int.tryParse(map['palletCapacity'])
          : map['palletCapacity'],
      truckWeight: map['truckWeight'] is String
          ? double.tryParse(map['truckWeight'])
          : (map['truckWeight'] as num?)?.toDouble(),
      vehicleNumber: map['vehicleNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      if (companyId != null) 'companyId': companyId,
      if (palletCapacity != null) 'palletCapacity': palletCapacity,
      if (truckWeight != null) 'truckWeight': truckWeight,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
    };
  }

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isDispatcher => role == 'dispatcher';
  bool get isDriver => role == 'driver';
  bool get isSuperAdmin => role == 'super_admin';
}
