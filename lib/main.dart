// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'config/theme_provider.dart';
import 'config/app_theme.dart';
import 'services/bin_status_listener_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI overlay style to match the splash screen
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize global bin status listener service
  final binStatusListener = BinStatusListenerService();

  // Start listening when user logs in
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      print('🔔 User logged in, starting bin status listener');
      binStatusListener.initialize();
    } else {
      print('🔕 User logged out, stopping bin status listener');
      binStatusListener.stopListening();
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BinovaApp(),
    ),
  );
}

class BinovaApp extends StatelessWidget {
  const BinovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Binova',
          theme: AppTheme.lightTheme.copyWith(
            scaffoldBackgroundColor: Colors.black, // Black background
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            scaffoldBackgroundColor: Colors.black, // Black background
          ),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
