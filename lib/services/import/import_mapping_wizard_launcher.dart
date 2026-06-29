import 'package:flutter/material.dart';

import '../../screens/shared/import_mapping_wizard_screen.dart';
import '../../models/import_wizard_type.dart';

/// Открыть Import Mapping Wizard.
class ImportMappingWizardLauncher {
  static Future<void> open(
    BuildContext context, {
    ImportWizardType? initialType,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportMappingWizardScreen(initialType: initialType),
      ),
    );
  }
}
