package examples;

/**
 * Example demonstrating how to use the GithubSource macro
 */
class GithubSourceExample {
    
    public static function main() {
        // Example 1: Download a raw file (like a JSON config) at compile time
        var configContent = yutautil.GithubSource.getRawFile("owner/repo", "config.settings", "main");
        if (configContent != null) {
            trace("Downloaded config: " + configContent.substring(0, 100) + "...");
        }
        
        // Example 2: Download a Haxe source file at compile time
        var haxeFilePath = yutautil.GithubSource.getHaxeFile("psych-engine/psych-engine", "backend.Conductor", "main");
        if (haxeFilePath != null) {
            trace("Downloaded Haxe file to: " + haxeFilePath);
        }
        
        // Example 3: Try different branches
        var devVersion = yutautil.GithubSource.getHaxeFile("owner/repo", "experimental.NewFeature", "development");
        
        // Example 4: Download from a different repository structure
        var utilsFile = yutautil.GithubSource.getHaxeFile("haxelib/somelib", "src.core.Utils", "master");
    }
    
    // Cleanup is done at compile time
    static function __init__() {
        yutautil.GithubSource.cleanup();
    }
}

/**
 * Example class using the build macro to include external code
 * This would attempt to download and include fields from an external class
 */
@:build(yutautil.GithubSource.includeFromGithub("example-user/example-repo", "utils.MathHelper"))
class ExtendedMathHelper {
    // This class will include all public fields from the downloaded MathHelper class
    // plus any additional fields defined here
    
    public function new() {
        // Constructor
    }
    
    // You can add additional methods here that complement the downloaded code
    public function customFunction():Void {
        trace("This is a custom function in addition to the downloaded code");
    }
}

/**
 * Example showing how to conditionally download different versions
 */
class ConditionalDownload {
    public static function example() {
        // These calls will be resolved at compile time
        var webContent = yutautil.GithubSource.getRawFile("owner/multi-platform-lib", "web.config", "web-optimized");
        var nativeContent = yutautil.GithubSource.getRawFile("owner/multi-platform-lib", "native.config", "native-optimized");
    }
}

/**
 * Example showing how to handle errors gracefully
 */
class ErrorHandlingExample {
    public static function safeDownload():Bool {
        // This will be resolved at compile time
        var content = yutautil.GithubSource.getRawFile("might-not-exist/repo", "might.not.exist", "main");
        if (content == null) {
            trace("File not found, using fallback");
            return false;
        }
        
        // Process the downloaded content
        trace("Successfully downloaded: " + content.length + " characters");
        return true;
    }
}
