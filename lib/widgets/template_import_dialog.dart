import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/import_result.dart';
import '../models/template_product.dart';
import '../services/auth_service.dart';
import '../services/company_context.dart';
import '../services/template_service.dart';

/// Шаги многошагового диалога импорта шаблонов.
enum _DialogStep { selectBusinessType, previewProducts, importing, summary }

/// Многошаговый диалог импорта шаблонов товаров.
///
/// Состояния:
/// - [selectBusinessType] — выбор типа бизнеса
/// - [previewProducts] — превью товаров с чекбоксами
/// - [importing] — процесс импорта
/// - [summary] — итоговый отчёт
class TemplateImportDialog extends StatefulWidget {
  const TemplateImportDialog({super.key});

  @override
  State<TemplateImportDialog> createState() => _TemplateImportDialogState();
}

class _TemplateImportDialogState extends State<TemplateImportDialog> {
  /// Maximum number of products that can be imported in a single batch.
  static const int _maxBatchSize = 100;

  _DialogStep _currentStep = _DialogStep.selectBusinessType;

  // --- State for selectBusinessType step ---
  List<String> _businessTypes = [];
  bool _isLoadingBusinessTypes = true;
  String? _selectedBusinessType;

  // --- State for previewProducts step ---
  List<TemplateProduct> _templates = [];
  bool _isLoadingTemplates = false;
  Set<String> _selectedTemplateIds = {};

  // --- State for importing/summary steps ---
  bool _isImporting = false;
  ImportResult? _importResult;

  @override
  void initState() {
    super.initState();
    _loadBusinessTypes();
  }

  Future<void> _loadBusinessTypes() async {
    try {
      final types = await TemplateService().getAvailableBusinessTypes();
      if (mounted) {
        setState(() {
          _businessTypes = types;
          _isLoadingBusinessTypes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _businessTypes = [];
          _isLoadingBusinessTypes = false;
        });
      }
    }
  }

