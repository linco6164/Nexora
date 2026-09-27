import 'package:flutter/material.dart';

import '../../../shared/widgets/responsive_container.dart';
import 'web_actions.dart';
import 'web_logo.dart';
import 'web_search_bar.dart';
import 'web_user_menu.dart';

class WebHeader extends StatelessWidget {
  const WebHeader({super.key});

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
            height: 80,
            child: Row(
              children: [
                const WebLogo(),

                const SizedBox(width: 40),

                const Expanded(
                  child: WebSearchBar(),
                ),

                const SizedBox(width: 24),

                const WebActions(),

                const SizedBox(width: 20),

                const WebUserMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}