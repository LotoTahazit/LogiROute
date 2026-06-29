# LogiRoute — контекст для агента

> ⚠️ **СНАЧАЛА прочитай постоянную память**, прежде чем работать:
> `C:\Users\wormu\.Codex\projects\D--Projects-A-LogiRoute3\memory\MEMORY.md`
> и файлы, на которые она ссылается. Там — устойчивые решения, которых нет в коде.
> (Голый CLI сам эту папку в контекст не грузит — поэтому читай её явно.)

## Жёсткие правила
- **Отвечать пользователю только по-русски.**
- Одна фиксированная тема (без переключателя светлая/тёмная) — `lib/theme/app_theme.dart`.
- Никаких секретов в клиенте: `.env.local` попадает в web-бандл и APK. Секреты — только в `functions/.env`.

## Окружение
- `node`/`npm`/`firebase` лежат в `.tools/node/` (уже в PATH). `flutter`, `git`, `curl` — в системном PATH.
- **Не деплоить** — `firebase deploy` и сборки приложения запускает пользователь.
- Проверки: `node --check <файл>.js` (functions), `npm run test:rules` (правила), `flutter analyze` / `flutter test` (Dart).
- 3 языка l10n: he/ru/en (`lib/l10n/*.arb`), после правок — `flutter gen-l10n`.

## Бухгалтерия — РЕШЕНО окончательно (вариант B)
Две системы документов: `invoices` (диспетчер) и `accountingDocs` (owner). Подробно — в `memory/accounting-two-systems.md`.

> **ОКОНЧАТЕЛЬНО: одна система = `invoices`. `accountingDocs` УДАЛИТЬ.** (Пользователь выбрал B.)

- Уже сделано: единая нумерация (общий счётчик+цепочка), расширена модель `Invoice` (`description` + per-line `vatRate`), `InvoiceService.watchInvoices`, `Invoice.isLive`.
- ⚠️ Отдельная Cursor-сессия (без памяти) ошибочно пошла в ДРУГУЮ сторону — добавила `lib/services/accounting_registry_service.dart` (склейка обеих в просмотр, `AccountingDoc.fromInvoice`). Это **противоречит B** → `accounting_registry_service.dart` и правки в `accounting_doc.dart` / `accounting_section.dart` / `accounting_helpers.dart` будут УДАЛЕНЫ/перезаписаны при консолидации. Не развивать этот реестр.
- Осталось: **Фаза 2** — owner-UI на `InvoiceService` (owner создаёт `Invoice` без `deliveryPointId` → `createInvoice` + `IssuanceService.issueDocument(counterKey: type.canonicalCounterKey)`); **Фаза 3** — удалить `issueAccountingDoc` (+index export, `onAccountingDocIssued` если только для неё), `AccountingDocsRepository`, `AccountingIssueService`, модели `accounting_doc`/`credit_note_data`/`document_status`, `accounting_registry_service`, правила firestore для `accountingDocs`, тест.
