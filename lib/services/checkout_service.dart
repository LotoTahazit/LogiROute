import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Сервис для создания hosted checkout сессий.
/// Вызывает Cloud Function createCheckoutSession → получает URL → открывает в браузере.
/// Источник правды — webhook. Этот сервис только генерирует ссылку.
class CheckoutService {
  static final CheckoutService _instance = CheckoutService._();
  factory CheckoutService() => _instance;
  CheckoutService._();

  final _functions = FirebaseFunctions.instance;

  /// Создать checkout session и открыть payment page.
  /// Возвращает [CheckoutResult] с URL и sessionId.
  /// Бросает исключение при ошибке.
  Future<CheckoutResult> createAndOpen({
    required String companyId,
    int months = 1,
  }) async {
    final callable = _functions.httpsCallable(
      'createCheckoutSession',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final result = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      'months': months,
    });

    final data = result.data;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No checkout URL returned');
    }

    // Open in external browser
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return CheckoutResult(
      url: url,
      sessionId: data['sessionId'] as String?,
      provider: data['provider'] as String? ?? 'unknown',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'ILS',
    );
  }
}

class CheckoutResult {
  final String url;
  final String? sessionId;
  final String provider;
  final double amount;
  final String currency;

  CheckoutResult({
    required this.url,
    this.sessionId,
    required this.provider,
    required this.amount,
    required this.currency,
  });
}
