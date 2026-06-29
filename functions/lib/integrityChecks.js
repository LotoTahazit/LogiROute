'use strict';

const crypto = require('crypto');

/**
 * Data Integrity Checker — чистая логика проверок (без Firestore).
 * Принимает снимок данных компании, возвращает список issues.
 * Дедуп/запись в Firestore — снаружи (generateIntegrityCheck.js).
 */

const SEVERITY = {
  CRITICAL: 'critical',
  HIGH: 'high',
  MEDIUM: 'medium',
  LOW: 'low',
};

const SEVERITY_ORDER = ['critical', 'high', 'medium', 'low'];

const KNOWN_ROLES = new Set([
  'owner',
  'admin',
  'super_admin',
  'dispatcher',
  'warehouse_keeper',
  'driver',
  'accountant',
  'viewer',
]);

// Статусы точек (raw из Firestore: en/he/ru варианты).
const ACTIVE_POINT_STATUSES = new Set([
  'assigned', 'הוקצה', 'назначен',
  'in_progress', 'בביצוע', 'в процессе',
]);
const DONE_POINT_STATUSES = new Set([
  'completed', 'הושלם', 'завершён', 'завершен',
  'cancelled', 'בוטל', 'отменён', 'отменен',
]);
const COMPLETED_POINT_STATUSES = new Set([
  'completed', 'הושלם', 'завершён', 'завершен',
]);

// Диапазоны валидации remote_config (зеркало CompanyRemoteConfigValidator).
const RC = {
  radiusMin: 20, radiusMax: 300,
  waitMin: 30, waitMax: 600,
  undoMin: 5, undoMax: 60,
  gpsStaleMin: 10, gpsStaleMax: 2880,
  hbMin: 15, hbMax: 120,
  sessMin: 2, sessMax: 30,
  prevMin: 5, prevMax: 100,
};

// Израиль: те же границы, что DeliveryPoint.isValidCoordinates.
function isValidIlCoords(lat, lng) {
  if (typeof lat !== 'number' || typeof lng !== 'number') return false;
  if (lat === 0 || lng === 0) return false;
  if (lat < 29.0 || lat > 34.0) return false;
  if (lng < 34.0 || lng > 36.5) return false;
  return true;
}

/** Универсальный разбор времени → millis | null. */
function tsMillis(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  if (typeof v.toMillis === 'function') return v.toMillis();
  if (typeof v._seconds === 'number') return v._seconds * 1000;
  if (typeof v.seconds === 'number') return v.seconds * 1000;
  if (v instanceof Date) return v.getTime();
  return null;
}

function num(v) {
  return typeof v === 'number' ? v : Number(v);
}

function nonEmpty(s) {
  return typeof s === 'string' && s.trim().length > 0;
}

/** Стабильный fingerprint = doc id issue. */
function fingerprint(companyId, entityType, entityId, issueCode) {
  return crypto
    .createHash('sha256')
    .update(`${companyId}|${entityType}|${entityId}|${issueCode}`, 'utf8')
    .digest('hex')
    .slice(0, 40);
}

/** Подсчёт суммы счёта до НДС (для проверки на отрицательность). */
function invoiceSubtotal(data) {
  const items = Array.isArray(data.items) ? data.items : [];
  const beforeDiscount = items.reduce((acc, it) => {
    const q = num(it && it.quantity) || 0;
    const p = num(it && it.pricePerUnit) || 0;
    return acc + q * p;
  }, 0);
  const discount = num(data.discount) || 0;
  return beforeDiscount * (1 - discount / 100);
}

/** Валидация remote_config raw. */
function validateRemoteConfig(raw) {
  const invalid = [];
  if (!raw || typeof raw !== 'object') {
    return { invalidFields: invalid, resetBelowEnter: false, bgNoLock: false };
  }
  const inRange = (key, min, max) => {
    if (!(key in raw)) return;
    const v = num(raw[key]);
    if (!(Number.isFinite(v) && v >= min && v <= max)) invalid.push(key);
  };
  inRange('autoCloseRadiusMeters', RC.radiusMin, RC.radiusMax);
  inRange('autoCloseResetRadiusMeters', RC.radiusMin, RC.radiusMax);
  inRange('autoCloseWaitSeconds', RC.waitMin, RC.waitMax);
  inRange('closeUndoSeconds', RC.undoMin, RC.undoMax);
  inRange('gpsStaleMinutes', RC.gpsStaleMin, RC.gpsStaleMax);
  inRange('driverSessionHeartbeatSeconds', RC.hbMin, RC.hbMax);
  inRange('driverSessionStaleMinutes', RC.sessMin, RC.sessMax);
  inRange('importPreviewRows', RC.prevMin, RC.prevMax);

  const radius = num(raw.autoCloseRadiusMeters);
  const reset = num(raw.autoCloseResetRadiusMeters);
  const resetBelowEnter =
    Number.isFinite(radius) && Number.isFinite(reset) && reset < radius;

  const bgNoLock =
    raw.backgroundAutoCloseEnabled === true &&
    raw.driverDeviceSessionLockEnabled === false;

  return { invalidFields: invalid, resetBelowEnter, bgNoLock };
}

