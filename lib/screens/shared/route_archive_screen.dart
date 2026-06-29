import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../services/company_context.dart';
import '../../services/route_archive_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/proof_of_delivery_viewer.dart';
import '../../utils/delivery_point_address_resolver.dart';

/// Простой архив завершённых доставок: по дням, фото до 90 дней, GPS дольше.
class RouteArchiveScreen extends StatefulWidget {
  const RouteArchiveScreen({super.key});

  @override
  State<RouteArchiveScreen> createState() => _RouteArchiveScreenState();
}

class _RouteArchiveScreenState extends State<RouteArchiveScreen> {
  late RouteArchiveService _service;
  List<DeliveryPoint> _points = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service = RouteArchiveService(
      companyId: CompanyContext.of(context).effectiveCompanyId ?? '',
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final points = await _service.fetchArchivedPoints();
      if (mounted) setState(() => _points = points);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DeliveryPoint> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _points;
    return _points
        .where((p) =>
            p.clientName.toLowerCase().contains(q) ||
            (p.driverName ?? '').toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<DeliveryPoint>> get _byDate {
    final map = <String, List<DeliveryPoint>>{};
    for (final p in _filtered) {
      final when = p.completedAt ?? p.archivedAt ?? DateTime.now();
      final key = DateFormat('yyyy-MM-dd').format(when);
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = _byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeArchiveTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l10n.routeArchiveHint,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.routeArchiveSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (dates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(l10n.routeArchiveEmpty,
                            style: TextStyle(color: AppTheme.muted)),
                      ),
                    )
                  else
                    ...dates.map((dateKey) {
                      final dayPoints = _byDate[dateKey]!;
                      final dayLabel =
                          DateFormat('dd.MM.yyyy (EEEE)').format(DateTime.parse(dateKey));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          initiallyExpanded: dates.length <= 3,
                          leading: const Icon(Icons.calendar_today),
                          title: Text(dayLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(l10n.routeArchivePointsCount(
                              dayPoints.length)),
                          children: dayPoints.map(_pointTile).toList(),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  String _displayAddress(DeliveryPoint p) =>
      resolveDeliveryPointAddress(p).displayAddress;

  String? _proofGps(DeliveryPoint p) {
    if (p.podLat != null && p.podLng != null) {
      return '${p.podLat!.toStringAsFixed(5)}, ${p.podLng!.toStringAsFixed(5)}';
    }
    if (DeliveryPoint.isValidCoordinates(p.latitude, p.longitude)) {
      return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    }
    return null;
  }

  Widget _pointTile(DeliveryPoint p) {
    final l10n = AppLocalizations.of(context)!;
    final when = p.completedAt ?? p.archivedAt ?? p.podAt;
    final hasPhoto =
        p.podPhotoUrl != null && p.podPhotoUrl!.trim().isNotEmpty;
    final address = _displayAddress(p);
    final gps = _proofGps(p);
    final dateStr =
        when != null ? DateFormat('dd.MM.yyyy').format(when) : '—';
    final timeStr =
        when != null ? DateFormat.Hm().format(when) : '—';

    final lines = <String>[
      address,
      '${p.driverName ?? "—"} · $dateStr $timeStr',
      if (!hasPhoto && gps != null) '${l10n.podGps}: $gps',
      if (!hasPhoto && gps == null) l10n.routeArchiveGpsOnly,
      if (p.autoCompleted) l10n.podViewerAutoClosed,
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasPhoto ? Colors.blue.shade50 : Colors.grey.shade200,
        child: Icon(
          hasPhoto ? Icons.image : Icons.location_on,
          color: hasPhoto ? Colors.blue : Colors.grey.shade600,
          size: 22,
        ),
      ),
      title: Text(p.clientName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        lines.join('\n'),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showProofOfDeliveryViewer(context: context, point: p),
    );
  }
}
