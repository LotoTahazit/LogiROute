const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {
  DEMO_COMPANY_ID,
  assertDemoCompanyId,
  assertDemoCompanyDoc,
  classifyDocForStrictDelete,
  buildPurgePaths,
} = require("./demoSeedSafety");
const { rootEntitlementsPatch } = require("./lib/companyModules");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

const DEMO_EMAIL_DOMAIN = "@demofoods.logiroute.app";
const DEMO_TAG = { isDemo: true };

function getDemoPassword() {
  const pw = process.env.DEMO_SEED_PASSWORD;
  if (!pw || String(pw).length < 12) {
    throw new Error(
      "DEMO_SEED_PASSWORD env var required (min 12 chars) for demo user creation",
    );
  }
  return pw;
}
const WAREHOUSE_LAT = 32.234;
const WAREHOUSE_LNG = 34.945;

const DRIVER_FIRST = [
  "יוסי", "דוד", "משה", "אבי", "רון", "עמית", "גל", "ניר", "אור", "תומר",
];
const DRIVER_LAST = [
  "כהן", "לוי", "מזרחי", "פרץ", "אברהם", "ביטון", "דהן", "שפירא", "חדד", "עמר",
];
const CLIENT_PREFIX = [
  "מכולת", "סופר", "מסעדה", "קפה", "מלון", "בית מלון", "קייטרינג", "חנות",
];
const CITIES = [
  { name: "תל אביב", lat: 32.0853, lng: 34.7818 },
  { name: "חיפה", lat: 32.794, lng: 34.9896 },
  { name: "ירושלים", lat: 31.7683, lng: 35.2137 },
  { name: "נתניה", lat: 32.3215, lng: 34.8532 },
  { name: "ראשון לציון", lat: 31.973, lng: 34.7925 },
  { name: "אשדוד", lat: 31.8044, lng: 34.6553 },
  { name: "באר שבע", lat: 31.2518, lng: 34.7915 },
  { name: "הרצליה", lat: 32.1663, lng: 34.8436 },
  { name: "פתח תקווה", lat: 32.084, lng: 34.8878 },
  { name: "רמת גן", lat: 32.0684, lng: 34.8248 },
];
const PRODUCT_CATEGORIES = [
  "dairy", "bakery", "produce", "beverages", "frozen", "snacks", "condiments", "household",
];
const PRODUCT_TYPES_HE = ["גביע", "מכסה", "שקית", "בקבוק", "אריזה"];

async function assertSuperAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const user = await db.doc(`users/${context.auth.uid}`).get();
  if (user.data()?.role !== "super_admin") {
    throw new functions.https.HttpsError("permission-denied", "super_admin only");
  }
}

function todayMidnight() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function daysAgo(n) {
  const d = todayMidnight();
  d.setDate(d.getDate() - n);
  return d;
}

function pad(n, len = 2) {
  return String(n).padStart(len, "0");
}

function fakePhone(i) {
  return `050-${pad(200 + (i % 700))}-${pad(1000 + (i % 8999), 4)}`.slice(0, 13);
}

function jitter(base, spread, seed) {
  const r = Math.sin(seed * 12.9898) * 43758.5453;
  const f = r - Math.floor(r);
  return base + (f - 0.5) * spread;
}

async function commitBatchOps(ops) {
  for (let i = 0; i < ops.length; i += 400) {
    const batch = db.batch();
    for (const op of ops.slice(i, i + 400)) {
      if (op.type === "set") batch.set(op.ref, op.data, op.options || {});
      else if (op.type === "delete") batch.delete(op.ref);
    }
    await batch.commit();
  }
}

async function scanCollection(colRef, mode) {
  const snap = await colRef.get();
  let deletable = 0;
  let blocked = 0;
  const blockedSamples = [];
  for (const doc of snap.docs) {
    if (mode === "strict") {
      const c = classifyDocForStrictDelete(doc.data());
      if (c.deletable) deletable++;
      else {
        blocked++;
        if (blockedSamples.length < 5) {
          blockedSamples.push({ path: doc.ref.path, reason: c.reason });
        }
      }
    } else {
      deletable++;
    }
  }
  return { total: snap.size, deletable, blocked, blockedSamples };
}

