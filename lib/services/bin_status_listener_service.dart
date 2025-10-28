// lib/services/bin_status_listener_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

/// Service that listens to bin status changes in the background
/// and sends notifications even when the app is not actively viewing the bin tracker
class BinStatusListenerService {
  static final BinStatusListenerService _instance =
      BinStatusListenerService._internal();
  factory BinStatusListenerService() => _instance;
  BinStatusListenerService._internal();

  final NotificationService _notificationService = NotificationService();
  final Set<String> _notifiedBins = {};
  bool _isListening = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  /// Initialize and start listening for bin status changes
  Future<void> initialize() async {
    await _notificationService.initialize();
    startListening();
  }

  /// Start listening for bin status changes
  void startListening() {
    if (_isListening) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('🔔 Starting global bin status listener for user: ${user.uid}');

    _subscription = FirebaseFirestore.instance
        .collection('bins')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            _handleBinStatusChanges(snapshot);
          },
          onError: (error) {
            print('Error listening to bin status changes: $error');
          },
        );

    _isListening = true;
  }

  /// Handle bin status changes and send notifications
  void _handleBinStatusChanges(QuerySnapshot snapshot) async {
    // Get notification preferences
    final prefs = await _getNotificationPreferences();
    if (prefs['binStatusUpdates'] != true) return;

    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.modified) {
        final bin = change.doc.data() as Map<String, dynamic>?;
        if (bin == null) continue;

        final binId = change.doc.id;
        final status = bin['status'] as String?;
        final type = bin['type'] as String? ?? 'Waste';

        if (status == null) continue;

        // Check if status changed to in-transit
        if (status == 'in-transit' &&
            !_notifiedBins.contains('$binId-transit')) {
          print('📲 Sending notification: Bin $binId is in transit');

          await _notificationService.showBinStatusNotification(
            status: 'in-transit',
            binType: type,
          );

          _notifiedBins.add('$binId-transit');
        }
        // Check if status changed to completed
        else if (status == 'completed' &&
            !_notifiedBins.contains('$binId-completed')) {
          print('📲 Sending notification: Bin $binId is completed');

          await _notificationService.showBinStatusNotification(
            status: 'completed',
            binType: type,
          );

          _notifiedBins.add('$binId-completed');
        }
        // Check if status changed to scheduled (pickup reminder)
        else if (status == 'scheduled' &&
            !_notifiedBins.contains('$binId-scheduled') &&
            prefs['pickupReminders'] == true) {
          print('📲 Sending notification: Bin $binId is scheduled');

          await _notificationService.showPickupReminderNotification(
            binType: type,
            hoursUntilPickup: 24, // Default to 24 hours
          );

          _notifiedBins.add('$binId-scheduled');
        }
      }
    }
  }

  /// Get user's notification preferences
  Future<Map<String, bool>> _getNotificationPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'pickupReminders': true, 'binStatusUpdates': true};
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        return {
          'pickupReminders': data?['pickupReminders'] ?? true,
          'binStatusUpdates': data?['binStatusUpdates'] ?? true,
        };
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
    }

    return {'pickupReminders': true, 'binStatusUpdates': true};
  }

  /// Stop listening for bin status changes
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    print('🔕 Stopped global bin status listener');
  }

  /// Clear notification history (useful for testing)
  void clearNotificationHistory() {
    _notifiedBins.clear();
    print('🗑️ Cleared notification history');
  }

  /// Dispose and cleanup
  void dispose() {
    stopListening();
    _notifiedBins.clear();
  }
}
