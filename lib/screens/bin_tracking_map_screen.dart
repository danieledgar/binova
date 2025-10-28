import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';

class BinTrackingMapScreen extends StatefulWidget {
  final String binId;
  final Map<String, dynamic> binData;

  const BinTrackingMapScreen({
    super.key,
    required this.binId,
    required this.binData,
  });

  @override
  State<BinTrackingMapScreen> createState() => _BinTrackingMapScreenState();
}

class _BinTrackingMapScreenState extends State<BinTrackingMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  // Google Maps API Key - Should be loaded from environment variables
  // For now using a placeholder. In production, use flutter_dotenv or similar
  final String _googleApiKey = const String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY',
  );

  // Locations
  late LatLng _pickupLocation;
  late LatLng _facilityLocation;
  LatLng? _currentBinLocation;
  String _facilityName = 'Recycling Facility';

  // List of recycling facilities in Kenya
  final List<Map<String, dynamic>> _recyclingFacilities = [
    // Nairobi & Central Kenya
    {
      'name': 'EcoRecycle Center',
      'position': const LatLng(-1.2821, 36.8119),
      'address': 'CBD, Nairobi',
    },
    {
      'name': 'GreenBin Facility',
      'position': const LatLng(-1.3021, 36.8319),
      'address': 'South B, Nairobi',
    },
    {
      'name': 'Sustainable Waste Solutions',
      'position': const LatLng(-1.2721, 36.7919),
      'address': 'Westlands, Nairobi',
    },
    {
      'name': 'Kasarani Green Hub',
      'position': const LatLng(-1.2197, 36.8986),
      'address': 'Kasarani, Nairobi',
    },
    {
      'name': 'Thika Eco Point',
      'position': const LatLng(-1.0332, 37.0693),
      'address': 'Thika Town',
    },
    {
      'name': 'Kiambu Recycle Center',
      'position': const LatLng(-1.1714, 36.8356),
      'address': 'Kiambu Road',
    },
    {
      'name': 'Ruiru Green Solutions',
      'position': const LatLng(-1.1458, 36.9612),
      'address': 'Ruiru Town',
    },

    // Rift Valley
    {
      'name': 'Nakuru Green Hub',
      'position': const LatLng(-0.3031, 36.0800),
      'address': 'Kenyatta Avenue, Nakuru',
    },
    {
      'name': 'Eldoret Recycle Point',
      'position': const LatLng(0.5143, 35.2698),
      'address': 'Uganda Road, Eldoret',
    },
    {
      'name': 'Naivasha Eco Center',
      'position': const LatLng(-0.7131, 36.4331),
      'address': 'Moi Avenue, Naivasha',
    },
    {
      'name': 'Kericho Green Valley',
      'position': const LatLng(-0.3676, 35.2839),
      'address': 'Kericho Town',
    },
    {
      'name': 'Kitale Waste Hub',
      'position': const LatLng(1.0167, 35.0061),
      'address': 'Kitale Town',
    },

    // Western Kenya
    {
      'name': 'Kisumu Green Cycle',
      'position': const LatLng(-0.0917, 34.7679),
      'address': 'Oginga Odinga Street, Kisumu',
    },
    {
      'name': 'Kakamega Eco Solutions',
      'position': const LatLng(0.2827, 34.7519),
      'address': 'Kakamega Town',
    },
    {
      'name': 'Bungoma Recycle Hub',
      'position': const LatLng(0.5635, 34.5606),
      'address': 'Bungoma Town',
    },
    {
      'name': 'Busia Green Point',
      'position': const LatLng(0.4604, 34.1115),
      'address': 'Busia Town',
    },

    // Coast Region
    {
      'name': 'Coastal Eco Center',
      'position': const LatLng(-4.0435, 39.6682),
      'address': 'Mombasa Road, Mombasa',
    },
    {
      'name': 'Nyali Recycle Station',
      'position': const LatLng(-4.0219, 39.7093),
      'address': 'Nyali, Mombasa',
    },
    {
      'name': 'Malindi Green Hub',
      'position': const LatLng(-3.2167, 40.1167),
      'address': 'Malindi Town',
    },
    {
      'name': 'Kilifi Eco Point',
      'position': const LatLng(-3.6306, 39.8493),
      'address': 'Kilifi Town',
    },
    {
      'name': 'Lamu Waste Solutions',
      'position': const LatLng(-2.2717, 40.9020),
      'address': 'Lamu Island',
    },

    // Eastern Kenya
    {
      'name': 'Machakos Green Center',
      'position': const LatLng(-1.5177, 37.2634),
      'address': 'Machakos Town',
    },
    {
      'name': 'Embu Recycle Hub',
      'position': const LatLng(-0.5316, 37.4575),
      'address': 'Embu Town',
    },
    {
      'name': 'Meru Eco Station',
      'position': const LatLng(0.0469, 37.6496),
      'address': 'Meru Town',
    },
    {
      'name': 'Kitui Green Point',
      'position': const LatLng(-1.3667, 38.0100),
      'address': 'Kitui Town',
    },

    // Nyanza Region
    {
      'name': 'Homa Bay Eco Hub',
      'position': const LatLng(-0.5273, 34.4572),
      'address': 'Homa Bay Town',
    },
    {
      'name': 'Migori Green Solutions',
      'position': const LatLng(-1.0634, 34.4731),
      'address': 'Migori Town',
    },
    {
      'name': 'Siaya Recycle Center',
      'position': const LatLng(0.0636, 34.2881),
      'address': 'Siaya Town',
    },

    // North Eastern
    {
      'name': 'Garissa Waste Management',
      'position': const LatLng(-0.4536, 39.6401),
      'address': 'Garissa Town',
    },
    {
      'name': 'Isiolo Green Hub',
      'position': const LatLng(0.3556, 37.5822),
      'address': 'Isiolo Town',
    },
    {
      'name': 'Marsabit Eco Point',
      'position': const LatLng(2.3284, 37.9887),
      'address': 'Marsabit Town',
    },
  ];

  // Simulation variables
  Timer? _simulationTimer;
  int _currentRouteIndex = 0;
  double _progress = 0.0;
  Duration? _remainingTime;
  bool _isTracking = false;
  double _totalDistanceKm = 0.0;
  int _totalDurationMinutes = 0; // Actual duration from Google API
  int _updateIntervalSeconds =
      3; // Update every 3 seconds for smoother animation

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _createRoute().then((_) {
      // After route is created with real roads, use actual duration from API or calculate
      setState(() {
        _remainingTime = Duration(minutes: _totalDurationMinutes);
      });
      _startSimulation();
    });
  }

  void _initializeLocations() {
    // Get actual pickup location from bin data (stored when pickup was scheduled)
    final pickupLat =
        widget.binData['latitude'] ?? -1.286389; // Fallback: Nairobi
    final pickupLng = widget.binData['longitude'] ?? 36.817223;

    _pickupLocation = LatLng(pickupLat, pickupLng);

    // Find the nearest recycling facility to the pickup location
    Map<String, dynamic>? nearestFacility;
    double shortestDistance = double.infinity;

    for (var facility in _recyclingFacilities) {
      final facilityPos = facility['position'] as LatLng;
      final distance = _calculateDistance(_pickupLocation, facilityPos);

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestFacility = facility;
      }
    }

    // Set facility location to nearest one
    if (nearestFacility != null) {
      _facilityLocation = nearestFacility['position'] as LatLng;
      _facilityName = nearestFacility['name'] as String;
    } else {
      // Fallback to default facility
      _facilityLocation = const LatLng(-1.2821, 36.8119);
      _facilityName = 'EcoRecycle Center';
    }

    // Calculate straight-line distance
    final straightLineDistance = _calculateDistance(
      _pickupLocation,
      _facilityLocation,
    );

    // Estimate actual road distance (typically 1.3x to 1.5x straight line in cities)
    _totalDistanceKm = straightLineDistance * 1.4;

    // Calculate estimated time using realistic traffic speed (40 km/h for city driving)
    _totalDurationMinutes = (_totalDistanceKm / 40 * 60)
        .round(); // km / (km/h) * 60 = minutes

    print('📏 Initialized locations:');
    print(
      '   Pickup: ${_pickupLocation.latitude}, ${_pickupLocation.longitude}',
    );
    print(
      '   Facility: $_facilityName at ${_facilityLocation.latitude}, ${_facilityLocation.longitude}',
    );
    print('   Estimated distance: ${_totalDistanceKm.toStringAsFixed(2)} km');
    print('   Estimated time: $_totalDurationMinutes minutes');
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // km
    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> _createRoute() async {
    // Create markers
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.binData['location'] ?? 'Pickup Point',
        ),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('facility'),
        position: _facilityLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: _facilityName,
          snippet: 'Recycling Destination',
        ),
      ),
    );

    // Get real road route from Google Directions API
    await _getDirectionsRoute();

    // Draw polyline
    if (_polylineCoordinates.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _polylineCoordinates,
          color: Colors.green,
          width: 5,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _getDirectionsRoute() async {
    print('🔄 Fetching route from Google Directions API...');
    print(
      '   Origin: ${_pickupLocation.latitude}, ${_pickupLocation.longitude}',
    );
    print(
      '   Destination: ${_facilityLocation.latitude}, ${_facilityLocation.longitude}',
    );

    try {
      // Use flutter_polyline_points to get route from Google Directions API
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(
            _pickupLocation.latitude,
            _pickupLocation.longitude,
          ),
          destination: PointLatLng(
            _facilityLocation.latitude,
            _facilityLocation.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      print('📍 API Response - Status: ${result.status}');
      print('📍 Points received: ${result.points.length}');

      if (result.points.isNotEmpty) {
        // Convert PointLatLng to LatLng
        _polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Calculate actual route distance from the points
        _totalDistanceKm = _calculateRouteDistance(_polylineCoordinates);

        // Try to get duration from API response
        // The API returns distance and duration in the result
        if (result.distanceTexts != null && result.distanceTexts!.isNotEmpty) {
          final distanceText = result.distanceTexts!.first;
          print('📍 API Distance: $distanceText');
        }

        if (result.durationTexts != null && result.durationTexts!.isNotEmpty) {
          final durationText = result.durationTexts!.first;
          print('📍 API Duration: $durationText');

          // Extract duration in minutes from text like "15 mins" or "1 hour 20 mins"
          final durationMinutes = _parseDurationText(durationText);
          if (durationMinutes > 0) {
            _totalDurationMinutes = durationMinutes;
            print('✅ Using API duration: $_totalDurationMinutes minutes');
          } else {
            // Fallback: calculate duration based on distance at city speed (40 km/h)
            _totalDurationMinutes = (_totalDistanceKm / 40 * 60).round();
            print(
              '⚠️ Could not parse duration, calculated: $_totalDurationMinutes minutes at 40 km/h',
            );
          }
        } else {
          // No duration from API, calculate based on distance
          _totalDurationMinutes = (_totalDistanceKm / 40 * 60).round();
          print(
            '⚠️ No duration from API, calculated: $_totalDurationMinutes minutes at 40 km/h',
          );
        }

        print(
          '✅ Got real route with ${_polylineCoordinates.length} points, distance: ${_totalDistanceKm.toStringAsFixed(2)} km, duration: $_totalDurationMinutes min',
        );
      } else {
        // Fallback to simulated route if API fails
        print('⚠️ Directions API returned empty result');
        print('   Status: ${result.status}');
        print('   Error: ${result.errorMessage}');
        print('   Using simulated route instead');

        _polylineCoordinates = _generateSimulatedRoute(
          _pickupLocation,
          _facilityLocation,
        );
        _totalDistanceKm = _calculateRouteDistance(_polylineCoordinates);
        _totalDurationMinutes = (_totalDistanceKm / 40 * 60).round();
      }
    } catch (e, stackTrace) {
      // Fallback to simulated route if there's an error
      print('❌ Error getting directions: $e');
      print('   Stack trace: $stackTrace');
      print('   Using simulated route instead');

      _polylineCoordinates = _generateSimulatedRoute(
        _pickupLocation,
        _facilityLocation,
      );
      _totalDistanceKm = _calculateRouteDistance(_polylineCoordinates);
      _totalDurationMinutes = (_totalDistanceKm / 40 * 60).round();
    }
  }

  int _parseDurationText(String durationText) {
    // Parse duration text like "15 mins", "1 hour 20 mins", "2 hours"
    int totalMinutes = 0;

    // Extract hours
    final hourMatch = RegExp(
      r'(\d+)\s*hour',
    ).firstMatch(durationText.toLowerCase());
    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }

    // Extract minutes
    final minMatch = RegExp(
      r'(\d+)\s*min',
    ).firstMatch(durationText.toLowerCase());
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }

    return totalMinutes;
  }

  double _calculateRouteDistance(List<LatLng> route) {
    // Calculate total distance along the route
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  List<LatLng> _generateSimulatedRoute(LatLng start, LatLng end) {
    // Generate a realistic route that follows roads more closely
    List<LatLng> route = [];

    // Calculate route segments based on distance (more points for longer distances)
    final distance = _calculateDistance(start, end);
    final int segments = math.max(
      50,
      (distance * 100).round(),
    ); // At least 50 points, more for longer routes

    // Create waypoints to simulate turns and road networks
    List<LatLng> waypoints = _generateWaypoints(start, end);

    // Generate smooth curve through waypoints
    for (var i = 0; i < waypoints.length - 1; i++) {
      final segmentStart = waypoints[i];
      final segmentEnd = waypoints[i + 1];
      final segmentPoints = segments ~/ (waypoints.length - 1);

      for (var j = 0; j < segmentPoints; j++) {
        final t = j / segmentPoints;

        // Use cubic Bezier-like curve for smoother roads
        final lat =
            segmentStart.latitude +
            (segmentEnd.latitude - segmentStart.latitude) * t;
        final lng =
            segmentStart.longitude +
            (segmentEnd.longitude - segmentStart.longitude) * t;

        // Add slight variations to simulate road curvature
        final variation = math.sin(t * math.pi * 4) * 0.0008;
        route.add(LatLng(lat + variation, lng + variation));
      }
    }

    // Add final destination
    route.add(end);

    return route;
  }

  List<LatLng> _generateWaypoints(LatLng start, LatLng end) {
    // Create intermediate waypoints to simulate road network
    List<LatLng> waypoints = [start];

    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;

    // Calculate number of turns based on distance
    final distance = _calculateDistance(start, end);
    final numTurns = math.max(
      2,
      (distance * 3).round(),
    ); // More turns for longer routes

    // Generate waypoints with road-like patterns
    for (var i = 1; i < numTurns; i++) {
      final t = i / numTurns;

      // Alternate between horizontal and vertical movement to simulate grid roads
      double lat, lng;
      if (i % 2 == 0) {
        // Horizontal segment
        lat =
            start.latitude +
            latDiff * (t - 0.1 + math.Random().nextDouble() * 0.2);
        lng = start.longitude + lngDiff * t;
      } else {
        // Vertical segment
        lat = start.latitude + latDiff * t;
        lng =
            start.longitude +
            lngDiff * (t - 0.1 + math.Random().nextDouble() * 0.2);
      }

      waypoints.add(LatLng(lat, lng));
    }

    waypoints.add(end);
    return waypoints;
  }

  void _startSimulation() {
    _isTracking = true;
    _currentBinLocation = _pickupLocation;

    // Calculate how many route points to skip per update to match the total duration
    // We want the simulation to complete in _totalDurationMinutes
    final totalUpdates =
        (_totalDurationMinutes * 60) /
        _updateIntervalSeconds; // total seconds / interval
    final pointsPerUpdate = math.max(
      1,
      (_polylineCoordinates.length / totalUpdates).round(),
    );

    print('🚛 Starting simulation:');
    print('   Total points: ${_polylineCoordinates.length}');
    print('   Total duration: $_totalDurationMinutes minutes');
    print('   Update interval: $_updateIntervalSeconds seconds');
    print('   Points per update: $pointsPerUpdate');

    _simulationTimer = Timer.periodic(
      Duration(seconds: _updateIntervalSeconds),
      (timer) {
        if (_currentRouteIndex < _polylineCoordinates.length - 1) {
          setState(() {
            // Move forward by calculated number of points
            _currentRouteIndex = math.min(
              _currentRouteIndex + pointsPerUpdate,
              _polylineCoordinates.length - 1,
            );

            _currentBinLocation = _polylineCoordinates[_currentRouteIndex];
            _progress = _currentRouteIndex / (_polylineCoordinates.length - 1);

            // Calculate remaining time based on progress
            final remainingMinutes = (_totalDurationMinutes * (1 - _progress))
                .round();
            _remainingTime = Duration(minutes: remainingMinutes);

            // Update bin marker
            _markers.removeWhere((m) => m.markerId.value == 'bin');
            _markers.add(
              Marker(
                markerId: const MarkerId('bin'),
                position: _currentBinLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(
                  title: 'Your Bin',
                  snippet: '${(_progress * 100).toStringAsFixed(0)}% complete',
                ),
              ),
            );

            // Move camera to follow bin
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_currentBinLocation!),
            );
          });
        } else {
          // Reached destination
          timer.cancel();
          _isTracking = false;
          _showArrivalDialog();
        }
      },
    );
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Arrived!'),
          ],
        ),
        content: Text(
          'Your bin has arrived at $_facilityName and is being processed. Thank you for recycling!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to bin tracker
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Track Your Bin'),
        backgroundColor: isDark ? Colors.green.shade800 : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentBinLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentBinLocation!, 14),
                );
              }
            },
            tooltip: 'Center on Bin',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickupLocation,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;

              // Fit bounds to show both markers
              LatLngBounds bounds = LatLngBounds(
                southwest: LatLng(
                  math.min(
                    _pickupLocation.latitude,
                    _facilityLocation.latitude,
                  ),
                  math.min(
                    _pickupLocation.longitude,
                    _facilityLocation.longitude,
                  ),
                ),
                northeast: LatLng(
                  math.max(
                    _pickupLocation.latitude,
                    _facilityLocation.latitude,
                  ),
                  math.max(
                    _pickupLocation.longitude,
                    _facilityLocation.longitude,
                  ),
                ),
              );

              controller.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 100),
              );
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Info Card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  Row(
                    children: [
                      Icon(Icons.recycling, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bin #${widget.binId.substring(0, 8).toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${(_progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.green,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Destination facility info
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              _facilityName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        icon: Icons.schedule,
                        label: 'ETA',
                        value: _remainingTime != null
                            ? '${_remainingTime!.inMinutes} min'
                            : 'Calculating...',
                        isDark: isDark,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      _buildInfoColumn(
                        icon: Icons.local_shipping,
                        label: 'Status',
                        value: _isTracking ? 'In Transit' : 'Arrived',
                        isDark: isDark,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      _buildInfoColumn(
                        icon: Icons.place,
                        label: 'Distance',
                        value: _currentBinLocation != null
                            ? '${_calculateDistance(_currentBinLocation!, _facilityLocation).toStringAsFixed(1)} km'
                            : '--',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
