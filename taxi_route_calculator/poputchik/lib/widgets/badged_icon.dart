import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BadgedIcon extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final Color? badgeColor;

  const BadgedIcon({
    super.key,
    required this.icon,
    this.badgeCount,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount == null || badgeCount! <= 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: badgeColor ?? const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: CupertinoColors.systemBackground,
                width: 1,
              ),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              badgeCount! > 99 ? '99+' : badgeCount.toString(),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
