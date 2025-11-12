// Модель адреса с координатами
import 'package:yandex_maps_mapkit/mapkit.dart';

class AddressPoint {
  final String address;
  final Point point;
  
  const AddressPoint({
    required this.address,
    required this.point,
  });
  
  AddressPoint copyWith({
    String? address,
    Point? point,
  }) {
    return AddressPoint(
      address: address ?? this.address,
      point: point ?? this.point,
    );
  }
  
  @override
  String toString() => 'AddressPoint($address, ${point.latitude}, ${point.longitude})';
}
