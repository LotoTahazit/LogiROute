import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/company_remote_config.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/company_remote_config_service.dart';
import '../../services/company_remote_config_validator.dart';
import '../../theme/app_theme.dart';

/// Admin / Super-admin: редактирование Company Remote Config.
/// Firestore: companies/{companyId}/settings/remote_config
class CompanyRemoteConfigScreen extends StatefulWidget {
  final String? companyId;

  const CompanyRemoteConfigScreen({super.key, this.companyId});

  @override
  State<CompanyRemoteConfigScreen> createState() =>
      _CompanyRemoteConfigScreenState();
}

class _CompanyRemoteConfigScreenState
    extends State<CompanyRemoteConfigScreen> {
  final _service = CompanyRemoteConfigService();
  CompanyRemoteConfig? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Controllers
  late TextEditingController _radiusCtrl;
  late TextEditingController _resetRadiusCtrl;
  late TextEditingController _waitCtrl;
  late TextEditingController _undoCtrl;
  late TextEditingController _gpsStaleCtrl;
  late TextEditingController _heartbeatCtrl;
  late TextEditingController _sessionStaleCtrl;
  late TextEditingController _previewRowsCtrl;

  bool _bgAutoClose = true;
  bool _sessionLock = true;
  bool _preferWaze = true;

  String get _cid =>
      widget.companyId ??
      CompanyContext.of(context).effectiveCompanyId ??
      '';

  @override
  void initState() {
    super.initState();
    _radiusCtrl = TextEditingController();
    _resetRadiusCtrl = TextEditingController();
    _waitCtrl = TextEditingController();
    _undoCtrl = TextEditingController();
    _gpsStaleCtrl = TextEditingController();
    _heartbeatCtrl = TextEditingController();
    _sessionStaleCtrl = TextEditingController();
    _previewRowsCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cfg = await _service.get(_cid);
      _populate(cfg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(CompanyRemoteConfig cfg) {
    _config = cfg;
    _radiusCtrl.text = cfg.autoCloseRadiusMeters.toStringAsFixed(0);
    _resetRadiusCtrl.text = cfg.autoCloseResetRadiusMeters.toStringAsFixed(0);
    _waitCtrl.text = cfg.autoCloseWaitSeconds.toString();
    _undoCtrl.text = cfg.closeUndoSeconds.toString();
    _gpsStaleCtrl.text = cfg.gpsStaleMinutes.toString();
    _heartbeatCtrl.text = cfg.driverSessionHeartbeatSeconds.toString();
    _sessionStaleCtrl.text = cfg.driverSessionStaleMinutes.toString();
    _previewRowsCtrl.text = cfg.importPreviewRows.toString();
    _bgAutoClose = cfg.backgroundAutoCloseEnabled;
    _sessionLock = cfg.driverDeviceSessionLockEnabled;
    _preferWaze = cfg.navigationPreferWaze;
  }

  CompanyRemoteConfig _buildFromForm() {
    final d = CompanyRemoteConfig.defaults;
    return CompanyRemoteConfig(
      autoCloseRadiusMeters:
          double.tryParse(_radiusCtrl.text) ?? d.autoCloseRadiusMeters,
      autoCloseResetRadiusMeters:
          double.tryParse(_resetRadiusCtrl.text) ?? d.autoCloseResetRadiusMeters,
      autoCloseWaitSeconds:
          int.tryParse(_waitCtrl.text) ?? d.autoCloseWaitSeconds,
      closeUndoSeconds:
          int.tryParse(_undoCtrl.text) ?? d.closeUndoSeconds,
      gpsStaleMinutes:
          int.tryParse(_gpsStaleCtrl.text) ?? d.gpsStaleMinutes,
      driverSessionHeartbeatSeconds:
          int.tryParse(_heartbeatCtrl.text) ?? d.driverSessionHeartbeatSeconds,
      driverSessionStaleMinutes:
          int.tryParse(_sessionStaleCtrl.text) ?? d.driverSessionStaleMinutes,
      backgroundAutoCloseEnabled: _bgAutoClose,
      driverDeviceSessionLockEnabled: _sessionLock,
      navigationPreferWaze: _preferWaze,
      importPreviewRows:
          int.tryParse(_previewRowsCtrl.text) ?? d.importPreviewRows,
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    final role = auth.userModel?.role ?? '';
    final cfg = _buildFromForm();

    final err = CompanyRemoteConfigValidator.validateForSave(cfg);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_validationMessage(err, l10n))));
      return;
    }

    setState(() => _saving = true);
    final saveErr = await _service.save(
      companyId: _cid,
      config: cfg,
      uid: uid,
      role: role,
      previous: _config,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saveErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.remoteConfigSaveError(saveErr))),
      );
    } else {
      _config = cfg;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.remoteConfigSaved)));
    }
  }

  Future<void> _resetAll() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    final role = auth.userModel?.role ?? '';
    final d = CompanyRemoteConfig.defaults;
    setState(() => _saving = true);
    final err = await _service.save(
      companyId: _cid,
      config: d,
      uid: uid,
      role: role,
      previous: _config,
    );
    if (!mounted) return;
    _populate(d);
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null ? l10n.remoteConfigSaved : l10n.remoteConfigSaveError(err)),
    ));
  }

  Future<void> _resetField(String fieldKey) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    final role = auth.userModel?.role ?? '';
    await _service.resetField(
      companyId: _cid,
      fieldKey: fieldKey,
      uid: uid,
      role: role,
    );
    if (!mounted) return;
    final fresh = await _service.get(_cid);
    if (!mounted) return;
    _populate(fresh);
    setState(() {});
  }

  String _validationMessage(String key, AppLocalizations l10n) {
    return switch (key) {
      'invalid_auto_close_radius' =>
        'Auto-close radius must be ${CompanyRemoteConfigValidator.radiusMin}–${CompanyRemoteConfigValidator.radiusMax} m',
      'reset_radius_below_enter' => 'Reset radius must be ≥ auto-close radius',
      'invalid_reset_radius' =>
        'Reset radius must be ≤ ${CompanyRemoteConfigValidator.radiusMax} m',
      'invalid_auto_close_wait' =>
        'Wait must be ${CompanyRemoteConfigValidator.waitMin}–${CompanyRemoteConfigValidator.waitMax} s',
      'invalid_close_undo' =>
        'Undo must be ${CompanyRemoteConfigValidator.undoMin}–${CompanyRemoteConfigValidator.undoMax} s',
      'invalid_gps_stale' =>
        'GPS stale must be ${CompanyRemoteConfigValidator.gpsStaleMin}–${CompanyRemoteConfigValidator.gpsStaleMax} min',
      'invalid_heartbeat' =>
        'Heartbeat must be ${CompanyRemoteConfigValidator.heartbeatMin}–${CompanyRemoteConfigValidator.heartbeatMax} s',
      'invalid_session_stale' =>
        'Session stale must be ${CompanyRemoteConfigValidator.sessionStaleMin}–${CompanyRemoteConfigValidator.sessionStaleMax} min',
      'invalid_preview_rows' =>
        'Preview rows must be ${CompanyRemoteConfigValidator.previewMin}–${CompanyRemoteConfigValidator.previewMax}',
      _ => key,
    };
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _resetRadiusCtrl.dispose();
    _waitCtrl.dispose();
    _undoCtrl.dispose();
    _gpsStaleCtrl.dispose();
    _heartbeatCtrl.dispose();
    _sessionStaleCtrl.dispose();
    _previewRowsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppTheme.p;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.surface,
        title: Text(l10n.remoteConfigTitle),
        actions: [
          if (!_loading && _error == null)
            TextButton(
              onPressed: _saving ? null : _resetAll,
              child: Text(l10n.remoteConfigResetAll,
                  style: TextStyle(color: p.danger)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: p.danger)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildForm(context, l10n, p),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n, AppPalette p) {
    final d = CompanyRemoteConfig.defaults;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.remoteConfigSubtitle,
              style: TextStyle(color: p.muted, fontSize: 13)),
          const SizedBox(height: 20),

          _sectionHeader(l10n.rcSectionAutoClose, p),
          _numericField(
            label: l10n.rcAutoCloseRadius,
            desc: l10n.rcAutoCloseRadiusDesc,
            ctrl: _radiusCtrl,
            defaultVal: d.autoCloseRadiusMeters.toStringAsFixed(0),
            fieldKey: 'autoCloseRadiusMeters',
            l10n: l10n,
            p: p,
          ),
          _numericField(
            label: l10n.rcAutoCloseResetRadius,
            desc: l10n.rcAutoCloseResetRadiusDesc,
            ctrl: _resetRadiusCtrl,
            defaultVal: d.autoCloseResetRadiusMeters.toStringAsFixed(0),
            fieldKey: 'autoCloseResetRadiusMeters',
            l10n: l10n,
            p: p,
          ),
          _numericField(
            label: l10n.rcAutoCloseWait,
            desc: l10n.rcAutoCloseWaitDesc,
            ctrl: _waitCtrl,
            defaultVal: d.autoCloseWaitSeconds.toString(),
            fieldKey: 'autoCloseWaitSeconds',
            l10n: l10n,
            p: p,
          ),
          _numericField(
            label: l10n.rcCloseUndo,
            desc: l10n.rcCloseUndoDesc,
            ctrl: _undoCtrl,
            defaultVal: d.closeUndoSeconds.toString(),
            fieldKey: 'closeUndoSeconds',
            l10n: l10n,
            p: p,
          ),

          _sectionHeader(l10n.rcSectionSession, p),
          _numericField(
            label: l10n.rcGpsStale,
            desc: l10n.rcGpsStaleDesc,
            ctrl: _gpsStaleCtrl,
            defaultVal: d.gpsStaleMinutes.toString(),
            fieldKey: 'gpsStaleMinutes',
            l10n: l10n,
            p: p,
          ),
          _numericField(
            label: l10n.rcSessionHeartbeat,
            desc: l10n.rcSessionHeartbeatDesc,
            ctrl: _heartbeatCtrl,
            defaultVal: d.driverSessionHeartbeatSeconds.toString(),
            fieldKey: 'driverSessionHeartbeatSeconds',
            l10n: l10n,
            p: p,
          ),
          _numericField(
            label: l10n.rcSessionStale,
            desc: l10n.rcSessionStaleDesc,
            ctrl: _sessionStaleCtrl,
            defaultVal: d.driverSessionStaleMinutes.toString(),
            fieldKey: 'driverSessionStaleMinutes',
            l10n: l10n,
            p: p,
          ),

          _sectionHeader(l10n.rcSectionFeatures, p),
          _toggleField(
            label: l10n.rcBgAutoClose,
            desc: l10n.rcBgAutoCloseDesc,
            value: _bgAutoClose,
            onChanged: (v) => setState(() => _bgAutoClose = v),
            defaultVal: d.backgroundAutoCloseEnabled,
            fieldKey: 'backgroundAutoCloseEnabled',
            l10n: l10n,
            p: p,
          ),
          _toggleField(
            label: l10n.rcSessionLock,
            desc: l10n.rcSessionLockDesc,
            value: _sessionLock,
            onChanged: (v) => setState(() => _sessionLock = v),
            defaultVal: d.driverDeviceSessionLockEnabled,
            fieldKey: 'driverDeviceSessionLockEnabled',
            l10n: l10n,
            p: p,
          ),
          _numericField(
            label: l10n.rcImportPreviewRows,
            desc: l10n.rcImportPreviewRowsDesc,
            ctrl: _previewRowsCtrl,
            defaultVal: d.importPreviewRows.toString(),
            fieldKey: 'importPreviewRows',
            l10n: l10n,
            p: p,
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  backgroundColor: p.accent, padding: const EdgeInsets.all(14)),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l10n.save,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(title,
          style: TextStyle(
              color: p.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5)),
    );
  }

  Widget _numericField({
    required String label,
    required String desc,
    required TextEditingController ctrl,
    required String defaultVal,
    required String fieldKey,
    required AppLocalizations l10n,
    required AppPalette p,
  }) {
    return _fieldCard(
      p: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: TextStyle(color: p.muted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(l10n.remoteConfigDefault(defaultVal),
                        style: TextStyle(
                            color: p.accentSoft,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    filled: true,
                    fillColor: p.surfaceHi,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _resetField(fieldKey),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(80, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(l10n.remoteConfigResetField,
                  style: TextStyle(color: p.muted, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleField({
    required String label,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool defaultVal,
    required String fieldKey,
    required AppLocalizations l10n,
    required AppPalette p,
  }) {
    return _fieldCard(
      p: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: TextStyle(color: p.muted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(l10n.remoteConfigDefault(defaultVal.toString()),
                        style: TextStyle(
                            color: p.accentSoft,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged, activeThumbColor: p.accent),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _resetField(fieldKey),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(80, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(l10n.remoteConfigResetField,
                  style: TextStyle(color: p.muted, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldCard({required Widget child, required AppPalette p}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

/// Read-only блок для Support Console (super_admin).
class RemoteConfigReadonlyBlock extends StatelessWidget {
  final String companyId;

  const RemoteConfigReadonlyBlock({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final service = CompanyRemoteConfigService();
    final p = AppTheme.p;
    return FutureBuilder<CompanyRemoteConfig>(
      future: service.get(companyId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final cfg = snap.data ?? CompanyRemoteConfig.defaults;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Auto-close radius', '${cfg.autoCloseRadiusMeters.toStringAsFixed(0)} m', p),
            _row('Reset radius', '${cfg.autoCloseResetRadiusMeters.toStringAsFixed(0)} m', p),
            _row('Auto-close wait', '${cfg.autoCloseWaitSeconds} s', p),
            _row('GPS stale', '${cfg.gpsStaleMinutes} min', p),
            _row('Background auto-close', cfg.backgroundAutoCloseEnabled ? 'ON' : 'OFF', p),
            _row('Session lock', cfg.driverDeviceSessionLockEnabled ? 'ON' : 'OFF', p),
            _row('Import preview rows', '${cfg.importPreviewRows}', p),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: p.muted, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: p.text, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
