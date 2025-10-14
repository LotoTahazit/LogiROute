import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import 'analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _lastUpdatedText = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final users = await authService.getAllUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
      _lastUpdatedText = '🕓 ${TimeOfDay.now().format(context)}';
    });
  }

  String _getLocalizedRole(String role, AppLocalizations l10n) {
    switch (role) {
      case 'admin':
        return l10n.roleAdmin;
      case 'dispatcher':
        return l10n.roleDispatcher;
      case 'driver':
        return l10n.roleDriver;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admin),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              onPressed: _isLoading ? null : _loadUsers,
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: l10n.analytics,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),
            PopupMenuButton<String>(
              tooltip: l10n.settings,
              onSelected: (value) {
                if (value == 'logout') {
                  authService.signOut();
                } else if (value == 'he' ||
                    value == 'ru' ||
                    value == 'en') {
                  localeService.setLocale(value);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'he', child: Text(l10n.hebrew)),
                PopupMenuItem(value: 'ru', child: Text(l10n.russian)),
                PopupMenuItem(value: 'en', child: Text(l10n.english)),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          '${l10n.viewAs}:',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: authService.viewAsRole ?? 'admin',
                          items: [
                            DropdownMenuItem(
                                value: 'admin',
                                child: Text(l10n.roleAdmin)),
                            DropdownMenuItem(
                                value: 'dispatcher',
                                child: Text(l10n.roleDispatcher)),
                            DropdownMenuItem(
                                value: 'driver',
                                child: Text(l10n.roleDriver)),
                          ],
                          onChanged: (value) =>
                              authService.setViewAsRole(value),
                        ),
                        const Spacer(),
                        if (_lastUpdatedText.isNotEmpty)
                          Text(
                            '${l10n.lastUpdated}: $_lastUpdatedText',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _users.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noUsersFound,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                elevation: 1,
                                child: ListTile(
                                  leading: Icon(
                                    user.role == 'driver'
                                        ? Icons.local_shipping
                                        : user.role == 'dispatcher'
                                            ? Icons.map
                                            : Icons.admin_panel_settings,
                                    color: Colors.blueGrey,
                                  ),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    '${user.email} • ${_getLocalizedRole(user.role, l10n)}',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  trailing: user.palletCapacity != null
                                      ? Text(
                                          '${user.palletCapacity} ${l10n.pallets}',
                                          style: const TextStyle(
                                              color: Colors.black87),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
