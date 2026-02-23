import 'package:cloud_firestore/cloud_firestore.dart';

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
    );
  }
}
