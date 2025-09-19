package states;

import backend.*;
import flixel.*;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSave;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import haxe.io.Path;
import lime.app.Application;
import openfl.utils.Assets;
import substates.Prompt;
import yutautil.save.MixSaveWrapper;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

    // Categories
    enum SaveCategory {
        ALL;
        GAME_DATA;      // MixSaves, game progress
        SETTINGS;       // Client preferences, graphics settings
        CONTROLS;       // Input bindings
        SCORES;         // Highscores, week progress
        ACHIEVEMENTS;   // Achievement data
        MODS;          // Mod-specific saves
        SYSTEM;        // Engine-specific saves
        OTHER;         // Unrecognized saves
    }

/**
 * Comprehensive Save Management State
 * Handles all types of save files in the Mixtape Engine:
 * - MixSave files (.json, .smix)
 * - FlxSave files (settings, controls, scores, etc.)
 * - Client preferences and configurations
 * - Achievements and unlocks
 * - Mod-specific saves
 */
class SaveManagementState extends MusicBeatState {
    // UI Elements
    var bg:FlxSprite;
    var gridOverlay:FlxBackdrop;
    var titleText:FlxText;
    var categoryTabs:FlxTypedGroup<FlxButton>;
    var saveList:FlxTypedGroup<SaveEntryUI>;
    var detailPanel:FlxSprite;
    var detailText:FlxText;
    var actionButtons:FlxTypedGroup<FlxButton>;

    // Save Management
    var allSaveFiles:Array<SaveFileData> = [];
    var filteredSaves:Array<SaveFileData> = [];
    var selectedSave:SaveFileData = null;
    var currentCategory:SaveCategory = ALL;

    // UI State
    var selectedIndex:Int = 0;
    var scrollOffset:Int = 0;
    var maxVisibleEntries:Int = 8;



