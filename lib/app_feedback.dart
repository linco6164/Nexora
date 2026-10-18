import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_navigator.dart';

enum AppFeedbackType { success, error, warning, info, notification }

class AppFeedback {
  const AppFeedback._();

  static void success(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppFeedbackType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    Object error, {
    String? title,
    String? fallback,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: readableError(error, fallback: fallback),
      title: title,
      type: AppFeedbackType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppFeedbackType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppFeedbackType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static bool notification({
    required String title,
    required String message,
    String actionLabel = 'Deschide',
    VoidCallback? onAction,
  }) {
    return show(
      title: title,
      message: message,
      type: AppFeedbackType.notification,
      actionLabel: onAction == null ? null : actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 6),
    );
  }

  static bool show({
    BuildContext? context,
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final messenger = context == null
        ? scaffoldMessengerKey.currentState
        : ScaffoldMessenger.maybeOf(context);
    final effectiveContext = context ?? navigatorKey.currentContext;

    if (messenger == null || effectiveContext == null) return false;

    final media = MediaQuery.maybeOf(effectiveContext);
    final viewportWidth = media?.size.width ?? 400;
    final horizontalMargin = viewportWidth > 620
        ? (viewportWidth - 520) / 2
        : 12.0;
    final bottomMargin = (media?.viewPadding.bottom ?? 0) + 12;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(
            horizontalMargin,
            12,
            horizontalMargin,
            bottomMargin,
          ),
          duration:
              duration ??
              (type == AppFeedbackType.error
                  ? const Duration(seconds: 5)
                  : const Duration(seconds: 4)),
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: false,
          content: _FeedbackCard(
            type: type,
            title: title ?? _defaultTitle(type),
            message: _cleanMessage(message),
            actionLabel: actionLabel,
            onAction: onAction,
            onClose: messenger.hideCurrentSnackBar,
          ),
        ),
      );

    if (!kIsWeb &&
        (type == AppFeedbackType.error ||
            type == AppFeedbackType.notification)) {
      HapticFeedback.lightImpact();
    }

    return true;
  }

  static String readableError(Object error, {String? fallback}) {
    final raw = error.toString().trim();
    final cleaned = _cleanMessage(raw);

    final technicalError =
        raw.contains('SocketException') ||
        raw.contains('ClientException') ||
        raw.contains('HandshakeException') ||
        raw.contains('TimeoutException') ||
        raw.contains('FormatException') ||
        raw.contains('XMLHttpRequest');

    if (technicalError && fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }

    if (cleaned.isEmpty ||
        cleaned == 'null' ||
        cleaned.toLowerCase() == 'exception') {
      return fallback ?? 'A apărut o problemă. Încearcă din nou.';
    }

    return cleaned;
  }

  static String _cleanMessage(String value) {
    return value
        .replaceFirst(
          RegExp(r'^(Exception|StateError|Bad state|FormatException):\s*'),
          '',
        )
        .replaceFirst(RegExp(r'^ApiException:\s*'), '')
        .trim();
  }

  static String _defaultTitle(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => 'Gata',
      AppFeedbackType.error => 'Nu am putut finaliza',
      AppFeedbackType.warning => 'Atenție',
      AppFeedbackType.info => 'Informație',
      AppFeedbackType.notification => 'Notificare nouă',
    };
  }
}

class _FeedbackCard extends StatelessWidget {
  final AppFeedbackType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  const _FeedbackCard({
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = switch (type) {
      AppFeedbackType.success => const Color(0xFF24A866),
      AppFeedbackType.error => colors.error,
      AppFeedbackType.warning => const Color(0xFFE59324),
      AppFeedbackType.info => colors.primary,
      AppFeedbackType.notification => const Color(0xFF7C5CFC),
    };
    final icon = switch (type) {
      AppFeedbackType.success => Icons.check_circle_outline_rounded,
      AppFeedbackType.error => Icons.error_outline_rounded,
      AppFeedbackType.warning => Icons.warning_amber_rounded,
      AppFeedbackType.info => Icons.info_outline_rounded,
      AppFeedbackType.notification => Icons.notifications_active_outlined,
    };

    return Material(
      color: colors.surfaceContainerHigh,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: accent.withValues(alpha: 0.42)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        message,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 7),
                      TextButton(
                        onPressed: () {
                          onClose();
                          onAction!();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Închide',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: colors.onSurfaceVariant,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
