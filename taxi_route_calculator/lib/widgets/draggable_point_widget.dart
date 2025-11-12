import 'package:flutter/material.dart';
import 'package:taxi_route_calculator/models/route_point.dart';

/// Виджет для визуального отображения точки маршрута с возможностью перетаскивания
class DraggablePointWidget extends StatelessWidget {
  final RoutePointType type;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DraggablePointWidget({
    super.key,
    required this.type,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isFromPoint = type == RoutePointType.from;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isFromPoint ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isFromPoint ? Icons.my_location : Icons.location_on,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Виджет-обертка для отображения точки с возможностью перетаскивания
class MapPointOverlay extends StatelessWidget {
  final RoutePointType type;
  final String title;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const MapPointOverlay({
    super.key,
    required this.type,
    required this.title,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isFromPoint = type == RoutePointType.from;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Подпись
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isFromPoint ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Точка
        GestureDetector(
          onPanStart: (_) => onDragStart?.call(),
          onPanEnd: (_) => onDragEnd?.call(),
          child: DraggablePointWidget(
            type: type,
            onLongPress: onDragStart,
          ),
        ),
      ],
    );
  }
}