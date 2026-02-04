import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../models/route_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<Map<String, dynamic>> _getAnalytics(AppLocalizations l10n) async {
    final firestore = FirebaseFirestore.instance;

    final pointsSnapshot = await firestore.collection('delivery_points').get();
    final routesSnapshot = await firestore.collection('routes').get();

    final points = pointsSnapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
    final routes = routesSnapshot.docs
        .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
        .toList();

    final completed =
        points.where((p) => p.status == l10n.statusCompleted).length;
    final pending = points.where((p) => p.status == l10n.statusPending).length;
    final inProgress = points
        .where((p) =>
            p.status == l10n.statusAssigned ||
            p.status == l10n.statusInProgress)
        .length;
    final cancelled =
        points.where((p) => p.status == l10n.statusCancelled).length;

    final totalPallets = points.fold<int>(0, (sum, p) => sum + (p.pallets));
    final completedPallets = points
        .where((p) => p.status == l10n.statusCompleted)
        .fold<int>(0, (sum, p) => sum + p.pallets);

    final activeRoutes =
        routes.where((r) => r.status == l10n.statusActive).length;

    final completionRate =
        points.isEmpty ? 0.0 : (completed / points.length * 100);

    return {
      'totalPoints': points.length,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'cancelled': cancelled,
      'totalPallets': totalPallets,
      'completedPallets': completedPallets,
      'activeRoutes': activeRoutes,
      'completionRate': completionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(l10n.analytics)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getAnalytics(l10n),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                l10n.statusCompleted,
                '${data['completed']}',
                Colors.green,
                Icons.check_circle,
              ),
              _buildCard(
                l10n.statusInProgress,
                '${data['inProgress']}',
                Colors.orange,
                Icons.local_shipping,
              ),
              _buildCard(
                l10n.statusPending,
                '${data['pending']}',
                Colors.blue,
                Icons.pending,
              ),
              _buildCard(
                l10n.statusCancelled,
                '${data['cancelled']}',
                Colors.red,
                Icons.cancel,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.palletStatistics,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.total}: ${data['totalPallets']}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      Text(
                        '${l10n.delivered}: ${data['completedPallets']}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: data['totalPallets'] > 0
                            ? data['completedPallets'] / data['totalPallets']
                            : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.completionRate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${data['completionRate'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                l10n.activeRoutes,
                '${data['activeRoutes']}',
                Colors.purple,
                Icons.route,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
