import 'package:cloud_functions/cloud_functions.dart';
import '../models/invoice.dart';

/// שירות מספר הקצאה — חשבוניות ישראל (Israel Tax Authority allocation number).
class InvoiceAssignmentService {
  final String companyId;
  final FirebaseFunctions _functions;

  InvoiceAssignmentService({
    required this.companyId,
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  bool isAssignmentRequired(Invoice invoice) => invoice.requiresAssignment;

  Future<String> getConnectUrl() async {
    final res = await _functions
        .httpsCallable(
          'israelInvoiceAuthUrl',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call<Map<String, dynamic>>({'companyId': companyId});
    return (res.data['url'] ?? '') as String;
  }

  Future<IsraelInvoiceStatus> getStatus() async {
    final res = await _functions
        .httpsCallable('israelInvoiceStatus')
        .call<Map<String, dynamic>>({'companyId': companyId});
    final data = Map<String, dynamic>.from(res.data as Map);
    return IsraelInvoiceStatus(
      platformConfigured: data['platformConfigured'] == true,
      companyConnected: data['companyConnected'] == true,
      assignmentReady: data['assignmentReady'] == true,
    );
  }

  Future<AssignmentResult> requestAssignmentNumber(String invoiceId) async {
    try {
      final res = await _functions
          .httpsCallable(
            'requestAllocationNumber',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call<Map<String, dynamic>>({
        'companyId': companyId,
        'invoiceId': invoiceId,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      final ok = data['ok'] == true;
      return AssignmentResult(
        success: ok,
        assignmentNumber: data['assignmentNumber']?.toString(),
        message: data['notRequired'] == true
            ? 'לא נדרש מספר הקצאה — מתחת לסף'
            : (data['alreadyApproved'] == true
                ? 'מספר הקצאה כבר התקבל'
                : null),
        error: ok ? null : (data['message']?.toString() ?? 'שגיאה'),
        isRejection: data['rejection'] == true,
      );
    } on FirebaseFunctionsException catch (e) {
      return AssignmentResult(success: false, error: e.message ?? e.code);
    } catch (e) {
      return AssignmentResult(success: false, error: e.toString());
    }
  }
}

class IsraelInvoiceStatus {
  final bool platformConfigured;
  final bool companyConnected;
  final bool assignmentReady;

  const IsraelInvoiceStatus({
    required this.platformConfigured,
    required this.companyConnected,
    required this.assignmentReady,
  });
}

class AssignmentResult {
  final bool success;
  final String? assignmentNumber;
  final String? error;
  final String? message;
  final String? rawResponse;
  final bool isRejection;

  AssignmentResult({
    required this.success,
    this.assignmentNumber,
    this.error,
    this.message,
    this.rawResponse,
    this.isRejection = false,
  });
}