async function previewDemoPurge(companyId) {
  assertDemoCompanyId(companyId);
  const companyRef = db.doc(`companies/${companyId}`);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    return {
      companyId,
      exists: false,
      safeToPurge: true,
      collections: [],
      blockedTotal: 0,
      deletableTotal: 0,
      demoAuthUsers: 0,
    };
  }
  assertDemoCompanyDoc(companySnap);

  const { strict, aux } = buildPurgePaths(companyId);
  const collections = [];
  let blockedTotal = 0;
  let deletableTotal = 0;

  for (const path of strict) {
    const stats = await scanCollection(fsCol(path), "strict");
    collections.push({ path, mode: "strict-isDemo", ...stats });
    blockedTotal += stats.blocked;
    deletableTotal += stats.deletable;
  }
  for (const path of aux) {
    const stats = await scanCollection(fsCol(path), "aux");
    collections.push({ path, mode: "aux-all", ...stats });
    deletableTotal += stats.deletable;
  }

  const demoUsersSnap = await db
    .collection("users")
    .where("companyId", "==", companyId)
    .where("isDemo", "==", true)
    .get();
  const nonDemoUsersSnap = await db
    .collection("users")
    .where("companyId", "==", companyId)
    .get();
  const blockedUsers = nonDemoUsersSnap.docs.filter(
    (d) => d.data().isDemo !== true,
  );

  let demoAuthUsers = 0;
  let pageToken;
  do {
    const list = await admin.auth().listUsers(1000, pageToken);
    demoAuthUsers += list.users.filter(
      (u) => u.email && u.email.endsWith(DEMO_EMAIL_DOMAIN),
    ).length;
    pageToken = list.pageToken;
  } while (pageToken);

  return {
    companyId,
    exists: true,
    demoCompany: true,
    safeToPurge: blockedTotal === 0 && blockedUsers.length === 0,
    collections,
    blockedTotal,
    deletableTotal,
    demoUsers: demoUsersSnap.size,
    blockedUsers: blockedUsers.length,
    blockedUserSamples: blockedUsers.slice(0, 3).map((d) => d.id),
    demoAuthUsers,
    companyDoc: 1,
  };
}

async function deleteStrictCollection(colRef) {
  const snap = await colRef.get();
  const toDelete = [];
  const blocked = [];
  for (const doc of snap.docs) {
    const c = classifyDocForStrictDelete(doc.data());
    if (c.deletable) toDelete.push(doc.ref);
    else blocked.push({ path: doc.ref.path, reason: c.reason });
  }
  if (blocked.length > 0) {
    const err = new Error("Demo purge blocked: non-demo documents found");
    err.blocked = blocked;
    throw err;
  }
  for (let i = 0; i < toDelete.length; i += 400) {
    const batch = db.batch();
    toDelete.slice(i, i + 400).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }
}

async function deleteAuxCollection(colRef) {
  const snap = await colRef.limit(400).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  return deleteAuxCollection(colRef);
}
/** Firestore path → CollectionReference (e.g. companies/x/logistics/_root/clients) */
function fsCol(path) {
  const p = path.split("/").filter(Boolean);
  let ref = db;
  for (let i = 0; i < p.length; i++) {
    ref = i % 2 === 0 ? ref.collection(p[i]) : ref.doc(p[i]);
  }
  return ref;
}

async function deleteDemoAuthUsers() {
  let pageToken;
  do {
    const list = await admin.auth().listUsers(1000, pageToken);
    for (const u of list.users) {
      if (u.email && u.email.endsWith(DEMO_EMAIL_DOMAIN)) {
        await admin.auth().deleteUser(u.uid);
      }
    }
    pageToken = list.pageToken;
  } while (pageToken);
}

