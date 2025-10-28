package states;

import backend.*;
import backend.ui.PsychUIDrawer.DrawerSide;
import backend.ui.PsychUIDrawer;
import backend.ui.PsychUITab;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.*;
import states.PlayState;

/**
 * ModchartEditor: A state for creating modchart effects that can be exported as HScript or JSON.
 * Uses PlayState as a base and ensures all PlayFields are in autoplay mode.
 */
class ModchartEditor extends PlayState {
    public var editorCamera:FlxCamera;
    public var editorDrawer:PsychUIDrawer;
    public var isEditorMode:Bool = true;

    // Editor-specific variables
    public var selectedStrumNote:StrumNote;
    public var selectedNote:Note;
    public var modchartData:Array<ModchartEvent>;
    public var currentTime:Float = 0;
    public var isPlaying:Bool = false;
    public var exportFormat:String = "hscript"; // "hscript" or "json"

    // UI Elements
    public var timelineText:FlxText;
    public var statusText:FlxText;
    public var helpText:FlxText;

    override function create() {
        // Initialize PlayState first
        super.create();

        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Creating a Modchart", null);
		#end

        // Force all playfields to autoplay after PlayState is created
        for (field in playfields.members) {
            if (field != null) {
                field.autoPlayed = true;
            }
        }

        // Hide/disable PlayState UI elements
        hidePlayStateUI();

        // Initialize modchart data
        modchartData = [];

        setupEditorCamera();
        setupEditorUI();
        setupEditorDrawer();

        // Pause the song initially
        FlxG.sound.music.pause();
        vocals.pause();
        isPlaying = false;

        // Make mouse visible for editor interaction
        FlxG.mouse.visible = true;

        trace("Modchart Editor initialized");
    }

    function hidePlayStateUI() {
        // Hide health bar
        if (healthBar != null) {
            healthBar.visible = false;
            if (healthBar.bg != null) healthBar.bg.visible = false;
        }
        if (iconP1 != null) iconP1.visible = false;
        if (iconP2 != null) iconP2.visible = false;

        // Hide score text
        if (scoreTxt != null) scoreTxt.visible = false;
        if (botplayTxt != null) botplayTxt.visible = false;

        // Hide countdown/ready sprites
        if (countdownReady != null) countdownReady.visible = false;
        if (countdownSet != null) countdownSet.visible = false;
        if (countdownGo != null) countdownGo.visible = false;

        // Keep time bar visible but make it less prominent
        if (timeBar != null) {
            timeBar.alpha = 0.5;
            timeBar.y = FlxG.height - 30; // Move to bottom
        }
        if (timeTxt != null) {
            timeTxt.alpha = 0.5;
            timeTxt.y = FlxG.height - 25;
        }

        // Disable pause menu
        canPause = false;
    }

    function setupEditorCamera() {
        // Create a separate camera for editor UI
        editorCamera = new FlxCamera();
        editorCamera.bgColor.alpha = 0;
        FlxG.cameras.add(editorCamera, false);
    }

    function setupEditorUI() {
        // Timeline display
        timelineText = new FlxText(10, 10, 300, "Time: 0.00s");
        timelineText.setFormat(null, 16, FlxColor.WHITE);
        timelineText.cameras = [editorCamera];
        add(timelineText);

        // Status display
        statusText = new FlxText(10, 40, 300, "Status: Paused");
        statusText.setFormat(null, 16, FlxColor.WHITE);
        statusText.cameras = [editorCamera];
        add(statusText);

        // Help text
        helpText = new FlxText(10, FlxG.height - 100, FlxG.width - 20, getHelpText());
        helpText.setFormat(null, 12, FlxColor.WHITE);
        helpText.cameras = [editorCamera];
        add(helpText);
    }

    function setupEditorDrawer() {
        // Create drawer on the right side
        editorDrawer = new PsychUIDrawer(camGame, RIGHT, 350);
        editorDrawer.cameras = [editorCamera];
        add(editorDrawer);

        // Add tabs for different editing modes
        setupModchartTab();
        setupStrumTab();
        setupNotesTab();
        setupExportTab();
    }

