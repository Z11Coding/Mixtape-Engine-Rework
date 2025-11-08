package;

import backend.ClientPrefs;
import backend.modules.TraceManager;

/**
 * Simple test for the enhanced tracing system
 */
class TestTrace
{
    public static function main():Void
    {
        // Test the tracing system
        trace("Testing enhanced tracing system");
        trace("Current trace mode: " + ClientPrefs.data.traceMode);
        trace("This should appear based on the trace mode setting");

        // Test the in-game viewer
        TraceManager.addTrace("Direct trace to in-game viewer");
        TraceManager.showViewer();

        trace("If you can see the viewer, the system is working!");
    }
}
