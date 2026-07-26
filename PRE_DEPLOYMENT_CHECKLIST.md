# Pre-Deployment Checklist

This checklist ensures your Flutter web app is ready for production deployment to GitHub Pages.

---

## Automated Checks ✅

**Run the validation script before every push:**

```bash
bash validate_before_push.sh
```

The script automatically verifies:

- ✅ Flutter environment is configured
- ✅ Web support is enabled
- ✅ Critical files exist (main.dart, index.html, manifest.json)
- ✅ Base href is correctly configured
- ✅ Environment variables are set up
- ✅ Key service files are present
- ✅ `flutter clean && flutter pub get` succeeds
- ✅ `flutter analyze` passes with no errors
- ✅ `flutter build web --release` completes successfully
- ✅ Build artifacts exist in `build/web/`
- ✅ main.dart.js size is reasonable (< 5MB)

**If the script fails, fix the errors before proceeding.**

---

## Manual Pre-Deployment Checks 📋

### 1. Supabase Configuration

- [ ] **Supabase project is live** and accessible
- [ ] **RLS (Row Level Security) is enabled** on all tables
- [ ] **Authentication is configured** (email/password enabled)
- [ ] **Storage buckets are configured** with proper access policies
- [ ] **Database tables exist** with correct schema:
  - `users`
  - `teams`
  - `events`
  - `booths`
  - `products`
  - `comments`
  - `price_negotiations`

### 2. GitHub Secrets Configuration

Verify all secrets are set in **GitHub Repository Settings → Secrets and variables → Actions**:

- [ ] `SUPABASE_URL` - Your Supabase project URL
- [ ] `SUPABASE_ANON_KEY` - Your Supabase anonymous/public key

**How to check:**
1. Go to your GitHub repository
2. Navigate to: Settings → Secrets and variables → Actions
3. Verify both secrets are present

### 3. Environment Variables

- [ ] `.env` file exists locally with correct values
- [ ] `.env.example` is up to date (without actual secrets)
- [ ] **Fallback values in main.dart are up-to-date** (for production use)
- [ ] `.env` is in `.gitignore` (never commit secrets!)

### 4. Code Quality

- [ ] **All features tested locally** with `flutter run -d chrome`
- [ ] **No hardcoded secrets** in source code (search for "password", "secret", "token")
- [ ] **Error handling is in place** for network failures
- [ ] **Loading states** are implemented for async operations
- [ ] **Responsive design** works on mobile/tablet/desktop

### 5. GitHub Actions Workflow

- [ ] `.github/workflows/deploy.yml` exists and is configured
- [ ] Workflow has correct permissions:
  - `contents: write` (for pushing to gh-pages branch)
  - `pages: write` (for deploying to GitHub Pages)
  - `id-token: write` (for GitHub Pages authentication)
- [ ] Base href is set to repository name: `--base-href "/${{ github.event.repository.name }}/"`

### 6. Version Management

- [ ] `pubspec.yaml` version is bumped (e.g., `1.0.5+5` → `1.0.6+6`)
- [ ] Git commit messages are clear and descriptive
- [ ] All changes are committed (no uncommitted work)

---

## Push to GitHub 🚀

Once all checks pass:

```bash
# Ensure you're on the correct branch
git status

# Add and commit changes
git add .
git commit -m "Release v1.0.x - Description of changes"

# Push to GitHub
git push origin master
```

GitHub Actions will automatically:
1. Check out the code
2. Set up Flutter
3. Install dependencies
4. Build web release with environment variables
5. Deploy to GitHub Pages

---

## Post-Deployment Verification 🔍

After GitHub Actions completes (check Actions tab):

### 1. GitHub Pages Deployment

- [ ] GitHub Actions workflow completed successfully
- [ ] No errors in the workflow logs
- [ ] Deployment job shows "Deployed successfully"

**Where to check:**
- Repository → Actions → Latest workflow run

### 2. Live Site Testing

- [ ] **Site loads** at: `https://[username].github.io/[repo-name]/`
- [ ] **No console errors** (open browser DevTools)
- [ ] **Login page displays** correctly
- [ ] **Can create an account** (sign up flow works)
- [ ] **Can log in** with test credentials
- [ ] **Supabase connection works** (check Network tab for API calls)
- [ ] **Images load** correctly
- [ ] **Routing works** (navigate between pages)
- [ ] **Responsive design** works (test on mobile viewport)

### 3. Supabase Integration

- [ ] **Authentication works** end-to-end
- [ ] **Data fetching works** (check Supabase dashboard for activity)
- [ ] **Data writing works** (create test data)
- [ ] **RLS policies are enforced** (can't access other users' data)
- [ ] **Storage uploads work** (if using image uploads)

### 4. Performance Check

- [ ] **Page load time** is reasonable (< 5 seconds)
- [ ] **main.dart.js loads** without timeout
- [ ] **No memory leaks** (test by navigating around the app)
- [ ] **Service worker** caches assets (check Application tab in DevTools)

---

## Rollback Procedure 🔄

If deployment fails or has critical bugs:

1. **Revert the commit:**
   ```bash
   git revert HEAD
   git push origin master
   ```

2. **Or force push previous commit:**
   ```bash
   git reset --hard HEAD~1
   git push origin master --force
   ```

3. **Check GitHub Actions** to ensure rollback deploys

4. **Verify site** is back to previous working state

---

## Common Issues and Solutions 🔧

### Issue: Build fails with "SUPABASE_URL not found"

**Solution:**
- Verify GitHub Secrets are set correctly
- Check `.github/workflows/deploy.yml` has correct secret names
- Ensure secrets are passed to build command

### Issue: Site loads but shows white screen

**Solution:**
- Check browser console for errors
- Verify base href matches repository name
- Check that all assets are loading (Network tab)

### Issue: "Failed to load .env file"

**Solution:**
- This is expected in production
- Fallback values in `main.dart` should be used
- Or environment variables should be injected during build

### Issue: Authentication doesn't work

**Solution:**
- Verify Supabase project is accessible
- Check CORS settings in Supabase dashboard
- Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct

### Issue: 404 error on page refresh

**Solution:**
- GitHub Pages doesn't support client-side routing by default
- Add a 404.html that redirects to index.html
- Or use hash-based routing in Flutter

---

## Emergency Contacts 📞

- **Supabase Dashboard:** https://supabase.com/dashboard
- **GitHub Actions:** `https://github.com/[username]/[repo]/actions`
- **GitHub Pages Settings:** `https://github.com/[username]/[repo]/settings/pages`

---

## Notes

- **First deployment may take 5-10 minutes** for GitHub Pages to propagate
- **Subsequent deployments are faster** (2-3 minutes)
- **Always test locally first** before pushing to production
- **Keep backups** of working commits using git tags: `git tag v1.0.5`

---

**Last Updated:** July 2026  
**Version:** 1.0
