import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../admin/data_retention_screen.dart';
import '../android_setup_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/notification_bell.dart';

/// AppBar водителя — минимальный набор (3 элемента).
class DriverAppBarActions extends StatelessWidget {
  final String companyId;
  final AuthService authService;

  const DriverAppBarActions({
    super.key,
    required this.companyId,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationBell(companyId: companyId),
        PopupMenuButton<String>(
          icon: const Icon(Icons.help_outline),
          tooltip: l10n.appBarGroupHelp,
          onSelected: (value) {
            if (value == 'pod') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DataRetentionScreen(podOnly: true),
                ),
              );
            } else if (value == 'android_setup') {
              showAndroidSetupSheet(context);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'pod',
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.podTitle)),
                ],
              ),
            ),
            if (!kIsWeb && Platform.isAndroid)
              PopupMenuItem(
                value: 'android_setup',
                child: Row(
                  children: [
                    const Icon(Icons.settings_suggest_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.androidSetupMenu)),
                  ],
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: l10n.logout,
          onPressed: () => authService.signOut(),
        ),
      ],
    );
  }
}
