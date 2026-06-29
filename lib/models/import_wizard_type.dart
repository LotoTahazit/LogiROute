/// Тип импорта в Import Mapping Wizard.
enum ImportWizardType {
  clients('clients'),
  products('products'),
  deliveryPoints('delivery_points');

  final String value;
  const ImportWizardType(this.value);

  static ImportWizardType? fromValue(String? v) {
    if (v == null) return null;
    for (final t in values) {
      if (t.value == v) return t;
    }
    return null;
  }
}
