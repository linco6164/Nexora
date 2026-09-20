import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onSellTapped;
  final bool isCollapsed;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onSellTapped,
    required this.isCollapsed,
  });

  static const _leftItems = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Acasă',
      index: 0,
    ),
    (
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explorează',
      index: 1,
    ),
  ];

  static const _rightItems = [
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Mesaje',
      index: 2,
    ),
    (
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      index: 3,
    ),
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
          // ============================================================
          // ANIMAȚIA ÎNTREGULUI NAVBAR
          // ============================================================
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: isCollapsed ? 1 : 0,
            ),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            builder: (context, progress, child) {
              // Bara începe să dispară după ce taburile
              // au început să se deplaseze.
              final backgroundProgress =
                  Curves.easeInCubic.transform(
                (progress * 1.35).clamp(0.0, 1.0),
              );

              final backgroundOpacity =
                  (1.0 - backgroundProgress).clamp(0.0, 1.0);

              // Micșorăm bara din ambele părți către centru.
              final backgroundScale =
                  1.0 - (backgroundProgress * 0.92);

              return Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: IgnorePointer(
                  ignoring: backgroundOpacity < 0.5,
                  child: Opacity(
                    opacity: backgroundOpacity,
                    child: Transform.scale(
                      alignment: Alignment.center,
                      scaleX: backgroundScale,
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha:
                                    0.08 * backgroundOpacity,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ============================================================
          // TABURILE
          // ============================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20,
            ),
            child: SizedBox(
              height: 64,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: isCollapsed ? 1 : 0,
                ),
                duration: const Duration(
                  milliseconds: 320,
                ),
                curve: Curves.easeInOutCubic,
                builder: (
                  context,
                  progress,
                  child,
                ) {
                  return Row(
                    children: [
                      // ==================================================
                      // STÂNGA
                      // ==================================================
                      Expanded(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _AnimatedNavItem(
                              icon: _leftItems[0].icon,
                              activeIcon:
                                  _leftItems[0].activeIcon,
                              label:
                                  _leftItems[0].label,
                              index:
                                  _leftItems[0].index,
                              selectedIndex:
                                  selectedIndex,
                              onTap: onItemTapped,
                              progress: progress,
                              direction: 1,
                              distance: 120,
                            ),

                            _AnimatedNavItem(
                              icon: _leftItems[1].icon,
                              activeIcon:
                                  _leftItems[1].activeIcon,
                              label:
                                  _leftItems[1].label,
                              index:
                                  _leftItems[1].index,
                              selectedIndex:
                                  selectedIndex,
                              onTap: onItemTapped,
                              progress: progress,
                              direction: 1,
                              distance: 85,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 72),

                      // ==================================================
                      // DREAPTA
                      // ==================================================
                      Expanded(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _AnimatedNavItem(
                              icon: _rightItems[0].icon,
                              activeIcon:
                                  _rightItems[0].activeIcon,
                              label:
                                  _rightItems[0].label,
                              index:
                                  _rightItems[0].index,
                              selectedIndex:
                                  selectedIndex,
                              onTap: onItemTapped,
                              progress: progress,
                              direction: -1,
                              distance: 85,
                            ),

                            _AnimatedNavItem(
                              icon: _rightItems[1].icon,
                              activeIcon:
                                  _rightItems[1].activeIcon,
                              label:
                                  _rightItems[1].label,
                              index:
                                  _rightItems[1].index,
                              selectedIndex:
                                  selectedIndex,
                              onTap: onItemTapped,
                              progress: progress,
                              direction: -1,
                              distance: 120,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ============================================================
          // BUTONUL CENTRAL +
          // RĂMÂNE PERMANENT VIZIBIL
          // ============================================================
          Positioned(
            bottom: 28,
            child: GestureDetector(
              onTap: onSellTapped,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                        alpha: 0.4,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// BUTON NAVBAR ANIMAT
// ========================================================================

class _AnimatedNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  final double progress;
  final double direction;
  final double distance;

  const _AnimatedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.progress,
    required this.direction,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isSelected =
        selectedIndex == index;

    // Deplasare către butonul +
    final translateX =
        direction * distance * progress;

    // Dispariție
    final opacity =
        (1.0 - progress).clamp(0.0, 1.0);

    // Micșorare
    final scale =
        1.0 - (progress * 0.45);

    return Expanded(
      child: IgnorePointer(
        ignoring: progress > 0.55,
        child: Transform.translate(
          offset: Offset(
            translateX,
            0,
          ),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _NavItem(
                icon: icon,
                activeIcon: activeIcon,
                label: label,
                isSelected: isSelected,
                onTap: () => onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================================================
// NAV ITEM
// ========================================================================

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
    final colorScheme =
        Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            isSelected
                ? activeIcon
                : icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}