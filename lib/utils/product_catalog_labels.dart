import '../l10n/app_localizations.dart';
import '../models/company_terminology.dart';

/// Подписи полей справочника товаров / box_types по [CompanyTerminology.businessType].
class ProductCatalogLabels {
  const ProductCatalogLabels({
    required this.typeLabel,
    required this.numberLabel,
    required this.volumeLabel,
    required this.quantityPerPalletLabel,
    required this.piecesPerBoxLabel,
    required this.showDiameter,
  });

  final String typeLabel;
  final String numberLabel;
  final String volumeLabel;
  final String quantityPerPalletLabel;
  final String piecesPerBoxLabel;
  final bool showDiameter;

  factory ProductCatalogLabels.fromTerminology(
    CompanyTerminology t,
    AppLocalizations l10n,
  ) {
    final qtyOnPallet = l10n.quantityOnPalletName(t.palletName);
    final piecesInBox = l10n.piecesPerUnitInBox(t.unitName);

    switch (t.businessType) {
      case 'food':
        return ProductCatalogLabels(
          typeLabel: l10n.typeLabelFood,
          numberLabel: l10n.numberLabelFood,
          volumeLabel: l10n.volumeLabelFood,
          quantityPerPalletLabel: qtyOnPallet,
          piecesPerBoxLabel: piecesInBox,
          showDiameter: false,
        );
      case 'clothing':
        return ProductCatalogLabels(
          typeLabel: l10n.typeLabelClothing,
          numberLabel: l10n.numberLabelClothing,
          volumeLabel: l10n.volumeLabelOptionalGeneric,
          quantityPerPalletLabel:
              t.usesPallets ? qtyOnPallet : l10n.quantityPerBoxLabel,
          piecesPerBoxLabel: piecesInBox,
          showDiameter: false,
        );
      case 'construction':
        return ProductCatalogLabels(
          typeLabel: l10n.typeLabelConstruction,
          numberLabel: l10n.numberLabelConstruction,
          volumeLabel: l10n.weightLabelOptional,
          quantityPerPalletLabel: qtyOnPallet,
          piecesPerBoxLabel: piecesInBox,
          showDiameter: false,
        );
      case 'packaging':
        return ProductCatalogLabels(
          typeLabel: l10n.typeLabel,
          numberLabel: l10n.numberLabel,
          volumeLabel: l10n.volumeMlLabel,
          quantityPerPalletLabel: qtyOnPallet,
          piecesPerBoxLabel: l10n.piecesPerBoxLabel,
          showDiameter: true,
        );
      default:
        return ProductCatalogLabels(
          typeLabel: l10n.typeLabelGeneric,
          numberLabel: l10n.numberLabelGeneric,
          volumeLabel: l10n.volumeLabelOptionalGeneric,
          quantityPerPalletLabel: qtyOnPallet,
          piecesPerBoxLabel: piecesInBox,
          showDiameter: false,
        );
    }
  }
}
