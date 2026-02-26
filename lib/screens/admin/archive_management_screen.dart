import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/archive_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';

class ArchiveManagementScreen extends StatefulWidget {
  const ArchiveManagementScreen({super.key});

  @override
  State<ArchiveManagementScreen> createState() =>
      _ArchiveManagementScreenState();
}

class _ArchiveManagementScreenState extends State<ArchiveManagementScreen> {
  late final ArchiveService _archiveService;
  bool _isLoading = false;
  List<Map<String, dynamic>> _archives = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _archiveService = ArchiveService(companyId: companyId);
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    setState(() => _isLoading = true);
    try {
      final archives = await _archiveService.listArchives();
      final stats = await _archiveService.getArchiveStats();

      if (mounted) {
        setState(() {
          _archives = archives;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingArchives}: $e')),
        );
      }
    }
  }

  Future<void> _archiveInventoryHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.archiveInventoryHistoryTitle),
        content: Text(l10n.archiveInventoryHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await _archiveService.archiveInventoryHistory(monthsOld: 3);
      final l10n = AppLocalizations.of(context)!;

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadArchives();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${l10n.error}: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _archiveCompletedOrders() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.archiveCompletedOrdersTitle),
        content: Text(l10n.archiveCompletedOrdersConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await _archiveService.archiveCompletedOrders(monthsOld: 1);
      final l10n = AppLocalizations.of(context)!;

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadArchives();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${l10n.error}: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.archiveManagement),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadArchives,
              tooltip: l10n.refresh,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статистика
                    if (_stats != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.statistics,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    l10n.totalArchives,
                                    '${_stats!['totalArchives']}',
                                    Icons.archive,
                                    Colors.blue,
                                  ),
                                  _buildStatCard(
                                    l10n.totalSize,
                                    '${_stats!['totalSizeMB']} ${l10n.mb}',
                                    Icons.storage,
                                    Colors.green,
                                  ),
                                  _buildStatCard(
                                    l10n.records,
                                    '${_stats!['totalRecords']}',
                                    Icons.description,
                                    Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Кнопки действий
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.archiveActions,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _archiveInventoryHistory,
                                    icon: const Icon(Icons.inventory),
                                    label: Text(l10n.archiveInventoryHistory),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _archiveCompletedOrders,
                                    icon: const Icon(Icons.shopping_cart),
                                    label: Text(l10n.archiveOrders),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Список архивов
                    Text(
                      l10n.existingArchives,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_archives.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(l10n.noArchives),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _archives.length,
                        itemBuilder: (context, index) {
                          final archive = _archives[index];
                          final isHistory =
                              archive['type'] == 'inventory_history';

                          return Card(
                            child: ListTile(
                              leading: Icon(
                                isHistory
                                    ? Icons.inventory
                                    : Icons.shopping_cart,
                                color: isHistory ? Colors.blue : Colors.green,
                                size: 32,
                              ),
                              title: Text(archive['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.size}: ${_formatBytes(archive['size'])} | '
                                    '${l10n.records}: ${archive['recordCount'] ?? 'N/A'}',
                                  ),
                                  Text(
                                    '${l10n.created}: ${_formatDate(archive['created'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'download',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.download),
                                        const SizedBox(width: 8),
                                        Text(l10n.download),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'download') {
                                    try {
                                      final url = await _archiveService
                                          .getArchiveDownloadUrl(
                                              archive['path']);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('URL: $url'),
                                            duration:
                                                const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('${l10n.error}: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
