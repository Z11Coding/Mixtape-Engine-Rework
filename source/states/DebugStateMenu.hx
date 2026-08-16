package states;

import backend.MusicBeatState;
import backend.WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.match3.Match3TestState;
import games.uno.beta.APUnoBetaTrapState;
import games.uno.beta.UnoBetaState;
import objects.Alphabet;
import shop.DaShop;
import states.MainMenuState;
// import states.MicrophoneTestState;
import states.freeplay.VSliceFreeplayMidState;
import yutautil.StatePick;
import yutautil.games.pong.PongTestState;

/**
 * Debug State Menu - Access any state in the engine for testing and debugging
 */
class DebugStateMenu extends MusicBeatState {
    private var stateEntries:Array<StateEntry> = [];
    private var grpTexts:FlxTypedGroup<Alphabet>;
    private var curSelected:Int = 0;
    private var searchText:FlxText;
    private var searchString:String = "";
    private var filteredEntries:Array<StateEntry> = [];
    private var displayEntries:Array<DisplayEntry> = []; // Includes categories and states
    private var infoText:FlxText;
    private var helpText:FlxText;

    override function create() {
        super.create();

        FlxG.camera.bgColor = FlxColor.BLACK;

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Debug State Menu", "Browsing states");
        #end

        setupBackground();
        setupStateList();
        setupUI();
        updateDisplay();

        FlxG.mouse.visible = false;
    }

    private function setupBackground():Void {
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
        bg.scrollFactor.set();
        bg.color = 0xFF1a1a1a; // Darker background for debug feel
        add(bg);
    }

    private function setupStateList():Void {
        // Get all registered states from StatePick
        var musicBeatStates = StatePick.getStateNames("MusicBeatState");
        var flxStates = StatePick.getStateNames("FlxState");

        // Add MusicBeatState-based states
        for (stateName in musicBeatStates) {
            var stateClass = Type.resolveClass(stateName);
            if (stateClass != null) {
                var displayName = getDisplayName(stateName);
                var category = getStateCategory(stateName);
                stateEntries.push({
                    className: stateName,
                    displayName: displayName,
                    category: category,
                    stateClass: stateClass,
                    description: getStateDescription(stateName)
                });
            }
        }

        // Add FlxState-based states
        for (stateName in flxStates) {
            var stateClass = Type.resolveClass(stateName);
            if (stateClass != null && !isAlreadyAdded(stateName)) {
                var displayName = getDisplayName(stateName);
                var category = getStateCategory(stateName);
                stateEntries.push({
                    className: stateName,
                    displayName: displayName,
                    category: category,
                    stateClass: stateClass,
                    description: getStateDescription(stateName)
                });
            }
        }

        // Manually add some known states that might not be in StatePick
        addKnownStates();

        // Sort by category then by name
        stateEntries.sort(function(a, b) {
            if (a.category != b.category) {
                return a.category < b.category ? -1 : 1;
            }
            return a.displayName < b.displayName ? -1 : 1;
        });

        filteredEntries = stateEntries.copy();
    }

