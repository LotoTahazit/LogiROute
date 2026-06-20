import 'package:cloud_functions/cloud_functions.dart';

/// Обёртка для callable verifyIntegrityChain.
/// Проверяет целостность криптоцепочки на сервере.
class IntegrityVerifyService {
  static final IntegrityVerifyService _instance = IntegrityVerifyService._();
  factory IntegrityVerifyService() => _instance;
  IntegrityVerifyService._();

  final _functions = FirebaseFunctions.instance;

  /// Проверить цепочку [counterKey] в диапазоне [from]..[to].
  Future<IntegrityVerifyResult> verify({
    required String companyId,
    required String counterKey,
    required int from,
    required int to,
  }) async {
    final callable = _functions.httpsCallable(
      'verifyIntegrityChain',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      'counterKey': counterKey,
      'from': from,
      'to': to,
    });

    final data = result.data;
    final range = data['range'] as Map?;
    final legacySkipped = data['legacySkipped'] as Map?;
    return IntegrityVerifyResult(
      ok: data['ok'] == true,
      companyId: data['companyId'] as String? ?? companyId,
      counterKey: data['counterKey'] as String? ?? counterKey,
      from: (range?['from'] as num?)?.toInt() ?? from,
      to: (range?['to'] as num?)?.toInt() ?? to,
      checkedFrom: (range?['checkedFrom'] as num?)?.toInt(),
      checked: (data['checked'] as num?)?.toInt() ?? 0,
      firstBrokenAt: (data['firstBrokenAt'] as num?)?.toInt(),
      reason: data['reason'] as String?,
      lastHash: data['last']?['hash'] as String?,
      legacyOnly: data['legacyOnly'] == true,
      legacySkippedFrom: (legacySkipped?['from'] as num?)?.toInt(),
      legacySkippedTo: (legacySkipped?['to'] as num?)?.toInt(),
    );
  }
}

class IntegrityVerifyResult {
  final bool ok;
  final String companyId;
  final String counterKey;
  final int from;
  final int to;
  final int? checkedFrom;
  final int checked;
  final int? firstBrokenAt;
  final String? reason;
  final String? lastHash;
  final bool legacyOnly;
  final int? legacySkippedFrom;
  final int? legacySkippedTo;

  IntegrityVerifyResult({
    required this.ok,
    required this.companyId,
    required this.counterKey,
    required this.from,
    required this.to,
    this.checkedFrom,
    required this.checked,
    this.firstBrokenAt,
    this.reason,
    this.lastHash,
    this.legacyOnly = false,
    this.legacySkippedFrom,
    this.legacySkippedTo,
  });
}
