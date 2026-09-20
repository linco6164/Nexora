import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'home_tab.dart';
import 'message_tab.dart';
import 'profile_page.dart';
import 'favorites_page.dart';
import 'notifications_page.dart';
import 'floating_nav_bar.dart';
import 'nexora_logo.dart';
import 'sell_page.dart';
import 'explore_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  bool _navBarCollapsed = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const HomeTab(),
      const ExploreTab(),
      const MessagesTab(),

      ProfilePage(
        onNavBarCollapse: _setNavBarCollapsed,
      ),
    ];
  }

  // ============================================================
  // NAVBAR COLLAPSE
  // ============================================================

  void _setNavBarCollapsed(bool collapsed) {
    if (_navBarCollapsed == collapsed) return;

    if (!mounted) return;

    setState(() {
      _navBarCollapsed = collapsed;
    });
  }

  // ============================================================
  // DETECTĂM SCROLL-UL DIN ORICARE TAB
  // ============================================================

  bool _handleScrollNotification(
    ScrollNotification notification,
  ) {
    // Ne interesează doar scroll-ul făcut efectiv
    // de utilizator.
    if (notification is UserScrollNotification) {
      final direction = notification.direction;

      // Scroll în sus în conținut
      if (direction == ScrollDirection.reverse) {
        _setNavBarCollapsed(true);
      }

      // Scroll în jos în conținut
      if (direction == ScrollDirection.forward) {
        _setNavBarCollapsed(false);
      }
    }

    return false;
  }

  // ============================================================
  // TAB
  // ============================================================

  void _onItemTapped(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _selectedIndex = index;

      // Când schimbăm tabul, navbarul revine.
      _navBarCollapsed = false;
    });
  }

  // ============================================================
  // SELL
  // ============================================================

  void _onSellTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellPage(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: const Row(
          children: [
            NexoraLogo(size: 32),
            SizedBox(width: 10),
          ],
        ),

        actions: [
          // FAVORITE
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FavoritesPage(),
                ),
              );
            },
          ),

          // NOTIFICATIONS
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),

      // Navbarul este plutitor peste conținut.
      extendBody: true,

      // ==========================================================
      // TOATE TABURILE SUNT ASCULTATE AICI
      // ==========================================================

      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,

        child: IndexedStack(
          index: _selectedIndex.clamp(
            0,
            _pages.length - 1,
          ),
          children: _pages,
        ),
      ),

      // ==========================================================
      // NAVBAR
      // ==========================================================

      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onSellTapped: _onSellTapped,
        isCollapsed: _navBarCollapsed,
      ),
    );
  }
}