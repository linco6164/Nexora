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
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                WebLogo(onTap: onHome),

                const SizedBox(width: 24),

                Expanded(
                  child: WebSearchBar(
                    onSubmitted: onSearch,
                    onFilters: onFilters,
                  ),
                ),

                const SizedBox(width: 16),

                WebActions(
                  onFavorites: onFavorites,
                  onMessages: onMessages,
                  onNotifications: onNotifications,
                  onSell: onSell,
                ),

                const SizedBox(width: 12),

                WebUserMenu(onNavigate: onUserNavigate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
