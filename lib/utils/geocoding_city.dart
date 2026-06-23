/// Город в адресе и сверка с ответом Google (иврит / английский).
class GeocodingCity {
  GeocodingCity._();

  static const _aliases = <String, List<String>>{
    'בית שמש': ['Beit Shemesh', 'Bet Shemesh'],
    'תל אביב': ['Tel Aviv', 'Tel Aviv-Yafo'],
    'תל אביב-יפו': ['Tel Aviv', 'Tel Aviv-Yafo'],
    'חולון': ['Holon'],
    'ראשון לציון': ['Rishon LeZion', 'Rishon Le Zion'],
    'פתח תקווה': ['Petah Tikva', 'Petach Tikva'],
    'ירושלים': ['Jerusalem'],
    'חיפה': ['Haifa'],
    'באר שבע': ['Beer Sheva', 'Beersheba'],
    'מודיעין': ['Modiin', "Modi'in"],
    'מודיעין-מכבים-רעות': ['Modiin', "Modi'in"],
    'אשדוד': ['Ashdod'],
    'נתניה': ['Netanya'],
    'רמת גן': ['Ramat Gan'],
    'בני ברק': ['Bnei Brak'],
    'אשקלון': ['Ashkelon'],
    'רחובות': ['Rehovot'],
    'כפר סבא': ['Kfar Saba'],
    'הרצליה': ['Herzliya'],
    'רעננה': ['Raanana', "Ra'anana"],
  };

  static const _knownCities = [
    'בית שמש',
    'תל אביב-יפו',
    'תל אביב',
    'ראשון לציון',
    'פתח תקווה',
    'מודיעין-מכבים-רעות',
    'מודיעין',
    'כפר סבא',
    'בני ברק',
    'רמת גן',
    'הרצליה',
    'רעננה',
    'חולון',
    'ירושלים',
    'חיפה',
    'באר שבע',
    'אשדוד',
    'נתניה',
    'אשקלון',
    'רחובות',
  ];

  /// «ул., город» или город в конце строки без запятой.
  static String? extractFromAddress(String address) {
    final parts = address
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    while (parts.isNotEmpty &&
        (parts.last == 'ישראל' || parts.last.toLowerCase() == 'israel')) {
      parts.removeLast();
    }
    if (parts.length >= 2) return parts.last;

    final trimmed = address.trim();
    for (final city in _knownCities) {
      if (trimmed.endsWith(city) && trimmed.length > city.length) {
        return city;
      }
    }
    return null;
  }

  static bool matches({
    required String reqCity,
    String? formattedAddress,
    Iterable<String> componentNames = const [],
  }) {
    bool hit(String name) {
      if (name == reqCity) return true;
      for (final alt in _aliases[reqCity] ?? const <String>[]) {
        if (name.toLowerCase() == alt.toLowerCase()) return true;
      }
      return false;
    }

    for (final n in componentNames) {
      if (hit(n)) return true;
    }
    if (formattedAddress != null) {
      if (formattedAddress.contains(reqCity)) return true;
      for (final alt in _aliases[reqCity] ?? const <String>[]) {
        if (formattedAddress.toLowerCase().contains(alt.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }

  static List<String> namesFromJsonComponents(List<dynamic>? components) {
    if (components == null) return const [];
    final out = <String>[];
    for (final c in components) {
      if (c is! Map) continue;
      final long = c['long_name']?.toString();
      final short = c['short_name']?.toString();
      if (long != null && long.isNotEmpty) out.add(long);
      if (short != null && short.isNotEmpty) out.add(short);
    }
    return out;
  }
}
