# GitHub Secrets Setup Guide

## ❌ Current Issue

CI/CD is failing because GitHub Secrets are not configured. The workflow needs:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 🔧 How to Fix

### Step 1: Get Your Supabase Credentials

From your `.env` file, copy the values for:
```
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here
```

### Step 2: Add Secrets to GitHub

1. Go to your repository: https://github.com/martinyyang/exhibition-buyer-app
2. Click **Settings** (top right)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add the first secret:
   - Name: `SUPABASE_URL`
   - Value: (paste your Supabase URL)
   - Click **Add secret**
6. Add the second secret:
   - Name: `SUPABASE_ANON_KEY`
   - Value: (paste your Supabase anon key)
   - Click **Add secret**

### Step 3: Verify Secrets Are Added

Run this command:
```bash
gh secret list
```

You should see:
```
SUPABASE_ANON_KEY  Updated YYYY-MM-DD
SUPABASE_URL       Updated YYYY-MM-DD
```

### Step 4: Re-run CI

Once secrets are added, re-run the failed workflow:
```bash
gh run rerun $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId') --failed
```

Or push a new commit to trigger CI again.

## 🔒 Security Note

Never commit `.env` files or secrets to Git. The CI workflow creates `.env` dynamically from GitHub Secrets.

## ✅ After Setup

Once secrets are configured:
- CI will build APK automatically on every push
- Web build will deploy to GitHub Pages on master branch
- No more "secrets not configured" errors
