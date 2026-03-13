import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_with_user.dart';
import '../models/membership.dart';

/// Репозиторий для управления участниками компании.
///
/// Работает с коллекцией `/companies/{companyId}/members/{uid}`
/// и объединяет данные с глобальными профилями из `/users/{uid}`.
///
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class MembersRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  MembersRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на коллекцию members компании.
  CollectionReference<Map<String, dynamic>> get _membersCollection =>
      _firestore.collection('companies').doc(companyId).collection('members');

  /// Ссылка на глобальную коллекцию users.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Стрим списка участников компании с данными из Global User.
  ///
  /// Для каждого membership-документа загружает соответствующий `/users/{uid}`
  /// и объединяет в [MemberWithUser]. Если глобальный профиль не найден,
  /// используются пустые значения для displayName, email, phone.
  Stream<List<MemberWithUser>> watchMembers() {
    return _membersCollection.snapshots().asyncMap((snapshot) async {
      final members = <MemberWithUser>[];

      for (final doc in snapshot.docs) {
        final uid = doc.id;
        final membership = Membership.fromMap(doc.data());

        final userDoc = await _usersCollection.doc(uid).get();
        final rawUser = userDoc.data();
        final userMap = rawUser != null
            ? Map<String, dynamic>.from(rawUser as Map)
            : <String, dynamic>{};

        members.add(
          MemberWithUser.fromUserMapAndMembership(
            uid: uid,
            userMap: userMap,
            membership: membership,
          ),
        );
      }

      return members;
    });
  }

  /// Обновляет роль участника в membership-документе и глобальном профиле.
  ///
  /// Использует batch write для атомарного обновления обоих документов:
  /// - `/companies/{companyId}/members/{uid}` — поле `role`
  /// - `/users/{uid}` — поле `role`
  Future<void> updateRole(String uid, String newRole) async {
    final batch = _firestore.batch();

    batch.update(_membersCollection.doc(uid), {
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_usersCollection.doc(uid), {
      'role': newRole,
    });

    await batch.commit();
  }

  /// Деактивирует участника, устанавливая статус `suspended`.
  ///
  /// Не удаляет документ — только обновляет поле `status`.
  Future<void> removeMember(String uid) async {
    await _membersCollection.doc(uid).update({
      'status': 'suspended',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for MembersRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
