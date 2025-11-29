import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:map_offline/features/region/state/region_ui_state.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

final class RegionsBottomSheet extends StatelessWidget {
  final RegionUiState regionUiState;
  final VoidCallback onShowButtonTap;
  final VoidCallback onStartDownloadButtonTapped;
  final VoidCallback onStopDownloadButtonTapped;
  final VoidCallback onPauseDownloadButtonTapped;
  final VoidCallback onDropDownloadButtonTapped;

  static const _regionStatesWhenProgressBarIsVisible = [
    OfflineCacheRegionState.Downloading,
    OfflineCacheRegionState.Paused,
    OfflineCacheRegionState.Completed,
  ];

  const RegionsBottomSheet({
    super.key,
    required this.regionUiState,
    required this.onShowButtonTap,
    required this.onStartDownloadButtonTapped,
    required this.onStopDownloadButtonTapped,
    required this.onPauseDownloadButtonTapped,
    required this.onDropDownloadButtonTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Детальное отладочное логирование
    if (regionUiState.state == OfflineCacheRegionState.Downloading) {
      print("🔄 DOWNLOADING Region ${regionUiState.id}: Progress=${(regionUiState.downloadProgress * 100).toStringAsFixed(2)}%, State=${regionUiState.state.name}");
    } else {
      print("📊 Region ${regionUiState.id}: State=${regionUiState.state.name}, Progress=${(regionUiState.downloadProgress * 100).toStringAsFixed(1)}%");
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ID: ${regionUiState.id}",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              "Название: ${regionUiState.name}",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10.0),
            Text(
              "Страна: ${regionUiState.country}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              "Города: ${regionUiState.cities}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              "Родительский ID: ${regionUiState.parentId}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Центр: (${regionUiState.center.latitude}, ${regionUiState.center.longitude})",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SimpleButton(
                  text: "Показать",
                  onPressed: onShowButtonTap,
                )
              ],
            ),
            const SizedBox(height: 10.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 10.0),
            Wrap(
              spacing: 10.0,
              children: [
                SimpleButton(
                  text: "Начать",
                  onPressed: () {
                    print("Starting download for region ${regionUiState.id}");
                    onStartDownloadButtonTapped();
                  },
                ),
                SimpleButton(
                  text: "Остановить",
                  onPressed: () {
                    print("Stopping download for region ${regionUiState.id}");
                    onStopDownloadButtonTapped();
                  },
                ),
                SimpleButton(
                  text: "Пауза",
                  onPressed: () {
                    print("Pausing download for region ${regionUiState.id}");
                    onPauseDownloadButtonTapped();
                  },
                ),
                SimpleButton(
                  text: "Удалить",
                  onPressed: () {
                    print("Dropping download for region ${regionUiState.id}");
                    onDropDownloadButtonTapped();
                  },
                ),
              ],
            ),
            // ТЕСТОВЫЙ индикатор - всегда показываем
            const SizedBox(height: 8.0),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Круглый индикатор прогресса
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: regionUiState.state == OfflineCacheRegionState.Completed 
                            ? 1.0 
                            : (regionUiState.downloadProgress > 0 ? regionUiState.downloadProgress : null),
                        strokeWidth: 6.0,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          regionUiState.state == OfflineCacheRegionState.Completed
                              ? Colors.green.shade600
                              : Colors.blue.shade600
                        ),
                      ),
                    ),
                    // Проценты в центре
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          regionUiState.state == OfflineCacheRegionState.Completed
                              ? "100%"
                              : "${(regionUiState.downloadProgress * 100).toStringAsFixed(0)}%",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Прогресс: ${regionUiState.downloadProgress.toStringAsFixed(3)}",
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_regionStatesWhenProgressBarIsVisible
                .contains(regionUiState.state)) ...[
              const SizedBox(height: 8.0),
            ] else ...[
              const SizedBox(height: 10.0)
            ],
            Text(
              "Состояние: ${regionUiState.state.name.toUpperCase()}",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              "Размер: ${regionUiState.size}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              "Время выпуска: ${regionUiState.releaseTime}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              "Время загрузки: ${regionUiState.downloadedReleaseTime}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
