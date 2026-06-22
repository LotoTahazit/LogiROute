import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/logi_route_tab_bar.dart';
import '../../../../models/company_settings.dart';
import '../../models/print_event.dart';
import '../../models/system_event.dart';
import '../../repositories/print_events_repository.dart';
import '../../repositories/system_events_repository.dart';

/// Секция «Операции» (Ops Health) Owner Dashboard.
///
/// Отображает:
/// - Список событий печати с фильтрацией по статусу
/// - Системные события: ошибки интеграций, сбои, ретраи; красный для error/failed
/// - Статистика ретраев: количество повторных попыток, процент успешных
/// - События вебхуков: endpoint, статус ответа, время
/// - Обновление в реальном времени через Firestore snapshots
///
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6
class OpsHealthSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const OpsHealthSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<OpsHealthSection> createState() => _OpsHealthSectionState();
}

class _OpsHealthSectionState extends State<OpsHealthSection> {
  late final PrintEventsRepository _printEventsRepo;
  late final SystemEventsRepository _systemEventsRepo;

  String? _printStatusFilter;
  String? _systemStatusFilter;

  @override
  void initState() {
    super.initState();
    _printEventsRepo = PrintEventsRepository(companyId: widget.companyId);
    _systemEventsRepo = SystemEventsRepository(companyId: widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(narrow ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Retry stats — Requirement 9.4
          _buildRetryStats(context),
          const SizedBox(height: 24),
          // Print events — Requirement 9.1
          _buildPrintEventsSection(context),
          const SizedBox(height: 24),
          // System events — Requirements 9.2, 9.3, 9.5, 9.6
          _buildSystemEventsSection(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Retry Stats — Requirement 9.4
  // ---------------------------------------------------------------------------

  Widget _buildRetryStats(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return FutureBuilder<Map<String, dynamic>>(
      future: _systemEventsRepo.getRetryStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ??
            {
              'totalRetries': 0,
              'totalEvents': 0,
              'successCount': 0,
              'successRate': 0.0,
            };

        final cards = [
          _StatCard(
            icon: Icons.replay,
            label: l10n.retryAttempts,
            value: '${stats['totalRetries']}',
            theme: theme,
          ),
          _StatCard(
            icon: Icons.event_note,
            label: l10n.totalEventsKpi,
            value: '${stats['totalEvents']}',
            theme: theme,
          ),
          _StatCard(
            icon: Icons.check_circle_outline,
            label: l10n.successRate,
            value: '${(stats['successRate'] as double).toStringAsFixed(1)}%',
            color: (stats['successRate'] as double) >= 90
                ? Colors.green
                : (stats['successRate'] as double) >= 70
                    ? Colors.orange
                    : Colors.red,
            theme: theme,
          ),
        ];

        if (narrow) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: c,
                    ))
                .toList(),
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map((card) => SizedBox(width: 220, child: card))
              .toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Print Events — Requirement 9.1
  // ---------------------------------------------------------------------------

  Widget _buildPrintEventsSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.printEvents, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        LogiRoutePillSelector(
          labels: [l10n.filterAll, l10n.filterSuccess, l10n.filterError],
          selectedIndex: _printStatusFilter == null
              ? 0
              : _printStatusFilter == 'success'
                  ? 1
                  : 2,
          onSelected: (i) => setState(() {
            _printStatusFilter =
                i == 0 ? null : i == 1 ? 'success' : 'error';
          }),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<PrintEvent>>(
          stream: _printEventsRepo.watchPrintEvents(
              statusFilter: _printStatusFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _ErrorCard(
                message: l10n.errorLoadingPrintEvents,
                onRetry: () => setState(() {}),
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.noPrintEvents)),
                ),
              );
            }

            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _PrintEventTile(event: events[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // System Events — Requirements 9.2, 9.3, 9.5, 9.6
  // ---------------------------------------------------------------------------

  Widget _buildSystemEventsSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.systemEvents, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        LogiRoutePillSelector(
          labels: [
            l10n.filterAll,
            l10n.filterError,
            l10n.filterFailed,
            l10n.filterSuccess,
          ],
          selectedIndex: switch (_systemStatusFilter) {
            null => 0,
            'error' => 1,
            'failed' => 2,
            _ => 3,
          },
          onSelected: (i) => setState(() {
            _systemStatusFilter = switch (i) {
              0 => null,
              1 => 'error',
              2 => 'failed',
              _ => 'success',
            };
          }),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<SystemEvent>>(
          stream: _systemEventsRepo.watchSystemEvents(
              statusFilter: _systemStatusFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _ErrorCard(
                message: l10n.errorLoadingSystemEvents,
                onRetry: () => setState(() {}),
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.noSystemEvents)),
                ),
              );
            }

            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _SystemEventTile(event: events[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Private widgets
// =============================================================================

/// Карточка статистики.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Строка события печати.
class _PrintEventTile extends StatelessWidget {
  final PrintEvent event;
  const _PrintEventTile({required this.event});

  static final _timeFmt = DateFormat('dd/MM HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = event.status == PrintEventStatus.error;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final timeStr =
        event.printedAt != null ? _timeFmt.format(event.printedAt!) : '—';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.print_disabled : Icons.print,
            color: isError ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (narrow) ...[
                  Text(AppLocalizations.of(context)!.invoiceLabel(event.invoiceId)),
                  const SizedBox(height: 2),
                  Text(timeStr, style: theme.textTheme.bodySmall),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.invoiceLabel(event.invoiceId),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(timeStr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(AppLocalizations.of(context)!
                    .printerUserLabel(event.printerName ?? '—', event.printedBy)),
                if (isError && event.errorMessage != null)
                  Text(
                    event.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка системного события.
///
/// Красный цвет для error/failed (Req 9.3).
/// Показывает endpoint, статус ответа, время для вебхуков (Req 9.5).
class _SystemEventTile extends StatelessWidget {
  final SystemEvent event;
  const _SystemEventTile({required this.event});

  static final _timeFmt = DateFormat('dd/MM HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final isErrorState = event.status == SystemEventStatus.error ||
        event.status == SystemEventStatus.failed;
    final statusColor = isErrorState
        ? Colors.red
        : event.status == SystemEventStatus.retrying
            ? Colors.orange
            : Colors.green;

    final timeStr =
        event.createdAt != null ? _timeFmt.format(event.createdAt!) : '—';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Icon(_sourceIcon(event.source), size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (narrow) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(event.message),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.status.value,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(timeStr, style: theme.textTheme.bodySmall),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.status.value,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(timeStr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  '${event.type.value} · ${event.source.value}'
                  '${event.retryCount > 0 ? AppLocalizations.of(context)!.retryCountLabel(event.retryCount) : ""}',
                ),
                if (event.endpoint != null)
                  Text(
                    '${event.endpoint}'
                    '${event.responseStatus != null ? " → ${event.responseStatus}" : ""}'
                    '${event.responseTime != null ? " (${event.responseTime}ms)" : ""}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: narrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _sourceIcon(SystemEventSource source) {
    switch (source) {
      case SystemEventSource.print:
        return Icons.print;
      case SystemEventSource.email:
        return Icons.email_outlined;
      case SystemEventSource.whatsapp:
        return Icons.chat;
      case SystemEventSource.webhook:
        return Icons.webhook;
      case SystemEventSource.api:
        return Icons.api;
    }
  }
}

/// Карточка ошибки с кнопкой повтора.
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 36, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
