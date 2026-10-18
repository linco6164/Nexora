import 'package:flutter/material.dart';

import '../../../shared/widgets/responsive_container.dart';
import 'web_actions.dart';
import 'web_logo.dart';
import 'web_search_bar.dart';
import 'web_user_menu.dart';

class WebHeader extends StatelessWidget {
  final VoidCallback? onHome;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onFilters;
  final VoidCallback? onFavorites;
  final VoidCallback? onMessages;
  final VoidCallback? onNotifications;
  final VoidCallback? onSell;
  final ValueChanged<String>? onUserNavigate;

  const WebHeader({
    super.key,
    this.onHome,
    this.onSearch,
    this.onFilters,
    this.onFavorites,
    this.onMessages,
    this.onNotifications,
    this.onSell,
    this.onUserNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 1,
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final search = WebSearchBar(
                onSubmitted: onSearch,
                onFilters: onFilters,
              );
              final actions = WebActions(
                compact: compact,
                onFavorites: onFavorites,
                onMessages: onMessages,
                onNotifications: onNotifications,
                onSell: onSell,
              );

              return SizedBox(
                height: compact ? 116 : 64,
                child: compact
                    ? Column(
                        children: [
                          SizedBox(
                            height: 60,
                            child: Row(
                              children: [
                                WebLogo(onTap: onHome, compact: true),
                                const Spacer(),
                                actions,
                                const SizedBox(width: 4),
                                WebUserMenu(
                                  onNavigate: onUserNavigate,
                                  compact: true,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 48, child: search),
                        ],
                      )
                    : Row(
                        children: [
                          WebLogo(onTap: onHome),
                          const SizedBox(width: 24),
                          Expanded(child: search),
                          const SizedBox(width: 16),
                          actions,
                          const SizedBox(width: 12),
                          WebUserMenu(onNavigate: onUserNavigate),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