    function setupModchartTab() {
        var modchartTab = editorDrawer.addDrawerTab("Modchart");

        // Add top tabs for modchart effects
        modchartTab.addTopTab("Transform");
        modchartTab.addTopTab("Visual");
        modchartTab.addTopTab("Movement");
        modchartTab.addTopTab("Custom");

        // Transform tab - position, rotation, scale
        var transformTab = modchartTab.getTopTab("Transform");
        if (transformTab != null) {
            // Add UI elements for transform editing
            // Position controls: transformX, transformY, transformZ
            // Rotation controls: roll, confusion, spin
            // Scale controls: scaleX, scaleY, scale
        }

        // Visual tab - alpha, color, effects
        var visualTab = modchartTab.getTopTab("Visual");
        if (visualTab != null) {
            // Alpha controls: alpha, vanish, sudden, blink
            // Color effects: flash, invert
            // Visual mods: stealth, dark, cover
        }

        // Movement tab - note movement patterns
        var movementTab = modchartTab.getTopTab("Movement");
        if (movementTab != null) {
            // Movement mods: drunk, tipsy, bumpy
            // Path mods: tornado, zigzag, sawtooth
            // Scroll mods: reverse, split, cross
        }
    }

    function setupStrumTab() {
        var strumTab = editorDrawer.addDrawerTab("Strums");

        strumTab.addTopTab("Position");
        strumTab.addTopTab("Rotation");
        strumTab.addTopTab("Scale");
        strumTab.addTopTab("Animation");

        // Position tab - strum positioning
        var positionTab = strumTab.getTopTab("Position");
        if (positionTab != null) {
            // UI for strum positioning: x, y, z offsets
            // Snap controls, centered, split, cross
        }

        // Rotation tab - strum rotation
        var rotationTab = strumTab.getTopTab("Rotation");
        if (rotationTab != null) {
            // UI for strum rotation: roll, confusion
            // Receptor scroll, field rotation
        }
    }

    function setupNotesTab() {
        var notesTab = editorDrawer.addDrawerTab("Notes");

        notesTab.addTopTab("Movement");
        notesTab.addTopTab("Visual");
        notesTab.addTopTab("Speed");
        notesTab.addTopTab("Patterns");

        // Movement tab - note movement effects
        var movementTab = notesTab.getTopTab("Movement");
        if (movementTab != null) {
            // UI for note movement: drunk, tipsy, bumpy
            // Wave effects: tornado, spiral, zigzag
        }

        // Visual tab - note visual effects
        var visualTab = notesTab.getTopTab("Visual");
        if (visualTab != null) {
            // UI for note visuals: alpha, stealth, sudden
            // Note coloring, glow effects
        }

        // Speed tab - note speed modifications
        var speedTab = notesTab.getTopTab("Speed");
        if (speedTab != null) {
            // UI for speed: cmod, xmod, note speed
            // Acceleration effects
        }
    }

    function setupExportTab() {
        var exportTab = editorDrawer.addDrawerTab("Export");

        exportTab.addTopTab("HScript");
        exportTab.addTopTab("JSON");
        exportTab.addTopTab("Import");
        exportTab.addTopTab("Settings");

        // HScript export tab
        var hscriptTab = exportTab.getTopTab("HScript");
        if (hscriptTab != null) {
            // UI for HScript export options
            // Export button, preview, save location
        }

        // JSON export tab
        var jsonTab = exportTab.getTopTab("JSON");
        if (jsonTab != null) {
            // UI for JSON export options
            // Export button, format options
        }

        // Import tab for loading existing modcharts
        var importTab = exportTab.getTopTab("Import");
        if (importTab != null) {
            // UI for importing modchart files
            // File browser, load button
        }

        // Settings tab for editor preferences
        var settingsTab = exportTab.getTopTab("Settings");
        if (settingsTab != null) {
            // UI for editor settings
            // Grid options, snap settings, etc.
        }
    }

