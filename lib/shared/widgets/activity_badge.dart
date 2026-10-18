import 'package:flutter/material.dart';

import '../../activity_controller.dart';

enum ActivityKind { notifications, messages, favorites }

class ActivityBadge extends StatelessWidget {
  final ActivityKind kind;
  final Widget child;

  const ActivityBadge({super.key, required this.kind, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: activityController,
      child: child,
      builder: (context, child) {
        final count = switch (kind) {
          ActivityKind.notifications => activityController.counts.notifications,
          ActivityKind.messages => activityController.counts.messages,
          ActivityKind.favorites => activityController.counts.favorites,
        };
        return Semantics(
          label: count > 0 ? '$count necitite' : null,
          child: Badge(
            isLabelVisible: count > 0,
            backgroundColor: const Color(0xFFD32F2F),
            textColor: Colors.white,
            label: Text(count > 99 ? '99+' : '$count'),
            child: child,
          ),
        );
      },
    );
  }
}
