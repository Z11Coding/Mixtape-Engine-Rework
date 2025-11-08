package;

import backend.ClientPrefs;
import flixel.FlxG;

/**
 * Simple test class to demonstrate the enhanced tracing system
 * This can be called from the command prompt to test different trace modes
 */
class TraceSystemTest
{
    public static function runTest():Void
    {
        trace("=== Tracing System Test ===");
        trace("Current trace mode: " + ClientPrefs.data.traceMode);
        trace("Max in-game traces: " + ClientPrefs.data.maxInGameTraces);
        trace("Haxe traces disabled: " + ClientPrefs.data.disableHaxeTraces);

        trace("Testing trace with position info from TraceSystemTest.hx");
        trace("If you can see this in the console, console tracing works!");
        trace("If you can see this in the in-game viewer (F3), game tracing works!");
        trace("You should be able to toggle the trace viewer with F3 key");

        for (i in 0...5)
        {
            trace('Test trace #${i + 1} - Multiple traces for scrolling test');
        }

        trace("=== End Tracing System Test ===");

        // Also test the in-game viewer directly if it exists
        if (backend.modules.TraceViewerPlugin.instance != null)
        {
            trace("In-game trace viewer plugin is active and ready!");
        }
        else
        {
            trace("In-game trace viewer plugin not found - make sure it's initialized");
        }
    }
}
