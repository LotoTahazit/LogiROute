import 'package:flutter/material.dart';
import '../models/shift_schedule_config.dart';
import '../services/firestore_paths.dart';
import '../l10n/app_localizations.dart';
import 'holidays_screen.dart';

/// Редактирование `companies/{companyId}/settings/shifts` (без Firebase Console).
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
  bool _loading = true;
  bool _saving = false;

  /// תצוגה: א׳→…→ש׳ (ראשון ראשון, שבת אחרונה). ערכי אחסון — עדיין `DateTime.weekday` (1=שני … 7=ראשון).
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
      if (mounted) {
        setState(() {
          _workingDays = List<int>.from(cfg.workingDays)..sort();
          _startHour = cfg.startHour;
          _endHour = cfg.endHour;
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
                  // Кнопка перехода на экран нерабочих дней
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
