import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../services/route_service.dart';

/// История маршрутов водителя — его завершённые точки, сгруппированные по
/// маршрутам. Закрывает пробел: завершённый маршрут (и 2-й маршрут того же дня)
/// уходит из активного дашборда, и водителю негде его посмотреть.
class DriverRouteHistoryScreen extends StatefulWidget {
  final String companyId;
  final String driverId;

  const DriverRouteHistoryScreen({
    super.key,
    required this.companyId,
    required this.driverId,
  });

  @override
  State<DriverRouteHistoryScreen> createState() =>
      _DriverRouteHistoryScreenState();
}

class _DriverRouteHistoryScreenState extends State<DriverRouteHistoryScreen> {
  late final RouteService _routeService;
  late Future<List<_RouteGroup>> _future;

  @override
  void initState() {
    super.initState();
    _routeService = RouteService(companyId: widget.companyId);
    _future = _load();
  }

  Future<List<_RouteGroup>> _load() async {
    final points =
        await _routeService.getDriverCompletedPoints(widget.driverId);
    return _groupByRoute(points);
  }

  DateTime _pointTime(DeliveryPoint p) =>
      p.completedAt ?? p.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  List<_RouteGroup> _groupByRoute(List<DeliveryPoint> points) {
    final map = <String, List<DeliveryPoint>>{};
    for (final p in points) {
      final key = (p.routeId != null && p.routeId!.isNotEmpty)
          ? p.routeId!
          : 'd_${DateFormat('yyyyMMdd').format(_pointTime(p))}';
      map.putIfAbsent(key, () => []).add(p);
    }
    final groups = map.values.map((list) {
      list.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
      final latest = list
          .map(_pointTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return _RouteGroup(points: list, date: latest);
    }).toList();
    // Свежие маршруты — сверху.
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          final f = _load();
          setState(() => _future = f);
          await f;
        },
        child: FutureBuilder<List<_RouteGroup>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text('${snapshot.error}')),
              ]);
            }
            final groups = snapshot.data ?? const [];
            if (groups.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 140),
                Icon(Icons.history,
                    size: 56, color: Theme.of(context).disabledColor),
                const SizedBox(height: 12),
                Center(child: Text(l10n.routeHistoryEmpty)),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              itemBuilder: (_, i) => _RouteCard(group: groups[i]),
            );
          },
        ),
      ),
    );
  }
}

class _RouteGroup {
  final List<DeliveryPoint> points;
  final DateTime date;
  const _RouteGroup({required this.points, required this.date});
}

class _RouteCard extends StatelessWidget {
  final _RouteGroup group;
  const _RouteCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(group.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(Icons.local_shipping_outlined,
            color: theme.colorScheme.primary),
        title: Text(dateStr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${TimeOfDay.fromDateTime(group.date).format(context)} · ${group.points.length}'),
        children: group.points.map((p) {
          final t = p.completedAt ?? p.updatedAt;
          final timeStr = t != null
              ? TimeOfDay.fromDateTime(t).format(context)
              : '';
          return ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle,
                color: Colors.green, size: 20),
            title: Text(p.clientName),
            subtitle: p.address.isNotEmpty ? Text(p.address) : null,
            trailing: timeStr.isNotEmpty
                ? Text(timeStr, style: theme.textTheme.bodySmall)
                : null,
          );
        }).toList(),
      ),
    );
  }
}
