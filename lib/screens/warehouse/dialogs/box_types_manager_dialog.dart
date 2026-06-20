import 'package:flutter/material.dart';
import 'package:logiroute/services/box_type_service.dart';
import 'package:logiroute/services/company_context.dart';
import 'package:logiroute/l10n/app_localizations.dart';
import 'package:logiroute/screens/warehouse/dialogs/edit_box_type_dialog.dart';
import 'package:logiroute/screens/warehouse/dialogs/delete_confirmation_dialog.dart';
import '../../../theme/app_theme.dart';

class BoxTypesManagerDialog extends StatefulWidget {
  const BoxTypesManagerDialog({super.key});

  @override
  State<BoxTypesManagerDialog> createState() => _BoxTypesManagerDialogState();

  static Future<void> show({required BuildContext context}) {
    return showDialog(
      context: context,
      builder: (context) => const BoxTypesManagerDialog(),
    );
  }
}

class _BoxTypesManagerDialogState extends State<BoxTypesManagerDialog> {
  late final BoxTypeService _boxTypeService;
  List<Map<String, dynamic>> _boxTypes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);
    _loadBoxTypes();
  }

  Future<void> _loadBoxTypes() async {
    setState(() => _isLoading = true);
    final boxTypes = await _boxTypeService.getAllBoxTypes();
    boxTypes.sort((a, b) {
      final codeA = a['productCode'] as String? ?? '';
      final codeB = b['productCode'] as String? ?? '';
      return codeA.compareTo(codeB);
    });
    if (mounted) {
      setState(() {
        _boxTypes = boxTypes;
        _isLoading = false;
      });
    }
  }

  Future<void> _editBoxType(
    String id,
    String productCode,
    String type,
    String number,
    int volumeMl,
    int quantityPerPallet,
    String? diameter,
    int? piecesPerBox,
    String? additionalInfo,
  ) async {
    await EditBoxTypeDialog.show(
      context: context,
      id: id,
      oldProductCode: productCode,
      oldType: type,
      oldNumber: number,
      oldVolumeMl: volumeMl,
      oldQuantityPerPallet: quantityPerPallet,
      oldDiameter: diameter,
      oldPiecesPerBox: piecesPerBox,
      oldAdditionalInfo: additionalInfo,
    );
    _loadBoxTypes();
  }

  Future<void> _deleteBoxType(
      String id, String productCode, String type, String number) async {
    await DeleteConfirmationDialog.show(
      context: context,
      title: 'מחק סוג',
      content: 'האם למחוק $productCode ($type $number) מהמאגר?',
      onConfirm: () async {
        await _boxTypeService.deleteBoxType(id);
      },
    );
    _loadBoxTypes();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Фильтруем список по поисковому запросу
    final filteredBoxTypes = _searchQuery.isEmpty
        ? _boxTypes
        : _boxTypes.where((bt) {
            final productCode =
                (bt['productCode'] as String? ?? '').toLowerCase();
            final type = (bt['type'] as String).toLowerCase();
            final number = (bt['number'] as String).toLowerCase();
            final search = _searchQuery.toLowerCase();

            return productCode.contains(search) ||
                type.contains(search) ||
                number.contains(search);
          }).toList();

    return AlertDialog(
      title: Text(l10n.boxTypesManager),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Поле поиска
            TextField(
              decoration: InputDecoration(
                labelText: 'חיפוש לפי מק"ט / סוג / מספר',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            // Список товаров
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBoxTypes.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? l10n.noBoxTypesInCatalog
                                : 'לא נמצאו תוצאות',
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredBoxTypes.length,
                          itemBuilder: (context, index) {
                            final boxType = filteredBoxTypes[index];
                            final productCode =
                                boxType['productCode'] as String? ?? '';
                            final type = boxType['type'] as String;
                            final number = boxType['number'] as String;
                            final volumeMl =
                                (boxType['volumeMl'] as num?)?.toInt();
                            final quantityPerPallet =
                                (boxType['quantityPerPallet'] as num?)
                                        ?.toInt() ??
                                    1;
                            final diameter = boxType['diameter'] as String?;
                            final piecesPerBox =
                                (boxType['piecesPerBox'] as num?)?.toInt();
                            final additionalInfo =
                                boxType['additionalInfo'] as String?;
                            final id = boxType['id'] as String;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        productCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                        textDirection: TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$type $number',
                                            textDirection: TextDirection.rtl,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            volumeMl != null
                                                ? '$volumeMl ${l10n.ml}'
                                                : l10n.volumeMlLabel,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.muted),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () => _editBoxType(
                                            id,
                                            productCode,
                                            type,
                                            number,
                                            volumeMl ?? 0,
                                            quantityPerPallet,
                                            diameter,
                                            piecesPerBox,
                                            additionalInfo,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteBoxType(
                                              id, productCode, type, number),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
