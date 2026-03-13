import '../../../models/user_model.dart';
import 'membership.dart';
import 'role_hierarchy.dart';

/// Объединённое представление Global User + Membership.
///
/// Комбинирует данные из `/users/{uid}` и `/companies/{companyId}/members/{uid}`
/// для отображения в секции «Пользователи и роли».
class MemberWithUser {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final AppRole role;
  final MembershipStatus status;
  final DateTime? createdAt;

  MemberWithUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.createdAt,
  });

  /// Создаёт [MemberWithUser] из raw-данных Global User и [Membership].
  ///
  /// [userMap] — данные из `/users/{uid}` (может содержать `name`/`displayName`, `email`, `phone`).
  /// Если [membership] равен `null`, пользователь отображается
  /// со статусом [MembershipStatus.suspended] и ролью [AppRole.viewer].
  factory MemberWithUser.fromUserMapAndMembership({
    required String uid,
    required Map<String, dynamic> userMap,
    Membership? membership,
  }) {
    return MemberWithUser(
      uid: uid,
      displayName: (userMap['displayName'] ?? userMap['name'] ?? '') as String,
      email: (userMap['email'] ?? '') as String,
      phone: (userMap['phone'] ?? '') as String,
      role: membership?.role ?? AppRole.viewer,
      status: membership?.status ?? MembershipStatus.suspended,
      createdAt: membership?.createdAt,
    );
  }

  /// Создаёт [MemberWithUser] из [UserModel] и [Membership].
  ///
  /// Если [membership] равен `null`, пользователь отображается
  /// со статусом [MembershipStatus.suspended] и ролью [AppRole.viewer].
  factory MemberWithUser.fromUserAndMembership({
    required UserModel user,
    Membership? membership,
  }) {
    return MemberWithUser(
      uid: user.uid,
      displayName: user.name,
      email: user.email,
      phone: '',
      role: membership?.role ?? AppRole.viewer,
      status: membership?.status ?? MembershipStatus.suspended,
      createdAt: membership?.createdAt,
    );
  }
}
