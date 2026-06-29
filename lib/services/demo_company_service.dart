import 'package:cloud_functions/cloud_functions.dart';

/// Демо-компания для продаж и презентаций (super_admin).
class DemoCompanyService {
  static const companyId = 'demo-foods-israel';
  static const emailDomain = '@demofoods.logiroute.app';

  static String demoEmail(String local) => '$local$emailDomain';

  final FirebaseFunctions _functions;

  DemoCompanyService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createDemoCompany() async {
    final result = await _functions
        .httpsCallable('createDemoCompany')
        .call<Map<String, dynamic>>();
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> previewResetDemoCompany() async {
    final result = await _functions
        .httpsCallable('previewResetDemoCompany')
        .call<Map<String, dynamic>>();
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> resetDemoCompany({required bool confirm}) async {
    final result = await _functions
        .httpsCallable('resetDemoCompany')
        .call<Map<String, dynamic>>({'confirm': confirm});
    return Map<String, dynamic>.from(result.data);
  }
}
