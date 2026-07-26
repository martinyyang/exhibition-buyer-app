@echo off
REM Pre-Deployment Validation Script for Flutter Web (Windows)
REM This script validates all aspects of the web build before pushing to GitHub

setlocal enabledelayedexpansion

echo =================================
echo Pre-Deployment Validation Script
echo =================================
echo.

set ERRORS=0
set WARNINGS=0

REM ==========================================
REM Step 1: Environment Check
REM ==========================================
echo [1/7] Checking environment...

where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)
echo [OK] Flutter is installed

flutter devices 2>&1 | findstr /i "chrome edge web" >nul
if %errorlevel% equ 0 (
    echo [OK] Flutter web support is available
) else (
    echo [WARNING] No web browsers detected
    set /a WARNINGS+=1
)

echo.

REM ==========================================
REM Step 2: Critical Files Check
REM ==========================================
echo [2/7] Checking critical files...

if exist "lib\main.dart" (
    echo [OK] lib\main.dart exists
) else (
    echo [ERROR] lib\main.dart is missing
    set /a ERRORS+=1
)

if exist "web\index.html" (
    echo [OK] web\index.html exists
    findstr /C:"<base href=\"/\">" web\index.html >nul
    if !errorlevel! equ 0 (
        echo [OK] web\index.html has correct base href placeholder
    ) else (
        echo [WARNING] web\index.html base href may not be correct
        set /a WARNINGS+=1
    )
) else (
    echo [ERROR] web\index.html is missing
    set /a ERRORS+=1
)

if exist "web\manifest.json" (
    echo [OK] web\manifest.json exists
) else (
    echo [WARNING] web\manifest.json is missing
    set /a WARNINGS+=1
)

if exist ".env" (
    echo [OK] .env file exists
    findstr "SUPABASE_URL" .env >nul && findstr "SUPABASE_ANON_KEY" .env >nul
    if !errorlevel! equ 0 (
        echo [OK] Environment variables are configured
    ) else (
        echo [WARNING] Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env
        set /a WARNINGS+=1
    )
) else (
    echo [WARNING] .env file missing
    set /a WARNINGS+=1
)

echo.

REM ==========================================
REM Step 3: Clean and Get Dependencies
REM ==========================================
echo [3/7] Cleaning and fetching dependencies...

flutter clean >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] flutter clean completed
) else (
    echo [ERROR] flutter clean failed
    set /a ERRORS+=1
)

flutter pub get >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] flutter pub get completed
) else (
    echo [ERROR] flutter pub get failed
    set /a ERRORS+=1
)

echo.

REM ==========================================
REM Step 4: Code Analysis
REM ==========================================
echo [4/7] Running flutter analyze...

flutter analyze >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] No analysis errors found
) else (
    echo [WARNING] Analysis found issues (review recommended)
    set /a WARNINGS+=1
)

echo.

REM ==========================================
REM Step 5: Build Web Release
REM ==========================================
echo [5/7] Building web release...
echo [INFO] This may take a few minutes...

flutter build web --release >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] flutter build web --release completed successfully
) else (
    echo [ERROR] Build failed
    echo Run 'flutter build web --release' manually to see errors
    set /a ERRORS+=1
    exit /b 1
)

echo.

REM ==========================================
REM Step 6: Build Artifacts Validation
REM ==========================================
echo [6/7] Validating build artifacts...

if exist "build\web" (
    echo [OK] build\web directory exists
) else (
    echo [ERROR] build\web directory not found
    set /a ERRORS+=1
    exit /b 1
)

if exist "build\web\main.dart.js" (
    echo [OK] main.dart.js generated
) else (
    echo [ERROR] main.dart.js not found in build output
    set /a ERRORS+=1
)

if exist "build\web\index.html" (
    echo [OK] index.html generated
) else (
    echo [ERROR] index.html not found in build output
    set /a ERRORS+=1
)

if exist "build\web\assets" (
    echo [OK] assets directory generated
) else (
    echo [WARNING] assets directory not found
    set /a WARNINGS+=1
)

echo.

REM ==========================================
REM Step 7: Summary
REM ==========================================
echo [7/7] Validation Summary
echo =================================

if !ERRORS! equ 0 (
    echo [SUCCESS] All critical checks passed!
    echo [SUCCESS] Build is ready for deployment

    if !WARNINGS! gtr 0 (
        echo [WARNING] !WARNINGS! warning(s) found (review recommended)
    )

    echo.
    echo Next steps:
    echo   1. Review PRE_DEPLOYMENT_CHECKLIST.md for manual checks
    echo   2. Commit and push changes
    echo   3. GitHub Actions will deploy automatically
    echo.
    exit /b 0
) else (
    echo [ERROR] !ERRORS! critical error(s) found

    if !WARNINGS! gtr 0 (
        echo [WARNING] !WARNINGS! warning(s) found
    )

    echo.
    echo [FAILED] Build is NOT ready for deployment
    echo Please fix the errors above before pushing
    echo.
    exit /b 1
)
