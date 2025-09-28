package managers;

import backend.ClientPrefs;
import objects.Note;
import objects.NotePool;

/**
 * Global manager for the experimental NotePool system
 * Handles the singleton NotePool instance and provides easy access methods
 */
class NotePoolManager {
    private static var _instance:NotePoolManager;
    private var _notePool:NotePool;

    public static function getInstance():NotePoolManager {
        if (_instance == null) {
            _instance = new NotePoolManager();
        }
        return _instance;
    }

    private function new() {
        _notePool = new NotePool();
        // updatePoolSettings();
    }

    /**
     * Get the global note pool instance
     */
    public static function getPool():NotePool {
        return getInstance()._notePool;
    }

    /**
     * Create a note using either the pool (if enabled) or standard creation
     */
    public static function createNote(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null):Note {
        if (ClientPrefs.data.useExperimentalNotePool) {
            return getPool().getNote(strumTime, noteData, prevNote, sustainNote, inEditor, createdFrom);
        } else {
            // Standard note creation
            return new Note(strumTime, noteData, prevNote, sustainNote, inEditor, createdFrom);
        }
    }

    /**
     * Return a note to the pool (only if pool is enabled)
     */
    public static function returnNote(note:Note):Void {
        if (ClientPrefs.data.useExperimentalNotePool && note != null) {
            getPool().returnNote(note);
        }
    }

    /**
     * Return multiple notes to the pool
     */
    public static function returnNotes(notes:Array<Note>):Void {
        if (ClientPrefs.data.useExperimentalNotePool && notes != null) {
            getPool().returnNotes(notes);
        }
    }

    /**
     * Clear all active notes and return them to pool
     */
    public static function clearActiveNotes():Void {
        if (ClientPrefs.data.useExperimentalNotePool) {
            getPool().clearActiveNotes();
        }
    }

    /**
     * Update pool settings based on current preferences
     */
    public static function updatePoolSettings():Void {
        var pool = getPool();
        pool.setEnabled(ClientPrefs.data.useExperimentalNotePool);

        // Adjust pool size based on performance settings
        if (ClientPrefs.data.lowQuality || ClientPrefs.data.trashMode) {
            // Smaller pool for low-end devices
            pool.resize(100);
        } else {
            // Standard pool size
            pool.resize(200);
        }
    }

    /**
     * Get pool statistics for debugging
     */
    public static function getStats():Dynamic {
        return getPool().getStats();
    }

    /**
     * Force aggressive cleanup of the pool (use when exiting PlayState)
     */
    public static function forceCleanup():Void {
        if (_instance != null) {
            _instance._notePool.forceCleanup();
        }
    }

    /**
     * Reset demand tracking for new songs
     */
    public static function resetDemandTracking():Void {
        if (_instance != null) {
            _instance._notePool.resetDemandTracking();
        }
    }

    /**
     * Get detailed pool information
     */
    public static function getDetailedStats():String {
        var stats = getStats();
        var efficiency = Math.round(stats.efficiency * 100) / 100;
        var utilization = Math.round(stats.poolUtilization * 100) / 100;

        return 'NotePool Stats:\n' +
               'Total Created: ${stats.totalCreated}\n' +
               'Total Reused: ${stats.totalReused}\n' +
               'Efficiency: ${efficiency}%\n' +
               'Active Notes: ${stats.activeNotes}\n' +
               'Active Sustains: ${stats.activeSustains}\n' +
               'Total Active: ${stats.totalActive}\n' +
               'Pooled Notes: ${stats.pooledNotes}\n' +
               'Pooled Sustains: ${stats.pooledSustains}\n' +
               'Total Pooled: ${stats.totalPooled}\n' +
               'Current Demand: ${stats.currentDemand}\n' +
               'Peak Demand: ${stats.peakDemand}\n' +
               'Target Pool Size: ${stats.targetPoolSize}\n' +
               'Pool Utilization: ${utilization}%\n' +
               'Memory Pressure: ${stats.memoryPressure ? "HIGH" : "NORMAL"}';
    }

    /**
     * Reset the pool manager (useful for state transitions)
     */
    public static function reset():Void {
        if (_instance != null) {
            _instance._notePool.forceCleanup();
            _instance._notePool.destroy();
            _instance._notePool = new NotePool();
            updatePoolSettings();
        }
    }

    /**
     * Cleanup the pool manager
     */
    public static function cleanup():Void {
        if (_instance != null) {
            _instance._notePool.destroy();
            _instance = null;
        }
    }
}
