import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/checkout_service.dart';

/// UI-обработка ошибок Checkout: без ложного Success, с Retry/Copy при наличии URL.
class CheckoutUiHelper {
  CheckoutUiHelper._();

  static Future<void> run({
    required BuildContext context,
    required Future<CheckoutResult> Function() checkout,
    required VoidCallback onOpened,
  }) async {
    try {
      final result = await checkout();
      if (!context.mounted) return;
      onOpened();
      debugPrint(
        'Checkout opened: provider=${result.provider} session=${result.sessionId}',
      );
    } on CheckoutOpenException catch (e, st) {
      debugPrint('CheckoutUiHelper open failed: ${e.message}');
      debugPrint('$st');
      if (!context.mounted) return;
      await _showOpenFailureDialog(
        context,
        checkoutUrl: e.checkoutUrl,
        onRetry: () => run(
          context: context,
          checkout: () async {
            await CheckoutService().openCheckoutUrl(e.checkoutUrl);
            return CheckoutResult(
              url: e.checkoutUrl,
              provider: 'unknown',
              amount: 0,
              currency: 'ILS',
            );
          },
          onOpened: onOpened,
        ),
      );
    } on CheckoutSessionException catch (e, st) {
      debugPrint('CheckoutUiHelper session failed: ${e.message}');
      debugPrint('$st');
      if (!context.mounted) return;
      _showSessionError(context, e);
    } catch (e, st) {
      debugPrint('CheckoutUiHelper unexpected error: $e');
      debugPrint('$st');
      if (!context.mounted) return;
      _showSessionError(
        context,
        CheckoutSessionException(message: e.toString(), cause: e),
      );
    }
  }

  static void _showSessionError(
    BuildContext context,
    CheckoutSessionException error,
  ) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.checkoutSessionFailed),
        backgroundColor: Colors.red,
      ),
    );
  }

  static Future<void> _showOpenFailureDialog(
    BuildContext context, {
    required String checkoutUrl,
    required Future<void> Function() onRetry,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.open_in_browser, color: Colors.orange),
        title: Text(l10n.cannotOpenPayment),
        content: Text(l10n.cannotOpenPayment),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: checkoutUrl));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.checkoutLinkCopied)),
                );
              }
            },
            child: Text(l10n.checkoutCopyLink),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onRetry();
            },
            child: Text(l10n.billingGuardRetry),
          ),
        ],
      ),
    );
  }
}
