# Service Level Agreement (SLA) — LogiRoute

**Version**: 1.0
**Last Updated**: February 2026
**Classification**: Customer-Facing

---

## 1. Service Description

LogiRoute provides a cloud-based billing, logistics, and document management platform for Israeli businesses. The service includes financial document generation, sequential numbering, print management, and Israel Tax Authority integration.

## 2. Availability

| Metric | Target |
|--------|--------|
| Monthly uptime | 99.9% |
| Maximum planned downtime | 4 hours/month |
| Annual downtime budget | ~8.7 hours |

### 2.1 Uptime Calculation

```
Uptime % = ((Total Minutes - Downtime Minutes) / Total Minutes) × 100
```

Planned maintenance windows are excluded from downtime calculation.

### 2.2 Component-Level SLA

| Component | SLA | Dependency |
|-----------|-----|------------|
| Web application | 99.9% | LogiRoute |
| Database (Firestore) | 99.999% | Google Cloud |
| Authentication (Firebase Auth) | 99.95% | Google Cloud |
| Israel Tax Authority API | Best-effort | Government |

## 3. Support Hours

| Tier | Hours | Channel |
|------|-------|---------|
| Standard | Sunday–Thursday 09:00–18:00 IST | Email, In-app |
| Critical incidents | 24/7 | Phone, Email |

## 4. Incident Response Targets

| Severity | Description | Response Time | Resolution Target |
|----------|-------------|---------------|-------------------|
| P1 — Critical | System down / data loss | 1 hour | 4 hours |
| P2 — High | Cannot create/print documents | 4 hours | 12 hours |
| P3 — Medium | Non-critical feature failure | 1 business day | 3 business days |
| P4 — Low | Enhancement request / cosmetic bug | 3 business days | Per roadmap |

### 4.1 Severity Definitions

- **P1 — Critical**: Complete service outage, data loss, or data integrity breach affecting financial documents
- **P2 — High**: Core functionality impaired (document creation, printing, assignment) but system accessible
- **P3 — Medium**: Non-core feature failure, workaround available
- **P4 — Low**: Cosmetic issues, enhancement requests, documentation

## 5. Backup & Recovery

| Metric | Value |
|--------|-------|
| RPO (Recovery Point Objective) | < 1 hour (PITR), < 24 hours (quarterly backup) |
| RTO (Recovery Time Objective) | < 4 hours |
| Backup frequency | Daily (automatic) + Quarterly (compliance) |
| Backup verification | Quarterly restore test |
| Backup location | Google Cloud Storage, me-west1 (Israel) |

## 6. Data Durability

| Property | Value |
|----------|-------|
| Storage | Google Cloud Firestore (multi-region replication) |
| Durability | 99.999999999% (11 nines) |
| Availability zones | 3 (automatic failover) |
| Data residency | Israel (me-west1) |

## 7. Maintenance Windows

| Property | Value |
|----------|-------|
| Preferred window | Friday 02:00–06:00 IST |
| Advance notice | 48 hours minimum |
| Emergency maintenance | Immediate (with notification) |
| Frequency | As needed, typically monthly |

## 8. Service Credits

| Actual Uptime | Credit |
|---------------|--------|
| 99.0% – 99.9% | 10% of monthly fee |
| 95.0% – 99.0% | 25% of monthly fee |
| 90.0% – 95.0% | 50% of monthly fee |
| Below 90.0% | 100% of monthly fee |

### 8.1 Credit Request Process

1. Customer submits credit request within 30 days of incident
2. LogiRoute verifies downtime from monitoring data
3. Credit applied to next billing cycle

### 8.2 Exclusions

Service credits do not apply to:
- Israel Tax Authority API outages
- Google Cloud infrastructure failures beyond LogiRoute's control
- Customer-caused issues (misconfiguration, unauthorized access)
- Force majeure events
- Planned maintenance within announced windows

## 9. Reporting

| Report | Frequency | Content |
|--------|-----------|---------|
| Uptime report | Monthly | Availability %, incidents |
| Incident report | Per P1/P2 incident | Root cause, timeline, remediation |
| Compliance report | Quarterly | Backup status, integrity checks |

## 10. Escalation Path

| Level | Contact | Timeframe |
|-------|---------|-----------|
| L1 — Support | Support team | Immediate |
| L2 — Engineering | Development team | Within response target |
| L3 — Management | System administrator | P1 incidents or SLA breach |

---

**Document Owner**: Product Management
**Approved By**: [Pending]
