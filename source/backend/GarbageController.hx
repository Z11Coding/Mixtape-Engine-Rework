package backend;

#if (cpp || hl)
import cpp.vm.Gc;
#end

/**
 * Experimental Garbage Controller for Mixtape Engine
 *
 * This class provides precise control over when garbage collection occurs
 * to prevent the hanging issues that can occur when idling in menus,
 * especially when the window is unfocused.
 *
 * Behavior:
 * - Disabled in menus and PlayState to prevent hangs during idle
 * - Enabled during loading states with forced cleanup before loading
 * - Forced cleanup after leaving PlayState for memory management
 *
 * @author Mixtape Engine Team
 */
class GarbageController
{
    private static var _isExperimentalMode:Bool = false;
    private static var _originalGCState:Bool = true;
    private static var _currentGCEnabled:Bool = true;

    /**
     * Initialize the Garbage Controller system
     * Should be called during engine initialization
     */
    public static function init():Void
    {
        #if (cpp || hl)
        _originalGCState = ClientPrefs.data.garbageCollection;
        _currentGCEnabled = _originalGCState;

        if (ClientPrefs.data.experimentalGC) {
            _isExperimentalMode = true;
            trace("GarbageController: Experimental GC mode enabled");
        } else {
            _isExperimentalMode = false;
            // Use normal GC behavior
            Gc.enable(_originalGCState);
        }
        #end
    }

    /**
     * Enable experimental garbage collection mode
     * This will take control over GC state management
     */
    public static function enableExperimentalMode():Void
    {
        #if (cpp || hl)
        _isExperimentalMode = true;
        ClientPrefs.data.experimentalGC = true;
        trace("GarbageController: Experimental mode enabled");
        #end
    }

    /**
     * Disable experimental garbage collection mode
     * Returns control to standard GC behavior
     */
    public static function disableExperimentalMode():Void
    {
        #if (cpp || hl)
        _isExperimentalMode = false;
        ClientPrefs.data.experimentalGC = false;

        // Restore original GC state
        Gc.enable(_originalGCState);
        _currentGCEnabled = _originalGCState;

        trace("GarbageController: Experimental mode disabled, restored original GC state");
        #end
    }

    /**
     * Disable garbage collection for menus and gameplay
     * Called when entering menus or PlayState in experimental mode
     */
    public static function disableForState():Void
    {
        #if (cpp || hl)
        if (!_isExperimentalMode) return;

        if (_currentGCEnabled) {
            Gc.enable(false);
            _currentGCEnabled = false;
            trace("GarbageController: Disabled GC for state (menu/gameplay)");
        }
        #end
    }

    /**
     * Enable garbage collection for loading states
     * Called when entering loading states in experimental mode
     */
    public static function enableForLoading():Void
    {
        #if (cpp || hl)
        if (!_isExperimentalMode) return;

        if (!_currentGCEnabled) {
            Gc.enable(true);
            _currentGCEnabled = true;
            trace("GarbageController: Enabled GC for loading");
        }
        #end
    }

    /**
     * Force garbage collection cleanup before loading
     * Performs both minor and major GC cycles
     */
    public static function forceCleanupBeforeLoading():Void
    {
        #if (cpp || hl)
        if (!_isExperimentalMode) return;

        enableForLoading();

        // Perform minor GC first
        #if (cpp || java || neko)
        Gc.run(false);
        #end

        // Then major GC with compaction
        #if cpp
        Gc.run(true);
        Gc.compact();
        #end

        trace("GarbageController: Forced cleanup completed before loading");
        #end
    }

    /**
     * Force cleanup after leaving PlayState
     * Ensures memory is cleaned up after gameplay
     */
    public static function forceCleanupAfterPlayState():Void
    {
        #if (cpp || hl)
        if (!_isExperimentalMode) return;

        // Temporarily enable GC for cleanup
        var wasEnabled = _currentGCEnabled;
        if (!wasEnabled) {
            Gc.enable(true);
        }

        // Perform comprehensive cleanup
        #if (cpp || java || neko)
        Gc.run(false);
        #end

        #if cpp
        Gc.run(true);
        Gc.compact();
        #end

        // Restore previous state
        if (!wasEnabled) {
            Gc.enable(false);
            _currentGCEnabled = false;
        }

        trace("GarbageController: Forced cleanup completed after PlayState");
        #end
    }

    /**
     * Get current experimental mode status
     */
    public static function isExperimentalMode():Bool
    {
        return _isExperimentalMode;
    }

    /**
     * Get current GC enabled state
     */
    public static function isGCEnabled():Bool
    {
        return _currentGCEnabled;
    }

    /**
     * Manual garbage collection trigger for debugging
     */
    public static function debugForceGC():Void
    {
        #if (cpp || hl)
        var wasEnabled = _currentGCEnabled;

        if (!wasEnabled) {
            Gc.enable(true);
        }

        #if (cpp || java || neko)
        Gc.run(false);
        #end

        #if cpp
        Gc.run(true);
        Gc.compact();
        #end

        if (!wasEnabled) {
            Gc.enable(false);
        }

        trace("GarbageController: Debug GC forced");
        #end
    }

    /**
     * Update the experimental mode based on ClientPrefs
     * Call this when settings change
     */
    public static function updateFromPrefs():Void
    {
        #if (cpp || hl)
        if (ClientPrefs.data.experimentalGC && !_isExperimentalMode) {
            enableExperimentalMode();
        } else if (!ClientPrefs.data.experimentalGC && _isExperimentalMode) {
            disableExperimentalMode();
        }

        // Update original state reference
        _originalGCState = ClientPrefs.data.garbageCollection;
        #end
    }
}
