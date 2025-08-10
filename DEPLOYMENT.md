# 🚀 FlutterLifter Deployment - Quick Reference

## Deployment URLs
- **Live Web App**: https://jeffruocco.github.io/FlutterLifter/
- **Repository**: https://github.com/jeffruocco/FlutterLifter
- **Actions**: https://github.com/jeffruocco/FlutterLifter/actions

## Quick Deploy Commands

### 1. Web Deployment (GitHub Pages)
```bash
# Push to main branch for immediate web deployment
git add .
git commit -m "Deploy to web"
git push origin main
```
**Result**: Web app deployed to GitHub Pages in ~3-5 minutes

### 2. Full Release (All Platforms)
```bash
# Create a new release for all platforms
git tag v1.0.0
git push origin v1.0.0
```
**Result**: Web + Android + Windows builds available

### 3. Manual Deployment
1. Go to **GitHub** → **Actions** → **Deploy FlutterLifter**
2. Click **Run workflow**
3. Select platform(s): web, android, windows, or all
4. Click **Run workflow**

## Build Status Badge
Add this to your README.md:
```markdown
[![Deploy](https://github.com/jeffruocco/FlutterLifter/actions/workflows/deploy.yml/badge.svg)](https://github.com/jeffruocco/FlutterLifter/actions/workflows/deploy.yml)
```

## Troubleshooting

### ❌ Web deployment fails
- Check if GitHub Pages is enabled with "GitHub Actions" source
- Verify base-href in build command matches repository name

### ❌ Android build fails  
- Ensure Java 17 is configured in workflow
- Check android/app/build.gradle for proper configuration

### ❌ Windows build fails
- Verify Flutter Windows desktop support is enabled
- Check for Windows-specific dependencies

## File Structure
```
.github/
└── workflows/
    ├── dart.yml          # CI/CD testing
    └── deploy.yml        # Deployment workflow

scripts/
├── setup-deployment.sh  # Unix setup script
└── setup-deployment.bat # Windows setup script

docs/
└── deployment-guide.md  # Detailed deployment guide
```

## Workflow Triggers
| Event | Platforms | Use Case |
|-------|-----------|----------|
| Push to main | Web only | Quick development deployment |
| Create release | All | Production release |
| Manual trigger | Configurable | Testing specific platforms |

## Environment Variables
```yaml
FLUTTER_VERSION: '3.24.x'  # Flutter version to use
```

## Secret Variables (Optional - for Android signing)
```
ANDROID_SIGNING_KEY       # Base64 encoded keystore
ANDROID_KEY_ALIAS         # Keystore alias
ANDROID_KEYSTORE_PASSWORD # Keystore password  
ANDROID_KEY_PASSWORD      # Key password
```

## Build Artifacts
After successful builds:
- **Web**: Automatically deployed to GitHub Pages
- **Android**: Download APK from Actions artifacts or release assets
- **Windows**: Download ZIP from Actions artifacts or release assets

---
> 💡 **Tip**: Use semantic versioning for releases (v1.0.0, v1.1.0, etc.) to trigger full platform builds
