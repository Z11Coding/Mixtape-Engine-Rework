package setup;

import archipelago.substates.InfoPanelSubstate;
import backend.ClientPrefs;
import backend.Mods;
import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import haxe.zip.Reader;
import lime.system.System;
import lime.ui.FileDialog;
import setup.EngineImportSetup;
import setup.EngineSettingsConfigSubstate;
import setup.ModInstallChoiceSubstate;
import setup.SetupBaseState;
import sys.FileSystem;
import sys.io.File;
import yutautil.GenericProgressSubstate;

/**
 * Basic engine setup for users not using Archipelago
 * Focuses on engine settings, controls, and basic configuration
 */
class BasicSettingsSetup extends SetupBaseState {
    private var setupSteps = [
        {
            title: "Welcome to Mixtape Engine",
            description: "This will help you set up the Mixtape Engine for regular FNF gameplay.\n\nYou'll configure basic settings, controls, and import any existing preferences from other FNF engines.",
            action: null
        },
        {
            title: "Import Previous Settings",
            description: "Do you want to import settings from other FNF engines? This can save time by copying your controls, graphics settings, and other preferences from engines like Psych Engine, Kade Engine, or others.",
            action: "import"
        },
        {
            title: "Basic Settings",
            description: "Configure essential engine settings like graphics quality, performance options, and gameplay preferences.",
            action: "basic_settings"
        },
        {
            title: "Engine Settings",
            description: "Configure graphics, visuals, and gameplay settings to optimize your experience.",
            action: "engine_settings"
        },
        {
            title: "Control Setup",
            description: "Set up your controls for playing. You can test them and make sure they feel right.",
            action: "controls"
        },
        {
            title: "Mod Management",
            description: "Manage your installed mods and add new ones. You can install mods from files or folders.",
            action: "mods"
        },
        {
            title: "Setup Complete!",
            description: "Basic setup is now complete! You can now:\n\n• Play songs in Freeplay mode\n• Adjust settings anytime from Options\n• Install mods and custom content\n• Use the charting tools\n\nEnjoy using Mixtape Engine!",
            action: "complete"
        }
    ];

    private var currentStepData:Dynamic;
    private var actionButtons:Array<FlxSprite> = [];
    private var actionTexts:Array<FlxText> = [];

    // Mod management variables
    private var modGroup:FlxTypedGroup<FlxSprite>;
    private var modIcons:Array<FlxSprite> = [];
    private var modLabels:Array<FlxText> = [];
    private var addModButton:FlxButton;
    private var detectedMods:Array<String> = [];
    private var fileDialog:FileDialog;

    override function create() {
        super.create();

        totalSteps = setupSteps.length;
        currentStep = 0;

        // Disable AP features since user chose basic setup
        ClientPrefs.data.setupArchipelagoMode = false;
        ClientPrefs.data.checkForUpdates = false; // User chose non-AP mode, disable AP update checking

        updateCurrentStep();
    }

    override function updateStep() {
        super.updateStep();
        updateCurrentStep();
    }

    function updateCurrentStep() {
        if (currentStep >= setupSteps.length) return;

        currentStepData = setupSteps[currentStep];

        titleText.text = currentStepData.title;
        descText.text = currentStepData.description;

        // Clear previous action buttons
        for (button in actionButtons) {
            button.destroy();
        }
        for (text in actionTexts) {
            text.destroy();
        }
        actionButtons = [];
        actionTexts = [];

        // Clear mod-related UI
        if (modGroup != null) {
            remove(modGroup);
            modGroup = new FlxTypedGroup<FlxSprite>();
        }
        if (modIcons != null) {
            for (icon in modIcons) remove(icon);
            modIcons = [];
        }
        if (modLabels != null) {
            for (label in modLabels) remove(label);
            modLabels = [];
        }

        // Create action buttons based on current step
        switch (currentStepData.action) {
            case "import":
                createImportButtons();
            case "basic_settings":
                createBasicSettingsButtons();

            case "engine_settings":
                createEngineSettingsButtons();
            case "controls":
                createControlsButtons();
            case "mods":
                createModManagementUI();
            case "complete":
                createCompleteButtons();
            default:
                // No action buttons for intro step
        }
    }

