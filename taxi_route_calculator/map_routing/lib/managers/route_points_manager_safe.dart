import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/mapkit.dart';
import '../widgets/point_type_selector.dart';

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

  late final _fromImageProvider = 
      image_provider.ImageProvider.fromImageProvider(
          const AssetImage("assets/ic_point.png"));

  late final _toImageProvider = 
      image_provider.ImageProvider.fromImageProvider(
          const AssetImage("assets/ic_finish_point.png"));

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
          _fromPlacemark!.setIcon(_fromImageProvider);
          _fromPlacemark!.setIconStyle(const IconStyle(scale: 2.0, zIndex: 20.0));
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
          _toPlacemark!.setIcon(_toImageProvider);
          _toPlacemark!.setIconStyle(const IconStyle(scale: 2.0, zIndex: 20.0));
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
}