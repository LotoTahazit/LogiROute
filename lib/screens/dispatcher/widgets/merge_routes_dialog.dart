import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/delivery_point.dart';

class MergeRoutesRequest {
  final String targetRouteId;
  final Set<String> sourceRouteIds;

  const MergeRoutesRequest({
    required this.targetRouteId,
    required this.sourceRouteIds,
  });
}

class _RouteGroup {
  final String routeId;
  final String driverId;
  final String driverName;
  final List<DeliveryPoint> points;

  _RouteGroup({
    required this.routeId,
    required this.driverId,
    required this.driverName,
    required this.points,
  });

  int get activeCount => points.where((p) {
        final s = DeliveryPoint.normalizeStatus(p.status);
        return DeliveryPoint.activeRouteStatuses.contains(s);
      }).length;

  int get doneCount => points.length - activeCount;

  String label(AppLocalizations l10n) => l10n.mergeRoutesRouteLabel(
        driverName,
        activeCount,
        doneCount,
        points.length,
      );
}

List<_RouteGroup> _eligibleGroups(List<DeliveryPoint> routes) {
  final byRoute = <String, List<DeliveryPoint>>{};
  for (final p in routes) {
    final id = p.routeId;
    if (id == null || id.isEmpty) continue;
    byRoute.putIfAbsent(id, () => []).add(p);
  }

  final byDriver = <String, List<_RouteGroup>>{};
  for (final e in byRoute.entries) {
    final pts = e.value;
    if (pts.isEmpty) continue;
    final g = _RouteGroup(
      routeId: e.key,
      driverId: pts.first.driverId ?? '',
      driverName: pts.first.driverName ?? '—',
      points: pts,
    );
    if (g.driverId.isEmpty) continue;
    byDriver.putIfAbsent(g.driverId, () => []).add(g);
  }

  final out = <_RouteGroup>[];
  for (final groups in byDriver.values) {
    if (groups.length >= 2) out.addAll(groups);
  }
  out.sort((a, b) => a.driverName.compareTo(b.driverName));
  return out;
}

Future<MergeRoutesRequest?> showMergeRoutesDialog({
  required BuildContext context,
  required List<DeliveryPoint> routes,
}) {
  final groups = _eligibleGroups(routes);
  final l10n = AppLocalizations.of(context)!;
  if (groups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mergeRoutesNoEligible)),
    );
    return Future.value(null);
  }

  return showDialog<MergeRoutesRequest>(
    context: context,
    builder: (ctx) => _MergeRoutesDialog(groups: groups),
  );
}

class _MergeRoutesDialog extends StatefulWidget {
  final List<_RouteGroup> groups;

  const _MergeRoutesDialog({required this.groups});

  @override
  State<_MergeRoutesDialog> createState() => _MergeRoutesDialogState();
}

class _MergeRoutesDialogState extends State<_MergeRoutesDialog> {
  late String _driverId;
  late String? _targetRouteId;
  late Set<String> _sourceIds;

  List<_RouteGroup> get _driverGroups =>
      widget.groups.where((g) => g.driverId == _driverId).toList();

  @override
  void initState() {
    super.initState();
    _driverId = widget.groups.first.driverId;
    _pickDefaults();
  }

  void _pickDefaults() {
    final list = _driverGroups;
    final withActive = list.where((g) => g.activeCount > 0).toList();
    final target = (withActive.isNotEmpty ? withActive : list)
        .reduce((a, b) => a.activeCount >= b.activeCount ? a : b);
    _targetRouteId = target.routeId;
    _sourceIds = list
        .where((g) => g.routeId != _targetRouteId)
        .map((g) => g.routeId)
        .toSet();
  }

  void _onDriverChanged(String? id) {
    if (id == null) return;
    setState(() {
      _driverId = id;
      _pickDefaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drivers = <String, String>{};
    for (final g in widget.groups) {
      drivers[g.driverId] = g.driverName;
    }
    final list = _driverGroups;

    return AlertDialog(
      title: Text(l10n.mergeRoutes),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.mergeRoutesHint, style: const TextStyle(fontSize: 13)),
              if (drivers.length > 1) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _driverId,
                  decoration: InputDecoration(
                    labelText: l10n.driverKvLabel,
                    isDense: true,
                  ),
                  items: drivers.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _onDriverChanged,
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.mergeRoutesTarget,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ...list.map((g) => RadioListTile<String>(
                    dense: true,
                    value: g.routeId,
                    groupValue: _targetRouteId,
                    title: Text(g.label(l10n), style: const TextStyle(fontSize: 13)),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _targetRouteId = v;
                        _sourceIds.remove(v);
                      });
                    },
                  )),
              const SizedBox(height: 8),
              Text(l10n.mergeRoutesSources,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ...list.where((g) => g.routeId != _targetRouteId).map(
                    (g) => CheckboxListTile(
                      dense: true,
                      value: _sourceIds.contains(g.routeId),
                      title: Text(g.label(l10n),
                          style: const TextStyle(fontSize: 13)),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _sourceIds.add(g.routeId);
                          } else {
                            _sourceIds.remove(g.routeId);
                          }
                        });
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_targetRouteId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.mergeRoutesPickTarget)),
              );
              return;
            }
            if (_sourceIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.mergeRoutesPickSource)),
              );
              return;
            }
            Navigator.pop(
              context,
              MergeRoutesRequest(
                targetRouteId: _targetRouteId!,
                sourceRouteIds: _sourceIds,
              ),
            );
          },
          child: Text(l10n.mergeRoutes),
        ),
      ],
    );
  }
}
