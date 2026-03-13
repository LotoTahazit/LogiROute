import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_hierarchy.dart';

/// Статус приглашения в компанию.
enum InviteStatus {
  pending,
  accepted,
  rejected,
  expired;

  String get value => name;

  static InviteStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return InviteStatus.pending;
      case 'accepted':
        return InviteStatus.accepted;
      case 'rejected':
        return InviteStatus.rejected;
      case 'expired':
        return InviteStatus.expired;
      default:
        throw ArgumentError('Unknown invite status: $status');
    }
  }
}

/// Invite-документ: `/companies/{companyId}/invites/{inviteId}`
///
/// Приглашение пользователя в компанию по email или телефону.
class Invite {
  final String emailOrPhone;
  final AppRole role;
  final DateTime? invitedAt;
  final String invitedBy;
  final InviteStatus status;
  final DateTime? acceptedAt;
  final String? acceptedBy;

  Invite({
    required this.emailOrPhone,
    required this.role,
    this.invitedAt,
    required this.invitedBy,
    required this.status,
    this.acceptedAt,
    this.acceptedBy,
  });

  factory Invite.fromMap(Map<String, dynamic> map) {
    return Invite(
      emailOrPhone: map['emailOrPhone'] ?? '',
      role: AppRole.fromString(map['role'] ?? 'viewer'),
      invitedAt: map['invitedAt'] != null
          ? (map['invitedAt'] as Timestamp).toDate()
          : null,
      invitedBy: map['invitedBy'] ?? '',
      status: InviteStatus.fromString(map['status'] ?? 'pending'),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      acceptedBy: map['acceptedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailOrPhone': emailOrPhone,
      'role': role.value,
      'invitedAt': invitedAt != null
          ? Timestamp.fromDate(invitedAt!)
          : FieldValue.serverTimestamp(),
      'invitedBy': invitedBy,
      'status': status.value,
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (acceptedBy != null) 'acceptedBy': acceptedBy,
    };
  }
}
