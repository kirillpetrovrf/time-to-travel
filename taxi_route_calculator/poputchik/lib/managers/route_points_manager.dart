import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/mapkit.dart';

enum RoutePointType { from, to }

class RoutePointsManager {
  final MapObjectCollection mapObjects;
  final void Function(List<Point>) onPointsChanged;
  
  RoutePointsManager({
    required this.mapObjects,
    required this.onPointsChanged,
  });

  Point? _fromPoint;
  Point? _toPoint;
  
  PlacemarkMapObject? _fromPlacemark;
  PlacemarkMapObject? _toPlacemark;

  image_provider.ImageProvider? _fromIcon;
  image_provider.ImageProvider? _toIcon;

  // Инициализация иконок из assets
  Future<void> init() async {
    // Загружаем иконки из файлов PNG
    _fromIcon = image_provider.ImageProvider.fromImageProvider(
      const AssetImage("assets/user_forward.png")  // Розовая стрелка для начальной точки (ОТКУДА)
    );
    _toIcon = image_provider.ImageProvider.fromImageProvider(
      const AssetImage("assets/user_backward.png")  // Красный человек на жёлтом для конечной точки (КУДА)
    );
    print("✅ RoutePointsManager инициализирован с PNG иконками");
  }

  void setPoint(RoutePointType type, Point point) {
    print("🔧 Setting $type point to: ${point.latitude}, ${point.longitude}");
    
    if (type == RoutePointType.from) {
      _fromPoint = point;
      _updateFromPlacemark();
    } else {
      _toPoint = point;
      _updateToPlacemark();
    }
    
    _notifyPointsChanged();
  }

  void _updateFromPlacemark() {
    if (_fromPlacemark != null) {
      mapObjects.remove(_fromPlacemark!);
      _fromPlacemark = null;
    }
    
    if (_fromPoint != null && _fromIcon != null) {
      _fromPlacemark = mapObjects.addPlacemark()
        ..geometry = _fromPoint!
        ..setIcon(_fromIcon!)
        ..setIconStyle(
          IconStyle(
            anchor: math.Point(0.5, 0.5),
            scale: 0.8,
            zIndex: 20.0,
          ),
        );
    }
  }

  void _updateToPlacemark() {
    if (_toPlacemark != null) {
      mapObjects.remove(_toPlacemark!);
      _toPlacemark = null;
    }
    
    if (_toPoint != null && _toIcon != null) {
      _toPlacemark = mapObjects.addPlacemark()
        ..geometry = _toPoint!
        ..setIcon(_toIcon!)
        ..setIconStyle(
          IconStyle(
            anchor: math.Point(0.5, 0.5),
            scale: 0.8,
            zIndex: 20.0,
          ),
        );
    }
  }

  void _notifyPointsChanged() {
    final points = <Point>[];
    if (_fromPoint != null) points.add(_fromPoint!);
    if (_toPoint != null) points.add(_toPoint!);
    onPointsChanged(points);
  }

  List<Point> get points {
    final result = <Point>[];
    if (_fromPoint != null) result.add(_fromPoint!);
    if (_toPoint != null) result.add(_toPoint!);
    return result;
  }

  void clearAllPoints() {
    print('🗑️ Очистка всех точек маршрута');
    _fromPoint = null;
    _toPoint = null;
    
    if (_fromPlacemark != null) {
      mapObjects.remove(_fromPlacemark!);
      _fromPlacemark = null;
    }
    
    if (_toPlacemark != null) {
      mapObjects.remove(_toPlacemark!);
      _toPlacemark = null;
    }
    
    _notifyPointsChanged();
  }

  void forceTripleClear() {
    print('🔥🔥🔥 Тройной сброс всех точек маршрута!');
    for (int i = 0; i < 3; i++) {
      clearAllPoints();
    }
    print('✅ Тройной сброс завершен');
  }
}