async function purgeDemoCompany(companyId) {
  assertDemoCompanyId(companyId);
  const companyRef = db.doc(`companies/${companyId}`);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) return { purged: false };

  assertDemoCompanyDoc(companySnap);

  const preview = await previewDemoPurge(companyId);
  if (!preview.safeToPurge) {
    const err = new Error("Demo purge aborted: blocked documents");
    err.preview = preview;
    throw err;
  }

  const { strict, aux } = buildPurgePaths(companyId);
  for (const path of strict) {
    await deleteStrictCollection(fsCol(path));
  }
  for (const path of aux) {
    await deleteAuxCollection(fsCol(path));
  }

  const demoUsers = await db
    .collection("users")
    .where("companyId", "==", companyId)
    .where("isDemo", "==", true)
    .get();
  const userOps = demoUsers.docs.map((d) => ({ type: "delete", ref: d.ref }));
  await commitBatchOps(userOps);
  await deleteDemoAuthUsers();
  await companyRef.delete();
  return { purged: true, deletedUsers: demoUsers.size };
}
async function ensureDemoUser({ email, name, role, companyId, extra = {} }) {
  let uid;
  try {
    const existing = await admin.auth().getUserByEmail(email);
    uid = existing.uid;
    await admin.auth().updateUser(uid, { password: getDemoPassword(), displayName: name });
  } catch (_) {
    const created = await admin.auth().createUser({
      email,
      password: getDemoPassword(),
      displayName: name,
    });
    uid = created.uid;
  }
  await admin.auth().setCustomUserClaims(uid, { role, companyId, isDemo: true });
  await db.doc(`users/${uid}`).set({
    email,
    name,
    role,
    companyId,
    ...DEMO_TAG,
    ...extra,
  }, { merge: true });
  await db.doc(`companies/${companyId}/members/${uid}`).set({
    role,
    status: "active",
    ...DEMO_TAG,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: "demo-seed",
  }, { merge: true });
  return uid;
}

