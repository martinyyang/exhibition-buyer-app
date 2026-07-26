# Quick Start: Pre-Deployment Validation

Run this **before every push** to GitHub to prevent deployment failures.

---

## One Command

### Linux/Mac/Git Bash:
```bash
bash validate_before_push.sh
```

### Windows Command Prompt:
```cmd
validate_before_push.bat
```

---

## What It Checks

✅ Flutter environment  
✅ Critical files exist  
✅ Dependencies install  
✅ Code analysis passes  
✅ Web build succeeds  
✅ Build artifacts valid  

---

## Expected Output

### Success ✅
```
=================================
Pre-Deployment Validation Script
=================================

[1/7] Checking environment...
✓ Flutter is installed
✓ Flutter web support is available

[2/7] Checking critical files...
✓ All critical files present

[3/7] Cleaning and fetching dependencies...
✓ flutter clean completed
✓ flutter pub get completed

[4/7] Running flutter analyze...
✓ No analysis errors found

[5/7] Building web release...
✓ flutter build web --release completed successfully

[6/7] Validating build artifacts...
✓ All build artifacts present

[7/7] Validation Summary
=================================
✓ All critical checks passed!
✓ Build is ready for deployment

Next steps:
  1. Review PRE_DEPLOYMENT_CHECKLIST.md for manual checks
  2. Commit and push changes
  3. GitHub Actions will deploy automatically
```

**You can now safely push to GitHub!**

---

### Failure ❌
```
[5/7] Building web release...
✗ Build failed

[7/7] Validation Summary
=================================
✗ 1 critical error(s) found

❌ Build is NOT ready for deployment
Please fix the errors above before pushing
```

**DO NOT PUSH. Fix errors first.**

---

## Common Fixes

### "Flutter is not installed"
```bash
# Install Flutter: https://flutter.dev/docs/get-started/install
flutter doctor
```

### "web/index.html is missing"
```bash
# Recreate web directory
flutter create . --platforms web
```

### "Build failed"
```bash
# See detailed error
flutter build web --release

# Common fixes:
flutter clean
flutter pub get
flutter pub upgrade
```

### "Environment variables not configured"
```bash
# Copy example and fill in values
cp .env.example .env
# Edit .env with your Supabase credentials
```

---

## Manual Checklist

After the script passes, verify:

1. **GitHub Secrets are set:**
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

2. **Supabase is configured:**
   - RLS enabled on all tables
   - Authentication enabled
   - Database schema exists

3. **Code quality:**
   - Tested locally: `flutter run -d chrome`
   - No hardcoded secrets
   - All features working

See full checklist: **PRE_DEPLOYMENT_CHECKLIST.md**

---

## Troubleshooting

### Script hangs on "Building web release"
- This can take 2-5 minutes on first build
- Press Ctrl+C to cancel
- Run manually: `flutter build web --release`

### Script passes but GitHub deployment fails
- Check GitHub Actions logs
- Verify GitHub Secrets are set correctly
- Ensure `.github/workflows/deploy.yml` exists

### Can't run bash script on Windows
- Use Git Bash (recommended)
- Or use `validate_before_push.bat` instead
- Or install WSL

---

## Integration with Git

### Option 1: Manual (Recommended)
```bash
# Before every push:
bash validate_before_push.sh
git push origin master
```

### Option 2: Pre-push Hook (Advanced)
```bash
# Add to .git/hooks/pre-push
#!/bin/bash
bash validate_before_push.sh || exit 1
```

---

**Last Updated:** July 2026
