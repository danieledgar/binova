import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'notification_message_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // v7: Use GoogleSignIn instance (serverClientId comes from google-services.json)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  // Track current Google user manually (v7 removed currentUser property)
  GoogleSignInAccount? _currentGoogleUser;

  /// Initialize Google Sign-In (required in v7)
  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;

    try {
      // The serverClientId is now read from google-services.json automatically
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;
      print('Google Sign-In initialized successfully');
    } catch (e) {
      print('Failed to initialize Google Sign-In: $e');
      rethrow;
    }
  }

  /// Sign up with email, password, and username
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String username,
    String role,
  ) async {
    try {
      if (email.isEmpty ||
          password.isEmpty ||
          username.isEmpty ||
          role.isEmpty) {
        throw 'Please fill in all fields';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send welcome notification
        await NotificationMessageService.sendWelcomeMessage(user.uid);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Sign up failed: $e';
    }
  }

  /// Login with email & password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Please fill in all fields';
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Login failed: $e';
    }
  }

  /// Sign in with Google (v7 API)
  Future<User?> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In first
      await _initializeGoogleSignIn();

      if (kIsWeb) {
        // WEB: Use Firebase Auth popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;

        if (user != null) {
          await _saveUserToFirestore(user);
        }
        return user;
      } else {
        // MOBILE: Use google_sign_in v7 API

        // v7: Use authenticate() instead of signIn()
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
          scopeHint: <String>['email', 'profile'],
        );

        // Store current user
        _currentGoogleUser = googleUser;

        // v7: authentication is now synchronous (not a Future)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // Get the ID token
        final String? idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'Failed to get ID token from Google';
        }

        // Get authorization for scopes to get access token
        final authClient = _googleSignIn.authorizationClient;
        final authorization = await authClient.authorizationForScopes(<String>[
          'email',
          'profile',
        ]);

        // Create Firebase credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization?.accessToken,
          idToken: idToken,
        );

        // Sign in to Firebase
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          await _saveUserToFirestore(user);
        }
        return user;
      }
    } on GoogleSignInException catch (e) {
      print(
        'Google Sign-In error: code: ${e.code.name} description: ${e.description} details: ${e.details}',
      );
      throw _handleGoogleSignInError(e);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('Unexpected error during Google Sign-In: $e');
      throw 'Failed to sign in with Google: ${e.toString()}';
    }
  }

  /// Attempt silent sign-in (v7: use attemptLightweightAuthentication)
  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    try {
      await _initializeGoogleSignIn();

      // v7: attemptLightweightAuthentication can return Future or immediate result
      final result = _googleSignIn.attemptLightweightAuthentication();

      // Handle both sync and async returns
      if (result is Future<GoogleSignInAccount?>) {
        return await result;
      } else {
        return result as GoogleSignInAccount?;
      }
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }

  /// Helper method to save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'username': user.displayName ?? "New User",
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'role': 'citizen', // Default role for Google sign-in
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('User saved to Firestore: ${user.uid}');

        // Send welcome notification for new users
        await NotificationMessageService.sendWelcomeMessage(user.uid);
      } else {
        print('User already exists in Firestore: ${user.uid}');
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
      // Don't throw here - user is authenticated even if Firestore fails
    }
  }

  /// Reset password by email
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw 'Please enter your email address';
      }
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Failed to send reset email: $e';
    }
  }

  /// Sign out (from Firebase + Google)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb && _currentGoogleUser != null) {
        try {
          await _googleSignIn.signOut();
          _currentGoogleUser = null;
        } catch (e) {
          print('Google sign out error (can be ignored): $e');
        }
      }
    } catch (e) {
      print('Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Current logged-in user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Handle Google Sign-In errors (v7)
  String _handleGoogleSignInError(GoogleSignInException e) {
    switch (e.code.name) {
      case 'canceled':
        return 'Sign-in was cancelled. Please try again.';
      case 'interrupted':
        return 'Sign-in was interrupted. Please try again.';
      case 'clientConfigurationError':
        return 'Configuration issue with Google Sign-In. Please contact support.';
      case 'providerConfigurationError':
        return 'Google Sign-In is currently unavailable.';
      case 'uiUnavailable':
        return 'Google Sign-In UI is currently unavailable.';
      case 'userMismatch':
        return 'Account mismatch. Please sign out and try again.';
      case 'unknownError':
      default:
        return 'An unexpected error occurred: ${e.description ?? "Unknown error"}';
    }
  }

  /// Handle Firebase Auth errors with friendly messages
  String _handleAuthError(FirebaseAuthException e) {
    print('Firebase Auth Error Code: ${e.code}');
    print('Firebase Auth Error Message: ${e.message}');

    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed before completion.';
      case 'popup-blocked':
        return 'Sign-in popup was blocked by the browser.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message ?? "Unknown error"}';
    }
  }
}
