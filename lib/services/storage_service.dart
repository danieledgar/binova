import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  /// Generates a unique file name for Firebase Storage, typically for a user's profile photo.
  static String _generateFileName(String userId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'profile_photos/$userId-$timestamp.$extension';
  }

  /// Uploads an image file to Firebase Storage and returns the public URL.
  ///
  /// Takes a [File] object and the [userId] to create a unique key.
  /// Returns the downloadable URL of the uploaded image, or null on failure.
  static Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final extension = imageFile.path.split('.').last;
      final fileName = _generateFileName(userId, extension);

      // Get a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Upload the file to Firebase Storage
      final uploadTask = storageRef.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      final taskSnapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print('Successfully uploaded file: $fileName');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Error uploading image to Firebase Storage: ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return null;
    }
  }

  /// Deletes an image from Firebase Storage using its full URL.
  ///
  /// Takes the full public [imageUrl] of the file in Firebase Storage.
  /// Returns true if deletion is successful, false otherwise.
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Get a reference to the file from its download URL
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);

      // Delete the file
      await ref.delete();

      print('Successfully deleted file: ${ref.fullPath}');
      return true;
    } on FirebaseException catch (e) {
      print('Error deleting file from Firebase Storage: ${e.message}');
      return false;
    } catch (e) {
      print('An unexpected error occurred while deleting file: $e');
      return false;
    }
  }
}
