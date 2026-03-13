# Investor Technical Summary — LogiRoute

**Version**: 1.0
**Last Updated**: February 2026
**Classification**: Investor — Confidential

---

## Product

**LogiRoute** is a compliance-grade billing and logistics SaaS platform built for Israeli businesses. It combines financial document management with logistics operations in a single multi-tenant cloud platform.

## Market

| Property | Value |
|----------|-------|
| Target market | Israeli SMB logistics and distribution |
| Segment | Companies with delivery fleets (food, beverages, supplies) |
| Regulatory environment | Israeli Bookkeeping Regulations (ניהול ספרים) |
| Market driver | Mandatory electronic invoicing (חשבוניות ישראל) rolling out 2025–2026 |

## Differentiation

| Feature | LogiRoute | Typical Competitor |
|---------|-----------|-------------------|
| Full audit trail | ✅ Append-only, log-before-action | Partial or none |
| Immutable financial records | ✅ Server-enforced, 19 protected fields | Client-side only |
| Assignment automation | ✅ Auto + retry + idempotency | Manual or basic |
| Multi-tenant architecture | ✅ Subcollection isolation + Rules | Shared tables |
| Integrity chain (hash-chain) | ✅ With external anchors | Not implemented |
| Print controls (מקור/עותק) | ✅ One original, labeled reprints | Basic |
| Logistics integration | ✅ Routes, GPS, delivery management | Separate system |

## Technical Architecture

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter (Web + Android + iOS) |
| Backend | Firebase (Serverless) |
| Database | Google Cloud Firestore |
| Region | me-west1 (Tel Aviv, Israel) |
| Security | RBAC + Firestore Rules + Encryption |

### Architecture Maturity

| Area | Rating | Notes |
|------|--------|-------|
| Security | ⭐⭐⭐⭐⭐ | Encryption, RBAC, Rules, audit, tenant isolation |
| Compliance | ⭐⭐⭐⭐½ | Full implementation, pre-registration status |
| Architecture | ⭐⭐⭐⭐⭐ | Cloud-native, serverless, auto-scaling |
| Legal readiness | ⭐⭐⭐⭐ | Policy documents complete, external audit pending |
| Investor readiness | ⭐⭐⭐⭐ | Full compliance package, SLA, DR plan |

## Compliance Status

| Requirement | Status |
|-------------|--------|
| Israeli Bookkeeping Regulations | ✅ Implemented |
| Electronic Invoice (חשבוניות ישראל) | ✅ Implemented (API placeholder) |
| Data Retention (7 years) | ✅ Policy + automated checks |
| Backup & Recovery | ✅ Quarterly + PITR + restore tests |
| Security Policy | ✅ Documented |
| SLA | ✅ Documented |
| DR Plan | ✅ Documented |
| Incident Response | ✅ Documented |
| External Audit | ⬜ Planned pre-launch |
| Penetration Testing | ⬜ Planned pre-launch |
| Tax Authority Registration | ⬜ Planned pre-launch |

## Technical Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Tax Authority API dependency | Medium | Retry + manual retry + copy printing |
| Firebase vendor lock-in | Low-Medium | Standard Firestore API, data exportable |
| Data loss | Very Low | Multi-AZ + PITR + quarterly backups |
| Security breach | Low | Rules + Auth + Audit + Tenant isolation |
| Regulatory change | Low | Modular design, threshold-based logic |

## Scalability

| Dimension | Capacity |
|-----------|----------|
| Companies | Unlimited (subcollection isolation) |
| Users per company | Unlimited (Firebase Auth) |
| Documents | Unlimited (Firestore auto-scaling) |
| Concurrent users | Thousands (Firebase infrastructure) |
| Geographic expansion | Region-configurable |

## Revenue Model

| Model | Description |
|-------|-------------|
| Subscription | Monthly per-company fee |
| Tiers | Based on document volume / users |
| Upsell | Premium features (analytics, API access) |

## Governance Documents

| Document | Status |
|----------|--------|
| Security Policy | ✅ Complete |
| Service Level Agreement | ✅ Complete |
| Disaster Recovery Plan | ✅ Complete |
| Incident Response Plan | ✅ Complete |
| Legal Terms | ✅ Complete |
| Architecture Whitepaper | ✅ Complete |
| Data Retention Policy | ✅ Complete |
| Compliance Declaration | ✅ Complete |
| Version Control Policy | ✅ Complete |

## Key Metrics (Post-Launch)

| Metric | Target |
|--------|--------|
| Uptime | 99.9% |
| RTO | < 4 hours |
| RPO | < 1 hour |
| Backup verification | Quarterly |
| Security review | Quarterly |

## Next Steps

1. **Tax Authority Registration** — Submit software for official registration
2. **External Audit** — Engage certified accountant for opinion letter
3. **Penetration Testing** — Pre-launch security assessment
4. **Beta Launch** — Controlled rollout with 3–5 pilot customers
5. **Production Launch** — Full market availability

---

**Document Owner**: Product / Engineering
**Prepared For**: Investors & Strategic Partners
