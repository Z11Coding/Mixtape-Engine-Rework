package debug;

import backend.MusicBeatState;
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

    // Static callback system for handling collection edits across substate transitions
    private static var activeOverlay:StateDebugOverlay = null;
    private static var pendingRefresh:Bool = false;

    /**
     * Static method to handle refresh requests from collection editors
     */
    public static function requestRefresh():Void {
        if (activeOverlay != null && activeOverlay.exists) {
            activeOverlay.refreshSerializedData();
            activeOverlay.updateDisplay();
        } else {
            pendingRefresh = true;
        }
    }

    private var backgroundPanel:FlxSprite;
    private var titleText:FlxText;
    private var breadcrumbText:FlxText;
    private var propertyList:FlxTypedGroup<FlxSprite>;
    private var scrollOffset:Int = 0;
    private var maxVisibleItems:Int = 15;

    // Collection editing mode
    private var collectionEditMode:Bool = false;
    private var currentCollection:Dynamic = null;
    private var currentCollectionPath:String = "";
    private var collectionType:String = ""; // "array" or "map"
    private var collectionKeys:Array<Dynamic> = [];

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
    private var canReturnToMainState:Bool = false; // Whether to show "Return to State" button

    // Property information structure
    private var propertyInfos:Map<String, PropertyInfo> = new Map();

    /**
     * Default constructor - debug current FlxG.state
     */
    public function new() {
        super();

        // Register as active overlay
        activeOverlay = this;

        initializeMouseState();

        // Initialize with current state and get its actual class name
        rootObject = FlxG.state;
        currentObject = rootObject;
        initializeOverlay();
    }

    /**
     * Initialize mouse state (shared by all constructors)
     */
    private function initializeMouseState():Void {
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
    }

    /**
     * Static factory: Create overlay for inspecting a specific object
     * @param customObject The object to inspect instead of the current state
     * @param objectLabel Optional label for the object (defaults to class name)
     * @return StateDebugOverlay instance
     */
    public static function forObject(customObject:Dynamic, ?objectLabel:String):StateDebugOverlay {
        var overlay = new StateDebugOverlay();

        @:privateAccess {
            // Override the default initialization
            overlay.rootObject = customObject;
            overlay.currentObject = customObject;

            // Set up breadcrumbs with custom label or class name
            if (objectLabel != null) {
                overlay.breadcrumbs = [objectLabel];
            } else if (customObject != null) {
                var className = Type.getClassName(Type.getClass(customObject));
                if (className != null) {
                    var parts = className.split(".");
                    overlay.breadcrumbs = [parts[parts.length - 1]];
                } else {
                    overlay.breadcrumbs = ["CustomObject"];
                }
            } else {
                overlay.breadcrumbs = ["NullObject"];
            }

            overlay.breadcrumbPaths = [overlay.breadcrumbs[0]];
            overlay.refreshSerializedData();
        }

        return overlay;
    }

    /**
     * Static factory: Create overlay for inspecting a specific field path
     * @param baseObject The root object to start from (if null, uses FlxG.state)
     * @param fieldPath Dot-separated path to the field (e.g., "player.stats.health") or array of path parts
     * @param canReturnToState Whether to show a "Return to State" button for quick navigation back
     * @return StateDebugOverlay instance
     */
    public static function forFieldPath(baseObject:Dynamic, fieldPath:Dynamic, canReturnToState:Bool = true):StateDebugOverlay {
        var overlay = new StateDebugOverlay();

        @:privateAccess {
            // Use provided base object or fall back to current state
            var rootObj = baseObject != null ? baseObject : FlxG.state;
            overlay.rootObject = rootObj;

            // Handle path as string or array
            var pathParts:Array<String> = [];
            if (Std.isOfType(fieldPath, String)) {
                pathParts = cast(fieldPath, String).split(".");
            } else if (Std.isOfType(fieldPath, Array)) {
                pathParts = cast fieldPath;
            } else {
                throw "fieldPath must be either a String or Array<String>";
            }

            // Navigate to the specific field path
            var currentObj:Dynamic = rootObj;
            var validPath:Bool = true;

            overlay.breadcrumbs = [];
            overlay.breadcrumbPaths = [];

            // Build path step by step starting with root object name
            var className = Type.getClassName(Type.getClass(rootObj));
            if (className != null) {
                var parts = className.split(".");
                overlay.breadcrumbs.push(parts[parts.length - 1]);
            } else {
                overlay.breadcrumbs.push("RootObject");
            }
            overlay.breadcrumbPaths.push("");

            for (part in pathParts) {
                if (currentObj == null) {
                    validPath = false;
                    break;
                }

                try {
                    var fieldValue = Reflect.field(currentObj, part);
                    if (fieldValue == null && !Reflect.hasField(currentObj, part)) {
                        validPath = false;
                        break;
                    }

                    overlay.breadcrumbs.push(part);
                    var newPath = overlay.breadcrumbPaths[overlay.breadcrumbPaths.length - 1];
                    if (newPath != "") newPath += ".";
                    newPath += part;
                    overlay.breadcrumbPaths.push(newPath);
                    currentObj = fieldValue;
                } catch (e:Dynamic) {
                    validPath = false;
                    break;
                }
            }

            if (validPath) {
                overlay.currentObject = currentObj;
                trace('Successfully navigated to field path: ${pathParts.join(".")}');
            } else {
                // Fall back to root if path is invalid
                overlay.currentObject = rootObj;
                overlay.breadcrumbs = [overlay.breadcrumbs[0]]; // Keep just the root
                overlay.breadcrumbPaths = [overlay.breadcrumbPaths[0]];
                trace('Invalid field path: ${pathParts.join(".")}, falling back to root object');
            }

            // Store whether we can return to main state view
            overlay.canReturnToMainState = canReturnToState;
            overlay.refreshSerializedData();
        }

        return overlay;
    }

    /**
     * Static factory: Create overlay for inspecting using breadcrumb array
     * @param baseObject The root object to start from (if null, uses FlxG.state)
     * @param breadcrumbArray Array of breadcrumb names ["State", "player", "stats", "health"]
     * @param pathArray Corresponding array of property paths ["", "player", "player.stats", "player.stats.health"]
     * @param canReturnToState Whether to show a "Return to State" button
     * @return StateDebugOverlay instance
     */
    public static function forBreadcrumbs(baseObject:Dynamic, breadcrumbArray:Array<String>, pathArray:Array<String>, canReturnToState:Bool = true):StateDebugOverlay {
        var overlay = new StateDebugOverlay();

        @:privateAccess {
            // Use provided base object or fall back to current state
            var rootObj = baseObject != null ? baseObject : FlxG.state;
            overlay.rootObject = rootObj;

            // Validate that breadcrumbs and paths match
            if (breadcrumbArray.length != pathArray.length) {
                throw "Breadcrumb array and path array must have the same length";
            }

            // Navigate to the final object using the last path
            var finalPath = pathArray[pathArray.length - 1];
            var finalObject = finalPath == "" ? rootObj : overlay.getPropertyByPath(rootObj, finalPath);

            if (finalObject == null) {
                // Fall back to root if path is invalid
                overlay.currentObject = rootObj;
                overlay.breadcrumbs = [breadcrumbArray[0]];
                overlay.breadcrumbPaths = [pathArray[0]];
                trace('Invalid breadcrumb path, falling back to root object');
            } else {
                overlay.currentObject = finalObject;
                overlay.breadcrumbs = breadcrumbArray.copy();
                overlay.breadcrumbPaths = pathArray.copy();
                trace('Successfully navigated using breadcrumbs to: ${breadcrumbArray.join(" -> ")}');
            }

            overlay.canReturnToMainState = canReturnToState;
            overlay.refreshSerializedData();
        }

        return overlay;
    }

    private function initializeOverlay():Void {
        // Only set up default breadcrumbs if they haven't been set by alternative constructors
        if (breadcrumbs.length == 0) {
            // Get the actual class name instead of just "FlxG.state"
            var stateClassName = Type.getClassName(Type.getClass(rootObject));
            if (stateClassName != null) {
                breadcrumbs = [stateClassName.split(".").pop()];
            } else {
                breadcrumbs = ["FlxG.state"];
            }
            breadcrumbPaths = [""];
        }

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
            serializedData = StateSerializer.createSerializableObject(currentObject);
            updateProperties();
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
                var baseInfo = 'Array<Dynamic>[${arr.length}]';

                if (ClientPrefs.data.debugTypeAnalysis) {
                    var typeAnalysis = analyzeCollectionTypes(value);
                    if (typeAnalysis != null) {
                        baseInfo = 'Array' + typeAnalysis + '[${arr.length}]';
                    }
                }

                return baseInfo;
            case TObject:
                if (value.isMap()) {
                    var map:Map<Dynamic, Dynamic> = cast value;

                    // Check if map is null
                    if (map == null) {
                        return 'Map<Dynamic, Dynamic>[null]';
                    }

                    var count = 0;

                    try {
                        // Simple key counting
                        for (k in map.keys()) {
                            count++;
                        }
                        var baseInfo = 'Map<Dynamic, Dynamic>[${count} keys]';

                        if (ClientPrefs.data.debugTypeAnalysis && count > 0) {
                            var typeAnalysis = analyzeCollectionTypes(value);
                            if (typeAnalysis != null) {
                                baseInfo = 'Map' + typeAnalysis + '[${count} keys]';
                            }
                        }

                        return baseInfo;
                    } catch (e:Dynamic) {
                        // Simple fallback - just return basic info
                        return 'Map<Dynamic, Dynamic>[? keys]';
                    }
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

        try {
            return Std.isOfType(value, Array) || value.isMap();
        } catch (e:Dynamic) {
            return false;
        }
    }    /**
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

        // Handle collection editing mode
        if (collectionEditMode) {
            updateCollectionEditDisplay();
            return;
        }

        // Update breadcrumb with clickable navigation
        updateBreadcrumbUI();

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

        // Add Return to State button if enabled
        if (canReturnToMainState) {
            var returnButton = new FlxButton(460, 60, "Return to State", function() {
                returnToMainState();
            });
            returnButton.color = FlxColor.PURPLE;
            returnButton.cameras = [overlayCamera];
            propertyList.add(returnButton);
        }

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
                        trace('Changed ' + prop.name + ' to "' + text + '"');
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
        if (value == null) return "[?] null collection";

        try {
            if (Std.isOfType(value, Array)) {
                var arr:Array<Dynamic> = cast value;
                return 'Array[${arr.length}]';
            } else if (value.isMap()) {
                var map:Map<Dynamic, Dynamic> = cast value;

                // Check if map is null
                if (map == null) {
                    return 'Map[null]';
                }

                var count = 0;

                try {
                    // Simple counting
                    for (k in map.keys()) {
                        count++;
                    }
                    return 'Map[${count} keys]';
                } catch (e:Dynamic) {
                    // Fallback for restored maps
                    return 'Map[? keys]';
                }
            }
        } catch (e:Dynamic) {
            return '[?] collection analysis failed';
        }

        return "Collection";
    }

    /**
     * Analyze the types of all elements in a collection
     * Returns formatted type string like " <String | Int | Bool>"
     */
    private function analyzeCollectionTypes(collection:Dynamic):String {
        if (!ClientPrefs.data.debugTypeAnalysis) return null;

        var typeSet:Map<String, Bool> = new Map();
        var sampleCount = 0;
        var maxSamples = 50; // Limit analysis to prevent performance issues

        try {
            if (Std.isOfType(collection, Array)) {
                var arr:Array<Dynamic> = cast collection;
                for (i in 0...Std.int(Math.min(arr.length, maxSamples))) {
                    var value = arr[i];
                    var typeStr = getElementTypeString(value);
                    typeSet.set(typeStr, true);
                    sampleCount++;
                }
            } else if (collection.isMap()) {
                var map:Map<Dynamic, Dynamic> = cast collection;
                try {
                    var count = 0;
                    // Simple iteration
                    for (key in map.keys()) {
                        if (count >= maxSamples) break;
                        var value = map.get(key);
                        var typeStr = getElementTypeString(value);
                        typeSet.set(typeStr, true);
                        sampleCount++;
                        count++;
                    }
                } catch (e:Dynamic) {
                    // Skip type analysis if iteration fails
                    return null;
                }
            }

            if (sampleCount == 0) return null;

            // Build type string
            var types:Array<String> = [];
            for (type in typeSet.keys()) {
                types.push(type);
            }

            if (types.length == 0) return null;

            // Sort types for consistent display
            types.sort(function(a:String, b:String):Int {
                // Prioritize common types
                var priority = function(t:String):Int {
                    switch (t) {
                        case "String": return 0;
                        case "Int": return 1;
                        case "Float": return 2;
                        case "Bool": return 3;
                        case "null": return 10;
                        default: return 5;
                    }
                };
                var priorityA = priority(a);
                var priorityB = priority(b);
                if (priorityA != priorityB) return priorityA - priorityB;
                return a < b ? -1 : (a > b ? 1 : 0);
            });

            var typeString = "<" + types.join(" | ") + ">";

            // Add sample indicator if we didn't analyze everything
            if (Std.isOfType(collection, Array)) {
                var arr:Array<Dynamic> = cast collection;
                if (arr.length > maxSamples) {
                    typeString += ' (${sampleCount}/${arr.length} sampled)';
                }
            } else if (sampleCount >= maxSamples) {
                typeString += ' (${sampleCount}+ sampled)';
            }

            return typeString;

        } catch (e:Dynamic) {
            trace('Error analyzing collection types: ${e}');
            return null;
        }
    }

    /**
     * Get type string for a single element in a collection
     */
    private function getElementTypeString(value:Dynamic):String {
        if (value == null) return "null";

        var type = Type.typeof(value);
        switch (type) {
            case TBool: return "Bool";
            case TInt: return "Int";
            case TFloat: return "Float";
            case TClass(String): return "String";
            case TClass(Array): return "Array";
            case TObject: return "Object";
            case TClass(c):
                var className = Type.getClassName(c);
                var parts = className.split(".");
                return parts[parts.length - 1]; // Return just the class name without package
            case TEnum(e):
                var enumName = Type.getEnumName(e);
                var parts = enumName.split(".");
                return parts[parts.length - 1]; // Return just the enum name without package
            default:
                return Std.string(type).split("(")[0]; // Clean up type display
        }
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
     * Enter collection editing mode for Arrays and Maps
     */
    private function editCollection(prop:PropertyInfo):Void {
        if (prop.value != null && prop.isCollection) {
            collectionEditMode = true;
            currentCollection = prop.value;
            currentCollectionPath = breadcrumbs.join(".") + (breadcrumbs.length > 0 ? "." : "") + prop.name;

            // Determine collection type and populate keys
            if (Std.isOfType(prop.value, Array)) {
                collectionType = "array";
                var arr:Array<Dynamic> = cast prop.value;
                collectionKeys = [];
                for (i in 0...arr.length) {
                    collectionKeys.push(i);
                }
            } else if (prop.value.isMap()) {
                collectionType = "map";
                var map:Map<Dynamic, Dynamic> = cast prop.value;
                collectionKeys = [];
                for (key in map.keys()) {
                    collectionKeys.push(key);
                }
            }

            // Add the actual property name as breadcrumb instead of generic [array]/[map]
            breadcrumbs.push(prop.name);
            breadcrumbPaths.push(currentCollectionPath);

            scrollOffset = 0;
            updateDisplay();
            trace('Entered collection editing mode for: ${currentCollectionPath}');
        } else {
            trace('Cannot edit collection - invalid property or not a collection');
        }
    }

    /**
     * Exit collection editing mode
     */
    private function exitCollectionEditMode():Void {
        if (collectionEditMode) {
            collectionEditMode = false;
            currentCollection = null;
            currentCollectionPath = "";
            collectionType = "";
            collectionKeys = [];

            // Remove collection breadcrumb
            if (breadcrumbs.length > 0) {
                breadcrumbs.pop();
            }
            if (breadcrumbPaths.length > 0) {
                breadcrumbPaths.pop();
            }

            // Navigate back to the previous level
            var parentPath = breadcrumbPaths.length > 0 ? breadcrumbPaths[breadcrumbPaths.length - 1] : "";
            if (parentPath != "") {
                currentObject = getPropertyByPath(rootObject, parentPath);
            } else {
                currentObject = rootObject;
            }

            scrollOffset = 0;
            refreshSerializedData();
            updateDisplay();
            trace('Exited collection editing mode');
        }
    }

    /**
     * Update display for collection editing mode
     */
    private function updateCollectionEditDisplay():Void {
        // Update breadcrumb to show collection editing
        breadcrumbText.text = "Editing: " + currentCollectionPath;

        var yPos:Float = 60;

        // Back button to exit collection editing
        var backButton = new FlxButton(10, yPos, "< Exit Editor", function() {
            exitCollectionEditMode();
        });
        backButton.color = FlxColor.RED;
        backButton.cameras = [overlayCamera];
        propertyList.add(backButton);

        // Collection info display
        var infoText = new FlxText(120, yPos, 400, 'Editing ' + collectionType + ' (' + collectionKeys.length + ' elements)', 12);
        infoText.color = FlxColor.CYAN;
        infoText.cameras = [overlayCamera];
        propertyList.add(infoText);

        yPos += 35;

        // Add new element button
        var addButton = new FlxButton(10, yPos, "+ Add Element", function() {
            addNewCollectionElement();
        });
        addButton.color = FlxColor.GREEN;
        addButton.cameras = [overlayCamera];
        propertyList.add(addButton);

        // For arrays, add sort buttons
        if (collectionType == "Array") {
            var sortUpButton = new FlxButton(130, yPos, "↑ Sort Up", function() {
                sortArrayElements(true);
            });
            sortUpButton.color = FlxColor.BLUE;
            sortUpButton.scale.set(0.8, 0.8);
            sortUpButton.updateHitbox();
            sortUpButton.cameras = [overlayCamera];
            propertyList.add(sortUpButton);

            var sortDownButton = new FlxButton(230, yPos, "↓ Sort Down", function() {
                sortArrayElements(false);
            });
            sortDownButton.color = FlxColor.BLUE;
            sortDownButton.scale.set(0.8, 0.8);
            sortDownButton.updateHitbox();
            sortDownButton.cameras = [overlayCamera];
            propertyList.add(sortDownButton);
        }

        yPos += 35;

        // Show collection elements with editing controls
        var visibleElements = collectionKeys.slice(scrollOffset, scrollOffset + (maxVisibleItems - 2));

        for (i in 0...visibleElements.length) {
            var keyIndex = scrollOffset + i;
            if (keyIndex >= collectionKeys.length) break;

            var key = collectionKeys[keyIndex];
            var element = getCollectionElement(currentCollection, key);
            var elementType = getElementTypeString(element);

            createCollectionElementUI(key, element, elementType, yPos, keyIndex);
            yPos += 40;
        }

        // Scroll indicators
        if (scrollOffset > 0) {
            var upText = new FlxText(FlxG.width - 100, 130, 90, "↑ More above", 12);
            upText.color = FlxColor.CYAN;
            upText.cameras = [overlayCamera];
            propertyList.add(upText);
        }

        if (scrollOffset + (maxVisibleItems - 2) < collectionKeys.length) {
            var downText = new FlxText(FlxG.width - 100, FlxG.height - 80, 90, "↓ More below", 12);
            downText.color = FlxColor.CYAN;
            downText.cameras = [overlayCamera];
            propertyList.add(downText);
        }
    }

    /**
     * Create UI for a single collection element
     */
    private function createCollectionElementUI(key:Dynamic, element:Dynamic, elementType:String, yPos:Float, keyIndex:Int):Void {
        // Key/Index display and editing
        if (collectionType == "map") {
            // For maps, show the key with proper breadcrumb syntax
            var propName = breadcrumbs[breadcrumbs.length - 1]; // Get the current property name
            var keyDisplayText = new FlxText(10, yPos + 12, 100, '${propName}[${key}]', 10);
            keyDisplayText.color = FlxColor.YELLOW;
            keyDisplayText.cameras = [overlayCamera];
            propertyList.add(keyDisplayText);

            // Allow key renaming with input field below
            var keyInput = new FlxUIInputText(10, yPos, 100, Std.string(key), 12);
            keyInput.callback = function(text:String, action:String) {
                if (action == "enter" && text != Std.string(key)) {
                    renameMapKey(key, text, keyIndex);
                }
            };
            keyInput.cameras = [overlayCamera];
            propertyList.add(keyInput);
        } else {
            // For arrays, show index with proper breadcrumb syntax
            var propName = breadcrumbs[breadcrumbs.length - 1]; // Get the current property name
            var indexText = new FlxText(10, yPos, 100, '${propName}[${key}]', 12);
            indexText.color = FlxColor.YELLOW;
            indexText.cameras = [overlayCamera];
            propertyList.add(indexText);

            // Array reordering buttons
            if (keyIndex > 0) {
                var upButton = new FlxButton(65, yPos, "↑", function() {
                    moveArrayElement(keyIndex, keyIndex - 1);
                });
                upButton.scale.set(0.5, 0.5);
                upButton.updateHitbox();
                upButton.cameras = [overlayCamera];
                propertyList.add(upButton);
            }

            if (keyIndex < collectionKeys.length - 1) {
                var downButton = new FlxButton(85, yPos, "↓", function() {
                    moveArrayElement(keyIndex, keyIndex + 1);
                });
                downButton.scale.set(0.5, 0.5);
                downButton.updateHitbox();
                downButton.cameras = [overlayCamera];
                propertyList.add(downButton);
            }
        }

        // Element type display
        var typeText = new FlxText(120, yPos + 12, 150, elementType, 10);
        typeText.color = FlxColor.GRAY;
        typeText.cameras = [overlayCamera];
        propertyList.add(typeText);

        // Element value display and editing
        var valueX:Float = 280;
        createElementValueUI(element, elementType, valueX, yPos, key);

        // Delete button
        var deleteButton = new FlxButton(FlxG.width - 80, yPos, "Delete", function() {
            deleteCollectionElement(key, keyIndex);
        });
        deleteButton.color = FlxColor.RED;
        deleteButton.scale.set(0.7, 0.7);
        deleteButton.updateHitbox();
        deleteButton.cameras = [overlayCamera];
        propertyList.add(deleteButton);
    }

    /**
     * Create UI for editing element values
     */
    private function createElementValueUI(element:Dynamic, elementType:String, x:Float, y:Float, key:Dynamic):Void {
        if (Std.isOfType(element, Bool)) {
            var toggleButton = new FlxButton(x, y, element ? "true" : "false", function() {
                var newValue = !cast(element, Bool);
                setCollectionElement(currentCollection, key, newValue);
                updateCollectionEditDisplay();
            });
            toggleButton.color = element ? FlxColor.GREEN : FlxColor.RED;
            toggleButton.scale.set(0.8, 0.8);
            toggleButton.updateHitbox();
            toggleButton.cameras = [overlayCamera];
            propertyList.add(toggleButton);
        } else if (Std.isOfType(element, String)) {
            var inputField = new FlxUIInputText(x, y, 150, Std.string(element), 12);
            inputField.callback = function(text:String, action:String) {
                if (action == "enter") {
                    setCollectionElement(currentCollection, key, text);
                }
            };
            inputField.cameras = [overlayCamera];
            propertyList.add(inputField);
        } else if (Std.isOfType(element, Int) || Std.isOfType(element, Float)) {
            createElementNumberUI(element, x, y, key);
        } else if (elementType.indexOf("Array") == 0 || elementType.indexOf("Map") == 0) {
            // Nested collection - show navigate button
            var navButton = new FlxButton(x, y, "Explore →", function() {
                // Create proper indexed path for the breadcrumb
                var keyStr = Std.string(key);
                var propName = breadcrumbs[breadcrumbs.length - 1];
                var indexedName = '${propName}[${keyStr}]';
                var indexedPath = currentCollectionPath + '[${keyStr}]';

                breadcrumbs.push(indexedName);
                breadcrumbPaths.push(indexedPath);
                currentObject = element;
                exitCollectionEditMode(); // Exit collection mode and navigate normally
            });
            navButton.color = FlxColor.CYAN;
            navButton.scale.set(0.8, 0.8);
            navButton.updateHitbox();
            navButton.cameras = [overlayCamera];
            propertyList.add(navButton);
        } else {
            // Complex object - show value and navigate button
            var valueText = new FlxText(x, y, 100, Std.string(element).substr(0, 20) + "...", 10);
            valueText.color = FlxColor.GRAY;
            valueText.cameras = [overlayCamera];
            propertyList.add(valueText);

            var navButton = new FlxButton(x + 105, y, "Edit", function() {
                // Create proper indexed path for the breadcrumb
                var keyStr = Std.string(key);
                var propName = breadcrumbs[breadcrumbs.length - 1];
                var indexedName = '${propName}[${keyStr}]';
                var indexedPath = currentCollectionPath + '[${keyStr}]';

                breadcrumbs.push(indexedName);
                breadcrumbPaths.push(indexedPath);
                currentObject = element;
                exitCollectionEditMode(); // Exit collection mode and navigate normally
            });
            navButton.color = FlxColor.ORANGE;
            navButton.scale.set(0.7, 0.7);
            navButton.updateHitbox();
            navButton.cameras = [overlayCamera];
            propertyList.add(navButton);
        }
    }

    /**
     * Create number editing UI for collection elements
     */
    private function createElementNumberUI(element:Dynamic, x:Float, y:Float, key:Dynamic):Void {
        var isInt = Std.isOfType(element, Int);
        var inputField = new FlxUIInputText(x, y, 80, Std.string(element), 12);
        inputField.callback = function(text:String, action:String) {
            if (action == "enter") {
                var newValue:Dynamic = isInt ? Std.parseInt(text) : Std.parseFloat(text);
                if (newValue != null) {
                    setCollectionElement(currentCollection, key, newValue);
                }
            }
        };
        inputField.cameras = [overlayCamera];
        propertyList.add(inputField);

        // +/- buttons
        var decButton = new FlxButton(x + 85, y, "-", function() {
            var currentVal:Float = isInt ? cast(element, Int) : cast(element, Float);
            var step:Float = isInt ? 1 : 0.1;
            var newValue:Dynamic = isInt ? Std.int(currentVal - step) : currentVal - step;
            setCollectionElement(currentCollection, key, newValue);
            updateCollectionEditDisplay();
        });
        decButton.scale.set(0.6, 0.6);
        decButton.updateHitbox();
        decButton.cameras = [overlayCamera];
        propertyList.add(decButton);

        var incButton = new FlxButton(x + 115, y, "+", function() {
            var currentVal:Float = isInt ? cast(element, Int) : cast(element, Float);
            var step:Float = isInt ? 1 : 0.1;
            var newValue:Dynamic = isInt ? Std.int(currentVal + step) : currentVal + step;
            setCollectionElement(currentCollection, key, newValue);
            updateCollectionEditDisplay();
        });
        incButton.scale.set(0.6, 0.6);
        incButton.updateHitbox();
        incButton.cameras = [overlayCamera];
        propertyList.add(incButton);
    }

    /**
     * Get or set collection element
     */
    private function getCollectionElement(collection:Dynamic, key:String):Dynamic {
        if (Std.isOfType(collection, Array)) {
            var arr:Array<Dynamic> = cast collection;
            var index = Std.parseInt(key);
            return (index != null && index >= 0 && index < arr.length) ? arr[index] : null;
        } else if (Reflect.hasField(collection, "get")) {
            // Map-like object
            return Reflect.callMethod(collection, Reflect.field(collection, "get"), [key]);
        } else {
            return Reflect.getProperty(collection, key);
        }
    }

    private function setCollectionElement(collection:Dynamic, key:String, value:Dynamic):Void {
        if (Std.isOfType(collection, Array)) {
            var arr:Array<Dynamic> = cast collection;
            var index = Std.parseInt(key);
            if (index != null && index >= 0 && index < arr.length) {
                arr[index] = value;
                trace('Set array element [' + index + '] to ' + value);
            }
        } else if (Reflect.hasField(collection, "set")) {
            // Map-like object
            Reflect.callMethod(collection, Reflect.field(collection, "set"), [key, value]);
            trace('Set map element "' + key + '" to ' + value);
        } else {
            Reflect.setProperty(collection, key, value);
            trace('Set property "' + key + '" to ' + value);
        }
    }

    /**
     * Add new element to collection
     */
    private function addNewCollectionElement():Void {
        if (currentCollection == null) return;

        if (collectionType == "Array") {
            var arr:Array<Dynamic> = cast currentCollection;
            // Analyze existing elements to determine default type
            var defaultValue = analyzeArrayForDefaultValue(arr);
            arr.push(defaultValue);

            // Refresh collection keys
            collectionKeys = [];
            for (i in 0...arr.length) {
                collectionKeys.push(Std.string(i));
            }

            trace('Added new array element: ' + defaultValue);
        } else if (Reflect.hasField(currentCollection, "set")) {
            // Map-like object - ask for key name
            var keyName = "newKey" + Date.now().getTime();
            var defaultValue = "newValue";

            Reflect.callMethod(currentCollection, Reflect.field(currentCollection, "set"), [keyName, defaultValue]);
            collectionKeys.push(keyName);

            trace('Added new map element: "' + keyName + '" -> "' + defaultValue + '"');
        }

        updateCollectionEditDisplay();
    }

    /**
     * Analyze array to determine appropriate default value for new elements
     */
    private function analyzeArrayForDefaultValue(arr:Array<Dynamic>):Dynamic {
        if (arr.length == 0) return "";

        var types = new Map<String, Int>();
        for (element in arr) {
            if (element == null) continue;

            var typeName = getElementTypeString(element).split("[")[0]; // Remove array size
            var count = types.exists(typeName) ? types.get(typeName) : 0;
            types.set(typeName, count + 1);
        }

        // Find most common type
        var maxCount = 0;
        var mostCommonType = "String";
        for (type in types.keys()) {
            if (types.get(type) > maxCount) {
                maxCount = types.get(type);
                mostCommonType = type;
            }
        }

        // Return appropriate default value
        switch (mostCommonType) {
            case "Int": return 0;
            case "Float": return 0.0;
            case "Bool": return false;
            case "String": return "";
            default: return null;
        }
    }

    /**
     * Delete collection element
     */
    private function deleteCollectionElement(key:String, keyIndex:Int):Void {
        if (currentCollection == null) return;

        if (collectionType == "Array") {
            var arr:Array<Dynamic> = cast currentCollection;
            var index = Std.parseInt(key);
            if (index != null && index >= 0 && index < arr.length) {
                arr.splice(index, 1);

                // Refresh collection keys
                collectionKeys = [];
                for (i in 0...arr.length) {
                    collectionKeys.push(Std.string(i));
                }

                trace('Deleted array element at index ' + index);
            }
        } else if (Reflect.hasField(currentCollection, "remove")) {
            // Map-like object
            Reflect.callMethod(currentCollection, Reflect.field(currentCollection, "remove"), [key]);
            collectionKeys.splice(keyIndex, 1);
            trace('Deleted map element "' + key + '"');
        }

        // Adjust scroll offset if needed
        if (scrollOffset >= collectionKeys.length && scrollOffset > 0) {
            scrollOffset = Std.int(Math.max(0, collectionKeys.length - maxVisibleItems + 2));
        }

        updateCollectionEditDisplay();
    }

    /**
     * Move array element to new position
     */
    private function moveArrayElement(fromIndex:Int, toIndex:Int):Void {
        if (collectionType != "Array" || currentCollection == null) return;

        var arr:Array<Dynamic> = cast currentCollection;
        if (fromIndex < 0 || fromIndex >= arr.length || toIndex < 0 || toIndex >= arr.length) return;

        var element = arr.splice(fromIndex, 1)[0];
        arr.insert(toIndex, element);

        // Refresh collection keys
        collectionKeys = [];
        for (i in 0...arr.length) {
            collectionKeys.push(Std.string(i));
        }

        trace('Moved array element from index ' + fromIndex + ' to ' + toIndex);
        updateCollectionEditDisplay();
    }

    /**
     * Rename map key
     */
    private function renameMapKey(oldKey:String, newKey:String, keyIndex:Int):Void {
        if (collectionType != "Map" || currentCollection == null || oldKey == newKey) return;

        // Check if new key already exists
        if (Reflect.hasField(currentCollection, "exists") &&
            Reflect.callMethod(currentCollection, Reflect.field(currentCollection, "exists"), [newKey])) {
            trace('Map key "' + newKey + '" already exists');
            return;
        }

        // Get current value
        var value = getCollectionElement(currentCollection, oldKey);

        // Set new key with same value
        setCollectionElement(currentCollection, newKey, value);

        // Remove old key
        if (Reflect.hasField(currentCollection, "remove")) {
            Reflect.callMethod(currentCollection, Reflect.field(currentCollection, "remove"), [oldKey]);
        }

        // Update collection keys
        collectionKeys[keyIndex] = newKey;

        trace('Renamed map key "' + oldKey + '" to "' + newKey + '"');
        updateCollectionEditDisplay();
    }

    /**
     * Sort array elements
     */
    private function sortArrayElements(ascending:Bool):Void {
        if (collectionType != "Array" || currentCollection == null) return;

        var arr:Array<Dynamic> = cast currentCollection;
        if (arr.length <= 1) return;

        // Simple sort based on string representation
        arr.sort(function(a:Dynamic, b:Dynamic):Int {
            var aStr = Std.string(a);
            var bStr = Std.string(b);

            if (ascending) {
                return aStr < bStr ? -1 : (aStr > bStr ? 1 : 0);
            } else {
                return aStr > bStr ? -1 : (aStr < bStr ? 1 : 0);
            }
        });

        trace('Sorted array elements ' + (ascending ? 'ascending' : 'descending'));
        updateCollectionEditDisplay();
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

    /**
     * Return to main state view (root level)
     * Used by the alternative constructors to provide quick navigation back
     */
    private function returnToMainState():Void {
        // Reset to root state
        currentObject = rootObject;
        scrollOffset = 0;

        // Reset breadcrumbs to just the root
        var stateClassName = Type.getClassName(Type.getClass(rootObject));
        if (stateClassName != null) {
            breadcrumbs = [stateClassName.split(".").pop()];
        } else {
            breadcrumbs = ["State"];
        }
        breadcrumbPaths = [breadcrumbs[0]];

        refreshSerializedData();
        updateDisplay();

        trace('Returned to main state view');
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
        // Clear active overlay reference if this is the active one
        if (activeOverlay == this) {
            activeOverlay = null;
        }

        // Ensure cleanup even if close() wasn't called
        if (overlayCamera != null) {
            FlxG.cameras.remove(overlayCamera, true);
            overlayCamera = null;
        }

        super.destroy();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle pending refresh when overlay becomes active again
        if (pendingRefresh) {
            pendingRefresh = false;
            refreshSerializedData();
            updateDisplay();
        }

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
            var jsonString = tjson.TJSON.encode(serialized, "fancy");

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

    /**
     * Create clickable breadcrumb navigation UI
     */
    private function updateBreadcrumbUI():Void {
        // Clear previous breadcrumb text and show clickable breadcrumbs
        var breadcrumbStr = "";
        var xPos:Float = 10;

        for (i in 0...breadcrumbs.length) {
            if (i > 0) {
                // Add separator
                var separator = new FlxText(xPos, 35, 20, " -> ", 12);
                separator.color = FlxColor.YELLOW;
                separator.cameras = [overlayCamera];
                propertyList.add(separator);
                xPos += 30;
            }

            var breadcrumbText = breadcrumbs[i];
            var isLastBreadcrumb = (i == breadcrumbs.length - 1);

            if (isLastBreadcrumb || i == 0) {
                // Current location or root - just show as text
                var text = new FlxText(xPos, 35, 150, breadcrumbText, 12);
                text.color = isLastBreadcrumb ? FlxColor.WHITE : FlxColor.YELLOW;
                text.cameras = [overlayCamera];
                propertyList.add(text);
                xPos += text.width + 5;
            } else {
                // Clickable breadcrumb button
                var button = new FlxButton(xPos, 33, breadcrumbText, function() {
                    navigateToBreadcrumb(i);
                });
                button.color = FlxColor.CYAN;
                button.scale.set(0.8, 0.8);
                button.updateHitbox();
                button.cameras = [overlayCamera];
                propertyList.add(button);
                xPos += button.width + 5;
            }
        }
    }

    /**
     * Navigate to a specific breadcrumb level
     */
    private function navigateToBreadcrumb(targetIndex:Int):Void {
        if (targetIndex < 0 || targetIndex >= breadcrumbs.length) {
            return;
        }

        // Exit collection editing if we're in it
        if (collectionEditMode) {
            exitCollectionEditMode();
        }

        // Trim breadcrumbs and paths to the target index
        breadcrumbs = breadcrumbs.slice(0, targetIndex + 1);
        breadcrumbPaths = breadcrumbPaths.slice(0, targetIndex + 1);

        // Navigate to the target object
        var targetPath = breadcrumbPaths[targetIndex];
        if (targetPath == "" || targetPath == breadcrumbs[0]) {
            // Root object
            currentObject = rootObject;
        } else {
            // Find object at path (need to handle indexed paths)
            currentObject = getObjectByPath(rootObject, targetPath);
        }

        scrollOffset = 0;
        updateDisplay();
    }

    /**
     * Get an object by a path that may include indexed access like "prop[0]" or "map[key]"
     */
    private function getObjectByPath(rootObj:Dynamic, path:String):Dynamic {
        if (path == "" || rootObj == null) {
            return rootObj;
        }

        var current = rootObj;
        var parts = path.split(".");

        for (part in parts) {
            if (part == "") continue;

            // Check if this part has indexing syntax like "prop[index]"
            var indexStart = part.indexOf("[");
            var indexEnd = part.indexOf("]");

            if (indexStart > 0 && indexEnd > indexStart) {
                // This is an indexed access like "prop[0]" or "map[key]"
                var propName = part.substring(0, indexStart);
                var indexStr = part.substring(indexStart + 1, indexEnd);

                // Get the property first
                current = Reflect.field(current, propName);
                if (current == null) return null;

                // Then access the index
                if (Std.isOfType(current, Array)) {
                    var arr:Array<Dynamic> = cast current;
                    var index = Std.parseInt(indexStr);
                    if (index != null && index >= 0 && index < arr.length) {
                        current = arr[index];
                    } else {
                        return null;
                    }
                } else if (current.isMap()) {
                    var map:Map<Dynamic, Dynamic> = cast current;
                    // Try to parse the index as different types
                    var key:Dynamic = indexStr;
                    var intKey = Std.parseInt(indexStr);
                    var floatKey = Std.parseFloat(indexStr);

                    if (intKey != null && Std.string(intKey) == indexStr) {
                        key = intKey;
                    } else if (!Math.isNaN(floatKey) && Std.string(floatKey) == indexStr) {
                        key = floatKey;
                    } else if (indexStr == "true") {
                        key = true;
                    } else if (indexStr == "false") {
                        key = false;
                    } else if (indexStr == "null") {
                        key = null;
                    }
                    // Otherwise keep as string

                    current = map.get(key);
                } else {
                    return null;
                }
            } else {
                // Regular property access
                current = Reflect.field(current, part);
                if (current == null) return null;
            }
        }

        return current;
    }
}
