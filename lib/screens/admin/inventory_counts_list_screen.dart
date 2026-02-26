import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_count.dart';
import '../../services/inventory_count_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import 'inventory_count_detail_screen.dart';
import 'package:intl/intl.dart';

/// Экран списка всех инвентаризаций (для админа/диспетчера, Web-ориентированный)
class InventoryCountsListScreen extends StatelessWidget {
  const InventoryCountsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyCtx = CompanyContext.watch(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    final countService = InventoryCountService(companyId: companyId);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryCountReports),
      ),
      body: StreamBuilder<List<InventoryCount>>(
        stream: countService.getAllCountsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${l10n.error}: ${snapshot.error}'),
            );
          }

          final counts = snapshot.data ?? [];

          if (counts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noCountReports,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: counts.length,
            itemBuilder: (context, index) {
              final count = counts[index];
              return _buildCountCard(context, count, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildCountCard(
      BuildContext context, InventoryCount count, AppLocalizations l10n) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isCompleted =
        count.status == 'completed' || count.status == 'approved';
    final isApproved = count.status == 'approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  InventoryCountDetailScreen(countId: count.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(
                    isApproved
                        ? Icons.check_circle
                        : isCompleted
                            ? Icons.done
                            : Icons.pending,
                    color: isApproved
                        ? Colors.green
                        : isCompleted
                            ? Colors.blue
                            : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.inventoryCount} #${count.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${l10n.performedBy}: ${count.userName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(count.status, l10n),
                ],
              ),
              const Divider(height: 24),

              // Даты
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.started}: ${dateFormat.format(count.startedAt)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (count.completedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.finished}: ${dateFormat.format(count.completedAt!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Статистика
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    icon: Icons.inventory,
                    label: l10n.items,
                    value: '${count.summary.totalItems}',
                    color: Colors.blue,
                  ),
                  _buildStatColumn(
                    icon: Icons.check_circle,
                    label: l10n.counted,
                    value: '${count.summary.checkedItems}',
                    color: Colors.green,
                  ),
                  _buildStatColumn(
                    icon: Icons.warning,
                    label: l10n.differences,
                    value: '${count.summary.itemsWithDifference}',
                    color: Colors.orange,
                  ),
                  _buildStatColumn(
                    icon: Icons.arrow_downward,
                    label: l10n.shortage,
                    value: '${count.summary.totalShortage}',
                    color: Colors.red,
                  ),
                  _buildStatColumn(
                    icon: Icons.arrow_upward,
                    label: l10n.surplus,
                    value: '${count.summary.totalSurplus}',
                    color: Colors.blue,
                  ),
                ],
              ),

              // Кнопка просмотра
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InventoryCountDetailScreen(countId: count.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text(l10n.viewDetails),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color color;
    String text;

    switch (status) {
      case 'in_progress':
        color = Colors.orange;
        text = l10n.inProgress;
        break;
      case 'completed':
        color = Colors.blue;
        text = l10n.completed;
        break;
      case 'approved':
        color = Colors.green;
        text = l10n.approved;
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
