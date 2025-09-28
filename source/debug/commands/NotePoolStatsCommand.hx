package debug.commands;

import backend.ClientPrefs;
import managers.NotePoolManager;

/**
 * Debug command to display NotePool statistics
 */
class NotePoolStatsCommand {
    public static function register() {
        #if (debug || FORCE_DEBUG_VERSION)
        // Add to console commands if console system exists
        // This is a placeholder for console integration
        trace("NotePool stats command registered");
        #end
    }

    /**
     * Display current NotePool statistics
     */
    public static function showStats():Void {
        if (!ClientPrefs.data.useExperimentalNotePool) {
            trace("Experimental NotePool is disabled");
            return;
        }

        var stats = NotePoolManager.getDetailedStats();
        trace("=== NotePool Statistics ===");
        trace(stats);
    }

    /**
     * Reset the NotePool and show new stats
     */
    public static function resetPool():Void {
        if (!ClientPrefs.data.useExperimentalNotePool) {
            trace("Experimental NotePool is disabled");
            return;
        }

        NotePoolManager.reset();
        trace("NotePool has been reset");
        showStats();
    }

    /**
     * Force aggressive cleanup of the pool
     */
    public static function forceCleanup():Void {
        if (!ClientPrefs.data.useExperimentalNotePool) {
            trace("Experimental NotePool is disabled");
            return;
        }

        NotePoolManager.forceCleanup();
        trace("NotePool has been aggressively cleaned up");
        showStats();
    }

    /**
     * Reset demand tracking
     */
    public static function resetDemand():Void {
        if (!ClientPrefs.data.useExperimentalNotePool) {
            trace("Experimental NotePool is disabled");
            return;
        }

        NotePoolManager.resetDemandTracking();
        trace("NotePool demand tracking has been reset");
        showStats();
    }
}