    private function addKnownStates():Void {
        var knownStates = [
            {className: "states.UnoTestState", displayName: "UNO Test State", category: "Games"},
            {className: "games.match3.Match3TestState", displayName: "Match 3 Game", category: "Games"},
            {className: "states.PlayState", displayName: "Play State", category: "Core"},
            {className: "states.MainMenuState", displayName: "Main Menu", category: "Core"},
            {className: "states.freeplay.FreeplayState", displayName: "Freeplay", category: "Core"},
            {className: "states.StoryMenuState", displayName: "Story Menu", category: "Core"},
            {className: "states.TitleState", displayName: "Title Screen", category: "Core"},
            {className: "states.CreditsState", displayName: "Credits", category: "Core"},
            {className: "states.ModsMenuState", displayName: "Mods Menu", category: "Core"},
            {className: "states.AchievementsMenuState", displayName: "Achievements", category: "Core"},
            {className: "states.editors.MasterEditorMenu", displayName: "Master Editor Menu", category: "Editors"},
            {className: "states.editors.ChartingState", displayName: "Chart Editor", category: "Editors"},
            {className: "states.editors.CharacterEditorState", displayName: "Character Editor", category: "Editors"},
            {className: "states.editors.StageEditorState", displayName: "Stage Editor", category: "Editors"},
            {className: "states.CameraTestState", displayName: "Camera Test", category: "Media"},
            {className: "states.MicrophoneTestState", displayName: "Microphone Test", category: "Media"},
            {className: "states.MediaComboTestState", displayName: "MediaCombo Test", category: "Media"},
            {className: "states.LoadingState", displayName: "Loading State", category: "Utility"},
            {className: "states.ErrorState", displayName: "Error State", category: "Utility"},
            {className: "flixel.FlxState", displayName: "Basic FlxState", category: "Framework"}
        ];

        for (known in knownStates) {
            if (!isAlreadyAdded(known.className)) {
                var stateClass = Type.resolveClass(known.className);
                if (stateClass != null) {
                    stateEntries.push({
                        className: known.className,
                        displayName: known.displayName,
                        category: known.category,
                        stateClass: stateClass,
                        description: getStateDescription(known.className)
                    });
                }
            }
        }
    }

    private function isAlreadyAdded(className:String):Bool {
        for (entry in stateEntries) {
            if (entry.className == className) {
                return true;
            }
        }
        return false;
    }

    private function getDisplayName(className:String):String {
        var parts = className.split(".");
        var simpleName = parts[parts.length - 1];

        // Add spaces before capital letters
        var displayName = "";
        for (i in 0...simpleName.length) {
            var char = simpleName.charAt(i);
            if (i > 0 && char.toUpperCase() == char && simpleName.charAt(i - 1).toLowerCase() == simpleName.charAt(i - 1)) {
                displayName += " ";
            }
            displayName += char;
        }

        return displayName;
    }

    private function getStateCategory(className:String):String {
        if (className.indexOf("editors") != -1) return "Editors";
        if (className.indexOf("substates") != -1) return "Substates";
        if (className.indexOf("freeplay") != -1) return "Freeplay";
        if (className.indexOf("debug") != -1) return "Debug";
        if (className.indexOf("options") != -1) return "Options";
        if (className.indexOf("UnoTest") != -1 || className.indexOf("match3") != -1 || className.indexOf("Match3") != -1) return "Games";
        if (className.indexOf("Camera") != -1 || className.indexOf("Microphone") != -1 || className.indexOf("Media") != -1) return "Media";
        if (className.indexOf("Play") != -1 || className.indexOf("Menu") != -1 || className.indexOf("Title") != -1) return "Core";
        if (className.indexOf("Loading") != -1 || className.indexOf("Error") != -1 || className.indexOf("Update") != -1) return "Utility";
        if (className.indexOf("flixel") != -1) return "Framework";

        return "Other";
    }

    private function getStateDescription(className:String):String {
        return switch(className) {
            case "states.UnoTestState": "Test implementation of UNO card game with custom colors and actions";
            case "games.match3.Match3TestState": "Complete Match 3 puzzle game with multiple modes, objectives, and power-ups";
            case "states.PlayState": "Main gameplay state where songs are played";
            case "states.MainMenuState": "Main menu of the game";
            case "states.TitleState": "Title screen with intro sequence";
            case "states.freeplay.FreeplayState": "Song selection screen for free play";
            case "states.StoryMenuState": "Story mode week selection";
            case "states.editors.MasterEditorMenu": "Hub for all game editors";
            case "states.editors.ChartingState": "Chart editor for creating/editing songs";
            case "states.editors.CharacterEditorState": "Character animation and offset editor";
            case "states.editors.StageEditorState": "Stage background and element editor";
            case "states.CameraTestState": "Test camera functionality with video feed and transmission to Flx objects";
            case "states.MicrophoneTestState": "Test microphone input with visual feedback and audio level monitoring";
            case "states.MediaComboTestState": "Test combined camera and microphone with synchronized audio-reactive effects";
            case "states.LoadingState": "Loading screen state";
            case "states.ErrorState": "Error display state";
            case _: "Game state: " + getDisplayName(className);
        }
    }

