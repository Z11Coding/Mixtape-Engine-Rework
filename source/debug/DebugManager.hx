package debug;

import debug.StateDebugOverlay;
import flixel.FlxG;

/**
 * Manager for debug overlays and utilities
 */
class DebugManager
{
	private static var debugOverlay:StateDebugOverlay;
	private static var initialized:Bool = false;

	/**
	 * Initialize debug manager
	 */
	public static function initialize():Void
	{
		if (initialized)
			return;

		initialized = true;
		trace('DebugManager initialized');
	}

	/**
	 * Toggle the debug overlay
	 */
	public static function toggleDebugOverlay():Void
	{
		if (!initialized)
			initialize();

		var state = FlxG.state;
		if (state == null)
			return;

		// If overlay is currently visible, close it
		if (debugOverlay != null && state.subState == debugOverlay)
		{
			debugOverlay.close(); // This will restore mouse state and clean up camera
			debugOverlay = null; // Clean up to save memory
			trace('Debug overlay closed');
			return;
		}

		// Create new overlay only when needed
		debugOverlay = new StateDebugOverlay();
		state.openSubState(debugOverlay);
		trace('Debug overlay opened');
	}

	/**
	 * Check if debug overlay is currently visible
	 */
	public static function isDebugOverlayVisible():Bool
	{
		return debugOverlay != null && FlxG.state != null && FlxG.state.subState == debugOverlay;
	}

	/**
	 * Force close debug overlay
	 */
	public static function closeDebugOverlay():Void
	{
		if (debugOverlay != null && FlxG.state != null && FlxG.state.subState == debugOverlay)
		{
			debugOverlay.close(); // This will restore mouse state and clean up camera
			debugOverlay = null; // Clean up to save memory
			trace('Debug overlay force closed');
		}
	}

	/**
	 * Handle debug key presses (call this from your main update loop)
	 */
	public static function handleDebugKeys():Void
	{
		// Ctrl+Alt+D to toggle debug overlay
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.D)
		{
			toggleDebugOverlay();
		}
	}
}
