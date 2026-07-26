@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Pre-Release Validation Script for Exhibition Buyer App
:: 展会采购App预发布验证脚本 (Windows版本)

set PASSED=0
set FAILED=0
set WARNINGS=0

echo.
echo ========================================
echo Flutter展会采购App - 预发布验证
echo ========================================
echo.
echo 开始时间: %date% %time%
echo.

:: 1. Flutter Doctor Check
echo ========================================
echo 1. Flutter环境检查
echo ========================================
echo.
echo [检查] 运行 flutter doctor
echo.

flutter doctor >nul 2>&1
if %errorlevel% equ 0 (
    echo [32m✓ 通过: Flutter环境验证完成[0m
    set /a PASSED+=1
    flutter doctor -v
) else (
    echo [31m✗ 失败: Flutter环境存在问题[0m
    set /a FAILED+=1
    echo   💡 建议: 运行 'flutter doctor -v' 查看详细信息并修复问题
    flutter doctor -v
)

:: 2. Dependencies Check
echo.
echo ========================================
echo 2. 依赖完整性检查
echo ========================================
echo.
echo [检查] 运行 flutter pub get
echo.

flutter pub get >nul 2>&1
if %errorlevel% equ 0 (
    echo [32m✓ 通过: 依赖下载完成[0m
    set /a PASSED+=1
) else (
    echo [31m✗ 失败: 依赖下载失败[0m
    set /a FAILED+=1
    echo   💡 建议: 检查网络连接，或删除 pubspec.lock 后重试
    exit /b 1
)

:: 3. Static Analysis
echo.
echo ========================================
echo 3. 静态代码分析
echo ========================================
echo.
echo [检查] 运行 flutter analyze
echo.

flutter analyze > analyze_output.tmp 2>&1
findstr /C:"No issues found" analyze_output.tmp >nul
if %errorlevel% equ 0 (
    echo [32m✓ 通过: 代码分析无错误[0m
    set /a PASSED+=1
) else (
    findstr /C:"info •" analyze_output.tmp >nul
    if %errorlevel% equ 0 (
        echo [33m⚠ 警告: 代码分析发现提示信息[0m
        set /a WARNINGS+=1
        findstr /C:"info •" analyze_output.tmp | more +0
        echo   💡 建议: 虽然不影响构建，但建议修复这些提示
    ) else (
        echo [31m✗ 失败: 代码分析发现错误[0m
        set /a FAILED+=1
        type analyze_output.tmp
        echo   💡 建议: 修复所有错误后再继续
        del analyze_output.tmp
        exit /b 1
    )
)
del analyze_output.tmp

:: 4. Environment File Check
echo.
echo ========================================
echo 4. 配置文件验证
echo ========================================
echo.
echo [检查] 检查 .env 文件
echo.

if not exist ".env" (
    echo [31m✗ 失败: .env 文件不存在[0m
    set /a FAILED+=1
    echo   💡 建议: 复制 .env.example 为 .env 并填入实际配置
    exit /b 1
) else (
    echo [32m✓ 通过: .env 文件存在[0m
    set /a PASSED+=1
)

echo [检查] 验证 .env 必需配置项
echo.

set ENV_VALID=true

findstr /C:"SUPABASE_URL=https://" .env >nul
if %errorlevel% equ 0 (
    findstr /C:"SUPABASE_URL=https://your-project-ref" .env >nul
    if %errorlevel% neq 0 (
        echo [32m✓ 通过: SUPABASE_URL 已配置[0m
        set /a PASSED+=1
    ) else (
        echo [31m✗ 失败: SUPABASE_URL 未正确配置[0m
        set /a FAILED+=1
        echo   💡 建议: 在 .env 中设置正确的 SUPABASE_URL
        set ENV_VALID=false
    )
) else (
    echo [31m✗ 失败: SUPABASE_URL 未配置[0m
    set /a FAILED+=1
    echo   💡 建议: 在 .env 中设置正确的 SUPABASE_URL
    set ENV_VALID=false
)

findstr /C:"SUPABASE_ANON_KEY=" .env | findstr /V /C:"your-anon-key" >nul
if %errorlevel% equ 0 (
    echo [32m✓ 通过: SUPABASE_ANON_KEY 已配置[0m
    set /a PASSED+=1
) else (
    echo [31m✗ 失败: SUPABASE_ANON_KEY 未正确配置[0m
    set /a FAILED+=1
    echo   💡 建议: 在 .env 中设置正确的 SUPABASE_ANON_KEY
    set ENV_VALID=false
)

if "!ENV_VALID!"=="false" (
    exit /b 1
)

:: 5. Android Manifest Check
echo.
echo ========================================
echo 5. Android配置验证
echo ========================================
echo.
echo [检查] 检查网络权限
echo.

set MANIFEST=android\app\src\main\AndroidManifest.xml
findstr /C:"android.permission.INTERNET" "%MANIFEST%" >nul
if %errorlevel% equ 0 (
    echo [32m✓ 通过: AndroidManifest.xml 包含 INTERNET 权限[0m
    set /a PASSED+=1
) else (
    echo [31m✗ 失败: AndroidManifest.xml 缺少 INTERNET 权限[0m
    set /a FAILED+=1
    echo   💡 建议: 在 %MANIFEST% 中添加: ^<uses-permission android:name="android.permission.INTERNET"/^>
    exit /b 1
)

:: 6. Version Check
echo.
echo ========================================
echo 6. 版本号验证
echo ========================================
echo.
echo [检查] 检查 pubspec.yaml 版本格式
echo.

for /f "tokens=2" %%a in ('findstr /C:"version:" pubspec.yaml') do set VERSION=%%a
echo | set /p="版本号: %VERSION% "

echo %VERSION% | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*+[0-9][0-9]*$" >nul
if %errorlevel% equ 0 (
    echo [32m✓ 格式正确[0m
    set /a PASSED+=1
) else (
    echo [31m✗ 格式错误[0m
    set /a FAILED+=1
    echo   💡 建议: 使用格式: major.minor.patch+buildNumber (例如: 1.0.0+1)
    exit /b 1
)

:: 7. Assets Check
echo [检查] 验证 assets 配置
echo.

findstr /C:".env" pubspec.yaml >nul
if %errorlevel% equ 0 (
    echo [32m✓ 通过: .env 已在 pubspec.yaml assets 中配置[0m
    set /a PASSED+=1
) else (
    echo [31m✗ 失败: .env 未在 pubspec.yaml assets 中配置[0m
    set /a FAILED+=1
    echo   💡 建议: 在 pubspec.yaml 的 assets 列表中添加 .env
    exit /b 1
)

:: 8. Build Test
echo.
echo ========================================
echo 7. Release构建测试
echo ========================================
echo.
echo [检查] 执行 flutter build apk --release
echo.
echo 开始构建，这可能需要几分钟...
echo.

flutter build apk --release
if %errorlevel% equ 0 (
    echo.
    echo [32m✓ 通过: APK构建成功[0m
    set /a PASSED+=1
) else (
    echo.
    echo [31m✗ 失败: APK构建失败[0m
    set /a FAILED+=1
    echo   💡 建议: 检查上述构建日志中的错误信息
    exit /b 1
)

:: 9. APK Validation
echo.
echo ========================================
echo 8. APK文件验证
echo ========================================
echo.

set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if not exist "%APK_PATH%" (
    echo [31m✗ 失败: APK文件不存在: %APK_PATH%[0m
    set /a FAILED+=1
    exit /b 1
)

echo [检查] 检查APK文件大小
echo.

for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA
set /a APK_SIZE_MB=%APK_SIZE% / 1024 / 1024

if %APK_SIZE_MB% lss 10 (
    echo [31m✗ 失败: APK文件过小 ^(%APK_SIZE_MB%MB^)，可能构建不完整[0m
    set /a FAILED+=1
    exit /b 1
) else if %APK_SIZE_MB% gtr 100 (
    echo [33m⚠ 警告: APK文件较大 ^(%APK_SIZE_MB%MB^)[0m
    set /a WARNINGS+=1
    echo   💡 建议: 考虑优化资源文件或启用代码混淆
) else (
    echo [32m✓ 通过: APK文件大小合理: %APK_SIZE_MB%MB[0m
    set /a PASSED+=1
)

:: Final Report
echo.
echo ========================================
echo 验证报告
echo ========================================
echo.
echo [32m✓ 通过: %PASSED%[0m
echo [31m✗ 失败: %FAILED%[0m
echo [33m⚠ 警告: %WARNINGS%[0m
echo.
echo APK路径: %APK_PATH%
echo APK大小: %APK_SIZE_MB%MB
echo 版本号: %VERSION%
echo.

if %FAILED% equ 0 (
    echo ========================================
    echo [32m🎉 所有检查通过，可以进行真机测试！[0m
    echo ========================================
    exit /b 0
) else (
    echo ========================================
    echo [31m❌ 发现 %FAILED% 个问题，请修复后再测试[0m
    echo ========================================
    exit /b 1
)
