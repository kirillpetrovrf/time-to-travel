import 'package:flutter/material.dart';
import '../core/constants.dart';

class OfflineMapsButton extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const OfflineMapsButton({
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
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.download_outlined,
          color: AppColors.black,
          size: 24,
        ),
        onPressed: onPressed ?? () {
          // TODO: Открыть управление офлайн картами
        },
      ),
    );
  }
}
