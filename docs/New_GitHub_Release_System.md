# New GitHub Release Update System

## Overview
The Mixtape Engine now features a comprehensive GitHub-based update system that replaces the old version-checking system. This new system provides users with full control over which releases to install and gives developers powerful tools for creating and managing releases directly from the engine.

## Features

### For Users

#### Release Selection (F6 or Ctrl+U)
- **Access**: Available from Main Menu with `F6` or `Ctrl+U`
- **Functionality**:
  - Displays all available GitHub releases in a scrollable list
  - Shows release information including version, date, changelog, and file sizes
  - Allows selection of any release to install (not just the latest)
  - Automatically detects platform-compatible files
  - Provides detailed release notes and asset information

#### Automatic Update Checking
- When the engine detects a newer version is available, it now redirects to the Release Selection screen instead of forcing an immediate update
- Users can choose to update or continue with their current version
- No more forced updates - complete user control

### For Developers (Live Reload Mode Only)

#### Developer Release Tool (F5 in Live Reload)
- **Access**: Only available when engine is launched with `-livereload` flag
- **Authentication**: Secure GitHub token storage with XOR encryption
- **Features**:
  - GitHub authentication with personal access tokens
  - Repository access verification
  - User information display
  - Release creation capability
  - Asset packaging and upload tools

## Usage Guide

### Installing Updates (Users)

1. **Automatic Prompt**: When a new version is detected, you'll be taken to the Release Selection screen
2. **Manual Access**: Press `F6` or `Ctrl+U` from the Main Menu
3. **Browse Releases**: Use UP/DOWN arrows to navigate through available releases
4. **View Details**: Each release shows:
   - Version number and stability (Stable/Pre-release)
   - Release date
   - Changelog/description
   - Available download files and sizes
5. **Install**: Press ENTER to install the selected release
6. **Cancel**: Press ESCAPE to return to the main menu

### Creating Releases (Developers)

1. **Launch in Live Reload**: Start engine with `-livereload` flag
2. **Access Dev Tools**: Press `F5` from Main Menu
3. **Authenticate**:
   - Select "Authenticate with GitHub"
   - Enter your GitHub Personal Access Token
   - Token requires `repo` scope for full functionality
4. **Create Release**:
   - Select "Create Release"
   - Fill in version, title, description
   - Mark as pre-release if needed
5. **Upload Assets**:
   - Select "Package and Upload"
   - Engine will create zip file excluding mods folder
   - Upload directly to the created release

## Technical Details

### File Structure
```
source/backend/GitHubAPI.hx          - GitHub API integration
source/states/ReleaseSelectionState.hx - Release selection UI
source/states/DevReleaseToolState.hx   - Developer tools
source/substates/TokenInputSubstate.hx - Token input interface
source/states/UpdateState.hx           - Modified update downloader
```

### GitHub API Integration
- **Authentication**: Personal Access Tokens with secure local storage
- **Release Management**: Full CRUD operations for releases
- **Asset Handling**: Upload and download of release assets
- **Repository Access**: Verification of push permissions
- **Error Handling**: Comprehensive error handling and user feedback

### Security Features
- Token encryption using XOR cipher for basic protection
- No tokens stored in plain text
- Token validation before storage
- Repository permission verification
- Secure cleanup on authentication clear

### Platform Support
- Automatic platform detection (Windows, macOS, Linux, Android)
- Platform-specific asset filtering
- Cross-platform compatible packaging
- Universal download support

## API Reference

### GitHubAPI Class Methods

#### Public Release Access
- `getPublicReleases(callback, errorCallback)` - Fetch all public releases
- `getPlatformAssets(release)` - Filter assets for current platform
- `formatFileSize(bytes)` - Human-readable file size formatting
- `formatDate(dateString)` - User-friendly date formatting

#### Authentication
- `setAuthToken(token)` - Set and save authentication token
- `loadAuthToken()` - Load saved token from disk
- `clearAuth()` - Clear authentication and delete saved token
- `validateToken(token, callback)` - Verify token validity
- `isAuthenticated()` - Check current authentication status

#### Authenticated Operations
- `getUserInfo(callback, errorCallback)` - Get authenticated user information
- `hasRepoAccess(callback, errorCallback)` - Verify repository permissions
- `createRelease(releaseData, callback, errorCallback)` - Create new release
- `uploadReleaseAsset(releaseId, filePath, fileName, contentType, progressCallback, callback, errorCallback)` - Upload files to release

## Configuration

### Client Preferences
- `ClientPrefs.data.checkForUpdates` - Enable/disable automatic update checking
- Engine respects existing update preferences

### Build Flags
No additional build flags required - works with existing engine configuration.

## Migration from Old System

### What Changed
- `OutdatedState` replaced with `ReleaseSelectionState`
- Version-based updates replaced with user-selected releases
- Added developer tools for release management
- Enhanced update UI with detailed release information

### Backwards Compatibility
- Existing update preferences are respected
- Version checking still works but redirects to new system
- No breaking changes to existing workflows

## Troubleshooting

### Common Issues

#### "Not Authenticated" Error
- Ensure you have a valid GitHub Personal Access Token
- Verify token has `repo` scope
- Check internet connection

#### "No Repository Access" Warning
- Token user must have push access to the repository
- Contact repository maintainer for access
- Verify token permissions

#### "No Compatible Files" Error
- Release may not have files for your platform
- Check release assets manually on GitHub
- Contact developer for platform-specific builds

#### Download Failures
- Check internet connection
- Verify GitHub API rate limits
- Try again after a few minutes

### Debug Information
- Enable debug logging in engine
- Check console output for detailed error messages
- Review GitHub API responses in network tools

## Best Practices

### For Users
- Always backup your mods before updating
- Read release notes before installing
- Use stable releases for important projects
- Test pre-releases in separate environments

### For Developers
- Always test releases before publishing
- Include comprehensive changelogs
- Tag versions consistently
- Exclude unnecessary files from releases
- Test on multiple platforms before release

## Security Considerations

### Token Management
- Keep Personal Access Tokens secure
- Use tokens with minimal required permissions
- Rotate tokens regularly
- Never share tokens publicly

### Release Verification
- Verify release authenticity
- Check checksums when available
- Only download from official repository
- Be cautious with pre-release versions

## Future Enhancements

### Planned Features
- Automatic checksumming for release verification
- Incremental updates for smaller downloads
- Release signing and verification
- Advanced filtering and search options
- Release scheduling and automation
- Multi-repository support
- Rollback functionality
- Update history and changelogs

### Developer Tools Expansion
- Automated building and packaging
- CI/CD integration
- Release template system
- Bulk asset management
- Release analytics and statistics

This new system provides a much more flexible and powerful update mechanism while maintaining ease of use for end users and providing powerful tools for developers.
