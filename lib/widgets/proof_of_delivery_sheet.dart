import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/delivery_point.dart';
import '../services/proof_of_delivery_service.dart';

/// Результат PoD для сохранения в Firestore.
class ProofOfDeliveryResult {
  const ProofOfDeliveryResult({
    required this.photoUrl,
    required this.lat,
    required this.lng,
    this.distanceM,
  });

  final String photoUrl;
  final double lat;
  final double lng;
  final int? distanceM;
}

/// Bottom sheet: фото + GPS + время перед закрытием точки.
Future<ProofOfDeliveryResult?> showProofOfDeliverySheet({
  required BuildContext context,
  required DeliveryPoint point,
  required String companyId,
}) {
  return showModalBottomSheet<ProofOfDeliveryResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ProofOfDeliverySheet(
      point: point,
      companyId: companyId,
    ),
  );
}

class _ProofOfDeliverySheet extends StatefulWidget {
  const _ProofOfDeliverySheet({
    required this.point,
    required this.companyId,
  });

  final DeliveryPoint point;
  final String companyId;

  @override
  State<_ProofOfDeliverySheet> createState() => _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends State<_ProofOfDeliverySheet> {
  final _pod = ProofOfDeliveryService();
  Uint8List? _preview;
  Position? _position;
  bool _loadingGps = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGps();
  }

  Future<void> _loadGps() async {
    final pos = await _pod.getCurrentPosition();
    if (mounted) {
      setState(() {
        _position = pos;
        _loadingGps = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await _pod.pickPhotoFromCamera();
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _preview = bytes;
      _error = null;
    });
  }

  int? get _distanceM {
    final pos = _position;
    if (pos == null) return null;
    return _pod.distanceToPointM(
      driverLat: pos.latitude,
      driverLng: pos.longitude,
      pointLat: widget.point.latitude,
      pointLng: widget.point.longitude,
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_preview == null) {
      setState(() => _error = l10n.podPhotoRequired);
      return;
    }
    final pos = _position;
    if (pos == null) {
      setState(() => _error = l10n.podGpsUnavailable);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final url = await _pod.uploadPhoto(
        companyId: widget.companyId,
        pointId: widget.point.id,
        bytes: _preview!,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        ProofOfDeliveryResult(
          photoUrl: url,
          lat: pos.latitude,
          lng: pos.longitude,
          distanceM: _distanceM,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final now = DateTime.now();
    final timeStr = DateFormat.Hm().format(now);
    final dist = _distanceM;
    final maxH = mq.size.height -
        mq.viewPadding.top -
        mq.viewPadding.bottom -
        mq.viewInsets.bottom -
        32;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: mq.viewInsets.bottom + mq.viewPadding.bottom + 16,
      ),
      child: SizedBox(
        height: maxH.clamp(280.0, mq.size.height * 0.92),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.podTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.point.clientName,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.podRetentionInfo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade800),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _preview != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child:
                                    Image.memory(_preview!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Icon(Icons.photo_camera,
                                    size: 48, color: Colors.grey.shade500),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_preview == null
                          ? l10n.podTakePhoto
                          : l10n.podRetake),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: l10n.podTime,
                      value: timeStr,
                    ),
                    _InfoRow(
                      icon: Icons.location_on,
                      label: l10n.podGps,
                      value: _loadingGps
                          ? '…'
                          : _position != null
                              ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                              : l10n.podGpsUnavailable,
                    ),
                    if (dist != null)
                      _InfoRow(
                        icon: Icons.social_distance,
                        label: l10n.podDistance,
                        value: '$dist m',
                        valueColor: dist <= 150 ? Colors.green : Colors.orange,
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.podConfirm),
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
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
