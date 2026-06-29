import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/driver_session.dart';

class DriverSessionBlockedScreen extends StatelessWidget {
  final DriverSession? remoteSession;
  final VoidCallback onTakeover;
  final VoidCallback onLogout;

  const DriverSessionBlockedScreen({
    super.key,
    this.remoteSession,
    required this.onTakeover,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = remoteSession?.deviceLabel;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.phonelink_lock, size: 72, color: Colors.orange.shade700),
              const SizedBox(height: 24),
              Text(
                l10n.driverSessionBlockedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                label != null && label.isNotEmpty
                    ? l10n.driverSessionBlockedDevice(label)
                    : l10n.driverSessionBlockedSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onTakeover,
                child: Text(l10n.driverSessionTakeoverButton),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onLogout,
                child: Text(l10n.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverSessionLostScreen extends StatelessWidget {
  final VoidCallback onAcknowledge;

  const DriverSessionLostScreen({
    super.key,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.swap_horiz, size: 72, color: Colors.red.shade700),
              const SizedBox(height: 24),
              Text(
                l10n.driverSessionLostTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.driverSessionLostSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onAcknowledge,
                child: Text(l10n.driverSessionLostAcknowledge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