    override function update(elapsed:Float) {
        // Update current time
        if (isPlaying && FlxG.sound.music != null) {
            currentTime = Conductor.songPosition / 1000;
        }

        // Ensure all playfields remain in autoplay mode
        for (field in playfields.members) {
            if (field != null && !field.autoPlayed) {
                field.autoPlayed = true;
            }
        }

        handleEditorInput();
        updateUI();

        super.update(elapsed);
    }

    // Override pause functionality to prevent normal pause menu
    override function openPauseMenu() {
        // Do nothing - prevent pause menu from opening
        return;
    }

    // Override substate opening to prevent pause menu
    override function openSubState(SubState:flixel.FlxSubState) {
        // Only allow specific substates if needed for the editor
        // Block all others to prevent normal PlayState substates
        return;
    }

    function handleEditorInput() {
        // Spacebar to play/pause
        if (FlxG.keys.justPressed.SPACE) {
            togglePlayback();
        }

        // Arrow keys for timeline navigation
        if (FlxG.keys.pressed.LEFT) {
            seekTime(-FlxG.elapsed);
        }
        if (FlxG.keys.pressed.RIGHT) {
            seekTime(FlxG.elapsed);
        }

        // Escape to exit editor
        if (FlxG.keys.justPressed.ESCAPE) {
            exitEditor();
        }

        // Tab to toggle drawer
        if (FlxG.keys.justPressed.TAB) {
            editorDrawer.toggleDrawer();
        }

        // Number keys to switch drawer tabs
        if (FlxG.keys.justPressed.ONE) {
            editorDrawer.toggleDrawer(0);
        }
        if (FlxG.keys.justPressed.TWO) {
            editorDrawer.toggleDrawer(1);
        }
        if (FlxG.keys.justPressed.THREE) {
            editorDrawer.toggleDrawer(2);
        }
        if (FlxG.keys.justPressed.FOUR) {
            editorDrawer.toggleDrawer(3);
        }

        // Mouse interaction for selecting strums/notes
        if (FlxG.mouse.justPressed) {
            selectObjectUnderMouse();
        }
    }

    function togglePlayback() {
        if (isPlaying) {
            FlxG.sound.music.pause();
            vocals.pause();
            isPlaying = false;
        } else {
            FlxG.sound.music.resume();
            vocals.resume();
            isPlaying = true;
        }
    }

    function seekTime(offset:Float) {
        currentTime = Math.max(0, Math.min(currentTime + offset, FlxG.sound.music.length / 1000));

        // Sync all audio sources
        FlxG.sound.music.time = currentTime * 1000;
        vocals.time = currentTime * 1000;

        // Sync additional vocal tracks if they exist
        if (opponentVocals != null) {
            opponentVocals.time = currentTime * 1000;
        }
        if (gfVocals != null) {
            gfVocals.time = currentTime * 1000;
        }

        // Update conductor position
        Conductor.songPosition = currentTime * 1000;

        // Resync vocals to ensure they stay in sync
        resyncVocals();
    }

    function selectObjectUnderMouse() {
        // Check for strum note selection
        for (field in playfields.members) {
            if (field == null) continue;

            for (strum in field.strumNotes) {
                if (FlxG.mouse.overlaps(strum, camGame)) {
                    selectedStrumNote = strum;
                    selectedNote = null;
                    return;
                }
            }
        }

        // Check for note selection
        for (note in notes.members) {
            if (note != null && FlxG.mouse.overlaps(note, camGame)) {
                selectedNote = note;
                selectedStrumNote = null;
                return;
            }
        }

        // Clear selection if nothing was clicked
        selectedStrumNote = null;
        selectedNote = null;
    }

    function updateUI() {
        timelineText.text = "Time: " + Math.round(currentTime * 100) / 100 + "s";
        statusText.text = "Status: " + (isPlaying ? "Playing" : "Paused");

        if (selectedStrumNote != null) {
            statusText.text += " | Selected: Strum " + selectedStrumNote.noteData;
        } else if (selectedNote != null) {
            statusText.text += " | Selected: Note " + selectedNote.noteData;
        }
    }

