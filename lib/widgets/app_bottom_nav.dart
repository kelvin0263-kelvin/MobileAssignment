import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = _navItems();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 8)),
            ],
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isActive = index == currentIndex;
              return _NavItem(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isActive: isActive,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<_BottomItem> _navItems() => const [
        _BottomItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        _BottomItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_turned_in_rounded,
          label: 'Task',
        ),
        _BottomItem(
          icon: Icons.book_outlined,
          activeIcon: Icons.book_rounded,
          label: 'Procedure',
        ),
        _BottomItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
        ),
      ];
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isActive ? activeIcon : icon, color: iconColor, size: 26),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: iconColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _BottomItem({required this.icon, required this.activeIcon, required this.label});
}
