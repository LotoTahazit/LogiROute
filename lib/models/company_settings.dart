import 'package:cloud_firestore/cloud_firestore.dart';

/// Доступные модули системы
class ModuleEntitlements {
  final bool warehouse;
  final bool logistics;
  final bool dispatcher;
  final bool accounting;
  final bool reports;

  const ModuleEntitlements({
    this.warehouse = true,
    this.logistics = true,
    this.dispatcher = true,
    this.accounting = true,
    this.reports = true,
  });

  factory ModuleEntitlements.fromMap(Map<String, dynamic>? map) {
    if (map == null)
      return const ModuleEntitlements(); // всё включено по умолчанию
    return ModuleEntitlements(
      warehouse: map['warehouse'] ?? true,
      logistics: map['logistics'] ?? true,
      dispatcher: map['dispatcher'] ?? true,
      accounting: map['accounting'] ?? true,
      reports: map['reports'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'warehouse': warehouse,
        'logistics': logistics,
        'dispatcher': dispatcher,
        'accounting': accounting,
        'reports': reports,
      };

  bool operator [](String key) {
    switch (key) {
      case 'warehouse':
        return warehouse;
      case 'logistics':
        return logistics;
      case 'dispatcher':
        return dispatcher;
      case 'accounting':
        return accounting;
      case 'reports':
        return reports;
      default:
        return false;
    }
  }
}

/// Лимиты по тарифу
class PlanLimits {
  final int maxUsers;
  final int maxDocsPerMonth;
  final int maxRoutesPerDay;

  const PlanLimits({
    this.maxUsers = 999,
    this.maxDocsPerMonth = 99999,
    this.maxRoutesPerDay = 999,
  });

  factory PlanLimits.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PlanLimits();
    return PlanLimits(
      maxUsers: map['maxUsers'] ?? 999,
      maxDocsPerMonth: map['maxDocsPerMonth'] ?? 99999,
      maxRoutesPerDay: map['maxRoutesPerDay'] ?? 999,
    );
  }

  Map<String, dynamic> toMap() => {
        'maxUsers': maxUsers,
        'maxDocsPerMonth': maxDocsPerMonth,
        'maxRoutesPerDay': maxRoutesPerDay,
      };
}

class CompanySettings {
  final String id;

  // Основные данные
  final String nameHebrew;
  final String nameEnglish;
  final String taxId; // ח.פ

  // Адреса
  final String addressHebrew;
  final String addressEnglish;
  final String poBox;
  final String city;
  final String zipCode;

  // Контакты
  final String phone;
  final String fax;
  final String email;
  final String website;

  // Для счетов
  final String invoiceFooterText;
  final String paymentTerms;
  final String bankDetails;

  // Логотип
  final String? logoUrl;

  // Дополнительные поля для счетов
  final String driverName; // Имя водителя по умолчанию (например, "יבגני")
  final String driverPhone; // Телефон водителя
  final String departureTime; // Время выезда по умолчанию

  // === Модульность SaaS ===
  final ModuleEntitlements modules;
  final PlanLimits limits;
  final String plan; // warehouse_only | ops | full | custom
  final String billingStatus; // active | trial | grace | suspended | cancelled
  final DateTime? trialEndsAt;
  final DateTime? accountingLockedUntil; // период закрытия бухгалтерии

  // === Payment & Billing ===
  final DateTime?
      paidUntil; // оплачено до (source of truth для billing automation)
  final String? paymentProvider; // stripe | tranzila | payplus | yaad | manual
  final String? subscriptionId; // ID подписки у провайдера
  final String? paymentCustomerId; // ID клиента у провайдера
  final int gracePeriodDays; // дней grace после paidUntil (default 7)

  CompanySettings({
    required this.id,
    required this.nameHebrew,
    required this.nameEnglish,
    required this.taxId,
    required this.addressHebrew,
    required this.addressEnglish,
    required this.poBox,
    required this.city,
    required this.zipCode,
    required this.phone,
    required this.fax,
    required this.email,
    required this.website,
    required this.invoiceFooterText,
    required this.paymentTerms,
    required this.bankDetails,
    this.logoUrl,
    required this.driverName,
    required this.driverPhone,
    required this.departureTime,
    this.modules = const ModuleEntitlements(),
    this.limits = const PlanLimits(),
    this.plan = 'full',
    this.billingStatus = 'active',
    this.trialEndsAt,
    this.accountingLockedUntil,
    this.paidUntil,
    this.paymentProvider,
    this.subscriptionId,
    this.paymentCustomerId,
    this.gracePeriodDays = 7,
  });

