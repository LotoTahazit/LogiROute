import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Вендорские экраны «Автозапуск» (best-effort). Перебираем по очереди:
/// запускаем первый, который реально открывается; иначе — настройки приложения.
const _autostartActivities = <List<String>>[
  // [package, fully-qualified activity]
  ['com.miui.securitycenter',
      'com.miui.permcenter.autostart.AutoStartManagementActivity'], // Xiaomi/MIUI
  ['com.letv.android.letvsafe',
      'com.letv.android.letvsafe.AutobootManageActivity'], // Letv
  ['com.huawei.systemmanager',
      'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'], // Huawei (new)
  ['com.huawei.systemmanager',
      'com.huawei.systemmanager.optimize.process.ProtectActivity'], // Huawei (old)
  ['com.coloros.safecenter',
      'com.coloros.safecenter.permission.startup.StartupAppListActivity'], // Oppo/ColorOS
  ['com.coloros.safecenter',
      'com.coloros.safecenter.startupapp.StartupAppListActivity'], // Oppo (alt)
  ['com.oppo.safe',
      'com.oppo.safe.permission.startup.StartupAppListActivity'], // Oppo (old)
  ['com.vivo.permissionmanager',
      'com.vivo.permissionmanager.activity.BgStartUpManagerActivity'], // Vivo
  ['com.iqoo.secure',
      'com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity'], // Vivo/iQOO
  ['com.asus.mobilemanager',
      'com.asus.mobilemanager.entry.FunctionActivity'], // Asus
];

/// Памятка водителю (Android): включить «Геолокация — Всегда», «Батарея без
/// ограничений» и «Автозапуск», чтобы смена и GPS работали в фоне (когда
/// приложение свёрнуто / экран заблокирован). Особенно важно на Xiaomi/MIUI.
Future<void> showAndroidSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AndroidSetupSheet(),
  );
}

class _AndroidSetupSheet extends StatefulWidget {
  const _AndroidSetupSheet();

  @override
  State<_AndroidSetupSheet> createState() => _AndroidSetupSheetState();
}

class _AndroidSetupSheetState extends State<_AndroidSetupSheet>
    with WidgetsBindingObserver {
  bool _locationAlways = false;
  bool _batteryOk = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Вернулись из системных настроек — перечитываем статусы.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final loc = await Permission.locationAlways.status;
    final bat = await Permission.ignoreBatteryOptimizations.status;
    if (!mounted) return;
    setState(() {
      _locationAlways = loc.isGranted;
      _batteryOk = bat.isGranted;
      _loading = false;
    });
  }

  Future<void> _enableLocation() async {
    final res = await Permission.locationAlways.request();
    // На Android 11+ фоновое «Всегда» нельзя выдать диалогом — уводим в настройки.
    if (!res.isGranted) await openAppSettings();
    await _refresh();
  }

  Future<void> _enableBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _refresh();
  }

  Future<void> _openAutostart() async {
    // Автозапуск — вендор-специфичный экран (нет общего API). Пробуем открыть
    // нужный напрямую (Xiaomi/Huawei/Oppo/Vivo/Asus); если ни один не
    // открылся — фолбэк на «О приложении».
    if (!kIsWeb && Platform.isAndroid) {
      for (final a in _autostartActivities) {
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: a[0],
            componentName: a[1],
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
          return; // открылось — выходим
        } catch (_) {
          // нет такого экрана на этом телефоне — пробуем следующий
        }
      }
    }
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.androidSetupTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.androidSetupIntro,
              style: TextStyle(color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _StepCard(
              icon: Icons.location_on,
              title: l10n.androidSetupLocationTitle,
              desc: l10n.androidSetupLocationDesc,
              done: _locationAlways,
              loading: _loading,
              actionLabel: l10n.androidSetupEnable,
              onAction: _enableLocation,
            ),
            _StepCard(
              icon: Icons.battery_charging_full,
              title: l10n.androidSetupBatteryTitle,
              desc: l10n.androidSetupBatteryDesc,
              done: _batteryOk,
              loading: _loading,
              actionLabel: l10n.androidSetupEnable,
              onAction: _enableBattery,
            ),
            _StepCard(
              icon: Icons.restart_alt,
              title: l10n.androidSetupAutostartTitle,
              desc: l10n.androidSetupAutostartDesc,
              done: null, // программно не проверяется
              loading: false,
              actionLabel: l10n.bgLocationOpenSettings,
              onAction: _openAutostart,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.androidSetupDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.done,
    required this.loading,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool? done; // null = статус не проверяется (ручная настройка)
  final bool loading;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget statusIcon;
    if (loading) {
      statusIcon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (done == true) {
      statusIcon = const Icon(Icons.check_circle, color: Colors.green);
    } else if (done == false) {
      statusIcon = Icon(Icons.error_outline, color: AppTheme.warning);
    } else {
      statusIcon = Icon(Icons.info_outline, color: AppTheme.muted);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.accentSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                statusIcon,
              ],
            ),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(color: AppTheme.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: done == true
                  ? Text(
                      l10n.androidSetupGranted,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : OutlinedButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
