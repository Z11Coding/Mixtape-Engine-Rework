package;

import yutautil.KonamiTracker;

class TestCheatOverlap {
    static function main() {
        trace("Testing cheat overlap detection...");

        var tracker = new KonamiTracker();

        try {
            // Add first cheat
            tracker.addCheatFromString("ABC", function(cheat) {
                trace("ABC activated!");
            });
            trace("Added cheat 'ABC' successfully");

            // Try to add overlapping cheat - this should throw an error
            tracker.addCheatFromString("ABCDEF", function(cheat) {
                trace("ABCDEF activated!");
            });
            trace("ERROR: Should have thrown an overlap error!");

        } catch (e:Dynamic) {
            trace("SUCCESS: Caught overlap error: " + e);
        }

        try {
            // Test reverse overlap
            var tracker2 = new KonamiTracker();

            tracker2.addCheatFromString("HELLO", function(cheat) {
                trace("HELLO activated!");
            });
            trace("Added cheat 'HELLO' successfully");

            // Try to add cheat that contains the first one
            tracker2.addCheatFromString("SAYHELLOWORLD", function(cheat) {
                trace("SAYHELLOWORLD activated!");
            });
            trace("ERROR: Should have thrown an overlap error!");

        } catch (e:Dynamic) {
            trace("SUCCESS: Caught reverse overlap error: " + e);
        }

        trace("Test completed!");
    }
}
