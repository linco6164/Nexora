import 'package:flutter/material.dart';

import 'HomeTab.dart';
import 'MessagesTab.dart';
import 'ProfilePage.dart';
import 'FavoritesPage.dart';
import 'NotificationsPage.dart';
import 'FloatingNavBar.dart';
import 'NexoraLogo.dart';
import 'SellPage.dart'; // îl construim imediat

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    Center(child: Text('Explorează')), // placeholder pentru căutare/filtrare
    MessagesTab(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSellTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const NexoraLogo(size: 32),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex.clamp(0, _pages.length - 1),
        children: _pages,
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onSellTapped: _onSellTapped,
      ),
    );
  }
}
