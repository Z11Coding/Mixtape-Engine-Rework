package setup;

import archipelago.substates.InfoPanelSubstate;
import backend.ClientPrefs;
import backend.Controls;
import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import haxe.Json;
import setup.SetupBaseState;
import sys.FileSystem;
import sys.io.File;

/**
 * Engine import setup that detects and imports settings from other FNF engines
 * Focuses on Psych Engine and other common engines
 */
class EngineImportSetup extends SetupBaseState {
    private var detectedEngines:Array<EngineData> = [];
    private var selectedEngine:Int = -1;
    private var engineButtons:Array<FlxSprite> = [];
    private var engineTexts:Array<FlxText> = [];

    override function create() {
        super.create();

        titleText.text = "Import Engine Settings";
        descText.text = "Scanning for other FNF engines to import settings from...\n\nThis can import your controls, graphics settings, and preferences from other engines.";

        totalSteps = 1;
        currentStep = 0;

        // Scan for engines
        scanForEngines();
        createEngineList();
    }

    function scanForEngines() {
        detectedEngines = [];

        // Check for Psych Engine
        var psychFiles = getAllPsychSaveFiles();
        if (psychFiles.length > 0) {
            detectedEngines.push({
                name: "Psych Engine",
                description: 'Original Psych Engine installation detected (${psychFiles.length} save file(s) found)',
                saveFile: "", // Will be selected by user
                engineType: "psych",
                availableFiles: psychFiles
            });
        }

        // Check for Kade Engine
        var kadeFiles = getAllKadeSaveFiles();
        if (kadeFiles.length > 0) {
            detectedEngines.push({
                name: "Kade Engine",
                description: 'Kade Engine installation detected (${kadeFiles.length} save file(s) found)',
                saveFile: "",
                engineType: "kade",
                availableFiles: kadeFiles
            });
        }

        // Check for other Psych Engine forks
        var forkFiles = getAllPsychForkFiles();
        if (forkFiles.length > 0) {
            detectedEngines.push({
                name: "Psych Engine Fork",
                description: 'Psych Engine fork detected (${forkFiles.length} save file(s) found)',
                saveFile: "",
                engineType: "psych_fork",
                availableFiles: forkFiles
            });
        }

        // Check for Funkin' Legacy
        var legacyFiles = getAllLegacySaveFiles();
        if (legacyFiles.length > 0) {
            detectedEngines.push({
                name: "Funkin' Legacy",
                description: 'Funkin\' Legacy installation detected (${legacyFiles.length} save file(s) found)',
                saveFile: "",
                engineType: "legacy",
                availableFiles: legacyFiles
            });
        }

        // If no engines detected, add manual option
        if (detectedEngines.length == 0) {
            detectedEngines.push({
                name: "Browse for Save File",
                description: "Manually select a save file from another engine",
                saveFile: "",
                engineType: "manual"
            });
        }

        // Always add skip option
        detectedEngines.push({
            name: "Skip Import",
            description: "Continue without importing settings",
            saveFile: "",
            engineType: "skip"
        });
    }

    function detectPsychEngine():Bool {
        // Check for Psych Engine FlxSave files (.sol) using correct ShadowMario paths
        var psychPaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\ShadowMario\\FunkinPsychEngine\\controls_v3.sol",
            Sys.getEnv("APPDATA") + "\\ShadowMario\\FunkinPsychEngine\\funkin.sol",
            Sys.getEnv("APPDATA") + "\\ShadowMario\\PsychEngine\\controls_v3.sol",
            Sys.getEnv("APPDATA") + "\\ShadowMario\\PsychEngine\\funkin.sol",
            Sys.getEnv("APPDATA") + "\\PsychEngine\\controls_v3.sol",
            Sys.getEnv("APPDATA") + "\\PsychEngine\\funkin.sol",
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario/FunkinPsychEngine/controls_v3.sol",
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario/FunkinPsychEngine/funkin.sol",
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario/PsychEngine/controls_v3.sol",
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario/PsychEngine/funkin.sol",
            Sys.getenv("HOME") + "/Library/Preferences/PsychEngine/controls_v3.sol",
            Sys.getenv("HOME") + "/Library/Preferences/PsychEngine/funkin.sol",
            #else
            Sys.getenv("HOME") + "/.local/share/ShadowMario/FunkinPsychEngine/controls_v3.sol",
            Sys.getenv("HOME") + "/.local/share/ShadowMario/FunkinPsychEngine/funkin.sol",
            Sys.getenv("HOME") + "/.local/share/ShadowMario/PsychEngine/controls_v3.sol",
            Sys.getenv("HOME") + "/.local/share/ShadowMario/PsychEngine/funkin.sol",
            Sys.getenv("HOME") + "/.local/share/PsychEngine/controls_v3.sol",
            Sys.getenv("HOME") + "/.local/share/PsychEngine/funkin.sol"
            #end
        ];

