import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../services/firestore_paths.dart';
import '../../theme/app_theme.dart';

enum _AnalyticsPeriodPreset { today, thisMonth, last3Months, custom }

class _AnalyticsFetch {
  final Map<String, dynamic> data;
  final bool truncated;
  const _AnalyticsFetch({required this.data, this.truncated = false});
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _kPageSize = 500;

  _AnalyticsPeriodPreset _preset = _AnalyticsPeriodPreset.thisMonth;
  DateTimeRange? _customRange;
  int _queryLimit = _kPageSize;

  DateTimeRange _effectiveRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    switch (_preset) {
      case _AnalyticsPeriodPreset.today:
        return DateTimeRange(start: todayStart, end: todayEnd);
      case _AnalyticsPeriodPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: monthEnd,
        );
      case _AnalyticsPeriodPreset.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: monthEnd,
        );
      case _AnalyticsPeriodPreset.custom:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: monthEnd,
            );
    }
  }

  Timestamp _tsStart(DateTime d) =>
      Timestamp.fromDate(DateTime(d.year, d.month, d.day));

  Timestamp _tsEnd(DateTime d) => Timestamp.fromDate(
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999));

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDateRange: _effectiveRange(),
    );
    if (range == null || !mounted) return;
    setState(() {
      _preset = _AnalyticsPeriodPreset.custom;
      _customRange = range;
      _queryLimit = _kPageSize;
    });
  }

  void _setPreset(_AnalyticsPeriodPreset preset) {
    setState(() {
      _preset = preset;
      _queryLimit = _kPageSize;
    });
  }

  Future<_AnalyticsFetch> _getAnalytics(String companyId) async {
    final range = _effectiveRange();
    final snapshot = await FirestorePaths.deliveryPointsOf(companyId)
        .where('createdAt', isGreaterThanOrEqualTo: _tsStart(range.start))
        .where('createdAt', isLessThanOrEqualTo: _tsEnd(range.end))
        .orderBy('createdAt', descending: true)
        .limit(_queryLimit)
        .get();

    final points = snapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();

    final completed = points
        .where((p) => p.status == DeliveryPoint.statusCompleted)
        .length;
    final pending =
        points.where((p) => p.status == DeliveryPoint.statusPending).length;
    final inProgress = points
        .where((p) =>
            p.status == DeliveryPoint.statusAssigned ||
            p.status == DeliveryPoint.statusInProgress)
        .length;
    final cancelled = points
        .where((p) => p.status == DeliveryPoint.statusCancelled)
        .length;

    final totalPallets =
        points.fold<int>(0, (total, p) => total + p.pallets);
    final completedPallets = points
        .where((p) => p.status == DeliveryPoint.statusCompleted)
        .fold<int>(0, (total, p) => total + p.pallets);

    final activeDriverIds = points
        .where((p) =>
            p.driverId != null &&
            (p.status == DeliveryPoint.statusAssigned ||
                p.status == DeliveryPoint.statusInProgress))
        .map((p) => p.driverId)
        .toSet();

    final completionRate =
        points.isEmpty ? 0.0 : (completed / points.length * 100);

    return _AnalyticsFetch(
      truncated: snapshot.docs.length >= _queryLimit,
      data: {
        'totalPoints': points.length,
        'completed': completed,
        'pending': pending,
        'inProgress': inProgress,
        'cancelled': cancelled,
        'totalPallets': totalPallets,
        'completedPallets': completedPallets,
        'activeRoutes': activeDriverIds.length,
        'completionRate': completionRate,
      },
    );
  }

  Widget _periodToolbar(AppLocalizations l10n, ThemeData theme) {
    final range = _effectiveRange();
    final fmt = DateFormat.yMMMd();
    final rangeLabel = '${fmt.format(range.start)} – ${fmt.format(range.end)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: theme.colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.analyticsPeriodHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<_AnalyticsPeriodPreset>(
                segments: [
                  ButtonSegment(
                    value: _AnalyticsPeriodPreset.today,
                    label: Text(l10n.analyticsPeriodToday),
                  ),
                  ButtonSegment(
                    value: _AnalyticsPeriodPreset.thisMonth,
                    label: Text(l10n.reportsPeriodThisMonth),
                  ),
                  ButtonSegment(
                    value: _AnalyticsPeriodPreset.last3Months,
                    label: Text(l10n.reportsPeriodLast3Months),
                  ),
                  ButtonSegment(
                    value: _AnalyticsPeriodPreset.custom,
                    label: Text(l10n.reportsPeriodCustom),
                  ),
                ],
                selected: {_preset},
                onSelectionChanged: (s) {
                  final p = s.first;
                  if (p == _AnalyticsPeriodPreset.custom) {
                    _pickCustomRange();
                  } else {
                    _setPreset(p);
                  }
                },
              ),
              Chip(
                avatar: const Icon(Icons.date_range, size: 16),
                label: Text(rangeLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    final range = _effectiveRange();

    return Scaffold(
      appBar: AppBar(
          backgroundColor: theme.primaryColor,
          title: Text(l10n.analytics)),
      body: companyId.isEmpty
          ? Center(child: Text(l10n.noCompanySelected))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _periodToolbar(l10n, theme),
                Expanded(
                  child: FutureBuilder<_AnalyticsFetch>(
                    key: ValueKey(
                        '$companyId-${range.start}-${range.end}-$_queryLimit'),
                    future: _getAnalytics(companyId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Center(
                            child: Text(l10n.errorLoadingData,
                                style: TextStyle(
                                    color: theme.colorScheme.error)));
                      }

                      final fetch = snapshot.data!;
                      final data = fetch.data;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (fetch.truncated)
                            Card(
                              color: theme.colorScheme.tertiaryContainer
                                  .withValues(alpha: 0.5),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  l10n.reportsTruncatedHint(_queryLimit),
                                  style: theme.textTheme.bodySmall,
                                ),
                                trailing: TextButton(
                                  onPressed: () => setState(
                                      () => _queryLimit += _kPageSize),
                                  child: Text(l10n.reportsLoadMore),
                                ),
                              ),
                            ),
                          _buildCard(
                            l10n.statusCompleted,
                            '${data['completed']}',
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildCard(
                            l10n.statusInProgress,
                            '${data['inProgress']}',
                            Colors.orange,
                            Icons.local_shipping,
                          ),
                          _buildCard(
                            l10n.statusPending,
                            '${data['pending']}',
                            Colors.blue,
                            Icons.pending,
                          ),
                          _buildCard(
                            l10n.statusCancelled,
                            '${data['cancelled']}',
                            Colors.red,
                            Icons.cancel,
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.palletStatistics,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${l10n.total}: ${data['totalPallets']}',
                                    style: TextStyle(
                                        fontSize: 16, color: AppTheme.text),
                                  ),
                                  Text(
                                    '${l10n.delivered}: ${data['completedPallets']}',
                                    style: TextStyle(
                                        fontSize: 16, color: AppTheme.text),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: data['totalPallets'] > 0
                                        ? data['completedPallets'] /
                                            data['totalPallets']
                                        : 0,
                                    backgroundColor: AppTheme.surfaceHi,
                                    valueColor: const AlwaysStoppedAnimation<
                                        Color>(Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.completionRate,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      '${data['completionRate'].toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCard(
                            l10n.activeRoutes,
                            '${data['activeRoutes']}',
                            Colors.purple,
                            Icons.route,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(String title, String value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
