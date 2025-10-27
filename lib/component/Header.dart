import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, this.height = kToolbarHeight});

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    final formattedDate =
        '$dayName, ${now.day.toString().padLeft(2, '0')} $monthName';

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface.withOpacity(0.87);

    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      iconTheme: IconThemeData(color: onSurface),
      title: Text(
        formattedDate,
        style: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: IconButton(
              key: ValueKey<bool>(isDark),
              tooltip: isDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              icon: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                color: onSurface,
              ),
              onPressed: () {
                AdaptiveTheme.of(context).setThemeMode(
                  isDark ? AdaptiveThemeMode.light : AdaptiveThemeMode.dark,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
