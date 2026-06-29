import 'package:flutter/material.dart';

import '../../../../screens/shared/client_management_screen.dart';

/// Секция «Управление клиентами» Owner Dashboard.
class ClientsSection extends StatelessWidget {
  const ClientsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClientManagementScreen(embedded: true);
  }
}
