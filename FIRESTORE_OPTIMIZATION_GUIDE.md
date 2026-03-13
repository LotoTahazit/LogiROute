# Firestore Cost Optimization Guide
# מדריך אופטימיזציה של עלויות Firestore

## 🚨 Current Issues Found

### Critical Problems (High Cost Impact)

#### 1. Unlimited Queries Without Pagination
❌ **FOUND IN:**
- `invoice_service.dart`: `getAllInvoices()` - no limit
- `client_service.dart`: `getAllClients()` - no limit  
- `price_service.dart`: `getAllPrices()` - no limit
- `inventory_service.dart`: `getInventory()` - no limit
- `box_type_service.dart`: `getAllBoxTypes()` - no limit

**Cost Impact:** 🔴 HIGH - Every document read = 1 read operation

#### 2. Realtime Listeners on Large Collections
❌ **FOUND IN:**
- `route_service.dart`: `snapshots()` on all delivery_points
- `price_service.dart`: `getPricesStream()` on all prices
- `inventory_service.dart`: `getInventoryStream()` on all inventory
- `location_service.dart`: `getAllDriverLocationsStream()` on all drivers

**Cost Impact:** 🔴 CRITICAL - Every change triggers reads for ALL listeners

#### 3. No Data Separation (Immutable vs Live Status)
❌ **FOUND IN:**
- Invoices: status mixed with immutable data
- Delivery points: GPS updates in same document as route data
- No separate "active" vs "archive" collections

**Cost Impact:** 🔴 HIGH - Updating status triggers reads of entire document

## ✅ Solution 1: Pagination & Limits

### Implementation Pattern

```dart
// ❌ BAD - Unlimited query
Future<List<Invoice>> getAllInvoices() async {
  final snapshot = await _firestore.collection('invoices').get();
  return snapshot.docs.map((doc) => Invoice.fromMap(doc.data(), doc.id)).toList();
}

// ✅ GOOD - Paginated query
Future<List<Invoice>> getInvoices({
  int limit = 20,
  DocumentSnapshot? startAfter,
  DateTime? fromDate,
}) async {
  Query query = _firestore
      .collection('invoices')
      .where('status', isEqualTo: 'active')
      .orderBy('createdAt', descending: true)
      .limit(limit);
  
  if (fromDate != null) {
    query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
  }
  
  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }
  
  final snapshot = await query.get();
  return snapshot.docs.map((doc) => Invoice.fromMap(doc.data(), doc.id)).toList();
}
```

### Files to Update

1. **invoice_service.dart**
   - Add pagination to `getAllInvoices()`
   - Add date filter (today, this week, this month)
   - Default limit: 50

2. **route_service.dart**
   - Add date filter to delivery points
   - Separate "today" vs "archive"
   - Default limit: 100

3. **client_service.dart**
   - Already has limit(10) in search ✅
   - Add pagination to `getAllClients()`

4. **price_service.dart**
   - Prices are relatively static - OK to load all
   - But add caching layer

5. **inventory_service.dart**
   - Add pagination for large inventories
   - Filter by type/status

## ✅ Solution 2: Separate Immutable Data from Live Status

### Architecture Pattern

```
invoices/{invoiceId}
  - sequentialNumber (immutable)
  - clientName (immutable)
  - items (immutable)
  - createdAt (immutable)
  - ... all invoice data

invoice_status/{invoiceId}
  - status: "active" | "cancelled"
  - printedCount: 3
  - lastPrinted: timestamp
  - lastModified: timestamp

delivery_points/{pointId}
  - clientName (immutable)
  - address (immutable)
  - items (immutable)
  - driverId (semi-mutable)
  - orderInRoute (semi-mutable)

delivery_status/{pointId}
  - status: "pending" | "assigned" | "in_progress" | "completed"
  - currentLocation: {lat, lng}
  - eta: timestamp
  - lastUpdated: timestamp

driver_locations/{driverId}
  - currentLocation: {lat, lng}
  - lastUpdated: timestamp
  - speed: number
  - heading: number
```

### Benefits
- Listen to small status docs (100 bytes) instead of full docs (5KB+)
- Immutable docs never trigger listener updates
- Can cache immutable data aggressively

## ✅ Solution 3: Aggregates & Summary Documents

### Daily Summary Pattern

```dart
// Instead of querying all invoices for dashboard
daily_summaries/{yyyy-mm-dd}
  - totalInvoices: 45
  - totalAmount: 125000
  - byStatus: {
      active: 42,
      cancelled: 3
    }
  - byDriver: {
      driver1: 15,
      driver2: 20,
      ...
    }
  - lastUpdated: timestamp

// Update via Cloud Function or transaction
Future<void> _updateDailySummary(Invoice invoice) async {
  final dateKey = DateFormat('yyyy-MM-dd').format(invoice.createdAt);
  final summaryRef = _firestore.collection('daily_summaries').doc(dateKey);
  
  await _firestore.runTransaction((transaction) async {
    final summary = await transaction.get(summaryRef);
    
    if (!summary.exists) {
      transaction.set(summaryRef, {
        'totalInvoices': 1,
        'totalAmount': invoice.totalWithVAT,
        'byStatus': {invoice.status.name: 1},
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      transaction.update(summaryRef, {
        'totalInvoices': FieldValue.increment(1),
        'totalAmount': FieldValue.increment(invoice.totalWithVAT),
        'byStatus.${invoice.status.name}': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  });
}
```

### Active List Pattern

