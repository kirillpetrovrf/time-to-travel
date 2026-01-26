import 'dart:async';
import 'package:common/common.dart';
import '../location/location_listener_impl.dart'; // ✅ Локальный файл вместо несуществующего пакета
import 'package:rxdart/rxdart.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

final class CameraManager {
  final MapWindow _mapWindow;
  final LocationManager _locationManager;

  final _cameraPosition = BehaviorSubject<CameraPosition>();

  late final _cameraPositionListener = CameraPositionListenerImpl(
      (_, cameraPosition, __, ___) => _cameraPosition.add(cameraPosition));

  late final _locationListener = LocationListenerImpl(
    onLocationUpdate: (location) {
      _location = location;

      if (_isLocationUnknown) {
        _isLocationUnknown = false;
        moveCameraToUserLocation();
      }
    },
    onLocationStatusUpdate: (locationStatus) {},
  );

  Location? _location;
  var _isLocationUnknown = true;

  static const _mapDefaultZoom = 15.0;

  CameraManager(
    this._mapWindow,
    this._locationManager,
  );

  Stream<CameraPosition> get cameraPosition => _cameraPosition;

  void moveCameraToUserLocation() {
    _location?.let((location) {
      final map = _mapWindow.map;

      final cameraPosition = map.cameraPosition;
      final newZoom = cameraPosition.zoom < _mapDefaultZoom
          ? _mapDefaultZoom
          : cameraPosition.zoom;

      final newCameraPosition = CameraPosition(
        location.position,
        zoom: newZoom,
        azimuth: cameraPosition.azimuth,
        tilt: 0.0,
      );

      map.moveWithAnimation(
        newCameraPosition,
        const Animation(AnimationType.Smooth, duration: 1.0),
      );
    });
  }

  void start() {
    _stop();
    _mapWindow.map.addCameraListener(_cameraPositionListener);

    _locationManager.subscribeForLocationUpdates(
      LocationSubscriptionSettings(LocationUseInBackground.Disallow, Purpose.General),
      _locationListener,
    );
  }

  void dispose() {
    _stop();
    _cameraPosition.close();
  }

  void _stop() {
    _locationManager.unsubscribe(_locationListener);
    _mapWindow.map.removeCameraListener(_cameraPositionListener);
  }

  // Методы для управления зумом карты
  void zoomIn() {
    final map = _mapWindow.map;
    final currentPosition = map.cameraPosition;
    
    final newCameraPosition = CameraPosition(
      currentPosition.target,
      zoom: currentPosition.zoom + 1.0,
      azimuth: currentPosition.azimuth,
      tilt: currentPosition.tilt,
    );

    map.moveWithAnimation(
      newCameraPosition,
      const Animation(AnimationType.Smooth, duration: 0.3),
    );
  }

  void zoomOut() {
    final map = _mapWindow.map;
    final currentPosition = map.cameraPosition;
    
    final newCameraPosition = CameraPosition(
      currentPosition.target,
      zoom: (currentPosition.zoom - 1.0).clamp(1.0, 23.0),
      azimuth: currentPosition.azimuth,
      tilt: currentPosition.tilt,
    );

    map.moveWithAnimation(
      newCameraPosition,
      const Animation(AnimationType.Smooth, duration: 0.3),
    );
  }
}