async function seedDemoCompany(createdByUid) {
  const companyId = DEMO_COMPANY_ID;
  const now = new Date();
  const today = todayMidnight();
  const ops = [];

  const companyRef = db.doc(`companies/${companyId}`);
  const existing = await companyRef.get();
  if (existing.exists && existing.data()?.demoCompany !== true) {
    throw new Error("Company ID reserved — not a demo company");
  }

  ops.push({
    type: "set",
    ref: companyRef,
    data: {
      nameHebrew: "מזון דמו ישראל",
      nameEnglish: "Demo Foods Israel",
      name: "Demo Foods Israel",
      billingStatus: "active",
      demoCompany: true,
      ...rootEntitlementsPatch("full"),
      ...DEMO_TAG,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: createdByUid || "demo-seed",
      trialUntil: Timestamp.fromDate(daysAgo(-365)),
    },
    options: { merge: true },
  });

  const settingsRef = db.doc(`companies/${companyId}/settings/settings`);
  ops.push({
    type: "set",
    ref: settingsRef,
    data: {
      nameHebrew: "מזון דמו ישראל",
      nameEnglish: "Demo Foods Israel",
      taxId: "514789632",
      addressHebrew: "אזור תעשייה משמרות, רחוב 12",
      addressEnglish: "Mishmarot Industrial Zone, St 12",
      city: "משמרות",
      zipCode: "4280500",
      phone: "03-555-0100",
      email: "info@demofoods.logiroute.app",
      website: "https://demofoods.logiroute.app",
      billingStatus: "active",
      departureTime: "6:30",
      requirePodPhoto: false,
      ...DEMO_TAG,
    },
    options: { merge: true },
  });

  const configRef = db.doc(`companies/${companyId}/settings/config`);
  ops.push({
    type: "set",
    ref: configRef,
    data: {
      warehouseLat: WAREHOUSE_LAT,
      warehouseLng: WAREHOUSE_LNG,
      maxPointsPerRoute: 25,
      ...DEMO_TAG,
    },
    options: { merge: true },
  });

  await commitBatchOps(ops);

  const driverCount = 10;
  const clientCount = 100;
  const productCount = 450;
  const driverUids = [];

  const staff = [
    { key: "owner", role: "owner", name: "Demo Owner" },
    { key: "admin", role: "admin", name: "Demo Admin" },
    { key: "dispatcher", role: "dispatcher", name: "Demo Dispatcher" },
    { key: "warehouse", role: "warehouse_keeper", name: "Demo Warehouse" },
    { key: "accountant", role: "accountant", name: "Demo Accountant" },
  ];
  for (const s of staff) {
    await ensureDemoUser({
      email: `demo.${s.key}${DEMO_EMAIL_DOMAIN}`,
      name: s.name,
      role: s.role,
      companyId,
    });
  }

  for (let i = 0; i < driverCount; i++) {
    const name = `${DRIVER_FIRST[i]} ${DRIVER_LAST[i]}`;
    const uid = await ensureDemoUser({
      email: `demo.driver${pad(i + 1)}${DEMO_EMAIL_DOMAIN}`,
      name,
      role: "driver",
      companyId,
      extra: {
        vehicleNumber: `${pad(10 + i)}-${pad(200 + i)}-${pad(30 + i)}`,
        palletCapacity: 18 + (i % 6),
        truckWeight: 7500 + i * 100,
      },
    });
    driverUids.push({ uid, name });
  }

  const clients = [];
  const clientOps = [];
  const clientsCol = db.collection(`companies/${companyId}/logistics/_root/clients`);
  for (let i = 0; i < clientCount; i++) {
    const city = CITIES[i % CITIES.length];
    const id = `demo-client-${pad(i + 1, 3)}`;
    const clientNumber = pad(100001 + i, 6);
    const name = `${CLIENT_PREFIX[i % CLIENT_PREFIX.length]} ${city.name} ${i + 1}`;
    const lat = jitter(city.lat, 0.08, i);
    const lng = jitter(city.lng, 0.08, i + 100);
    const data = {
      clientNumber,
      name,
      address: `רחוב ${1 + (i % 80)} ${city.name}`,
      latitude: lat,
      longitude: lng,
      phone: fakePhone(i),
      contactPerson: `איש קשר ${i + 1}`,
      companyId,
      zones: ["center"],
      paymentMethod: i % 3 === 0 ? "cash" : "credit",
      ...DEMO_TAG,
    };
    clientOps.push({ type: "set", ref: clientsCol.doc(id), data });
    clients.push({ id, clientNumber, name, address: data.address, lat, lng });
  }
  await commitBatchOps(clientOps);

  const productOps = [];
  const inventoryOps = [];
  const historyOps = [];
  const productsCol = db.collection(`companies/${companyId}/warehouse/_root/product_types`);
  const inventoryCol = db.collection(`companies/${companyId}/warehouse/_root/inventory`);
  const historyCol = db.collection(`companies/${companyId}/warehouse/_root/inventory_history`);

  for (let i = 0; i < productCount; i++) {
    const code = `DF-${pad(i + 1, 5)}`;
    const cat = PRODUCT_CATEGORIES[i % PRODUCT_CATEGORIES.length];
    const typeHe = PRODUCT_TYPES_HE[i % PRODUCT_TYPES_HE.length];
    const num = String(100 + (i % 900));
    productsCol.doc(code);
    productOps.push({
      type: "set",
      ref: productsCol.doc(code),
      data: {
        companyId,
        name: `${typeHe} ${num} ${cat}`,
        productCode: code,
        category: cat,
        unitsPerBox: 12 + (i % 24),
        boxesPerPallet: 40 + (i % 20),
        isActive: true,
        createdAt: Timestamp.fromDate(daysAgo(30 + (i % 60))),
        createdBy: "demo-seed",
        ...DEMO_TAG,
      },
    });
    const qty = 500 + (i * 17) % 5000;
    inventoryOps.push({
      type: "set",
      ref: inventoryCol.doc(code),
      data: {
        productCode: code,
        type: typeHe,
        number: num,
        quantity: qty,
        quantityPerPallet: 480,
        piecesPerBox: 12,
        lastUpdated: Timestamp.fromDate(now),
        updatedBy: "Demo Warehouse",
        barcode: `729000${pad(i + 1, 6)}`,
        ...DEMO_TAG,
      },
    });
    if (i < 40) {
      historyOps.push({
        type: "set",
        ref: historyCol.doc(`demo-hist-${pad(i + 1, 3)}`),
        data: {
          productCode: code,
          type: typeHe,
          number: num,
          quantityChange: 100 + i * 5,
          quantityBefore: qty - (100 + i * 5),
          quantityAfter: qty,
          timestamp: Timestamp.fromDate(daysAgo(i % 14)),
          userName: "Demo Warehouse",
          action: "add",
          reason: "demo inbound",
          ...DEMO_TAG,
        },
      });
    }
  }
  await commitBatchOps([...productOps, ...inventoryOps, ...historyOps]);

  const routesCol = db.collection(`companies/${companyId}/logistics/_root/routes`);
  const pointsCol = db.collection(`companies/${companyId}/logistics/_root/delivery_points`);
  const routeSpecs = [
    { status: "completed", driverIdx: 0, points: 5, completed: true },
    { status: "completed", driverIdx: 1, points: 4, completed: true },
    { status: "completed", driverIdx: 2, points: 6, completed: true },
    { status: "active", driverIdx: 3, points: 6, completed: false },
    { status: "planned", driverIdx: 4, points: 5, completed: false },
    { status: "planned", driverIdx: 5, points: 4, completed: false },
  ];

  const pointOps = [];
  const routeOps = [];
  let clientIdx = 0;
  let pendingCount = 0;

  for (let r = 0; r < routeSpecs.length; r++) {
    const spec = routeSpecs[r];
    const driver = driverUids[spec.driverIdx];
    const routeId = `demo-route-${pad(r + 1, 2)}`;
    const pointIds = [];

    for (let p = 0; p < spec.points; p++) {
      const client = clients[clientIdx % clients.length];
      clientIdx++;
      const pointId = `demo-point-${pad(r + 1, 2)}-${pad(p + 1, 2)}`;
      pointIds.push(pointId);
      let status = "assigned";
      let completedAt = null;
      let pod = {};
      if (spec.completed) {
        status = "completed";
        completedAt = Timestamp.fromDate(new Date(today.getTime() + (8 + p) * 3600000));
        if (p % 2 === 0) {
          pod = {
            podPhotoUrl: "https://placehold.co/400x300/png?text=POD+Demo",
            podLat: client.lat,
            podLng: client.lng,
            podAt: completedAt,
            podDistanceM: 12 + p,
          };
        }
      } else if (spec.status === "active" && p === 0) {
        status = "in_progress";
      } else if (spec.status === "active" && p < 2) {
        status = "completed";
        completedAt = Timestamp.fromDate(new Date());
      }

      pointOps.push({
        type: "set",
        ref: pointsCol.doc(pointId),
        data: {
          companyId,
          address: client.address,
          latitude: client.lat,
          longitude: client.lng,
          clientName: client.name,
          clientNumber: client.clientNumber,
          urgency: "normal",
          pallets: 1 + (p % 3),
          boxes: 5 + p * 2,
          status,
          orderInRoute: p + 1,
          driverId: driver.uid,
          driverName: driver.name,
          routeId,
          completedAt,
          createdAt: Timestamp.fromDate(today),
          ...pod,
          ...DEMO_TAG,
        },
      });
    }

    routeOps.push({
      type: "set",
      ref: routesCol.doc(routeId),
      data: {
        companyId,
        driverId: driver.uid,
        driverName: driver.name,
        pointIds,
        status: spec.status,
        routeDate: Timestamp.fromDate(today),
        createdAt: Timestamp.fromDate(today),
        metadata: { ...DEMO_TAG },
        ...DEMO_TAG,
      },
    });
  }

  for (let i = 0; i < 8; i++) {
    const client = clients[(clientIdx + i) % clients.length];
    pointOps.push({
      type: "set",
      ref: pointsCol.doc(`demo-pending-${pad(i + 1, 2)}`),
      data: {
        companyId,
        address: client.address,
        latitude: client.lat,
        longitude: client.lng,
        clientName: client.name,
        clientNumber: client.clientNumber,
        urgency: i % 2 === 0 ? "high" : "normal",
        pallets: 1,
        boxes: 4,
        status: "pending",
        orderInRoute: 0,
        createdAt: Timestamp.fromDate(today),
        ...DEMO_TAG,
      },
    });
    pendingCount++;
  }

  await commitBatchOps([...pointOps, ...routeOps]);

  const invoicesCol = db.collection(`companies/${companyId}/accounting/_root/invoices`);
  const invoiceOps = [];
  const docTypes = ["invoice", "receipt", "delivery", "invoice", "taxInvoiceReceipt"];
  for (let i = 0; i < 18; i++) {
    const client = clients[i * 5 % clients.length];
    const code = `DF-${pad((i * 7) % productCount + 1, 5)}`;
    invoiceOps.push({
      type: "set",
      ref: invoicesCol.doc(`demo-inv-${pad(i + 1, 3)}`),
      data: {
        companyId,
        sequentialNumber: 1000 + i,
        clientName: client.name,
        clientNumber: client.clientNumber,
        address: client.address,
        driverName: driverUids[i % driverCount].name,
        truckNumber: "12-345-67",
        deliveryDate: Timestamp.fromDate(daysAgo(i % 20)),
        departureTime: Timestamp.fromDate(today),
        items: [{
          productCode: code,
          type: "גביע",
          number: "100",
          quantity: 3 + (i % 5),
          piecesPerBox: 12,
          pricePerUnit: 8.5 + i * 0.3,
        }],
        discount: 0,
        createdAt: Timestamp.fromDate(daysAgo(i % 20)),
        createdBy: "demo-seed",
        status: i % 7 === 0 ? "draft" : "issued",
        documentType: docTypes[i % docTypes.length],
        assignmentStatus: "notRequired",
        ...DEMO_TAG,
      },
    });
  }
  await commitBatchOps(invoiceOps);

  const countersCol = db.collection(`companies/${companyId}/accounting/_root/counters`);
  const counterOps = ["tax_invoice", "receipt", "credit_note", "delivery_note", "tax_invoice_receipt"].map((key) => ({
    type: "set",
    ref: countersCol.doc(key),
    data: { lastNumber: 1020, ...DEMO_TAG },
    options: { merge: true },
  }));
  await commitBatchOps(counterOps);

  const metricsCol = db.collection(`companies/${companyId}/metrics/daily/days`);
  const metricsOps = [];
  for (let d = 0; d < 14; d++) {
    const date = daysAgo(d);
    const key = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
    metricsOps.push({
      type: "set",
      ref: metricsCol.doc(key),
      data: {
        date: key,
        deliveriesToday: 12 + (d % 8),
        invoicesThisMonth: 45 + d,
        warehouseMovements: 20 + d * 2,
        activeDrivers: 6 + (d % 4),
        printEventsToday: 3 + (d % 5),
        printErrorsToday: d % 5 === 0 ? 1 : 0,
        recordsCreatedToday: 8 + d,
        updatedAt: Timestamp.fromDate(date),
        ...DEMO_TAG,
      },
    });
  }
  await commitBatchOps(metricsOps);

  const locCol = db.collection(`companies/${companyId}/driver_locations`);
  const locOps = driverUids.slice(0, 4).map((d, i) => ({
    type: "set",
    ref: locCol.doc(d.uid),
    data: {
      driverId: d.uid,
      driverName: d.name,
      latitude: jitter(WAREHOUSE_LAT, 0.15, i),
      longitude: jitter(WAREHOUSE_LNG, 0.15, i + 50),
      updatedAt: FieldValue.serverTimestamp(),
      ...DEMO_TAG,
    },
  }));
  await commitBatchOps(locOps);

  return {
    ok: true,
    companyId,
    drivers: driverCount,
    clients: clientCount,
    products: productCount,
    routes: routeSpecs.length,
    deliveryPoints: pointOps.length,
    pendingPoints: pendingCount,
    invoices: 18,
    credentials: {
      owner: `demo.owner${DEMO_EMAIL_DOMAIN}`,
      driver1: `demo.driver01${DEMO_EMAIL_DOMAIN}`,
      dispatcher: `demo.dispatcher${DEMO_EMAIL_DOMAIN}`,
    },
  };
}

