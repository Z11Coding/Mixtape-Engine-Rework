package states.editors;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import substates.Prompt;
import yutautil.typeregistry.RuntimeRegistry;
import yutautil.typeregistry.SourceMapper;
import yutautil.typeregistry.TypeRegistryAPI;
import yutautil.typeregistry.Typer;

using StringTools;
#if HSCRIPT_ALLOWED
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
#end


/**
 * Debug state for object creation, modification, and testing
 * Includes a terminal interface for running code and accessing commands
 */
class ObjectDebugState extends MusicBeatState {
    // UI Groups
    var objectPanel:FlxTypedGroup<FlxSprite>;
    var terminalPanel:FlxTypedGroup<FlxSprite>;
    var inspectorPanel:FlxTypedGroup<FlxSprite>;

    // Object management
    var objectList:FlxUIList;
    var typeDropdown:FlxUIDropDownMenu;
    var createButton:FlxButton;
    var deleteButton:FlxButton;
    var cloneButton:FlxButton;

    // Terminal
    var terminalOutput:FlxText;
    var terminalInput:FlxUIInputText;
    var executeButton:FlxButton;
    var clearButton:FlxButton;
    var commandHistory:Array<String>;
    var historyIndex:Int = 0;

    // Inspector
    var inspectorText:FlxText;
    var propertyInput:FlxUIInputText;
    var valueInput:FlxUIInputText;
    var setPropertyButton:FlxButton;

    // Debug objects storage
    var debugObjects:Map<String, Dynamic>;
    var selectedObject:String;
    var objectCounter:Int = 0;

    // HScript integration
    #if HSCRIPT_ALLOWED
    var hscriptParser:Parser;
    var hscriptInterp:Interp;
    #end

    // Terminal output buffer
    var terminalLines:Array<String>;
    var maxTerminalLines:Int = 50;

    // UI Constants
    static final PANEL_HEIGHT:Int = 400;
    static final MARGIN:Int = 10;

    override function create() {
        super.create();

        // Initialize data structures
        debugObjects = new Map();
        commandHistory = [];
        terminalLines = [];

        #if HSCRIPT_ALLOWED
        setupHScript();
        #end

        // Create background
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(20, 25, 30));
        add(bg);

        // Initialize UI groups
        objectPanel = new FlxTypedGroup<FlxSprite>();
        terminalPanel = new FlxTypedGroup<FlxSprite>();
        inspectorPanel = new FlxTypedGroup<FlxSprite>();

        // Create UI panels
        createObjectPanel();
        createTerminalPanel();
        createInspectorPanel();

        // Add groups
        add(objectPanel);
        add(terminalPanel);
        add(inspectorPanel);

        // Create navigation
        createNavigation();

        // Initialize
        refreshTypeList();
        addTerminalLine("Object Debug Terminal initialized");
        addTerminalLine("Type 'help' for available commands");

