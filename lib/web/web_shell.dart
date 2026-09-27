import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import 'web_home.dart';
import '../web/widgets/web_explore.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';

import 'legal/cookie_banner.dart';

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _selectedIndex = 0;

  final List<String> _navigationItems = const [
    'Acasă',
    'Explorează',
    'Mesaje',
    'Comenzi',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent()),
            ],
          ),

          const CookieBanner(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.25)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                _buildLogo(context),

                const SizedBox(width: 36),

                Expanded(child: _buildSearch(context)),

                const SizedBox(width: 28),

                _buildHeaderAction(
                  context,
                  icon: Icons.favorite_border_rounded,
                  label: 'Favorite',
                  onTap: () {},
                ),

                _buildHeaderAction(
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Mesaje',
                  onTap: () {},
                ),

                _buildHeaderAction(
                  context,
                  icon: Icons.notifications_none_rounded,
                  label: 'Notificări',
                  onTap: () {},
                ),

                const SizedBox(width: 12),

                _buildSellButton(context),

                const SizedBox(width: 16),

                _buildProfileButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),

            const SizedBox(width: 10),

            Text(
              'Nexora',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Caută produse, branduri, categorii...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: theme.colorScheme.onSurface.withOpacity(0.045),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.3,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 23),
        color: theme.colorScheme.onSurface.withOpacity(0.75),
      ),
    );
  }

  Widget _buildSellButton(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      onPressed: () {
        setState(() {
          _selectedIndex = 4;
        });
      },
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text('Vinde', style: TextStyle(fontWeight: FontWeight.w800)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _profileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final theme = Theme.of(context);

    final itemColor = color ?? theme.colorScheme.onSurface.withOpacity(0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: itemColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.48),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    final isLoggedIn = auth.isLoggedIn;
    final user = auth.user;

    final username = user?['username']?.toString() ?? 'Utilizator';
    final email = user?['email']?.toString() ?? '';
    final avatar = user?['avatar']?.toString() ?? '';

    return PopupMenuButton<String>(
      tooltip: 'Cont',
      offset: const Offset(0, 12),
      elevation: 16,
      color: theme.colorScheme.surface,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) async {
        switch (value) {
          case 'login':
            setState(() {
              _selectedIndex = 4;
            });
            break;

          case 'register':
            setState(() {
              _selectedIndex = 5;
            });
            break;

          case 'profile':
            setState(() {
              _selectedIndex = 6;
            });
            break;

          case 'listings':
            setState(() {
              _selectedIndex = 7;
            });
            break;

          case 'favorites':
            setState(() {
              _selectedIndex = 8;
            });
            break;

          case 'messages':
            setState(() {
              _selectedIndex = 2;
            });
            break;

          case 'orders':
            setState(() {
              _selectedIndex = 3;
            });
            break;

          case 'sales':
            setState(() {
              _selectedIndex = 9;
            });
            break;

          case 'shipping':
            setState(() {
              _selectedIndex = 10;
            });
            break;

          case 'reviews':
            setState(() {
              _selectedIndex = 11;
            });
            break;

          case 'notifications':
            setState(() {
              _selectedIndex = 12;
            });
            break;

          case 'settings':
            setState(() {
              _selectedIndex = 13;
            });
            break;

          case 'help':
            setState(() {
              _selectedIndex = 14;
            });
            break;

          case 'logout':
            await auth.logout();
            break;
        }
      },
      itemBuilder: (context) {
        if (!isLoggedIn) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 27,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bine ai venit!',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Accesează contul tău Nexora',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const PopupMenuDivider(),

            PopupMenuItem<String>(
              value: 'login',
              child: _profileMenuItem(
                context,
                icon: Icons.login_rounded,
                title: 'Autentificare',
                subtitle: 'Intră în contul tău',
                color: theme.colorScheme.primary,
              ),
            ),

            PopupMenuItem<String>(
              value: 'register',
              child: _profileMenuItem(
                context,
                icon: Icons.person_add_alt_1_rounded,
                title: 'Creează cont',
                subtitle: 'Înregistrează-te gratuit',
                color: theme.colorScheme.primary,
              ),
            ),

            const PopupMenuDivider(),

            PopupMenuItem<String>(
              enabled: false,
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 17,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Cont securizat Nexora',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.50),
                    ),
                  ),
                ],
              ),
            ),
          ];
        }

        return [
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 330,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              color: theme.colorScheme.primary,
                              size: 27,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.55,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'profile',
            child: _profileMenuItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Profilul meu',
              subtitle: 'Vezi și editează profilul',
            ),
          ),

          PopupMenuItem<String>(
            value: 'listings',
            child: _profileMenuItem(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Anunțurile mele',
              subtitle: 'Produsele pe care le vinzi',
            ),
          ),

          PopupMenuItem<String>(
            value: 'favorites',
            child: _profileMenuItem(
              context,
              icon: Icons.favorite_border_rounded,
              title: 'Favorite',
              subtitle: 'Produsele salvate',
            ),
          ),

          PopupMenuItem<String>(
            value: 'messages',
            child: _profileMenuItem(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Mesaje',
              subtitle: 'Conversațiile tale',
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'orders',
            child: _profileMenuItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'Comenzile mele',
              subtitle: 'Produsele cumpărate',
            ),
          ),

          PopupMenuItem<String>(
            value: 'sales',
            child: _profileMenuItem(
              context,
              icon: Icons.sell_outlined,
              title: 'Vânzările mele',
              subtitle: 'Produsele vândute',
            ),
          ),

          PopupMenuItem<String>(
            value: 'shipping',
            child: _profileMenuItem(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Livrările mele',
              subtitle: 'Statusul expedierilor',
            ),
          ),

          PopupMenuItem<String>(
            value: 'reviews',
            child: _profileMenuItem(
              context,
              icon: Icons.star_border_rounded,
              title: 'Recenziile mele',
              subtitle: 'Recenzii primite și oferite',
            ),
          ),

          PopupMenuItem<String>(
            value: 'notifications',
            child: _profileMenuItem(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Notificări',
              subtitle: 'Activitatea contului',
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'settings',
            child: _profileMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Setări',
              subtitle: 'Preferințe și securitate',
            ),
          ),

          PopupMenuItem<String>(
            value: 'help',
            child: _profileMenuItem(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Ajutor și suport',
              subtitle: 'Ai nevoie de ajutor?',
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 19,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Deconectare',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.16),
          ),
        ),
        child: isLoggedIn && avatar.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Icon(
                      Icons.person_outline_rounded,
                      color: theme.colorScheme.primary,
                    );
                  },
                ),
              )
            : Icon(
                Icons.person_outline_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const WebHome();

      case 1:
        return const WebExplore();

      case 2:
        return _buildPlaceholder('Mesaje', Icons.chat_bubble_outline_rounded);

      case 3:
        return _buildPlaceholder('Comenzile mele', Icons.shopping_bag_outlined);

      case 4:
        return const LoginPage();

      case 5:
        return const RegisterPage();

      case 6:
        return _buildPlaceholder('Profilul meu', Icons.person_outline_rounded);

      case 7:
        return _buildPlaceholder('Anunțurile mele', Icons.inventory_2_outlined);

      case 8:
        return _buildPlaceholder('Favorite', Icons.favorite_border_rounded);

      case 9:
        return _buildPlaceholder('Vânzările mele', Icons.sell_outlined);

      case 10:
        return _buildPlaceholder(
          'Livrările mele',
          Icons.local_shipping_outlined,
        );

      case 11:
        return _buildPlaceholder('Recenziile mele', Icons.star_border_rounded);

      case 12:
        return _buildPlaceholder(
          'Notificări',
          Icons.notifications_none_rounded,
        );

      case 13:
        return _buildPlaceholder('Setări', Icons.settings_outlined);

      case 14:
        return _buildPlaceholder(
          'Ajutor și suport',
          Icons.help_outline_rounded,
        );

      default:
        return const WebHome();
    }
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
