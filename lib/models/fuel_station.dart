import 'package:latlong2/latlong.dart';

class FuelStation {
  final String id;
  final String name;
  final LatLng location;
  final String? brand;
  final String? address;

  FuelStation({
    required this.id,
    required this.name,
    required this.location,
    this.brand,
    this.address,
  });

  factory FuelStation.fromOverpassJson(Map<String, dynamic> json) {
    // Handle both nodes and ways/relations
    double lat;
    double lon;

    if (json['lat'] != null && json['lon'] != null) {
      // Node
      lat = json['lat'].toDouble();
      lon = json['lon'].toDouble();
    } else if (json['center'] != null) {
      // Way or Relation
      lat = json['center']['lat'].toDouble();
      lon = json['center']['lon'].toDouble();
    } else {
      throw Exception('Invalid fuel station data: no coordinates found');
    }

    final tags = json['tags'] as Map<String, dynamic>? ?? {};

    return FuelStation(
      id: json['id'].toString(),
      name: tags['name'] as String? ?? 'Fuel Station',
      location: LatLng(lat, lon),
      brand: tags['brand'] as String?,
      address: tags['addr:street'] as String?,
    );
  }

  double distanceFrom(LatLng userLocation) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, userLocation, location) / 1000; // km
  }
}
