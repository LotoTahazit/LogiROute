# LogiRoute — визуальные референсы конкурентов

> Источник правды по ссылкам для `docs/design-system.md`.
> **Честно об источниках:** живые авторизованные дашборды конкурентов **не скриншотились**
> (нет доступа и нельзя выдумывать кадры). Ниже — только **публичные** материалы:
> официальные блоги/доки продуктов, маркетинговые лендинги, демо-видео (с тайм-кодами),
> галереи обзорных сайтов (G2/GetApp/SoftwareAdvice/Nerdisa) и логотипы.
> Точные HEX из брендбуков у этих компаний публично **не опубликованы** — все цвета
> в гайде помечены как «приблизительно».

Дата сбора: 2026-06-30.

---

## Onfleet (last-mile dispatch)

| # | Ссылка | Что видно на UI |
|---|--------|------------------|
| O1 | [Onfleet Demo (YouTube)](https://www.youtube.com/watch?v=uC4wCJKDr7Y) — ~0:30–2:30 | Десктоп-дашборд в браузере: **карта во весь экран** с пинами, **левый сайдбар** с водителями, сгруппированными по командам (под каждым — его задачи), панель фильтров. Двойной клик по пину/строке → редактирование задачи. |
| O2 | [Onfleet Dashboard Map Gets a Refresh (blog)](https://onfleet.com/blog/onfleet-dashboard-map-gets-a-refresh/) | Скриншоты редизайна карты: трафик-слой (Google), спутник, **polygon-выделение** области, multi-pin при совпадающих адресах, переработанная панель фильтров. |
| O3 | [Introducing The New Onfleet Table View (blog)](https://onfleet.com/blog/the-new-onfleet-table-view/) | Скриншоты **табличного режима**: сортируемая таблица тысяч задач, **bulk-actions** (выделить много строк → optimize/reassign/delete), модалки с деталями задачи/водителя/получателя. |
| O4 | [Dashboard Analytics (Support)](https://support.onfleet.com/hc/en-us/articles/360023910431-Dashboard-Analytics) | Вкладка **Analyze**: левый тулбар-навигация, графики (Line/Stacked/Bar), фильтр по командам/водителям/периоду, кастомные сохранённые виды. |
| O5 | [Onfleet review + galleries (Nerdisa)](https://nerdisa.com/onfleet) | Обзорная галерея скриншотов дашборда/драйвер-апп/трекинга получателя. |

**Ключевой факт о цвете (из демо O1, прямая цитата спикера):** статусы задач на карте кодируются цветом —
**grey = unassigned, purple = assigned, blue = in transit, green = completed, red = failed**.
Это самый надёжный публичный ориентир по семантике статусов во всём бенчмарке.

---

## OptimoRoute (route planning)

| # | Ссылка | Что видно на UI |
|---|--------|------------------|
| Op1 | [Getting started for dispatchers (Help)](https://help.optimoroute.com/hc/en-us/articles/35511474016404-Getting-started-for-new-OptimoRoute-dispatchers) | Три режима: **Plan & Optimize**, **Live**, **Analytics**. Live-дашборд: слева фильтр planned/actual/both + breadcrumbs трека, справа — сводка дня (completions/failed). |
| Op2 | [View and configure the timeline (Help)](https://help.optimoroute.com/hc/en-us/articles/27713882472084-View-and-configure-the-timeline) | **Timeline-режим**: водители списком слева, время по горизонтали (15/30/60 мин), заказы — цветные плитки (цвет = цвет водителя/маршрута), число = номер остановки. Zoom/Print/Options/Edit. |
| Op3 | [Drag & Drop Timeline (marketing)](https://optimoroute.com/drag-and-drop/) | Маркетинговые скрин-кадры drag&drop тайм-лайна, undo/redo, мгновенная переоценка маршрута. |
| Op4 | [Intro to optimized route planning (Help)](https://help.optimoroute.com/hc/en-us/articles/27712119329172-Intro-to-optimized-route-planning) | **Карта** с маршрутами разных цветов и нумерованными маркерами; **таблица заказов** (driver/stop#/planned time, добавляемые колонки через стрелку у заголовка); **route summaries** (distance/duration/load). |
| Op5 | [OptimoRoute Driver (Google Play)](https://play.google.com/store/apps/details?id=com.optimoroute.optimoroute) | Скриншоты мобильного **драйвер-аппа**: карта маршрута + расписание, «focus on next task», навигация (Google/Waze/Here/Garmin), POD (подпись/фото/заметки), офлайн. |

---

## Routific (route planning, SMB)

| # | Ссылка | Что видно на UI |
|---|--------|------------------|
| R1 | [How it works (marketing)](https://www.routific.com/how-it-works) | Скриншоты: «optimize one click», drag&drop правок, dispatch в драйвер-апп; чистый минималистичный UI. |
| R2 | [Route Planning Tools (marketing)](https://www.routific.com/route-planning-tools) | **Карта-центрик**: drag&drop стопов между маршрутами, **lasso-инструмент** (обвести группу стопов), batch-edit. |
| R3 | [How to make changes to your routes (Help)](https://help.routific.com/en/articles/20-how-to-make-changes-to-your-routes) | Скриншоты: **правый route-details-панель** со списком стопов/заказов выбранного маршрута, timeline, lasso, «draw route» по карте. |
| R4 | [Routific (GetApp gallery)](https://www.getapp.com/transportation-logistics-software/a/routific/) | Галерея скриншотов + раздел «Routific's user interface». Перечень UI-возможностей (Map-Based / Timeline Route Plan View, Drag&Drop Scheduling). |
| R5 | [Routific (SoftwareAdvice)](https://www.softwareadvice.com/retail/routific-profile/) | Галерея скриншотов и демо; «визуальная наглядность стопов, понятно с первого взгляда». |
| R6 | [Routific logo breakdown (Logowik)](https://logowik.com/routific-logo-vector-77972.html) | Логотип: гексагональная «цветочная» иконка из полигонов в **синем + золотисто-оранжевом**; wordmark — насыщенный синий, rounded sans-serif lowercase. |

---

## Bringg (enterprise last-mile orchestration)

> У Bringg документация открытая, с **прямыми ссылками на PNG-скриншоты** (CDN document360).

| # | Ссылка | Что видно на UI |
|---|--------|------------------|
| B1 | [New Dispatch & Planning experience (Help)](https://help.bringg.com/docs/introducing-the-new-dispatch-and-planning-experience) | Современный модульный UI; **Unified View** карты + списков одновременно; два режима: **Route Monitor** (single-day, агрегированные KPI, timeline истории, live-трекинг) и **Order Manager** (детальные данные заказов). Кастомизируемые виды, сохранение колонок/группировок. |
| B1-img | [enroute_dispatchplanning_general2.png](https://cdn.document360.io/a18074ef-073a-4ab1-bcab-12625715280e/Images/Documentation/enroute_dispatchplanning_general2(1%29.png) · [routemonitor_scope.png](https://cdn.document360.io/a18074ef-073a-4ab1-bcab-12625715280e/Images/Documentation/enroute_routemonitor_scope(6%29.png) | Прямые скриншоты нового дашборда (карта + панели + KPI). |
| B2 | [Adjust routes with Route Planner (Help)](https://help.bringg.com/docs/adjust-routes-for-planned-orders-with-the-route-planner) | **Route Planner**: левая панель маршрутов (eye-иконка показывает маршрут на карте, по умолчанию первые 3), таблица заказов с **кастомизацией колонок** (column-иконка + grip-dots для порядка), expandable timeline/map. |
| B2-img | [planday_routeplanner_view_customize.png](https://cdn.document360.io/a18074ef-073a-4ab1-bcab-12625715280e/Images/Documentation/planday_routeplanner_view_customize.png) | Скриншот настройки колонок таблицы. |
| B3 | [Analytics / BI Dashboard (Help)](https://help.bringg.com/v1/docs/keep-track-of-kpis-with-the-analytics-dashboard) | **BI-дашборд**: виджеты из каталога, resize/reposition, несколько дашбордов во вкладках, zoom/pan по графикам, sidebar навигация (Analytics > BI Dashboard). |
| B4 | [Find an Order in Bringg (Help)](https://help.bringg.com/docs/find-an-order-in-bringg) | Экраны **Dispatch > List / Map**, **Planning**, **History**; quick-filters (late/missing address), drag колонок, группировка по Route/Driver. |
| B5 | [Bringg homepage (marketing)](https://www.bringg.com/) | Лендинг: «modular, extensible, fully configurable»; брендинг в фиолетово-синей гамме. |

---

## Сводка «откуда что взято» по осям

- **Сетка/лейаут** — O1 (map+sidebar), B1 (unified map+lists), Op1/Op2 (3 режима + timeline).
- **Таблицы** — O3 (table view, bulk, sort), Op4 (orders table + columns), B2/B4 (column customize, grip-dots, filters).
- **Карта-первичность + drag&drop** — R2/R3 (lasso, drag), Op3 (timeline drag), O2 (polygon).
- **Статусы/цвет** — O1 (grey/purple/blue/green/red — единственный твёрдый публичный факт).
- **Драйвер-апп (мобайл)** — Op5 (focus next task, навигация, POD), R1 (dispatch в апп).
- **Аналитика** — O4, B3 (виджеты, drill-in, сохранённые виды).
- **Бренд-цвета (приблизительно)** — R6 (синий+золотой Routific), B5 (фиолетовый Bringg); точные брендбуки публично недоступны.
