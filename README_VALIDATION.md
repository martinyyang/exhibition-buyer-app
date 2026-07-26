# Pre-Deployment Validation

**Status:** ✅ Validation scripts created and tested

---

## Overview

This project includes comprehensive pre-deployment validation to prevent GitHub push failures and ensure successful deployments.

## Files Created

### 1. `validate_before_push.sh` (Linux/Mac/Git Bash)
Bash script that runs all validation checks before pushing to GitHub.

### 2. `validate_before_push.bat` (Windows)
Windows batch script equivalent for Command Prompt/PowerShell users.

### 3. `PRE_DEPLOYMENT_CHECKLIST.md`
Comprehensive checklist covering:
- Automated checks (run by script)
- Manual pre-deployment checks
- Post-deployment verification
- Rollback procedures
- Troubleshooting guide

### 4. `VALIDATION_QUICK_START.md`
Quick reference guide with common commands and fixes.

---

## Usage

**Run before every push:**

```bash
# Linux/Mac/Git Bash
bash validate_before_push.sh

# Windows Command Prompt
validate_before_push.bat
```

---

## What Gets Validated

### ✅ Automated Checks (by script)

1. **Environment:**
   - Flutter installed and in PATH
   - Web support enabled (Chrome/Edge available)
   - Flutter version info

2. **Critical Files:**
   - `lib/main.dart` exists
   - `web/index.html` exists with correct base href
   - `web/manifest.json` exists
   - `.env` file exists with required variables
   - Key service files present

3. **Dependencies:**
   - `flutter clean` succeeds
   - `flutter pub get` succeeds

4. **Code Quality:**
   - `flutter analyze` runs
   - No critical errors (warnings/info are acceptable)

5. **Build:**
   - `flutter build web --release` succeeds
   - Build artifacts exist in `build/web/`
   - `main.dart.js` generated and size < 5MB
   - `index.html` generated
   - `assets` directory created

### 📋 Manual Checks (see PRE_DEPLOYMENT_CHECKLIST.md)

1. **Supabase Configuration:**
   - Project is live
   - RLS enabled on all tables
   - Authentication configured
   - Database schema exists

2. **GitHub Secrets:**
   - `SUPABASE_URL` set
   - `SUPABASE_ANON_KEY` set

3. **Code Quality:**
   - Tested locally
   - No hardcoded secrets
   - All features working

---

## Expected Results

### ✅ Success Output

```
=================================
Pre-Deployment Validation Script
=================================

[1/7] Checking environment...
✓ Flutter is installed
✓ Flutter web support is available

[2/7] Checking critical files...
✓ lib/main.dart exists
✓ web/index.html exists
✓ web/index.html has correct base href placeholder
✓ web/manifest.json exists
✓ .env file exists
✓ Environment variables are configured
✓ All key service files exist

[3/7] Cleaning and fetching dependencies...
✓ flutter clean completed
✓ flutter pub get completed

[4/7] Running flutter analyze...
✓ No critical errors found
⚠ 836 info/warning messages (acceptable)

[5/7] Building web release...
ℹ This may take a few minutes...
✓ flutter build web --release completed successfully

[6/7] Validating build artifacts...
✓ build/web directory exists
✓ main.dart.js generated
✓ main.dart.js size is acceptable
✓ index.html generated
✓ assets directory generated

[7/7] Validation Summary
=================================
✓ All critical checks passed!
✓ Build is ready for deployment
⚠ 836 info/warning messages found (review recommended)

Next steps:
  1. Review PRE_DEPLOYMENT_CHECKLIST.md for manual checks
  2. Commit and push changes
  3. GitHub Actions will deploy automatically
```

**Exit code:** 0 (success)

### ❌ Failure Output

If any critical check fails, the script will:
- Show error message with ✗ symbol
- Count total errors
- Exit with code 1
- Prevent you from pushing broken code

---

## Current Status

### Test Results

The validation script has been tested and confirmed working:

- ✅ Environment checks pass
- ✅ All critical files detected
- ✅ Dependencies install successfully
- ✅ Code analysis runs (0 errors, 836 info/warnings)
- ✅ Build completes successfully
- ✅ All build artifacts generated

**Note:** The 836 info/warning messages are acceptable:
- Most are `avoid_print` in test files (not production code)
- Some are deprecation warnings for `anonKey` (non-breaking)
- No critical errors that would prevent deployment

---

## Integration with Workflow

### Recommended Workflow

```bash
# 1. Make your changes
git add .

# 2. Run validation
bash validate_before_push.sh

# 3. If validation passes:
git commit -m "Your commit message"
git push origin master

# 4. GitHub Actions will automatically deploy
```

### Optional: Git Hook

To run validation automatically before every push:

```bash
# Create pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
echo "Running pre-deployment validation..."
bash validate_before_push.sh || exit 1
EOF

# Make it executable
chmod +x .git/hooks/pre-push
```

Now validation runs automatically when you `git push`.

---

## Troubleshooting

### Script Takes Too Long

The build step can take 2-5 minutes on first run. This is normal.

**Solutions:**
- Be patient on first run
- Subsequent runs are faster (cached)
- Press Ctrl+C to cancel if needed

### Script Fails on "flutter analyze"

If you get 836+ info/warnings but 0 errors, **this is acceptable**.

The script only fails on **errors**, not warnings/info.

### Build Fails

**Common causes:**
- Network issues during `flutter pub get`
- Syntax errors in Dart code
- Missing dependencies

**Fix:**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build web --release
```

### Script Won't Run on Windows

**Solutions:**
1. Use Git Bash (recommended)
2. Use `validate_before_push.bat` instead
3. Install WSL (Windows Subsystem for Linux)

---

## File Locations

```
exhibition-buyer-app/
├── validate_before_push.sh         # Bash validation script
├── validate_before_push.bat        # Windows validation script
├── PRE_DEPLOYMENT_CHECKLIST.md    # Full checklist
├── VALIDATION_QUICK_START.md      # Quick reference
└── README_VALIDATION.md            # This file
```

---

## Next Steps

1. ✅ **Run validation:** `bash validate_before_push.sh`
2. ✅ **Review checklist:** See `PRE_DEPLOYMENT_CHECKLIST.md`
3. ✅ **Manual checks:** Verify Supabase and GitHub Secrets
4. ✅ **Push to GitHub:** `git push origin master`
5. ✅ **Monitor deployment:** Check GitHub Actions tab

---

**Last Updated:** July 2026  
**Version:** 1.0  
**Status:** Production Ready ✅
