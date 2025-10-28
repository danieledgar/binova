// lib/screens/bin_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/notification_service.dart';
// REVERTED to Google Maps
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'bin_tracking_map_screen.dart';

class BinTrackerScreen extends StatefulWidget {
  const BinTrackerScreen({super.key});

  @override
  State<BinTrackerScreen> createState() => _BinTrackerScreenState();
}

class _BinTrackerScreenState extends State<BinTrackerScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  String _selectedStatus = 'all';
  Timer? _countdownTimer;
  // REVERTED controller type
  GoogleMapController? _googleMapController;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  final Set<String> _notifiedBins = {}; // Track which bins we've notified about

  // Notification preferences
  bool _pickupRemindersEnabled = true;

  // Truck animation variables
  LatLng? _truckPosition;
  Timer? _truckAnimationTimer;
  LatLng? _truckDestination;

  // Recycling centers data (using google_maps_flutter.LatLng)
  final List<Map<String, dynamic>> _recyclingCenters = [
    // Nairobi & Central Kenya
    {
      'name': 'EcoRecycle Center - Nairobi CBD',
      'address': 'Kenyatta Avenue, Nairobi CBD',
      'position': const LatLng(-1.2864, 36.8172),
      'types': ['Plastic', 'Paper', 'Glass', 'Metal'],
    },
    {
      'name': 'GreenBin Facility - South B',
      'address': 'Mombasa Road, South B',
      'position': const LatLng(-1.3107, 36.8324),
      'types': ['Plastic', 'Paper', 'Electronics'],
    },
    {
      'name': 'Westlands Recycling Hub',
      'address': 'Waiyaki Way, Westlands',
      'position': const LatLng(-1.2676, 36.8070),
      'types': ['Plastic', 'Glass', 'Organic'],
    },
    {
      'name': 'Kasarani Eco Point',
      'address': 'Thika Road, Kasarani',
      'position': const LatLng(-1.2258, 36.8969),
      'types': ['Plastic', 'Paper', 'Metal'],
    },
    {
      'name': 'Thika Green Center',
      'address': 'Garissa Road, Thika Town',
      'position': const LatLng(-1.0332, 37.0690),
      'types': ['Plastic', 'Paper', 'Glass', 'Organic'],
    },
    {
      'name': 'Kiambu Recycle Hub',
      'address': 'Kiambu Road, Kiambu Town',
      'position': const LatLng(-1.1714, 36.8356),
      'types': ['Plastic', 'Paper', 'Organic'],
    },
    {
      'name': 'Ruiru Waste Solutions',
      'address': 'Eastern Bypass, Ruiru',
      'position': const LatLng(-1.1460, 36.9609),
      'types': ['Plastic', 'Glass', 'Metal'],
    },

    // Rift Valley
    {
      'name': 'Nakuru Green Hub',
      'address': 'Kenyatta Avenue, Nakuru Town',
      'position': const LatLng(-0.3031, 36.0800),
      'types': ['Plastic', 'Paper', 'Glass', 'Organic'],
    },
    {
      'name': 'Eldoret Recycle Point',
      'address': 'Uganda Road, Eldoret Town',
      'position': const LatLng(0.5143, 35.2698),
      'types': ['Plastic', 'Paper', 'Organic'],
    },
    {
      'name': 'Naivasha Eco Center',
      'address': 'Moi South Lake Road, Naivasha',
      'position': const LatLng(-0.7167, 36.4333),
      'types': ['Plastic', 'Glass', 'Organic'],
    },
    {
      'name': 'Kericho Green Solutions',
      'address': 'Moi Highway, Kericho Town',
      'position': const LatLng(-0.3676, 35.2839),
      'types': ['Plastic', 'Paper', 'Organic'],
    },
    {
      'name': 'Kitale Recycling Hub',
      'address': 'Kenyatta Street, Kitale',
      'position': const LatLng(1.0157, 34.9988),
      'types': ['Plastic', 'Paper', 'Glass'],
    },

    // Western Kenya
    {
      'name': 'Kisumu Green Cycle',
      'address': 'Oginga Odinga Street, Kisumu',
      'position': const LatLng(-0.0917, 34.7679),
      'types': ['Plastic', 'Paper', 'Organic'],
    },
    {
      'name': 'Kakamega Eco Point',
      'address': 'Mumias Road, Kakamega',
      'position': const LatLng(0.2827, 34.7519),
      'types': ['Plastic', 'Paper', 'Glass'],
    },
    {
      'name': 'Bungoma Recycle Center',
      'address': 'Webuye Road, Bungoma',
      'position': const LatLng(0.5635, 34.5606),
      'types': ['Plastic', 'Organic'],
    },
    {
      'name': 'Busia Green Hub',
      'address': 'Custom Road, Busia',
      'position': const LatLng(0.4604, 34.1115),
      'types': ['Plastic', 'Paper'],
    },

    // Coast Region
    {
      'name': 'Coastal Eco Center',
      'address': 'Nkrumah Road, Mombasa',
      'position': const LatLng(-4.0435, 39.6682),
      'types': ['Plastic', 'Glass', 'Organic'],
    },
    {
      'name': 'Nyali Recycling Point',
      'address': 'Links Road, Nyali',
      'position': const LatLng(-4.0297, 39.7073),
      'types': ['Plastic', 'Paper', 'Glass'],
    },
    {
      'name': 'Malindi Green Solutions',
      'address': 'Lamu Road, Malindi',
      'position': const LatLng(-3.2167, 40.1167),
      'types': ['Plastic', 'Glass'],
    },
    {
      'name': 'Kilifi Eco Hub',
      'address': 'Mombasa-Malindi Road, Kilifi',
      'position': const LatLng(-3.6307, 39.8493),
      'types': ['Plastic', 'Organic'],
    },
    {
      'name': 'Lamu Recycling Center',
      'address': 'Waterfront, Lamu Town',
      'position': const LatLng(-2.2717, 40.9020),
      'types': ['Plastic', 'Paper'],
    },

    // Eastern Kenya
    {
      'name': 'Machakos Green Point',
      'address': 'Syokimau Road, Machakos',
      'position': const LatLng(-1.5177, 37.2634),
      'types': ['Plastic', 'Paper', 'Glass'],
    },
    {
      'name': 'Embu Eco Center',
      'address': 'Embu-Meru Highway, Embu',
      'position': const LatLng(-0.5311, 37.4570),
      'types': ['Plastic', 'Organic'],
    },
    {
      'name': 'Meru Recycling Hub',
      'address': 'Maua Road, Meru Town',
      'position': const LatLng(0.0469, 37.6497),
      'types': ['Plastic', 'Paper'],
    },
    {
      'name': 'Kitui Green Solutions',
      'address': 'Kitui-Mwingi Road, Kitui',
      'position': const LatLng(-1.3669, 38.0106),
      'types': ['Plastic', 'Organic'],
    },

    // Nyanza Region
    {
      'name': 'Homa Bay Eco Point',
      'address': 'Kisumu-Homa Bay Road',
      'position': const LatLng(-0.5273, 34.4571),
      'types': ['Plastic', 'Organic'],
    },
    {
      'name': 'Migori Green Center',
      'address': 'Migori-Isebania Road, Migori',
      'position': const LatLng(-1.0634, 34.4731),
      'types': ['Plastic', 'Paper'],
    },
    {
      'name': 'Siaya Recycling Hub',
      'address': 'Kisumu-Busia Road, Siaya',
      'position': const LatLng(0.0621, 34.2880),
      'types': ['Plastic', 'Organic'],
    },

    // North Eastern
    {
      'name': 'Garissa Eco Center',
      'address': 'Garissa-Nairobi Road',
      'position': const LatLng(-0.4536, 39.6401),
      'types': ['Plastic', 'Paper'],
    },
    {
      'name': 'Isiolo Green Point',
      'address': 'Isiolo Town Center',
      'position': const LatLng(0.3556, 37.5820),
      'types': ['Plastic'],
    },
    {
      'name': 'Marsabit Recycling Hub',
      'address': 'Marsabit-Moyale Road',
      'position': const LatLng(2.3284, 37.9899),
      'types': ['Plastic', 'Organic'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadNotificationPreferences();
    _checkAndUpdateBinStatus();
    // Removed _startBinStatusListener() - now handled globally in main.dart
    // Update countdowns every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndUpdateBinStatus();
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _truckAnimationTimer?.cancel();
    _googleMapController?.dispose(); // Dispose the Google Map controller
    super.dispose();
  }

  // Load notification preferences from Firestore
  Future<void> _loadNotificationPreferences() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        setState(() {
          _pickupRemindersEnabled = data?['pickupReminders'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
    }
  }

  void _showNotification(String title, String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move map to user location (using Google Maps Controller)
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13.0),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location found!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Calculate bearing between two points for truck rotation
  double _calculateBearing(LatLng from, LatLng to) {
    final dLon = _degreesToRadians(to.longitude - from.longitude);
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  Future<void> _checkAndUpdateBinStatus() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bins')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'scheduled')
          .get();

      for (var doc in snapshot.docs) {
        final bin = doc.data();
        if (bin['pickupId'] != null) {
          final pickupDoc = await FirebaseFirestore.instance
              .collection('pickups')
              .doc(bin['pickupId'])
              .get();

          if (pickupDoc.exists) {
            final pickup = pickupDoc.data();
            if (pickup?['date'] != null && pickup?['time'] != null) {
              final pickupDateTime = DateTime.parse(
                '${pickup!['date']}T${pickup['time']}',
              );

              // Check if pickup is within 24 hours and send reminder if enabled
              if (_pickupRemindersEnabled) {
                final timeUntilPickup = pickupDateTime.difference(now);
                final binId = doc.id;
                final binType = bin['type'] ?? 'waste';

                // Send reminder if pickup is in 24 hours and not already notified
                if (timeUntilPickup.inHours <= 24 &&
                    timeUntilPickup.inHours > 0 &&
                    !_notifiedBins.contains('$binId-reminder')) {
                  _showNotification(
                    '⏰ Pickup Reminder',
                    'Your $binType pickup is scheduled in ${timeUntilPickup.inHours} hours',
                    Colors.orange,
                  );
                  // Show system notification
                  _notificationService.showPickupReminderNotification(
                    binType: binType,
                    hoursUntilPickup: timeUntilPickup.inHours,
                  );
                  _notifiedBins.add('$binId-reminder');
                }

                // Send immediate reminder if pickup is within 1 hour
                if (timeUntilPickup.inMinutes <= 60 &&
                    timeUntilPickup.inMinutes > 0 &&
                    !_notifiedBins.contains('$binId-imminent')) {
                  _showNotification(
                    '🔔 Pickup Soon!',
                    'Your $binType pickup is in less than 1 hour!',
                    Colors.deepOrange,
                  );
                  // Show system notification
                  _notificationService.showPickupReminderNotification(
                    binType: binType,
                    hoursUntilPickup: 0,
                  );
                  _notifiedBins.add('$binId-imminent');
                }
              }

              if (now.isAfter(pickupDateTime)) {
                await doc.reference.update({
                  'status': 'in-transit',
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking bin status: $e');
    }
  }

  String _formatTimeRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final diff = targetDate.difference(now);

    if (diff.isNegative) {
      return "Pickup time reached";
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    String result = "";
    if (days > 0) result += "${days}d ";
    if (hours > 0 || days > 0) result += "${hours}h ";
    result += "${minutes}m remaining";

    return result;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.orange;
      case 'available':
        return Colors.green;
      case 'in-use':
        return Colors.blue;
      case 'full':
        return Colors.red;
      case 'in-transit':
        return Colors.purple;
      case 'picked-up':
      case 'picked up':
        return Colors.teal;
      case 'recycled':
      case 'completed':
        return Colors.lightGreen;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled for Pickup';
      case 'available':
        return 'Available';
      case 'in-use':
        return 'In Use';
      case 'full':
        return 'Full - Awaiting Pickup';
      case 'in-transit':
        return 'In Transit';
      case 'picked-up':
      case 'picked up':
        return 'Picked Up';
      case 'recycled':
      case 'completed':
        return 'Recycled';
      case 'maintenance':
        return 'Under Maintenance';
      default:
        return 'Unknown';
    }
  }

  int _getProgressPercent(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'available':
        return 15;
      case 'in-use':
        return 35;
      case 'full':
        return 50;
      case 'in-transit':
        return 70;
      case 'picked-up':
      case 'picked up':
        return 85;
      case 'recycled':
      case 'completed':
        return 100;
      case 'maintenance':
        return 20;
      default:
        return 0;
    }
  }

  Color _getFillLevelColor(int fillLevel) {
    if (fillLevel > 90) return Colors.red;
    if (fillLevel > 70) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: AppBar(
        title: const Text('Bin Tracker'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade800
            : Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Google Maps section
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade800
                : Colors.green,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recycling Centers Near You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Reverted to GoogleMap
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                _userLocation ??
                                const LatLng(
                                  -1.2921,
                                  36.8219,
                                ), // Nairobi default
                            zoom: 12.0,
                          ),
                          onMapCreated: (controller) {
                            _googleMapController = controller;
                          },
                          markers: {
                            // User location marker
                            if (_userLocation != null)
                              Marker(
                                markerId: const MarkerId('user_location'),
                                position: _userLocation!,
                                // Blue marker for user
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueBlue,
                                ),
                              ),
                            // Animated truck marker
                            if (_truckPosition != null)
                              Marker(
                                markerId: const MarkerId('delivery_truck'),
                                position: _truckPosition!,
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange,
                                ),
                                infoWindow: const InfoWindow(
                                  title: '🚚 Pickup Truck',
                                  snippet: 'En route',
                                ),
                                rotation: _calculateBearing(
                                  _truckPosition!,
                                  _truckDestination ?? _truckPosition!,
                                ),
                              ),
                            // Recycling center markers
                            ..._recyclingCenters.map((center) {
                              return Marker(
                                markerId: MarkerId(center['name']),
                                position: center['position'],
                                // Green marker for recycling centers
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen,
                                ),
                                onTap: () => _showCenterInfo(center),
                              );
                            }).toSet(),
                          },
                          // Disable unnecessary controls for a cleaner UI
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled:
                              false, // Use the custom FAB instead
                          myLocationEnabled: true,
                        ),
                        // Location button overlay
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _isLoadingLocation
                                ? null
                                : _getUserLocation,
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                    color: Colors.green,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status tabs
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusTab('all', 'All Bins'),
                  const SizedBox(width: 8),
                  _buildStatusTab('available', 'Available'),
                  const SizedBox(width: 8),
                  _buildStatusTab('in-use', 'In Use'),
                  const SizedBox(width: 8),
                  _buildStatusTab('full', 'Full'),
                  const SizedBox(width: 8),
                  _buildStatusTab('scheduled', 'Scheduled'),
                  const SizedBox(width: 8),
                  _buildStatusTab('in-transit', 'In Transit'),
                  const SizedBox(width: 8),
                  _buildStatusTab('completed', 'Recycled'),
                ],
              ),
            ),
          ),

          // Bin list
          Expanded(child: _buildBinList()),
        ],
      ),
    );
  }

  void _showCenterInfo(Map<String, dynamic> center) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.recycling, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(center['name'], style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(center['address'])),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Accepts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (center['types'] as List<String>).map((type) {
                return Chip(
                  label: Text(type),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String status, String label) {
    final isSelected = _selectedStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBinList() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view bins'));
    }

    // Build the query based on selected status
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bins')
        .where('userId', isEqualTo: user.uid);

    // Add status filter if not 'all'
    if (_selectedStatus != 'all') {
      // For 'completed' tab, show both 'recycled' and 'completed' statuses
      if (_selectedStatus == 'completed') {
        query = query.where(
          'status',
          whereIn: ['completed', 'recycled', 'picked-up'],
        );
      } else {
        query = query.where('status', isEqualTo: _selectedStatus);
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('lastUpdated', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No bins found${_selectedStatus != 'all' ? ' with this status' : ''}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Request Bin Registration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bin registration request submitted. Our team will contact you shortly.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildBinItem(doc);
          },
        );
      },
    );
  }

  Widget _buildBinItem(DocumentSnapshot doc) {
    final bin = doc.data() as Map<String, dynamic>;
    final status = bin['status'] ?? 'scheduled';
    final fillLevel = bin['fillLevel'] ?? 0;
    final type = bin['type'] ?? 'General Waste';
    final location = bin['location'] ?? 'No location data';
    final lastUpdated = bin['lastUpdated'] as Timestamp?;

    return FutureBuilder<Widget>(
      future: _buildBinItemContent(
        doc.id,
        bin,
        status,
        fillLevel,
        type,
        location,
        lastUpdated,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          );
        }
        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }

  Future<Widget> _buildBinItemContent(
    String binId,
    Map<String, dynamic> bin,
    String status,
    int fillLevel,
    String type,
    String location,
    Timestamp? lastUpdated,
  ) async {
    Widget? countdownWidget;

    if (bin['pickupId'] != null && status == 'scheduled') {
      try {
        final pickupDoc = await FirebaseFirestore.instance
            .collection('pickups')
            .doc(bin['pickupId'])
            .get();

        if (pickupDoc.exists) {
          final pickup = pickupDoc.data();
          if (pickup?['date'] != null && pickup?['time'] != null) {
            final pickupDateTime = DateTime.parse(
              '${pickup!['date']}T${pickup['time']}',
            );
            final timeRemaining = _formatTimeRemaining(pickupDateTime);

            countdownWidget = Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeRemaining,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        print('Error fetching pickup data: $e');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 32,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        lastUpdated != null
                            ? '${lastUpdated.toDate().day}/${lastUpdated.toDate().month}/${lastUpdated.toDate().year}'
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: $location',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(status),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getFillLevelColor(fillLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Fill: $fillLevel%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getFillLevelColor(fillLevel),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (countdownWidget != null) countdownWidget,
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _getProgressPercent(status) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(status),
                      ),
                      minHeight: 8,
                    ),
                  ),
                  // Track truck button for in-transit bins
                  if (status == 'in-transit' || status == 'picked-up')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to tracking map screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BinTrackingMapScreen(
                                  binId: binId,
                                  binData: bin,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on, size: 18),
                          label: const Text(
                            'Track Bin on Map',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
