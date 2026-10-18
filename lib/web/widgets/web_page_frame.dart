import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';

class WebPageFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool useSurface;

  const WebPageFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1040,
    this.useSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compact = viewportWidth < 700;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 24,
            compact ? 14 : 24,
            compact ? 12 : 24,
            compact ? 12 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackHeader =
                          compact ||
                          (actions.length > 1 && constraints.maxWidth < 820);
                      final heading = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(title),
                            style:
                                (compact
                                        ? theme.textTheme.titleLarge
                                        : theme.textTheme.headlineSmall)
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.5,
                                    ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              context.tr(subtitle!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      );

                      if (actions.isEmpty) return heading;

                      final actionBar = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions,
                      );

                      if (stackHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            heading,
                            const SizedBox(height: 12),
                            actionBar,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 16),
                          Flexible(child: actionBar),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  Expanded(
                    child: useSurface
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(
                                compact ? 12 : 14,
                              ),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                compact ? 12 : 14,
                              ),
                              child: child,
                            ),
                          )
                        : child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
