import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/checkout_service.dart';
import 'checkout_ui_helper.dart';

/// Support / Upgrade actions для billing и blocked screens.
class BillingSupportActions {
  BillingSupportActions._();

  static Future<void> showSupportDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final email = AppConfig.supportEmail.trim();
    final phone = AppConfig.supportPhone.trim();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.support_agent),
        title: Text(l10n.billingSupportDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billingSupportDialogBody),
            const SizedBox(height: 12),
            if (email.isNotEmpty)
              SelectableText(
                email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(phone),
            ],
          ],
        ),
        actions: [
          if (email.isNotEmpty)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: email));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.billingSupportEmailCopied)),
                  );
                }
              },
              child: Text(l10n.billingSupportCopyEmail),
            ),
          if (email.isNotEmpty)
            FilledButton(
              onPressed: () => _openEmail(ctx, email),
              child: Text(l10n.billingSupportOpenEmail),
            ),
          if (phone.isNotEmpty)
            TextButton(
              onPressed: () => _openPhone(ctx, phone),
              child: Text(l10n.billingSupportCall),
            ),
        ],
      ),
    );
  }

  static Future<void> startUpgradeCheckout(
    BuildContext context, {
    required String companyId,
  }) async {
    if (companyId.isEmpty) {
      debugPrint('❌ [Billing] Upgrade checkout: empty companyId');
      _showPayUnavailable(context);
      return;
    }
    await CheckoutUiHelper.run(
      context: context,
      checkout: () => CheckoutService().createAndOpen(
        companyId: companyId,
        userId: FirebaseAuth.instance.currentUser?.uid,
      ),
      onOpened: () {
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingGuardCheckoutOpened),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  static void _showPayUnavailable(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.billingSupportPayUnavailable),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static Future<void> _openEmail(BuildContext context, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('LogiRoute Support')}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        await Clipboard.setData(ClipboardData(text: email));
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.billingSupportEmailCopied)),
        );
      }
    } catch (e, st) {
      debugPrint('❌ [Billing] open email failed: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _openPhone(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e, st) {
      debugPrint('❌ [Billing] open phone failed: $e');
      debugPrint('$st');
    }
  }
}
