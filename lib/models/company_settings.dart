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
    if (map == null) {
      return const ModuleEntitlements(); // всё включено по умолчанию
    }
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
    required this.maxUsers,
    required this.maxDocsPerMonth,
    required this.maxRoutesPerDay,
  });

  factory PlanLimits.fromMap(Map<String, dynamic>? map, {String plan = 'full'}) {
    final normalized = _normalizePlan(plan);
    final defaults = _defaultsForPlan(normalized);
    if (map == null || map.isEmpty) return defaults;
    int i(String key, int def) => ((map[key] ?? def) as num).toInt();
    return PlanLimits(
      maxUsers: i('maxUsers', defaults.maxUsers),
      maxDocsPerMonth: i('maxDocsPerMonth', defaults.maxDocsPerMonth),
      maxRoutesPerDay: i('maxRoutesPerDay', defaults.maxRoutesPerDay),
    );
  }

  static String _normalizePlan(String? plan) {
    const known = {'warehouse_only', 'logistics', 'ops', 'full'};
    return known.contains(plan) ? plan! : 'full';
  }

  /// Sync with [PlanLimitsService.defaultLimitsForPlan] (H5).
  static PlanLimits _defaultsForPlan(String plan) {
    switch (plan) {
      case 'warehouse_only':
        return const PlanLimits(
            maxUsers: 5, maxDocsPerMonth: 500, maxRoutesPerDay: 10);
      case 'logistics':
        return const PlanLimits(
            maxUsers: 10, maxDocsPerMonth: 1000, maxRoutesPerDay: 40);
      case 'ops':
        return const PlanLimits(
            maxUsers: 15, maxDocsPerMonth: 2000, maxRoutesPerDay: 50);
      case 'full':
      default:
        return const PlanLimits(
            maxUsers: 50, maxDocsPerMonth: 10000, maxRoutesPerDay: 200);
    }
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
  final String departureTime; // Время выезда по умолчанию ("H:mm")

  // ── Параметры маршрутизации (ETA / окна доставки) ──
  final double avgSpeedKmh; // средняя городская скорость для ETA
  final int serviceMinutes; // время разгрузки на точке (мин)
  /// Паттерн даты маршрута при создании: 'same' (сегодня) | 'next' (завтра) |
  /// 'next_working' (ближайший рабочий день, пропуская пт/сб).
  final String deliveryDayMode;

  /// Требовать POD-фото на каждую доставку. Если true — кнопка «Доставлено»
  /// (без фото) скрыта, автозакрытие отключено (закрытие только с фото).
  final bool requirePodPhoto;

  /// Включено ли автозакрытие точек по GPS (стоянка у клиента).
  /// Если false — точки закрывает только водитель вручную (для компаний,
  /// которым авто-закрытие не нужно). Имеет смысл только при
  /// [requirePodPhoto] == false (с обязательным фото закрытие и так ручное).
  final bool autoCloseEnabled;

  /// Куда выгружать бухгалтерские документы:
  /// 'none' — никуда (встроенная бухгалтерия), 'export' — файловый экспорт
  /// (מבנה אחיד), 'greeninvoice' / 'icount' — интеграция с внешней системой.
  final String accountingProvider;

  /// Разрешить диспетчеру выписывать חשבונית מס/קבלה (оплата при выдаче).
  final bool dispatcherTaxInvoiceReceipt;

  /// מספר רישום תוכנה ל-BKMV (רשות המסים), 8 ספרות.
  final String bkmvSoftwareRegistrationNumber;

  /// סוג עוסק לתצוגה ב-PDF: authorized | exempt | company
  final String vatRegime;

  /// מחסן ממוחשב — סריקת ברקודים בממשק המחסן (כבוי כברירת מחדל).
  final bool computerizedWarehouseEnabled;

  /// Плановое время выезда в минутах от полуночи (парсинг [departureTime]).
  int get departureMinutes => parseTimeToMinutes(departureTime, fallback: 7 * 60);

  /// Дата доставки по умолчанию согласно [deliveryDayMode]:
  /// 'same' — сегодня, 'next' — завтра, 'next_working' — ближайший рабочий день
  /// (пропуская пятницу/субботу — выходные в Израиле). Возвращает полночь.
  DateTime resolveDeliveryDate([DateTime? from]) {
    final base = from ?? DateTime.now();
    final d0 = DateTime(base.year, base.month, base.day);
    switch (deliveryDayMode) {
      case 'same':
        return d0;
      case 'next_working':
        var d = d0.add(const Duration(days: 1));
        while (d.weekday == DateTime.friday || d.weekday == DateTime.saturday) {
          d = d.add(const Duration(days: 1));
        }
        return d;
      case 'next':
      default:
        return d0.add(const Duration(days: 1));
    }
  }

  /// Парсит "H:mm"/"HH:mm" в минуты от полуночи; при ошибке — [fallback].
  static int parseTimeToMinutes(String? s, {int fallback = 7 * 60}) {
    if (s == null || s.trim().isEmpty) return fallback;
    final parts = s.trim().split(':');
    if (parts.isEmpty) return fallback;
    final h = int.tryParse(parts[0]);
    final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (h == null || h < 0 || h > 23) return fallback;
    final mm = (m == null || m < 0 || m > 59) ? 0 : m;
    return h * 60 + mm;
  }

  // === Модульность SaaS ===
  final ModuleEntitlements modules;
  final PlanLimits limits;
  final String plan; // logistics | warehouse_only | ops | full
  final String billingStatus; // active | trial | grace | suspended | cancelled (C3)
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
    this.avgSpeedKmh = 30.0,
    this.serviceMinutes = 8,
    this.deliveryDayMode = 'next',
    this.requirePodPhoto = false,
    this.autoCloseEnabled = true,
    this.accountingProvider = 'none',
    this.dispatcherTaxInvoiceReceipt = false,
    this.bkmvSoftwareRegistrationNumber = '00000000',
    this.vatRegime = 'authorized',
    this.computerizedWarehouseEnabled = false,
    this.modules = const ModuleEntitlements(),
    this.limits = const PlanLimits(
      maxUsers: 50,
      maxDocsPerMonth: 10000,
      maxRoutesPerDay: 200,
    ),
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
    final raw = doc.data();
    final data = raw != null
        ? Map<String, dynamic>.from(raw as Map)
        : <String, dynamic>{};
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
      avgSpeedKmh: (data['avgSpeedKmh'] is num)
          ? (data['avgSpeedKmh'] as num).toDouble()
          : 30.0,
      serviceMinutes: (data['serviceMinutes'] is num)
          ? (data['serviceMinutes'] as num).toInt()
          : 8,
      deliveryDayMode: (data['deliveryDayMode'] as String?) ?? 'next',
      requirePodPhoto: data['requirePodPhoto'] == true,
      autoCloseEnabled: data['autoCloseEnabled'] != false,
      accountingProvider: (data['accountingProvider'] as String?) ?? 'none',
      dispatcherTaxInvoiceReceipt:
          data['dispatcherTaxInvoiceReceipt'] == true,
      bkmvSoftwareRegistrationNumber:
          (data['bkmvSoftwareRegistrationNumber'] as String?) ?? '00000000',
      vatRegime: (data['vatRegime'] as String?) ?? 'authorized',
      computerizedWarehouseEnabled:
          data['computerizedWarehouseEnabled'] == true,
      modules: ModuleEntitlements.fromMap(data['modules'] != null
          ? Map<String, dynamic>.from(data['modules'] as Map)
          : null),
      limits: PlanLimits.fromMap(
        data['limits'] != null
            ? Map<String, dynamic>.from(data['limits'] as Map)
            : null,
        plan: data['plan'] ?? 'full',
      ),
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
      gracePeriodDays: ((data['gracePeriodDays'] ?? 7) as num).toInt(),
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
      'avgSpeedKmh': avgSpeedKmh,
      'serviceMinutes': serviceMinutes,
      'deliveryDayMode': deliveryDayMode,
      'requirePodPhoto': requirePodPhoto,
      'autoCloseEnabled': autoCloseEnabled,
      'accountingProvider': accountingProvider,
      'dispatcherTaxInvoiceReceipt': dispatcherTaxInvoiceReceipt,
      'bkmvSoftwareRegistrationNumber': bkmvSoftwareRegistrationNumber,
      'vatRegime': vatRegime,
      'computerizedWarehouseEnabled': computerizedWarehouseEnabled,
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
    double? avgSpeedKmh,
    int? serviceMinutes,
    String? deliveryDayMode,
    bool? requirePodPhoto,
    bool? autoCloseEnabled,
    String? accountingProvider,
    bool? dispatcherTaxInvoiceReceipt,
    String? bkmvSoftwareRegistrationNumber,
    String? vatRegime,
    bool? computerizedWarehouseEnabled,
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
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      serviceMinutes: serviceMinutes ?? this.serviceMinutes,
      deliveryDayMode: deliveryDayMode ?? this.deliveryDayMode,
      requirePodPhoto: requirePodPhoto ?? this.requirePodPhoto,
      autoCloseEnabled: autoCloseEnabled ?? this.autoCloseEnabled,
      accountingProvider: accountingProvider ?? this.accountingProvider,
      dispatcherTaxInvoiceReceipt:
          dispatcherTaxInvoiceReceipt ?? this.dispatcherTaxInvoiceReceipt,
      bkmvSoftwareRegistrationNumber: bkmvSoftwareRegistrationNumber ??
          this.bkmvSoftwareRegistrationNumber,
      vatRegime: vatRegime ?? this.vatRegime,
      computerizedWarehouseEnabled: computerizedWarehouseEnabled ??
          this.computerizedWarehouseEnabled,
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

/// Текст סוג עוסק для печати на PDF.
extension CompanySettingsVatRegime on CompanySettings {
  bool get isVatExempt => vatRegime == 'exempt';

  /// Левая колонка (латиница) — ID по типу עוסק.
  String get vatRegimePdfLabelEn {
    if (isVatExempt) {
      return taxId.isNotEmpty ? 'ID $taxId' : 'VAT exempt';
    }
    if (vatRegime == 'company') {
      return taxId.isNotEmpty ? 'Co. # $taxId' : 'Ltd.';
    }
    return taxId.isNotEmpty ? 'VAT # $taxId' : '';
  }

  String get vatRegimePdfLabel {
    switch (vatRegime) {
      case 'exempt':
        return 'עוסק פטור';
      case 'company':
        return taxId.isNotEmpty ? 'ח.פ $taxId' : 'חברה בע״מ';
      case 'authorized':
      default:
        return taxId.isNotEmpty ? 'עוסק מורשה $taxId' : 'עוסק מורשה';
    }
  }
}