exports.DEMO_COMPANY_ID = DEMO_COMPANY_ID;
exports.seedDemoCompany = seedDemoCompany;
exports.purgeDemoCompany = purgeDemoCompany;
exports.previewDemoPurge = previewDemoPurge;

exports.createDemoCompany = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onCall(async (_data, context) => {
    await assertSuperAdmin(context);
    const companyRef = db.doc(`companies/${DEMO_COMPANY_ID}`);
    const existing = await companyRef.get();
    if (existing.exists) {
      throw new functions.https.HttpsError("already-exists", "Demo company exists — use resetDemoCompany");
    }
    return seedDemoCompany(context.auth.uid);
  });

exports.resetDemoCompany = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onCall(async (data, context) => {
    await assertSuperAdmin(context);
    if (data?.confirm !== true) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Call previewResetDemoCompany first, then reset with confirm:true",
      );
    }
    const preview = await previewDemoPurge(DEMO_COMPANY_ID);
    if (!preview.safeToPurge) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Demo purge blocked",
        preview,
      );
    }
    await purgeDemoCompany(DEMO_COMPANY_ID);
    return seedDemoCompany(context.auth.uid);
  });

exports.previewResetDemoCompany = functions
  .runWith({ timeoutSeconds: 120, memory: "512MB" })
  .https.onCall(async (_data, context) => {
    await assertSuperAdmin(context);
    return previewDemoPurge(DEMO_COMPANY_ID);
  });