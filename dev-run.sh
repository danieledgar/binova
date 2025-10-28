#!/bin/bash
# Development script: Inject API key before running

# Load environment variables
set -a
source .env
set +a

# Replace placeholder in web/index.html
sed -i "s|key=MAP_API_KEY|key=$MAPS_API_KEY|g" web/index.html

echo "✅ API key injected. Running Flutter..."

# Run Flutter
flutter run -d chrome
