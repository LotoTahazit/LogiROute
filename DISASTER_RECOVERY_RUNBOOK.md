# Disaster Recovery Runbook — LogiRoute Systems Ltd.

## Инфраструктура

| Параметр | Значение |
|---|---|
| Project ID | `logiroute-app` |
| Database | `(default)` |
| Location | `nam5 (United States)` |
| Edition | Standard |
| Mode | Firestore Native |
| PITR | Enabled (7-day retention) |
| Scheduled Backups | Daily (14-day retention) |

## SLA обязательства

| Параметр | Значение |
|---|---|
| RPO (Recovery Point Objective) | ≤ 24 часа (реально < 1 час через PITR) |
| RTO (Recovery Time Objective) | ≤ 8 часов (цель) |

---

## Сценарий 1: Accidental Delete (коллекция или документы)

### Симптомы
- Пользователи сообщают об отсутствии данных
- В audit log нет записей о легитимном удалении

### Процедура восстановления (PITR)

1. Определить точное время инцидента (UTC)
2. Открыть GCP Console → Firestore → Disaster Recovery
3. Выбрать "Restore database"
4. Указать source: `(default)` database
5. Указать timestamp: момент ДО инцидента
6. Указать destination: НОВАЯ база (например `restore-YYYYMMDD`)
7. Дождаться завершения restore (зависит от размера, обычно 10-60 минут)
8. Проверить данные в новой базе
9. Скопировать нужные документы обратно в `(default)` через Admin SDK скрипт

### Команда через gcloud

```bash
# Restore на конкретный момент времени
gcloud firestore databases restore \
  --source-database="(default)" \
  --destination-database="restore-$(date +%Y%m%d)" \
  --snapshot-time="2026-02-28T10:00:00Z" \
  --project=logiroute-app
```

### Ожидаемое время: 1-4 часа (включая верификацию)

---

## Сценарий 2: Неправильный deploy Firestore Rules

### Симптомы
- Пользователи получают "Permission denied"
- Или наоборот — доступ открыт шире, чем нужно

### Процедура

1. Немедленно откатить rules:
```bash
# Посмотреть историю deployments
firebase firestore:rules:list --project=logiroute-app

# Откатить на предыдущую версию
firebase deploy --only firestore:rules --project=logiroute-app
```

2. Если текущий `firestore.rules` в репозитории корректен:
```bash
firebase deploy --only firestore:rules --project=logiroute-app
```

3. Проверить через Firebase Console → Firestore → Rules → что активная версия корректна

### Ожидаемое время: 5-15 минут

---

## Сценарий 3: Corruption данных (массовое некорректное обновление)

### Симптомы
- Данные в документах некорректны
- Статусы документов изменены неправильно

### Процедура

1. Определить scope: какие коллекции/документы затронуты
2. Определить время начала corruption
3. Использовать PITR restore в новую базу (как в Сценарии 1)
4. Написать миграционный скрипт для копирования корректных данных:

```javascript
const admin = require('firebase-admin');

// Инициализация с двумя базами
const sourceDb = admin.firestore(); // restore-YYYYMMDD
const targetDb = admin.firestore(); // (default)

// Копирование конкретной коллекции компании
async function restoreCompanyDocs(companyId, collection) {
  const snapshot = await sourceDb
    .collection('companies').doc(companyId)
    .collection(collection).get();
  
  const batch = targetDb.batch();
  snapshot.forEach(doc => {
    const targetRef = targetDb
      .collection('companies').doc(companyId)
      .collection(collection).doc(doc.id);
    batch.set(targetRef, doc.data());
  });
  await batch.commit();
}
```

### Ожидаемое время: 2-6 часов

---

## Сценарий 4: Полный project outage (Firebase/GCP)

### Симптомы
- Firebase Console недоступна
- Все сервисы проекта не отвечают

### Процедура

1. Проверить Firebase Status Dashboard: https://status.firebase.google.com
2. Проверить GCP Status: https://status.cloud.google.com
3. Если проблема на стороне Google — ждать, уведомить клиентов
4. Если проблема локальная (проект заблокирован/удалён):
   - Связаться с Google Cloud Support
   - Использовать daily backup для restore в новый проект

