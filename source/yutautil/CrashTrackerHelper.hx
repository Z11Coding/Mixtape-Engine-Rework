package yutautil;

/**
 * Crash Tracker Helper - Utility functions for managing crash tracking
 */
class CrashTrackerHelper {
    
    /**
     * Initialize crash tracking system
     * Call this early in your application startup
     */
    public static function initialize():Void {
        CrashReporter.init();
        trace("CrashTracker: System initialized");
    }
    
    /**
     * Apply crash tracking to MusicBeatState and its subclasses
     * Add this to your MusicBeatState class:
     * @:autoBuild(yutautil.CrashTracker.instrument())
     */
    public static function instrumentStates():Void {
        // This is handled by the macro, but this function serves as documentation
        trace("CrashTracker: Add @:autoBuild(yutautil.CrashTracker.instrument()) to your state classes");
    }
    
    /**
     * Manually log an activity (useful for critical sections)
     */
    public static function logCriticalActivity(className:String, method:String, description:String):Void {
        CrashReporter.logActivity(className, method, "CRITICAL: " + description);
    }
    
    /**
     * Log memory usage (useful for tracking memory leaks)
     */
    public static function logMemoryUsage(context:String):Void {
        #if cpp
        try {
            var memInfo = cpp.vm.Gc.memInfo64(0); // Pass required argument
            CrashReporter.logActivity("MemoryTracker", context, 'Memory: ${memInfo}');
        } catch (e:Dynamic) {
            CrashReporter.logActivity("MemoryTracker", context, 'Memory tracking failed: $e');
        }
        #else
        CrashReporter.logActivity("MemoryTracker", context, 'Memory tracking not available on this platform');
        #end
    }
    
    /**
     * Create a checkpoint for tracking game progression
     */
    public static function checkpoint(location:String, data:String = ""):Void {
        CrashReporter.logActivity("GameCheckpoint", location, "CHECKPOINT: " + data);
    }
    
    /**
     * Log state transitions
     */
    public static function logStateTransition(fromState:String, toState:String):Void {
        CrashReporter.logActivity("StateManager", "transition", 'State change: $fromState -> $toState');
    }
    
    /**
     * Log asset loading
     */
    public static function logAssetLoad(assetType:String, assetPath:String, success:Bool):Void {
        var status = success ? "SUCCESS" : "FAILED";
        CrashReporter.logActivity("AssetLoader", assetType, '$status: $assetPath');
    }
    
    /**
     * Generate crash report with custom reason
     */
    public static function reportCrash(reason:String):Void {
        CrashReporter.generateCrashReport(reason);
    }
    
    /**
     * Get summary of recent activity (useful for debugging)
     */
    public static function getActivitySummary(count:Int = 10):String {
        var recent = CrashReporter.getRecentActivity(count);
        var summary = "Recent Activity:\n";
        
        for (entry in recent) {
            var time = DateTools.format(entry.timestamp, "%H:%M:%S");
            summary += '[$time] ${entry.className}.${entry.method}: ${entry.action}\n';
        }
        
        return summary;
    }
    
    /**
     * Enable or disable crash detection
     */
    public static function toggleCrashDetection(enabled:Bool):Void {
        CrashReporter.setCrashDetectionEnabled(enabled);
    }
    
    /**
     * Test the crash reporting system
     */
    public static function testCrashReporting():Void {
        trace("CrashTracker: Testing crash reporting system...");
        
        // Log some test activities
        logCriticalActivity("TestClass", "testMethod", "This is a test critical activity");
        checkpoint("TestCheckpoint", "Testing checkpoint system");
        logStateTransition("TestState1", "TestState2");
        
        // Generate test crash report
        CrashReporter.triggerTestCrashReport();
        
        trace("CrashTracker: Test completed - check logger folder");
    }
}
