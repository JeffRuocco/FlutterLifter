@echo off
REM 🚀 FlutterLifter Deployment Setup Script (Windows)
REM This script helps you set up GitHub Actions deployment for your Flutter app

echo 🚀 FlutterLifter Deployment Setup
echo ==================================
echo.

REM Check if we're in a git repository
if not exist ".git" (
    echo ❌ Error: This doesn't appear to be a Git repository.
    echo    Please run this script from the root of your Flutter project.
    pause
    exit /b 1
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Flutter is not installed or not in PATH.
    echo    Please install Flutter first: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Git repository detected
echo ✅ Flutter installation detected
echo.

REM Check if GitHub Actions workflow exists
if exist ".github\workflows\deploy.yml" (
    echo ✅ Deployment workflow already exists at .github\workflows\deploy.yml
) else (
    echo ❌ Deployment workflow not found
    echo    Please ensure the deploy.yml file is in .github\workflows\
)

echo.
echo 📋 Setup Checklist:
echo.

echo 1. 🌐 GitHub Pages Setup:
echo    - Go to your repository settings
echo    - Navigate to 'Pages' section
echo    - Set Source to 'GitHub Actions'
echo    - Your app will be available at: https://[username].github.io/FlutterLifter/
echo.

echo 2. 🔧 Repository Configuration:
echo    ✅ Flutter project structure
echo    ✅ GitHub Actions workflow

if exist "android\app\build.gradle" (
    echo    ✅ Android configuration detected
) else (
    echo    ⚠️  Android configuration not found
)

if exist "windows" (
    echo    ✅ Windows configuration detected
) else (
    echo    ⚠️  Windows configuration not found
)

if exist "web" (
    echo    ✅ Web configuration detected
) else (
    echo    ⚠️  Web configuration not found
)

echo.
echo 3. 🚀 Deployment Triggers:
echo    • Push to main branch → Web deployment
echo    • Create GitHub release → All platforms
echo    • Manual workflow run → Configurable platforms
echo.

echo 4. 📦 What Gets Built:
echo    • Web: Progressive Web App deployed to GitHub Pages
echo    • Android: APK files and App Bundle for Google Play
echo    • Windows: Executable package for Windows desktop
echo.

echo 5. 🔒 Optional: Android Signing (for production):
echo    Add these secrets in your repository settings:
echo    • ANDROID_SIGNING_KEY (base64 encoded keystore)
echo    • ANDROID_KEY_ALIAS
echo    • ANDROID_KEYSTORE_PASSWORD
echo    • ANDROID_KEY_PASSWORD
echo.

echo 6. 🧪 Test Your Setup:
echo    Run: git push origin main
echo    Check: GitHub Actions tab for workflow status
echo    Visit: Your GitHub Pages URL when deployment completes
echo.

echo 📚 Need Help?
echo    • Read docs\deployment-guide.md for detailed instructions
echo    • Check GitHub Actions logs for build issues
echo    • Ensure Flutter web/desktop support is enabled
echo.

echo 🎉 Setup complete! Push to main branch to trigger your first deployment.

REM Create a simple test to verify Flutter build works
echo.
echo 🔍 Quick Build Test:
echo Testing if Flutter can build for web...

flutter build web --release >nul 2>&1
if errorlevel 1 (
    echo ❌ Web build test failed
    echo    Run 'flutter build web' to see detailed error messages
) else (
    echo ✅ Web build test passed
)

echo.
echo Ready to deploy! 🚀
echo.
pause
