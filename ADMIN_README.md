# Binova Admin App

A separate administrative application for managing the Binova waste management platform. This app runs concurrently with the main user app and provides comprehensive service management capabilities.

## 🚀 Running the Admin App

### Option 1: Using the Script (Recommended)
```bash
./admin-run.sh
```

### Option 2: Using Flutter Command
```bash
flutter run -t lib/admin_main.dart
```

## 🔐 Admin Access

The admin app requires **admin role authentication**. Only users with `role: "admin"` in their Firestore user document can access the admin platform.

### Setting Up an Admin User

1. Create a user account in the main Binova app
2. In Firebase Console, go to Firestore
3. Find the user document in the `users` collection
4. Add or update the field: `role: "admin"`

Example Firestore document:
```json
{
  "email": "admin@binova.com",
  "username": "Admin User",
  "role": "admin",
  "createdAt": "2025-10-21T12:00:00Z"
}
```

## 📱 Admin Features

### 1. Service Completion Management
- **Complete Pickups**: Mark waste pickups as picked up/completed
- **Track Status**: View pending, in-transit, and completed services
- **Update Information**: Modify pickup details and schedules

### 2. Dumping Report Review
- **View Reports**: See all illegal dumping reports with photo evidence
- **Photo Evidence**: Review uploaded images from reports
- **Investigation**: Add notes and mark reports as investigated/resolved
- **Status Management**: Track pending, investigating, and resolved reports

### 3. Food Stock Inventory
- **Track Donations**: Manage food donations and inventory
- **Stock Levels**: Monitor quantities and low stock alerts
- **Categories**: Organize by vegetables, fruits, grains, canned, dairy
- **Expiry Dates**: Track expiration dates for perishables
- **Add/Update/Delete**: Full CRUD operations for inventory items

### 4. Bin Management
- **Monitor Bins**: Track all bins and their status
- **Fill Levels**: View real-time fill percentages
- **Status Updates**: Mark bins as available, in-use, maintenance, or full
- **Location Tracking**: Manage bin locations and assignments

### 5. User Management
- **View All Users**: List all registered users
- **Role Management**: Toggle between user and admin roles
- **User Details**: View user information and activity
- **Account Management**: Delete or disable user accounts

### 6. Analytics Dashboard
- **Statistics Overview**: See key metrics at a glance
- **Priority Tasks**: Highlighted pending items requiring attention
- **Charts & Graphs**: Visual representation of data trends

## 🎨 Theme Support

The admin app supports both light and dark themes:
- Toggle theme using the sun/moon icon in the app bar
- Theme preference is shared with the main app

## 📊 Admin Dashboard Layout

### Priority Tasks Section
- **Pending Pickups**: Number of pickups awaiting completion
- **Pending Reports**: Unresolved dumping reports
- **Low Stock Items**: Food inventory items below threshold
- **Active Bins**: Number of operational bins

### Service Management Section
- **Complete Pickups**: Direct access to pickup completion
- **Review Dumping Reports**: Access photo evidence and investigation tools
- **Food Stock Inventory**: Manage donation inventory
- **Bin Management**: Monitor bin status and levels
- **Users & Analytics**: Access user management and statistics

## 🔒 Security Features

- **Role-Based Access Control**: Only admin users can login
- **Firebase Authentication**: Secure authentication flow
- **Firestore Security Rules**: Backend protection (configure separately)
- **Session Management**: Secure logout functionality

## 🛠️ Technical Details

- **Entry Point**: `lib/admin_main.dart` (separate from main app)
- **Authentication Screen**: `lib/screens/admin_login_screen.dart`
- **Main Dashboard**: `lib/screens/admin_dashboard_screen.dart`
- **Dependencies**: Shares dependencies with main app (Firebase, Provider, etc.)

## 📱 Running Both Apps

You can run both the main user app and admin app simultaneously:

### Terminal 1 - Main User App:
```bash
./dev-run.sh
# or
flutter run
```

### Terminal 2 - Admin App:
```bash
./admin-run.sh
# or
flutter run -t lib/admin_main.dart
```

## 🗄️ Firestore Collections Used

- `users` - User accounts and roles
- `pickups` - Waste pickup requests
- `dumping_reports` - Illegal dumping reports with photos
- `food_stock` - Food donation inventory
- `bins` - Bin tracking and status

## 🐛 Troubleshooting

### "Access denied" Error
- Verify the user has `role: "admin"` in Firestore
- Check Firebase Authentication is working
- Ensure internet connection for Firebase

### Theme Not Working
- Verify `ThemeProvider` is properly configured
- Check Provider package is imported

### Photos Not Loading
- Verify `cached_network_image` package is installed
- Check Firebase Storage permissions
- Ensure images were uploaded with proper URLs

## 📝 Notes

- Admin app uses the same Firebase project as the main app
- Changes made in admin app are reflected in real-time
- Both apps can run simultaneously on different devices
- Admin credentials should be kept secure

## 🔄 Updates

When updating the main app, remember to also test the admin app for compatibility with any Firestore structure changes.

---

**Binova Admin** - Service Management Made Easy 🌱
