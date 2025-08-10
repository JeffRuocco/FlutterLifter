# 🚀 Deployment Guide for FlutterLifter

This document explains how to set up automatic deployment for the FlutterLifter app using GitHub Actions.

## 📋 Overview

The deployment workflow supports multiple platforms:
- **🌐 Web**: Automatic deployment to GitHub Pages
- **📱 Android**: APK and App Bundle builds
- **🖥️ Windows**: Executable builds

## 🔧 Setup Instructions

### 1. Enable GitHub Pages

1. Go to your repository settings
2. Navigate to **Pages** section
3. Set **Source** to "GitHub Actions"
4. The web app will be available at: `https://[username].github.io/FlutterLifter`

### 2. Configure Repository Secrets (Optional - for Android Signing)

For production Android releases, add these secrets in your repository settings:

| Secret Name | Description |
|-------------|-------------|
| `ANDROID_SIGNING_KEY` | Base64 encoded keystore file |
| `ANDROID_KEY_ALIAS` | Key alias name |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |

### 3. Workflow Triggers

The deployment workflow runs automatically on:

| Trigger | Platforms Built | Description |
|---------|----------------|-------------|
| **Push to main** | Web only | Quick web deployment |
| **Create release** | All platforms | Full production build |
| **Manual trigger** | Configurable | Choose specific platforms |

## 🎯 Deployment Scenarios

### Scenario 1: Development Deployment (Web Only)
```bash
# Simply push to main branch
git push origin main
```
- ✅ Builds and deploys web version to GitHub Pages
- ✅ Fast deployment (~3-5 minutes)
- ✅ Perfect for testing and demos

### Scenario 2: Production Release (All Platforms)
```bash
# Create and push a release tag
git tag v1.0.0
git push origin v1.0.0

# Or create a release through GitHub UI
```
- ✅ Builds web, Android, and Windows versions
- ✅ Deploys web to GitHub Pages
- ✅ Creates downloadable artifacts
- ✅ Attaches files to GitHub release

### Scenario 3: Manual Deployment
1. Go to **Actions** tab in your repository
2. Select **Deploy FlutterLifter** workflow
3. Click **Run workflow**
4. Choose your target platform(s)
5. Click **Run workflow**

## 📦 Build Artifacts

After successful builds, you can download:

### Web Deployment
- **Live Demo**: `https://[username].github.io/FlutterLifter`
- **Source**: Available in GitHub Pages

### Android Builds
- **APK Files**: `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`
- **App Bundle**: `app-release.aab` (for Google Play Store)
- **Download**: From GitHub Actions artifacts or release assets

### Windows Builds
- **Executable**: `FlutterLifter-Windows-x64.zip`
- **Contains**: All necessary files to run on Windows
- **Download**: From GitHub Actions artifacts or release assets

## 🔍 Monitoring Deployments

### GitHub Actions Dashboard
1. Go to **Actions** tab
2. View workflow runs and their status
3. Check build logs for any issues
4. Download artifacts from successful runs

### Deployment Summary
Each workflow run provides a summary with:
- ✅ Platform build status
- 🔗 Links to deployed applications
- 📊 Build information and metadata

## 🛠️ Troubleshooting

### Common Issues

#### 1. Web Deployment Fails
**Problem**: GitHub Pages not enabled
**Solution**: Enable GitHub Pages with "GitHub Actions" source

#### 2. Android Build Fails
**Problem**: Missing dependencies or signing issues
**Solution**: 
- Check Java version (requires Java 17)
- Verify Android SDK setup
- For signing issues, ensure secrets are configured

#### 3. Windows Build Fails
**Problem**: Windows-specific build issues
**Solution**: 
- Check Flutter Windows desktop support
- Verify Windows dependencies in `pubspec.yaml`

### Build Logs
- Navigate to **Actions** → **[Workflow Run]** → **[Job]** → **[Step]**
- Check console output for specific error messages
- Look for Flutter build errors or dependency issues

## 📋 Workflow Configuration

### Customization Options

You can modify `.github/workflows/deploy.yml` to:

1. **Change Flutter Version**:
   ```yaml
   env:
     FLUTTER_VERSION: '3.24.x'  # Update version here
   ```

2. **Modify Triggers**:
   ```yaml
   on:
     push:
       branches: [ "main", "develop" ]  # Add more branches
   ```

3. **Add More Platforms**:
   ```yaml
   # Add iOS, macOS, or Linux builds
   build-ios:
     runs-on: macos-latest
     # iOS build steps
   ```

4. **Custom Build Commands**:
   ```yaml
   - name: Custom build
     run: |
       flutter build web --dart-define=API_URL=${{ secrets.API_URL }}
   ```

## 🚀 Advanced Features

### Environment-Specific Builds
```yaml
# Different builds for different environments
- name: Build for production
  if: github.event_name == 'release'
  run: flutter build web --dart-define=ENV=production

- name: Build for staging
  if: github.ref == 'refs/heads/main'
  run: flutter build web --dart-define=ENV=staging
```

### Conditional Deployments
```yaml
# Only deploy on specific conditions
deploy-web:
  if: |
    github.event_name == 'push' && 
    contains(github.event.head_commit.message, '[deploy]')
```

### Slack/Discord Notifications
```yaml
- name: Notify deployment
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 📈 Performance Tips

1. **Enable Caching**: Already configured for Flutter dependencies
2. **Parallel Builds**: Jobs run in parallel when possible
3. **Artifact Management**: Automatic cleanup after 90 days
4. **Build Optimization**: Use `--release` flag for production builds

## 🔒 Security Best Practices

1. **Never commit secrets** to the repository
2. **Use GitHub Secrets** for sensitive data
3. **Limit workflow permissions** to necessary scopes
4. **Regular security updates** for actions and dependencies
5. **Review workflow changes** before merging

---

> **Note**: This deployment setup provides a professional CI/CD pipeline for your FlutterLifter app, supporting multiple platforms with automated testing and deployment capabilities.