    function createImportButtons() {
        var buttonY = 350;
        var buttonHeight = 50;

        var importButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, buttonHeight,
            "Import Settings", FlxColor.fromRGB(80, 120, 180));
        var skipButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, buttonHeight,
            "Skip Import", FlxColor.fromRGB(120, 80, 80));

        actionButtons.push(importButton);
        actionButtons.push(skipButton);
    }

    function createBasicSettingsButtons() {
        var buttonY = 350;
        var buttonHeight = 50;

        var configureButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, buttonHeight,
            "Configure Now", FlxColor.fromRGB(80, 180, 80));
        var defaultsButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, buttonHeight,
            "Use Defaults", FlxColor.fromRGB(120, 120, 120));

        actionButtons.push(configureButton);
        actionButtons.push(defaultsButton);
    }

    function createEngineSettingsButtons() {
        var buttonY = 350;
        var buttonHeight = 50;

        var settingsButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, buttonHeight,
            "Configure Settings", FlxColor.fromRGB(80, 180, 80));
        var skipButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, buttonHeight,
            "Use Defaults", FlxColor.fromRGB(120, 120, 120));

        actionButtons.push(settingsButton);
        actionButtons.push(skipButton);
    }

    function createControlsButtons() {
        var buttonY = 350;
        var buttonHeight = 50;

        var testButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, buttonHeight,
            "Test Controls", FlxColor.fromRGB(80, 180, 80));
        var skipButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, buttonHeight,
            "Use Defaults", FlxColor.fromRGB(120, 120, 120));

        actionButtons.push(testButton);
        actionButtons.push(skipButton);
    }

    function createCompleteButtons() {
        var buttonY = 350;
        var buttonHeight = 50;

        var finishButton = createActionButton(FlxG.width * 0.3, buttonY, FlxG.width * 0.4, buttonHeight,
            "Finish Setup", FlxColor.fromRGB(80, 180, 80));

        actionButtons.push(finishButton);
    }

    function createActionButton(x:Float, y:Float, width:Float, height:Float, text:String, color:FlxColor):FlxSprite {
        var button = new FlxSprite(x, y);
        button.makeGraphic(Std.int(width), Std.int(height), color);
        button.alpha = 0.8;
        add(button);

        var buttonText = new FlxText(x, y, width, text);
        buttonText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
        buttonText.y += (height - buttonText.height) / 2;
        buttonText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        add(buttonText);
        actionTexts.push(buttonText);

        return button;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle action button clicks
        if (FlxG.mouse.justPressed && canNavigate) {
            for (i in 0...actionButtons.length) {
                if (FlxG.mouse.overlaps(actionButtons[i])) {
                    handleActionClick(i);
                    break;
                }
            }
        }
    }

    function handleActionClick(buttonIndex:Int) {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        switch (currentStepData.action) {
            case "import":
                if (buttonIndex == 0) {
                    // Import settings
                    MusicBeatState.switchState(new EngineImportSetup());
                    return;
                } else {
                    // Skip import, continue to next step
                }

            case "basic_settings":
                if (buttonIndex == 0) {
                    // Configure settings - open graphics settings substate
                    openSubState(new options.GraphicsSettingsSubState());
                    return;
                } else {
                    // Use defaults - apply recommended settings
                    applyRecommendedSettings();
                }

            case "controls":
                if (buttonIndex == 0) {
                    // Test controls - go to a test state
                    MusicBeatState.switchState(new setup.SetupControlsTest());
                    return;
                } else {
                    // Use default controls
                }

            case "mods":
                if (buttonIndex == 0) {
                    // Add mod button clicked
                    showModInstallOptions();
                    return;
                }

            case "complete":
                completeSetup();
                return;
        }

        // Continue to next step
        onNext();
    }

    function applyRecommendedSettings() {
        // Apply good default settings for most users
        ClientPrefs.data.antialiasing = true;
        ClientPrefs.data.lowQuality = false;
        ClientPrefs.data.framerate = 60;
        ClientPrefs.data.ghostTapping = true;
        ClientPrefs.data.downScroll = false;
        ClientPrefs.data.middleScroll = false;
        ClientPrefs.data.flashing = true;
        ClientPrefs.data.autoPause = true;
        ClientPrefs.data.camZooms = true;
        ClientPrefs.data.scoreZoom = true;
        ClientPrefs.data.healthBarAlpha = 1.0;
        ClientPrefs.data.hitsoundVolume = 0.0;
        ClientPrefs.data.pauseMusic = 'Tea Time';

        ClientPrefs.saveSettings();

        showSettingsResult("Applied recommended settings for optimal performance and gameplay!");
    }

    function showSettingsResult(message:String) {
        var settingsPanel = new InfoPanelSubstate(
            "Settings Applied",
            "✓ " + message + "\n\nYou can change these later in the Options menu.",
            FlxColor.LIME,
            function() {
                onNext(); // Continue to next step
            }
        );
        openSubState(settingsPanel);
    }

    // Mod Management Functions
    function createModManagementUI() {
        // Clear existing UI
        if (modGroup != null) {
            remove(modGroup);
            modGroup.destroy();
        }

        modGroup = new FlxTypedGroup<FlxSprite>();
        add(modGroup);

        // Detect installed mods
        detectedMods = Mods.getModDirectories();

        // Create mod display area
        var startY = 320;
        var modHeight = 60;
        var maxVisible = 4;

        modIcons = [];
        modLabels = [];

        // Display up to maxVisible mods
        for (i in 0...Std.int(Math.min(detectedMods.length, maxVisible))) {
            var modName = detectedMods[i];
            var modY = startY + (i * (modHeight + 10));

            // Create mod icon background
            var modBg = new FlxSprite(50, modY);
            modBg.makeGraphic(FlxG.width - 100, modHeight, FlxColor.fromRGB(40, 40, 60));
            modGroup.add(modBg);

            // Try to load mod icon
            var iconPath = Paths.mods(modName + '/pack.png');
            var modIcon = new FlxSprite(60, modY + 5);
            if (FileSystem.exists(iconPath)) {
                modIcon.loadGraphic(iconPath);
                modIcon.setGraphicSize(50, 50);
            } else {
                modIcon.makeGraphic(50, 50, FlxColor.fromRGB(80, 80, 100));
            }
            modIcon.updateHitbox();
            modGroup.add(modIcon);
            modIcons.push(modIcon);

            // Create mod label
            var modLabel = new FlxText(120, modY + 15, FlxG.width - 200, modName, 18);
            modLabel.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
            modGroup.add(modLabel);
            modLabels.push(modLabel);

            // Add mod info if pack.json exists
            var packData = Mods.getPack(modName);
            if (packData != null && packData.name != null) {
                var packLabel = new FlxText(120, modY + 35, FlxG.width - 200, packData.name, 14);
                packLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
                modGroup.add(packLabel);
            }
        }

        // Show count if more mods exist
        if (detectedMods.length > maxVisible) {
            var moreText = new FlxText(50, startY + (maxVisible * (modHeight + 10)), FlxG.width - 100,
                'And ${detectedMods.length - maxVisible} more mod(s)...', 16);
            moreText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
            modGroup.add(moreText);
        }

        // Create add mod button
        var buttonY = startY + (maxVisible * (modHeight + 10)) + 40;
        var addButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, 50,
            "Add Mod", FlxColor.fromRGB(80, 150, 80));
        var continueButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, 50,
            "Continue", FlxColor.fromRGB(80, 120, 180));

        actionButtons.push(addButton);
        actionButtons.push(continueButton);

        // Setup file drop handling
        setupFileDropHandling();
    }

    function setupFileDropHandling() {
        // Enable file dropping
        #if desktop
        try {
            if (!states.FirstCheckState.dropFileSetup) {
                lime.app.Application.current.window.onDropFile.add(onFileDropped);
                states.FirstCheckState.dropFileSetup = true;
            }
        } catch (e:Dynamic) {
            trace('Could not setup file dropping: $e');
        }
        #end
    }

    function onFileDropped(path:String) {
        if (currentStepData != null && currentStepData.action == "mods") {
            trace('File dropped: $path');
            installModFromPath(path);
        }
    }

    function showModInstallOptions() {
        var modChoiceDialog = new ModInstallChoiceSubstate(
            function() {
                // Choose folder
                var dialog = new FileDialog();
                dialog.onSelect.add(function(path:String) {
                    installModFromPath(path);
                });
                dialog.browse(lime.ui.FileDialogType.OPEN_DIRECTORY, null, null, "Select Mod Folder");
            },
            function() {
                // Choose zip file
                var dialog = new FileDialog();
                dialog.onSelect.add(function(path:String) {
                    installModFromPath(path);
                });
                dialog.browse(lime.ui.FileDialogType.OPEN, "Zip Files (*.zip)", null, "Select Mod ZIP");
            }
        );
        openSubState(modChoiceDialog);
    }

    function installModFromPath(path:String) {
        if (!FileSystem.exists(path)) {
            showModResult("Error: File or folder not found.");
            return;
        }

        var isZip = path.toLowerCase().endsWith('.zip');

        if (isZip) {
            installModFromZip(path);
        } else if (FileSystem.isDirectory(path)) {
            installModFromFolder(path);
        } else {
            showModResult("Error: Selected file is not a ZIP or folder.");
        }
    }

    function installModFromZip(zipPath:String) {
        openSubState(new GenericProgressSubstate(
            "Installing Mod from ZIP",
            [
                Func({
                    name: "Extracting ZIP file",
                    func: function(_) {
                        return extractZipToTemp(zipPath);
                    }
                }),
                Func({
                    name: "Validating mod structure",
                    func: function(args:Array<Dynamic>) {
                        var tempPath:String = args[0];
                        return validateAndInstallMod(tempPath, true);
                    }
                })
            ],
            function(results:Array<Dynamic>) {
                var success:Bool = results[1];
                if (success) {
                    showModResult("Mod installed successfully!");
                    createModManagementUI(); // Refresh UI
                } else {
                    showModResult("Failed to install mod. Check if it's a valid FNF mod.");
                }
            },
            function(error:String, shouldThrow:Bool) {
                showModResult("Error installing mod: " + error);
            }
        ));
    }

    function extractZipToTemp(zipPath:String):String {
        var tempDir = Paths.mods('__temp_mod_install__');

        // Create temp directory
        if (!FileSystem.exists(tempDir)) {
            FileSystem.createDirectory(tempDir);
        }

        // Extract ZIP
        var zipData = File.getBytes(zipPath);
        var entries = Reader.readZip(new haxe.io.BytesInput(zipData));

        for (entry in entries) {
            var outputPath = haxe.io.Path.join([tempDir, entry.fileName]);

            // Create directories if needed
            var dir = haxe.io.Path.directory(outputPath);
            if (!FileSystem.exists(dir)) {
                FileSystem.createDirectory(dir);
            }

            // Extract file
            if (!entry.fileName.endsWith('/')) {
                File.saveBytes(outputPath, Reader.unzip(entry));
            }
        }

        return tempDir;
    }

    function installModFromFolder(folderPath:String) {
        openSubState(new GenericProgressSubstate(
            "Installing Mod from Folder",
            [
                Func({
                    name: "Validating mod structure",
                    func: function(_) {
                        return validateAndInstallMod(folderPath, false);
                    }
                })
            ],
            function(results:Array<Dynamic>) {
                var success:Bool = results[0];
                if (success) {
                    showModResult("Mod installed successfully!");
                    createModManagementUI(); // Refresh UI
                } else {
                    showModResult("Failed to install mod. Check if it's a valid FNF mod.");
                }
            },
            function(error:String, shouldThrow:Bool) {
                showModResult("Error installing mod: " + error);
            }
        ));
    }

    function validateAndInstallMod(sourcePath:String, fromZip:Bool):Bool {
        var modsFolder = Paths.mods();
        if (!FileSystem.exists(modsFolder)) {
            FileSystem.createDirectory(modsFolder);
        }

        // Check for pack.json in root
        var packJsonPath = haxe.io.Path.join([sourcePath, 'pack.json']);
        if (FileSystem.exists(packJsonPath)) {
            // Direct mod folder
            return installSingleMod(sourcePath, modsFolder, fromZip);
        }

        // Check for typical mod folders
        var typicalFolders = ['data', 'songs', 'images', 'sounds', 'music', 'characters', 'stages'];
        var hasTypicalStructure = false;
        for (folder in typicalFolders) {
            if (FileSystem.exists(haxe.io.Path.join([sourcePath, folder]))) {
                hasTypicalStructure = true;
                break;
            }
        }

        if (hasTypicalStructure) {
            // Mod without pack.json but has structure - ask for confirmation
            return confirmAndInstallMod(sourcePath, modsFolder, fromZip);
        }

        // Check subdirectories for mods
        var subModPaths:Array<String> = [];
        try {
            for (item in FileSystem.readDirectory(sourcePath)) {
                var itemPath = haxe.io.Path.join([sourcePath, item]);
                if (FileSystem.isDirectory(itemPath)) {
                    var subPackJson = haxe.io.Path.join([itemPath, 'pack.json']);
                    if (FileSystem.exists(subPackJson)) {
                        subModPaths.push(itemPath);
                    }
                }
            }
        } catch (e:Dynamic) {
            trace('Error reading directory: $e');
        }

        if (subModPaths.length > 0) {
            return installMultipleMods(subModPaths, modsFolder, fromZip);
        }

        return false;
    }

    function installSingleMod(sourcePath:String, modsFolder:String, fromZip:Bool):Bool {
        try {
            var modName = haxe.io.Path.withoutDirectory(sourcePath);
            var targetPath = haxe.io.Path.join([modsFolder, modName]);

            // Ensure unique name
            var counter = 1;
            var originalTarget = targetPath;
            while (FileSystem.exists(targetPath)) {
                targetPath = originalTarget + '_' + counter;
                counter++;
            }

            copyDirectory(sourcePath, targetPath);

            if (fromZip) {
                // Clean up temp directory
                deleteDirectory(Paths.mods('__temp_mod_install__'));
            }

            return true;
        } catch (e:Dynamic) {
            trace('Error installing mod: $e');
            return false;
        }
    }

    function confirmAndInstallMod(sourcePath:String, modsFolder:String, fromZip:Bool):Bool {
        // For now, just install it - in a real implementation you'd show a dialog
        return installSingleMod(sourcePath, modsFolder, fromZip);
    }

    function installMultipleMods(modPaths:Array<String>, modsFolder:String, fromZip:Bool):Bool {
        try {
            for (modPath in modPaths) {
                installSingleMod(modPath, modsFolder, false);
            }

            if (fromZip) {
                deleteDirectory(Paths.mods('__temp_mod_install__'));
            }

            return true;
        } catch (e:Dynamic) {
            trace('Error installing multiple mods: $e');
            return false;
        }
    }

    function copyDirectory(source:String, target:String) {
        if (!FileSystem.exists(target)) {
            FileSystem.createDirectory(target);
        }

        for (item in FileSystem.readDirectory(source)) {
            var sourcePath = haxe.io.Path.join([source, item]);
            var targetPath = haxe.io.Path.join([target, item]);

            if (FileSystem.isDirectory(sourcePath)) {
                copyDirectory(sourcePath, targetPath);
            } else {
                File.copy(sourcePath, targetPath);
            }
        }
    }

    function deleteDirectory(path:String) {
        if (!FileSystem.exists(path)) return;

        try {
            for (item in FileSystem.readDirectory(path)) {
                var itemPath = haxe.io.Path.join([path, item]);
                if (FileSystem.isDirectory(itemPath)) {
                    deleteDirectory(itemPath);
                } else {
                    FileSystem.deleteFile(itemPath);
                }
            }
            FileSystem.deleteDirectory(path);
        } catch (e:Dynamic) {
            trace('Error deleting directory: $e');
        }
    }

    function openEngineSettingsMenu() {
        var settingsDialog = new EngineSettingsConfigSubstate(
            function() {
                showSettingsResult("Engine settings have been configured.");
            }
        );
        openSubState(settingsDialog);
    }

    function showModResult(message:String) {
        var resultPanel = new InfoPanelSubstate(
            "Mod Installation",
            message.indexOf("successfully") != -1 ? "✓ " + message : "❌ " + message,
            message.indexOf("successfully") != -1 ? FlxColor.LIME : FlxColor.RED,
            function() {
                // Continue
            }
        );
        openSubState(resultPanel);
    }

    override function completeSetup() {
        // Mark setup as completed
        ClientPrefs.data.setupCompleted = true;
        ClientPrefs.data.setupSkipped = false;
        // Disable APWorld checking since user chose basic (non-Archipelago) mode
        ClientPrefs.data.checkAPWorld = false;
        ClientPrefs.saveSettings();

        // Show completion message
        var completionPanel = new InfoPanelSubstate(
            "Setup Complete!",
            "🎉 Basic setup is complete! You're ready to enjoy Mixtape Engine.\n\nHave fun!",
            FlxColor.LIME,
            function() {
                // Go to title state
                MusicBeatState.switchState(new states.TitleState());
            }
        );
        openSubState(completionPanel);
    }
}
