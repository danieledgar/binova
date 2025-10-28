// lib/screens/schedule_pickup_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_message_service.dart';
// REVERTED to Google Maps
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SchedulePickupScreen extends StatefulWidget {
  const SchedulePickupScreen({super.key});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instructionsController = TextEditingController();
  final AuthService _authService = AuthService();
  // REVERTED controller type
  GoogleMapController? _googleMapController;

  String _wasteType = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  LatLng? _selectedLocation;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial location to pre-fill the form
    _getUserLocation();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _googleMapController?.dispose(); // Dispose the Google Map controller
    super.dispose();
  }

  Future<void> _getUserLocation({bool moveMap = false}) async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Enable',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

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
            SnackBar(
              content: const Text(
                'Location permissions are permanently denied',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = newLocation;
        // Only set _selectedLocation if this is the initial fetch for the form
        if (!moveMap) {
          _selectedLocation = newLocation;
        }
        _isLoadingLocation = false;
      });

      if (moveMap && _googleMapController != null) {
        _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 15.0),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              moveMap
                  ? 'Map moved to current location!'
                  : 'Initial location set.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showMapPicker() {
    LatLng? tempSelectedLocation = _selectedLocation; // Initialize outside

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          GoogleMapController? modalMapController;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Pickup Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tempSelectedLocation == null
                                  ? '👆 Tap anywhere on the map to pin your location'
                                  : '✓ Location pinned! Tap elsewhere to move it',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: tempSelectedLocation == null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: Stack(
                    children: [
                      // Reverted to GoogleMap
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target:
                              tempSelectedLocation ??
                              _userLocation ??
                              const LatLng(-1.2921, 36.8219),
                          zoom: 15.0,
                        ),
                        onMapCreated: (controller) {
                          modalMapController = controller;
                        },
                        // Set the location based on a tap
                        onTap: (point) {
                          print(
                            'Map tapped at: ${point.latitude}, ${point.longitude}',
                          );
                          setModalState(() {
                            tempSelectedLocation = point;
                          });
                        },
                        markers: {
                          if (tempSelectedLocation != null)
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: tempSelectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Pickup Location',
                                snippet: 'Tap elsewhere to move pin',
                              ),
                            ),
                        },
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        compassEnabled: false,
                      ),

                      // Instruction overlay when no location is selected
                      if (tempSelectedLocation == null)
                        Positioned(
                          bottom: 100,
                          left: 16,
                          right: 16,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tap anywhere on the map',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'to pin your pickup location',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Location info overlay
                      if (tempSelectedLocation != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Location:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${tempSelectedLocation!.latitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Lng: ${tempSelectedLocation!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // My Location button
                      Positioned(
                        right: 16,
                        bottom: 80,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.white,
                              heroTag: 'myLocation',
                              onPressed: () async {
                                if (_userLocation != null) {
                                  modalMapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      _userLocation!,
                                      15.0,
                                    ),
                                  );
                                  setModalState(() {
                                    tempSelectedLocation = _userLocation;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Getting your location...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  // Call _getUserLocation with moveMap = true to update _userLocation and move the map
                                  await _getUserLocation(moveMap: true);
                                  if (_userLocation != null) {
                                    setModalState(() {
                                      tempSelectedLocation = _userLocation;
                                    });
                                  }
                                }
                              },
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.white,
                              heroTag: 'zoomIn',
                              onPressed: () {
                                modalMapController?.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              },
                              child: const Icon(Icons.add, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.white,
                              heroTag: 'zoomOut',
                              onPressed: () {
                                modalMapController?.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              },
                              child: const Icon(
                                Icons.remove,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Confirm button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: tempSelectedLocation == null
                          ? null
                          : () {
                              setState(() {
                                _selectedLocation = tempSelectedLocation;
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Location selected successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitPickup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select a pickup date');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a pickup time');
      return;
    }
    if (_selectedLocation == null) {
      _showError('Please select a pickup location');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not logged in';

      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final pickupRef = await FirebaseFirestore.instance
          .collection('pickups')
          .add({
            'userId': user.uid,
            'email': user.email,
            'type': _wasteType,
            'date': dateStr,
            'time': timeStr,
            'instructions': _instructionsController.text.trim(),
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'status': 'Scheduled',
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance.collection('bins').add({
        'userId': user.uid,
        'email': user.email,
        'type': _wasteType,
        'pickupId': pickupRef.id,
        'location': _instructionsController.text.trim(),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'status': 'scheduled',
        'fillLevel': 75,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Send pickup scheduled notification
      await NotificationMessageService.sendPickupScheduledMessage(
        user.uid,
        dateStr,
        timeStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Pickup scheduled successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to schedule pickup: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: AppBar(
        title: const Text('Schedule Pickup'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade800
            : Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Type of Waste',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        initialValue: _wasteType.isEmpty ? null : _wasteType,
                        items: const [
                          DropdownMenuItem(
                            value: 'General Waste',
                            child: Text('General Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'Recyclables',
                            child: Text('Recyclables'),
                          ),
                          DropdownMenuItem(
                            value: 'Organic Waste',
                            child: Text('Organic Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'Bulk Waste',
                            child: Text('Bulk Waste'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _wasteType = value ?? '');
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select waste type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Pickup Date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Select date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Pickup Time',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedTime == null
                                ? 'Select time'
                                : _selectedTime!.format(context),
                            style: TextStyle(
                              color: _selectedTime == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Picker (Opens map directly)
                      InkWell(
                        onTap: _isLoadingLocation ? null : _showMapPicker,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedLocation != null
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: _selectedLocation != null ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _selectedLocation != null
                                ? Colors.green.shade50
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _selectedLocation != null
                                    ? Colors.green
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedLocation != null
                                          ? '📍 Location Pinned (Tap to Change)'
                                          : _isLoadingLocation
                                          ? 'Getting location...'
                                          : 'Tap to Pin Pickup Location on Map',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedLocation != null
                                            ? Colors.green.shade700
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    if (_selectedLocation != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_isLoadingLocation)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: _selectedLocation != null
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _instructionsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Additional Instructions',
                          hintText: 'Apartment name, gate details, floor, etc.',
                          prefixIcon: const Icon(Icons.notes),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide additional details';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPickup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade700
                        : Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Scheduling...'),
                          ],
                        )
                      : const Text(
                          'Schedule Pickup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
