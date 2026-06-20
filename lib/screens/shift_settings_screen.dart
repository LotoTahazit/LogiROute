import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_schedule_config.dart';
import '../services/firestore_paths.dart';
import '../services/company_settings_service.dart';
import '../l10n/app_localizations.dart';
import 'holidays_screen.dart';

/// Редактирование `companies/{companyId}/settings/shifts` + параметров маршрутизации.
class ShiftSettingsScreen extends StatefulWidget {
  const ShiftSettingsScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<ShiftSettingsScreen> createState() => _ShiftSettingsScreenState();
}

class _ShiftSettingsScreenState extends State<ShiftSettingsScreen> {
  List<int> _workingDays = [1, 2, 3, 4, 5];
  int _startHour = 6;
  int _endHour = 20;
  int _depHour = 7;
  int _depMinute = 0;
  double _avgSpeed = 30;
  int _serviceMin = 8;
  String _deliveryDayMode = 'next';
  bool _loading = true;
  bool _saving = false;

  static const List<int> _weekdayDisplayOrder = [7, 1, 2, 3, 4, 5, 6];

  static String _weekdayLabel(AppLocalizations l10n, int day) {
    switch (day) {
      case 1:
        return l10n.shiftDayMon;
      case 2:
        return l10n.shiftDayTue;
      case 3:
        return l10n.shiftDayWed;
      case 4:
        return l10n.shiftDayThu;
      case 5:
        return l10n.shiftDayFri;
      case 6:
        return l10n.shiftDaySat;
      case 7:
        return l10n.shiftDaySun;
      default:
        return '$day';
    }
  }

  String _deliveryDayLabel(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'same':
        return l10n.deliveryDaySame;
      case 'next_working':
        return l10n.deliveryDayNextWorking;
      case 'next':
      default:
        return l10n.deliveryDayNext;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.companyId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirestorePaths.companyShiftsOf(widget.companyId).get();
      final cfg = ShiftScheduleConfig.fromFirestore(snap.data());
      final cs =
          await CompanySettingsService(companyId: widget.companyId).getSettings();
      final depMin = cs?.departureMinutes ?? 7 * 60;
      if (mounted) {
        setState(() {
          _workingDays = List<int>.from(cfg.workingDays)..sort();
          _startHour = cfg.startHour;
          _endHour = cfg.endHour;
          _depHour = depMin ~/ 60;
          _depMinute = depMin % 60;
          _avgSpeed = cs?.avgSpeedKmh ?? 30;
          _serviceMin = cs?.serviceMinutes ?? 8;
          _deliveryDayMode = cs?.deliveryDayMode ?? 'next';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final l10n = AppLocalizations.of(context)!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.shiftLoadError(e.toString()))),
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (widget.companyId.isEmpty) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirestorePaths.companyShiftsOf(widget.companyId).set({
        'workingDays': _workingDays,
        'startHour': _startHour,
        'endHour': _endHour,
      }, SetOptions(merge: true));
      final depTime =
          '$_depHour:${_depMinute.toString().padLeft(2, '0')}';
      await CompanySettingsService(companyId: widget.companyId).updateSettings({
        'departureTime': depTime,
        'avgSpeedKmh': _avgSpeed,
        'serviceMinutes': _serviceMin,
        'deliveryDayMode': _deliveryDayMode,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shiftSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shiftSaveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.shiftScheduleTitle)),
        body: Center(child: Text(l10n.shiftNoCompanyId)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shiftScheduleTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.shiftWorkingDays,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._weekdayDisplayOrder.map(
                    (day) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_weekdayLabel(l10n, day)),
                      value: _workingDays.contains(day),
                      onChanged: (v) {
                        if (v == null) return;
                        if (v) {
                          if (!_workingDays.contains(day)) {
                            setState(() {
                              _workingDays = [..._workingDays, day]..sort();
                            });
                          }
                        } else {
                          setState(() {
                            _workingDays =
                                _workingDays.where((d) => d != day).toList();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.shiftStart,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_startHour),
                    initialValue: _startHour,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: List.generate(
                      24,
                      (h) => DropdownMenuItem(value: h, child: Text('$h:00')),
                    ),
                    onChanged: (v) {
                      if (v != null) setState(() => _startHour = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.shiftEnd,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_endHour),
                    initialValue: _endHour,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: List.generate(
                      24,
                      (h) => DropdownMenuItem(value: h, child: Text('$h:00')),
                    ),
                    onChanged: (v) {
                      if (v != null) setState(() => _endHour = v);
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.shiftRoutingSection,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.departureTime),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('depH$_depHour'),
                          initialValue: _depHour,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                          items: List.generate(
                            24,
                            (h) =>
                                DropdownMenuItem(value: h, child: Text('$h:00')),
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => _depHour = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('depM$_depMinute'),
                          initialValue: _depMinute,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                          items: const [0, 15, 30, 45]
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(':${m.toString().padLeft(2, '0')}'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _depMinute = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: ValueKey(_avgSpeed),
                    initialValue: _avgSpeed.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.routingAvgSpeedKmh,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n != null && n > 0) _avgSpeed = n;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: ValueKey(_serviceMin),
                    initialValue: '$_serviceMin',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.routingServiceMinutes,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) _serviceMin = n;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.routingDeliveryDayMode),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_deliveryDayMode),
                    initialValue: _deliveryDayMode,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: ['same', 'next', 'next_working']
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(_deliveryDayLabel(l10n, m)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _deliveryDayMode = v);
                    },
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            HolidaysScreen(companyId: widget.companyId),
                      ),
                    ),
                    icon: const Icon(Icons.event_busy),
                    label: Text(l10n.shiftHolidaysTitle),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.save),
                  ),
                ],
              ),
            ),
    );
  }
}
