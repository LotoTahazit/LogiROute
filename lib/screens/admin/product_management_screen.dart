import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_type.dart';
import '../../services/product_type_service.dart';
import '../../services/product_import_service.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/dialog_helper.dart';
import '../../l10n/app_localizations.dart';
import 'dialogs/add_product_type_dialog.dart';
import 'dialogs/edit_product_type_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/file_download.dart';
import '../../widgets/template_import_dialog.dart';

/// Экран управления типами товаров
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String? _selectedCategory;
  bool _showInactiveProducts = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    if (companyId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.noCompanySelected)),
      );
    }

    final productService = ProductTypeService(companyId: companyId);
    final authService = context.read<AuthService>();
    final isAdmin = authService.userModel?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(context, companyId),
            tooltip: l10n.addProduct,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'show_inactive') {
                setState(() => _showInactiveProducts = !_showInactiveProducts);
              } else if (value == 'import') {
                _showImportDialog(context, companyId);
              } else if (value == 'export') {
                _exportProducts(context, companyId);
              } else if (value == 'template') {
                _downloadTemplate();
              } else if (value == 'load_template') {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const TemplateImportDialog(),
                );
                if (result == true && context.mounted) {
                  setState(() {}); // Refresh product list
                }
              } else if (value == 'sync_inventory') {
                _syncFromInventory(context, companyId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'show_inactive',
                child: Row(
                  children: [
                    Icon(
                      _showInactiveProducts
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    const SizedBox(width: 8),
                    Text(_showInactiveProducts
                        ? l10n.hideInactive
                        : l10n.showInactive),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 8),
                    Text(l10n.importFromExcel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text(l10n.exportToExcel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 8),
                    Text(l10n.downloadTemplate),
                  ],
                ),
              ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'load_template',
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('טען תבנית מוצרים'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'sync_inventory',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('סנכרן מהמחסן'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(productService, l10n),
          Expanded(
            child: StreamBuilder<List<ProductType>>(
              stream: productService.getProductTypes(
                activeOnly: !_showInactiveProducts,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('${l10n.error}: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];
                final filteredProducts = _selectedCategory == null
                    ? products
                    : products
                        .where((p) => p.category == _selectedCategory)
                        .toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.noProducts,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddProductDialog(context, companyId),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addFirstProduct),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(
                        context, product, productService, companyId, l10n);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
      ProductTypeService productService, AppLocalizations l10n) {
    return FutureBuilder<List<String>>(
      future: productService.getCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: Text(l10n.allCategories),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  setState(() => _selectedCategory = null);
                },
              ),
              const SizedBox(width: 8),
              ...categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(_getCategoryName(category, l10n)),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(
                          () => _selectedCategory = selected ? category : null);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductType product,
    ProductTypeService productService,
    String companyId,
    AppLocalizations l10n,
  ) {
    final authService = context.read<AuthService>();
    final isSuperAdmin = authService.userModel?.isSuperAdmin ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.isActive ? Colors.blue : Colors.grey,
          child: Text(
            product.name.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: product.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.productCode}: ${product.productCode}'),
            Text(
                '${product.unitsPerBox} ${l10n.unitsPerBox} • ${product.boxesPerPallet} ${l10n.boxesPerPallet}'),
            if (product.category != 'general')
              Text(
                  '${l10n.category}: ${_getCategoryName(product.category, l10n)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _showEditProductDialog(context, product, companyId);
            } else if (value == 'delete') {
              final confirmed = await DialogHelper.showConfirmation(
                context: context,
                title: l10n.deleteProduct,
                content: l10n.deleteProductConfirm(product.name),
              );
              if (confirmed == true) {
                await productService.deleteProductType(product.id);
                if (context.mounted) {
                  SnackbarHelper.showSuccess(context, l10n.productDeleted);
                }
              }
            } else if (value == 'hard_delete') {
              final confirmed = await DialogHelper.showConfirmation(
                context: context,
                title: 'מחיקה סופית',
                content:
                    'למחוק לצמיתות את "${product.name}"? פעולה זו אינה הפיכה.',
              );
              if (confirmed == true) {
                await productService.hardDeleteProductType(product.id);
                if (context.mounted) {
                  SnackbarHelper.showSuccess(context, l10n.productDeleted);
                }
              }
            } else if (value == 'toggle_active') {
              await productService.updateProductType(
                product.id,
                product.copyWith(isActive: !product.isActive),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text(l10n.edit)
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_active',
              child: Row(
                children: [
                  Icon(product.isActive
                      ? Icons.visibility_off
                      : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(product.isActive ? l10n.inactive : l10n.active),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            if (isSuperAdmin)
              const PopupMenuItem(
                value: 'hard_delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('מחיקה סופית', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String category, AppLocalizations l10n) {
    switch (category) {
      case 'general':
        return l10n.categoryGeneral;
      case 'cups':
        return l10n.categoryCups;
      case 'lids':
        return l10n.categoryLids;
      case 'containers':
        return l10n.categoryContainers;
      case 'bread':
        return l10n.categoryBread;
      case 'dairy':
        return l10n.categoryDairy;
      case 'shirts':
        return l10n.categoryShirts;
      case 'trays':
        return l10n.categoryTrays;
      case 'bottles':
        return l10n.categoryBottles;
      case 'bags':
        return l10n.categoryBags;
      case 'boxes':
        return l10n.categoryBoxes;
      default:
        return category;
    }
  }

  Future<void> _showAddProductDialog(
      BuildContext context, String companyId) async {
    final authService = context.read<AuthService>();
    final userName = authService.userModel?.name ?? 'Unknown';

    final result = await showDialog<ProductType>(
      context: context,
      builder: (context) => AddProductTypeDialog(
        companyId: companyId,
        createdBy: userName,
      ),
    );

    if (result != null && context.mounted) {
      try {
        final productService = ProductTypeService(companyId: companyId);
        await productService.createProductType(result);
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          SnackbarHelper.showSuccess(context, l10n.productAdded);
        }
      } catch (e) {
        if (context.mounted) {
          final msg = e.toString();
          if (msg.contains('DUPLICATE_PRODUCT_CODE')) {
            SnackbarHelper.showError(
              context,
              'מק"ט ${result.productCode} כבר קיים. יש לבחור מק"ט אחר.',
            );
          } else {
            SnackbarHelper.showError(context, 'שגיאה: $e');
          }
        }
      }
    }
  }

  Future<void> _showEditProductDialog(
    BuildContext context,
    ProductType product,
    String companyId,
  ) async {
    final result = await showDialog<ProductType>(
      context: context,
      builder: (context) => EditProductTypeDialog(product: product),
    );

    if (result != null && context.mounted) {
      final productService = ProductTypeService(companyId: companyId);
      await productService.updateProductType(product.id, result);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showSuccess(context, l10n.productUpdated);
      }
    }
  }

  Future<void> _showImportDialog(BuildContext context, String companyId) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final userName = authService.userModel?.name ?? 'Unknown';

    try {
      final products = await ProductImportService.pickAndImportFile(
        companyId,
        userName,
      );

      if (products == null || products.isEmpty) {
        if (context.mounted) {
          SnackbarHelper.showWarning(context, l10n.importError);
        }
        return;
      }

      // Импортируем товары
      final productService = ProductTypeService(companyId: companyId);
      await productService.importProductTypes(products);

      if (context.mounted) {
        SnackbarHelper.showSuccess(
          context,
          l10n.importSuccess(products.length),
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, '${l10n.importError}: $e');
      }
    }
  }

  Future<void> _exportProducts(BuildContext context, String companyId) async {
    final l10n = AppLocalizations.of(context)!;
    final productService = ProductTypeService(companyId: companyId);

    try {
      final products =
          await productService.getProductTypes(activeOnly: false).first;
      final bytes = ProductImportService.exportProducts(products);

      if (kIsWeb) {
        // Скачиваем файл на Web
        downloadFile(
            bytes, 'products_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      } else {
        // На мобильных платформах показываем сообщение
        if (context.mounted) {
          SnackbarHelper.showWarning(context, 'Export not supported on mobile');
        }
        return;
      }

      if (context.mounted) {
        SnackbarHelper.showSuccess(context, l10n.exportSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, '${l10n.error}: $e');
      }
    }
  }

  void _downloadTemplate() {
    final l10n = AppLocalizations.of(context)!;

    try {
      final bytes = ProductImportService.createTemplate();

      if (kIsWeb) {
        // Скачиваем файл на Web
        downloadFile(bytes, 'product_template.xlsx');
      } else {
        // На мобильных платформах показываем сообщение
        SnackbarHelper.showWarning(
            context, 'Template download not supported on mobile');
        return;
      }

      SnackbarHelper.showSuccess(context, l10n.templateDownloaded);
    } catch (e) {
      SnackbarHelper.showError(context, '${l10n.error}: $e');
    }
  }

  Future<void> _syncFromInventory(
      BuildContext context, String companyId) async {
    final authService = context.read<AuthService>();
    final userName = authService.userModel?.name ?? 'Unknown';

    final confirmed = await DialogHelper.showConfirmation(
      context: context,
      title: 'סנכרון מהמחסן',
      content:
          'ליצור מוצרים חדשים בקטלוג עבור כל הפריטים שקיימים במחסן אך חסרים בקטלוג?',
    );
    if (confirmed != true || !context.mounted) return;

    final inventoryService = InventoryService(companyId: companyId);
    final result = await inventoryService.syncAllToProductTypes(userName);

    if (context.mounted) {
      final created = result['created'] ?? 0;
      final updated = result['updated'] ?? 0;
      final skipped = result['skipped'] ?? 0;
      SnackbarHelper.showSuccess(
        context,
        '✅ סנכרון הושלם: נוספו $created, עודכנו $updated, דולגו $skipped',
      );
      setState(() {}); // רענון הרשימה
    }
  }
}
