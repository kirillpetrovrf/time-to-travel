import 'package:flutter/material.dart';
import '../core/constants.dart';

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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.my_location,
          color: AppColors.black,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
