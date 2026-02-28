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
    return IntegrityVerifyResult(
      ok: data['ok'] == true,
      companyId: data['companyId'] as String? ?? companyId,
      counterKey: data['counterKey'] as String? ?? counterKey,
      from: (data['range']?['from'] as num?)?.toInt() ?? from,
      to: (data['range']?['to'] as num?)?.toInt() ?? to,
      checked: (data['checked'] as num?)?.toInt() ?? 0,
      firstBrokenAt: (data['firstBrokenAt'] as num?)?.toInt(),
      reason: data['reason'] as String?,
      lastHash: data['last']?['hash'] as String?,
    );
  }
}

class IntegrityVerifyResult {
  final bool ok;
  final String companyId;
  final String counterKey;
  final int from;
  final int to;
  final int checked;
  final int? firstBrokenAt;
  final String? reason;
  final String? lastHash;

  IntegrityVerifyResult({
    required this.ok,
    required this.companyId,
    required this.counterKey,
    required this.from,
    required this.to,
    required this.checked,
    this.firstBrokenAt,
    this.reason,
    this.lastHash,
  });

  String get summary {
    if (ok) return '✅ תקין — $checked מסמכים נבדקו';
    return '❌ שגיאה במסמך #$firstBrokenAt: $reason';
  }
}
