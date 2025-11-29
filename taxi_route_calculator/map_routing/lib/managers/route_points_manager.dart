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
      _updateFromPlacemark();
    } else {
      _toPoint = point;
      _updateToPlacemark();
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

  void _updateFromPlacemark() {
    print("� Updating FROM placemark...");
    
    if (_fromPoint != null) {
      // Если placemark еще не создан, создаем его
      if (_fromPlacemark == null) {
        print("✅ Creating new FROM placemark");
        _fromPlacemark = mapObjects.addPlacemark();
        _fromPlacemark!.setIcon(_fromImageProvider);
        _fromPlacemark!.setIconStyle(const IconStyle(scale: 2.0, zIndex: 20.0));
      }
      
      // Обновляем геометрию существующего placemark
      print("📍 Updating FROM placemark geometry");
      _fromPlacemark!.geometry = _fromPoint!;
      print("✅ FROM placemark updated");
    } else {
      // Удаляем placemark только если точка убрана
      if (_fromPlacemark != null) {
        try {
          print("🗑️ Removing FROM placemark");
          mapObjects.remove(_fromPlacemark!);
        } catch (e) {
          print("⚠️ Error removing FROM placemark: $e");
        }
        _fromPlacemark = null;
      }
    }
  }

  void _updateToPlacemark() {
    print("� Updating TO placemark...");
    
    if (_toPoint != null) {
      // Если placemark еще не создан, создаем его
      if (_toPlacemark == null) {
        print("✅ Creating new TO placemark");
        _toPlacemark = mapObjects.addPlacemark();
        _toPlacemark!.setIcon(_toImageProvider);
        _toPlacemark!.setIconStyle(const IconStyle(scale: 2.0, zIndex: 20.0));
      }
      
      // Обновляем геометрию существующего placemark
      print("📍 Updating TO placemark geometry");
      _toPlacemark!.geometry = _toPoint!;
      print("✅ TO placemark updated");
    } else {
      // Удаляем placemark только если точка убрана
      if (_toPlacemark != null) {
        try {
          print("🗑️ Removing TO placemark");
          mapObjects.remove(_toPlacemark!);
        } catch (e) {
          print("⚠️ Error removing TO placemark: $e");
        }
        _toPlacemark = null;
      }
    }
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

  void clearAll() {
    print("🗑️ Clearing all route points");
    removePoint(RoutePointType.from);
    removePoint(RoutePointType.to);
  }
}