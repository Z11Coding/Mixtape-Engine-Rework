package debug;

import backend.MusicBeatSubstate;
import debug.CollectionEditor;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import yutautil.StatePick;
import yutautil.save.StateSerializer;

/**
 * Information about a property for debugging
 */
typedef PropertyInfo = {
    name: String,
    value: Dynamic,
    type: String,
    isEditable: Bool,
    isCollection: Bool,
    isComplex: Bool,
    fullPath: String
}

/**
 * Debug menu overlay that allows editing any property of the current state using the StateSerializer system
 * Only created when needed to prevent performance issues
 */
class StateDebugOverlay extends MusicBeatSubstate {
    private var backgroundPanel:FlxSprite;
    private var titleText:FlxText;
    private var breadcrumbText:FlxText;
    private var propertyList:FlxTypedGroup<FlxSprite>;
    private var scrollOffset:Int = 0;
    private var maxVisibleItems:Int = 15;

    // Camera and mouse state
    private var overlayCamera:FlxCamera;
    private var originalMouseVisible:Bool;
    private var originalCursorVisible:Bool;

    // Navigation state using serializer
    private var rootObject:Dynamic;
    private var currentObject:Dynamic;
    private var serializedData:Dynamic;
    private var breadcrumbs:Array<String> = [];
    private var breadcrumbPaths:Array<String> = []; // Full property paths for navigation
    private var properties:Array<PropertyInfo> = [];

    // Property information structure
    private var propertyInfos:Map<String, PropertyInfo> = new Map();

    public function new() {
        super();

        // Store original mouse state
        originalMouseVisible = FlxG.mouse.visible;
        #if desktop
        originalCursorVisible = FlxG.mouse.useSystemCursor;
        #end

        // Force mouse to be visible for debugging
        FlxG.mouse.visible = true;
        #if desktop
        FlxG.mouse.useSystemCursor = true;
        #end

        // Initialize with current state and get its actual class name
        rootObject = FlxG.state;
        currentObject = rootObject;

        // Get the actual class name instead of just "FlxG.state"
        var stateClassName = Type.getClassName(Type.getClass(rootObject));
        if (stateClassName != null) {
            breadcrumbs = [stateClassName.split(".").pop()];
        } else {
            breadcrumbs = ["FlxG.state"];
        }
        breadcrumbPaths = [""];

        // Only refresh data when created
        refreshSerializedData();
    }

    /**
     * Get all available state classes using StatePick
     */
    private function getAllStateClasses():Map<String, Class<Dynamic>> {
        var stateClasses:Map<String, Class<Dynamic>> = new Map();

        try {
            // Get MusicBeatState classes
            var musicBeatStates = StatePick.getStateNames("MusicBeatState");
            for (stateName in musicBeatStates) {
                var stateClass = Type.resolveClass(stateName);
                if (stateClass != null) {
                    stateClasses.set(stateName, stateClass);
                }
            }

            // Get FlxState classes
            var flxStates = StatePick.getStateNames("FlxState");
            for (stateName in flxStates) {
                var stateClass = Type.resolveClass(stateName);
                if (stateClass != null) {
                    stateClasses.set(stateName, stateClass);
                }
            }
        } catch (e:Dynamic) {
            trace('Error getting state classes: ${e}');
        }

        return stateClasses;
    }

    /**
     * Refresh the serialized data for the current object
     */
    private function refreshSerializedData():Void {
        try {
            serializedData = StateSerializer.createSerializableObject(currentObject);
            updateProperties();
        } catch (e:Dynamic) {
            trace('Error refreshing serialized data: ${e}');
        }
    }

