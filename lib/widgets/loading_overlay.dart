import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedOpacity(
          opacity: isLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isLoading
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: Semantics(
                    label: MaterialLocalizations.of(context).dialogLabel,
                    child: const CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
