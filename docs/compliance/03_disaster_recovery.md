# Disaster Recovery Plan — LogiRoute

**Version**: 1.0
**Last Updated**: February 2026
**Classification**: Internal — Confidential

---

## 1. Recovery Objectives

| Metric | Target | Justification |
|--------|--------|---------------|
| RPO (Recovery Point Objective) | < 1 hour | PITR available; quarterly backups as fallback |
| RTO (Recovery Time Objective) | < 4 hours | Maximum acceptable downtime for financial operations |
| Data durability | 99.999999999% | Google Cloud Firestore SLA |

## 2. Infrastructure Overview

| Component | Provider | Region | Redundancy |
|-----------|----------|--------|------------|
| Database | Google Cloud Firestore | me-west1 (Tel Aviv) | 3 availability zones |
| Authentication | Firebase Auth | Global | Multi-region |
| Storage | Google Cloud Storage | me-west1 | Regional redundancy |
| Application | Firebase Hosting | Global CDN | Multi-region |

## 3. Backup Strategy

| Type | Frequency | Retention | Location | Verification |
|------|-----------|-----------|----------|-------------|
| Firestore Automatic | Daily | 7 days | me-west1 | Automatic |
| PITR (Point-in-Time Recovery) | Continuous | 7 days | me-west1 | On-demand |
| Compliance Backup | Quarterly (week 1 of Q) | 7 years | GCS me-west1 | Quarterly restore test |

### 3.1 Backup Verification

- **Frequency**: Quarterly
- **Record**: `companies/{companyId}/restore_tests/{testId}`
- **Includes**: Success/failure, document count, restore duration
- **Post-restore validation**:
  - `verifyChain()` — integrity chain validation
  - `verifySequentialIntegrity()` — numbering gap detection
  - `verifyAnchor()` — external anchor comparison
  - Manual spot-check of 10 random documents

## 4. Disaster Scenarios

### 4.1 Scenario A — Database Corruption / Data Loss

| Property | Value |
|----------|-------|
| Probability | Very low (Firestore multi-region) |
| Impact | Critical — no access to financial data |
| Recovery method | PITR or quarterly backup restore |
| RTO | 2–4 hours |

**Recovery Steps:**
1. **Detect**: Monitoring alerts (integrity chain break, missing data)
2. **Assess**: Determine scope — which companies/documents affected
3. **Decide**: Choose recovery point (PITR preferred, backup as fallback)
4. **Restore**: Execute Firestore PITR restore to last known good state
5. **Validate**:
   - Run `verifyChain()` on all affected companies
   - Run `verifySequentialIntegrity()` for all document types
   - Verify latest external anchor matches chain state
   - Manual spot-check of 10 documents per company
6. **Resume**: Restore service access
7. **Notify**: Inform affected customers within 4 hours
8. **Post-mortem**: Root cause analysis within 48 hours

### 4.2 Scenario B — Authentication Service Outage

| Property | Value |
|----------|-------|
| Probability | Low (Google SLA 99.95%) |
| Impact | High — users cannot log in |
| Recovery method | Wait for Google + local cache |
| RTO | 1–2 hours (dependent on Google) |

**Recovery Steps:**
1. **Detect**: User reports + Firebase status page monitoring
2. **Verify**: Check status.firebase.google.com
3. **Communicate**: Notify customers of known issue
4. **Wait**: Firebase Auth recovery is Google-managed
5. **Verify**: Confirm authentication restored
6. **Communicate**: Update customers

### 4.3 Scenario C — Israel Tax Authority API Outage

| Property | Value |
|----------|-------|
| Probability | Medium |
| Impact | Medium — cannot print originals above threshold |
| Recovery method | Automatic retry + manual retry |
| RTO | Dependent on Tax Authority |

**Recovery Steps:**
1. **Automatic**: 3 retries with exponential backoff (2s, 4s, 8s)
2. **Status**: Set to `error` — logged in audit trail
3. **User action**: Manual retry button available in UI
4. **Workaround**: Copy printing allowed (not originals)
5. **Post-recovery**: Batch retry all pending assignments

### 4.4 Scenario D — Security Breach

| Property | Value |
|----------|-------|
| Probability | Low (Rules + Auth + Tenant Isolation) |
| Impact | Critical — potential data exposure |
| Recovery method | Incident Response Plan |
| RTO | Variable |

**Recovery Steps:**
1. **Detect**: Audit log anomalies, access log patterns
2. **Contain**: Disable compromised accounts immediately
3. **Assess**: Determine scope of breach
4. **Validate**: Run integrity checks on affected data
5. **Remediate**: Patch vulnerability, update Rules if needed
6. **Notify**: Affected customers within 24 hours (72 hours for GDPR)
7. **Report**: To privacy authority if required
8. **Post-mortem**: Full incident report

## 5. DR Team

| Role | Responsibility | Contact Method |
|------|---------------|----------------|
| System Administrator | DR activation, customer communication | Phone + Email |
| Lead Developer | Technical recovery, integrity validation | Phone + Email |
| Accountant | Financial data verification post-restore | Email |

## 6. Communication Plan

| Audience | Channel | Timing |
|----------|---------|--------|
| Internal team | Phone/Chat | Immediate |
| Affected customers | Email + In-app | Within 4 hours (P1) |
| All customers | Email | Within 24 hours (P1) |
| Regulatory (if required) | Formal letter | Within 72 hours |

## 7. Testing Schedule

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Backup restore test | Quarterly | System Administrator |
| Integrity chain verification | Quarterly | System Administrator |
| External anchor verification | Quarterly | System Administrator |
| Full DR simulation | Annually | DR Team |
| DR plan review | Annually | DR Team |

## 8. Recovery Validation Checklist

- [ ] All companies accessible
- [ ] Integrity chain valid (`verifyChain()`)
- [ ] Sequential numbering intact (`verifySequentialIntegrity()`)
- [ ] External anchor matches (`verifyAnchor()`)
- [ ] Audit logs intact (append-only verified)
- [ ] Print events intact
- [ ] Counter values correct
- [ ] 10 random documents spot-checked per company
- [ ] Authentication working
- [ ] Assignment API responsive

---

**Document Owner**: System Administrator
**Approved By**: [Pending]
