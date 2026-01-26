import 'package:flutter/material.dart';
import '../models/route_point.dart'; // ✅ Используем единый RoutePointType

// enum RoutePointType удалён - используем из models/route_point.dart

class PointTypeSelector extends StatelessWidget {
  final RoutePointType selectedType;
  final Function(RoutePointType) onTypeChanged;
  
  const PointTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionButton(
              context,
              RoutePointType.from,
              'Откуда',
              Colors.green,
              Icons.my_location,
            ),
            const SizedBox(width: 8),
            _buildOptionButton(
              context,
              RoutePointType.to,
              'Куда',
              Colors.red,
              Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    RoutePointType type,
    String text,
    Color color,
    IconData icon,
  ) {
    final isSelected = selectedType == type;
    
    return InkWell(
      onTap: () {
        print("🎯 Выбран тип точки: $type");
        onTypeChanged(type);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.9),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}