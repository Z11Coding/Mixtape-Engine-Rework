# Version Tracking System

## Overview

The Mixtape Engine includes a comprehensive version tracking system that automatically manages version information and build numbers. This system provides both compile-time and runtime access to version data.

## Files

### Core Files
- `source/macros/VersionMacro.hx` - The macro that generates version constants at compile time
- `source/backend/Version.hx` - Runtime access class for version information
- `gitVersion.txt` - Primary version source (format: `version:beta`)
- `build.txt` - Auto-generated build tracking file (auto-increments)

### Version Sources
1. **Primary**: `gitVersion.txt` (format: `4.8.0:beta11`)
2. **Fallback**: `Project.xml` version attribute
3. **Build Tracking**: `build.txt` (auto-generated and auto-incremented)

## Usage

### Runtime Access
```haxe
import backend.Version;

// Basic version information
var version = Version.ENGINE_VERSION;        // "4.8.0"
var beta = Version.ENGINE_BETA;             // "beta11"
var buildNum = Version.BUILD_NUMBER;        // 1, 2, 3, etc.
var buildDate = Version.BUILD_DATE;         // "2024-12-28 15:30:45"

// Formatted strings
var versionWithBuild = Version.getVersionString(true);    // "4.8.0:beta11 [Build 5]"
var versionNoBuild = Version.getVersionString(false);     // "4.8.0:beta11"
var fullInfo = Version.getFullVersionInfo();              // "4.8.0:beta11 [Build 5] (2024-12-28 15:30:45)"
```

### UI Integration
```haxe
// Title screen
titleText = "Friday Night Funkin': Mixtape Engine " + Version.getVersionString(true);

// Credits/About screen
creditsText = "Built on " + Version.BUILD_DATE + " (Build " + Version.BUILD_NUMBER + ")";

// Debug information
debugInfo = "Engine: " + Version.getFullVersionInfo();
```

## Build System Integration

### Automatic Build Incrementing
- Each compilation automatically increments the build number
- Build information is stored in `build.txt`
- Build date is captured at compile time

### Version File Format
**gitVersion.txt**:
```
4.8.0:beta11
```

**build.txt** (auto-generated):
```
BUILD_NUMBER=5
BUILD_DATE=2024-12-28 15:30:45
LAST_COMPILE=1703787045000
```

## Features

### Compile-Time Generation
- All version constants are generated at compile time for efficiency
- No runtime file reading overhead
- Constants are inlined for optimal performance

### Multi-Source Support
- Reads from `gitVersion.txt` first
- Falls back to `Project.xml` version if needed
- Handles missing files gracefully

### Build Tracking
- Automatic build number incrementing
- Timestamp tracking for each build
- Persistent build history

### Error Handling
- Graceful fallbacks for missing files
- Compile-time warnings for version read failures
- Default values to prevent build failures

## Implementation Details

### Macro System
The `VersionMacro.build()` function:
1. Reads version from `gitVersion.txt` or `Project.xml`
2. Increments build number in `build.txt`
3. Generates static constants on the `Version` class
4. Provides helper functions for formatted output

### Generated Constants
The macro generates these static constants:
- `ENGINE_VERSION: String` - Main version number
- `ENGINE_BETA: String` - Beta/suffix version
- `BUILD_NUMBER: Int` - Auto-incrementing build count
- `BUILD_DATE: String` - Compilation timestamp

### Generated Functions
- `getVersionString(includeBuild: Bool): String` - Formatted version
- `getFullVersionInfo(): String` - Complete version with date

## Integration Points

### Mixtape Settings
Version information is displayed in the Mixtape Settings menu under "VERSION INFO":
- Shows current engine version with build number
- Indicates version source (gitVersion.txt vs Project.xml)

### Debug/Development
- Available in command prompt system
- Integrated with crash reporting
- Useful for development builds and testing

## Best Practices

### Version Updates
1. Update `gitVersion.txt` for version changes
2. Let the build system handle build numbers automatically
3. Use `getVersionString(true)` for user-visible version info

### Performance
- All version data is compile-time generated
- No runtime file I/O required
- Constants are inlined by compiler

### Git Integration
- Consider ignoring `build.txt` if you don't want build numbers in version control
- Or commit it to track build progression across team members

## Examples

See `source/examples/VersionExample.hx` for complete usage examples and demonstrations of all available version functions.
