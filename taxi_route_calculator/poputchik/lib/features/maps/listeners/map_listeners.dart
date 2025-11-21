import 'package:yandex_maps_mapkit/mapkit.dart';

// Camera Position Listener Implementation (as MapCameraListener)
final class CameraPositionListenerImpl implements MapCameraListener {
  final void Function(
    Map map,
    CameraPosition cameraPosition,
    CameraUpdateReason cameraUpdateReason,
    bool isFinished,
  ) _onCameraPositionChanged;

  const CameraPositionListenerImpl(this._onCameraPositionChanged);

  @override
  void onCameraPositionChanged(
    Map map,
    CameraPosition cameraPosition,
    CameraUpdateReason cameraUpdateReason,
    bool finished,
  ) {
    _onCameraPositionChanged(map, cameraPosition, cameraUpdateReason, finished);
  }
}

// Map Object Tap Listener Implementation
final class MapObjectTapListenerImpl implements MapObjectTapListener {
  final bool Function(MapObject, Point) onMapObjectTapped;

  const MapObjectTapListenerImpl({required this.onMapObjectTapped});

  @override
  bool onMapObjectTap(MapObject mapObject, Point point) {
    return onMapObjectTapped(mapObject, point);
  }
}

// Map Size Changed Listener Implementation
final class MapSizeChangedListenerImpl implements MapSizeChangedListener {
  final void Function(MapWindow, int, int) onMapWindowSizeChange;

  const MapSizeChangedListenerImpl({required this.onMapWindowSizeChange});

  @override
  void onMapWindowSizeChanged(
    MapWindow mapWindow,
    int newWidth,
    int newHeight,
  ) {
    onMapWindowSizeChange(mapWindow, newWidth, newHeight);
  }
}

// Map Input Listener Implementation
final class MapInputListenerImpl implements MapInputListener {
  final void Function(Map, Point) onMapTapCallback;
  final void Function(Map, Point) onMapLongTapCallback;

  const MapInputListenerImpl({
    required this.onMapTapCallback,
    required this.onMapLongTapCallback,
  });

  @override
  void onMapTap(Map map, Point point) => onMapTapCallback(map, point);

  @override
  void onMapLongTap(Map map, Point point) => onMapLongTapCallback(map, point);
}

// Map Object Drag Listener Implementation
final class MapObjectDragListenerImpl implements MapObjectDragListener {
  final void Function(MapObject) onMapObjectDragStartCallback;
  final void Function(MapObject, Point) onMapObjectDragCallback;
  final void Function(MapObject) onMapObjectDragEndCallback;

  const MapObjectDragListenerImpl({
    required this.onMapObjectDragStartCallback,
    required this.onMapObjectDragCallback,
    required this.onMapObjectDragEndCallback,
  });

  @override
  void onMapObjectDragStart(MapObject mapObject) =>
      onMapObjectDragStartCallback(mapObject);

  @override
  void onMapObjectDrag(MapObject mapObject, Point point) =>
      onMapObjectDragCallback(mapObject, point);

  @override
  void onMapObjectDragEnd(MapObject mapObject) =>
      onMapObjectDragEndCallback(mapObject);
}