import 'package:flutter/material.dart';

class InactivityDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onActivity;

  const InactivityDetector({
    super.key,
    required this.child,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onActivity(),
      onPointerMove: (_) => onActivity(),
      onPointerUp: (_) => onActivity(),
      onPointerSignal: (_) => onActivity(),
      child: child,
    );
  }
}
