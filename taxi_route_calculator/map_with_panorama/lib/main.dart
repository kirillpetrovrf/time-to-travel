import 'package:common/common.dart';
import 'package:flutter/material.dart' hide TextStyle;
import 'package:map_with_panorama/listeners/layers_geo_object_tap_listener.dart';
import 'package:map_with_panorama/utils/extension_utils.dart';
import 'package:yandex_maps_mapkit/init.dart' as init;
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/places.dart';
import 'package:yandex_maps_mapkit/runtime.dart';
import 'package:yandex_maps_mapkit/widgets.dart';
import 'package:flutter/material.dart' as flutter show TextStyle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /**
   * Replace "your_api_key" with a valid developer key.
   */
  await init.initMapkit(apiKey: "2f1d6a75-b751-4077-b305-c6abaea0b542");

  runApp(
    MaterialApp(
      title: 'Такси - Панорамы',
      theme: MapkitFlutterTheme.lightTheme,
      darkTheme: MapkitFlutterTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MapkitFlutterApp(),
    ),
  );
}

class MapkitFlutterApp extends StatefulWidget {
  const MapkitFlutterApp({super.key});

  @override
  State<MapkitFlutterApp> createState() => _MapkitFlutterAppState();
}

class _MapkitFlutterAppState extends State<MapkitFlutterApp> with WidgetsBindingObserver {
  static const _startPosition = CameraPosition(
    const Point(latitude: 55.751244, longitude: 37.618423),
    zoom: 16.0,
    azimuth: 0.0,
    tilt: 0.0,
  );

  late final _mapInputListener = MapInputListenerImpl(
    onMapTapCallback: (map, point) {
      _searchSession = _panoramaService.findNearest(
        point,
        _panoramaSearchListener,
      );
    },
    onMapLongTapCallback: (_, __) {},
  );

  late final _geoObjectTapListener = LayersGeoObjectTapListenerImpl(
    onObjectTapped: (event) {
      final geoObject = event.geoObject;
      final airshipTapInto = geoObject.airshipTapInfo;
      final point = geoObject.point;

      if (airshipTapInto != null && point != null) {
        _navigateToPanorama(airshipTapInto.panoramaId);
        return true;
      }
      return false;
    },
  );

  late final _panoramaSearchListener = PanoramaServiceSearchListener(
    onPanoramaSearchResult: _navigateToPanorama,
    onPanoramaSearchError: (error) {
      String errorMessage = switch (error) {
        final NotFoundError _ => "🔍 Панорама не найдена в этом месте",
        final RemoteError _ => "🌐 Ошибка сервера панорам",
        final NetworkError _ => "📡 Ошибка сети - проверьте подключение",
        _ => "❌ Неизвестная ошибка",
      };
      showSnackBar(context, errorMessage);
    },
  );

  late final PanoramaService _panoramaService;

  PanoramaServiceSearchSession? _searchSession;
  MapWindow? _mapWindow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Такси - Панорамные Виды'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Карта занимает весь экран
          Positioned.fill(
            child: FlutterMapWidget(
              onMapCreated: _setupMap,
              onMapDispose: _onMapDispose,
            ),
          ),
          // Компактная панель внизу
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Text('📸', style: flutter.TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Нажмите на карту для панорамы',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🔵 Синие точки - доступные панорамы улиц',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '📷 Полезно для ознакомления с местностью',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.paused) {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  void _setupMap(MapWindow mapWindow) {
    _mapWindow = mapWindow;
    mapWindow.map.move(_startPosition);

    mapWindow.map.addInputListener(_mapInputListener);
    mapWindow.map.addTapListener(_geoObjectTapListener);

    _panoramaService = PlacesFactory.instance.createPanoramaService();

    PlacesFactory.instance.createPanoramaLayer(mapWindow)
      ..setStreetPanoramaVisible(true)
      ..setAirshipPanoramaVisible(true);
    
    print("🚖 Карта с панорамами инициализирована для такси приложения");
  }

  void _onMapDispose() {
    _mapWindow?.map.removeInputListener(_mapInputListener);
    _mapWindow?.map.removeTapListener(_geoObjectTapListener);
    _mapWindow = null;
  }

  void _navigateToPanorama(String panoramaId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PanoramaWidget(
            onPanoramaCreated: (panoramaPlayer) {
              panoramaPlayer
                ..openPanorama(panoramaId)
                ..enableMove()
                ..enableRotation()
                ..enableZoom()
                ..enableMarkers()
                ..enableCompanies()
                ..enableLoadingWheel();
            },
            platformViewType: PlatformViewType.Hybrid,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.ease;
          final tween = Tween(begin: 0.0, end: 1.0);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          return FadeTransition(
            opacity: tween.animate(curvedAnimation),
            child: child,
          );
        },
      ),
    );
  }
}
