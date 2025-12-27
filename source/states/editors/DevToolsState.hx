package states.editors;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import substates.Prompt;

/**
 * Developer Tools main menu
 * Provides access to the Source Editor and Object Debugger states
 */
class DevToolsState extends MusicBeatState {
    var menuItems:FlxTypedGroup<FlxButton>;

    override function create() {
        super.create();

        // Background
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(15, 20, 25));
        add(bg);

        // Title
        var title = new FlxText(0, 100, FlxG.width, "Developer Tools");
        title.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(title);

        var subtitle = new FlxText(0, 140, FlxG.width, "Advanced development and debugging utilities");
        subtitle.setFormat(null, 16, FlxColor.GRAY, CENTER);
        add(subtitle);

        // Menu items
        menuItems = new FlxTypedGroup<FlxButton>();

        var centerX = FlxG.width / 2;
        var startY = 200;
        var spacing = 80;

        // Source Editor button
        var editorBtn = new FlxButton(centerX - 150, startY, "", function() {
            FlxG.switchState(new SourceEditorState());
        });
        editorBtn.loadGraphic("assets/shared/images/menubutton", true, 300, 60);
        editorBtn.color = FlxColor.fromRGB(80, 120, 180);
        menuItems.add(editorBtn);

        var editorText = new FlxText(centerX - 145, startY + 15, 290, "Source Code Editor");
        editorText.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(editorText);

        var editorDesc = new FlxText(centerX - 145, startY + 35, 290, "Edit game source code in real-time");
        editorDesc.setFormat(null, 10, FlxColor.GRAY, CENTER);
        add(editorDesc);

        // Object Debugger button
        var debugBtn = new FlxButton(centerX - 150, startY + spacing, "", function() {
            FlxG.switchState(new ObjectDebugState());
        });
        debugBtn.loadGraphic("assets/shared/images/menubutton", true, 300, 60);
        debugBtn.color = FlxColor.fromRGB(180, 120, 80);
        menuItems.add(debugBtn);

        var debugText = new FlxText(centerX - 145, startY + spacing + 15, 290, "Object Debugger");
        debugText.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(debugText);

        var debugDesc = new FlxText(centerX - 145, startY + spacing + 35, 290, "Create and test objects with terminal");
        debugDesc.setFormat(null, 10, FlxColor.GRAY, CENTER);
        add(debugDesc);

        // Type Registry Info button
        var registryBtn = new FlxButton(centerX - 150, startY + spacing * 2, "", function() {
            showRegistryInfo();
        });
        registryBtn.loadGraphic("assets/shared/images/menubutton", true, 300, 60);
        registryBtn.color = FlxColor.fromRGB(120, 180, 80);
        menuItems.add(registryBtn);

        var registryText = new FlxText(centerX - 145, startY + spacing * 2 + 15, 290, "Type Registry Info");
        registryText.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(registryText);

        var registryDesc = new FlxText(centerX - 145, startY + spacing * 2 + 35, 290, "View type system information");
        registryDesc.setFormat(null, 10, FlxColor.GRAY, CENTER);
        add(registryDesc);

        add(menuItems);

        // Back button
        var backBtn = new FlxButton(50, FlxG.height - 80, "Back to Main Menu", function() {
            FlxG.switchState(new states.MainMenuState());
        });
        backBtn.color = FlxColor.fromRGB(150, 80, 80);
        add(backBtn);

        // Info text
        var infoText = new FlxText(20, FlxG.height - 50, FlxG.width - 40,
            "Use these tools for advanced development tasks. Source Editor allows real-time code modification, " +
            "Object Debugger provides runtime object testing with terminal access.");
        infoText.setFormat(null, 10, FlxColor.GRAY, LEFT);
        infoText.wordWrap = true;
        add(infoText);

        trace("DevToolsState: Created successfully");
    }

    function showRegistryInfo():Void {
        try {
            import yutautil.typeregistry.TypeRegistryAPI;

            var info = 'Type Registry Status:\n\n';

            // Check for build data first
            if (TypeRegistryAPI.hasBuildData()) {
                var buildStats = TypeRegistryAPI.getBuildStats();
                info += '🟢 Build Data Available!\n';
                info += 'Generated: ${Date.fromTime(buildStats.timestamp)}\n';
                info += 'Platform: ${buildStats.platform}\n\n';
                info += 'Build-time Collection:\n';
                info += '  Classes: ${buildStats.classCount}\n';
                info += '  Abstracts: ${buildStats.abstractCount}\n';
                info += '  Functions: ${buildStats.functionCount}\n';
                info += '  Source Files: ${buildStats.sourceFileCount}\n\n';
                info += 'The build macro successfully collected\n';
                info += 'comprehensive type metadata during\n';
                info += 'compilation. This provides enhanced\n';
                info += 'performance and detailed analysis.\n\n';
            } else {
                info += '🟡 Build Data Not Available\n';
                info += 'Using runtime type discovery fallback.\n\n';
                info += 'To enable build-time collection:\n';
                info += '1. Ensure BUILD_MACRO_ENABLED is defined\n';
                info += '2. Compile with desktop target\n';
                info += '3. Check export/builddata/ for output\n\n';
            }

            // Runtime discovery stats
            var classCount = TypeRegistryAPI.getAllClasses().length;
            var abstractCount = TypeRegistryAPI.getAllAbstracts().length;
            var typedefCount = TypeRegistryAPI.getAllTypedefs().length;

            info += 'Runtime Access:\n';
            info += '  Classes: $classCount\n';
            info += '  Abstracts: $abstractCount\n';
            info += '  Typedefs: $typedefCount\n\n';
            info += 'System operational and ready for use.';

            openSubState(new Prompt("Type Registry", info, function() {
                // Close callback
            }, null, true));

        } catch (e:Dynamic) {
            var errorInfo = 'Type Registry Error:\n\n';
            errorInfo += 'Failed to access registry: $e\n\n';
            errorInfo += 'This may indicate compilation issues\n';
            errorInfo += 'or missing macro execution.';

            openSubState(new Prompt("Registry Error", errorInfo, function() {
                // Close callback
            }, null, true));
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Keyboard shortcuts
        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new states.MainMenuState());
        }

        if (FlxG.keys.justPressed.ONE) {
            FlxG.switchState(new SourceEditorState());
        }

        if (FlxG.keys.justPressed.TWO) {
            FlxG.switchState(new ObjectDebugState());
        }
    }
}
