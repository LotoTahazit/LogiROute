# Architecture Whitepaper — LogiRoute

**Version**: 1.0
**Last Updated**: February 2026
**Classification**: Investor / Auditor

---

## 1. Overview

LogiRoute is a multi-tenant SaaS platform for billing, logistics, and financial document management, purpose-built for Israeli businesses. The system provides compliance-grade financial document handling with immutable records, sequential numbering, audit trails, and integration with the Israel Tax Authority.

### 1.1 Key Capabilities

- Financial document lifecycle management (create → finalize → print → archive)
- Israeli tax law compliance (ניהול ספרים)
- Assignment number automation (חשבוניות ישראל)
- Multi-tenant data isolation
- Real-time logistics tracking
- Inventory management

## 2. Core Architecture Principles

| Principle | Implementation |
|-----------|---------------|
| Immutability by default | Finalized documents cannot be modified or deleted |
| Server-side enforcement | Firestore Security Rules — not client-side |
| Append-only audit | All critical actions logged before execution |
| Atomic operations | Sequential numbering via transactions |
| Tenant isolation | Subcollection-based data separation |
| Defense in depth | Auth → Rules → Application → Audit |

## 3. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Flutter (Dart) | Cross-platform UI (Web, Android, iOS) |
| Backend | Firebase (Serverless) | Authentication, Database, Hosting |
| Database | Cloud Firestore | NoSQL document database |
| Auth | Firebase Authentication | User identity management |
| Storage | Google Cloud Storage | Backups, exports |
| API | Israel Tax Authority API | Assignment numbers |
| PDF | pdf + printing packages | Document generation |

## 4. Data Architecture

### 4.1 Multi-Tenant Structure

```
companies/
  {companyId}/
    invoices/{invoiceId}
      auditLog/{eventId}          ← append-only
      printEvents/{eventId}       ← append-only
    counters/{documentType}       ← atomic increment
    clients/{clientId}
    product_types/{typeId}
    inventory/{itemId}
    delivery_points/{pointId}
    assignment_requests/{reqId}   ← append-only
    integrity_chain/{chainId}     ← append-only
    integrity_anchors/{anchorId}  ← append-only
    document_links/{linkId}       ← append-only
    access_log/{logId}            ← append-only
    backups/{backupId}            ← append-only
    restore_tests/{testId}        ← append-only
    uniform_export_runs/{runId}   ← append-only
    retention_checks/{checkId}    ← append-only
    print_templates/{templateId}
    settings/{settingId}
```

### 4.2 Isolation Guarantee

- Every query scoped to `companies/{companyId}/...`
- Security Rules enforce: `user.companyId == companyId`
- No cross-tenant data access possible
- `companyId` derived from authenticated user profile

## 5. Document Lifecycle

```
┌─────────┐     ┌──────────┐     ┌───────────┐     ┌─────────┐
│  Draft   │────▶│ Finalize │────▶│  Assign   │────▶│  Print  │
│ (editable)│    │(immutable)│    │(if needed) │    │(original)│
└─────────┘     └──────────┘     └───────────┘     └─────────┘
                      │                                   │
                      ▼                                   ▼
                ┌──────────┐                        ┌─────────┐
                │  Cancel  │                        │ Reprint │
                │(reason+UID)│                      │ (copy)  │
                └──────────┘                        └─────────┘
                      │
                      ▼
                ┌──────────┐
                │Credit Note│
                │(new doc)  │
                └──────────┘
```

### 5.1 Finalization

- Assigns `finalizedAt` (server timestamp)
- Computes `immutableSnapshotHash` (SHA-256 of all protected fields + VAT totals)
- Appends to integrity chain
- Triggers assignment request (if above threshold)
- Audit event logged before operation (log-before-action)

### 5.2 Immutability Enforcement

**19 protected fields** locked after finalization:

`companyId`, `sequentialNumber`, `clientName`, `clientNumber`, `address`, `driverName`, `truckNumber`, `departureTime`, `items`, `discount`, `deliveryDate`, `paymentDueDate`, `createdAt`, `createdBy`, `documentType`, `finalizedAt`, `finalizedBy`, `immutableSnapshotHash`, `linkedInvoiceId`

