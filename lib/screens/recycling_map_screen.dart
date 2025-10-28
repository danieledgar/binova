import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';

class RecyclingMapScreen extends StatefulWidget {
  const RecyclingMapScreen({super.key});

  @override
  State<RecyclingMapScreen> createState() => _RecyclingMapScreenState();
}

class _RecyclingMapScreenState extends State<RecyclingMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-1.2921, 36.8219); // Nairobi default
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  // Sample recycling centers data (replace with actual data from Firestore)
  final List<Map<String, dynamic>> _recyclingCenters = [
    // Nairobi & Central Kenya
    {
      'name': 'EcoRecycle Center',
      'type': 'recycling_center',
      'latitude': -1.2821,
      'longitude': 36.8119,
      'description': 'Main recycling facility - CBD, Nairobi',
      'phone': '+254 700 000 001',
    },
    {
      'name': 'GreenBin Facility',
      'type': 'recycling_center',
      'latitude': -1.3021,
      'longitude': 36.8319,
      'description': 'Community recycling center - South B, Nairobi',
      'phone': '+254 700 000 002',
    },
    {
      'name': 'Sustainable Waste Solutions',
      'type': 'recycling_center',
      'latitude': -1.2721,
      'longitude': 36.7919,
      'description': 'All waste types accepted - Westlands, Nairobi',
      'phone': '+254 700 000 003',
    },
    {
      'name': 'Kasarani Green Hub',
      'type': 'recycling_center',
      'latitude': -1.2197,
      'longitude': 36.8986,
      'description': 'Kasarani recycling facility',
      'phone': '+254 700 000 004',
    },
    {
      'name': 'Thika Eco Point',
      'type': 'recycling_center',
      'latitude': -1.0332,
      'longitude': 37.0693,
      'description': 'Thika Town recycling center',
      'phone': '+254 700 000 005',
    },
    {
      'name': 'Kiambu Recycle Center',
      'type': 'recycling_center',
      'latitude': -1.1714,
      'longitude': 36.8356,
      'description': 'Kiambu Road facility',
      'phone': '+254 700 000 006',
    },
    {
      'name': 'Ruiru Green Solutions',
      'type': 'recycling_center',
      'latitude': -1.1458,
      'longitude': 36.9612,
      'description': 'Ruiru Town recycling',
      'phone': '+254 700 000 007',
    },

    // Rift Valley
    {
      'name': 'Nakuru Green Hub',
      'type': 'recycling_center',
      'latitude': -0.3031,
      'longitude': 36.0800,
      'description': 'Kenyatta Avenue, Nakuru',
      'phone': '+254 700 000 008',
    },
    {
      'name': 'Eldoret Recycle Point',
      'type': 'recycling_center',
      'latitude': 0.5143,
      'longitude': 35.2698,
      'description': 'Uganda Road, Eldoret',
      'phone': '+254 700 000 009',
    },
    {
      'name': 'Naivasha Eco Center',
      'type': 'recycling_center',
      'latitude': -0.7131,
      'longitude': 36.4331,
      'description': 'Moi Avenue, Naivasha',
      'phone': '+254 700 000 010',
    },
    {
      'name': 'Kericho Green Valley',
      'type': 'recycling_center',
      'latitude': -0.3676,
      'longitude': 35.2839,
      'description': 'Kericho Town facility',
      'phone': '+254 700 000 011',
    },
    {
      'name': 'Kitale Waste Hub',
      'type': 'recycling_center',
      'latitude': 1.0167,
      'longitude': 35.0061,
      'description': 'Kitale Town recycling center',
      'phone': '+254 700 000 012',
    },

    // Western Kenya
    {
      'name': 'Kisumu Green Cycle',
      'type': 'recycling_center',
      'latitude': -0.0917,
      'longitude': 34.7679,
      'description': 'Oginga Odinga Street, Kisumu',
      'phone': '+254 700 000 013',
    },
    {
      'name': 'Kakamega Eco Solutions',
      'type': 'recycling_center',
      'latitude': 0.2827,
      'longitude': 34.7519,
      'description': 'Kakamega Town facility',
      'phone': '+254 700 000 014',
    },
    {
      'name': 'Bungoma Recycle Hub',
      'type': 'recycling_center',
      'latitude': 0.5635,
      'longitude': 34.5606,
      'description': 'Bungoma Town center',
      'phone': '+254 700 000 015',
    },
    {
      'name': 'Busia Green Point',
      'type': 'recycling_center',
      'latitude': 0.4604,
      'longitude': 34.1115,
      'description': 'Busia Town recycling',
      'phone': '+254 700 000 016',
    },

    // Coast Region
    {
      'name': 'Coastal Eco Center',
      'type': 'recycling_center',
      'latitude': -4.0435,
      'longitude': 39.6682,
      'description': 'Main facility - Mombasa Road',
      'phone': '+254 700 000 017',
    },
    {
      'name': 'Nyali Recycle Station',
      'type': 'recycling_center',
      'latitude': -4.0219,
      'longitude': 39.7093,
      'description': 'Nyali, Mombasa',
      'phone': '+254 700 000 018',
    },
    {
      'name': 'Malindi Green Hub',
      'type': 'recycling_center',
      'latitude': -3.2167,
      'longitude': 40.1167,
      'description': 'Malindi Town center',
      'phone': '+254 700 000 019',
    },
    {
      'name': 'Kilifi Eco Point',
      'type': 'recycling_center',
      'latitude': -3.6306,
      'longitude': 39.8493,
      'description': 'Kilifi Town facility',
      'phone': '+254 700 000 020',
    },
    {
      'name': 'Lamu Waste Solutions',
      'type': 'recycling_center',
      'latitude': -2.2717,
      'longitude': 40.9020,
      'description': 'Lamu Island recycling',
      'phone': '+254 700 000 021',
    },

    // Eastern Kenya
    {
      'name': 'Machakos Green Center',
      'type': 'recycling_center',
      'latitude': -1.5177,
      'longitude': 37.2634,
      'description': 'Machakos Town facility',
      'phone': '+254 700 000 022',
    },
    {
      'name': 'Embu Recycle Hub',
      'type': 'recycling_center',
      'latitude': -0.5316,
      'longitude': 37.4575,
      'description': 'Embu Town center',
      'phone': '+254 700 000 023',
    },
    {
      'name': 'Meru Eco Station',
      'type': 'recycling_center',
      'latitude': 0.0469,
      'longitude': 37.6496,
      'description': 'Meru Town recycling',
      'phone': '+254 700 000 024',
    },
    {
      'name': 'Kitui Green Point',
      'type': 'recycling_center',
      'latitude': -1.3667,
      'longitude': 38.0100,
      'description': 'Kitui Town facility',
      'phone': '+254 700 000 025',
    },

    // Nyanza Region
    {
      'name': 'Homa Bay Eco Hub',
      'type': 'recycling_center',
      'latitude': -0.5273,
      'longitude': 34.4572,
      'description': 'Homa Bay Town center',
      'phone': '+254 700 000 026',
    },
    {
      'name': 'Migori Green Solutions',
      'type': 'recycling_center',
      'latitude': -1.0634,
      'longitude': 34.4731,
      'description': 'Migori Town recycling',
      'phone': '+254 700 000 027',
    },
    {
      'name': 'Siaya Recycle Center',
      'type': 'recycling_center',
      'latitude': 0.0636,
      'longitude': 34.2881,
      'description': 'Siaya Town facility',
      'phone': '+254 700 000 028',
    },

    // North Eastern
    {
      'name': 'Garissa Waste Management',
      'type': 'recycling_center',
      'latitude': -0.4536,
      'longitude': 39.6401,
      'description': 'Garissa Town center',
      'phone': '+254 700 000 029',
    },
    {
      'name': 'Isiolo Green Hub',
      'type': 'recycling_center',
      'latitude': 0.3556,
      'longitude': 37.5822,
      'description': 'Isiolo Town recycling',
      'phone': '+254 700 000 030',
    },
    {
      'name': 'Marsabit Eco Point',
      'type': 'recycling_center',
      'latitude': 2.3284,
      'longitude': 37.9887,
      'description': 'Marsabit Town facility',
      'phone': '+254 700 000 031',
    },

    // Help Centers (Selected Locations)
    {
      'name': 'Nairobi Help Center',
      'type': 'help_center',
      'latitude': -1.2676,
      'longitude': 36.8108,
      'description': 'Get help with recycling and waste management',
      'phone': '+254 700 100 001',
    },
    {
      'name': 'Mombasa Help Desk',
      'type': 'help_center',
      'latitude': -4.0500,
      'longitude': 39.6630,
      'description': 'Information and support center',
      'phone': '+254 700 100 002',
    },
    {
      'name': 'Kisumu Support Center',
      'type': 'help_center',
      'latitude': -0.1000,
      'longitude': 34.7520,
      'description': 'Recycling guidance and assistance',
      'phone': '+254 700 100 003',
    },
    {
      'name': 'Nakuru Help Point',
      'type': 'help_center',
      'latitude': -0.3100,
      'longitude': 36.0700,
      'description': 'Waste management support',
      'phone': '+254 700 100 004',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadMarkers();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 12),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadMarkers() async {
    final markers = <Marker>{};

    // Add user's current location
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'You are here',
        ),
      ),
    );

    // Add recycling centers, help centers, and pickup points
    for (var center in _recyclingCenters) {
      if (_selectedFilter != 'all' && center['type'] != _selectedFilter) {
        continue;
      }

      final markerColor = _getMarkerColor(center['type']);
      markers.add(
        Marker(
          markerId: MarkerId(center['name']),
          position: LatLng(center['latitude'], center['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: center['name'],
            snippet: center['description'],
            onTap: () => _showLocationDetails(center),
          ),
        ),
      );
    }

    // Load user's pickup locations from Firestore
    await _loadUserPickupLocations(markers);

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  Future<void> _loadUserPickupLocations(Set<Marker> markers) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final pickups = await FirebaseFirestore.instance
          .collection('pickups')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in pickups.docs) {
        final data = doc.data();
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;

        if (latitude != null && longitude != null) {
          if (_selectedFilter == 'all' || _selectedFilter == 'pickup_point') {
            markers.add(
              Marker(
                markerId: MarkerId('pickup_${doc.id}'),
                position: LatLng(latitude, longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(
                  title: 'Your Pickup',
                  snippet: '${data['wasteType']} - ${data['quantity']}',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading pickup locations: $e');
    }
  }

  double _getMarkerColor(String type) {
    switch (type) {
      case 'recycling_center':
        return BitmapDescriptor.hueGreen;
      case 'help_center':
        return BitmapDescriptor.hueViolet;
      case 'pickup_point':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(location['type']),
                  color: isDark ? Colors.green.shade400 : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    location['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              location['description'],
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 20,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  location['phone'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Open directions in maps app
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.green.shade700
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.green.shade400
                          : Colors.green,
                      side: BorderSide(
                        color: isDark ? Colors.green.shade700 : Colors.green,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'recycling_center':
        return Icons.recycling;
      case 'help_center':
        return Icons.help_center;
      case 'pickup_point':
        return Icons.local_shipping;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                _mapController = controller;
                if (isDark) {
                  controller.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [{"color": "#242f3e"}]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [{"color": "#242f3e"}]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [{"color": "#746855"}]
                      }
                    ]
                  ''');
                }
              },
            ),
          // Filter chips
          Positioned(
            top: 56, // Moved down to avoid status bar
            left: 16,
            right: 16,
            child: Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', Icons.map, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Recycling Centers',
                        'recycling_center',
                        Icons.recycling,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Help Centers',
                        'help_center',
                        Icons.help_center,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Pickup Points',
                        'pickup_point',
                        Icons.local_shipping,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: isDark ? Colors.green.shade700 : Colors.green,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .startFloat, // Moved to left side to avoid zoom controls
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _loadMarkers();
        });
      },
      selectedColor: isDark ? Colors.green.shade700 : Colors.green,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.grey[400] : Colors.grey[700]),
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
