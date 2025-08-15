# GithubSource Macro Usage Guide

The `GithubSource` class provides powerful macro functionality for downloading and integrating raw GitHub files into your Haxe project.

## Features

- **Download raw files**: Get any file from GitHub repositories
- **Haxe source integration**: Automatically parse and integrate Haxe source files
- **Dependency resolution**: Automatically download missing imports from the same repository
- **Smart path resolution**: Tries multiple common source directory structures
- **Caching**: Avoids re-downloading the same files multiple times

## Basic Usage

### 1. Download Raw Files

```haxe
// Download any raw file from GitHub (at compile time)
class MyClass {
    public function new() {
        var content = yutautil.GithubSource.getRawFile("owner/repo", "path.to.file", "main");
        // content will be a compile-time string literal
    }
}
```

### 2. Download Haxe Source Files

```haxe
// Download and validate Haxe source files (at compile time)
class MyClass {
    public function new() {
        var tempPath = yutautil.GithubSource.getHaxeFile("owner/repo", "backend.MusicBeatState", "main");
        // tempPath will be a compile-time string literal pointing to the temp file
    }
}
```

### 3. Build Macro Integration

```haxe
// Use as a build macro to include external classes
@:build(yutautil.GithubSource.includeFromGithub("owner/repo", "backend.SomeClass"))
class MyClass {
    // This class will include all fields from the downloaded GitHub class
}
```

## Advanced Usage

### Custom Branch

```haxe
// Download from a specific branch
var content = yutautil.GithubSource.getRawFile("owner/repo", "path.to.file", "development");
```

### Path Resolution

The macro automatically tries multiple path patterns when a file isn't found:

1. Direct path: `path/to/file.hx`
2. With source prefix: `source/path/to/file.hx`
3. With src prefix: `src/path/to/file.hx`

### Import Resolution

When downloading Haxe files, the macro automatically:

1. Parses all import statements
2. Filters out standard library imports (haxe.*, sys.*, etc.)
3. Attempts to download missing custom imports from the same repository
4. Recursively processes imports in downloaded files

## Examples

### Example 1: Download a utility class

```haxe
class MyGame {
    public function new() {
        // Download a utility class from another project (at compile time)
        var utilPath = yutautil.GithubSource.getHaxeFile("someuser/haxe-utils", "utils.StringHelper");
        // utilPath will be null if download failed, or a string path if successful
    }
}
```

### Example 2: Extend a class from GitHub

```haxe
@:build(yutautil.GithubSource.includeFromGithub("psych-engine/psych-engine", "backend.BaseStage"))
class CustomStage extends BaseStage {
    // Inherits all functionality from the downloaded BaseStage class
    
    override public function create() {
        super.create();
        // Add custom functionality
    }
}
```

### Example 3: Download configuration files

```haxe
class ConfigLoader {
    public static function loadFromGitHub() {
        // This will be resolved at compile time to the actual JSON content
        var configJson = yutautil.GithubSource.getRawFile("myorg/configs", "game.config", "production");
        if (configJson != null) {
            var config = haxe.Json.parse(configJson);
            return config;
        }
        return null;
    }
}
```

## Cleanup

The macro creates temporary files during compilation. To clean them up:

```haxe
// Clean up all temporary files created by GithubSource (at compile time)
class MyClass {
    static function __init__() {
        yutautil.GithubSource.cleanup();
    }
}
```

## Error Handling

The macro includes comprehensive error handling:

- **Network errors**: Gracefully handles download failures
- **Invalid Haxe source**: Validates downloaded Haxe files before processing
- **Missing files**: Provides warnings for files that couldn't be found
- **Import resolution**: Continues processing even if some imports fail

## Best Practices

1. **Use specific branches**: For production code, use specific commit hashes or stable branch names
2. **Cache considerations**: The macro caches downloads per session, but doesn't persist across compilations
3. **Import filtering**: The macro only attempts to download custom imports, not standard library ones
4. **Path conventions**: Use consistent package-like naming for better path resolution

## Limitations

- Only works at compile time (macro context)
- Requires internet connection during compilation
- Temporary files are created and should be cleaned up
- No authentication support for private repositories
- Limited to raw file downloads (no Git operations)
