# Demo Mode — Demo Foods Israel



Демонстрационная компания для продаж и презентаций LogiRoute без пустых экранов.



## Идентификатор



- **Company ID:** `demo-foods-israel` (единственный допустимый ID для reset)

- **Флаги:** `demoCompany: true` на документе компании; `isDemo: true` на всех seed-записях

- **Изоляция:** reset/delete только при `companyId === demo-foods-israel` **и** `demoCompany === true`



## Пароль demo-пользователей



Demo password is configured via environment variable / local setup only.



Cloud Functions / CLI:



```bash

# functions/.env или export перед deploy/seed

DEMO_SEED_PASSWORD=your-local-secret-min-12-chars

```



## Как создать demo company



### UI (super_admin)



Platform → **Создать демо-компанию**



### CLI



```bash

export DEMO_SEED_PASSWORD=...

node scripts/seed_demo_company.js

node scripts/seed_demo_company.js --dry-run   # предпросмотр purge

node scripts/seed_demo_company.js --reset     # preview + purge + seed

```



## Как сбросить demo (dry-run → confirm)



1. **previewResetDemoCompany** — показывает, что будет удалено

2. **resetDemoCompany** с `{ confirm: true }` — только если `safeToPurge === true`



UI: кнопка «Сбросить» сначала вызывает preview, затем подтверждение.



## Safety checks



| Проверка | Где |

|----------|-----|

| `companyId === demo-foods-israel` | `demoSeedSafety.js` |

| `demoCompany === true` | перед purge |

| strict-коллекции: только `isDemo === true` | purge abort при blocked |

| demo users: только `demo-foods-israel` | Firestore rules + claims `isDemo` |

| reset требует preview + `confirm: true` | CF `resetDemoCompany` |



## Роли и логины (фиктивные)



| Роль | Email |

|------|-------|

| owner | `demo.owner@demofoods.logiroute.app` |

| dispatcher | `demo.dispatcher@demofoods.logiroute.app` |

| driver 1 | `demo.driver01@demofoods.logiroute.app` |



## Ручная проверка



1. Preview reset — counts, `safeToPurge`

2. Попытка reset real company — отказ (не demo ID)

3. Demo user login — нет доступа к другим companyId

4. Документ без `isDemo` в strict-коллекции — блокирует reset