    function getHelpText():String {
        return "CONTROLS:\n" +
               "SPACE - Play/Pause\n" +
               "LEFT/RIGHT - Seek timeline\n" +
               "TAB - Toggle drawer\n" +
               "1-4 - Switch drawer tabs\n" +
               "MOUSE - Select strums/notes\n" +
               "ESC - Exit editor";
    }

    function exitEditor() {
        // Save work if needed
        FlxG.switchState(() -> new MainMenuState());
    }

    // Modchart event creation and management
    public function addModchartEvent(type:String, time:Float, target:String, value:Dynamic, ?ease:String = "linear", ?endTime:Float = -1) {
        var stepTime = time * (Conductor.bpm / 60) * 4;

        if (endTime > 0) {
            var endStep = endTime * (Conductor.bpm / 60) * 4;
            // Use queueEase for animated changes
            modManager.queueEase(stepTime, endStep, target, value, ease, getPlayerFromTarget(target));
        } else {
            // Use queueSet for instant changes
            modManager.queueSet(stepTime, target, value, getPlayerFromTarget(target));
        }

        var event:ModchartEvent = {
            type: type,
            time: time,
            endTime: endTime,
            target: target,
            value: value,
            ease: ease
        };
        modchartData.push(event);
        modchartData.sort((a, b) -> Std.int((a.time - b.time) * 1000));
    }

    function getPlayerFromTarget(target:String):Int {
        // Determine player based on target name
        if (target.contains("opponent") || target.contains("dad") || target.contains("1")) {
            return 1; // Opponent
        } else if (target.contains("player") || target.contains("bf") || target.contains("0")) {
            return 0; // Player
        }
        return -1; // Both players
    }

    public function exportModchart(format:String = "hscript"):String {
        if (format == "hscript") {
            return exportAsHScript();
        } else {
            return exportAsJSON();
        }
    }

    function exportAsHScript():String {
        var script = "// Generated Modchart Script\n\n";
        script += "function loadModchart() {\n";
        script += "    if (!getPropertyFromClass('backend.ClientPrefs', 'data.modcharts')) return;\n\n";

        for (event in modchartData) {
            var step = Math.round(event.time * (Conductor.bpm / 60) * 4);
            if (event.endTime > 0) {
                var endStep = Math.round(event.endTime * (Conductor.bpm / 60) * 4);
                script += "    queueEase(" + step + ", " + endStep + ", '" + event.target + "', " + event.value + ", '" + event.ease + "');\n";
            } else {
                script += "    queueSet(" + step + ", '" + event.target + "', " + event.value + ");\n";
            }
        }

        script += "}\n\n";
        script += "function onCreate() {\n";
        script += "    loadModchart();\n";
        script += "}\n";

        return script;
    }

    function exportAsJSON():String {
        return haxe.Json.stringify(modchartData, null, "    ");
    }

    function generateHScriptCall(event:ModchartEvent):String {
        if (event.endTime > 0) {
            var step = Math.round(event.time * (Conductor.bpm / 60) * 4);
            var endStep = Math.round(event.endTime * (Conductor.bpm / 60) * 4);
            return 'queueEase(' + step + ', ' + endStep + ', "' + event.target + '", ' + event.value + ', "' + event.ease + '");';
        } else {
            var step = Math.round(event.time * (Conductor.bpm / 60) * 4);
            return 'queueSet(' + step + ', "' + event.target + '", ' + event.value + ');';
        }
    }

    override function destroy() {
        if (editorCamera != null) {
            FlxG.cameras.remove(editorCamera);
            editorCamera = null;
        }

        editorDrawer = null;
        modchartData = null;
        selectedStrumNote = null;
        selectedNote = null;

        super.destroy();
    }
}

// Data structure for modchart events
typedef ModchartEvent = {
    var type:String;
    var time:Float;
    var endTime:Float;
    var target:String;
    var value:Dynamic;
    var ease:String;
}
