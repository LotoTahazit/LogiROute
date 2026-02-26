import 'package:flutter/material.dart';
import '../../models/audit_event.dart';
import '../../services/audit_log_service.dart';

/// מסך היסטוריית מסמך — יומן ביקורת
class AuditLogScreen extends StatelessWidget {
  final String invoiceId;
  final String companyId;
  final String invoiceTitle;

  const AuditLogScreen({
    super.key,
    required this.invoiceId,
    required this.companyId,
    required this.invoiceTitle,
  });

  @override
  Widget build(BuildContext context) {
    final auditService = AuditLogService(companyId: companyId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('היסטוריה: $invoiceTitle'),
        ),
        body: StreamBuilder<List<AuditEvent>>(
          stream: auditService.watchAuditLog(invoiceId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('שגיאה בטעינת היסטוריה: ${snapshot.error}'),
              );
            }
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return const Center(
                child:
                    Text('אין אירועים עדיין', style: TextStyle(fontSize: 16)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) =>
                  _AuditEventTile(event: events[index]),
            );
          },
        ),
      ),
    );
  }
}

class _AuditEventTile extends StatelessWidget {
  final AuditEvent event;

  const _AuditEventTile({required this.event});

  IconData get _icon {
    switch (event.eventType) {
      case AuditEventType.created:
        return Icons.add_circle_outline;
      case AuditEventType.finalized:
        return Icons.lock_outline;
      case AuditEventType.printed:
        return Icons.print;
      case AuditEventType.exported:
        return Icons.download;
      case AuditEventType.cancelled:
        return Icons.cancel_outlined;
      case AuditEventType.creditNoteCreated:
        return Icons.receipt_long;
      case AuditEventType.statusChanged:
        return Icons.swap_horiz;
      case AuditEventType.technicalUpdate:
        return Icons.settings;
    }
  }

  Color get _color {
    switch (event.eventType) {
      case AuditEventType.created:
        return Colors.green;
      case AuditEventType.finalized:
        return Colors.blue;
      case AuditEventType.printed:
        return Colors.indigo;
      case AuditEventType.exported:
        return Colors.teal;
      case AuditEventType.cancelled:
        return Colors.red;
      case AuditEventType.creditNoteCreated:
        return Colors.orange;
      case AuditEventType.statusChanged:
        return Colors.purple;
      case AuditEventType.technicalUpdate:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = event.timestamp;
    final timeStr = ts != null
        ? '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withOpacity(0.15),
          child: Icon(_icon, color: _color, size: 20),
        ),
        title: Text(
          event.localizedDescription,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${event.actorName ?? event.actorUid} • $timeStr',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: event.metadata != null && event.metadata!.isNotEmpty
            ? Tooltip(
                message: event.metadata!.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
                child: const Icon(Icons.info_outline, size: 18),
              )
            : null,
      ),
    );
  }
}
