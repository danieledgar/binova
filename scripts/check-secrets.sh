#!/bin/bash

# Script to check for sensitive data before committing

echo "🔍 Checking for sensitive data in staged files..."

# Define patterns to search for
PATTERNS=(
    "AIza[0-9A-Za-z_-]{35}"  # Google API keys
    "api_key.*=.*['\"][^'\"]{30,}['\"]"
    "API_KEY.*=.*['\"][^'\"]{30,}['\"]"
)

# Files that should not be committed
SENSITIVE_FILES=(
    "google-services.json"
    "GoogleService-Info.plist"
    ".env"
    "users.json"
)

ERROR_FOUND=0

# Check for sensitive files
echo ""
echo "📁 Checking for sensitive files..."
for file in "${SENSITIVE_FILES[@]}"; do
    if git diff --cached --name-only | grep -q "$file"; then
        echo "❌ ERROR: Sensitive file '$file' is staged for commit!"
        ERROR_FOUND=1
    fi
done

# Check for API keys in staged files
echo ""
echo "🔑 Checking for API keys in code..."
for pattern in "${PATTERNS[@]}"; do
    if git diff --cached | grep -E "$pattern" > /dev/null; then
        echo "❌ ERROR: Potential API key found in staged changes!"
        echo "   Pattern: $pattern"
        ERROR_FOUND=1
    fi
done

if [ $ERROR_FOUND -eq 0 ]; then
    echo ""
    echo "✅ No sensitive data detected!"
    echo "✅ Safe to commit."
else
    echo ""
    echo "⚠️  COMMIT BLOCKED: Sensitive data detected!"
    echo "   Please remove sensitive data before committing."
    echo ""
    echo "   Run: git reset HEAD <file>  to unstage files"
    exit 1
fi
