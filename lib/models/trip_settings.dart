import 'package:cloud_firestore/cloud_firestore.dart';

class TripSettings {
  final String id;
  final List<String> departureTimes;
  final List<String> donetskPickupPoints;
  final List<String> rostovPickupPoints;
  final List<String> donetskDropoffPoints;
  final List<String> rostovDropoffPoints;
  final Map<String, int> pricing;
  final int maxPassengers;
  final bool isActive;
  final DateTime updatedAt;

  TripSettings({
    required this.id,
    required this.departureTimes,
    required this.donetskPickupPoints,
    required this.rostovPickupPoints,
    required this.donetskDropoffPoints,
    required this.rostovDropoffPoints,
    required this.pricing,
    required this.maxPassengers,
    required this.isActive,
    required this.updatedAt,
  });

  factory TripSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripSettings(
      id: doc.id,
      departureTimes: List<String>.from(data['departureTimes'] ?? []),
      donetskPickupPoints: List<String>.from(data['donetskPickupPoints'] ?? []),
      rostovPickupPoints: List<String>.from(data['rostovPickupPoints'] ?? []),
      donetskDropoffPoints: List<String>.from(
        data['donetskDropoffPoints'] ?? [],
      ),
      rostovDropoffPoints: List<String>.from(data['rostovDropoffPoints'] ?? []),
      pricing: Map<String, int>.from(data['pricing'] ?? {}),
      maxPassengers: data['maxPassengers'] ?? 8,
      isActive: data['isActive'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'departureTimes': departureTimes,
      'donetskPickupPoints': donetskPickupPoints,
      'rostovPickupPoints': rostovPickupPoints,
      'donetskDropoffPoints': donetskDropoffPoints,
      'rostovDropoffPoints': rostovDropoffPoints,
      'pricing': pricing,
      'maxPassengers': maxPassengers,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TripSettings copyWith({
    String? id,
    List<String>? departureTimes,
    List<String>? donetskPickupPoints,
    List<String>? rostovPickupPoints,
    List<String>? donetskDropoffPoints,
    List<String>? rostovDropoffPoints,
    Map<String, int>? pricing,
    int? maxPassengers,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return TripSettings(
      id: id ?? this.id,
      departureTimes: departureTimes ?? this.departureTimes,
      donetskPickupPoints: donetskPickupPoints ?? this.donetskPickupPoints,
      rostovPickupPoints: rostovPickupPoints ?? this.rostovPickupPoints,
      donetskDropoffPoints: donetskDropoffPoints ?? this.donetskDropoffPoints,
      rostovDropoffPoints: rostovDropoffPoints ?? this.rostovDropoffPoints,
      pricing: pricing ?? this.pricing,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TripSettings getDefault() {
    return TripSettings(
      id: 'default',
      departureTimes: ['06:00', '09:00', '13:00', '16:00'],
      // Места посадки в Донецке (первая остановка маршрута)
      donetskPickupPoints: ['Центральный автовокзал'],
      // Места посадки в Ростове-на-Дону (последняя остановка маршрута)
      rostovPickupPoints: ['Главный автовокзал'],
      // Места высадки в Донецке
      donetskDropoffPoints: ['Центральный автовокзал'],
      // Места высадки в Ростове-на-Дону
      rostovDropoffPoints: ['Главный автовокзал'],
      pricing: {
        'groupTripPrice': 2000,
        'individualTripPrice': 8000,
        'individualTripNightPrice': 10000,
      },
      maxPassengers: 8,
      isActive: true,
      updatedAt: DateTime.now(),
    );
  }
}
