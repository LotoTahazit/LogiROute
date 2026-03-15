import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart';

/// Фабрика виджета для просмотра документа.
typedef DocumentWidgetFactory = Widget Function(String companyId, String docId);

/// Центральный реестр документов — UI не содержит if/switch по типам.
///
/// Добавить новый тип документа = 1 вызов [register].
/// UI вызывает только [open] / [openInNewTab] / [copyLink].
class DocumentRouter {
  DocumentRouter._();

  static const _baseUrl = 'https://logiroute-app.web.app';

  /// Реестр: collection → factory.
  static final Map<String, DocumentWidgetFactory> _registry = {};

  /// Зарегистрировать тип документа.
  static void register(String collection, DocumentWidgetFactory factory) {
    _registry[collection] = factory;
  }

  /// Проверка поддержки коллекции.
  static bool isSupported(String collection) =>
      _registry.containsKey(collection);

  /// Построить deep-link URL.
  static String buildUrl(String companyId, String docId, String collection) =>
      '$_baseUrl/doc?id=$docId&company=$companyId&col=$collection';

  /// Построить виджет для документа.
  static Widget build(String collection, String companyId, String docId) =>
      _registry[collection]!(companyId, docId);

  /// Открыть документ внутри приложения.
  static void open(
    BuildContext context, {
    required String companyId,
    required String collection,
    required String docId,
  }) {
    final factory = _registry[collection];
    if (factory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('פתיחת מסמך מסוג $collection עדיין לא נתמכת')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => factory(companyId, docId)),
    );
  }

  /// Открыть в новой вкладке (web) или in-app fallback.
  static void openInNewTab(
    BuildContext context, {
    required String companyId,
    required String collection,
    required String docId,
  }) {
    if (!isSupported(collection)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('פתיחת מסמך מסוג $collection עדיין לא נתמכת')),
      );
      return;
    }
    if (kIsWeb) {
      openUrlInNewTab(buildUrl(companyId, docId, collection));
    } else {
      open(context, companyId: companyId, collection: collection, docId: docId);
    }
  }

  /// Скопировать deep-link URL в буфер обмена.
  static void copyLink(
    BuildContext context, {
    required String companyId,
    required String collection,
    required String docId,
  }) {
    Clipboard.setData(
        ClipboardData(text: buildUrl(companyId, docId, collection)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('קישור הועתק ללוח'), duration: Duration(seconds: 2)),
    );
  }
}