    /**
     * Update the properties list from the serialized data
     */
    private function updateProperties():Void {
        properties = [];
        propertyInfos.clear();

        if (serializedData == null || serializedData.FIELDS == null) return;

        var fields = Reflect.fields(serializedData.FIELDS);
        for (fieldName in fields) {
            var fieldValue = Reflect.field(serializedData.FIELDS, fieldName);
            var propertyInfo = analyzeProperty(fieldName, fieldValue);
            properties.push(propertyInfo);
            propertyInfos.set(fieldName, propertyInfo);
        }

        // Sort properties alphabetically
        properties.sort(function(a, b) return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0));
    }

    /**
     * Analyze a property to determine its editing capabilities
     */
    private function analyzeProperty(name:String, value:Dynamic):PropertyInfo {
        var fullPath = breadcrumbPaths[breadcrumbPaths.length - 1];
        if (fullPath != "") fullPath += ".";
        fullPath += name;

        var actualValue = getPropertyByPath(rootObject, fullPath);
        var typeStr = getValueTypeString(actualValue);

        return {
            name: name,
            value: actualValue,
            type: typeStr,
            isEditable: isEditableType(actualValue),
            isCollection: isCollectionType(actualValue),
            isComplex: isComplexObject(actualValue),
            fullPath: fullPath
        };
    }

    /**
     * Get a property value by its full path from the root object
     */
    private function getPropertyByPath(obj:Dynamic, path:String):Dynamic {
        if (path == "") return obj;

        var parts = path.split(".");
        var current = obj;

        for (part in parts) {
            if (current == null) return null;
            current = Reflect.getProperty(current, part);
        }

        return current;
    }

    /**
     * Set a property value by its full path from the root object
     */
    private function setPropertyByPath(obj:Dynamic, path:String, value:Dynamic):Bool {
        if (path == "") return false;

        var parts = path.split(".");
        var current = obj;

        // Navigate to the parent object
        for (i in 0...parts.length - 1) {
            if (current == null) return false;
            current = Reflect.getProperty(current, parts[i]);
        }

        if (current == null) return false;

        try {
            Reflect.setProperty(current, parts[parts.length - 1], value);
            return true;
        } catch (e:Dynamic) {
            trace('Error setting property ${path}: ${e}');
            return false;
        }
    }

    override public function create():Void {
        super.create();

        // Create dedicated camera for the overlay
        overlayCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        overlayCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(overlayCamera, false);

        // Set all overlay elements to use the overlay camera
        cameras = [overlayCamera];

        // Create semi-transparent background
        backgroundPanel = new FlxSprite(0, 0);
        backgroundPanel.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 180));
        backgroundPanel.cameras = [overlayCamera];
        add(backgroundPanel);

        // Create title
        titleText = new FlxText(10, 10, FlxG.width - 20, "State Debug Menu", 16);
        titleText.color = FlxColor.WHITE;
        titleText.cameras = [overlayCamera];
        add(titleText);

        // Create breadcrumb
        breadcrumbText = new FlxText(10, 35, FlxG.width - 20, "", 12);
        breadcrumbText.color = FlxColor.YELLOW;
        breadcrumbText.cameras = [overlayCamera];
        add(breadcrumbText);

        // Create property list group
        propertyList = new FlxTypedGroup<FlxSprite>();
        propertyList.cameras = [overlayCamera];
        add(propertyList);

        // Update display
        updateDisplay();
    }

    /**
     * Get string representation of a value's type
     */
    private function getValueTypeString(value:Dynamic):String {
        if (value == null) return "null";

        var type = Type.typeof(value);
        switch (type) {
            case TBool: return "Bool";
            case TInt: return "Int";
            case TFloat: return "Float";
            case TClass(String): return "String";
            case TClass(Array):
                var arr:Array<Dynamic> = cast value;
                return 'Array<Dynamic>[${arr.length}]';
            case TObject:
                if (value.isMap()) {
                    var map:Map<Dynamic, Dynamic> = cast value;
                    var keys = [for (k in map.keys()) k];
                    return 'Map<Dynamic, Dynamic>[${keys.length} keys]';
                }
                return "Object";
            case TClass(c): return Type.getClassName(c);
            case TEnum(e): return Type.getEnumName(e);
            default: return Std.string(type);
        }
    }

    /**
     * Check if a value is of an editable type
     */
    private function isEditableType(value:Dynamic):Bool {
        if (value == null) return false;

        var type = Type.typeof(value);
        switch (type) {
            case TBool, TInt, TFloat, TClass(String): return true;
            default: return false;
        }
    }

    /**
     * Check if a value is a collection type (Array or Map)
     */
    private function isCollectionType(value:Dynamic):Bool {
        if (value == null) return false;
        return Std.isOfType(value, Array) || value.isMap();
    }

    /**
     * Check if a value is a complex object
     */
    private function isComplexObject(value:Dynamic):Bool {
        if (value == null) return false;

        var type = Type.typeof(value);
        switch (type) {
            case TBool, TInt, TFloat, TClass(String): return false;
            default: return true;
        }
    }

    private function updateDisplay():Void {
        // Clear existing items
        propertyList.clear();

        // Update breadcrumb
        breadcrumbText.text = "Path: " + breadcrumbs.join(" -> ");

        var yPos:Float = 60;
        var itemIndex:Int = 0;

        // Add back button if we're not at root
        if (breadcrumbs.length > 1) {
            var backButton = new FlxButton(10, yPos, "< Back", function() {
                navigateBack();
            });
            backButton.color = FlxColor.GRAY;
            backButton.cameras = [overlayCamera];
            propertyList.add(backButton);
            yPos += 25;
            itemIndex++;
        }

        // Add action buttons row
        var staticButton = new FlxButton(100, 60, "Static States", function() {
            openStaticStatesMenu();
        });
        staticButton.color = FlxColor.BLUE;
        staticButton.cameras = [overlayCamera];
        propertyList.add(staticButton);

        var exportButton = new FlxButton(220, 60, "Export JSON", function() {
            exportCurrentStateAsJSON();
        });
        exportButton.color = FlxColor.GREEN;
        exportButton.cameras = [overlayCamera];
        propertyList.add(exportButton);

        var refreshButton = new FlxButton(340, 60, "Refresh", function() {
            refreshSerializedData();
            updateDisplay();
        });
        refreshButton.color = FlxColor.ORANGE;
        refreshButton.cameras = [overlayCamera];
        propertyList.add(refreshButton);

        if (breadcrumbs.length > 1) yPos += 25; // Skip a line after buttons if we have back button
        else yPos = 90; // Standard position if no back button

        // Show properties with scroll
        var visibleProps = properties.slice(scrollOffset, scrollOffset + maxVisibleItems);

        for (prop in visibleProps) {
            if (itemIndex >= maxVisibleItems) break;

            // Property name and type display
            var nameText = new FlxText(10, yPos, 200, '${prop.name}:', 12);
            nameText.color = FlxColor.WHITE;
            nameText.cameras = [overlayCamera];
            propertyList.add(nameText);

            var typeText = new FlxText(10, yPos + 12, 200, prop.type, 10);
            typeText.color = FlxColor.GRAY;
            typeText.cameras = [overlayCamera];
            propertyList.add(typeText);

            // Value display and editing controls
            var valueX:Float = 220;

            if (prop.isEditable) {
                createEditableUI(prop, valueX, yPos);
            } else if (prop.isCollection) {
                createCollectionUI(prop, valueX, yPos);
            } else if (prop.isComplex) {
                createComplexUI(prop, valueX, yPos);
            } else {
                // Non-editable value - just display
                var valueText = new FlxText(valueX, yPos, 200, Std.string(prop.value), 12);
                valueText.color = FlxColor.GRAY;
                valueText.cameras = [overlayCamera];
                propertyList.add(valueText);
            }

            yPos += 30;
            itemIndex++;
        }

        // Scroll indicators
        if (scrollOffset > 0) {
            var upText = new FlxText(FlxG.width - 100, 90, 90, "↑ More above", 12);
            upText.color = FlxColor.CYAN;
            upText.cameras = [overlayCamera];
            propertyList.add(upText);
        }

        if (scrollOffset + maxVisibleItems < properties.length) {
            var downText = new FlxText(FlxG.width - 100, FlxG.height - 80, 90, "↓ More below", 12);
            downText.color = FlxColor.CYAN;
            downText.cameras = [overlayCamera];
            propertyList.add(downText);
        }
    }

    /**
     * Create UI for editable properties
     */
    private function createEditableUI(prop:PropertyInfo, x:Float, y:Float):Void {
        var valueDisplay = new FlxText(x, y, 120, Std.string(prop.value), 12);
        valueDisplay.color = FlxColor.WHITE;
        valueDisplay.cameras = [overlayCamera];
        propertyList.add(valueDisplay);

        // Add editing controls based on type
        if (Std.isOfType(prop.value, Bool)) {
            var toggleButton = new FlxButton(x + 125, y, prop.value ? "true" : "false");
            toggleButton.onUp.callback = function() {
                var newValue = !cast(prop.value, Bool);
                if (setPropertyByPath(rootObject, prop.fullPath, newValue)) {
                    prop.value = newValue;
                    toggleButton.text = newValue ? "true" : "false";
                    valueDisplay.text = Std.string(newValue);
                    toggleButton.color = newValue ? FlxColor.GREEN : FlxColor.RED;
                    trace('Changed ${prop.name} to ${newValue}');
                }
            };
            toggleButton.color = prop.value ? FlxColor.GREEN : FlxColor.RED;
            toggleButton.scale.set(0.8, 0.8);
            toggleButton.updateHitbox();
            toggleButton.cameras = [overlayCamera];
            propertyList.add(toggleButton);
        } else if (Std.isOfType(prop.value, String)) {
            var inputField = new FlxUIInputText(x + 125, y, 150, Std.string(prop.value), 12);
            inputField.callback = function(text:String, action:String) {
                if (action == "enter") {
                    if (setPropertyByPath(rootObject, prop.fullPath, text)) {
                        prop.value = text;
                        valueDisplay.text = text;
                        trace('Changed ${prop.name} to "${text}"');
                    }
                }
            };
            inputField.cameras = [overlayCamera];
            propertyList.add(inputField);
        } else if (Std.isOfType(prop.value, Int) || Std.isOfType(prop.value, Float)) {
            createNumberUI(prop, valueDisplay, x, y);
        }
    }

    /**
     * Create UI for number editing with +/- buttons
     */
    private function createNumberUI(prop:PropertyInfo, valueDisplay:FlxText, x:Float, y:Float):Void {
        var isInt = Std.isOfType(prop.value, Int);
        var inputField = new FlxUIInputText(x + 80, y, 80, Std.string(prop.value), 12);
        inputField.callback = function(text:String, action:String) {
            if (action == "enter") {
                var newValue:Dynamic = isInt ? Std.parseInt(text) : Std.parseFloat(text);
                if (newValue != null && setPropertyByPath(rootObject, prop.fullPath, newValue)) {
                    prop.value = newValue;
                    valueDisplay.text = Std.string(newValue);
                    trace('Changed ${prop.name} to ${newValue}');
                }
            }
        };
        inputField.cameras = [overlayCamera];
        propertyList.add(inputField);

        // Decrement button
        var decButton = new FlxButton(x + 170, y, "-", function() {
            var currentVal:Float = isInt ? cast(prop.value, Int) : cast(prop.value, Float);
            var step:Float = isInt ? 1 : 0.1;
            var newValue:Dynamic = isInt ? Std.int(currentVal - step) : currentVal - step;

            if (setPropertyByPath(rootObject, prop.fullPath, newValue)) {
                prop.value = newValue;
                inputField.text = Std.string(newValue);
                valueDisplay.text = Std.string(newValue);
                trace('Decremented ${prop.name} to ${newValue}');
            }
        });
        decButton.scale.set(0.6, 0.6);
        decButton.updateHitbox();
        decButton.cameras = [overlayCamera];
        propertyList.add(decButton);

        // Increment button
        var incButton = new FlxButton(x + 200, y, "+", function() {
            var currentVal:Float = isInt ? cast(prop.value, Int) : cast(prop.value, Float);
            var step:Float = isInt ? 1 : 0.1;
            var newValue:Dynamic = isInt ? Std.int(currentVal + step) : currentVal + step;

            if (setPropertyByPath(rootObject, prop.fullPath, newValue)) {
                prop.value = newValue;
                inputField.text = Std.string(newValue);
                valueDisplay.text = Std.string(newValue);
                trace('Incremented ${prop.name} to ${newValue}');
            }
        });
        incButton.scale.set(0.6, 0.6);
        incButton.updateHitbox();
        incButton.cameras = [overlayCamera];
        propertyList.add(incButton);
    }

    /**
     * Create UI for collection properties
     */
    private function createCollectionUI(prop:PropertyInfo, x:Float, y:Float):Void {
        var collectionInfo = getCollectionInfo(prop.value);
        var infoText = new FlxText(x, y, 200, collectionInfo, 12);
        infoText.color = FlxColor.LIME;
        infoText.cameras = [overlayCamera];
        propertyList.add(infoText);

        var editButton = new FlxButton(x + 150, y, "Edit", function() {
            editCollection(prop);
        });
        editButton.scale.set(0.8, 0.8);
        editButton.updateHitbox();
        editButton.cameras = [overlayCamera];
        propertyList.add(editButton);
    }

    /**
     * Create UI for complex object properties
     */
    private function createComplexUI(prop:PropertyInfo, x:Float, y:Float):Void {
        var valueText = new FlxText(x, y, 150, Std.string(prop.value), 12);
        valueText.color = FlxColor.CYAN;
        valueText.cameras = [overlayCamera];
        propertyList.add(valueText);

        var navButton = new FlxButton(x + 120, y, "->", function() {
            navigateToProperty(prop);
        });
        navButton.scale.set(0.8, 0.8);
        navButton.updateHitbox();
        navButton.cameras = [overlayCamera];
        propertyList.add(navButton);
    }

    /**
     * Get collection information string
     */
    private function getCollectionInfo(value:Dynamic):String {
        if (Std.isOfType(value, Array)) {
            var arr:Array<Dynamic> = cast value;
            return 'Array[${arr.length}]';
        } else if (value.isMap()) {
            var map:Map<Dynamic, Dynamic> = cast value;
            var keys = [for (k in map.keys()) k];
            return 'Map[${keys.length} keys]';
        }
        return "Collection";
    }

    /**
     * Navigate to a property (drill down into complex objects)
     */
    private function navigateToProperty(prop:PropertyInfo):Void {
        if (prop.value == null || !prop.isComplex) return;

        breadcrumbs.push(prop.name);
        breadcrumbPaths.push(prop.fullPath);
        currentObject = prop.value;
        scrollOffset = 0;

        refreshSerializedData();
        updateDisplay();
    }

    /**
     * Navigate back to parent object
     */
    private function navigateBack():Void {
        if (breadcrumbs.length <= 1) return;

        breadcrumbs.pop();
        breadcrumbPaths.pop();

        // Navigate back to the parent object
        var parentPath = breadcrumbPaths[breadcrumbPaths.length - 1];
        currentObject = getPropertyByPath(rootObject, parentPath);

        scrollOffset = 0;
        refreshSerializedData();
        updateDisplay();
    }

    /**
     * Edit a collection (Array or Map)
     */
    private function editCollection(prop:PropertyInfo):Void {
        // This could open a specialized collection editor
        // For now, let's navigate into the collection
        navigateToProperty(prop);
    }

    /**
     * Open static states menu
     */
    private function openStaticStatesMenu():Void {
        // Navigate to static states overview
        breadcrumbs.push("Static States");
        breadcrumbPaths.push("_static_states_");
        currentObject = getAllStateClasses();
        scrollOffset = 0;
        refreshSerializedData();
        updateDisplay();
    }

    override public function close():Void {
        // Restore original mouse state
        FlxG.mouse.visible = originalMouseVisible;
        #if desktop
        FlxG.mouse.useSystemCursor = originalCursorVisible;
        #end

        // Remove the overlay camera
        if (overlayCamera != null) {
            FlxG.cameras.remove(overlayCamera, true);
            overlayCamera = null;
        }

        super.close();
    }

    override public function destroy():Void {
        // Ensure cleanup even if close() wasn't called
        if (overlayCamera != null) {
            FlxG.cameras.remove(overlayCamera, true);
            overlayCamera = null;
        }

        super.destroy();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle input
        if (FlxG.keys.justPressed.ESCAPE) {
            close();
        }

        if (FlxG.keys.justPressed.UP) {
            scrollOffset = Std.int(Math.max(0, scrollOffset - 1));
            updateDisplay();
        }

        if (FlxG.keys.justPressed.DOWN) {
            scrollOffset = Std.int(Math.min(properties.length - maxVisibleItems, scrollOffset + 1));
            updateDisplay();
        }

        if (FlxG.keys.justPressed.BACKSPACE) {
            navigateBack();
        }
    }

    /**
     * Export current state as JSON for inspection
     */
    private function exportCurrentStateAsJSON():Void {
        try {
            var serialized = StateSerializer.createSerializableObject(FlxG.state);
            var jsonString = haxe.Json.stringify(serialized, null, "  ");

            #if sys
            var timestamp = Std.string(Date.now().getTime());
            var filename = 'debug_state_export_${timestamp}.json';
            sys.io.File.saveContent(filename, jsonString);
            trace('State exported to ${filename}');

            // Show a temporary notification in the debug overlay
            var notification = new FlxText(10, FlxG.height - 30, FlxG.width - 20, 'Exported to ${filename}', 12);
            notification.color = FlxColor.LIME;
            notification.cameras = [overlayCamera];
            add(notification);

            // Remove notification after 3 seconds
            var timer = new haxe.Timer(3000);
            timer.run = function() {
                remove(notification);
                timer.stop();
            };
            #else
            trace('State JSON (copy from console):');
            trace(jsonString);

            // Show notification that JSON was logged
            var notification = new FlxText(10, FlxG.height - 30, FlxG.width - 20, 'JSON exported to console log', 12);
            notification.color = FlxColor.LIME;
            notification.cameras = [overlayCamera];
            add(notification);

            // Remove notification after 3 seconds
            var timer = new haxe.Timer(3000);
            timer.run = function() {
                remove(notification);
                timer.stop();
            };
            #end
        } catch (e:Dynamic) {
            trace('Error exporting state as JSON: ${e}');

            // Show error notification
            var errorNotification = new FlxText(10, FlxG.height - 30, FlxG.width - 20, 'Export failed: ${e}', 12);
            errorNotification.color = FlxColor.RED;
            errorNotification.cameras = [overlayCamera];
            add(errorNotification);

            // Remove error notification after 5 seconds
            var timer = new haxe.Timer(5000);
            timer.run = function() {
                remove(errorNotification);
                timer.stop();
            };
        }
    }
}