### Ожидаемое время: зависит от Google (вне нашего контроля)

---

## Сценарий 5: Восстановление из Daily Backup

### Когда использовать
- PITR недоступен (прошло > 7 дней)
- Нужен полный snapshot на конкретную дату

### Процедура

1. GCP Console → Firestore → Disaster Recovery → Backups
2. Выбрать нужный backup по дате
3. Actions → "Restore to new database"
4. Указать имя новой базы
5. Дождаться restore
6. Верифицировать данные
7. При необходимости — мигрировать данные в `(default)`

---

## Контакты при инциденте

| Роль | Контакт |
|---|---|
| DevOps / Admin | [указать] |
| CTO | [указать] |
| Google Cloud Support | https://cloud.google.com/support |

## Restore drill (пилот — обязательно до go-live)

**Цель:** проверить, что восстановление из бэкапа/PITR реально работает, и зафиксировать evidence в приложении (Admin → Backup → Restore drill).

> **Production restore** — только по runbook ниже, отдельное решение CTO. Drill делается в **test/staging** или в **новую базу** (`restore-YYYYMMDD`), не в `(default)` production.

### Сценарий drill (≈ 1–2 часа)

1. **Подготовка**
   - Выбрать backup: daily snapshot или PITR timestamp (см. Сценарий 1 или 5).
   - Целевая среда: новая Firestore DB `restore-YYYYMMDD` или staging-проект.
   - Зафиксировать backup в журнале: Admin → «Зарегистрировать бэкап LogiRoute Cloud».

2. **Выполнение restore (ручно, GCP)**
   ```bash
   gcloud firestore databases restore \
     --source-database="(default)" \
     --destination-database="restore-$(date +%Y%m%d)" \
     --snapshot-time="2026-06-01T12:00:00Z" \
     --project=logiroute-app
   ```
   Засечь время начала/окончания (durationMinutes).

3. **Верификация (evidence)**
   - Открыть восстановленную БД в Firebase Console или скриптом Admin SDK.
   - Проверить минимум 3 коллекции, например:
     - `companies/{pilotCompanyId}/logistics/_root/delivery_points` — count > 0
     - `companies/{pilotCompanyId}/accounting/_root/invoices` — sample doc readable
     - `companies/{pilotCompanyId}/logistics/_root/clients` — sample doc readable
   - Записать в evidenceNotes: timestamp restore, destination DB, что сравнили, результат.

4. **Журнал в приложении**
   - Admin → Backup Management → вкладка Restore tests → «Зарегистрировать restore drill».
   - Заполнить все поля (backupId, targetEnvironment, collections, duration, result, evidence).
   - **Success** только если restore + верификация прошли; иначе **Failed** с описанием ошибки.

### Что считается Success

| Критерий | Обязательно |
|----------|-------------|
| Restore завершился без ошибки GCP | ✅ |
| Данные pilot-компании читаются в целевой БД | ✅ |
| Evidence ≥ 40 символов с конкретикой | ✅ |
| durationMinutes > 0 | ✅ |
| restoredCollections перечислены | ✅ |

### При Failed

1. Зафиксировать drill с result **Failed** и evidence (ошибка gcloud, timeout, пустые коллекции).
2. Не ставить Success «на будущее».
3. Эскалация DevOps/CTO; повтор drill после fix.
4. Go-live **блокируется**, пока нет одного verified Success drill.

---

## Тестирование restore (квартальный)

**Рекомендация**: проводить restore drill раз в квартал + после крупных изменений infra.

### Чеклист:
- [ ] PITR или daily backup restore в **отдельную** базу (не production)
- [ ] Проверка delivery_points, clients, invoices pilot-компании
- [ ] Замер durationMinutes
- [ ] Запись restore drill в Admin UI с evidence
- [ ] Обновление RTO фактическими данными

### Последний verified drill: _заполнить после первого drill_
### Реальное время restore: _из поля durationMinutes журнала_

---