        for (path in psychPaths) {
            if (FileSystem.exists(path)) {
                return true;
            }
        }

        return false;
    }

    function getAllPsychSaveFiles():Array<String> {
        var foundFiles:Array<String> = [];
        var basePaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\ShadowMario\\FunkinPsychEngine",
            Sys.getEnv("APPDATA") + "\\ShadowMario\\PsychEngine",
            Sys.getEnv("APPDATA") + "\\PsychEngine",
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario/FunkinPsychEngine",
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario/PsychEngine",
            Sys.getenv("HOME") + "/Library/Preferences/PsychEngine",
            #else
            Sys.getenv("HOME") + "/.local/share/ShadowMario/FunkinPsychEngine",
            Sys.getenv("HOME") + "/.local/share/ShadowMario/PsychEngine",
            Sys.getenv("HOME") + "/.local/share/PsychEngine"
            #end
        ];

        // Check all possible Psych save files in all base paths
        var possibleFiles = ["controls_v3.sol", "funkin.sol", "controls_v2.sol", "controls.sol", "psychengine.sol"];

        for (basePath in basePaths) {
            for (file in possibleFiles) {
                var fullPath = basePath + "/" + file;
                if (FileSystem.exists(fullPath) && foundFiles.indexOf(fullPath) == -1) {
                    foundFiles.push(fullPath);
                }
            }
        }

        return foundFiles;
    }

    function detectKadeEngine():Bool {
        // Kade Engine uses different save system, check for FlxSave files
        var kadePaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\KadeEngine\\save.sol",
            Sys.getEnv("APPDATA") + "\\ninjamuffin99\\Kade Engine\\save.sol",
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/KadeEngine/save.sol",
            Sys.getenv("HOME") + "/Library/Preferences/ninjamuffin99/Kade Engine/save.sol",
            #else
            Sys.getenv("HOME") + "/.local/share/KadeEngine/save.sol",
            Sys.getenv("HOME") + "/.local/share/ninjamuffin99/Kade Engine/save.sol"
            #end
        ];

        for (path in kadePaths) {
            if (FileSystem.exists(path)) {
                return true;
            }
        }

        return false;
    }

    function getAllKadeSaveFiles():Array<String> {
        var foundFiles:Array<String> = [];
        var basePaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\KadeEngine",
            Sys.getEnv("APPDATA") + "\\ninjamuffin99\\Kade Engine",
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/KadeEngine",
            Sys.getenv("HOME") + "/Library/Preferences/ninjamuffin99/Kade Engine",
            #else
            Sys.getenv("HOME") + "/.local/share/KadeEngine",
            Sys.getenv("HOME") + "/.local/share/ninjamuffin99/Kade Engine"
            #end
        ];

        var possibleFiles = ["save.sol", "controls.sol", "kade.sol"];

        for (basePath in basePaths) {
            for (file in possibleFiles) {
                var fullPath = basePath + "/" + file;
                if (FileSystem.exists(fullPath) && foundFiles.indexOf(fullPath) == -1) {
                    foundFiles.push(fullPath);
                }
            }
        }

        return foundFiles;
    }

    function detectPsychForks():Bool {
        // Check for other Psych Engine forks and variants
        var forkPaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\ShadowMario",
            Sys.getEnv("APPDATA") + "\\PsychEngine",
            Sys.getEnv("APPDATA") + "\\FunkinCrew", // For Funkin' Crew builds
            Sys.getEnv("APPDATA") + "\\Psych Engine", // Space variant
            Sys.getEnv("APPDATA") + "\\YoshiCrafter29\\CodenameEngine", // Codename Engine
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario",
            Sys.getenv("HOME") + "/Library/Preferences/PsychEngine",
            Sys.getenv("HOME") + "/Library/Preferences/FunkinCrew",
            Sys.getenv("HOME") + "/Library/Preferences/Psych Engine",
            Sys.getenv("HOME") + "/Library/Preferences/YoshiCrafter29/CodenameEngine",
            #else
            Sys.getenv("HOME") + "/.local/share/ShadowMario",
            Sys.getenv("HOME") + "/.local/share/PsychEngine",
            Sys.getenv("HOME") + "/.local/share/FunkinCrew",
            Sys.getenv("HOME") + "/.local/share/Psych Engine",
            Sys.getenv("HOME") + "/.local/share/YoshiCrafter29/CodenameEngine"
            #end
        ];

        for (basePath in forkPaths) {
            if (FileSystem.exists(basePath) && FileSystem.isDirectory(basePath)) {
                try {
                    var dirs = FileSystem.readDirectory(basePath);
                    for (dir in dirs) {
                        var dirPath = haxe.io.Path.join([basePath, dir]);
                        if (FileSystem.isDirectory(dirPath)) {
                            var files = FileSystem.readDirectory(dirPath);
                            for (file in files) {
                                if (file.endsWith(".sol")) {
                                    return true;
                                }
                            }
                        }
                    }
                } catch (e:Dynamic) {
                    // Continue if directory can't be read
                }
            }
        }

        return false;
    }

    function getAllPsychForkFiles():Array<String> {
        var foundFiles:Array<String> = [];
        var forkPaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\ShadowMario",
            Sys.getEnv("APPDATA") + "\\PsychEngine",
            Sys.getEnv("APPDATA") + "\\FunkinCrew",
            Sys.getEnv("APPDATA") + "\\Psych Engine",
            Sys.getEnv("APPDATA") + "\\YoshiCrafter29\\CodenameEngine",
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/ShadowMario",
            Sys.getenv("HOME") + "/Library/Preferences/PsychEngine",
            Sys.getenv("HOME") + "/Library/Preferences/FunkinCrew",
            Sys.getenv("HOME") + "/Library/Preferences/Psych Engine",
            Sys.getenv("HOME") + "/Library/Preferences/YoshiCrafter29/CodenameEngine",
            #else
            Sys.getenv("HOME") + "/.local/share/ShadowMario",
            Sys.getenv("HOME") + "/.local/share/PsychEngine",
            Sys.getenv("HOME") + "/.local/share/FunkinCrew",
            Sys.getenv("HOME") + "/.local/share/Psych Engine",
            Sys.getenv("HOME") + "/.local/share/YoshiCrafter29/CodenameEngine"
            #end
        ];

        for (basePath in forkPaths) {
            if (FileSystem.exists(basePath) && FileSystem.isDirectory(basePath)) {
                try {
                    var dirs = FileSystem.readDirectory(basePath);
                    for (dir in dirs) {
                        var dirPath = haxe.io.Path.join([basePath, dir]);
                        if (FileSystem.isDirectory(dirPath)) {
                            var files = FileSystem.readDirectory(dirPath);
                            for (file in files) {
                                if (file.endsWith(".sol")) {
                                    var fullPath = haxe.io.Path.join([dirPath, file]);
                                    if (foundFiles.indexOf(fullPath) == -1) {
                                        foundFiles.push(fullPath);
                                    }
                                }
                            }
                        }
                    }
                } catch (e:Dynamic) {
                    // Continue if directory can't be read
                }
            }
        }

        return foundFiles;
    }

    function detectFunkinLegacy():Bool {
        // Check for Funkin' Legacy (and other common engines) save locations
        var legacyPaths = [
            #if windows
            Sys.getEnv("APPDATA") + "\\FunkinLegacy\\save.sol",
            Sys.getEnv("APPDATA") + "\\ModdingPlus\\save.sol",
            Sys.getEnv("APPDATA") + "\\MicUp\\save.sol",
            Sys.getEnv("APPDATA") + "\\Leather128\\LeatherEngine\\save.sol",
            #elseif mac
            Sys.getenv("HOME") + "/Library/Preferences/FunkinLegacy/save.sol",
            Sys.getenv("HOME") + "/Library/Preferences/ModdingPlus/save.sol",
            Sys.getenv("HOME") + "/Library/Preferences/MicUp/save.sol",
            Sys.getenv("HOME") + "/Library/Preferences/Leather128/LeatherEngine/save.sol",
            #else
            Sys.getenv("HOME") + "/.local/share/FunkinLegacy/save.sol",
            Sys.getenv("HOME") + "/.local/share/ModdingPlus/save.sol",
            Sys.getenv("HOME") + "/.local/share/MicUp/save.sol",
            Sys.getenv("HOME") + "/.local/share/Leather128/LeatherEngine/save.sol"
            #end
        ];

        for (path in legacyPaths) {
            if (FileSystem.exists(path)) {
                return true;
            }
        }

        return false;
    }

    function getAllLegacySaveFiles():Array<String> {
        var foundFiles:Array<String> = [];
        var basePaths = [
            #if windows
            ["FunkinLegacy", Sys.getEnv("APPDATA") + "\\FunkinLegacy"],
            ["ModdingPlus", Sys.getEnv("APPDATA") + "\\ModdingPlus"],
            ["MicUp", Sys.getEnv("APPDATA") + "\\MicUp"],
            ["LeatherEngine", Sys.getEnv("APPDATA") + "\\Leather128\\LeatherEngine"],
            #elseif mac
            ["FunkinLegacy", Sys.getenv("HOME") + "/Library/Preferences/FunkinLegacy"],
            ["ModdingPlus", Sys.getenv("HOME") + "/Library/Preferences/ModdingPlus"],
            ["MicUp", Sys.getenv("HOME") + "/Library/Preferences/MicUp"],
            ["LeatherEngine", Sys.getenv("HOME") + "/Library/Preferences/Leather128/LeatherEngine"],
            #else
            ["FunkinLegacy", Sys.getenv("HOME") + "/.local/share/FunkinLegacy"],
            ["ModdingPlus", Sys.getenv("HOME") + "/.local/share/ModdingPlus"],
            ["MicUp", Sys.getenv("HOME") + "/.local/share/MicUp"],
            ["LeatherEngine", Sys.getenv("HOME") + "/.local/share/Leather128/LeatherEngine"]
            #end
        ];

        var possibleFiles = ["save.sol", "settings.sol", "preferences.sol"];

        for (engineInfo in basePaths) {
            var basePath = engineInfo[1];
            if (FileSystem.exists(basePath)) {
                for (file in possibleFiles) {
                    var fullPath = basePath + "/" + file;
                    if (FileSystem.exists(fullPath) && foundFiles.indexOf(fullPath) == -1) {
                        foundFiles.push(fullPath);
                    }
                }
            }
        }

        return foundFiles;
    }

    function createEngineList() {
        var startY = 250;
        var buttonHeight = 80;
        var buttonSpacing = 10;

        for (i in 0...detectedEngines.length) {
            var engine = detectedEngines[i];
            var buttonY = startY + i * (buttonHeight + buttonSpacing);

            // Button background
            var button = new FlxSprite(FlxG.width * 0.1, buttonY);
            button.makeGraphic(Std.int(FlxG.width * 0.8), buttonHeight,
                i == selectedEngine ? FlxColor.fromRGB(80, 120, 180) : FlxColor.fromRGB(50, 50, 80));
            button.alpha = 0.8;
            add(button);
            engineButtons.push(button);

            // Engine name
            var nameText = new FlxText(button.x + 20, button.y + 10, button.width - 40, engine.name);
            nameText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT);
            nameText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
            add(nameText);
            engineTexts.push(nameText);

            // Engine description
            var descText = new FlxText(button.x + 20, button.y + 35, button.width - 40, engine.description);
            descText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.fromRGB(200, 200, 200), LEFT);
            descText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            add(descText);
            engineTexts.push(descText);

            // Save file path (if available)
            if (engine.saveFile != "" && engine.engineType != "skip" && engine.engineType != "manual") {
                var pathText = new FlxText(button.x + 20, button.y + 55, button.width - 40, engine.saveFile);
                pathText.setFormat(Paths.font('vcr.ttf'), 10, FlxColor.fromRGB(150, 150, 150), LEFT);
                pathText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
                add(pathText);
                engineTexts.push(pathText);
            }
        }

        // Auto-select first option if available
        if (detectedEngines.length > 0) {
            selectedEngine = 0;
            updateEngineSelection();
        }
    }

    function updateEngineSelection() {
        for (i in 0...engineButtons.length) {
            var isSelected = i == selectedEngine;
            engineButtons[i].color = isSelected ? FlxColor.fromRGB(80, 120, 180) : FlxColor.fromRGB(50, 50, 80);
        }
    }

    override function update(elapsed:Float) {
        if (canNavigate) {
            // Handle selection
            if (controls.UI_UP_P || FlxG.keys.justPressed.UP) {
                selectedEngine = (selectedEngine - 1 + detectedEngines.length) % detectedEngines.length;
                updateEngineSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }
            else if (controls.UI_DOWN_P || FlxG.keys.justPressed.DOWN) {
                selectedEngine = (selectedEngine + 1) % detectedEngines.length;
                updateEngineSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }

            // Mouse selection
            for (i in 0...engineButtons.length) {
                if (FlxG.mouse.overlaps(engineButtons[i])) {
                    if (selectedEngine != i) {
                        selectedEngine = i;
                        updateEngineSelection();
                    }

                    if (FlxG.mouse.justPressed) {
                        selectEngine();
                        return;
                    }
                }
            }
        }

        super.update(elapsed);
    }

    override function onNext() {
        selectEngine();
    }

    function selectEngine() {
        if (!canNavigate || selectedEngine == -1) return;

        var engine = detectedEngines[selectedEngine];

        switch (engine.engineType) {
            case "skip":
                // Skip import and return to previous setup
                returnToPreviousSetup();

            case "manual":
                // Open file browser (not implemented, just skip for now)
                showResult("Manual file selection not yet implemented. Skipping import.");

            default:
                // Try to import from the selected engine
                importFromEngine(engine);
        }
    }

    function importFromEngine(engine:EngineData) {
        canNavigate = false;

        // Check if we need to ask the user which file to use
        if (engine.availableFiles != null && engine.availableFiles.length > 1) {
            showFileSelectionDialog(engine);
        } else if (engine.availableFiles != null && engine.availableFiles.length == 1) {
            // Only one file, use it directly
            performImportFromFile(engine.availableFiles[0], engine);
        } else {
            // No files or using old system - fallback to engine.saveFile
            performImportFromFile(engine.saveFile, engine);
        }
    }

    function showFileSelectionDialog(engine:EngineData) {
        var fileList = "";
        for (i in 0...engine.availableFiles.length) {
            var fileName = haxe.io.Path.withoutDirectory(engine.availableFiles[i]);
            fileList += '${i + 1}. ${fileName}\n';
        }

        var message = 'Multiple ${engine.name} save files found:\n\n${fileList}\nWhich file would you like to import settings from?';

        // Create a simple selection system - for now, we'll use the first file
        // In a full implementation, you'd create a proper selection UI
        var selectedFile = engine.availableFiles[0]; // Default to first file

        performImportFromFile(selectedFile, engine);
    }

    function performImportFromFile(filePath:String, engine:EngineData) {
        try {
            // Use comprehensive import with proper FlxSave handling
            var success = performComprehensiveImport(filePath, engine.engineType);

            if (success) {
                showResult("Successfully imported settings from " + engine.name + "!");
            } else {
                showResult("Failed to import settings from " + engine.name + ". Using defaults.");
            }
        } catch (e:Dynamic) {
            showResult("Error importing from " + engine.name + ": " + e + "\nUsing defaults.");
        }
    }

    function importPsychSettings(savePath:String):Bool {
        if (!FileSystem.exists(savePath)) return false;

        try {
            // Create a temporary FlxSave to load the foreign save data
            var tempSave = new FlxSave();

            // Use mergeDataFrom to load the foreign save file directly
            if (tempSave.mergeDataFrom(savePath)) {

                // Import graphics settings
                if (tempSave.data.antialiasing != null)
                    ClientPrefs.data.antialiasing = tempSave.data.antialiasing;
                if (tempSave.data.lowQuality != null)
                    ClientPrefs.data.lowQuality = tempSave.data.lowQuality;
                if (tempSave.data.globalAntialiasing != null)
                    ClientPrefs.data.antialiasing = tempSave.data.globalAntialiasing;
                if (tempSave.data.framerate != null)
                    ClientPrefs.data.framerate = Std.int(Math.max(60, Math.min(240, tempSave.data.framerate)));

                // Import gameplay settings
                if (tempSave.data.downScroll != null)
                    ClientPrefs.data.downScroll = tempSave.data.downScroll;
                if (tempSave.data.middleScroll != null)
                    ClientPrefs.data.middleScroll = tempSave.data.middleScroll;
                if (tempSave.data.ghostTapping != null)
                    ClientPrefs.data.ghostTapping = tempSave.data.ghostTapping;
                if (tempSave.data.hideHud != null)
                    ClientPrefs.data.hideHud = tempSave.data.hideHud;
                if (tempSave.data.timeBarType != null)
                    ClientPrefs.data.timeBarType = tempSave.data.timeBarType;
                if (tempSave.data.scoreZoom != null)
                    ClientPrefs.data.scoreZoom = tempSave.data.scoreZoom;
                if (tempSave.data.noReset != null)
                    ClientPrefs.data.noReset = tempSave.data.noReset;
                if (tempSave.data.healthBarAlpha != null)
                    ClientPrefs.data.healthBarAlpha = tempSave.data.healthBarAlpha;
                if (tempSave.data.comboOffset != null && Std.isOfType(tempSave.data.comboOffset, Array))
                    ClientPrefs.data.comboOffset = tempSave.data.comboOffset.copy();

                // Import audio settings
                if (tempSave.data.hitsoundVolume != null)
                    ClientPrefs.data.hitsoundVolume = tempSave.data.hitsoundVolume;
                if (tempSave.data.pauseMusic != null)
                    ClientPrefs.data.pauseMusic = tempSave.data.pauseMusic;
                if (tempSave.data.checkForUpdates != null)
                    ClientPrefs.data.checkForUpdates = tempSave.data.checkForUpdates;

                // Import visual settings
                if (tempSave.data.camZooms != null)
                    ClientPrefs.data.camZooms = tempSave.data.camZooms;
                if (tempSave.data.showFPS != null)
                    ClientPrefs.data.showFPS = tempSave.data.showFPS;
                if (tempSave.data.flashing != null)
                    ClientPrefs.data.flashing = tempSave.data.flashing;
                if (tempSave.data.autoPause != null)
                    ClientPrefs.data.autoPause = tempSave.data.autoPause;

                // Import language/misc settings
                if (tempSave.data.language != null)
                    ClientPrefs.data.language = tempSave.data.language;

                // Try to import controls if available
                importControlsFromSave(tempSave, "ShadowMario", savePath);

                // Clean up temporary save
                tempSave.destroy();
                tempSave = null;

                // Save imported settings
                ClientPrefs.saveSettings();

                return true;
            }
        } catch (e:Dynamic) {
            trace('Error importing Psych settings: $e');
            return false;
        }

        return false;
    }

    function importControlsFromSave(tempSave:FlxSave, company:String, saveFile:String) {
        // Try to import controls from a separate controls save
        var controlsSave = new FlxSave();
        var controlsFiles = ["controls_v3", "controls_v2", "controls"];

        for (controlsFile in controlsFiles) {
            try {
                if (controlsSave.bind(controlsFile, company)) {
                    // Import keyboard controls
                    var keyboardKeys = ["note_left", "note_down", "note_up", "note_right",
                                      "ui_left", "ui_down", "ui_up", "ui_right",
                                      "accept", "back", "pause", "reset"];

                    for (key in keyboardKeys) {
                        if (Reflect.hasField(controlsSave.data, key)) {
                            var keyArray:Array<Dynamic> = Reflect.field(controlsSave.data, key);
                            if (keyArray != null && keyArray.length > 0) {
                                // Cast to proper FlxKey array
                                var flxKeyArray:Array<flixel.input.keyboard.FlxKey> = cast keyArray;
                                // Apply controls to ClientPrefs (simplified - full implementation would be more complex)
                                switch (key) {
                                    case "note_left": ClientPrefs.keyBinds.set("note_left", flxKeyArray);
                                    case "note_down": ClientPrefs.keyBinds.set("note_down", flxKeyArray);
                                    case "note_up": ClientPrefs.keyBinds.set("note_up", flxKeyArray);
                                    case "note_right": ClientPrefs.keyBinds.set("note_right", flxKeyArray);
                                    case "ui_left": ClientPrefs.keyBinds.set("ui_left", flxKeyArray);
                                    case "ui_down": ClientPrefs.keyBinds.set("ui_down", flxKeyArray);
                                    case "ui_up": ClientPrefs.keyBinds.set("ui_up", flxKeyArray);
                                    case "ui_right": ClientPrefs.keyBinds.set("ui_right", flxKeyArray);
                                    case "accept": ClientPrefs.keyBinds.set("accept", flxKeyArray);
                                    case "back": ClientPrefs.keyBinds.set("back", flxKeyArray);
                                    case "pause": ClientPrefs.keyBinds.set("pause", flxKeyArray);
                                    case "reset": ClientPrefs.keyBinds.set("reset", flxKeyArray);
                                }
                            }
                        }
                    }

                    controlsSave.destroy();
                    break; // Successfully imported controls
                }
            } catch (e:Dynamic) {
                trace('Failed to import controls from $controlsFile: $e');
            }
        }

        controlsSave = null;
    }

    function importKadeSettings(savePath:String):Bool {
        if (!FileSystem.exists(savePath)) return false;

        try {
            // Create temporary save for Kade Engine
            var tempSave = new FlxSave();

            // Use mergeDataFrom to load the foreign save file directly
            if (tempSave.mergeDataFrom(savePath)) {
                // Import Kade Engine specific settings
                if (tempSave.data.downscroll != null)
                    ClientPrefs.data.downScroll = tempSave.data.downscroll;
                if (tempSave.data.ghost != null)
                    ClientPrefs.data.ghostTapping = tempSave.data.ghost;
                if (tempSave.data.fps != null)
                    ClientPrefs.data.framerate = Std.int(Math.max(60, Math.min(240, tempSave.data.fps)));
                if (tempSave.data.antialiasing != null)
                    ClientPrefs.data.antialiasing = tempSave.data.antialiasing;
                if (tempSave.data.noteGlow != null)
                    ClientPrefs.data.noteSplashes = tempSave.data.noteGlow;

                // Kade-specific visual settings
                if (tempSave.data.accuracyDisplay != null)
                    ClientPrefs.data.scoreZoom = tempSave.data.accuracyDisplay;
                if (tempSave.data.offset != null)
                    ClientPrefs.data.noteOffset = tempSave.data.offset;

                tempSave.destroy();
                ClientPrefs.saveSettings();
                return true;
            }
        } catch (e:Dynamic) {
            trace('Error importing Kade settings: $e');
            return false;
        }

        return false;
    }

    function importLegacySettings(savePath:String):Bool {
        if (!FileSystem.exists(savePath)) return false;

        try {
            // Create temporary save for Legacy engines
            var tempSave = new FlxSave();

            // Use mergeDataFrom to load the foreign save file directly
            if (tempSave.mergeDataFrom(savePath)) {
                // Import common settings that most engines share
                if (tempSave.data.downScroll != null)
                    ClientPrefs.data.downScroll = tempSave.data.downScroll;
                if (tempSave.data.ghostTapping != null)
                    ClientPrefs.data.ghostTapping = tempSave.data.ghostTapping;
                if (tempSave.data.antialiasing != null)
                    ClientPrefs.data.antialiasing = tempSave.data.antialiasing;
                if (tempSave.data.framerate != null)
                    ClientPrefs.data.framerate = Std.int(Math.max(60, Math.min(240, tempSave.data.framerate)));
                if (tempSave.data.flashing != null)
                    ClientPrefs.data.flashing = tempSave.data.flashing;
                if (tempSave.data.lowQuality != null)
                    ClientPrefs.data.lowQuality = tempSave.data.lowQuality;

                // Try to import volume settings
                if (tempSave.data.masterVolume != null)
                    FlxG.sound.volume = tempSave.data.masterVolume;

                tempSave.destroy();
                ClientPrefs.saveSettings();
                return true;
            }
        } catch (e:Dynamic) {
            trace('Error importing Legacy settings: $e');
            return false;
        }

        return false;
    }

    function performComprehensiveImport(savePath:String, engineType:String):Bool {
        var success = false;
        var importCount = 0;
        var errorMessages:Array<String> = [];

        try {
            // Create backup of current settings
            var backupSave = new FlxSave();
            backupSave.bind('Mixtape_backup_' + Date.now().getTime(), backend.CoolUtil.getSavePath());
            backupSave.mergeDataFrom(FlxG.save.name);
            backupSave.flush();

            // Perform import based on engine type
            switch (engineType) {
                case "psych", "psych_fork":
                    success = importPsychSettings(savePath);
                    if (success) importCount++;

                case "kade":
                    success = importKadeSettings(savePath);
                    if (success) importCount++;

                case "legacy":
                    success = importLegacySettings(savePath);
                    if (success) importCount++;

                default:
                    // Try generic FlxSave import for unknown engines
                    success = importGenericFlxSave(savePath);
                    if (success) importCount++;
            }

            // Clean up backup if import was successful
            if (success) {
                backupSave.erase();
            }

            backupSave.destroy();

        } catch (e:Dynamic) {
            errorMessages.push('Import error: $e');
            trace('Comprehensive import error: $e');
        }

        return success && importCount > 0;
    }

    function importGenericFlxSave(savePath:String):Bool {
        if (!FileSystem.exists(savePath)) return false;

        try {
            var tempSave = new FlxSave();

            // Use mergeDataFrom to load the foreign save file directly
            if (tempSave.mergeDataFrom(savePath)) {
                // Import any compatible settings we can find
                var compatibleFields = [
                    "downScroll", "ghostTapping", "antialiasing", "framerate",
                    "flashing", "lowQuality", "middleScroll", "hideHud",
                    "showFPS", "autoPause", "camZooms", "healthBarAlpha"
                ];

                for (field in compatibleFields) {
                    if (Reflect.hasField(tempSave.data, field)) {
                        var value = Reflect.field(tempSave.data, field);
                        if (value != null) {
                            Reflect.setField(ClientPrefs.data, field, value);
                        }
                    }
                }

                tempSave.destroy();
                ClientPrefs.saveSettings();
                return true;
            }
        } catch (e:Dynamic) {
            trace('Error importing generic FlxSave: $e');
        }

        return false;
    }

    function showResult(message:String) {
        // Determine success based on message content
        var success = message.indexOf("Successfully imported") > -1;

        // Add more detailed information about what was imported
        var detailedMessage = message;
        if (message.indexOf("Successfully imported") > -1) {
            detailedMessage += "\n\nImported settings may include:\n" +
                "• Graphics settings (antialiasing, framerate)\n" +
                "• Gameplay settings (downscroll, ghost tapping)\n" +
                "• Visual preferences (HUD, flashing)\n" +
                "• Control bindings (if available)\n" +
                "• Audio preferences\n\n" +
                "You can adjust these anytime in Options.";
        }

        var resultPanel = new InfoPanelSubstate(
            "Import Result",
            detailedMessage,
            success ? FlxColor.LIME : FlxColor.ORANGE,
            function() {
                returnToPreviousSetup();
            }
        );
        openSubState(resultPanel);
    }

    function returnToPreviousSetup() {
        // Return to the appropriate setup based on the user's choice
        if (ClientPrefs.data.setupArchipelagoMode) {
            MusicBeatState.switchState(new ArchipelagoSetupState());
        } else {
            MusicBeatState.switchState(new BasicSettingsSetup());
        }
    }
}

typedef EngineData = {
    var name:String;
    var description:String;
    var saveFile:String;
    var engineType:String;
    @:optional var availableFiles:Array<String>;
}
