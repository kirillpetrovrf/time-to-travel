import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Виджет логотипа Time to Travel
class TimeToTravelLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const TimeToTravelLogo({
    super.key,
    this.size = 120,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Используем PNG логотип из assets
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (primaryColor ?? const Color(0xFFDC2626)).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback к программному логотипу если PNG не загружается
            return _buildFallbackLogo();
          },
        ),
      ),
    );
  }

  // Fallback логотип на случай если PNG не загружается
  Widget _buildFallbackLogo() {
    final primary = primaryColor ?? const Color(0xFFDC2626);
    final secondary = secondaryColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
      ),
      child: Icon(
        CupertinoIcons.car_detailed,
        size: size * 0.5,
        color: secondary,
      ),
    );
  }
}
