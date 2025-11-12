import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/mapkit.dart';
import '../models/route_point.dart';

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

  // Инициализация иконок
  Future<void> init() async {
    _fromIcon = await _createCircleIcon(Colors.red);
    _toIcon = await _createCircleIcon(Colors.blue);
  }

  // Создание круглой иконки заданного цвета
  Future<image_provider.ImageProvider> _createCircleIcon(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final size = 256.0;  // Большой размер для видимости
    final radius = size / 2;
    
    // Рисуем круг
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    // Белая обводка
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;  // Толстая обводка
    canvas.drawCircle(Offset(radius, radius), radius - 5.0, strokePaint);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    return image_provider.ImageProvider.fromImageProvider(
      MemoryImage(bytes)
    );
  }

  void setPoint(RoutePointType type, Point point) {
    print("🔧 Setting $type point to: ${point.latitude}, ${point.longitude}");
    
    if (type == RoutePointType.from) {
      _fromPoint = point;
      _safeUpdateFromPlacemark();
    } else {
      _toPoint = point;
      _safeUpdateToPlacemark();
    }
    
    _notifyPointsChanged();
  }

  void removePoint(RoutePointType type) {
    print("🗑️ Removing $type point");
    
    if (type == RoutePointType.from) {
      _fromPoint = null;
      if (_fromPlacemark != null) {
        try {
          mapObjects.remove(_fromPlacemark!);
        } catch (e) {
          print("⚠️ Error removing FROM placemark: $e");
        }
        _fromPlacemark = null;
      }
    } else {
      _toPoint = null;
      if (_toPlacemark != null) {
        try {
          mapObjects.remove(_toPlacemark!);
        } catch (e) {
          print("⚠️ Error removing TO placemark: $e");
        }
        _toPlacemark = null;
      }
    }
    
    _notifyPointsChanged();
  }

  void _safeUpdateFromPlacemark() {
    print("🔄 Safe updating FROM placemark...");
    
    if (_fromPoint != null) {
      print("📍 FROM point exists: ${_fromPoint!.latitude}, ${_fromPoint!.longitude}");
      
      // Если placemark не создан, создаем новый
      if (_fromPlacemark == null) {
        print("✅ Creating new FROM placemark");
        try {
          _fromPlacemark = mapObjects.addPlacemark();
          if (_fromIcon != null) {
            _fromPlacemark!.setIcon(_fromIcon!);
            _fromPlacemark!.setIconStyle(
              IconStyle(
                anchor: math.Point(0.5, 0.5),
                scale: 0.5,
                zIndex: 20.0,
              ),
            );
          }
          _fromPlacemark!.geometry = _fromPoint!;
          print("✅ FROM placemark created and added to map");
        } catch (e) {
          print("❌ Error creating FROM placemark: $e");
          _fromPlacemark = null;
          return;
        }
      } else {
        // Обновляем только геометрию существующего placemark
        try {
          print("📍 Updating FROM placemark geometry");
          _fromPlacemark!.geometry = _fromPoint!;
          print("✅ FROM placemark geometry updated successfully");
        } catch (e) {
          print("❌ Error updating FROM placemark geometry: $e");
          // Не пытаемся пересоздать, просто оставляем как есть
        }
      }
    }
    print("🔄 FROM placemark safe update completed");
  }

  void _safeUpdateToPlacemark() {
    print("🔄 Safe updating TO placemark...");
    
    if (_toPoint != null) {
      print("📍 TO point exists: ${_toPoint!.latitude}, ${_toPoint!.longitude}");
      
      // Если placemark не создан, создаем новый
      if (_toPlacemark == null) {
        print("✅ Creating new TO placemark");
        try {
          _toPlacemark = mapObjects.addPlacemark();
          if (_toIcon != null) {
            _toPlacemark!.setIcon(_toIcon!);
            _toPlacemark!.setIconStyle(
              IconStyle(
                anchor: math.Point(0.5, 0.5),
                scale: 0.5,
                zIndex: 20.0,
              ),
            );
          }
          _toPlacemark!.geometry = _toPoint!;
          print("✅ TO placemark created and added to map");
        } catch (e) {
          print("❌ Error creating TO placemark: $e");
          _toPlacemark = null;
          return;
        }
      } else {
        // Обновляем только геометрию существующего placemark
        try {
          print("📍 Updating TO placemark geometry");
          _toPlacemark!.geometry = _toPoint!;
          print("✅ TO placemark geometry updated successfully");
        } catch (e) {
          print("❌ Error updating TO placemark geometry: $e");
          // Не пытаемся пересоздать, просто оставляем как есть
        }
      }
    }
    print("🔄 TO placemark safe update completed");
  }

  void _notifyPointsChanged() {
    final points = <Point>[];
    if (_fromPoint != null) points.add(_fromPoint!);
    if (_toPoint != null) points.add(_toPoint!);
    
    print("📊 Notifying points changed: ${points.length} points total");
    onPointsChanged(points);
  }

  List<Point> get points {
    final result = <Point>[];
    if (_fromPoint != null) result.add(_fromPoint!);
    if (_toPoint != null) result.add(_toPoint!);
    return result;
  }

  Point? get fromPoint => _fromPoint;
  Point? get toPoint => _toPoint;

  void clearAllPoints() {
    print("🗑️ Clearing all route points");
    
    // Безопасное удаление FROM placemark
    if (_fromPlacemark != null) {
      print("🗑️ Removing RoutePointType.from point");
      try {
        _fromPlacemark!.parent.remove(_fromPlacemark!);
      } catch (e) {
        print("⚠️ Error removing FROM placemark: $e");
      }
      _fromPlacemark = null;
      _fromPoint = null;
    }
    
    // Безопасное удаление TO placemark  
    if (_toPlacemark != null) {
      print("🗑️ Removing RoutePointType.to point");
      try {
        _toPlacemark!.parent.remove(_toPlacemark!);
      } catch (e) {
        print("⚠️ Error removing TO placemark: $e");
      }
      _toPlacemark = null;
      _toPoint = null;
    }
    
    _notifyPointsChanged();
  }

  /// Тройной сброс для гарантированной очистки
  void forceTripleClear() {
    print("🔥🔥🔥 TRIPLE FORCE CLEAR - Выполняем тройной сброс...");
    
    for (int i = 1; i <= 3; i++) {
      print("🔥 Сброс #$i из 3");
      clearAllPoints();
      
      // Небольшая задержка между сбросами
      if (i < 3) {
        Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    print("✅ TRIPLE FORCE CLEAR завершен - все точки гарантированно удалены");
  }
}
