import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/delivery_point.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';

/// Просмотр доказательства доставки (POD) для диспетчера и выше по иерархии.
Future<void> showProofOfDeliveryViewer({
  required BuildContext context,
  required DeliveryPoint point,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ProofOfDeliveryViewer(point: point),
  );
}

class _ProofOfDeliveryViewer extends StatefulWidget {
  const _ProofOfDeliveryViewer({required this.point});

  final DeliveryPoint point;

  @override
  State<_ProofOfDeliveryViewer> createState() => _ProofOfDeliveryViewerState();
}

class _ProofOfDeliveryViewerState extends State<_ProofOfDeliveryViewer> {
  bool _busy = false;

  DeliveryPoint get point => widget.point;

  String get _filename {
    final safeName = point.clientName
        .replaceAll(RegExp(r'[^\w\s-]', unicode: true), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(point.podAt ?? DateTime.now());
    return 'LogiRoute_pod_${safeName.isEmpty ? point.id : safeName}_$stamp.jpg';
  }

  Future<List<int>?> _fetchPhotoBytes() async {
    final url = point.podPhotoUrl;
    if (url == null || url.isEmpty) return null;
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) return null;
    return r.bodyBytes;
  }

  Future<void> _downloadPhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _fetchPhotoBytes();
      if (!mounted) return;
      if (bytes == null) {
        _toast(AppLocalizations.of(context)!.podViewerPhotoError);
        return;
      }
      downloadFile(bytes, _filename);
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.podViewerPhotoError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _fetchPhotoBytes();
      if (!mounted) return;
      if (bytes == null) {
        _toast(AppLocalizations.of(context)!.podViewerPhotoError);
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), mimeType: 'image/jpeg', name: _filename)],
        text: '${point.clientName} — LogiRoute',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.podViewerPhotoError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final when = point.podAt ?? point.completedAt;
    final hasPhoto = point.podPhotoUrl != null && point.podPhotoUrl!.isNotEmpty;
    final hasGps = point.podLat != null && point.podLng != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.podTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(point.clientName, style: TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 12),
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    point.podPhotoUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (ctx, err, st) => _noPhotoBox(
                      l10n.podViewerPhotoError,
                      Icons.broken_image_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (kIsWeb)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _downloadPhoto,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download, size: 20),
                          label: Text(l10n.download),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _sharePhoto,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.share, size: 20),
                          label: Text(l10n.podSharePhoto),
                        ),
                      ),
                  ],
                ),
              ] else
                _noPhotoBox(l10n.podViewerNoPhoto, Icons.no_photography_outlined),
              const SizedBox(height: 12),
              if (when != null)
                _InfoRow(
                  icon: Icons.access_time,
                  label: l10n.podTime,
                  value: DateFormat('dd.MM.yyyy HH:mm').format(when),
                ),
              if (hasGps)
                _InfoRow(
                  icon: Icons.location_on,
                  label: l10n.podGps,
                  value:
                      '${point.podLat!.toStringAsFixed(5)}, ${point.podLng!.toStringAsFixed(5)}',
                ),
              if (point.podDistanceM != null)
                _InfoRow(
                  icon: Icons.social_distance,
                  label: l10n.podDistance,
                  value: '${point.podDistanceM} m',
                  valueColor:
                      point.podDistanceM! <= 150 ? Colors.green : Colors.orange,
                ),
              if (point.autoCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.podViewerAutoClosed,
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noPhotoBox(String message, IconData icon) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