```dart
// For dispatcher dashboard - only active items
active_deliveries/{officeId}
  - pointIds: [id1, id2, id3, ...] // max 50
  - lastUpdated: timestamp
  - count: 45

// UI loads skeleton first, then details on demand
Future<List<DeliveryPoint>> getActiveDeliveries() async {
  // 1 read for active list
  final activeList = await _firestore
      .collection('active_deliveries')
      .doc('main_office')
      .get();
  
  final pointIds = activeList.data()?['pointIds'] as List<String>? ?? [];
  
  // Load only visible items (e.g., first 20)
  final visibleIds = pointIds.take(20).toList();
  
  // Batch read - more efficient than individual reads
  final points = await Future.wait(
    visibleIds.map((id) => 
      _firestore.collection('delivery_points').doc(id).get()
    )
  );
  
  return points
      .where((doc) => doc.exists)
      .map((doc) => DeliveryPoint.fromMap(doc.data()!, doc.id))
      .toList();
}
```

## 📊 Cost Estimation for Your Case

### Current Architecture (Worst Case)
```
Scenario: 50 invoices/day, 5 dispatchers watching realtime

Daily reads:
- 5 dispatchers × snapshots() on all invoices
- Each invoice update = 5 reads (one per listener)
- 50 invoices × 5 listeners = 250 reads/day just from listeners
- Plus initial loads, refreshes, etc.

Monthly: ~10,000 reads minimum
Cost: ~$0.36/month (within free tier)
```

### Optimized Architecture
```
Daily reads:
- 5 dispatchers × listen to daily_summary (1 doc)
- Each invoice update = 5 reads of summary (tiny doc)
- Load full invoices only on demand (20 at a time)
- Archive queries use get() not snapshots()

Monthly: ~2,000 reads
Cost: ~$0.07/month (5x cheaper)
```

### At Scale (500 invoices/day)
```
Current: ~100,000 reads/month = $3.60/month
Optimized: ~20,000 reads/month = $0.72/month

Savings: 80% reduction
```

## 🎯 Priority Implementation Plan

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Add limits to all queries (default 50)
2. ✅ Add date filters (today, this week, this month)
3. ✅ Replace snapshots() with get() for archives
4. ✅ Add pagination to invoice list

### Phase 2: Architecture Changes (4-6 hours)
1. ✅ Create invoice_status collection
2. ✅ Create delivery_status collection
3. ✅ Migrate status updates to separate docs
4. ✅ Update UI to listen to status docs only

### Phase 3: Aggregates (2-3 hours)
1. ✅ Create daily_summaries collection
2. ✅ Add Cloud Function to update summaries
3. ✅ Update dashboard to use summaries
4. ✅ Create active_deliveries index

### Phase 4: GPS Optimization (3-4 hours)
1. ✅ Separate driver_locations from user profiles
2. ✅ Batch GPS updates (every 30 seconds, not every second)
3. ✅ Use separate collection for location history
4. ✅ Auto-cleanup old location data (>24 hours)

## 🔧 Specific Code Changes Needed

### 1. invoice_service.dart
```dart
// Add these methods:
- getRecentInvoices(limit: 50, fromDate: today)
- getInvoicesPaginated(limit: 20, startAfter: lastDoc)
- getInvoiceStatus(invoiceId) // from invoice_status collection
- updateInvoiceStatus(invoiceId, status) // update status doc only
```

### 2. route_service.dart
```dart
// Change:
- getActiveRoutesStream() → add .where('date', isEqualTo: today)
- getPendingPointsStream() → add .limit(100)
- getAllPointsForMapTesting() → remove or add date filter

// Add:
- getDeliveryStatus(pointId)
- updateDeliveryStatus(pointId, status)
- getDailySummary(date)
```

### 3. location_service.dart
```dart
// Change:
- Batch GPS updates (buffer 30 seconds)
- Don't update if location hasn't changed significantly (>50m)
- Use separate collection for history

// Add:
- cleanupOldLocations() // delete >24h old
```

## 📈 Monitoring & Alerts

### Set Up Billing Alerts
```
1. Go to Google Cloud Console
2. Billing → Budgets & alerts
3. Set alert at $5/month
4. Set hard limit at $10/month
```

### Monitor Firestore Usage
```
1. Firestore Console → Usage tab
2. Watch for:
   - Reads per day
   - Document writes
   - Snapshot listeners count
3. Set up daily email reports
```

### Add Logging
```dart
// Add to each service
void _logQuery(String operation, int docCount) {
  print('📊 [Firestore] $operation: $docCount docs');
  // Send to analytics if needed
}
```

## 🚫 Anti-Patterns to Avoid

### 1. Never Do This
```dart
// ❌ Listen to entire collection
_firestore.collection('invoices').snapshots()

// ❌ Update document every second
Timer.periodic(Duration(seconds: 1), (_) {
  _firestore.collection('locations').doc(id).update({...});
});

// ❌ Load all data then filter in memory
final all = await _firestore.collection('items').get();
final filtered = all.docs.where((doc) => doc.data()['status'] == 'active');
```

### 2. Always Do This
```dart
// ✅ Listen to filtered, limited query
_firestore
  .collection('invoices')
  .where('date', isEqualTo: today)
  .where('status', isEqualTo: 'active')
  .limit(50)
  .snapshots()

// ✅ Batch updates
final batch = _firestore.batch();
for (final update in updates) {
  batch.update(ref, update);
}
await batch.commit();

// ✅ Filter on server
_firestore
  .collection('items')
  .where('status', isEqualTo: 'active')
  .get()
```

## 📚 Resources

- [Firestore Pricing](https://firebase.google.com/docs/firestore/quotas)
- [Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Query Optimization](https://firebase.google.com/docs/firestore/query-data/queries)

---

**Next Steps:**
1. Review current queries (this document)
2. Implement Phase 1 (quick wins)
3. Test with monitoring enabled
4. Implement Phase 2-4 based on actual usage

**Estimated Savings:** 70-90% reduction in Firestore costs