        trace("ObjectDebugState: Created successfully");
    }

    #if HSCRIPT_ALLOWED
    function setupHScript():Void {
        hscriptParser = new Parser();
        hscriptInterp = new Interp();

        // Add standard functions
        hscriptInterp.variables.set("trace", function(v:Dynamic) {
            addTerminalLine("[Script] " + Std.string(v));
        });
        hscriptInterp.variables.set("Math", Math);
        hscriptInterp.variables.set("Std", Std);
        hscriptInterp.variables.set("Type", Type);
        hscriptInterp.variables.set("Reflect", Reflect);
        hscriptInterp.variables.set("StringTools", StringTools);
        hscriptInterp.variables.set("FlxG", FlxG);

        // Add type registry access
        hscriptInterp.variables.set("TypeRegistry", TypeRegistryAPI);
        hscriptInterp.variables.set("Typer", Typer);

        // Add debug object access
        hscriptInterp.variables.set("getObject", function(name:String) {
            return debugObjects.get(name);
        });
        hscriptInterp.variables.set("setObject", function(name:String, obj:Dynamic) {
            debugObjects.set(name, obj);
            refreshObjectList();
            return obj;
        });
        hscriptInterp.variables.set("listObjects", function() {
            return [for (key in debugObjects.keys()) key];
        });

        // Add command prompt access
        hscriptInterp.variables.set("cmd", function(command:String) {
            return executeCommandPromptCommand(command);
        });
    }
    #end

    function createObjectPanel():Void {
        var panelWidth = Std.int(FlxG.width * 0.25);
        var panelBg = new FlxSprite(MARGIN, MARGIN).makeGraphic(panelWidth, PANEL_HEIGHT, FlxColor.fromRGB(30, 35, 40));
        objectPanel.add(panelBg);

        // Title
        var title = new FlxText(MARGIN + 10, MARGIN + 10, panelWidth - 20, "Debug Objects");
        title.setFormat(null, 14, FlxColor.WHITE, LEFT);
        objectPanel.add(title);

        // Type selector
        typeDropdown = new FlxUIDropDownMenu(MARGIN + 10, MARGIN + 35, ["Loading..."], function(typeName:String) {
            // Type selected for creation
        });
        typeDropdown.dropPanel.color = FlxColor.fromRGB(50, 55, 60);
        objectPanel.add(typeDropdown);

        // Create button
        createButton = new FlxButton(MARGIN + 10, MARGIN + 65, "Create", function() {
            createObject();
        });
        createButton.color = FlxColor.fromRGB(100, 150, 100);
        objectPanel.add(createButton);

        // Object list
        objectList = new FlxUIList(MARGIN + 10, MARGIN + 100, ["No objects"], panelWidth - 20, 200, false, 11, FlxColor.WHITE);
        objectList.callback = function(objectName:String) {
            selectObject(objectName);
        };
        objectPanel.add(objectList);

        // Object controls
        var buttonY = PANEL_HEIGHT - 60;

        cloneButton = new FlxButton(MARGIN + 10, buttonY, "Clone", function() {
            cloneObject();
        });
        cloneButton.color = FlxColor.fromRGB(100, 100, 150);
        objectPanel.add(cloneButton);

        deleteButton = new FlxButton(MARGIN + 70, buttonY, "Delete", function() {
            deleteObject();
        });
        deleteButton.color = FlxColor.fromRGB(150, 100, 100);
        objectPanel.add(deleteButton);

        var inspectBtn = new FlxButton(MARGIN + 130, buttonY, "Inspect", function() {
            inspectObject();
        });
        inspectBtn.color = FlxColor.fromRGB(150, 150, 100);
        objectPanel.add(inspectBtn);

        var testBtn = new FlxButton(MARGIN + 10, buttonY + 25, "Test", function() {
            testObject();
        });
        testBtn.color = FlxColor.fromRGB(100, 150, 150);
        objectPanel.add(testBtn);
    }

    function createTerminalPanel():Void {
        var panelX = MARGIN + Std.int(FlxG.width * 0.25) + MARGIN;
        var panelWidth = Std.int(FlxG.width * 0.5);
        var panelBg = new FlxSprite(panelX, MARGIN).makeGraphic(panelWidth, PANEL_HEIGHT, FlxColor.fromRGB(15, 20, 25));
        terminalPanel.add(panelBg);

        // Title
        var title = new FlxText(panelX + 10, MARGIN + 10, panelWidth - 20, "Debug Terminal");
        title.setFormat(null, 14, FlxColor.WHITE, LEFT);
        terminalPanel.add(title);

        // Terminal output
        terminalOutput = new FlxText(panelX + 10, MARGIN + 35, panelWidth - 20, "");
        terminalOutput.setFormat("_sans", 10, FlxColor.LIME, LEFT);
        terminalOutput.wordWrap = true;
        terminalPanel.add(terminalOutput);

        // Terminal input
        terminalInput = new FlxUIInputText(panelX + 10, PANEL_HEIGHT - 60, panelWidth - 100, 25, null, 11, FlxColor.WHITE, FlxColor.fromRGB(25, 30, 35));
        terminalInput.callback = function(text:String, action:String) {
            if (action == "enter") {
                executeTerminalCommand();
            }
        };
        terminalPanel.add(terminalInput);

        // Execute button
        executeButton = new FlxButton(panelX + panelWidth - 85, PANEL_HEIGHT - 60, "Execute", function() {
            executeTerminalCommand();
        });
        executeButton.color = FlxColor.fromRGB(100, 150, 100);
        terminalPanel.add(executeButton);

        // Clear button
        clearButton = new FlxButton(panelX + panelWidth - 85, PANEL_HEIGHT - 30, "Clear", function() {
            clearTerminal();
        });
        clearButton.color = FlxColor.fromRGB(150, 100, 100);
        terminalPanel.add(clearButton);
    }

    function createInspectorPanel():Void {
        var panelX = FlxG.width - Std.int(FlxG.width * 0.25) - MARGIN;
        var panelWidth = Std.int(FlxG.width * 0.25);
        var panelBg = new FlxSprite(panelX, MARGIN).makeGraphic(panelWidth, PANEL_HEIGHT, FlxColor.fromRGB(25, 30, 35));
        inspectorPanel.add(panelBg);

        // Title
        var title = new FlxText(panelX + 10, MARGIN + 10, panelWidth - 20, "Object Inspector");
        title.setFormat(null, 14, FlxColor.WHITE, LEFT);
        inspectorPanel.add(title);

        // Object info display
        inspectorText = new FlxText(panelX + 10, MARGIN + 35, panelWidth - 20, "No object selected");
        inspectorText.setFormat(null, 9, FlxColor.GRAY, LEFT);
        inspectorText.wordWrap = true;
        inspectorPanel.add(inspectorText);

        // Property editor
        var propY = PANEL_HEIGHT - 120;
        var propTitle = new FlxText(panelX + 10, propY, panelWidth - 20, "Edit Property:");
        propTitle.setFormat(null, 11, FlxColor.WHITE, LEFT);
        inspectorPanel.add(propTitle);

        propertyInput = new FlxUIInputText(panelX + 10, propY + 20, panelWidth - 20, 20, null, 10, FlxColor.WHITE, FlxColor.fromRGB(35, 40, 45));
        propertyInput.text = "property";
        inspectorPanel.add(propertyInput);

        valueInput = new FlxUIInputText(panelX + 10, propY + 45, panelWidth - 20, 20, null, 10, FlxColor.WHITE, FlxColor.fromRGB(35, 40, 45));
        valueInput.text = "value";
        inspectorPanel.add(valueInput);

        setPropertyButton = new FlxButton(panelX + 10, propY + 70, "Set", function() {
            setObjectProperty();
        });
        setPropertyButton.color = FlxColor.fromRGB(100, 150, 100);
        inspectorPanel.add(setPropertyButton);

        var refreshBtn = new FlxButton(panelX + 60, propY + 70, "Refresh", function() {
            refreshInspector();
        });
        refreshBtn.color = FlxColor.fromRGB(100, 100, 150);
        inspectorPanel.add(refreshBtn);
    }

    function createNavigation():Void {
        // Back button
        var backBtn = new FlxButton(FlxG.width - 80, 10, "Back", function() {
            exitDebugger();
        });
        backBtn.color = FlxColor.fromRGB(180, 80, 80);
        add(backBtn);

        // Quick access buttons
        var editorBtn = new FlxButton(FlxG.width - 160, 10, "Editor", function() {
            FlxG.switchState(new SourceEditorState());
        });
        editorBtn.color = FlxColor.fromRGB(80, 120, 180);
        add(editorBtn);
    }

    // === Object Management ===

    function refreshTypeList():Void {
        var types = ["Dynamic", "String", "Int", "Float", "Bool", "Array<Dynamic>"];

        try {
            var registryTypes = TypeRegistryAPI.getAllClasses();
            for (type in registryTypes.slice(0, 10)) { // Limit to prevent overflow
                if (types.indexOf(type) == -1) {
                    types.push(type);
                }
            }
        } catch (e:Dynamic) {
            addTerminalLine("Warning: Could not load registry types: " + e);
        }

        typeDropdown.setData(types);
    }

    function createObject():Void {
        var typeName = typeDropdown.selectedLabel;
        if (typeName == null) return;

        var objectName = "obj" + (++objectCounter);
        var obj:Dynamic = null;

        try {
            switch (typeName) {
                case "Dynamic":
                    obj = {};
                case "String":
                    obj = "Hello World";
                case "Int":
                    obj = 42;
                case "Float":
                    obj = 3.14;
                case "Bool":
                    obj = true;
                case "Array<Dynamic>":
                    obj = [];
                default:
                    // Try to create instance using type registry
                    obj = createTypeInstance(typeName);
            }

            if (obj != null) {
                debugObjects.set(objectName, obj);
                refreshObjectList();
                addTerminalLine('Created object "$objectName" of type "$typeName"');
            } else {
                addTerminalLine('Failed to create object of type "$typeName"');
            }
        } catch (e:Dynamic) {
            addTerminalLine('Error creating object: $e');
        }
    }

    function createTypeInstance(typeName:String):Dynamic {
        try {
            var typeClass = Type.resolveClass(typeName);
            if (typeClass != null) {
                return Type.createInstance(typeClass, []);
            }

            // Try through type registry
            var typeInfo = TypeRegistryAPI.getTypeInfo(typeName);
            if (typeInfo != null) {
                return {}; // Create basic object as placeholder
            }

            return null;
        } catch (e:Dynamic) {
            return null;
        }
    }

    function refreshObjectList():Void {
        var objectNames = [for (key in debugObjects.keys()) key];
        if (objectNames.length == 0) {
            objectNames = ["No objects"];
        }
        objectList.setData(objectNames);
    }

    function selectObject(objectName:String):Void {
        if (debugObjects.exists(objectName)) {
            selectedObject = objectName;
            refreshInspector();
            addTerminalLine('Selected object: $objectName');
        }
    }

    function cloneObject():Void {
        if (selectedObject == null || !debugObjects.exists(selectedObject)) {
            addTerminalLine("No object selected for cloning");
            return;
        }

        var original = debugObjects.get(selectedObject);
        var cloneName = selectedObject + "_clone" + objectCounter++;

        try {
            // Simple clone (shallow copy)
            var clone = Reflect.copy(original);
            debugObjects.set(cloneName, clone);
            refreshObjectList();
            addTerminalLine('Cloned object "$selectedObject" to "$cloneName"');
        } catch (e:Dynamic) {
            addTerminalLine('Error cloning object: $e');
        }
    }

    function deleteObject():Void {
        if (selectedObject == null || !debugObjects.exists(selectedObject)) {
            addTerminalLine("No object selected for deletion");
            return;
        }

        debugObjects.remove(selectedObject);
        refreshObjectList();
        addTerminalLine('Deleted object: $selectedObject');

        selectedObject = null;
        refreshInspector();
    }

    function inspectObject():Void {
        if (selectedObject == null || !debugObjects.exists(selectedObject)) {
            addTerminalLine("No object selected for inspection");
            return;
        }

        var obj = debugObjects.get(selectedObject);
        var inspection = TypeRegistryAPI.inspect(obj);

        var info = 'Object: $selectedObject\n';
        info += 'Native Type: ${inspection.nativeType}\n';
        info += 'Best Match: ${inspection.bestMatch}\n';
        info += 'Confidence: ${Math.round(inspection.confidence * 100)}%\n';
        info += 'Most Specific: ${inspection.mostSpecific}\n';

        addTerminalLine("=== Object Inspection ===");
        addTerminalLine(info);
        addTerminalLine("========================");
    }

    function testObject():Void {
        if (selectedObject == null || !debugObjects.exists(selectedObject)) {
            addTerminalLine("No object selected for testing");
            return;
        }

        var obj = debugObjects.get(selectedObject);

        // Run basic tests
        addTerminalLine('=== Testing object: $selectedObject ===');
        addTerminalLine('toString(): ${Std.string(obj)}');
        addTerminalLine('Type: ${Type.typeof(obj)}');

        // Test type checking
        var allTypes = TypeRegistryAPI.getAllPossibleTypes(obj);
        addTerminalLine('Possible types (${allTypes.length}):');
        for (typeInfo in allTypes.slice(0, 5)) {
            addTerminalLine('  - ${typeInfo.name} (${Math.round(typeInfo.confidence * 100)}%)');
        }

        addTerminalLine("================");
    }

    // === Inspector ===

    function refreshInspector():Void {
        if (selectedObject == null || !debugObjects.exists(selectedObject)) {
            inspectorText.text = "No object selected";
            return;
        }

        var obj = debugObjects.get(selectedObject);
        var info = new StringBuf();

        info.add('Object: $selectedObject\n');
        info.add('Type: ${Type.typeof(obj)}\n');
        info.add('String: ${Std.string(obj)}\n\n');

        // List properties
        info.add('Properties:\n');
        var fields = Reflect.fields(obj);
        if (fields.length == 0) {
            info.add('  (no fields)\n');
        } else {
            for (field in fields.slice(0, 10)) { // Limit displayed fields
                var value = Reflect.field(obj, field);
                var valueStr = Std.string(value);
                if (valueStr.length > 30) {
                    valueStr = valueStr.substr(0, 27) + "...";
                }
                info.add('  $field: $valueStr\n');
            }
            if (fields.length > 10) {
                info.add('  ... and ${fields.length - 10} more\n');
            }
        }

        inspectorText.text = info.toString();
    }

    function setObjectProperty():Void {
        if (selectedObject == null || !debugObjects.exists(selectedObject)) {
            addTerminalLine("No object selected");
            return;
        }

        var property = propertyInput.text;
        var valueStr = valueInput.text;

        if (property.length == 0) {
            addTerminalLine("Property name cannot be empty");
            return;
        }

        var obj = debugObjects.get(selectedObject);
        var value:Dynamic = valueStr;

        // Try to parse value as appropriate type
        if (valueStr == "true") value = true;
        else if (valueStr == "false") value = false;
        else if (valueStr == "null") value = null;
        else {
            var intVal = Std.parseInt(valueStr);
            if (intVal != null && Std.string(intVal) == valueStr) {
                value = intVal;
            } else {
                var floatVal = Std.parseFloat(valueStr);
                if (!Math.isNaN(floatVal) && Std.string(floatVal) == valueStr) {
                    value = floatVal;
                }
            }
        }

        try {
            Reflect.setField(obj, property, value);
            addTerminalLine('Set $selectedObject.$property = $value');
            refreshInspector();
        } catch (e:Dynamic) {
            addTerminalLine('Error setting property: $e');
        }
    }

    // === Terminal ===

    function executeTerminalCommand():Void {
        var command = terminalInput.text.trim();
        if (command.length == 0) return;

        // Add to history
        commandHistory.push(command);
        historyIndex = commandHistory.length;

        // Show command in output
        addTerminalLine("> " + command);

        // Clear input
        terminalInput.text = "";

        // Execute command
        executeCommand(command);
    }

    function executeCommand(command:String):Void {
        var parts = command.split(" ");
        var cmd = parts[0].toLowerCase();

        switch (cmd) {
            case "help":
                showHelp();
            case "clear":
                clearTerminal();
            case "list":
                listObjects();
            case "create":
                createObjectCommand(parts);
            case "delete":
                deleteObjectCommand(parts);
            case "inspect":
                inspectObjectCommand(parts);
            case "set":
                setPropertyCommand(parts);
            case "get":
                getPropertyCommand(parts);
            case "test":
                testObjectCommand(parts);
            case "types":
                listTypes();
            case "cmd":
                executeCommandPromptCommand(command.substr(4));
            case "hscript" | "hs":
                executeHScript(command.substr(cmd.length + 1));
            case "load":
                loadScript(parts);
            case "save":
                saveObject(parts);
            default:
                // Try as HScript if enabled
                #if HSCRIPT_ALLOWED
                executeHScript(command);
                #else
                addTerminalLine('Unknown command: $cmd. Type "help" for available commands.');
                #end
        }
    }

    function showHelp():Void {
        addTerminalLine("Available commands:");
        addTerminalLine("  help - Show this help");
        addTerminalLine("  clear - Clear terminal");
        addTerminalLine("  list - List all objects");
        addTerminalLine("  create <type> [name] - Create object");
        addTerminalLine("  delete <name> - Delete object");
        addTerminalLine("  inspect <name> - Inspect object");
        addTerminalLine("  set <obj> <prop> <value> - Set property");
        addTerminalLine("  get <obj> <prop> - Get property");
        addTerminalLine("  test <name> - Test object");
        addTerminalLine("  types - List available types");
        addTerminalLine("  cmd <command> - Execute command prompt command");
        #if HSCRIPT_ALLOWED
        addTerminalLine("  hscript <code> - Execute HScript code");
        #end
    }

    function listObjects():Void {
        var objects = [for (key in debugObjects.keys()) key];
        if (objects.length == 0) {
            addTerminalLine("No objects created");
        } else {
            addTerminalLine('Objects (${objects.length}):');
            for (obj in objects) {
                addTerminalLine('  - $obj: ${Type.typeof(debugObjects.get(obj))}');
            }
        }
    }

    function createObjectCommand(parts:Array<String>):Void {
        if (parts.length < 2) {
            addTerminalLine("Usage: create <type> [name]");
            return;
        }

        var typeName = parts[1];
        var objectName = parts.length > 2 ? parts[2] : "obj" + (++objectCounter);

        try {
            var obj = createTypeInstance(typeName);
            if (obj == null) {
                // Try basic types
                switch (typeName.toLowerCase()) {
                    case "string": obj = "";
                    case "int": obj = 0;
                    case "float": obj = 0.0;
                    case "bool": obj = false;
                    case "array": obj = [];
                    case "object": obj = {};
                    default: obj = {};
                }
            }

            debugObjects.set(objectName, obj);
            refreshObjectList();
            addTerminalLine('Created "$objectName" of type "$typeName"');
        } catch (e:Dynamic) {
            addTerminalLine('Error creating object: $e');
        }
    }

    function deleteObjectCommand(parts:Array<String>):Void {
        if (parts.length < 2) {
            addTerminalLine("Usage: delete <name>");
            return;
        }

        var objectName = parts[1];
        if (debugObjects.exists(objectName)) {
            debugObjects.remove(objectName);
            refreshObjectList();
            addTerminalLine('Deleted object: $objectName');
            if (selectedObject == objectName) {
                selectedObject = null;
                refreshInspector();
            }
        } else {
            addTerminalLine('Object not found: $objectName');
        }
    }

    function inspectObjectCommand(parts:Array<String>):Void {
        if (parts.length < 2) {
            addTerminalLine("Usage: inspect <name>");
            return;
        }

        var objectName = parts[1];
        if (debugObjects.exists(objectName)) {
            selectedObject = objectName;
            refreshInspector();
            inspectObject();
        } else {
            addTerminalLine('Object not found: $objectName');
        }
    }

    function setPropertyCommand(parts:Array<String>):Void {
        if (parts.length < 4) {
            addTerminalLine("Usage: set <object> <property> <value>");
            return;
        }

        var objectName = parts[1];
        var property = parts[2];
        var value = parts.slice(3).join(" ");

        if (!debugObjects.exists(objectName)) {
            addTerminalLine('Object not found: $objectName');
            return;
        }

        selectedObject = objectName;
        propertyInput.text = property;
        valueInput.text = value;
        setObjectProperty();
    }

    function getPropertyCommand(parts:Array<String>):Void {
        if (parts.length < 3) {
            addTerminalLine("Usage: get <object> <property>");
            return;
        }

        var objectName = parts[1];
        var property = parts[2];

        if (!debugObjects.exists(objectName)) {
            addTerminalLine('Object not found: $objectName');
            return;
        }

        var obj = debugObjects.get(objectName);
        try {
            var value = Reflect.field(obj, property);
            addTerminalLine('$objectName.$property = ${Std.string(value)}');
        } catch (e:Dynamic) {
            addTerminalLine('Error getting property: $e');
        }
    }

    function testObjectCommand(parts:Array<String>):Void {
        if (parts.length < 2) {
            addTerminalLine("Usage: test <name>");
            return;
        }

        var objectName = parts[1];
        if (debugObjects.exists(objectName)) {
            selectedObject = objectName;
            testObject();
        } else {
            addTerminalLine('Object not found: $objectName');
        }
    }

    function listTypes():Void {
        try {
            var types = TypeRegistryAPI.getAllClasses().slice(0, 20);
            addTerminalLine('Available types (showing first 20):');
            for (type in types) {
                addTerminalLine('  - $type');
            }
        } catch (e:Dynamic) {
            addTerminalLine('Error listing types: $e');
        }
    }

    function executeCommandPromptCommand(command:String):String {
        try {
            // Access the command prompt system
            if (Main.CommandPrompt != null) {
                var result = Main.CommandPrompt.execute(command);
                addTerminalLine('[CMD] $result');
                return result;
            } else {
                addTerminalLine('[CMD] Command prompt not available');
                return "Error: Command prompt not available";
            }
        } catch (e:Dynamic) {
            addTerminalLine('[CMD] Error: $e');
            return 'Error: $e';
        }
    }

    #if HSCRIPT_ALLOWED
    function executeHScript(code:String):Void {
        try {
            var expr = hscriptParser.parseString(code);
            var result = hscriptInterp.execute(expr);
            addTerminalLine('[HScript] ${Std.string(result)}');
        } catch (e:Dynamic) {
            addTerminalLine('[HScript Error] $e');
        }
    }
    #end

    function loadScript(parts:Array<String>):Void {
        addTerminalLine("Script loading not implemented yet");
    }

    function saveObject(parts:Array<String>):Void {
        addTerminalLine("Object saving not implemented yet");
    }

    function addTerminalLine(line:String):Void {
        terminalLines.push(line);

        // Keep terminal output manageable
        if (terminalLines.length > maxTerminalLines) {
            terminalLines = terminalLines.slice(-maxTerminalLines);
        }

        terminalOutput.text = terminalLines.join("\n");

        trace('ObjectDebugState Terminal: $line');
    }

    function clearTerminal():Void {
        terminalLines = [];
        terminalOutput.text = "";
        addTerminalLine("Terminal cleared");
    }

    function exitDebugger():Void {
        trace("ObjectDebugState: Exiting debugger");
        FlxG.switchState(new states.MainMenuState());
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle keyboard shortcuts
        if (FlxG.keys.justPressed.ESCAPE) {
            exitDebugger();
        }

        if (FlxG.keys.justPressed.F12) {
            terminalInput.hasFocus = true;
        }

        // Terminal history navigation
        if (terminalInput.hasFocus) {
            if (FlxG.keys.justPressed.UP && historyIndex > 0) {
                historyIndex--;
                terminalInput.text = commandHistory[historyIndex];
            }
            if (FlxG.keys.justPressed.DOWN && historyIndex < commandHistory.length - 1) {
                historyIndex++;
                terminalInput.text = commandHistory[historyIndex];
            }
        }
    }
}
