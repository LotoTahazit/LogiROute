import 'dart:async';

import 'package:flutter/material.dart';

/// StreamBuilder без бесконечного спиннера при проблемах с сетью/Firestore.
class StreamLoadingGate<T> extends StatefulWidget {
  const StreamLoadingGate({
    super.key,
    required this.stream,
    required this.builder,
    this.timeout = const Duration(seconds: 12),
    this.loading,
    this.onTimeout,
  });

  final Stream<T> stream;
  final Duration timeout;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) builder;
  final Widget? loading;
  final Widget Function(BuildContext context)? onTimeout;

  @override
  State<StreamLoadingGate<T>> createState() => _StreamLoadingGateState<T>();
}

class _StreamLoadingGateState<T> extends State<StreamLoadingGate<T>> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _clearTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData || snapshot.hasError) {
          _clearTimer();
          return widget.builder(context, snapshot);
        }
        if (_timedOut) {
          return widget.onTimeout?.call(context) ??
              widget.builder(context, snapshot);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loading ??
              const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
        }
        return widget.builder(context, snapshot);
      },
    );
  }
}
