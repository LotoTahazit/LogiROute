import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firestore_paths.dart';

import '../models/invite.dart';
import '../models/role_hierarchy.dart';

/// Допустимые роли для приглашений.
///
/// Owner и super_admin не могут быть назначены через приглашения.
const allowedInviteRoles = {
  AppRole.admin,
  AppRole.dispatcher,
  AppRole.driver,
  AppRole.warehouseKeeper,
  AppRole.accountant,
  AppRole.viewer,
};

/// Репозиторий для управления приглашениями в компанию.
///
/// Работает с коллекцией `/companies/{companyId}/invites/{inviteId}`.
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class InvitesRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  InvitesRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на коллекцию invites компании.
  CollectionReference<Map<String, dynamic>> get _invitesCollection =>
      FirestorePaths(firestore: _firestore).invites(companyId);

  /// Создаёт новое приглашение в компанию.
  ///
  /// Валидация:
  /// - [Invite.emailOrPhone] не должен быть пустым
  /// - [Invite.role] должна быть из [allowedInviteRoles]
  /// - Статус автоматически устанавливается в `pending`
  /// - `invitedAt` устанавливается как server timestamp
  Future<void> createInvite(Invite data) async {
    if (data.emailOrPhone.trim().isEmpty) {
      throw ArgumentError('emailOrPhone must not be empty');
    }
    if (!allowedInviteRoles.contains(data.role)) {
      throw ArgumentError(
        'Role "${data.role.value}" is not allowed for invites. '
        'Allowed roles: ${allowedInviteRoles.map((r) => r.value).join(', ')}',
      );
    }

    final invite = Invite(
      emailOrPhone: data.emailOrPhone,
      role: data.role,
      invitedBy: data.invitedBy,
      status: InviteStatus.pending,
    );

    await _invitesCollection.add(invite.toMap());
  }

  /// Стрим списка всех приглашений компании.
  Stream<List<Invite>> watchInvites() {
    return _invitesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Invite.fromMap(doc.data())).toList();
    });
  }

  /// Одобряет приглашение — устанавливает статус `accepted` и `acceptedAt`.
  Future<void> approveInvite(String inviteId) async {
    await _invitesCollection.doc(inviteId).update({
      'status': InviteStatus.accepted.value,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Отклоняет приглашение — устанавливает статус `rejected`.
  Future<void> rejectInvite(String inviteId) async {
    await _invitesCollection.doc(inviteId).update({
      'status': InviteStatus.rejected.value,
    });
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for InvitesRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