/**
 * Запускает все P0-проверки.
 * @param {object} s снимок данных компании
 * @returns {Array} issues
 */
function runIntegrityChecks(s) {
  const companyId = s.companyId;
  const now = s.nowMillis || Date.now();
  const issues = [];
  const add = (entityType, entityId, issueCode, severity, title, description, metadata) => {
    issues.push({
      entityType,
      entityId: String(entityId),
      issueCode,
      severity,
      title,
      description: description || '',
      metadata: metadata || {},
    });
  };

  const users = s.users || [];
  const members = s.members || [];
  const points = s.deliveryPoints || [];
  const routes = s.routes || [];
  const invoices = s.invoices || [];
  const inventory = s.inventory || [];
  const productTypes = s.productTypes || [];
  const sessions = s.driverSessions || [];
  const locations = s.driverLocations || [];
  const syncLedger = s.syncLedger || [];

  const userById = new Map(users.map((u) => [u.id, u]));
  const memberById = new Map(members.map((m) => [m.id, m]));
  const pointById = new Map(points.map((p) => [p.id, p]));
  const routeById = new Map(routes.map((r) => [r.id, r]));
  const productTypeById = new Map(productTypes.map((p) => [p.id, p]));
  const hasUser = (id) => nonEmpty(id) && userById.has(id);

  // ===== 1. Users / Members =====
  for (const m of members) {
    if (!userById.has(m.id)) {
      add('member', m.id, 'member_without_user', SEVERITY.CRITICAL,
        'Участник без пользователя',
        'В members есть запись, но документ users отсутствует.');
    }
    const role = m.role;
    if (!nonEmpty(role) || !KNOWN_ROLES.has(role)) {
      add('member', m.id, 'invalid_role', SEVERITY.HIGH,
        'Неизвестная роль участника',
        `role="${role ?? ''}" не входит в список ролей.`);
    }
    const u = userById.get(m.id);
    if (u && nonEmpty(u.role) && nonEmpty(role) && u.role !== role) {
      add('member', m.id, 'member_user_role_mismatch', SEVERITY.HIGH,
        'Роли member и user различаются',
        `members.role="${role}" ≠ users.role="${u.role}".`,
        { memberRole: role, userRole: u.role });
    }
  }
  for (const u of users) {
    if (!memberById.has(u.id)) {
      add('user', u.id, 'user_without_member', SEVERITY.HIGH,
        'Пользователь без участника',
        'users.companyId указывает на компанию, но members отсутствует.');
    }
    if (!nonEmpty(u.role) || !KNOWN_ROLES.has(u.role)) {
      add('user', u.id, 'invalid_role', SEVERITY.HIGH,
        'Неизвестная роль пользователя',
        `role="${u.role ?? ''}" не входит в список ролей.`);
    }
  }

  // ===== 2. Delivery Points =====
  for (const p of points) {
    if (p.archived === true) continue;
    if (nonEmpty(p.companyId) && p.companyId !== companyId) {
      add('delivery_point', p.id, 'cross_tenant', SEVERITY.CRITICAL,
        'Точка из другой компании',
        `companyId="${p.companyId}" не совпадает с компанией.`,
        { companyId: p.companyId });
    }
    if (!nonEmpty(p.clientNumber) && !nonEmpty(p.clientName)) {
      add('delivery_point', p.id, 'point_without_client', SEVERITY.MEDIUM,
        'Точка без клиента',
        'Нет ни clientNumber, ни clientName.');
    }
    const status = p.status;
    const active = ACTIVE_POINT_STATUSES.has(status);
    if (active && nonEmpty(p.driverId) && !hasUser(p.driverId)) {
      add('delivery_point', p.id, 'point_assigned_missing_driver', SEVERITY.HIGH,
        'Точка назначена несуществующему водителю',
        `driverId="${p.driverId}" не найден среди пользователей.`,
        { driverId: p.driverId });
    }
    if (COMPLETED_POINT_STATUSES.has(status) && tsMillis(p.completedAt) == null) {
      add('delivery_point', p.id, 'point_completed_no_timestamp', SEVERITY.MEDIUM,
        'Завершённая точка без completedAt',
        'status=completed, но completedAt не заполнен.');
    }
    const overrideText = p.deliveryAddressOverride || p.temporaryAddress;
    if (nonEmpty(overrideText)) {
      const overrideCoords = isValidIlCoords(
        num(p.deliveryAddressOverrideLat),
        num(p.deliveryAddressOverrideLng),
      );
      const fallbackCoords = isValidIlCoords(num(p.latitude), num(p.longitude));
      if (!overrideCoords && !fallbackCoords) {
        add('delivery_point', p.id, 'point_override_no_coords', SEVERITY.MEDIUM,
          'Альтернативный адрес без координат',
          'Есть deliveryAddressOverride, но нет валидных координат и fallback.');
      }
    }
    if (active && nonEmpty(p.routeId) && !routeById.has(p.routeId)) {
      add('delivery_point', p.id, 'point_route_missing', SEVERITY.MEDIUM,
        'Точка ссылается на несуществующий маршрут',
        `routeId="${p.routeId}" не найден.`,
        { routeId: p.routeId });
    }
  }

  // ===== 3. Routes =====
  for (const r of routes) {
    const status = r.status;
    const isActive = status === 'active';
    if (!nonEmpty(r.driverId)) {
      add('route', r.id, 'route_without_driver', SEVERITY.HIGH,
        'Маршрут без водителя',
        'driverId не заполнен.');
    } else if (!hasUser(r.driverId)) {
      add('route', r.id, 'route_missing_driver', SEVERITY.HIGH,
        'Маршрут с несуществующим водителем',
        `driverId="${r.driverId}" не найден.`,
        { driverId: r.driverId });
    }
    const pointIds = Array.isArray(r.pointIds) ? r.pointIds : [];
    if (isActive && pointIds.length === 0) {
      add('route', r.id, 'route_active_no_points', SEVERITY.CRITICAL,
        'Активный маршрут без точек',
        'status=active, но pointIds пуст.');
    }
    if (isActive && pointIds.length > 0) {
      const known = pointIds.map((id) => pointById.get(id)).filter(Boolean);
      if (known.length > 0 &&
          known.every((p) => DONE_POINT_STATUSES.has(p.status))) {
        add('route', r.id, 'route_active_all_done', SEVERITY.CRITICAL,
          'Активный маршрут, но все точки закрыты',
          'status=active, но все точки completed/cancelled.');
      }
    }
  }

  // ===== 4. Invoices =====
  const ledgerByInvoice = new Map(syncLedger.map((e) => [e.id, e]));
  const ledgerInUse = syncLedger.length > 0;
  for (const inv of invoices) {
    const isLive = inv.status === 'issued' || inv.status === 'active';
    if (nonEmpty(inv.companyId) && inv.companyId !== companyId) {
      add('invoice', inv.id, 'cross_tenant', SEVERITY.CRITICAL,
        'Счёт из другой компании',
        `companyId="${inv.companyId}" не совпадает с компанией.`,
        { companyId: inv.companyId });
    }
    if (!nonEmpty(inv.clientName) && !nonEmpty(inv.clientNumber)) {
      add('invoice', inv.id,
        isLive ? 'invoice_issued_missing_client' : 'invoice_draft_missing_client',
        isLive ? SEVERITY.HIGH : SEVERITY.LOW,
        'Счёт без клиента',
        'Нет ни clientName, ни clientNumber.');
    }
    if (nonEmpty(inv.deliveryPointId) && !pointById.has(inv.deliveryPointId)) {
      add('invoice', inv.id, 'invoice_point_missing', SEVERITY.MEDIUM,
        'Счёт ссылается на несуществующую точку',
        `deliveryPointId="${inv.deliveryPointId}" не найден.`,
        { deliveryPointId: inv.deliveryPointId });
    }
    if (inv.status === 'issued' && tsMillis(inv.finalizedAt) == null) {
      add('invoice', inv.id, 'invoice_issued_no_timestamp', SEVERITY.HIGH,
        'Выписанный счёт без даты выписки',
        'status=issued, но finalizedAt не заполнен.');
    }
    if (inv.documentType !== 'creditNote' && invoiceSubtotal(inv) < 0) {
      add('invoice', inv.id, 'invoice_negative_total', SEVERITY.CRITICAL,
        'Отрицательная сумма счёта',
        'Сумма до НДС < 0, а документ не зачётный (credit_note).');
    }
    if (inv.documentType === 'creditNote' && !nonEmpty(inv.linkedInvoiceId)) {
      add('invoice', inv.id, 'credit_note_no_link', SEVERITY.HIGH,
        'Зачётный документ без ссылки',
        'creditNote без linkedInvoiceId.');
    }
    if (inv.assignmentStatus === 'rejected' || inv.assignmentStatus === 'error') {
      add('invoice', inv.id, 'assignment_failed', SEVERITY.HIGH,
        'Проблема с номером הקצאה',
        `assignmentStatus="${inv.assignmentStatus}".`,
        { assignmentStatus: inv.assignmentStatus });
    }
    if (ledgerInUse && isLive && !ledgerByInvoice.has(inv.id)) {
      add('invoice', inv.id, 'invoice_no_sync', SEVERITY.MEDIUM,
        'Счёт без статуса синхронизации',
        'Бухгалтерская интеграция активна, но записи sync нет.');
    }
  }

  // ===== 5. Inventory =====
  for (const pt of productTypes) {
    if (!nonEmpty(pt.productCode) || !nonEmpty(pt.name)) {
      add('product_type', pt.id, 'product_type_incomplete', SEVERITY.LOW,
        'Тип товара без кода/названия',
        'Отсутствует productCode или name.');
    }
  }
  for (const it of inventory) {
    if ((num(it.quantity) || 0) < 0) {
      add('inventory', it.id, 'inventory_negative_quantity', SEVERITY.MEDIUM,
        'Отрицательный остаток',
        `quantity=${it.quantity}.`,
        { quantity: it.quantity });
    }
    if (nonEmpty(it.productTypeId) && !productTypeById.has(it.productTypeId)) {
      add('inventory', it.id, 'inventory_missing_product_type', SEVERITY.LOW,
        'Остаток ссылается на несуществующий тип',
        `productTypeId="${it.productTypeId}" не найден.`,
        { productTypeId: it.productTypeId });
    }
  }

  // ===== 6. Driver GPS / Sessions =====
  const staleMinutes = num(s.sessionStaleMinutes) || 5;
  for (const sess of sessions) {
    if (sess.active !== true) continue;
    const driverId = sess.driverId || sess.userId || sess.id;
    const u = userById.get(driverId);
    if (!u || u.role !== 'driver') {
      add('driver_session', sess.id, 'session_without_driver', SEVERITY.MEDIUM,
        'Активная сессия без активного водителя',
        'Сессия active, но пользователь не водитель/не найден.',
        { driverId });
    }
    const last = tsMillis(sess.lastSeenAt);
    if (last != null && now - last > staleMinutes * 60 * 1000) {
      add('driver_session', sess.id, 'session_stale', SEVERITY.MEDIUM,
        'Зависшая активная сессия',
        `lastSeenAt старше ${staleMinutes} мин, но active=true.`,
        { staleMinutes });
    }
  }
  for (const loc of locations) {
    if (tsMillis(loc.timestamp) == null && tsMillis(loc.updatedAt) == null) {
      add('driver_location', loc.id, 'location_no_timestamp', SEVERITY.MEDIUM,
        'GPS без времени',
        'driver_location без timestamp/updatedAt.');
    }
    if (num(loc.latitude) === 0 && num(loc.longitude) === 0) {
      add('driver_location', loc.id, 'location_zero_coords', SEVERITY.MEDIUM,
        'GPS с координатами 0,0',
        'driver_location с нулевыми координатами.');
    }
  }

  // ===== 7. Accounting / Sync =====
  for (const e of syncLedger) {
    if (e.status === 'failed') {
      add('invoice', e.id, 'sync_failed', SEVERITY.HIGH,
        'Ошибка синхронизации бухгалтерии',
        `sync_ledger.status=failed${e.lastError ? `: ${e.lastError}` : ''}.`,
        { provider: e.provider || null, lastError: e.lastError || null });
    }
  }

  // ===== 8. Remote Config =====
  const rc = validateRemoteConfig(s.remoteConfig);
  if (rc.invalidFields.length > 0) {
    add('remote_config', 'remote_config', 'remote_config_invalid', SEVERITY.MEDIUM,
      'Невалидные значения remote_config',
      `Поля вне диапазона: ${rc.invalidFields.join(', ')}.`,
      { invalidFields: rc.invalidFields });
  }
  if (rc.resetBelowEnter) {
    add('remote_config', 'remote_config', 'remote_config_reset_below_enter', SEVERITY.MEDIUM,
      'reset radius меньше радиуса входа',
      'autoCloseResetRadiusMeters < autoCloseRadiusMeters.');
  }
  if (rc.bgNoLock) {
    add('remote_config', 'remote_config', 'remote_config_bg_no_lock', SEVERITY.LOW,
      'Фоновое автозакрытие без блокировки сессии',
      'backgroundAutoCloseEnabled=true, но driverDeviceSessionLockEnabled=false.');
  }

  return issues;
}

/** Сводка по severity для документа проверки. */
function summarizeBySeverity(issues) {
  const counts = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const i of issues) {
    if (counts[i.severity] != null) counts[i.severity] += 1;
  }
  return counts;
}

module.exports = {
  SEVERITY,
  SEVERITY_ORDER,
  KNOWN_ROLES,
  tsMillis,
  fingerprint,
  invoiceSubtotal,
  validateRemoteConfig,
  runIntegrityChecks,
  summarizeBySeverity,
};
