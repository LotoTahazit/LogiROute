import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/shift_schedule_config.dart';
import '../services/firestore_paths.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Экран управления нерабочими днями (праздники + выходные).
/// Отдельный экран с крупными карточками для удобного просмотра и редактирования.
class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  List<HolidayEntry> _holidays = [];
  bool _loading = true;
  bool _saving = false;
  bool _loadingHolidays = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirestorePaths.companyShiftsOf(widget.companyId).get();
      final cfg = ShiftScheduleConfig.fromFirestore(snap.data());
      if (mounted) {
        setState(() {
          _holidays = List<HolidayEntry>.from(cfg.holidays)
            ..sort((a, b) => a.date.compareTo(b.date));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({bool silent = false}) async {
    setState(() => _saving = true);
    try {
      final snap = await FirestorePaths.companyShiftsOf(widget.companyId).get();
      final existing = snap.data() ?? {};
      await FirestorePaths.companyShiftsOf(widget.companyId).set({
        ...existing,
        'holidays': _holidays.map((h) => h.toMap()).toList(),
      }, SetOptions(merge: true));
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shiftSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadFromHebcal() async {
    setState(() => _loadingHolidays = true);
    try {
      final years = [DateTime.now().year, DateTime.now().year + 1];
      final Map<String, Map<String, String>> fetched = {};

      for (final year in years) {
        final results = await Future.wait([
          _fetchHebcal(year, 'en'),
          _fetchHebcal(year, 'he'),
          _fetchHebcal(year, 'ru'),
        ]);
        final en = results[0], he = results[1], ru = results[2];
        for (final date in en.keys) {
          fetched[date] = {
            'en': en[date] ?? '',
            'he': he[date] ?? en[date] ?? '',
            'ru': ru[date] ?? en[date] ?? '',
          };
        }
      }

      if (fetched.isNotEmpty && mounted) {
        final newEntries = fetched.entries
            .map((e) => HolidayEntry(
                  date: e.key,
                  title: e.value['en'] ?? '',
                  titleHe: e.value['he'],
                  titleRu: e.value['ru'],
                ))
            .toList();

        setState(() {
          final existing =
              Map.fromEntries(_holidays.map((h) => MapEntry(h.date, h)));
          for (final e in newEntries) {
            existing[e.date] = e;
          }
          _holidays = existing.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        });

        await _save(silent: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .shiftHolidaysLoaded(fetched.length)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .shiftHolidaysLoadError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHolidays = false);
    }
  }

  Future<Map<String, String>> _fetchHebcal(int year, String lang) async {
    try {
      final url = Uri.parse(
        'https://www.hebcal.com/hebcal?v=1&cfg=json&year=$year'
        '&maj=on&mod=on&nx=on&i=on&geo=il&m=50&lg=$lang',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return {};
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final result = <String, String>{};
      for (final item in items) {
        final date = item['date']?.toString();
        final category = item['category']?.toString() ?? '';
        final title = item['title']?.toString() ?? '';
        if (date != null && category == 'holiday' && title.isNotEmpty) {
          result[date.substring(0, 10)] = title;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void _removeHoliday(String date) {
    setState(() {
      _holidays = _holidays.where((h) => h.date != date).toList();
    });
    _save(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shiftHolidaysTitle),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save),
              tooltip: l10n.save,
              onPressed: _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Кнопка загрузки праздников
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loadingHolidays ? null : _loadFromHebcal,
                      icon: _loadingHolidays
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.cloud_download),
                      label: Text(l10n.shiftLoadHolidays),
                    ),
                  ),
                ),
                // Счётчик
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${_holidays.length} ${l10n.shiftHolidaysTitle.toLowerCase()}',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Список
                Expanded(
                  child: _holidays.isEmpty
                      ? Center(
                          child: Text(
                            l10n.shiftNoHolidays,
                            style: TextStyle(
                                color: AppTheme.muted, fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _holidays.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final h = _holidays[index];
                            final name = h.localizedTitle(lang);
                            return _HolidayCard(
                              date: h.date,
                              name: name,
                              onDelete: () => _removeHoliday(h.date),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({
    required this.date,
    required this.name,
    required this.onDelete,
  });

  final String date;
  final String name;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Парсим дату для красивого отображения
    final parts = date.split('-');
    final dateFormatted =
        parts.length == 3 ? '${parts[2]}.${parts[1]}.${parts[0]}' : date;

    // Определяем день недели
    String? weekday;
    try {
      final dt = DateTime.parse(date);
      const days = ['', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳', 'א׳'];
      weekday = days[dt.weekday];
    } catch (_) {}

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Дата
            Container(
              width: 64,
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                  ),
                  if (weekday != null)
                    Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const VerticalDivider(width: 1, thickness: 1),
            const SizedBox(width: 12),
            // Название
            Expanded(
              child: Text(
                name.isNotEmpty ? name : date,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Удалить
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade300, size: 22),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
