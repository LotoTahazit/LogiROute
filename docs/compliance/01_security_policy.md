# Security Policy — LogiRoute Billing System

**Version**: 1.0
**Last Updated**: February 2026
**Classification**: Confidential

---

## 1. Purpose

This document defines the security controls, data protection mechanisms, and access policies governing the LogiRoute billing and document management system. It applies to all system components, users, and data processed by the platform.

## 2. Scope

- All financial documents (invoices, receipts, delivery notes, credit notes)
- All user accounts and authentication
- All audit trails and access logs
- All backup and recovery operations
- All API integrations (Israel Tax Authority)

## 3. Data Classification

| Classification | Examples | Protection Level | Retention |
|---------------|----------|-----------------|-----------|
| Financial | Invoices, credit notes, receipts | Highest — immutable after finalization | 7 years minimum |
| Personal | Client names, addresses, contact info | High — encrypted, access-controlled | 7 years minimum |
| Operational | Routes, delivery points, inventory | Medium — access-controlled | Per business need |
| Audit | Audit logs, access logs, print events | High — append-only, immutable | 7 years minimum |
| System | Counters, integrity chain, anchors | High — append-only or atomic-only | 7 years minimum |

## 4. Encryption

| Layer | Standard | Implementation |
|-------|----------|---------------|
| Data in transit | TLS 1.2+ | Firebase HTTPS (enforced, no HTTP fallback) |
| Data at rest | AES-256 | Google Cloud Firestore (managed encryption keys) |
| Backup storage | AES-256 | Google Cloud Storage, region me-west1 |
| Authentication tokens | RS256 JWT | Firebase Authentication |

## 5. Access Control

### 5.1 Role-Based Access Control (RBAC)

| Role | Financial Docs | Inventory | Users | Settings | Audit Logs |
|------|---------------|-----------|-------|----------|------------|
| super_admin | Full | Full | Full | Full | Read |
| admin | Full (own company) | Full | Create/Edit | Full | Read |
| dispatcher | Create/Read/Cancel | Read | — | — | — |
| driver | — | — | Own profile | — | — |
| warehouse_keeper | — | Full | — | — | — |

### 5.2 Enforcement

- **Server-side**: Firestore Security Rules — legally binding enforcement
- **Client-side**: Application-level checks — UX convenience only
- **Principle**: Least privilege — each role receives minimum required permissions

### 5.3 Tenant Isolation

- All data stored in subcollections: `companies/{companyId}/...`
- Security Rules enforce: `user.companyId == companyId`
- No cross-company queries possible
- `companyId` derived from authenticated user profile, never from client input

## 6. Authentication

| Property | Value |
|----------|-------|
| Provider | Firebase Authentication |
| Methods | Email/Password |
| Token type | JWT (RS256) |
| Token expiry | 1 hour (auto-refresh) |
| Anonymous access | Prohibited (`request.auth != null` on all rules) |
| Session management | Firebase SDK managed |

## 7. Document Immutability

### 7.1 Protected Fields (19 fields)

After finalization, the following fields cannot be modified:

`companyId`, `sequentialNumber`, `clientName`, `clientNumber`, `address`, `driverName`, `truckNumber`, `departureTime`, `items`, `discount`, `deliveryDate`, `paymentDueDate`, `createdAt`, `createdBy`, `documentType`, `finalizedAt`, `finalizedBy`, `immutableSnapshotHash`, `linkedInvoiceId`

### 7.2 Enforcement Mechanism

```
Firestore Security Rules enforce field-level immutability regardless of
write method (single write / batch write / transaction). Each document
in a batch is validated independently against the rules.
```

### 7.3 Whitelist Fields (allowed after finalization)

`lastViewedAt`, `printedCount`, `exportedAt`, `originalPrinted`, `copiesPrinted`, `status` (only active→cancelled), `assignmentNumber`, `assignmentStatus`, `assignmentRequestedAt`, `assignmentResponseRaw`

### 7.4 Deletion Policy

- Financial documents: `allow delete: if false` — deletion permanently prohibited
- Audit logs: `allow delete: if false` — append-only
- Print events: `allow delete: if false` — append-only
- Integrity chain: `allow delete: if false` — append-only
- Counters: `allow delete: if false`

## 8. Integrity Controls

| Control | Implementation |
|---------|---------------|
| Hash snapshot | SHA-256 of all protected fields + VAT totals |
| Integrity chain | Hash-chain linking all finalized documents |
| External anchors | Quarterly snapshots of chain state |
| Sequential numbering | Atomic transactions + Rules (increment == 1) |
| Gap detection | `verifySequentialIntegrity()` with audit logging |
| Chain verification | `verifyChain()` validates entire chain |

## 9. Audit Logging

| Property | Value |
|----------|-------|
| Storage | Subcollection: `invoices/{id}/auditLog/{eventId}` |
| Mutability | Append-only (create only, update/delete prohibited) |
| Actor verification | `actorUid == request.auth.uid` (enforced by Rules) |
| Timestamps | `FieldValue.serverTimestamp()` (server clock, not client) |
| Pattern | Log-before-action (audit written before operation) |

### 9.1 Logged Events

Created, Finalized, Printed, Exported, Cancelled, Credit Note Created, Status Changed, Technical Update

## 10. Access Logging

| Property | Value |
|----------|-------|
| Storage | `companies/{companyId}/access_log/{logId}` |
| Mutability | Append-only |
| Events | Login, Logout, View Document, Print, Export, Admin Action |
| Actor verification | `actorUid == request.auth.uid` |

## 11. Print Security

| Control | Implementation |
|---------|---------------|
| Original copy | One-time only (`originalPrinted` flag) |
| Reprint label | Date/time stamp on reprinted copies |
| Draft marking | "טיוטה — לא לשימוש רשמי" on draft documents |
| Assignment blocking | Original print blocked until assignment number received (above threshold) |
| Export bypass | Not possible — PDF generation only through PrintService |

## 12. Monitoring & Alerting

| Monitor | Trigger | Action |
|---------|---------|--------|
| Sequential gap | Gap detected in numbering | Audit event (severity: HIGH) |
| Assignment failure | API timeout/rejection | Audit event + manual retry available |
| Integrity chain break | Chain verification failure | Alert to admin |
| Backup overdue | Quarterly backup missing | Alert to admin |

## 13. Data Residency

| Component | Location | Region |
|-----------|----------|--------|
| Primary database | Google Cloud Firestore | me-west1 (Tel Aviv, Israel) |
| Backups | Google Cloud Storage | me-west1 (Tel Aviv, Israel) |
| Authentication | Firebase Auth | Global (Google infrastructure) |

**All financial data is stored in Israel.**

## 14. Third-Party Dependencies

| Dependency | Purpose | Risk Level |
|------------|---------|------------|
| Google Firebase | Infrastructure | Low (Google SLA) |
| Israel Tax Authority API | Assignment numbers | Medium (government dependency) |

## 15. Security Review Schedule

| Activity | Frequency |
|----------|-----------|
| Access log review | Quarterly |
| Security Rules review | After each change |
| Penetration testing | Annually (planned) |
| Policy review | Annually |
| Integrity chain verification | Quarterly |

---

**Document Owner**: System Administrator
**Approved By**: [Pending]