    override function create() {
        super.create();

        setupBackground();
        setupUI();
        scanForSaveFiles();
        updateDisplay();

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    function setupBackground() {
        // Animated gradient background
        bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [FlxColor.fromRGB(25, 25, 40), FlxColor.fromRGB(15, 15, 25)], 1, 90);
        add(bg);

        // Subtle grid pattern
        gridOverlay = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x11FFFFFF, 0x0));
        gridOverlay.velocity.set(-20, -20);
        gridOverlay.alpha = 0.1;
        add(gridOverlay);
    }

    function setupUI() {
        // Title
        titleText = new FlxText(0, 20, FlxG.width, "Save File Manager", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Category tabs
        categoryTabs = new FlxTypedGroup<FlxButton>();
        add(categoryTabs);

        var categories = [
            {name: "All", category: ALL},
            {name: "Game Data", category: GAME_DATA},
            {name: "Settings", category: SETTINGS},
            {name: "Controls", category: CONTROLS},
            {name: "Scores", category: SCORES},
            {name: "Achievements", category: ACHIEVEMENTS},
            {name: "Mods", category: MODS},
            {name: "System", category: SYSTEM}
        ];

        for (i in 0...categories.length) {
            var tab = new FlxButton(50 + i * 120, 80, categories[i].name);
            tab.loadGraphic(Paths.image('ui/button'), true, 100, 30);
            tab.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
            tab.onUp.callback = () -> switchCategory(categories[i].category);
            categoryTabs.add(tab);
        }

        // Save file list
        saveList = new FlxTypedGroup<SaveEntryUI>();
        add(saveList);

        // Detail panel
        detailPanel = new FlxSprite(FlxG.width - 400, 120);
        detailPanel.makeGraphic(380, FlxG.height - 140, FlxColor.fromRGB(20, 20, 30));
        detailPanel.alpha = 0.9;
        add(detailPanel);

        detailText = new FlxText(detailPanel.x + 20, detailPanel.y + 20, 340, "Select a save file to view details");
        detailText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE);
        detailText.wordWrap = true;
        add(detailText);

        // Action buttons
        actionButtons = new FlxTypedGroup<FlxButton>();
        add(actionButtons);

        var backBtn = new FlxButton(20, FlxG.height - 60, "Back", goBack);
        backBtn.loadGraphic(Paths.image('ui/button'), true, 80, 40);
        backBtn.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
        actionButtons.add(backBtn);

        var refreshBtn = new FlxButton(120, FlxG.height - 60, "Refresh", refreshSaveList);
        refreshBtn.loadGraphic(Paths.image('ui/button'), true, 80, 40);
        refreshBtn.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
        actionButtons.add(refreshBtn);

        var openFolderBtn = new FlxButton(220, FlxG.height - 60, "Open Folder", openSaveFolder);
        openFolderBtn.loadGraphic(Paths.image('ui/button'), true, 100, 40);
        openFolderBtn.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
        actionButtons.add(openFolderBtn);

        setupDetailButtons();
    }

    function setupDetailButtons() {
        var editBtn = new FlxButton(detailPanel.x + 20, detailPanel.y + detailPanel.height - 120, "Edit", editSelectedSave);
        editBtn.loadGraphic(Paths.image('ui/button'), true, 80, 30);
        editBtn.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        actionButtons.add(editBtn);

        var backupBtn = new FlxButton(detailPanel.x + 110, detailPanel.y + detailPanel.height - 120, "Backup", backupSelectedSave);
        backupBtn.loadGraphic(Paths.image('ui/button'), true, 80, 30);
        backupBtn.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        actionButtons.add(backupBtn);

        var deleteBtn = new FlxButton(detailPanel.x + 200, detailPanel.y + detailPanel.height - 120, "Delete", deleteSelectedSave);
        deleteBtn.loadGraphic(Paths.image('ui/button'), true, 80, 30);
        deleteBtn.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.RED, CENTER);
        actionButtons.add(deleteBtn);

        var restoreBtn = new FlxButton(detailPanel.x + 20, detailPanel.y + detailPanel.height - 80, "Restore", restoreSelectedSave);
        restoreBtn.loadGraphic(Paths.image('ui/button'), true, 80, 30);
        restoreBtn.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        actionButtons.add(restoreBtn);

        var exportBtn = new FlxButton(detailPanel.x + 110, detailPanel.y + detailPanel.height - 80, "Export", exportSelectedSave);
        exportBtn.loadGraphic(Paths.image('ui/button'), true, 80, 30);
        exportBtn.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        actionButtons.add(exportBtn);

        var importBtn = new FlxButton(detailPanel.x + 200, detailPanel.y + detailPanel.height - 80, "Import", importSave);
        importBtn.loadGraphic(Paths.image('ui/button'), true, 80, 30);
        importBtn.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        actionButtons.add(importBtn);
    }

    function scanForSaveFiles() {
        allSaveFiles = [];

        // Scan MixSave files in save/ directory
        scanMixSaveFiles();

        // Scan FlxSave files
        scanFlxSaveFiles();

        // Scan specific engine saves
        scanEngineSaves();

        // Sort by category and then by name
        allSaveFiles.sort((a, b) -> {
            var catCompare = Std.int(Type.enumIndex(a.category) - Type.enumIndex(b.category));
            return catCompare != 0 ? catCompare : a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
        });

        trace('Found ${allSaveFiles.length} save files');
    }

    function scanMixSaveFiles() {
        #if sys
        var saveDir = "save";
        if (!FileSystem.exists(saveDir)) {
            FileSystem.createDirectory(saveDir);
        }

        try {
            for (file in FileSystem.readDirectory(saveDir)) {
                var fullPath = Path.join([saveDir, file]);
                if (FileSystem.isDirectory(fullPath)) continue;

                var category = GAME_DATA;
                var fileType = "Unknown";

                if (file.endsWith('.json')) {
                    fileType = "MixSave JSON";
                    if (file.contains('control') || file.contains('input')) category = CONTROLS;
                    else if (file.contains('setting') || file.contains('config')) category = SETTINGS;
                    else if (file.contains('score') || file.contains('highscore')) category = SCORES;
                    else if (file.contains('achievement')) category = ACHIEVEMENTS;
                    else if (file.contains('mod')) category = MODS;
                    else if (file.contains('ap') || file.contains('archipelago')) category = SYSTEM;
                } else if (file.endsWith('.smix')) {
                    // Skip .smix files as SecureMixSave is currently disabled
                    continue;
                }

                if (fileType != "Unknown") {
                    var stat = FileSystem.stat(fullPath);
                    allSaveFiles.push({
                        name: file,
                        path: fullPath,
                        category: category,
                        type: fileType,
                        size: stat.size,
                        lastModified: stat.mtime,
                        isReadonly: false
                    });
                }
            }
        } catch (e:Dynamic) {
            trace('Error scanning MixSave files: $e');
        }
        #end
    }

    function scanFlxSaveFiles() {
        #if sys
        try {
            var savePath = CoolUtil.getSavePath();
            var fullSavePath = #if windows
                Sys.getEnv("APPDATA") + "/FlxG.save.data/" + savePath
            #elseif mac
                Sys.getEnv("HOME") + "/Library/Application Support/FlxG.save.data/" + savePath
            #else
                Sys.getEnv("HOME") + "/.local/share/FlxG.save.data/" + savePath
            #end;

            if (FileSystem.exists(fullSavePath)) {
                for (file in FileSystem.readDirectory(fullSavePath)) {
                    if (file.endsWith('.dat') || file.endsWith('.sol')) {
                        var fullPath = Path.join([fullSavePath, file]);
                        var stat = FileSystem.stat(fullPath);

                        var category = categorizeFlxSave(file);

                        allSaveFiles.push({
                            name: file,
                            path: fullPath,
                            category: category,
                            type: "FlxSave",
                            size: stat.size,
                            lastModified: stat.mtime,
                            isReadonly: false
                        });
                    }
                }
            }
        } catch (e:Dynamic) {
            trace('Error scanning FlxSave files: $e');
        }
        #end
    }

    function scanEngineSaves() {
        // Check for specific engine saves
        var engineSaves = [
            {file: "controls_v3", category: CONTROLS},
            {file: "achievements", category: ACHIEVEMENTS},
            {file: "weekScores", category: SCORES},
            {file: "songScores", category: SCORES}
        ];

        for (saveInfo in engineSaves) {
            try {
                var save = new FlxSave();
                save.bind(saveInfo.file, CoolUtil.getSavePath());
                if (save.data != null && Reflect.fields(save.data).length > 0) {
                    allSaveFiles.push({
                        name: saveInfo.file + " (Engine)",
                        path: "engine://" + saveInfo.file,
                        category: saveInfo.category,
                        type: "Engine Save",
                        size: 0, // Can't easily get size of FlxSave
                        lastModified: Date.now(),
                        isReadonly: false
                    });
                }
                save.destroy();
            } catch (e:Dynamic) {
                trace('Error checking engine save ${saveInfo.file}: $e');
            }
        }
    }

    function categorizeFlxSave(filename:String):SaveCategory {
        var lower = filename.toLowerCase();

        if (lower.contains('control') || lower.contains('input') || lower.contains('key')) return CONTROLS;
        if (lower.contains('setting') || lower.contains('config') || lower.contains('pref')) return SETTINGS;
        if (lower.contains('score') || lower.contains('highscore') || lower.contains('week')) return SCORES;
        if (lower.contains('achieve') || lower.contains('unlock')) return ACHIEVEMENTS;
        if (lower.contains('mod')) return MODS;
        if (lower.contains('system') || lower.contains('engine')) return SYSTEM;

        return OTHER;
    }

    function switchCategory(category:SaveCategory) {
        currentCategory = category;
        selectedIndex = 0;
        scrollOffset = 0;
        updateDisplay();

        // Update tab appearance
        for (i in 0...categoryTabs.length) {
            var tab = categoryTabs.members[i];
            if (tab != null) {
                tab.color = (Type.enumIndex(category) == i) ? FlxColor.YELLOW : FlxColor.WHITE;
            }
        }
    }

    function updateDisplay() {
        // Filter saves by category
        filteredSaves = [];
        for (save in allSaveFiles) {
            if (currentCategory == ALL || save.category == currentCategory) {
                filteredSaves.push(save);
            }
        }

        // Clear existing entries
        saveList.clear();

        // Create visible entries
        for (i in 0...Std.int(Math.min(maxVisibleEntries, filteredSaves.length - scrollOffset))) {
            var saveIndex = scrollOffset + i;
            if (saveIndex >= filteredSaves.length) break;

            var save = filteredSaves[saveIndex];
            var entry = new SaveEntryUI(20, 120 + i * 60, save, saveIndex == selectedIndex);
            entry.onSelect = () -> selectSave(save);
            saveList.add(entry);
        }

        updateDetailPanel();
    }

    function selectSave(save:SaveFileData) {
        selectedSave = save;

        // Update selected index
        for (i in 0...filteredSaves.length) {
            if (filteredSaves[i] == save) {
                selectedIndex = i;
                break;
            }
        }

        updateDetailPanel();
        updateDisplay(); // Refresh to show selection
    }

    function updateDetailPanel() {
        if (selectedSave == null) {
            detailText.text = "Select a save file to view details";
            return;
        }

        var info = "Name: " + selectedSave.name + "\n";
        info += "Type: " + selectedSave.type + "\n";
        info += "Category: " + selectedSave.category + "\n";
        info += "Size: " + CoolUtil.formatMemory(selectedSave.size) + "\n";
        info += "Modified: " + Std.string(selectedSave.lastModified) + "\n";
        info += "Path: " + selectedSave.path + "\n\n";

        // Try to load and preview content
        try {
            var preview = getContentPreview(selectedSave);
            info += "Content Preview:\n" + preview;
        } catch (e:Dynamic) {
            info += "Content: Unable to preview (" + e + ")";
        }

        detailText.text = info;
    }

    function getContentPreview(save:SaveFileData):String {
        if (save.type == "MixSave JSON") {
            try {
                #if sys
                var content = File.getContent(save.path);
                var parsed = haxe.Json.parse(content);
                var preview = "";
                var keys = Reflect.fields(parsed);

                if (keys.length == 0) {
                    return "Empty save file";
                }

                for (i in 0...Std.int(Math.min(5, keys.length))) {
                    var key = keys[i];
                    var value = Reflect.field(parsed, key);
                    var valueStr = Std.string(value);
                    if (valueStr.length > 50) valueStr = valueStr.substr(0, 50) + "...";
                    preview += key + ": " + valueStr + "\n";
                }

                if (keys.length > 5) {
                    preview += "... and " + (keys.length - 5) + " more items";
                }

                return preview;
                #else
                return "File preview not available on this platform";
                #end
            } catch (e:Dynamic) {
                return "Error reading JSON: " + e;
            }
        }
        else if (save.type == "Engine Save") {
            return "Engine-managed save data\n(Use in-game settings to modify)";
        }

        return "Preview not available for this save type";
    }

    // Action functions
    function goBack() {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new options.OptionsState());
    }

    function refreshSaveList() {
        FlxG.sound.play(Paths.sound('scrollMenu'));
        scanForSaveFiles();
        updateDisplay();
    }

    function openSaveFolder() {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        if (selectedSave != null) {
            var folder = Path.directory(selectedSave.path);
            CoolUtil.openFolder(folder, true);
        } else {
            CoolUtil.openFolder("save");
        }
    }

    function editSelectedSave() {
        if (selectedSave == null) return;

        FlxG.sound.play(Paths.sound('confirmMenu'));
        // TODO: Open save editor substate
        trace('Edit save: ${selectedSave.name}');
    }

    function backupSelectedSave() {
        if (selectedSave == null) return;

        FlxG.sound.play(Paths.sound('confirmMenu'));
        try {
            #if sys
            var backupPath = selectedSave.path + ".backup." + Std.string(Date.now().getTime());
            File.copy(selectedSave.path, backupPath);

            Application.current.window.alert("Backup created: " + Path.withoutDirectory(backupPath), "Backup Complete");
            #else
            Application.current.window.alert("Backup not available on this platform", "Backup Failed");
            #end
        } catch (e:Dynamic) {
            Application.current.window.alert("Failed to create backup: " + e, "Backup Failed");
        }
    }

    function deleteSelectedSave() {
        if (selectedSave == null) return;

        FlxG.sound.play(Paths.sound('cancelMenu'));

        // Confirmation dialog
        var promptText = "Are you sure you want to delete this save file?\n\n" +
            selectedSave.name + "\n\nThis action cannot be undone!";

        var prompt = new Prompt(promptText, 0,
            function() { // OK callback
                try {
                    #if sys
                    FileSystem.deleteFile(selectedSave.path);
                    #end
                    allSaveFiles.remove(selectedSave);
                    selectedSave = null;
                    updateDisplay();

                    Application.current.window.alert("Save file deleted successfully.", "Delete Complete");
                } catch (e:Dynamic) {
                    Application.current.window.alert("Failed to delete save file: " + e, "Delete Failed");
                }
            },
            function() { // Cancel callback
                // Do nothing, just close the prompt
            }
        );
        openSubState(prompt);
    }

    function restoreSelectedSave() {
        if (selectedSave == null) return;

        FlxG.sound.play(Paths.sound('confirmMenu'));
        trace('Restore save: ${selectedSave.name}');
        // TODO: Implement save restore functionality
    }

    function exportSelectedSave() {
        if (selectedSave == null) return;

        FlxG.sound.play(Paths.sound('confirmMenu'));
        trace('Export save: ${selectedSave.name}');
        // TODO: Implement save export functionality
    }

    function importSave() {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        trace('Import save');
        // TODO: Implement save import functionality
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Scroll through saves
        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W) {
            if (selectedIndex > 0) {
                selectedIndex--;
                if (selectedIndex < scrollOffset) {
                    scrollOffset--;
                }
            } else {
                selectedIndex = filteredSaves.length - 1;
                scrollOffset = Std.int(Math.max(0, filteredSaves.length - maxVisibleEntries));
            }

            if (filteredSaves.length > 0) {
                selectSave(filteredSaves[selectedIndex]);
            }

            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S) {
            if (selectedIndex < filteredSaves.length - 1) {
                selectedIndex++;
                if (selectedIndex >= scrollOffset + maxVisibleEntries) {
                    scrollOffset++;
                }
            } else {
                selectedIndex = 0;
                scrollOffset = 0;
            }

            if (filteredSaves.length > 0) {
                selectSave(filteredSaves[selectedIndex]);
            }

            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        // Category switching
        if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A) {
            var currentIndex = Type.enumIndex(currentCategory);
            var newIndex = currentIndex > 0 ? currentIndex - 1 : Type.getEnumConstructs(SaveCategory).length - 1;
            switchCategory(Type.createEnumIndex(SaveCategory, newIndex));
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D) {
            var currentIndex = Type.enumIndex(currentCategory);
            var newIndex = (currentIndex + 1) % Type.getEnumConstructs(SaveCategory).length;
            switchCategory(Type.createEnumIndex(SaveCategory, newIndex));
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        // Quick actions
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) {
            editSelectedSave();
        }

        if (FlxG.keys.justPressed.DELETE) {
            deleteSelectedSave();
        }

        if (FlxG.keys.justPressed.B) {
            backupSelectedSave();
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            goBack();
        }

        if (FlxG.keys.justPressed.F5) {
            refreshSaveList();
        }
    }
}

