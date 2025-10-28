# Quick Guide: Preparing for GitHub Push

## ✅ What I've Done For You

1. **Updated `.gitignore`** to exclude sensitive files:
   - `google-services.json`
   - `GoogleService-Info.plist`
   - `.env` files
   - `users.json`
   - `firebase-debug.log`

2. **Created template files** (safe to commit):
   - `google-services.json.example`
   - `GoogleService-Info.plist.example`
   - `.env.example`

3. **Replaced API keys** in code with placeholders:
   - `AndroidManifest.xml` → `YOUR_GOOGLE_MAPS_API_KEY`
   - `web/index.html.template` → `YOUR_GOOGLE_MAPS_API_KEY`

4. **Created security documentation**:
   - `SETUP_SECURITY.md` - Complete setup guide
   - `scripts/check-secrets.sh` - Script to check for exposed secrets

## 🚨 BEFORE You Push to GitHub

Run this command to check for any exposed secrets:
```bash
./scripts/check-secrets.sh
```

## 📋 Steps to Push Safely

1. **Check git status:**
   ```bash
   git status
   ```

2. **Verify sensitive files are NOT listed** (should be ignored):
   - google-services.json
   - GoogleService-Info.plist
   - .env
   - users.json

3. **Add your changes:**
   ```bash
   git add .
   ```

4. **Run security check:**
   ```bash
   ./scripts/check-secrets.sh
   ```

5. **If check passes, commit:**
   ```bash
   git commit -m "Initial commit - Binova waste management app"
   ```

6. **Push to GitHub:**
   ```bash
   git push origin main
   ```

## ⚠️ Files That Should NOT Be In Git

These files contain sensitive data and are already ignored:
- ❌ `android/app/google-services.json`
- ❌ `GoogleService-Info.plist`
- ❌ `.env`
- ❌ `users.json`
- ❌ `firebase-debug.log`

## ✅ Files That SHOULD Be In Git

These are templates/examples (safe):
- ✅ `android/app/google-services.json.example`
- ✅ `GoogleService-Info.plist.example`
- ✅ `.env.example`
- ✅ `.gitignore`
- ✅ `SETUP_SECURITY.md`
- ✅ All your source code files

## 🔄 For Other Developers

When someone clones your repo, they should:

1. Read `SETUP_SECURITY.md`
2. Create their own Firebase project
3. Download their own config files
4. Copy `.env.example` to `.env` and add their keys
5. Update `AndroidManifest.xml` with their API key

## 🆘 Emergency: If You Accidentally Committed Secrets

If you've already pushed API keys to GitHub:

1. **Immediately revoke/delete** the exposed API keys in Google Cloud Console
2. **Generate new keys**
3. **Use this to remove from history:**
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/sensitive/file" \
     --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

4. **Better yet, use BFG Repo Cleaner:**
   ```bash
   bfg --delete-files sensitive-file.json
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force
   ```

## 📞 Need Help?

Read the full guide: `SETUP_SECURITY.md`
