import 'package:flutter/material.dart';

import '../utils/zone_utils.dart';
import 'logi_route_tab_bar.dart';

/// Мульти-выбор зон доставки с единым pill-стилем LogiRoute.
class ZoneSelector extends StatelessWidget {
  final List<String> selectedZones;
  final ValueChanged<List<String>> onChanged;
  final String locale;
  final String? errorText;

  const ZoneSelector({
    super.key,
    required this.selectedZones,
    required this.onChanged,
    this.locale = 'he',
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final zones = ZoneUtils.allZones;
    final selectedIndices = {
      for (var i = 0; i < zones.length; i++)
        if (selectedZones.contains(zones[i].id)) i,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LogiRoutePillToggleBar(
          labels: zones.map((z) => z.nameHe).toList(),
          selectedIndices: selectedIndices,
          onToggle: (i) {
            final updated = List<String>.from(selectedZones);
            final id = zones[i].id;
            if (updated.contains(id)) {
              updated.remove(id);
            } else {
              updated.add(id);
            }
            onChanged(updated);
          },
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
