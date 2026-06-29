import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/correlation/correlation_context.dart';
import '../models/usage_event.dart';

/// Сервис hosted checkout: CF createCheckoutSession → открытие URL в браузере.
/// Источник правды — webhook. Сервис только создаёт сессию и открывает страницу.
class CheckoutService {
  static final CheckoutService _instance = CheckoutService._();
  factory CheckoutService() => _instance;
  CheckoutService._();

  final _functions = FirebaseFunctions.instance;

  /// Создать checkout session без открытия браузера.
  Future<CheckoutResult> createSession({
    required String companyId,
    int months = 1,
    String? userId,
    String? correlationId,
  }) async {
    final trace = correlationIf(
      operation: CorrelatedOperation.stripeCheckout,
      companyId: companyId,
      userId: userId ?? '',
      correlationId: correlationId,
    );
    trace?.log('createCheckoutSession months=$months');

    final callable = _functions.httpsCallable(
      'createCheckoutSession',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'companyId': companyId,
        'months': months,
        if (trace != null) ...trace.cfPayload(),
      });
      trace?.log('session created');
      unawaited(trace?.trackPilot(
        UsageEventName.checkoutStarted,
        metadata: {'months': months},
      ));
      return _parseSessionResponse(result.data, companyId: companyId);
    } on FirebaseFunctionsException catch (e, st) {
      trace?.logError(e, st);
      debugPrint(
        'CheckoutService.createSession FirebaseFunctionsException '
        '[${e.code}]: ${e.message}',
      );
      debugPrint('$st');
      throw CheckoutSessionException(
        message: e.message ?? e.code,
        code: e.code,
        cause: e,
        correlation: trace?.toErrorMap(message: e.message, cause: e),
      );
    } on TimeoutException catch (e, st) {
      trace?.logError(e, st);
      debugPrint('CheckoutService.createSession timeout: $e');
      debugPrint('$st');
      throw CheckoutSessionException(
        message: 'Checkout session timeout',
        code: 'timeout',
        cause: e,
        correlation: trace?.toErrorMap(cause: e),
      );
    } catch (e, st) {
      trace?.logError(e, st);
      debugPrint('CheckoutService.createSession error: $e');
      debugPrint('$st');
      throw CheckoutSessionException(
        message: e.toString(),
        cause: e,
        correlation: trace?.toErrorMap(cause: e),
      );
    }
  }

  /// Открыть уже полученный checkout URL. Бросает [CheckoutOpenException] при неудаче.
  Future<void> openCheckoutUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw CheckoutOpenException(
        checkoutUrl: url,
        reason: CheckoutOpenFailureReason.invalidUrl,
        message: 'Empty checkout URL',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw CheckoutOpenException(
        checkoutUrl: trimmed,
        reason: CheckoutOpenFailureReason.invalidUrl,
        message: 'Invalid checkout URL: $trimmed',
      );
    }
    if (uri.scheme != 'https') {
      throw CheckoutOpenException(
        checkoutUrl: trimmed,
        reason: CheckoutOpenFailureReason.invalidUrl,
        message: 'Checkout URL must use HTTPS',
      );
    }

    bool canLaunch;
    try {
      canLaunch = await canLaunchUrl(uri);
    } catch (e, st) {
      debugPrint('CheckoutService.openCheckoutUrl canLaunchUrl error: $e');
      debugPrint('$st');
      throw CheckoutOpenException(
        checkoutUrl: trimmed,
        reason: CheckoutOpenFailureReason.networkError,
        message: 'canLaunchUrl failed: $e',
        cause: e,
      );
    }

    if (!canLaunch) {
      debugPrint(
        'CheckoutService.openCheckoutUrl: canLaunchUrl returned false for $trimmed',
      );
      throw CheckoutOpenException(
        checkoutUrl: trimmed,
        reason: CheckoutOpenFailureReason.cannotLaunch,
        message: 'canLaunchUrl returned false',
      );
    }

    bool launched;
    try {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e, st) {
      debugPrint('CheckoutService.openCheckoutUrl launchUrl error: $e');
      debugPrint('$st');
      throw CheckoutOpenException(
        checkoutUrl: trimmed,
        reason: CheckoutOpenFailureReason.launchFailed,
        message: 'launchUrl threw: $e',
        cause: e,
      );
    }

    if (!launched) {
      debugPrint(
        'CheckoutService.openCheckoutUrl: launchUrl returned false (popup blocked?)',
      );
      throw CheckoutOpenException(
        checkoutUrl: trimmed,
        reason: CheckoutOpenFailureReason.launchFailed,
        message: 'launchUrl returned false',
      );
    }
  }

  /// Создать session и открыть payment page. Успех только если URL реально открыт.
  Future<CheckoutResult> createAndOpen({
    required String companyId,
    int months = 1,
    String? userId,
    String? correlationId,
  }) async {
    final session = await createSession(
      companyId: companyId,
      months: months,
      userId: userId,
      correlationId: correlationId,
    );
    await openCheckoutUrl(session.url);
    return session;
  }

  CheckoutResult _parseSessionResponse(
    Map<String, dynamic>? data, {
    required String companyId,
  }) {
    if (data == null) {
      throw CheckoutSessionException(
        message: 'Empty response from createCheckoutSession',
      );
    }

    final url = data['url'] as String?;
    if (url == null || url.trim().isEmpty) {
      debugPrint(
        'CheckoutService: no checkout URL for company $companyId, data=$data',
      );
      throw CheckoutSessionException(
        message: 'No checkout URL returned',
      );
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw CheckoutSessionException(
        message: 'Invalid checkout URL from server: $url',
      );
    }

    return CheckoutResult(
      url: url.trim(),
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

enum CheckoutOpenFailureReason {
  invalidUrl,
  cannotLaunch,
  launchFailed,
  networkError,
}

/// CF createCheckoutSession завершилась ошибкой — URL не получен.
class CheckoutSessionException implements Exception {
  final String message;
  final String? code;
  final Object? cause;
  final Map<String, dynamic>? correlation;

  CheckoutSessionException({
    required this.message,
    this.code,
    this.cause,
    this.correlation,
  });

  @override
  String toString() {
    if (correlation != null) {
      return '$message | correlation=$correlation';
    }
    return message;
  }
}

/// URL получен, но открыть страницу оплаты не удалось.
class CheckoutOpenException implements Exception {
  final String checkoutUrl;
  final CheckoutOpenFailureReason reason;
  final String message;
  final Object? cause;

  CheckoutOpenException({
    required this.checkoutUrl,
    required this.reason,
    required this.message,
    this.cause,
  });

  @override
  String toString() => message;
}
