# ✅ Firestore Index Fix

## Problem
Error on "מסלולים" (Routes) tab:
```
Error: [cloud_firestore/failed-precondition] 
The query requires an index. 
You can create it here: https://console.firebase.google.com/v1/r/project/logiroute-app/firestore/indexes?...
```

## Root Cause
The `getAllRoutes()` query uses compound filtering:
```dart
query = query
  .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
  .where('deliveryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
  .limit(200);
```

Firestore requires a composite index for queries with multiple `where` clauses.

## Solution Applied

### 1. Added Composite Index
Updated `firestore_indexes.json`:
```json
{
  "collectionGroup": "delivery_points",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "deliveryDate",
      "order": "ASCENDING"
    }
  ]
}
```

### 2. Deployed Index
```bash
firebase deploy --only firestore:indexes
```

## Index Build Status

⏳ **Index is being built** - This can take 5-15 minutes depending on data size.

### Check Status:
1. Go to Firebase Console: https://console.firebase.google.com/project/logiroute-app/firestore/indexes
2. Look for index: `delivery_points` → `status` + `deliveryDate`
3. Status should change from "Building" → "Enabled"

### While Waiting:
- The error will persist until index is fully built
- Other tabs (נקודות משלוח, מפה) should work fine
- Once index is ready, refresh the page

## Expected Timeline
- Small dataset (<1000 docs): 2-5 minutes
- Medium dataset (1000-10000 docs): 5-10 minutes
- Large dataset (>10000 docs): 10-15 minutes

## Verification
Once index is built:
1. Refresh the web app (Ctrl+F5)
2. Navigate to "מסלולים" tab
3. Routes should load without errors

---

**Status**: Index deployment initiated ✅
**Next**: Wait for index build to complete (check Firebase Console)
