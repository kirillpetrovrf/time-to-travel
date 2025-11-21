import 'package:flutter/cupertino.dart';

final class MapControlButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final EdgeInsets margin;
  final double size;
  final VoidCallback? onPressed;

  const MapControlButton({
    super.key,
    required this.icon,
    this.iconColor = CupertinoColors.white,
    this.backgroundColor = CupertinoColors.activeBlue,
    this.margin = EdgeInsets.zero,
    this.size = 28.0,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: onPressed,
        child: Icon(
          icon,
          color: iconColor,
          size: size,
        ),
      ),
    );
  }
}