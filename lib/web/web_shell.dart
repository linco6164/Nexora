import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../l10n/app_locale.dart';

import 'web_home.dart';
import '../web/widgets/web_explore.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import '../saved_cards_page.dart';
import '../addresses_page.dart';
import '../favorites_page.dart';
import '../message_tab.dart';
import '../my_listings_page.dart';
import '../my_reviews_page.dart';
import '../notification_settings_page.dart';
import '../notifications_page.dart';
import '../order_page.dart';
import '../profile_page.dart';
import '../promotion_page.dart';
import '../security_page.dart';
import '../sell_page.dart';
import '../sold_page.dart';
import '../support_page.dart';
import '../theme_settings_page.dart';

import 'legal/cookie_banner.dart';
import 'widgets/header/web_language_selector.dart';

class WebShell extends StatefulWidget {
  final int initialIndex;

  const WebShell({super.key, this.initialIndex = 0});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  late int _selectedIndex;
  final TextEditingController _searchController = TextEditingController();
  String _exploreQuery = '';
  String _exploreCategory = 'all';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectSection(int index, {bool requiresAuthentication = true}) {
    final authenticated = context.read<AuthProvider>().isLoggedIn;
    setState(() {
      _selectedIndex = requiresAuthentication && !authenticated ? 4 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final useMobileNavigation = MediaQuery.sizeOf(context).width < 650;

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
      bottomNavigationBar: useMobileNavigation
          ? _buildMobileNavigation(context)
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 650;

    return Container(
      height: narrow ? 116 : 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1050;
              final narrow = constraints.maxWidth < 650;

              final desktopHeader = Row(
                children: [
                  _buildLogo(context, compact: compact),
                  SizedBox(width: compact ? 10 : 24),
                  Expanded(child: _buildSearch(context)),
                  SizedBox(width: compact ? 6 : 16),
                  _buildHeaderAction(
                    context,
                    icon: Icons.favorite_border_rounded,
                    label: context.tr('Favorite'),
                    onTap: () => _selectSection(8),
                  ),
                  _buildHeaderAction(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: context.tr('Mesaje'),
                    onTap: () => _selectSection(2),
                  ),
                  _buildHeaderAction(
                    context,
                    icon: Icons.notifications_none_rounded,
                    label: context.tr('Notificări'),
                    onTap: () => _selectSection(12),
                  ),
                  SizedBox(width: compact ? 4 : 12),
                  const WebLanguageSelector(),
                  SizedBox(width: compact ? 6 : 10),
                  _buildSellButton(context, compact: compact),
                  SizedBox(width: compact ? 6 : 16),
                  _buildProfileButton(context),
                ],
              );

              final mobileHeader = Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        _buildLogo(
                          context,
                          compact: constraints.maxWidth < 370,
                        ),
                        const Spacer(),
                        const WebLanguageSelector(compact: true),
                        const SizedBox(width: 4),
                        _buildMobileQuickMenu(context),
                        const SizedBox(width: 2),
                        _buildSellButton(context, compact: true),
                        const SizedBox(width: 4),
                        _buildProfileButton(context),
                      ],
                    ),
                  ),
                  SizedBox(height: 46, child: _buildSearch(context)),
                ],
              );

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
                child: narrow ? mobileHeader : desktopHeader,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, {required bool compact}) {
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),

            if (!compact) ...[
              const SizedBox(width: 10),
              Text(
                'Nexora',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          setState(() {
            _exploreQuery = value.trim();
            _exploreCategory = 'all';
            _selectedIndex = 1;
          });
        },
        decoration: InputDecoration(
          hintText: context.tr('Caută produse, branduri, categorii...'),
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.045),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.3,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
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
        icon: Icon(icon, size: 20),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _buildSellButton(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);

    if (compact) {
      return IconButton.filled(
        onPressed: () => _selectSection(16),
        icon: const Icon(Icons.add_rounded),
        tooltip: context.tr('Adaugă anunț'),
      );
    }

    return FilledButton.icon(
      onPressed: () {
        _selectSection(16);
      },
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        context.tr('Vinde'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    final itemColor =
        color ?? theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: itemColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
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
    final viewportSize = MediaQuery.sizeOf(context);
    final menuMaxHeight = (viewportSize.height - 96)
        .clamp(320.0, 620.0)
        .toDouble();
    final menuWidth = (viewportSize.width - 24).clamp(280.0, 360.0).toDouble();
    final menuContentWidth = menuWidth - 28;

    return PopupMenuButton<String>(
      tooltip: context.tr('Cont'),
      offset: const Offset(0, 12),
      elevation: 16,
      color: theme.colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
        maxHeight: menuMaxHeight,
      ),
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

          case 'balance':
            setState(() {
              _selectedIndex = 17;
            });
            break;

          case 'promotions':
            setState(() {
              _selectedIndex = 18;
            });
            break;

          case 'addresses':
            setState(() {
              _selectedIndex = 19;
            });
            break;

          case 'security':
            setState(() {
              _selectedIndex = 20;
            });
            break;

          case 'cards':
            setState(() {
              _selectedIndex = 15;
            });
            break;

          case 'reviews':
            setState(() {
              _selectedIndex = 11;
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
                width: menuContentWidth,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.10,
                          ),
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
                title: context.tr('Autentificare'),
                subtitle: context.tr('Intră în contul tău'),
                color: theme.colorScheme.primary,
              ),
            ),

            PopupMenuItem<String>(
              value: 'register',
              child: _profileMenuItem(
                context,
                icon: Icons.person_add_alt_1_rounded,
                title: context.tr('Creează cont'),
                subtitle: context.tr('Înregistrează-te gratuit'),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Cont securizat Nexora',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.50,
                      ),
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
              width: menuContentWidth,
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
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
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
              title: context.tr('Profilul meu'),
              subtitle: context.tr('Vezi și editează profilul'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'listings',
            child: _profileMenuItem(
              context,
              icon: Icons.inventory_2_outlined,
              title: context.tr('Anunțurile mele'),
              subtitle: context.tr('Produsele pe care le vinzi'),
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'orders',
            child: _profileMenuItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: context.tr('Comenzile mele'),
              subtitle: context.tr('Produsele cumpărate'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'balance',
            child: _profileMenuItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: context.tr('Sold și încasări'),
              subtitle: context.tr('Tranzacții și retrageri'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'sales',
            child: _profileMenuItem(
              context,
              icon: Icons.sell_outlined,
              title: context.tr('Vânzările mele'),
              subtitle: context.tr('Produsele vândute'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'cards',
            child: _profileMenuItem(
              context,
              icon: Icons.credit_card_outlined,
              title: context.tr('Cardurile mele'),
              subtitle: context.tr('Metodele tale de plată'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'promotions',
            child: _profileMenuItem(
              context,
              icon: Icons.rocket_launch_outlined,
              title: context.tr('Promovări'),
              subtitle: context.tr('Promovează anunțurile tale'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'addresses',
            child: _profileMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: context.tr('Adrese salvate'),
              subtitle: context.tr('Adrese pentru livrare'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'reviews',
            child: _profileMenuItem(
              context,
              icon: Icons.star_border_rounded,
              title: context.tr('Recenziile mele'),
              subtitle: context.tr('Evaluările primite de la cumpărători'),
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'settings',
            child: _profileMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: context.tr('Setări'),
              subtitle: context.tr('Preferințe și securitate'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'security',
            child: _profileMenuItem(
              context,
              icon: Icons.security_outlined,
              title: context.tr('Securitate'),
              subtitle: context.tr('Parolă, 2FA și sesiuni'),
            ),
          ),

          PopupMenuItem<String>(
            value: 'help',
            child: _profileMenuItem(
              context,
              icon: Icons.help_outline_rounded,
              title: context.tr('Ajutor și suport'),
              subtitle: context.tr('Ai nevoie de ajutor?'),
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
                    color: theme.colorScheme.error.withValues(alpha: 0.09),
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
                  context.tr('Deconectare'),
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
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.16),
          ),
        ),
        child: isLoggedIn && avatar.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
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

  Widget _buildMobileQuickMenu(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: context.tr('Mai multe'),
      onSelected: _selectSection,
      icon: const Icon(Icons.more_horiz_rounded),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 8,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite_border_rounded),
            title: Text(context.tr('Favorite')),
          ),
        ),
        PopupMenuItem(
          value: 12,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_none_rounded),
            title: Text(context.tr('Notificări')),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    const sections = [0, 1, 16, 2, 6];
    final accountSections = {3, 4, 5, 6, 7, 9, 11, 13, 14, 15, 17, 18, 19, 20};
    final selected = switch (_selectedIndex) {
      0 => 0,
      1 => 1,
      16 => 2,
      2 => 3,
      _ when accountSections.contains(_selectedIndex) => 4,
      _ => 0,
    };

    return NavigationBar(
      height: 68,
      selectedIndex: selected,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      onDestinationSelected: (index) => _selectSection(sections[index]),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: context.tr('Acasă'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore_rounded),
          label: context.tr('Explorează'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.add_circle_outline_rounded),
          selectedIcon: const Icon(Icons.add_circle_rounded),
          label: context.tr('Vinde'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
          label: context.tr('Mesaje'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: context.tr('Profil'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final authenticated = context.watch<AuthProvider>().isLoggedIn;
    const publicSections = {0, 1, 4, 5};

    if (!authenticated && !publicSections.contains(_selectedIndex)) {
      return const LoginPage();
    }

    switch (_selectedIndex) {
      case 0:
        return WebHome(
          onExplore: () {
            setState(() {
              _exploreQuery = '';
              _exploreCategory = 'all';
              _selectedIndex = 1;
            });
          },
          onCategory: (category) {
            setState(() {
              _exploreQuery = '';
              _exploreCategory = category;
              _selectedIndex = 1;
            });
          },
        );

      case 1:
        return WebExplore(
          key: ValueKey('$_exploreQuery|$_exploreCategory'),
          initialQuery: _exploreQuery,
          initialCategory: _exploreCategory,
        );

      case 2:
        return const MessagesTab();

      case 3:
        return const OrderPage();

      case 4:
        return const LoginPage();

      case 5:
        return const RegisterPage();

      case 6:
        return ProfilePage(
          embedded: true,
          onNavigate: (destination) {
            switch (destination) {
              case 'listings':
                _selectSection(7);
                break;
              case 'sales':
                _selectSection(9);
                break;
              case 'reviews':
                _selectSection(11);
                break;
            }
          },
          onLogout: () async {
            await context.read<AuthProvider>().logout();
            if (mounted) setState(() => _selectedIndex = 0);
          },
        );

      case 7:
        return const MyListingsPage();

      case 8:
        return const FavoritesPage();

      case 9:
        return const OrderPage(initialTab: 1);

      case 11:
        return const MyReviewsPage();

      case 12:
        return const NotificationsPage();

      case 13:
        return _buildSettings(context);

      case 14:
        return const SupportPage();

      case 15:
        return const SavedCardsPage(embedded: true);

      case 16:
        return SellPage(
          embedded: true,
          onPublished: () {
            if (mounted) setState(() => _selectedIndex = 7);
          },
        );

      case 17:
        return const SoldPage();

      case 18:
        return const PromotionPage();

      case 19:
        return const AddressesPage();

      case 20:
        return const SecurityPage();

      default:
        return const WebHome();
    }
  }

  Widget _buildSettings(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 14 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Setări'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Gestionează preferințele, securitatea și datele contului.',
                ),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: compact ? 18 : 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 720
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _settingsCard(
                        context,
                        width: width,
                        icon: Icons.security_outlined,
                        title: context.tr('Securitate'),
                        subtitle: context.tr(
                          'Parolă, autentificare 2FA și sesiuni active',
                        ),
                        page: const SecurityPage(),
                      ),
                      _settingsCard(
                        context,
                        width: width,
                        icon: Icons.notifications_outlined,
                        title: context.tr('Preferințe notificări'),
                        subtitle: context.tr(
                          'Mesaje, oferte și activitatea contului',
                        ),
                        page: const NotificationSettingsPage(),
                      ),
                      _settingsCard(
                        context,
                        width: width,
                        icon: Icons.dark_mode_outlined,
                        title: context.tr('Tema aplicației'),
                        subtitle: context.tr('Luminos, întunecat sau automat'),
                        page: const ThemeSettingsPage(),
                      ),
                      _settingsCard(
                        context,
                        width: width,
                        icon: Icons.location_on_outlined,
                        title: context.tr('Adrese salvate'),
                        subtitle: context.tr(
                          'Gestionează adresele pentru livrare',
                        ),
                        page: const AddressesPage(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
