import 'package:flutter/material.dart';
import '../managers/route_points_manager.dart';

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
              Icons.place,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    RoutePointType type,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = selectedType == type;
    
    return ElevatedButton.icon(
      onPressed: () => onTypeChanged(type),
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4.0 : 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}