**Enforcement**: Firestore Security Rules check each field individually. Works for single writes, batch writes, and transactions.

## 6. Integrity Controls

### 6.1 Hash Snapshot

SHA-256 computed from all protected fields plus financial totals:
- All 19 protected fields
- `subtotalBeforeVAT`, `vatAmount`, `totalWithVAT`
- Stored as `immutableSnapshotHash`

### 6.2 Integrity Chain

Hash-chain linking all finalized documents:

```
Document 1: chainHash = SHA256(GENESIS | docHash1 | seq1 | type1)
Document 2: chainHash = SHA256(chainHash1 | docHash2 | seq2 | type2)
Document N: chainHash = SHA256(chainHashN-1 | docHashN | seqN | typeN)
```

- Verification: `verifyChain()` validates entire chain
- Any modification to a past document breaks the chain from that point forward

### 6.3 External Anchors

Quarterly snapshots of the latest chain hash:
- Stored in `integrity_anchors` (append-only)
- Can be exported to external immutable storage (Cloud Storage signed objects)
- Verification: `verifyAnchor()` compares anchor with chain state

### 6.4 Sequential Numbering

- Atomic via Firestore Transaction (read + increment + write)
- Security Rules enforce: `lastNumber == resource.data.lastNumber + 1`
- Separate series per document type (invoice, receipt, delivery, credit note)
- Gap detection: `verifySequentialIntegrity()` with audit logging (severity: HIGH)

## 7. Security Architecture

### 7.1 Authentication Flow

```
User → Firebase Auth → JWT Token → Firestore Rules → Data
```

### 7.2 Authorization Model

```
Request → Auth Check → Role Check → Company Check → Field Check → Allow/Deny
```

### 7.3 Audit Trail

```
Action Request → Audit Log (append-only) → Execute Action → Result
         ↑                                        ↓
    log-before-action                    integrity chain update
```

## 8. Assignment Integration (חשבוניות ישראל)

### 8.1 Thresholds

| Date | Threshold (before VAT) |
|------|----------------------|
| 2025 | ₪20,000 |
| January 1, 2026 | ₪10,000 |
| June 1, 2026 | ₪5,000 |

### 8.2 Flow

```
Finalize → Check threshold → Request assignment → Retry (3x, exponential backoff)
                                                        ↓
                                              Success: store number, allow print
                                              Failure: log, manual retry available
```

### 8.3 Safeguards

- Idempotency key in API requests (prevents duplicate assignments)
- Deduplication check (skip if already approved/pending)
- Original print blocked until assignment received
- Copy printing always allowed
- Full request history in `assignment_requests`

## 9. Scalability

| Dimension | Approach |
|-----------|----------|
| Users | Firebase Auth scales automatically |
| Data | Firestore auto-scales (no capacity planning) |
| Companies | Subcollection isolation — no cross-tenant impact |
| Documents | Indexed queries with pagination |
| Regions | me-west1 with multi-AZ redundancy |

## 10. Compliance Summary

| Requirement | Status |
|-------------|--------|
| Sequential numbering | ✅ Atomic + Rules enforced |
| Document immutability | ✅ 19 protected fields + Rules |
| No deletion | ✅ `allow delete: if false` |
| Audit trail | ✅ Append-only, log-before-action |
| Print controls | ✅ Original once, reprint labeled |
| Assignment automation | ✅ Auto + retry + manual retry |
| Hash integrity | ✅ SHA-256 + chain + anchors |
| Tenant isolation | ✅ Subcollections + Rules |
| Encryption | ✅ AES-256 at-rest, TLS 1.2+ in-transit |
| Data residency | ✅ Israel (me-west1) |
| Retention | ✅ 7 years, automated checks |
| Backup | ✅ Daily + quarterly + PITR |

---

**Document Owner**: Engineering
**Approved By**: [Pending]
