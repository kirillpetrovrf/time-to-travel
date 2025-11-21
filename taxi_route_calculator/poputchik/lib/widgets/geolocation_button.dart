import 'package:flutter/cupertino.dart';

class GeolocationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const GeolocationButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.location_fill,
          color: CupertinoColors.systemYellow.resolveFrom(context),
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}