    private function setupUI():Void {
        // Title
        var titleText = new FlxText(0, 20, FlxG.width, "DEBUG STATE MENU", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        add(titleText);

        // Search bar
        var searchBG = new FlxSprite(20, 60).makeGraphic(FlxG.width - 40, 30, FlxColor.fromRGB(40, 40, 40));
        add(searchBG);

        searchText = new FlxText(25, 65, FlxG.width - 50, "Search: " + searchString, 16);
        searchText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        add(searchText);

        // State list
        grpTexts = new FlxTypedGroup<Alphabet>();
        add(grpTexts);

        // Info panel
        var infoBG = new FlxSprite(FlxG.width - 320, 100).makeGraphic(300, FlxG.height - 200, FlxColor.fromRGB(20, 20, 20));
        infoBG.alpha = 0.8;
        add(infoBG);

        infoText = new FlxText(FlxG.width - 310, 110, 280, "", 12);
        infoText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT);
        add(infoText);

        // Help text
        helpText = new FlxText(20, FlxG.height - 100, FlxG.width - 40,
            "ENTER: Go to State | BACKSPACE: Clear Search | ESC: Return to Main Menu\nR: Reload States | T: Test Crash Tracker | C: Generate Crash Report", 12);
        helpText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, CENTER);
        add(helpText);
    }

    private function updateDisplay():Void {
        grpTexts.clear();
        displayEntries = [];

        var startY = 110;
        var currentCategory = "";

        // Build display entries list
        for (i in 0...filteredEntries.length) {
            var entry = filteredEntries[i];

            // Add category header if new category
            if (entry.category != currentCategory) {
                currentCategory = entry.category;
                displayEntries.push({
                    type: CATEGORY,
                    text: "-- " + currentCategory + " --",
                    stateEntry: null
                });
            }

            // Add state entry
            displayEntries.push({
                type: STATE,
                text: entry.displayName,
                stateEntry: entry
            });
        }

        // Create UI elements
        for (i in 0...displayEntries.length) {
            var displayEntry = displayEntries[i];
            var alphabet:Alphabet;

            if (displayEntry.type == CATEGORY) {
                alphabet = new Alphabet(50, startY, displayEntry.text, true);
                alphabet.color = FlxColor.CYAN;
                alphabet.isMenuItem = true;
                alphabet.alpha = 0.8;
            } else {
                alphabet = new Alphabet(70, startY, displayEntry.text, true);
                alphabet.isMenuItem = true;
                alphabet.alpha = 0.6; // Default alpha, will be updated in update()
            }

            // Configure for responsive scrolling
            alphabet.ID = i;
            alphabet.targetY = i; // Initial position
            alphabet.distancePerItem.y = 80; // Tighter spacing for better responsiveness
            alphabet.isMenuItem = true; // Ensure menu item behavior

            grpTexts.add(alphabet);
        }

        // Update search text
        searchText.text = "Search: " + searchString + (searchString.length > 0 ? " (" + filteredEntries.length + " results)" : "");

        // Update info panel for current selection
        if (filteredEntries.length > 0 && curSelected >= 0 && curSelected < filteredEntries.length) {
            updateInfoPanel(filteredEntries[curSelected]);
        }
    }

    private function updateInfoPanel(entry:StateEntry):Void {
        var info = "State Information:\n\n";
        info += "Name: " + entry.displayName + "\n";
        info += "Category: " + entry.category + "\n";
        info += "Class: " + entry.className + "\n\n";
        info += "Description:\n" + entry.description + "\n\n";

        // Add safety warnings for certain states
        if (entry.className.indexOf("PlayState") != -1) {
            info += "WARNING: May require song to be loaded!\n\n";
        }
        if (entry.className.indexOf("Editor") != -1) {
            info += "INFO: This is an editor state.\n\n";
        }

        info += "Press ENTER to switch to this state.";

        infoText.text = info;
    }

    private function filterStates():Void {
        if (searchString.length == 0) {
            filteredEntries = stateEntries.copy();
        } else {
            filteredEntries = [];
            var searchLower = searchString.toLowerCase();

            for (entry in stateEntries) {
                if (entry.displayName.toLowerCase().indexOf(searchLower) != -1 ||
                    entry.category.toLowerCase().indexOf(searchLower) != -1 ||
                    entry.className.toLowerCase().indexOf(searchLower) != -1) {
                    filteredEntries.push(entry);
                }
            }
        }

        curSelected = 0;
        updateDisplay();
    }

    private function changeSelection(change:Int):Void {
        if (filteredEntries.length == 0) return;

        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curSelected = FlxMath.wrap(curSelected + change, 0, filteredEntries.length - 1);

        // Update info panel immediately for new selection
        if (curSelected >= 0 && curSelected < filteredEntries.length) {
            updateInfoPanel(filteredEntries[curSelected]);
        }
    }

    private function switchToSelectedState():Void {
        if (filteredEntries.length == 0) return;

        var selectedEntry = filteredEntries[curSelected];

        try {
            var newState = Type.createInstance(selectedEntry.stateClass, []);

            if (Std.isOfType(newState, MusicBeatState)) {
                MusicBeatState.switchState(cast newState);
            } else if (Std.isOfType(newState, flixel.FlxState)) {
                FlxG.switchState(cast newState);
            } else {
                FlxG.log.error("Invalid state type: " + selectedEntry.className);
                FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
            }
        } catch (e:Dynamic) {
            FlxG.log.error("Failed to create state " + selectedEntry.className + ": " + e);
            FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);

            // Show error message temporarily
            var errorText = new FlxText(20, FlxG.height - 120, FlxG.width - 40,
                "ERROR: Failed to load " + selectedEntry.displayName + " - " + Std.string(e), 14);
            errorText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.RED, CENTER);
            add(errorText);

            new FlxTimer().start(3.0, function(timer) {
                remove(errorText);
            });
        }
    }

    private function reloadStates():Void {
        stateEntries = [];
        setupStateList();
        filterStates();
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Update alphabet positions for scrolling (faster, more responsive)
        var selectedDisplayIndex = getSelectedDisplayIndex();
        for (num => item in grpTexts.members) {
            if (item != null) {
                var oldTargetY = item.targetY;
                item.targetY = num - selectedDisplayIndex;

                // For snappier scrolling, adjust distance per item for tighter spacing
                //item.distancePerItem.y = 80;

                // If this is a big jump (like when selection changes), snap immediately
                if (Math.abs(item.targetY - oldTargetY) > 3) {
                    item.snapToPosition();
                }

                // Set alpha based on position
                if (item.targetY == 0) {
                    item.alpha = 1.0;
                } else {
                    // Special handling for category headers
                    if (item.color == FlxColor.CYAN) {
                        item.alpha = 0.8;
                    } else {
                        item.alpha = 0.6;
                    }
                }
            }
        }

        // Update info panel for currently selected item
        if (filteredEntries.length > 0 && curSelected >= 0 && curSelected < filteredEntries.length) {
            updateInfoPanel(filteredEntries[curSelected]);
        }

        // Navigation
        if (controls.UI_UP_P) {
            changeSelection(-1);
        }
        if (controls.UI_DOWN_P) {
            changeSelection(1);
        }

        // Page up/down for faster navigation
        if (FlxG.keys.justPressed.PAGEUP) {
            changeSelection(-10);
        }
        if (FlxG.keys.justPressed.PAGEDOWN) {
            changeSelection(10);
        }

        // Actions
        if (controls.ACCEPT) {
            switchToSelectedState();
        }

        if (controls.BACK) {
            MusicBeatState.switchState(new MainMenuState());
        }

        // Search functionality
        if (FlxG.keys.justPressed.BACKSPACE) {
            if (searchString.length > 0) {
                searchString = searchString.substr(0, searchString.length - 1);
                filterStates();
            }
        }

        // Reload states
        if (FlxG.keys.justPressed.R) {
            reloadStates();
        }

        // Test crash tracker
        if (FlxG.keys.justPressed.T) {
            yutautil.CrashTrackerHelper.testCrashReporting();
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
        }

        // Generate crash report
        if (FlxG.keys.justPressed.C) {
            yutautil.CrashTrackerHelper.reportCrash("Manual crash report from Debug State Menu");
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);

            // Show confirmation
            var confirmText = new FlxText(20, FlxG.height - 140, FlxG.width - 40,
                "Crash report generated - check crash_logs folder", 14);
            confirmText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GREEN, CENTER);
            add(confirmText);

            new FlxTimer().start(3.0, function(timer) {
                remove(confirmText);
            });
        }

        // Handle text input for search (exclude R for reload)
        handleTextInput();
    }

    private function getSelectedDisplayIndex():Int {
        // Find the display index for the currently selected state
        var stateIndex = 0;
        for (i in 0...displayEntries.length) {
            if (displayEntries[i].type == STATE) {
                if (stateIndex == curSelected) {
                    return i;
                }
                stateIndex++;
            }
        }
        return 0;
    }

    private function handleTextInput():Void {
        var oldLength = searchString.length;

        // Handle alphanumeric input for search
        if (FlxG.keys.justPressed.A) searchString += "a";
        else if (FlxG.keys.justPressed.B) searchString += "b";
        else if (FlxG.keys.justPressed.C) searchString += "c";
        else if (FlxG.keys.justPressed.D) searchString += "d";
        else if (FlxG.keys.justPressed.E) searchString += "e";
        else if (FlxG.keys.justPressed.F) searchString += "f";
        else if (FlxG.keys.justPressed.G) searchString += "g";
        else if (FlxG.keys.justPressed.H) searchString += "h";
        else if (FlxG.keys.justPressed.I) searchString += "i";
        else if (FlxG.keys.justPressed.J) searchString += "j";
        else if (FlxG.keys.justPressed.K) searchString += "k";
        else if (FlxG.keys.justPressed.L) searchString += "l";
        else if (FlxG.keys.justPressed.M) searchString += "m";
        else if (FlxG.keys.justPressed.N) searchString += "n";
        else if (FlxG.keys.justPressed.O) searchString += "o";
        else if (FlxG.keys.justPressed.P) searchString += "p";
        else if (FlxG.keys.justPressed.Q) searchString += "q";
        // R is reserved for reload function
        else if (FlxG.keys.justPressed.S) searchString += "s";
        else if (FlxG.keys.justPressed.T) searchString += "t";
        else if (FlxG.keys.justPressed.U) searchString += "u";
        else if (FlxG.keys.justPressed.V) searchString += "v";
        else if (FlxG.keys.justPressed.W) searchString += "w";
        else if (FlxG.keys.justPressed.X) searchString += "x";
        else if (FlxG.keys.justPressed.Y) searchString += "y";
        else if (FlxG.keys.justPressed.Z) searchString += "z";
        else if (FlxG.keys.justPressed.SPACE) searchString += " ";
        else if (FlxG.keys.justPressed.ONE) searchString += "1";
        else if (FlxG.keys.justPressed.TWO) searchString += "2";
        else if (FlxG.keys.justPressed.THREE) searchString += "3";
        else if (FlxG.keys.justPressed.FOUR) searchString += "4";
        else if (FlxG.keys.justPressed.FIVE) searchString += "5";
        else if (FlxG.keys.justPressed.SIX) searchString += "6";
        else if (FlxG.keys.justPressed.SEVEN) searchString += "7";
        else if (FlxG.keys.justPressed.EIGHT) searchString += "8";
        else if (FlxG.keys.justPressed.NINE) searchString += "9";
        else if (FlxG.keys.justPressed.ZERO) searchString += "0";

        // Check if any text was added and update filter
        if (searchString.length != oldLength) {
            filterStates();
        }
    }
}

/**
 * Data structure for state entries
 */
typedef StateEntry = {
    var className:String;
    var displayName:String;
    var category:String;
    var stateClass:Class<Dynamic>;
    var description:String;
}

/**
 * Display entry type enum
 */
enum DisplayEntryType {
    CATEGORY;
    STATE;
}

/**
 * Data structure for display entries (categories and states)
 */
typedef DisplayEntry = {
    var type:DisplayEntryType;
    var text:String;
    var stateEntry:StateEntry;
}
