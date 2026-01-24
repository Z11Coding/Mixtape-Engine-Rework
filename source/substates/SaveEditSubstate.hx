package substates;

import backend.*;
import backend.ui.PsychUIButton;
import flixel.*;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import haxe.Json;
import lime.app.Application;
import yutautil.save.MixSaveWrapper;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end


class SaveEditSubstate extends MusicBeatSubstate {
    var saveData:SaveFileData;
    var bg:FlxSprite;
    var titleText:FlxText;
    var scrollableGroup:FlxTypedGroup<FlxBasic>;
    var propertyEntries:Array<PropertyEntry> = [];
    var actionButtons:FlxTypedGroup<PsychUIButton>;

    // Scrolling
    var scrollY:Float = 0;
    var maxScrollY:Float = 0;
    var originalYPositions:Map<FlxBasic, Float> = new Map();

    // Edit state
    var isModified:Bool = false;
    var originalData:Dynamic;

    public function new(saveData:SaveFileData) {
        super();
        this.saveData = saveData;
    }

    override function create() {
        super.create();

        // Semi-transparent background
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.8;
        add(bg);

        // Main panel
        var panel = new FlxSprite(100, 50);
        panel.makeGraphic(FlxG.width - 200, FlxG.height - 100, FlxColor.fromRGB(30, 30, 40));
        panel.alpha = 0.95;
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, "Editing: " + saveData.name, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Scrollable content area
        scrollableGroup = new FlxTypedGroup<FlxBasic>();
        add(scrollableGroup);

        // Load and display save data
        loadSaveData();

        // Action buttons
        setupActionButtons();

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    function loadSaveData() {
        try {
            if (saveData.type == "Engine Save") {
                loadEngineSave();
            } else if (saveData.type == "FlxSave") {
                loadFlxSave();
            } else if (saveData.type == "MixSave JSON") {
                loadMixSave();
            } else {
                showError("Unsupported save type: " + saveData.type);
                return;
            }

            createPropertyUI();
        } catch (e:Dynamic) {
            showError("Failed to load save data: " + e);
        }
    }

    function loadEngineSave() {
        var saveName = saveData.path.substring(9); // Remove "engine://"
        var save = new FlxSave();
        save.bind(saveName, CoolUtil.getSavePath());

        if (save.data != null) {
            originalData = save.data;
            parseObjectToProperties("", save.data);
        }
        save.destroy();
    }

    function loadFlxSave() {
        #if sys
        if (FileSystem.exists(saveData.path)) {
            // For .sol files, we need to load them as FlxSave
            var tempSave = new FlxSave();
            if (tempSave.mergeDataFrom(saveData.path)) {
                originalData = tempSave.data;
                parseObjectToProperties("", tempSave.data);
            }
            tempSave.destroy();
        }
        #end
    }

    function loadMixSave() {
        #if sys
        if (FileSystem.exists(saveData.path)) {
            var content = File.getContent(saveData.path);
            originalData = Json.parse(content);
            parseObjectToProperties("", originalData);
        }
        #end
    }

    function parseObjectToProperties(prefix:String, obj:Dynamic) {
        var fields = Reflect.fields(obj);
        for (field in fields) {
            var fullPath = prefix.length > 0 ? prefix + "." + field : field;
            var value = Reflect.field(obj, field);

            if (value != null) {
                var valueType = Type.typeof(value);

                switch (valueType) {
                    case TInt, TFloat, TBool:
                        propertyEntries.push({
                            path: fullPath,
                            type: Std.string(valueType).substring(1), // Remove T prefix
                            value: Std.string(value),
                            originalValue: value
                        });

                    case TClass(String):
                        propertyEntries.push({
                            path: fullPath,
                            type: "String",
                            value: Std.string(value),
                            originalValue: value
                        });

                    case TObject:
                        // Recursively parse nested objects
                        parseObjectToProperties(fullPath, value);

                    default:
                        // For arrays and other complex types, store as JSON string
                        propertyEntries.push({
                            path: fullPath,
                            type: "JSON",
                            value: Json.stringify(value),
                            originalValue: value
                        });
                }
            }
        }
    }

    function createPropertyUI() {
        var startY = titleText.y + titleText.height + 40;
        var entryHeight = 60;
        var margin = 10;

        for (i in 0...propertyEntries.length) {
            var entry = propertyEntries[i];
            var y = startY + i * (entryHeight + margin);

            // Property name
            var nameText = new FlxText(titleText.x, y, 200, entry.path);
            nameText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE);
            addToScrollableGroup(nameText);

            // Type label
            var typeText = new FlxText(titleText.x + 210, y, 60, entry.type);
            typeText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY);
            addToScrollableGroup(typeText);

            // Value input
            var valueInput = new FlxInputText(titleText.x + 280, y, 300, entry.value);
            valueInput.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK);
            valueInput.callback = function(text:String, action:String) {
                entry.value = text;
                checkForModifications();
            };
            addToScrollableGroup(valueInput);
            entry.inputField = valueInput;
        }

        maxScrollY = Math.max(0, (propertyEntries.length * (entryHeight + margin)) - 400);
    }

    function setupActionButtons() {
        actionButtons = new FlxTypedGroup<PsychUIButton>();
        add(actionButtons);

        var buttonY = FlxG.height - 80;

        var saveBtn = new PsychUIButton(200, buttonY, "Save Changes", saveChanges, 120, 40);
        actionButtons.add(saveBtn);

        var revertBtn = new PsychUIButton(340, buttonY, "Revert", revertChanges, 100, 40);
        actionButtons.add(revertBtn);

        var closeBtn = new PsychUIButton(460, buttonY, "Close", close, 80, 40);
        actionButtons.add(closeBtn);
    }

    function checkForModifications() {
        isModified = false;

        for (entry in propertyEntries) {
            if (entry.value != Std.string(entry.originalValue)) {
                isModified = true;
                break;
            }
        }

        // Update save button color based on modification state
        if (actionButtons.members.length > 0) {
            var saveBtn = actionButtons.members[0];
            if (saveBtn != null) {
                saveBtn.normalStyle.bgColor = isModified ? FlxColor.YELLOW : 0xFFAAAAAA;
            }
        }
    }

    function saveChanges() {
        if (!isModified) {
            Application.current.window.alert("No changes to save.", "Save");
            return;
        }

        try {
            // Build modified data object
            var newData:Dynamic = {};

            // Copy original structure
            if (originalData != null) {
                newData = haxe.Json.parse(haxe.Json.stringify(originalData));
            }

            // Apply property changes
            for (entry in propertyEntries) {
                var pathParts = entry.path.split(".");
                var current = newData;

                // Navigate to the parent object
                for (i in 0...pathParts.length - 1) {
                    var part = pathParts[i];
                    if (!Reflect.hasField(current, part)) {
                        Reflect.setField(current, part, {});
                    }
                    current = Reflect.field(current, part);
                }

                // Set the final value
                var finalKey = pathParts[pathParts.length - 1];
                var convertedValue = convertStringToType(entry.value, entry.type);
                Reflect.setField(current, finalKey, convertedValue);
            }

            // Save based on type
            if (saveData.type == "Engine Save") {
                saveEngineSave(newData);
            } else if (saveData.type == "FlxSave") {
                saveFlxSave(newData);
            } else if (saveData.type == "MixSave JSON") {
                saveMixSave(newData);
            }

            isModified = false;
            checkForModifications();
            Application.current.window.alert("Changes saved successfully!", "Save");

        } catch (e:Dynamic) {
            showError("Failed to save changes: " + e);
        }
    }

    function convertStringToType(value:String, type:String):Dynamic {
        return switch (type) {
            case "Int": Std.parseInt(value);
            case "Float": Std.parseFloat(value);
            case "Bool": value.toLowerCase() == "true";
            case "JSON": Json.parse(value);
            case "String" | _: value;
        }
    }

    function saveEngineSave(newData:Dynamic) {
        var saveName = saveData.path.substring(9); // Remove "engine://"
        var save = new FlxSave();
        save.bind(saveName, CoolUtil.getSavePath());

        // Clear existing data and set new data
        save.erase();
        for (field in Reflect.fields(newData)) {
            Reflect.setField(save.data, field, Reflect.field(newData, field));
        }
        save.flush();
        save.destroy();
    }

    function saveFlxSave(newData:Dynamic) {
        #if sys
        // For .sol files, we create a temporary FlxSave, set the data, and flush
        var tempSave = new FlxSave();
        for (field in Reflect.fields(newData)) {
            Reflect.setField(tempSave.data, field, Reflect.field(newData, field));
        }

        // Save to original path - this is complex for .sol files
        // For now, we'll create a backup and show a warning
        var backupPath = saveData.path + ".backup." + Std.string(Date.now().getTime());
        File.copy(saveData.path, backupPath);

        Application.current.window.alert("FlxSave files are complex to edit directly.\nA backup was created: " +
            haxe.io.Path.withoutDirectory(backupPath), "FlxSave Warning");

        tempSave.destroy();
        #end
    }

    function saveMixSave(newData:Dynamic) {
        #if sys
        // Create backup first
        var backupPath = saveData.path + ".backup." + Std.string(Date.now().getTime());
        File.copy(saveData.path, backupPath);

        // Save new data as JSON
        var jsonString = Json.stringify(newData, null, "\t");
        File.saveContent(saveData.path, jsonString);
        #end
    }

    function revertChanges() {
        for (entry in propertyEntries) {
            entry.value = Std.string(entry.originalValue);
            if (entry.inputField != null) {
                entry.inputField.text = entry.value;
            }
        }
        isModified = false;
        checkForModifications();
    }

    function showError(message:String) {
        var errorText = new FlxText(titleText.x, titleText.y + titleText.height + 20, titleText.width, message);
        errorText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER);
        add(errorText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle scrolling
        if (FlxG.keys.pressed.UP || FlxG.mouse.wheel > 0) {
            scrollY = Math.max(0, scrollY - 100 * elapsed);
            updateScrollPosition();
        }

        if (FlxG.keys.pressed.DOWN || FlxG.mouse.wheel < 0) {
            scrollY = Math.min(maxScrollY, scrollY + 100 * elapsed);
            updateScrollPosition();
        }

        // ESC to close
        if (FlxG.keys.justPressed.ESCAPE) {
            if (isModified) {
                // Create confirmation dialog as substate
                var confirmDialog = new ConfirmationSubstate("You have unsaved changes. Close anyway?",
                    function() { close(); }, // Yes callback
                    function() { } // No callback (do nothing)
                );
                openSubState(confirmDialog);
            } else {
                close();
            }
        }
    }

    function updateScrollPosition() {
        scrollableGroup.forEach(function(member:FlxBasic) {
            if (Std.isOfType(member, FlxObject)) {
                var obj = cast(member, FlxObject);
                if (originalYPositions.exists(member)) {
                    obj.y = originalYPositions.get(member) - scrollY;
                }
            }
        });
    }

    function addToScrollableGroup(object:FlxObject) {
        originalYPositions.set(object, object.y);
        scrollableGroup.add(object);
    }
}

typedef SaveFileData = {
    var name:String;
    var path:String;
    var category:Dynamic; // SaveManagementState.SaveCategory
    var type:String;
    var size:Int;
    var lastModified:Date;
    var isReadonly:Bool;
}

typedef PropertyEntry = {
    var path:String;
    var type:String;
    var value:String;
    var originalValue:Dynamic;
    @:optional var inputField:FlxInputText;
}
