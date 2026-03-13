import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_hierarchy.dart';

/// Статус участника компании.
enum MembershipStatus {
  active,
  invited,
  suspended;

  String get value => name;

  static MembershipStatus fromString(String status) {
    switch (status) {
      case 'active':
        return MembershipStatus.active;
      case 'invited':
        return MembershipStatus.invited;
      case 'suspended':
        return MembershipStatus.suspended;
      default:
        throw ArgumentError('Unknown membership status: $status');
    }
  }
}

/// Membership-документ: `/companies/{companyId}/members/{uid}`
///
/// Связывает пользователя с компанией, хранит роль и статус в рамках тенанта.
class Membership {
  final AppRole role;
  final MembershipStatus status;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  Membership({
    required this.role,
    required this.status,
    this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory Membership.fromMap(Map<String, dynamic> map) {
    return Membership(
      role: AppRole.fromString(map['role'] ?? 'viewer'),
      status: MembershipStatus.fromString(map['status'] ?? 'active'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'] ?? '',
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.value,
      'status': status.value,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }
}
