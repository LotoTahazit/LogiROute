class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final int? palletCapacity;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.palletCapacity,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'driver',
      palletCapacity: map['palletCapacity'] is String 
          ? int.tryParse(map['palletCapacity']) 
          : map['palletCapacity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      if (palletCapacity != null) 'palletCapacity': palletCapacity,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isDispatcher => role == 'dispatcher';
  bool get isDriver => role == 'driver';
}

