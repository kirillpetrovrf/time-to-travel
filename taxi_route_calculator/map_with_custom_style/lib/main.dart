import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/material.dart' hide TextStyle;
import 'package:flutter/services.dart';
import 'package:yandex_maps_mapkit/init.dart' as init;
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:flutter/material.dart' as flutter show TextStyle;

Future<String> _readJsonFile(String filePath) async {
  return await rootBundle.loadString(filePath);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /**
   * Replace "your_api_key" with a valid developer key.
   */
  await init.initMapkit(apiKey: "2f1d6a75-b751-4077-b305-c6abaea0b542");
  final mapStyleJson = await _readJsonFile("assets/map_style.json");

  runApp(
    MaterialApp(
      title: 'Такси - Кастомный Стиль Карты',
      theme: MapkitFlutterTheme.lightTheme,
      darkTheme: MapkitFlutterTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MapkitFlutterApp(mapStyleJson: mapStyleJson),
    ),
  );
}

class MapkitFlutterApp extends StatefulWidget {
  final String mapStyleJson;

  const MapkitFlutterApp({super.key, required this.mapStyleJson});

  @override
  State<MapkitFlutterApp> createState() => _MapkitFlutterAppState();
}

class _MapkitFlutterAppState extends State<MapkitFlutterApp> {
  late MapWindow _mapWindow;
  String _currentStyleName = "Такси стиль";
  bool _isCustomStyleApplied = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Такси - Кастомизация Карты'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Карта занимает весь экран
          Positioned.fill(
            child: FlutterMapWidget(onMapCreated: _setupMap),
          ),
          // Панель управления стилями
          SafeArea(
            child: Positioned(
              top: 20,
              left: 20,
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Стиль карты для такси',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Текущий: $_currentStyleName',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _applyCustomStyle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCustomStyleApplied 
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade200,
                                foregroundColor: _isCustomStyleApplied 
                                    ? Colors.white 
                                    : Colors.black87,
                                elevation: _isCustomStyleApplied ? 4 : 1,
                              ),
                              child: Text(
                                'Такси стиль',
                                style: flutter.TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isCustomStyleApplied ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _applyDefaultStyle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_isCustomStyleApplied 
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade200,
                                foregroundColor: !_isCustomStyleApplied 
                                    ? Colors.white 
                                    : Colors.black87,
                                elevation: !_isCustomStyleApplied ? 4 : 1,
                              ),
                              child: Text(
                                'Стандартный стиль',
                                style: flutter.TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isCustomStyleApplied ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setupMap(MapWindow mapWindow) {
    _mapWindow = mapWindow;
    
    // Устанавливаем начальную позицию карты (Москва)
    _mapWindow.map.move(
      const CameraPosition(
        Point(latitude: 55.751244, longitude: 37.618423),
        zoom: 12.0,
        azimuth: 0.0,
        tilt: 0.0,
      ),
    );
    
    // Применяем кастомный стиль карты для такси
    _mapWindow.map.setMapStyle(widget.mapStyleJson);
    
    print("🚖 Карта инициализирована с кастомным стилем для такси");
  }

  void _applyCustomStyle() {
    _mapWindow.map.setMapStyle(widget.mapStyleJson);
    setState(() {
      _currentStyleName = "Такси стиль";
      _isCustomStyleApplied = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚖 Применен кастомный стиль для такси'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyDefaultStyle() {
    // Сбрасываем стиль карты к стандартному
    _mapWindow.map.setMapStyle("");
    setState(() {
      _currentStyleName = "Стандартный стиль";
      _isCustomStyleApplied = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗺️ Применен стандартный стиль карты'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
