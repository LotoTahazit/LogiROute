import 'onboarding_section.dart';

/// Делегирование и заметки карточки Launch Center (в setup_wizard.cardMeta).
class LaunchCardMeta {
  final String? assignedRole;
  final String? assignedUserId;
  final String? notes;

  const LaunchCardMeta({
    this.assignedRole,
    this.assignedUserId,
    this.notes,
  });

  LaunchCardMeta copyWith({
    String? assignedRole,
    String? assignedUserId,
    String? notes,
    bool clearRole = false,
    bool clearUserId = false,
  }) {
    return LaunchCardMeta(
      assignedRole: clearRole ? null : (assignedRole ?? this.assignedRole),
      assignedUserId:
          clearUserId ? null : (assignedUserId ?? this.assignedUserId),
      notes: notes ?? this.notes,
    );
  }

  factory LaunchCardMeta.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const LaunchCardMeta();
    return LaunchCardMeta(
      assignedRole: map['assignedRole'] as String?,
      assignedUserId: map['assignedUserId'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (assignedRole != null && assignedRole!.isNotEmpty)
        'assignedRole': assignedRole,
      if (assignedUserId != null && assignedUserId!.isNotEmpty)
        'assignedUserId': assignedUserId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  static Map<OnboardingSectionId, LaunchCardMeta> parseCardMeta(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null || raw.isEmpty) return {};
    final out = <OnboardingSectionId, LaunchCardMeta>{};
    for (final card in OnboardingSectionId.ordered) {
      final entry = raw[card.storageKey];
      if (entry is Map<String, dynamic>) {
        out[card] = LaunchCardMeta.fromMap(entry);
      }
    }
    return out;
  }

  static Map<String, dynamic> cardMetaToFirestore(
    Map<OnboardingSectionId, LaunchCardMeta> meta,
  ) {
    return {
      for (final e in meta.entries)
        if (e.value.toMap().isNotEmpty) e.key.storageKey: e.value.toMap(),
    };
  }
}
