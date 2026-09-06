import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onSellTapped;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onSellTapped,
  });

  static const _leftItems = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Acasă', index: 0),
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explorează', index: 1),
  ];

  static const _rightItems = [
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Mesaje', index: 2),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', index: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bara de fundal
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _leftItems.map((item) => _NavItem(
                        icon: item.icon,
                        activeIcon: item.activeIcon,
                        label: item.label,
                        isSelected: selectedIndex == item.index,
                        onTap: () => onItemTapped(item.index),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(width: 72), // spațiu pentru butonul central
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _rightItems.map((item) => _NavItem(
                        icon: item.icon,
                        activeIcon: item.activeIcon,
                        label: item.label,
                        isSelected: selectedIndex == item.index,
                        onTap: () => onItemTapped(item.index),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Butonul central "Sell", proeminent, ridicat deasupra barei
          Positioned(
            bottom: 28,
            child: GestureDetector(
              onTap: onSellTapped,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.add, color: colorScheme.onPrimary, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}