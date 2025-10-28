# Binova - Security Setup Guide

## 🔐 IMPORTANT: Complete This Setup Before Running the App

This project uses sensitive API keys and configuration files that are NOT included in the repository for security reasons.

---

## 📋 Quick Start Checklist

- [ ] Configure Firebase (Method 1 or 2)
- [ ] Set up Google Maps API
- [ ] Create environment variables file
- [ ] Update configuration files
- [ ] Run the app

---

## 1️⃣ Firebase Configuration

### Method 1: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This automatically creates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` (if you have iOS)

### Method 2: Manual Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing
3. Add apps for your platforms:

#### For Android:
- Add Android app with package: `com.example.binova`
- Download `google-services.json`
- Place in: `android/app/google-services.json`

#### For iOS:
- Add iOS app
- Download `GoogleService-Info.plist`
- Place in root: `GoogleService-Info.plist`

#### For Web/All Platforms:
- Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart`
- Fill in your Firebase project details from Firebase Console

---

## 2️⃣ Google Maps API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select existing
3. Enable these APIs:
   - **Maps JavaScript API** (for web)
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Directions API** (for route drawing)

4. Create API Key:
   - Go to **Credentials** → **Create Credentials** → **API Key**
   - **Important**: Add restrictions to secure your key!

5. Configure API Key Restrictions:
   - **Application restrictions**: 
     - Android: Add your app's package name and SHA-1
     - iOS: Add your iOS bundle ID
     - Web: Add your website URLs
   - **API restrictions**: Select only the APIs you enabled above

---

## 3️⃣ Environment Variables

Create `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and add your API key:
```
MAPS_API_KEY=your_actual_google_maps_api_key_here
```

---

## 4️⃣ Update Configuration Files

### Android (`android/app/src/main/AndroidManifest.xml`)

Replace `YOUR_GOOGLE_MAPS_API_KEY`:
```xml
<meta-data 
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### Web (`web/index.html.template`)

Replace `YOUR_GOOGLE_MAPS_API_KEY`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY_HERE"></script>
```

### Bin Tracking Screen (`lib/screens/bin_tracking_map_screen.dart`)

The code is already set up to use environment variables. To use it:

```bash
# Run with environment variable
flutter run --dart-define=MAPS_API_KEY=your_actual_key
```

Or hardcode it temporarily for development (remember to revert before committing):
```dart
final String _googleApiKey = 'your_actual_key';
```

---

## 5️⃣ Install Dependencies

```bash
flutter pub get
```

---

## 6️⃣ Run the App

### User App:
```bash
flutter run
# or
./dev-run.sh
```

### Admin App:
```bash
flutter run -d chrome --target lib/admin_main.dart
# or
./admin-run.sh
```

---

## 🔒 Files That Must Stay Private

These files contain sensitive data and are already in `.gitignore`:

- ❌ `android/app/google-services.json`
- ❌ `GoogleService-Info.plist`
- ❌ `lib/firebase_options.dart`
- ❌ `.env`
- ❌ `users.json`
- ❌ `firebase-debug.log`

**NEVER commit these files to version control!**

---

## ✅ Template Files (Safe to Commit)

These are examples for other developers:

- ✅ `android/app/google-services.json.example`
- ✅ `GoogleService-Info.plist.example`
- ✅ `lib/firebase_options.dart.example`
- ✅ `.env.example`

---

## 🆘 Troubleshooting

### "API key not found" error
- Make sure you've created `.env` file
- Check that API key is correctly set in configuration files
- For Flutter, use `--dart-define=MAPS_API_KEY=your_key`

### Firebase connection issues
- Verify `google-services.json` is in the correct location
- Check that package names match in Firebase Console
- Run `flutterfire configure` again to reconfigure

### Maps not displaying
- Enable Maps JavaScript API in Google Cloud Console
- Check API key restrictions aren't blocking your request
- Verify billing is enabled for your Google Cloud project

---

## 📞 Need Help?

1. Read the [GitHub Push Guide](GITHUB_PUSH_GUIDE.md)
2. Check Firebase docs: https://firebase.google.com/docs
3. Check Google Maps docs: https://developers.google.com/maps

---

## ⚠️ Security Best Practices

1. **Never** commit API keys to version control
2. **Always** use environment variables for secrets
3. **Enable** API key restrictions in Google Cloud Console
4. **Rotate** API keys regularly
5. **Use** different keys for development and production
6. **Monitor** API usage in Google Cloud Console

---

## 🎉 You're All Set!

Once you've completed these steps, you can run the Binova app locally. For deploying to production, make sure to use production API keys and Firebase projects.
