import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/core/correlation/correlation_context.dart';

void main() {
  test('resolveId prefers requestId over new uuid', () {
    expect(
      CorrelationContext.resolveId(requestId: 'req-1'),
      'req-1',
    );
  });

  test('CorrelatedException contains required error fields', () {
    final ctx = CorrelationContext.start(
      operation: CorrelatedOperation.createRoute,
      companyId: 'c1',
      userId: 'u1',
      correlationId: 'cid-1',
    );
    final ex = ctx.toException(Exception('fail'), message: 'fail');
    final map = ex.toMap();
    expect(map['companyId'], 'c1');
    expect(map['userId'], 'u1');
    expect(map['correlationId'], 'cid-1');
    expect(map['operation'], 'create_route');
    expect(map['timestamp'], isNotEmpty);
    expect(map['message'], 'fail');
  });
}
