import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../data/route_info.dart';

class RouteInfoCard extends StatelessWidget {
  final RouteInfo? routeInfo;
  
  const RouteInfoCard({
    super.key,
    this.routeInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (routeInfo == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(AppPadding.medium),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.straighten,
                label: 'Расстояние',
                value: routeInfo!.distanceText,
              ),
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'Время',
                value: routeInfo!.durationText,
              ),
              _buildInfoItem(
                icon: Icons.attach_money,
                label: 'Стоимость',
                value: routeInfo!.priceText,
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Заказать такси
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppPadding.medium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
              ),
              child: const Text(
                'Заказать такси',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.41,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.gray,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.0,
            color: AppColors.gray,
            letterSpacing: -0.08,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: -0.41,
          ),
        ),
      ],
    );
  }
}
