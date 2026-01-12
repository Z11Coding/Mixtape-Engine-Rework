package backend.window;

/**
 * Test class for the Priority system to verify functionality.
 * You can call Priority.Test.runBasicTests() to test the system.
 */
class PriorityTest
{
    /**
     * Runs basic tests of the priority system functionality
     */
    public static function runBasicTests():Void
    {
        #if windows
        trace("Starting Priority System Tests...");

        // Test 1: Get current priority
        var currentPriority = Priority.getPriority();
        var currentPriorityString = Priority.getPriorityString();
        trace('Current Priority: $currentPriority ($currentPriorityString)');

        // Test 2: Set to Normal priority
        trace("Setting priority to Normal...");
        var result = Priority.setPriorityString("Normal");
        trace('Set Normal Priority Result: $result');

        // Verify the change
        var newPriority = Priority.getPriority();
        var newPriorityString = Priority.getPriorityString();
        trace('New Priority: $newPriority ($newPriorityString)');

        // Test 3: Set to High priority
        trace("Setting priority to High...");
        result = Priority.setPriorityString("High");
        trace('Set High Priority Result: $result');

        // Verify the change
        newPriority = Priority.getPriority();
        newPriorityString = Priority.getPriorityString();
        trace('New Priority: $newPriority ($newPriorityString)');

        // Test 4: Reset to Normal
        trace("Resetting priority to Normal...");
        result = Priority.resetToNormal();
        trace('Reset to Normal Result: $result');

        // Verify the reset
        newPriority = Priority.getPriority();
        newPriorityString = Priority.getPriorityString();
        trace('Final Priority: $newPriority ($newPriorityString)');

        // Test 5: Test monitoring features
        trace("Testing monitoring features...");
        testMonitoring();

        trace("Priority System Tests Complete!");
        #else
        trace("Priority System Tests are only available on Windows.");
        #end
    }

    /**
     * Tests the new monitoring and force-lock features
     */
    public static function testMonitoring():Void
    {
        #if windows
        trace("=== Testing Priority Monitoring Features ===");

        // Test 1: Basic monitoring status
        trace('Is monitoring active? ${Priority.isMonitoring()}');
        trace('Is force-lock enabled? ${Priority.isForceLockEnabled()}');
        trace('Target priority: ${Priority.getTargetPriority()} (${Priority.getPriorityStringFromLevel(Priority.getTargetPriority())})');

        // Test 2: Start monitoring without force-lock
        trace("Starting priority monitoring (no force-lock) for 'Above Normal' priority...");
        Priority.startPriorityMonitoring(3, false, 500); // Target Above Normal, no force-lock, check every 500ms

        trace('Is monitoring active? ${Priority.isMonitoring()}');
        trace('Target priority: ${Priority.getTargetPriority()} (${Priority.getPriorityStringFromLevel(Priority.getTargetPriority())})');
        trace('Force-lock enabled? ${Priority.isForceLockEnabled()}');

        // Test 3: Enable force-lock
        trace("Enabling force-lock...");
        Priority.setForceLock(true);
        trace('Force-lock enabled? ${Priority.isForceLockEnabled()}');

        // Test 4: Change target priority
        trace("Changing target priority to High...");
        Priority.setTargetPriority(4);
        trace('New target priority: ${Priority.getTargetPriority()} (${Priority.getPriorityStringFromLevel(Priority.getTargetPriority())})');

        // Test 5: Stop monitoring
        trace("Stopping monitoring...");
        Priority.stopPriorityMonitoring();
        trace('Is monitoring active? ${Priority.isMonitoring()}');

        trace("=== Monitoring Tests Complete ===");
        #else
        trace("Priority monitoring tests are only available on Windows.");
        #end
    }

    /**
     * Monitors priority changes for a few seconds to test external detection
     */
    public static function monitorPriorityChanges():Void
    {
        #if windows
        var lastKnownPriority = Priority.getPriority();
        trace('Starting priority monitoring. Current priority: ${Priority.getPriorityString()}');
        trace('Change the priority in Task Manager to test external change detection...');

        var timer = new haxe.Timer(1000); // Check every second
        var checkCount = 0;

        timer.run = function() {
            var change = Priority.checkForExternalChanges(lastKnownPriority);
            if (change != -1) {
                trace('Priority changed externally! New priority: ${change} (${Priority.getPriorityString()})');
                lastKnownPriority = change;
            }

            checkCount++;
            if (checkCount >= 10) { // Monitor for 10 seconds
                timer.stop();
                trace('Priority monitoring stopped.');
            }
        };
        #else
        trace("Priority monitoring is only available on Windows.");
        #end
    }
}
