@echo off
REM Integration Test Runner Script for Windows
REM 用于本地和CI环境运行集成测试

setlocal enabledelayedexpansion

echo ========================================
echo Flutter Integration Tests
echo ========================================
echo.

REM 检查Flutter环境
echo 检查Flutter环境...
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter未安装或未在PATH中
    exit /b 1
)

flutter --version
echo.

REM 检查.env文件
echo 检查环境配置...
if not exist .env (
    echo [WARNING] .env文件不存在
    if exist .env.example (
        echo 请复制.env.example为.env并填入正确的配置：
        echo   copy .env.example .env
    )
    exit /b 1
)

REM 验证环境变量
findstr /C:"SUPABASE_URL=https://" .env >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] .env文件中SUPABASE_URL配置无效
    exit /b 1
)

findstr /C:"SUPABASE_ANON_KEY=" .env >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] .env文件中SUPABASE_ANON_KEY配置无效
    exit /b 1
)

echo [OK] 环境配置正常
echo.

REM 清理构建缓存
echo 清理构建缓存...
flutter clean
flutter pub get
echo.

REM 运行测试
set TEST_MODE=%1
if "%TEST_MODE%"=="" set TEST_MODE=all

if "%TEST_MODE%"=="startup" (
    echo 运行启动测试...
    flutter test integration_test/startup_test.dart
    goto :check_result
)

if "%TEST_MODE%"=="env" (
    echo 运行环境变量测试...
    flutter test integration_test/env_loading_test.dart
    goto :check_result
)

if "%TEST_MODE%"=="error" (
    echo 运行错误处理测试...
    flutter test integration_test/error_handling_test.dart
    goto :check_result
)

if "%TEST_MODE%"=="e2e" (
    echo 运行完整E2E测试...
    flutter test integration_test/app_test.dart
    goto :check_result
)

if "%TEST_MODE%"=="quick" (
    echo 运行快速测试（startup + env + error）...
    echo.
    echo 1/3 启动测试...
    flutter test integration_test/startup_test.dart
    if %ERRORLEVEL% NEQ 0 goto :test_failed
    echo.
    echo 2/3 环境变量测试...
    flutter test integration_test/env_loading_test.dart
    if %ERRORLEVEL% NEQ 0 goto :test_failed
    echo.
    echo 3/3 错误处理测试...
    flutter test integration_test/error_handling_test.dart
    goto :check_result
)

if "%TEST_MODE%"=="all" (
    echo 运行所有集成测试...
    echo.
    echo 1/4 启动测试...
    flutter test integration_test/startup_test.dart
    if %ERRORLEVEL% NEQ 0 goto :test_failed
    echo.
    echo 2/4 环境变量测试...
    flutter test integration_test/env_loading_test.dart
    if %ERRORLEVEL% NEQ 0 goto :test_failed
    echo.
    echo 3/4 错误处理测试...
    flutter test integration_test/error_handling_test.dart
    if %ERRORLEVEL% NEQ 0 goto :test_failed
    echo.
    echo 4/4 完整E2E测试...
    flutter test integration_test/app_test.dart
    goto :check_result
)

echo [ERROR] 无效的测试模式: %TEST_MODE%
echo.
echo 用法: %0 [mode]
echo 模式选项：
echo   startup  - 仅运行启动测试
echo   env      - 仅运行环境变量测试
echo   error    - 仅运行错误处理测试
echo   e2e      - 仅运行完整E2E测试
echo   quick    - 运行快速测试（不含E2E，^< 1分钟）
echo   all      - 运行所有测试（默认）
exit /b 1

:check_result
if %ERRORLEVEL% NEQ 0 goto :test_failed
echo.
echo ========================================
echo [OK] 所有测试通过
echo ========================================
exit /b 0

:test_failed
echo.
echo ========================================
echo [ERROR] 测试失败
echo ========================================
exit /b 1
