/**
 * Seed script: заполнение коллекции /product_templates/ в Firestore.
 *
 * Использование:
 *   1. Установить зависимости: cd scripts && npm install
 *   2. Настроить credentials:
 *      - export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
 *      - или использовать gcloud auth application-default login
 *   3. Запустить: npm run seed:templates
 *
 * Скрипт идемпотентен — если коллекция уже содержит документы, повторная запись не выполняется.
 */

const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const COLLECTION = 'product_templates';

/**
 * Шаблоны товаров для всех бизнес-типов.
 * Legacy-товары (из ProductTypeService.createTemplateProducts) помечены комментарием.
 * Дополнительные товары расширяют каждый businessType до 3-5 позиций.
 */
const templates = [
  // ── packaging (6 товаров) ──────────────────────────────────────────
  // Legacy
  {
    name: 'גביע 100',
    productCode: '1001',
    category: 'cups',
    unitsPerBox: 20,
    boxesPerPallet: 50,
    businessType: 'packaging',
  },
  // Legacy
  {
    name: 'גביע 250',
    productCode: '1002',
    category: 'cups',
    unitsPerBox: 20,
    boxesPerPallet: 40,
    businessType: 'packaging',
  },
  // Legacy
  {
    name: 'מכסה שטוח',
    productCode: '1030',
    category: 'lids',
    unitsPerBox: 60,
    boxesPerPallet: 40,
    businessType: 'packaging',
  },
  // New
  {
    name: 'גביע 500',
    productCode: '1003',
    category: 'cups',
    unitsPerBox: 15,
    boxesPerPallet: 35,
    businessType: 'packaging',
  },
  // New
  {
    name: 'מגש אלומיניום',
    productCode: '1040',
    category: 'trays',
    unitsPerBox: 25,
    boxesPerPallet: 30,
    businessType: 'packaging',
  },
  // New
  {
    name: 'שקית ניילון',
    productCode: '1050',
    category: 'bags',
    unitsPerBox: 100,
    boxesPerPallet: 50,
    businessType: 'packaging',
  },

  // ── food (5 товаров) ──────────────────────────────────────────────
  // Legacy
  {
    name: 'לחם לבן',
    productCode: '2001',
    category: 'bread',
    unitsPerBox: 10,
    boxesPerPallet: 30,
    weight: 0.5,
    businessType: 'food',
  },
  // Legacy
  {
    name: 'חלב 1 ליטר',
    productCode: '2002',
    category: 'dairy',
    unitsPerBox: 12,
    boxesPerPallet: 40,
    weight: 1.0,
    volume: 1.0,
    businessType: 'food',
  },
  // New
  {
    name: 'גבינה צהובה',
    productCode: '2003',
    category: 'dairy',
    unitsPerBox: 10,
    boxesPerPallet: 25,
    weight: 0.3,
    businessType: 'food',
  },
  // New
  {
    name: 'עוגיות',
    productCode: '2004',
    category: 'general',
    unitsPerBox: 24,
    boxesPerPallet: 40,
    weight: 0.2,
    businessType: 'food',
  },
  // New
  {
    name: 'מים מינרליים',
    productCode: '2005',
    category: 'bottles',
    unitsPerBox: 6,
    boxesPerPallet: 60,
    weight: 1.5,
    volume: 1.5,
    businessType: 'food',
  },

  // ── clothing (5 товаров) ──────────────────────────────────────────
  // Legacy
  {
    name: 'חולצה S',
    productCode: '3001',
    category: 'shirts',
    unitsPerBox: 10,
    boxesPerPallet: 20,
    businessType: 'clothing',
  },
  // Legacy
  {
    name: 'חולצה M',
    productCode: '3002',
    category: 'shirts',
    unitsPerBox: 10,
    boxesPerPallet: 20,
    businessType: 'clothing',
  },
  // New
  {
    name: 'חולצה L',
    productCode: '3003',
    category: 'shirts',
    unitsPerBox: 10,
    boxesPerPallet: 20,
    businessType: 'clothing',
  },
  // New
  {
    name: 'מכנסיים M',
    productCode: '3010',
    category: 'pants',
    unitsPerBox: 8,
    boxesPerPallet: 15,
    businessType: 'clothing',
  },
  // New
  {
    name: 'כובע',
    productCode: '3020',
    category: 'accessories',
    unitsPerBox: 20,
    boxesPerPallet: 30,
    businessType: 'clothing',
  },
];

/**
 * Проверяет, есть ли уже документы в коллекции.
 * @returns {Promise<number>} количество существующих документов
 */
async function getExistingCount() {
  const snapshot = await db.collection(COLLECTION).limit(1).get();
  return snapshot.size;
}

/**
 * Заливает шаблоны в Firestore через batch write.
 */
async function seedTemplates() {
  console.log('🚀 Seed: product_templates');
  console.log(`   Проект: ${admin.app().options.projectId || '(default)'}`);
  console.log(`   Коллекция: /${COLLECTION}/`);
  console.log(`   Шаблонов к записи: ${templates.length}`);
  console.log('');

  // Идемпотентность: проверяем, есть ли уже данные
  const existingCount = await getExistingCount();
  if (existingCount > 0) {
    console.log(`⚠️  Коллекция /${COLLECTION}/ уже содержит документы.`);
    console.log('   Повторная запись пропущена. Удалите коллекцию вручную, если нужно перезалить.');
    process.exit(0);
  }

  // Firestore batch limit = 500, у нас ~16 документов — один batch достаточно
  const batch = db.batch();

  for (const template of templates) {
    const docRef = db.collection(COLLECTION).doc(); // auto-ID
    batch.set(docRef, template);
  }

  await batch.commit();

  // Вывод результата по бизнес-типам
  const byType = {};
  for (const t of templates) {
    if (!byType[t.businessType]) byType[t.businessType] = [];
    byType[t.businessType].push(t);
  }

  console.log('✅ Успешно записано:');
  for (const [type, items] of Object.entries(byType)) {
    console.log(`\n   📦 ${type} (${items.length} товаров):`);
    for (const item of items) {
      const extras = [];
      if (item.weight != null) extras.push(`weight=${item.weight}`);
      if (item.volume != null) extras.push(`volume=${item.volume}`);
      const extrasStr = extras.length > 0 ? ` [${extras.join(', ')}]` : '';
      console.log(`      - ${item.name} (${item.productCode}) | ${item.category} | ${item.unitsPerBox}×${item.boxesPerPallet}${extrasStr}`);
    }
  }

  console.log(`\n🎉 Итого: ${templates.length} шаблонов в /${COLLECTION}/`);
}

// Запуск
seedTemplates()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('❌ Ошибка:', err.message);
    process.exit(1);
  });
