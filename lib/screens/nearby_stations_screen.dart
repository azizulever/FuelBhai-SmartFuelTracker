import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mileage_calculator/models/fuel_station.dart';
import 'package:mileage_calculator/services/nearby_stations_service.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyStationsScreen extends StatefulWidget {
  const NearbyStationsScreen({super.key});

  @override
  State<NearbyStationsScreen> createState() => _NearbyStationsScreenState();
}

class _NearbyStationsScreenState extends State<NearbyStationsScreen> {
  final NearbyStationsService _stationsService = NearbyStationsService();
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  List<FuelStation> _stations = [];
  bool _isLoading = true;
  String? _error;
  String _loadingStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logScreenView('NearbyStationsScreen');
    // Clear cache to ensure fresh data when screen opens
    _stationsService.clearCache();
    _loadStations();
  }

  Future<void> _loadStations({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _loadingStatus = 'Getting location...';
    });

    try {
      // Get user location with extended timeout
      final position = await _stationsService
          .getCurrentLocation(forceRefresh: forceRefresh)
          .timeout(
            Duration(seconds: forceRefresh ? 40 : 35),
            onTimeout: () {
              return null;
            },
          );

      if (position == null) {
        setState(() {
          _error =
              'Unable to get your location.\n\n'
              'Troubleshooting steps:\n'
              '• Make sure you\'re outdoors or near a window\n'
              '• Enable Location Services in device settings\n'
              '• Grant location permission to FuelBhai\n'
              '• Turn on High Accuracy mode in Location settings\n'
              '• Wait a moment for GPS to acquire satellites';
          _isLoading = false;
        });
        return;
      }

      setState(() => _loadingStatus = 'Searching for fuel stations...');

      final userLoc = LatLng(position.latitude, position.longitude);

      // Fetch stations with timeout and periodic status updates
      final stationsFuture = _stationsService.getNearbyStations(userLoc);

      // Update radius in loading status periodically
      final radiusTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) {
        if (mounted) {
          setState(() {
            _loadingStatus =
                'Searching ${_stationsService.currentRadius.toStringAsFixed(0)}km radius...';
          });
        }
      });

      final stations = await stationsFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          radiusTimer.cancel();
          throw Exception(
            'Request timed out. Please check your internet connection.',
          );
        },
      );

      radiusTimer.cancel();

      setState(() {
        _userLocation = userLoc;
        _stations = stations;
        _isLoading = false;
      });

      // Automatically center map on user's location
      if (_userLocation != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _mapController.move(_userLocation!, 14.0);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load fuel stations:\n$e';
        _isLoading = false;
      });
    }
  }

  void _openInGoogleMaps(FuelStation station) async {
    final lat = station.location.latitude;
    final lon = station.location.longitude;
    final label = Uri.encodeComponent(station.name);

    // Use geo: URI scheme for Android (more reliable)
    final geoUrl = Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)');

    // Fallback to web URL
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    try {
      // Try geo: scheme first (works on Android with Maps installed)
      bool launched = false;
      try {
        launched = await launchUrl(
          geoUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {}

      // If geo: failed, try web URL
      if (!launched) {
        launched = await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        throw 'Could not launch Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStationDetails(FuelStation station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStationBottomSheet(station),
    );
  }

  Widget _buildStationBottomSheet(FuelStation station) {
    final distance =
        _userLocation != null ? station.distanceFrom(_userLocation!) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Station icon and name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_gas_station,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (station.brand != null)
                      Text(
                        station.brand!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Distance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  '${distance.toStringAsFixed(2)} km away',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (station.address != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    station.address!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Open in Google Maps button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openInGoogleMaps(station);
              },
              icon: const Icon(Icons.map),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // User location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      );
    }

    // Fuel station markers
    for (final station in _stations) {
      markers.add(
        Marker(
          point: station.location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showStationDetails(station),
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_gas_station,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Fuel Stations'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _stationsService.clearCache();
              setState(() {
                _userLocation = null;
                _stations = [];
              });
              _loadStations(forceRefresh: true);
            },
            tooltip: 'Refresh My Location',
          ),
        ],
      ),
      body:
          _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadStations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          // Open location settings
                          Geolocator.openLocationSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Location Settings'),
                      ),
                    ],
                  ),
                ),
              )
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _userLocation ?? const LatLng(0, 0),
                      initialZoom: 14.0,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.fuelbhai.mileage_calculator',
                        maxZoom: 19,
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),

                  // Loading overlay at top
                  if (_isLoading)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 3,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _loadingStatus,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Station count indicator (only when not loading and no error)
                  if (!_isLoading && _error == null && _stations.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_gas_station,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_stations.length} fuel stations nearby',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