  factory CompanySettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanySettings(
      id: doc.id,
      nameHebrew: data['nameHebrew'] ?? '',
      nameEnglish: data['nameEnglish'] ?? '',
      taxId: data['taxId'] ?? '',
      addressHebrew: data['addressHebrew'] ?? '',
      addressEnglish: data['addressEnglish'] ?? '',
      poBox: data['poBox'] ?? '',
      city: data['city'] ?? '',
      zipCode: data['zipCode'] ?? '',
      phone: data['phone'] ?? '',
      fax: data['fax'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      invoiceFooterText: data['invoiceFooterText'] ?? '',
      paymentTerms: data['paymentTerms'] ?? '',
      bankDetails: data['bankDetails'] ?? '',
      logoUrl: data['logoUrl'],
      driverName: data['driverName'] ?? '',
      driverPhone: data['driverPhone'] ?? '',
      departureTime: data['departureTime'] ?? '7:00',
      modules:
          ModuleEntitlements.fromMap(data['modules'] as Map<String, dynamic>?),
      limits: PlanLimits.fromMap(data['limits'] as Map<String, dynamic>?),
      plan: data['plan'] ?? 'full',
      billingStatus: data['billingStatus'] ?? 'active',
      trialEndsAt: data['trialUntil'] != null
          ? (data['trialUntil'] as Timestamp).toDate()
          : data['trialEndsAt'] != null
              ? (data['trialEndsAt'] as Timestamp).toDate()
              : null,
      accountingLockedUntil: data['accountingLockedUntil'] != null
          ? (data['accountingLockedUntil'] as Timestamp).toDate()
          : null,
      paidUntil: data['paidUntil'] != null
          ? (data['paidUntil'] as Timestamp).toDate()
          : null,
      paymentProvider: data['paymentProvider'],
      subscriptionId: data['subscriptionId'],
      paymentCustomerId: data['paymentCustomerId'],
      gracePeriodDays: data['gracePeriodDays'] ?? 7,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameHebrew': nameHebrew,
      'nameEnglish': nameEnglish,
      'taxId': taxId,
      'addressHebrew': addressHebrew,
      'addressEnglish': addressEnglish,
      'poBox': poBox,
      'city': city,
      'zipCode': zipCode,
      'phone': phone,
      'fax': fax,
      'email': email,
      'website': website,
      'invoiceFooterText': invoiceFooterText,
      'paymentTerms': paymentTerms,
      'bankDetails': bankDetails,
      'logoUrl': logoUrl,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'departureTime': departureTime,
      'modules': modules.toMap(),
      'limits': limits.toMap(),
      'plan': plan,
      'billingStatus': billingStatus,
      'trialUntil':
          trialEndsAt != null ? Timestamp.fromDate(trialEndsAt!) : null,
      'accountingLockedUntil': accountingLockedUntil != null
          ? Timestamp.fromDate(accountingLockedUntil!)
          : null,
      'paidUntil': paidUntil != null ? Timestamp.fromDate(paidUntil!) : null,
      'paymentProvider': paymentProvider,
      'subscriptionId': subscriptionId,
      'paymentCustomerId': paymentCustomerId,
      'gracePeriodDays': gracePeriodDays,
    };
  }

  CompanySettings copyWith({
    String? id,
    String? nameHebrew,
    String? nameEnglish,
    String? taxId,
    String? addressHebrew,
    String? addressEnglish,
    String? poBox,
    String? city,
    String? zipCode,
    String? phone,
    String? fax,
    String? email,
    String? website,
    String? invoiceFooterText,
    String? paymentTerms,
    String? bankDetails,
    String? logoUrl,
    String? driverName,
    String? driverPhone,
    String? departureTime,
    ModuleEntitlements? modules,
    PlanLimits? limits,
    String? plan,
    String? billingStatus,
    DateTime? trialEndsAt,
    DateTime? accountingLockedUntil,
    DateTime? paidUntil,
    String? paymentProvider,
    String? subscriptionId,
    String? paymentCustomerId,
    int? gracePeriodDays,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      nameHebrew: nameHebrew ?? this.nameHebrew,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      taxId: taxId ?? this.taxId,
      addressHebrew: addressHebrew ?? this.addressHebrew,
      addressEnglish: addressEnglish ?? this.addressEnglish,
      poBox: poBox ?? this.poBox,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      email: email ?? this.email,
      website: website ?? this.website,
      invoiceFooterText: invoiceFooterText ?? this.invoiceFooterText,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      bankDetails: bankDetails ?? this.bankDetails,
      logoUrl: logoUrl ?? this.logoUrl,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      departureTime: departureTime ?? this.departureTime,
      modules: modules ?? this.modules,
      limits: limits ?? this.limits,
      plan: plan ?? this.plan,
      billingStatus: billingStatus ?? this.billingStatus,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      accountingLockedUntil:
          accountingLockedUntil ?? this.accountingLockedUntil,
      paidUntil: paidUntil ?? this.paidUntil,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      paymentCustomerId: paymentCustomerId ?? this.paymentCustomerId,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
    );
  }
}