  Future<void> _loadTemplates() async {
    if (_selectedBusinessType == null) return;
    setState(() {
      _isLoadingTemplates = true;
      _templates = [];
      _selectedTemplateIds = {};
    });
    try {
      final templates = await TemplateService()
          .getTemplatesByBusinessType(_selectedBusinessType!);
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _templates = [];
          _isLoadingTemplates = false;
        });
      }
    }
  }

  Map<String, List<TemplateProduct>> _groupByCategory() {
    final groups = <String, List<TemplateProduct>>{};
    for (final t in _templates) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    return groups;
  }

  Future<void> _startImport() async {
    try {
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId;
      if (companyId == null || companyId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שגיאה: לא נבחרה חברה')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final authService = context.read<AuthService>();
      final createdBy = authService.currentUser?.uid ?? '';

      final selectedTemplates =
          _templates.where((t) => _selectedTemplateIds.contains(t.id)).toList();

      // Analytics: template_import_started
      FirebaseAnalytics.instance.logEvent(
        name: 'template_import_started',
        parameters: {
          'businessType': _selectedBusinessType ?? '',
          'selectedCount': selectedTemplates.length,
        },
      );

      final result = await TemplateService().importSelectedTemplates(
        companyId: companyId,
        createdBy: createdBy,
        selectedTemplates: selectedTemplates,
      );

      // Analytics: template_import_completed
      FirebaseAnalytics.instance.logEvent(
        name: 'template_import_completed',
        parameters: {
          'businessType': _selectedBusinessType ?? '',
          'addedCount': result.addedCount,
          'skippedCount': result.skippedCount,
          'errorCount': result.errorCount,
        },
      );

      if (mounted) {
        setState(() {
          _importResult = result;
          _currentStep = _DialogStep.summary;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בייבוא: $e')),
        );
        setState(() {
          _currentStep = _DialogStep.previewProducts;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_titleForStep(_currentStep)),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildStepContent(),
      ),
      actions: _buildActions(),
    );
  }

  String _titleForStep(_DialogStep step) {
    switch (step) {
      case _DialogStep.selectBusinessType:
        return 'בחר סוג עסק';
      case _DialogStep.previewProducts:
        return 'תצוגה מקדימה';
      case _DialogStep.importing:
        return 'מייבא...';
      case _DialogStep.summary:
        return 'סיכום ייבוא';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case _DialogStep.selectBusinessType:
        return _buildSelectBusinessType();
      case _DialogStep.previewProducts:
        return _buildPreviewProducts();
      case _DialogStep.importing:
        return _buildImporting();
      case _DialogStep.summary:
        return _buildSummary();
    }
  }

  List<Widget> _buildActions() {
    switch (_currentStep) {
      case _DialogStep.selectBusinessType:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ];
      case _DialogStep.previewProducts:
        final batchExceeded = _selectedTemplateIds.length > _maxBatchSize;
        return [
          TextButton(
            onPressed: () => setState(() {
              _currentStep = _DialogStep.selectBusinessType;
              _templates = [];
              _selectedTemplateIds = {};
            }),
            child: const Text('חזרה'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: _selectedTemplateIds.isNotEmpty &&
                    !_isImporting &&
                    !batchExceeded
                ? () {
                    setState(() {
                      _isImporting = true;
                      _currentStep = _DialogStep.importing;
                    });
                    _startImport();
                  }
                : null,
            child: Text('ייבוא (${_selectedTemplateIds.length})'),
          ),
        ];
      case _DialogStep.importing:
        return []; // No actions during import
      case _DialogStep.summary:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('סגור'),
          ),
        ];
    }
  }

  // --- Build methods for each step ---

  Widget _buildSelectBusinessType() {
    if (_isLoadingBusinessTypes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_businessTypes.isEmpty) {
      return const Center(
        child: Text('אין סוגי עסק זמינים'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _businessTypes.length,
      itemBuilder: (context, index) {
        final type = _businessTypes[index];
        return ListTile(
          title: Text(type),
          onTap: () {
            setState(() {
              _selectedBusinessType = type;
              _currentStep = _DialogStep.previewProducts;
            });
            _loadTemplates();
          },
        );
      },
    );
  }

  Widget _buildPreviewProducts() {
    if (_isLoadingTemplates) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_templates.isEmpty) {
      return const Center(
        child: Text('אין תבניות זמינות לסוג עסק זה'),
      );
    }

    final groups = _groupByCategory();
    final allSelected = _selectedTemplateIds.length == _templates.length;
    final batchExceeded = _selectedTemplateIds.length > _maxBatchSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Global select all / deselect all
        CheckboxListTile(
          title: Text(
              'בחר הכל (${_selectedTemplateIds.length}/${_templates.length})'),
          value: _selectedTemplateIds.isEmpty
              ? false
              : allSelected
                  ? true
                  : null,
          tristate: true,
          onChanged: (value) {
            setState(() {
              if (allSelected) {
                _selectedTemplateIds.clear();
              } else {
                _selectedTemplateIds = _templates.map((t) => t.id).toSet();
              }
            });
          },
        ),
        if (batchExceeded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ניתן לייבא עד $_maxBatchSize מוצרים בכל פעם. נבחרו ${_selectedTemplateIds.length} מוצרים.',
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        Expanded(
          child: ListView(
            children: groups.entries.expand((entry) {
              final category = entry.key;
              final products = entry.value;
              final categoryIds = products.map((p) => p.id).toSet();
              final allCategorySelected =
                  categoryIds.every((id) => _selectedTemplateIds.contains(id));
              final someCategorySelected =
                  categoryIds.any((id) => _selectedTemplateIds.contains(id));

              return [
                // Category header with select all/deselect all
                CheckboxListTile(
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: !someCategorySelected
                      ? false
                      : allCategorySelected
                          ? true
                          : null,
                  tristate: true,
                  onChanged: (value) {
                    setState(() {
                      if (allCategorySelected) {
                        _selectedTemplateIds.removeAll(categoryIds);
                      } else {
                        _selectedTemplateIds.addAll(categoryIds);
                      }
                    });
                  },
                ),
                // Products in this category
                ...products.map((product) => CheckboxListTile(
                      value: _selectedTemplateIds.contains(product.id),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedTemplateIds.add(product.id);
                          } else {
                            _selectedTemplateIds.remove(product.id);
                          }
                        });
                      },
                      title: Text(product.name),
                      subtitle: Text(
                        'מק"ט: ${product.productCode} | '
                        'קטגוריה: ${product.category} | '
                        'יח׳/ארגז: ${product.unitsPerBox} | '
                        'ארגזים/משטח: ${product.boxesPerPallet}',
                      ),
                    )),
                const Divider(height: 1),
              ];
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImporting() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('מייבא מוצרים, אנא המתן...'),
      ],
    );
  }

  Widget _buildSummary() {
    if (_importResult == null) {
      return const SizedBox.shrink();
    }

    final result = _importResult!;
    final showSuccess = result.addedCount > 0 && result.errorCount == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSuccess)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Icon(Icons.check_circle, color: Colors.green, size: 48),
          ),
        Text(
          result.summaryString,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (result.errorCount > 0 && result.errorProductNames.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'מוצרים עם שגיאות:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          const SizedBox(height: 8),
          ...result.errorProductNames.map(
            (name) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $name'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
