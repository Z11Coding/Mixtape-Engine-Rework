package yutautil;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BitmapData;

/**
 * Test class for ManagedState functionality
 * Demonstrates asset tracking, cleanup, and EndOfLife features
 */
class ManagedStateTest extends ManagedState {

    private var testSprites:Array<FlxSprite> = [];
    private var testTexts:Array<FlxText> = [];
    private var testSounds:Array<FlxSound> = [];
    private var testGroup:FlxGroup;

    override public function create():Void {
        super.create();

        trace("=== ManagedStateTest: Starting comprehensive test ===");

        // Test 1: Create various sprites with graphics
        createTestSprites();

        // Test 2: Create text objects
        createTestTexts();

        // Test 3: Create sound objects
        createTestSounds();

        // Test 4: Create nested groups
        createTestGroups();

        // Test 5: Create objects with custom bitmaps
        createCustomBitmapObjects();

        // Print initial debug info
        printDebugInfo();

        // Schedule tests
        scheduleTests();
    }

    private function createTestSprites():Void {
        trace("Creating test sprites with graphics...");

        for (i in 0...5) {
            var sprite = new FlxSprite(i * 100, 100);
            sprite.makeGraphic(64, 64, FlxColor.fromHSB(i * 72, 1.0, 1.0));
            testSprites.push(sprite);
            add(sprite);
        }
    }

    private function createTestTexts():Void {
        trace("Creating test text objects...");

        for (i in 0...3) {
            var text = new FlxText(i * 150, 200, 100, "Test Text " + i);
            text.setFormat(null, 16, FlxColor.WHITE);
            testTexts.push(text);
            add(text);
        }
    }

    private function createTestSounds():Void {
        trace("Creating test sound objects...");

        // Note: In a real test, you would load actual sound files
        // For this test, we'll create empty FlxSound objects
        for (i in 0...2) {
            var sound = new FlxSound();
            testSounds.push(sound);
            add(sound);
        }
    }

    private function createTestGroups():Void {
        trace("Creating nested groups with sprites...");

        testGroup = new FlxGroup();

        // Add sprites to the group
        for (i in 0...3) {
            var groupSprite = new FlxSprite(i * 80, 300);
            groupSprite.makeGraphic(32, 32, FlxColor.CYAN);
            testGroup.add(groupSprite);
        }

        // Add a nested group
        var nestedGroup = new FlxGroup();
        for (i in 0...2) {
            var nestedSprite = new FlxSprite(i * 60, 350);
            nestedSprite.makeGraphic(24, 24, FlxColor.MAGENTA);
            nestedGroup.add(nestedSprite);
        }
        testGroup.add(nestedGroup);

        add(testGroup);
    }

    private function createCustomBitmapObjects():Void {
        trace("Creating objects with custom bitmaps...");

        // Create a sprite with a custom bitmap
        var customBitmap = new BitmapData(128, 128, true, 0xFFFF00FF);
        var customGraphic = FlxGraphic.fromBitmapData(customBitmap);

        var customSprite = new FlxSprite(400, 100);
        customSprite.loadGraphic(customGraphic);
        add(customSprite);
    }

    private function scheduleTests():Void {
        // Test tracking after 2 seconds
        FlxTimer.wait(2.0, function() {
            trace("\n=== After 2 seconds ===");
            printDebugInfo();
            testPartialCleanup();
        });

        // Test EndOfLife after 4 seconds
        FlxTimer.wait(4.0, function() {
            trace("\n=== Testing EndOfLife ===");
            testEndOfLife();
        });

        // Final test after 6 seconds
        FlxTimer.wait(6.0, function() {
            trace("\n=== Final state ===");
            printDebugInfo();
        });
    }

    private function testPartialCleanup():Void {
        trace("Testing partial cleanup...");

        // Remove some sprites manually
        if (testSprites.length > 0) {
            var spriteToRemove = testSprites[0];
            remove(spriteToRemove);
            testSprites.splice(0, 1);
            trace("Removed one sprite manually");
        }

        // Force cleanup of a specific object
        if (testTexts.length > 0) {
            var textToCleanup = testTexts[0];
            forceCleanupObject(textToCleanup);
            testTexts.splice(0, 1);
            trace("Force cleaned up one text object");
        }

        printDebugInfo();
    }

    private function testEndOfLife():Void {
        trace("Testing EndOfLife functionality...");

        var statsBefore = getMemoryStats();
        trace('Before EndOfLife - Objects: ${statsBefore.currentObjectsTracked}, Assets: ${statsBefore.totalAssetsManaged}');

        // Trigger EndOfLife
        EndOfLife();

        var statsAfter = getMemoryStats();
        trace('After EndOfLife - Objects: ${statsAfter.currentObjectsTracked}, Assets: ${statsAfter.totalAssetsManaged}');

        // Verify cleanup
        if (statsAfter.currentObjectsTracked == 0) {
            trace("SUCCESS: EndOfLife properly cleaned up all objects");
        } else {
            trace("WARNING: EndOfLife did not clean up all objects");
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Exit test with ESCAPE key
        if (FlxG.keys.justPressed.ESCAPE) {
            trace("Exiting test...");
            FlxG.switchState(new flixel.FlxState());
        }

        // Print debug info with SPACE key
        if (FlxG.keys.justPressed.SPACE) {
            printDebugInfo();
        }

        // Test EndOfLife with E key
        if (FlxG.keys.justPressed.E) {
            trace("Manual EndOfLife test triggered");
            testEndOfLife();
        }
    }

    override public function destroy():Void {
        trace("=== ManagedStateTest: destroy() called ===");

        // Clear test arrays
        testSprites = null;
        testTexts = null;
        testSounds = null;
        testGroup = null;

        super.destroy();

        trace("=== ManagedStateTest: destroy() completed ===");
    }
}

/**
 * Simple test runner that can be called from anywhere
 */
class ManagedStateTestRunner {
    public static function runTest():Void {
        trace("Starting ManagedState test...");
        FlxG.switchState(new ManagedStateTest());
    }
}
