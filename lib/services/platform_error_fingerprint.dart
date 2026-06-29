import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/platform_system_error.dart';

String platformErrorStackTop(String? stackTrace) {
  if (stackTrace == null || stackTrace.isEmpty) return '';
  final lines = stackTrace
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.length > 1) return lines[1];
  return lines.isNotEmpty ? lines.first : '';
}

String computePlatformErrorFingerprint({
  required String errorType,
  String? stackTrace,
  String? operation,
}) {
  final payload = [
    errorType.toLowerCase(),
    platformErrorStackTop(stackTrace),
    (operation ?? 'unknown').toLowerCase(),
  ].join('|');
  return sha256.convert(utf8.encode(payload)).toString().substring(0, 40);
}

PlatformErrorSeverity inferPlatformErrorSeverity({
  required String errorType,
  String? errorMessage,
}) {
  final t = '${errorType.toLowerCase()} ${errorMessage?.toLowerCase() ?? ''}';
  if (RegExp(
    r'unhandled|crash|corruption|billing.*fail|accounting.*fail|internal-error',
  ).hasMatch(t)) {
    return PlatformErrorSeverity.critical;
  }
  if (RegExp(r'permission.denied|permission-denied|sync.*fail|import.*fail')
      .hasMatch(t)) {
    return PlatformErrorSeverity.high;
  }
  if (RegExp(r'gps|navigation|waze|notification').hasMatch(t)) {
    return PlatformErrorSeverity.medium;
  }
  return PlatformErrorSeverity.low;
}

String sanitizePlatformErrorText(String? text) {
  if (text == null || text.isEmpty) return '';
  var s = text;
  s = s.replaceAll(
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
    '[email]',
  );
  s = s.replaceAll(
    RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+\b'),
    '[jwt]',
  );
  s = s.replaceAll(RegExp(r'\b\d{13,19}\b'), '[card]');
  s = s.replaceAll(RegExp(r'password[=:]\s*\S+', caseSensitive: false),
      'password=[redacted]');
  s = s.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer [redacted]');
  s = s.replaceAll(RegExp(r'\+?\d{10,15}'), '[phone]');
  if (s.length > 8000) s = s.substring(0, 8000);
  return s;
}
