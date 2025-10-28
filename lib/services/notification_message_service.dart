// lib/services/notification_message_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationMessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a notification message to a specific user (stores in Firestore)
  static Future<void> sendMessage({
    required String userId,
    required String title,
    required String message,
    required String category,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'category': category, // Account, Update, Environmental, News, Pickup
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Send welcome message to new users
  static Future<void> sendWelcomeMessage(String userId) async {
    await sendMessage(
      userId: userId,
      title: 'Welcome to Binova! 🌱',
      message:
          'Thank you for joining Binova! Together, we\'re making the world cleaner and greener. Start by scheduling your first pickup or exploring our recycling information.',
      category: 'Account',
    );
  }

  /// Send password change confirmation
  static Future<void> sendPasswordChangedMessage(String userId) async {
    await sendMessage(
      userId: userId,
      title: 'Password Changed Successfully',
      message:
          'Your account password has been updated. If you didn\'t make this change, please contact support immediately.',
      category: 'Account',
    );
  }

  /// Send pickup scheduled confirmation
  static Future<void> sendPickupScheduledMessage(
    String userId,
    String date,
    String time,
  ) async {
    await sendMessage(
      userId: userId,
      title: 'Pickup Scheduled ✅',
      message:
          'Your waste pickup has been scheduled for $date at $time. We\'ll send you a reminder before the pickup time.',
      category: 'Pickup',
    );
  }

  /// Send pickup reminder
  static Future<void> sendPickupReminderMessage(
    String userId,
    String date,
    String time,
  ) async {
    await sendMessage(
      userId: userId,
      title: 'Pickup Reminder 🔔',
      message:
          'Reminder: Your pickup is scheduled for today at $time. Please ensure your waste is ready for collection.',
      category: 'Pickup',
    );
  }

  /// Send pickup completed message
  static Future<void> sendPickupCompletedMessage(
    String userId,
    String wasteType,
  ) async {
    await sendMessage(
      userId: userId,
      title: 'Pickup Completed! ♻️',
      message:
          'Your $wasteType has been successfully collected and is being processed. Thank you for your contribution to a cleaner environment!',
      category: 'Pickup',
    );
  }

  /// Send environmental tip
  static Future<void> sendEnvironmentalTip(String userId, String tip) async {
    await sendMessage(
      userId: userId,
      title: 'Green Tip of the Day 🌍',
      message: tip,
      category: 'Environmental',
    );
  }

  /// Send app update notification
  static Future<void> sendAppUpdateMessage(String userId) async {
    await sendMessage(
      userId: userId,
      title: 'New Features Available! 🎉',
      message:
          'We\'ve added new features to improve your experience: Enhanced map picker, real-time notifications, and more! Update your app to get the latest features.',
      category: 'Update',
    );
  }

  /// Send news/announcement
  static Future<void> sendNewsMessage(
    String userId,
    String title,
    String message,
  ) async {
    await sendMessage(
      userId: userId,
      title: title,
      message: message,
      category: 'News',
    );
  }

  /// Broadcast message to all users
  static Future<void> broadcastMessage({
    required String title,
    required String message,
    required String category,
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        await sendMessage(
          userId: userDoc.id,
          title: title,
          message: message,
          category: category,
        );
      }
    } catch (e) {
      print('Error broadcasting message: $e');
    }
  }

  /// Sample environmental tips
  static final List<String> environmentalTips = [
    'Did you know? Recycling one aluminum can saves enough energy to power a TV for 3 hours!',
    'Composting food waste can reduce your household waste by up to 30%.',
    'Using reusable bags saves approximately 6 plastic bags per week per person.',
    'Recycling paper saves 17 trees per ton of paper recycled.',
    'Glass can be recycled endlessly without losing quality or purity.',
    'E-waste contains valuable materials like gold, silver, and copper that can be recovered.',
    'Plastic bottles take 450 years to decompose in a landfill.',
    'Recycling one ton of plastic saves 5,774 kWh of energy.',
    'Reducing food waste is one of the most effective ways to combat climate change.',
    'Every ton of recycled plastic saves 2,000 gallons of gasoline.',
  ];

  /// Send random environmental tip
  static Future<void> sendRandomEnvironmentalTip(String userId) async {
    final random =
        DateTime.now().millisecondsSinceEpoch % environmentalTips.length;
    await sendEnvironmentalTip(userId, environmentalTips[random]);
  }
}
