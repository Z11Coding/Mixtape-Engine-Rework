package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import backend.MusicBeatState;
import yutautil.CrashTrackerHelper;

/**
 * Crash Tracker Test State - Demonstrates the crash tracking system
 */
class CrashTrackerTestState extends MusicBeatState {
    private var titleText:FlxText;
    private var instructionText:FlxText;
    private var logText:FlxText;
    private var testCounter:Int = 0;
    
    override function create() {
        super.create();
        
        // Log state creation
        CrashTrackerHelper.logCriticalActivity("CrashTrackerTestState", "create", "Test state initialized");
        CrashTrackerHelper.checkpoint("TestStateCreate", "Starting crash tracker demonstration");
        
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Testing Crash Tracker", "Crash Tracker Test State");
        #end
        
        setupBackground();
        setupUI();
        
        // Schedule some test activities
        scheduleTestActivities();
    }
    
    private function setupBackground():Void {
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
        bg.scrollFactor.set();
        bg.color = 0xFF2a2a2a;
        add(bg);
    }
    
    private function setupUI():Void {
        // Title
        titleText = new FlxText(0, 50, FlxG.width, "CRASH TRACKER TEST STATE", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        add(titleText);
        
        // Instructions
        instructionText = new FlxText(20, 120, FlxG.width - 40, "", 16);
        instructionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.CYAN, CENTER);
        instructionText.text = "This state demonstrates the crash tracking system.\n\n";
        instructionText.text += "Press 1-6 to test different scenarios:\n";
        instructionText.text += "1: Log Critical Activity\n";
        instructionText.text += "2: Create Checkpoint\n";
        instructionText.text += "3: Log Memory Usage\n";
        instructionText.text += "4: Simulate Exception (Caught)\n";
        instructionText.text += "5: Generate Test Crash Report\n";
        instructionText.text += "6: View Recent Activity\n\n";
        instructionText.text += "ESC: Return to Debug Menu";
        add(instructionText);
        
        // Log display
        logText = new FlxText(20, 350, FlxG.width - 40, "", 12);
        logText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, LEFT);
        add(logText);
        
        updateLogDisplay();
    }
    
    private function scheduleTestActivities():Void {
        // Schedule periodic test activities to show continuous monitoring
        new FlxTimer().start(2.0, function(timer:FlxTimer) {
            testCounter++;
            CrashTrackerHelper.logCriticalActivity("CrashTrackerTestState", "periodicTest", 'Periodic test #$testCounter');
            
            if (testCounter % 5 == 0) {
                CrashTrackerHelper.checkpoint("PeriodicCheckpoint", 'Checkpoint at test #$testCounter');
            }
            
            updateLogDisplay();
        }, 0); // Loop infinitely
    }
    
    private function updateLogDisplay():Void {
        var recentActivity = CrashTrackerHelper.getActivitySummary(8);
        logText.text = "Recent Activity:\n" + recentActivity;
    }
    
    private function testCriticalActivity():Void {
        CrashTrackerHelper.logCriticalActivity("CrashTrackerTestState", "testCriticalActivity", 
            "User triggered critical activity test");
        
        logText.text = "✓ Critical activity logged!\n" + CrashTrackerHelper.getActivitySummary(5);
        
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
    }
    
    private function testCheckpoint():Void {
        CrashTrackerHelper.checkpoint("UserTestCheckpoint", 
            "User-triggered checkpoint at " + Date.now().toString());
        
        logText.text = "✓ Checkpoint created!\n" + CrashTrackerHelper.getActivitySummary(5);
        
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
    }
    
    private function testMemoryUsage():Void {
        CrashTrackerHelper.logMemoryUsage("userTest");
        
        logText.text = "✓ Memory usage logged!\n" + CrashTrackerHelper.getActivitySummary(5);
        
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
    }
    
    private function testException():Void {
        try {
            // Simulate an exception
            throw "Test exception for crash tracking demonstration";
        } catch (e:Dynamic) {
            // The crash tracker automatically logs this exception
            logText.text = "✓ Exception caught and logged!\nException: " + Std.string(e) + 
                           "\n" + CrashTrackerHelper.getActivitySummary(3);
        }
        
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
    }
    
    private function testCrashReport():Void {
        CrashTrackerHelper.reportCrash("User-triggered test crash report from CrashTrackerTestState");
        
        logText.text = "✓ Test crash report generated!\nCheck logger folder for the report.\n" + 
                       CrashTrackerHelper.getActivitySummary(3);
        
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
    }
    
    private function viewRecentActivity():Void {
        var activity = CrashTrackerHelper.getActivitySummary(15);
        logText.text = "Recent Activity (Last 15 entries):\n" + activity;
        
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
    }
    
    // This method will be automatically instrumented by the macro
    public function automaticallyInstrumentedMethod():Void {
        // This demonstrates automatic instrumentation
        // Entry and exit will be logged automatically
        
        var someComplexOperation = "This method is automatically monitored";
        
        // Simulate some work
        for (i in 0...100) {
            someComplexOperation += i;
        }
        
        CrashTrackerHelper.logCriticalActivity("CrashTrackerTestState", 
            "automaticallyInstrumentedMethod", "Complex operation completed");
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        // Handle input
        if (controls.BACK) {
            CrashTrackerHelper.logStateTransition("CrashTrackerTestState", "DebugStateMenu");
            MusicBeatState.switchState(new DebugStateMenu());
        }
        
        // Test scenarios
        if (FlxG.keys.justPressed.ONE) {
            testCriticalActivity();
        }
        
        if (FlxG.keys.justPressed.TWO) {
            testCheckpoint();
        }
        
        if (FlxG.keys.justPressed.THREE) {
            testMemoryUsage();
        }
        
        if (FlxG.keys.justPressed.FOUR) {
            testException();
        }
        
        if (FlxG.keys.justPressed.FIVE) {
            testCrashReport();
        }
        
        if (FlxG.keys.justPressed.SIX) {
            viewRecentActivity();
        }
        
        // Test automatic instrumentation
        if (FlxG.keys.justPressed.SPACE) {
            automaticallyInstrumentedMethod();
            logText.text = "✓ Automatically instrumented method called!\n" + 
                           CrashTrackerHelper.getActivitySummary(5);
        }
    }
    
    override function destroy() {
        CrashTrackerHelper.logCriticalActivity("CrashTrackerTestState", "destroy", "Test state being destroyed");
        super.destroy();
    }
}
