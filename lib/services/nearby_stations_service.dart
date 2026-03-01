import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mileage_calculator/models/fuel_station.dart';

class NearbyStationsService {
  static final NearbyStationsService _instance =
      NearbyStationsService._internal();
  factory NearbyStationsService() => _instance;
  NearbyStationsService._internal();

  // Cache configuration
  List<FuelStation>? _cachedStations;
  DateTime? _cacheTimestamp;
  LatLng? _lastFetchLocation;
  static const _cacheDuration = Duration(minutes: 5);
  static const _minMovementDistance =
      100.0; // meters (reduced for better sensitivity)

  // Current search radius
  double _currentRadius = 3.0;
  double get currentRadius => _currentRadius;

  /// Get current location with permission handling
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get current position
    try {
      // Platform-specific location settings
      LocationSettings locationSettings;
      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy:
              forceRefresh ? LocationAccuracy.best : LocationAccuracy.medium,
          distanceFilter: forceRefresh ? 0 : 100,
          forceLocationManager: true, // Avoid FusedLocationProvider NMEA issues
        );
      } else if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy:
              forceRefresh ? LocationAccuracy.best : LocationAccuracy.medium,
          distanceFilter: forceRefresh ? 0 : 100,
        );
      } else {
        locationSettings = LocationSettings(
          accuracy:
              forceRefresh ? LocationAccuracy.best : LocationAccuracy.medium,
          distanceFilter: forceRefresh ? 0 : 100,
        );
      }

      // Try to get current position first (more accurate)
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        ).timeout(Duration(seconds: forceRefresh ? 30 : 15));
      } on TimeoutException {
      } catch (e) {}

      if (currentPosition != null) {
        return currentPosition;
      }

      // If force refresh is enabled, don't use cached position
      if (forceRefresh) {
        throw Exception(
          'Could not get fresh GPS position. Please ensure you are outdoors or near a window.',
        );
      }

      // Fallback to last known position
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
      throw Exception('Could not get location - please ensure GPS is enabled');
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(LatLng currentLocation) {
    if (_cachedStations == null ||
        _cacheTimestamp == null ||
        _lastFetchLocation == null) {
      return false;
    }

    // Check if cache expired
    if (DateTime.now().difference(_cacheTimestamp!) > _cacheDuration) {
      return false;
    }

    // Check if user moved significantly
    const distance = Distance();
    final moved = distance.as(
      LengthUnit.Meter,
      _lastFetchLocation!,
      currentLocation,
    );

    if (moved > _minMovementDistance) {
      return false;
    }
    return true;
  }

  /// Public method to check if cache will be used
  bool isCacheValid(LatLng currentLocation) {
    return _isCacheValid(currentLocation);
  }

  /// Fetch nearby fuel stations from Overpass API
  Future<List<FuelStation>> getNearbyStations(
    LatLng userLocation, {
    double radiusKm = 3.0,
  }) async {
    // Check cache first
    if (_isCacheValid(userLocation)) {
      return _cachedStations!;
    }

    // Try multiple radii: 3km, 10km, 20km
    final radii = [3.0, 10.0, 20.0];
    List<FuelStation> stations = [];

    for (final radius in radii) {
      _currentRadius = radius;
      stations = await _fetchStationsForRadius(userLocation, radius);

      if (stations.isNotEmpty) {
        // Update cache
        _cachedStations = stations;
        _cacheTimestamp = DateTime.now();
        _lastFetchLocation = userLocation;
        return stations;
      }
    }
    return [];
  }

  /// Helper method to fetch stations for a specific radius
  Future<List<FuelStation>> _fetchStationsForRadius(
    LatLng userLocation,
    double radiusKm,
  ) async {
    final lat = userLocation.latitude;
    final lon = userLocation.longitude;
    final radiusMeters = radiusKm * 1000;

    // Overpass API query for fuel stations (simplified for better performance)
    final query = '''
[out:json][timeout:15];
node["amenity"="fuel"](around:$radiusMeters,$lat,$lon);
out center;
''';

    // List of Overpass API mirrors to try
    final apiUrls = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass-api.de/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
    ];

    Exception? lastError;

    for (final apiUrl in apiUrls) {
      try {
        final response = await http
            .post(
              Uri.parse(apiUrl),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: query,
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final elements = data['elements'] as List;

          final stations =
              elements
                  .map((element) {
                    try {
                      return FuelStation.fromOverpassJson(element);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<FuelStation>()
                  .toList();

          // Sort by distance
          stations.sort(
            (a, b) => a
                .distanceFrom(userLocation)
                .compareTo(b.distanceFrom(userLocation)),
          );

          // Update cache
          _cachedStations = stations;
          _cacheTimestamp = DateTime.now();
          _lastFetchLocation = userLocation;
          return stations;
        } else {
          lastError = Exception('API error: ${response.statusCode}');
        }
      } catch (e) {
        lastError = Exception(e.toString());
        continue; // Try next server
      }
    }

    // All servers failed
    // Return cached data if available
    if (_cachedStations != null) {
      return _cachedStations!;
    }
    throw lastError ?? Exception('Failed to fetch fuel stations');
  }

  /// Clear cache (useful for manual refresh)
  void clearCache() {
    _cachedStations = null;
    _cacheTimestamp = null;
    _lastFetchLocation = null;
  }
}