// Data structures
typedef SaveFileData = {
    var name:String;
    var path:String;
    var category:SaveManagementState.SaveCategory;
    var type:String;
    var size:Int;
    var lastModified:Date;
    var isReadonly:Bool;
}

// UI Components
class SaveEntryUI extends FlxSpriteGroup {
    var bg:FlxSprite;
    var nameText:FlxText;
    var typeText:FlxText;
    var sizeText:FlxText;
    var saveData:SaveFileData;
    var isSelected:Bool;

    public var onSelect:Void->Void;

    public function new(x:Float, y:Float, data:SaveFileData, selected:Bool = false) {
        super(x, y);

        saveData = data;
        isSelected = selected;

        // Background
        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width - 440, 50, isSelected ? FlxColor.fromRGB(50, 50, 80) : FlxColor.fromRGB(30, 30, 40));
        bg.alpha = 0.8;
        add(bg);

        // Category indicator
        var categoryColor = getCategoryColor(data.category);
        var indicator = new FlxSprite(5, 5);
        indicator.makeGraphic(5, 40, categoryColor);
        add(indicator);

        // Name
        nameText = new FlxText(20, 5, 200, data.name);
        nameText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE);
        add(nameText);

        // Type
        typeText = new FlxText(20, 25, 150, data.type);
        typeText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY);
        add(typeText);

        // Size
        sizeText = new FlxText(bg.width - 120, 5, 100, CoolUtil.formatMemory(data.size));
        sizeText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT);
        add(sizeText);

        // Date
        var dateText = new FlxText(bg.width - 120, 25, 100, Std.string(data.lastModified).substr(0, 10));
        dateText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, RIGHT);
        add(dateText);

        // Make clickable
        bg.scrollFactor.set(0, 0);

        #if FLX_MOUSE
        FlxG.mouse.visible = true;
        #end
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        #if FLX_MOUSE
        if (FlxG.mouse.overlaps(bg) && FlxG.mouse.justPressed) {
            if (onSelect != null) onSelect();
        }
        #end
    }

    function getCategoryColor(category:SaveManagementState.SaveCategory):FlxColor {
        return switch (category) {
            case GAME_DATA: FlxColor.GREEN;
            case SETTINGS: FlxColor.BLUE;
            case CONTROLS: FlxColor.YELLOW;
            case SCORES: FlxColor.ORANGE;
            case ACHIEVEMENTS: FlxColor.PURPLE;
            case MODS: FlxColor.CYAN;
            case SYSTEM: FlxColor.RED;
            case OTHER: FlxColor.WHITE;
            case ALL: FlxColor.WHITE;
        }
    }
}
