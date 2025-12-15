package backend.window;

/**
 * Cross-Platform API Test and Examples
 * 
 * This class demonstrates the usage of the enhanced CppAPI 
 * with cross-platform alternatives for Linux, Mac, and Android.
 * 
 * NOTE: Requires -D CROSSPLATFORM flag for cross-platform features to work.
 * Without this flag, only Windows functionality is available.
 */
class CppAPITest {
    public static function testAllFeatures():Void {
        trace("=== CppAPI Cross-Platform Test ===");
        
        #if CROSSPLATFORM
        trace("CROSSPLATFORM flag is enabled - full cross-platform features available");
        #else
        trace("CROSSPLATFORM flag is disabled - only Windows features available");
        #end
        
        // Platform detection
        trace("Platform: " + CppAPI.getPlatform());
        trace("Platform Info: " + CppAPI.getPlatformInfo());        // Memory information
        var totalRAM = CppAPI.obtainRAM();
        var availableRAM = CppAPI.getAvailableRAM();
        trace("Total RAM: " + (totalRAM > 0 ? totalRAM + " MB" : "Unknown"));
        trace("Available RAM: " + (availableRAM > 0 ? availableRAM + " MB" : "Unknown"));

        // System commands
        trace("Has 'git' command: " + CppAPI.hasSystemCommand("git"));
        trace("Has 'python' command: " + CppAPI.hasSystemCommand("python"));

        // Performance test
        var perfScore = CppAPI.getPerformanceScore();
        trace("Performance Score: " + perfScore);

        // System uptime (Linux/Mac)
        var uptime = CppAPI.getSystemUptime();
        if (uptime > 0) {
            trace("System Uptime: " + Math.round(uptime) + " seconds");
        }

        // Test notifications on all platforms
        trace("Sending test notification...");
        var notifResult = CppAPI.sendWindowsNotification("Mixtape Engine", "Cross-platform test successful!");
        trace("Notification sent: " + notifResult);

        // Window management (mostly Windows-specific)
        trace("Testing window management features...");

        #if windows
        trace("Windows-specific features available");
        #else
        trace("Windows-specific features not available on this platform");
        #end

        // File operations
        trace("Testing file operations...");
        var testPath = Sys.getCwd();
        trace("Current directory: " + testPath);

        // Test opening with system (be careful with this in automated tests)
        // CppAPI.openWithSystem(testPath);

        trace("=== CppAPI Test Complete ===");
    }

    public static function testPlatformSpecific():Void {
        trace("=== Platform-Specific Tests ===");

        #if windows
        trace("Windows-specific test:");
        // Test Windows-only features

        #elseif linux
        trace("Linux-specific test:");
        var de = backend.window.os.Linux.getDesktopEnvironment();
        trace("Desktop Environment: " + de);

        trace("Available commands:");
        var commonCommands = ["notify-send", "gsettings", "feh", "xdg-open"];
        for (cmd in commonCommands) {
            trace("  " + cmd + ": " + backend.window.os.Linux.hasCommand(cmd));
        }

        #elseif mac
        trace("macOS-specific test:");
        var version = backend.window.os.Mac.getMacOSVersion();
        var arch = backend.window.os.Mac.getArchitecture();
        trace("macOS Version: " + version);
        trace("Architecture: " + arch);

        #elseif android
        trace("Android-specific test:");
        var androidVersion = backend.window.os.Android.getAndroidVersion();
        var apiLevel = backend.window.os.Android.getAPILevel();
        var deviceModel = backend.window.os.Android.getDeviceModel();
        var isRooted = backend.window.os.Android.isRooted();

        trace("Android Version: " + androidVersion);
        trace("API Level: " + apiLevel);
        trace("Device Model: " + deviceModel);
        trace("Is Rooted: " + isRooted);

        #else
        trace("Generic platform - limited features available");
        #end

        trace("=== Platform-Specific Tests Complete ===");
    }
}
