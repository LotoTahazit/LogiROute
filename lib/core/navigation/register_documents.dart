import 'document_router.dart';
import '../../widgets/invoice_deep_link_viewer.dart';

/// Регистрация всех типов документов в DocumentRouter.
/// Вызывается один раз в main() перед runApp.
/// Добавить новый тип = 1 строка.
void registerDocuments() {
  DocumentRouter.register(
    'invoices',
    (companyId, docId) => InvoiceDeepLinkViewer(
        companyId: companyId, docId: docId, collection: 'invoices'),
  );

  DocumentRouter.register(
    'creditNotes',
    (companyId, docId) => InvoiceDeepLinkViewer(
        companyId: companyId, docId: docId, collection: 'creditNotes'),
  );

  DocumentRouter.register(
    'receipts',
    (companyId, docId) => InvoiceDeepLinkViewer(
        companyId: companyId, docId: docId, collection: 'receipts'),
  );

  DocumentRouter.register(
    'deliveryNotes',
    (companyId, docId) => InvoiceDeepLinkViewer(
        companyId: companyId, docId: docId, collection: 'deliveryNotes'),
  );

  // Future modules — add 1 line each:
  // DocumentRouter.register('inventory', (cid, did) => InventoryItemScreen(...));
  // DocumentRouter.register('routes', (cid, did) => RouteScreen(...));
}
