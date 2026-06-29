import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/platform_error_service.dart';

/// Глобальные хуки Flutter → Platform Error Center.
void initPlatformErrorHooks() {
  final prevFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    prevFlutter?.call(details);
    FlutterError.dumpErrorToConsole(details);
    PlatformErrorService.report(
      error: details.exception,
      stack: details.stack,
      source: 'flutter_error',
      route: details.context?.toString(),
      operation: 'unhandled_flutter',
    );
  };

  final prevPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    PlatformErrorService.report(
      error: error,
      stack: stack,
      source: 'platform_dispatcher',
      operation: 'unhandled_async',
    );
    return prevPlatform?.call(error, stack) ?? true;
  };
}
