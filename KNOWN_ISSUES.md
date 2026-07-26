# Known Issues and Technical Debt

## Deprecation Warnings

### 1. Supabase `anonKey` Parameter
**Warning:** `The 'anonKey' parameter is deprecated. Use 'publishableKey' instead.`  
**Location:** Throughout codebase where Supabase client is initialized  
**Impact:** Low - Still works, will break in future Supabase versions  
**Fix Required:** Replace all `anonKey:` with `publishableKey:`  
**Priority:** Medium (plan to fix before next major Supabase update)

**Example:**
```dart
// Current (deprecated)
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseKey,
);

// Should be
await Supabase.initialize(
  url: supabaseUrl,
  publishableKey: supabaseKey,
);
```

---

## Code Quality (Info Level)

### 1. `avoid_print` in Integration Tests
**Location:** `integration_test/error_handling_test.dart`  
**Issue:** Using `print()` statements for debug output  
**Impact:** None (test files)  
**Fix:** Optional - can replace with `debugPrint()` or proper logging  
**Priority:** Low

### 2. `prefer_const_constructors`
**Location:** Multiple test files  
**Issue:** Non-const constructors where const could be used  
**Impact:** Minimal performance impact in tests  
**Fix:** Add `const` keyword where suggested  
**Priority:** Low

---

## Temporary Solutions to Review

### 1. RLS Temporarily Disabled During Development
**Status:** Re-enabled with proper policies  
**Note:** All RLS policies now correctly configured  
**Action:** None needed - already fixed

### 2. Service Role Key Exposed for RLS Fix
**Status:** Used once in `fix_rls_policies.js`  
**Security Risk:** High if not regenerated  
**Action Required:** **Regenerate service_role key after deployment**  
**How to:** Supabase Dashboard → Settings → API Keys → Generate new service_role key

### 3. Email Confirmation Disabled
**Status:** Permanent for MVP  
**Reason:** No SMTP server configured  
**Future:** Enable when email service is set up (SendGrid, AWS SES, etc.)  
**Priority:** Post-MVP

---

## CI/CD Issues to Monitor

### 1. Test Job Skipped
**Reason:** Chinese characters in directory path cause CI test failures  
**Current Workaround:** `needs: test` commented out in `build-web` job  
**Impact:** Web builds proceed without running tests  
**Fix:** Either fix path encoding or move repo to ASCII-only path  
**Priority:** Medium

### 2. Android Build Job Still Present
**Status:** Not needed for web-only deployment  
**Action:** Consider removing or disabling Android build job  
**Priority:** Low

---

## Web-Specific Limitations

### 1. No Camera Access
**Issue:** Web platform doesn't support `ImageSource.camera`  
**Workaround:** Falls back to file picker (correct behavior)  
**User Impact:** Users upload photos instead of taking them  
**Note:** This is expected on web, not a bug

### 2. File System Access Limited
**Issue:** Web can't use `dart:io` File class  
**Solution:** Using `XFile` with in-memory byte arrays  
**Status:** ✅ Implemented correctly

---

## Performance Considerations

### 1. Main.dart.js Size
**Current:** 2.9MB  
**Concern:** Large initial download for users  
**Optimization Options:**
- Code splitting (Flutter 3.16+ support)
- Tree shaking (already enabled in release mode)
- Lazy loading features
**Priority:** Post-MVP

### 2. No Service Worker
**Current:** No offline support  
**Impact:** App requires network connection  
**Future:** Implement PWA with service worker for offline caching  
**Priority:** Post-MVP

---

## Database Schema Considerations

### 1. No Migration System
**Current:** Manual schema changes in Supabase Dashboard  
**Risk:** Schema drift between environments  
**Future:** Consider using Supabase CLI migrations  
**Priority:** Before production launch

### 2. RLS Policies Not Version Controlled
**Current:** Policies created via script, not in repository  
**Risk:** Hard to track changes and rollback  
**Future:** Export policies to SQL migration files  
**Priority:** Medium

---

## Testing Gaps

### 1. No Unit Tests for Services
**Coverage:** Integration tests only  
**Missing:** Unit tests for PhotoService, AuthService, etc.  
**Priority:** Medium

### 2. No E2E Tests in CI
**Current:** E2E tests run manually  
**Future:** Add GitHub Actions job for Playwright/Selenium tests  
**Priority:** Low (manual testing sufficient for MVP)

---

## Documentation Debt

### 1. API Documentation Missing
**Missing:** Supabase table schema documentation  
**Missing:** RLS policy documentation  
**Priority:** Medium

### 2. Deployment Runbook Incomplete
**Current:** Basic deployment guide exists  
**Missing:** Rollback procedures, troubleshooting guide  
**Priority:** Medium

---

## Security Review Needed

### 1. Service Role Key Regeneration
**Action:** MUST regenerate after deployment  
**Why:** Key was exposed in fix_rls_policies.js  
**Priority:** 🔴 CRITICAL

### 2. Anon Key Exposed in Client
**Status:** This is normal and expected  
**Note:** Protected by RLS policies  
**Action:** None needed

---

**Last Updated:** 2026-07-26  
**Review Schedule:** After each major feature addition