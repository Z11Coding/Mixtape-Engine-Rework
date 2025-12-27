package setup;

import archipelago.APEntryState;
import archipelago.substates.InfoPanelSubstate;
import backend.ClientPrefs;
import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import setup.EngineImportSetup;
import setup.SetupBaseState;
// Prompt import removed - using InfoPanelSubstate instead

/**
 * Archipelago-specific setup state
 * Handles AP-related configuration and APWorld management
 */
class ArchipelagoSetupState extends SetupBaseState {
    private var setupSteps = [
        {
            title: "Welcome to Archipelago Setup",
            description: "This will help you set up the Mixtape Engine for use with Archipelago multiworld randomizer.\n\nArchipelago allows you to play Friday Night Funkin' alongside other games in a shared randomized experience.",
            action: null
        },
        {
            title: "Important Archipelago Guidelines",
            description: "Please read these important guidelines for proper Archipelago usage:\n\n• YAML Creation: Always use the Engine Settings Menu (not Archipelago Launcher Templates) to create YAML files for best compatibility.\n\n• Sanity Options: If using Sanity Options, configure your settings to allow 3 checks per song (Note Checks or Both mode) for proper integration.\n\nThese guidelines ensure the best Archipelago experience.",
            action: null
        },
        {
            title: "Import Previous Settings",
            description: "Do you want to import settings from other FNF engines? This can save time by copying your controls, graphics settings, and other preferences.",
            action: "import"
        },
        {
            title: "APWorld Management",
            description: "The APWorld file is required to connect to Archipelago servers. Would you like to install or export the latest APWorld?",
            action: "apworld"
        },
        {
            title: "Enable AP Features",
            description: "This will enable Archipelago-specific features like automatic update checking for APWorld files and AP-related UI elements.",
            action: "enable_ap"
        },
        {
            title: "Setup Complete!",
            description: "Archipelago setup is now complete! You can now:\n\n• Use the Archipelago menu from the main menu\n• Generate YAML files for AP games\n• Connect to AP servers and play\n\nYou can re-run this setup anytime from Options > Setup Guide.",
            action: "complete"
        }
    ];

    private var currentStepData:Dynamic;
    private var actionButtons:Array<FlxSprite> = [];
    private var actionTexts:Array<FlxText> = [];

    override function create() {
        super.create();

        totalSteps = setupSteps.length;
        currentStep = 0;

        // Enable AP features by default since user chose AP setup
        ClientPrefs.data.setupArchipelagoMode = true;

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

        // Create action buttons based on current step
        switch (currentStepData.action) {
            case "import":
                createImportButtons();
            case "apworld":
                createAPWorldButtons();
            case "enable_ap":
                createEnableAPButtons();
            case "complete":
                createCompleteButtons();
            default:
                // No action buttons for intro step
        }
    }

    function createImportButtons() {
        var buttonY = 350;
        var buttonHeight = 50;
        var buttonSpacing = 60;

        var importButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, buttonHeight,
            "Import Settings", FlxColor.fromRGB(80, 120, 180));
        var skipButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, buttonHeight,
            "Skip Import", FlxColor.fromRGB(120, 80, 80));

        actionButtons.push(importButton);
        actionButtons.push(skipButton);
    }

    function createAPWorldButtons() {
        var buttonY = 350;
        var buttonHeight = 50;
        var buttonWidth = FlxG.width * 0.25;
        var buttonSpacing = (FlxG.width - (buttonWidth * 3)) / 4;

        var installButton = createActionButton(buttonSpacing, buttonY, buttonWidth, buttonHeight,
            "Install APWorld", FlxColor.fromRGB(80, 180, 80));
        var exportButton = createActionButton(buttonSpacing * 2 + buttonWidth, buttonY, buttonWidth, buttonHeight,
            "Export APWorld", FlxColor.fromRGB(180, 120, 80));
        var skipButton = createActionButton(buttonSpacing * 3 + buttonWidth * 2, buttonY, buttonWidth, buttonHeight,
            "Skip for Now", FlxColor.fromRGB(120, 80, 80));

        actionButtons.push(installButton);
        actionButtons.push(exportButton);
        actionButtons.push(skipButton);
    }

    function createEnableAPButtons() {
        var buttonY = 350;
        var buttonHeight = 50;
        var buttonSpacing = 60;

        var enableButton = createActionButton(FlxG.width * 0.2, buttonY, FlxG.width * 0.25, buttonHeight,
            "Enable AP Features", FlxColor.fromRGB(80, 180, 80));
        var disableButton = createActionButton(FlxG.width * 0.55, buttonY, FlxG.width * 0.25, buttonHeight,
            "Minimal Setup", FlxColor.fromRGB(120, 120, 120));

        actionButtons.push(enableButton);
        actionButtons.push(disableButton);
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

            case "apworld":
                if (buttonIndex == 0) {
                    // Install APWorld - delegate to AP system
                    installAPWorld();
                    return;
                } else if (buttonIndex == 1) {
                    // Export APWorld - delegate to AP system
                    exportAPWorld();
                    return;
                } else {
                    // Skip for now
                }

            case "enable_ap":
                if (buttonIndex == 0) {
                    // Enable full AP features
                    ClientPrefs.data.checkForUpdates = true;
                    ClientPrefs.data.setupArchipelagoMode = true;
                } else {
                    // Minimal setup - disable auto-updates
                    ClientPrefs.data.checkForUpdates = false;
                    ClientPrefs.data.setupArchipelagoMode = true; // Still true, but with minimal features
                }

            case "complete":
                completeSetup();
                return;
        }

        // Continue to next step
        onNext();
    }

    function installAPWorld() {
        canNavigate = false;

        // Use the actual APWorld installation function
        #if ARCHIPELAGO_ALLOWED
        try {
            APEntryState.installAPWorld();
            canNavigate = true;
            showAPWorldResult("✓ APWorld installation completed successfully!\n\nThe Friday Night Funkin APWorld file has been installed to your Archipelago custom_worlds folder.", FlxColor.LIME);
        } catch (e:Dynamic) {
            canNavigate = true;
            showAPWorldResult("❌ Failed to install APWorld: " + e + "\n\nYou can try again later from the Archipelago menu.", FlxColor.RED);
        }
        #else
        canNavigate = true;
        showAPWorldResult("⚠️ Archipelago features not compiled\n\nThis build doesn't include Archipelago support. Please check your build configuration and ensure ARCHIPELAGO_ALLOWED flag is enabled.", FlxColor.ORANGE);
        #end
    }

    function exportAPWorld() {
        canNavigate = false;

        #if ARCHIPELAGO_ALLOWED
        try {
            APEntryState.outputAPWorld();
            canNavigate = true;
            showAPWorldResult("✓ APWorld exported successfully!\n\nThe fridaynightfunkin.apworld file has been saved to your main directory. You can now distribute this file or install it manually.", FlxColor.LIME);
        } catch (e:Dynamic) {
            canNavigate = true;
            showAPWorldResult("❌ Failed to export APWorld: " + e + "\n\nYou can try again later from the Archipelago menu.", FlxColor.RED);
        }
        #else
        canNavigate = true;
        showAPWorldResult("⚠️ Archipelago features not compiled\n\nThis build doesn't include Archipelago support. Please check your build configuration and ensure ARCHIPELAGO_ALLOWED flag is enabled.", FlxColor.ORANGE);
        #end
    }

    function showAPWorldResult(message:String, ?color:FlxColor) {
        if (color == null) color = FlxColor.CYAN; // Archipelago theme color

        var resultPanel = new InfoPanelSubstate(
            "APWorld Operation",
            message,
            color,
            function() {
                onNext(); // Continue to next step
            }
        );

        openSubState(resultPanel);
    }

    override function completeSetup() {
        // Mark setup as completed
        ClientPrefs.data.setupCompleted = true;
        ClientPrefs.data.setupSkipped = false;
        // Enable APWorld checking since user chose Archipelago mode
        ClientPrefs.data.checkAPWorld = true;
        ClientPrefs.saveSettings();

        // Show completion message with Archipelago styling
        var completionPanel = new InfoPanelSubstate(
            "Archipelago Setup Complete!",
            "🌍 Mixtape Engine is now ready for multiworld randomizer gaming!\n\n" +
            "✓ APWorld management configured\n" +
            "✓ Engine settings imported\n" +
            "✓ Archipelago features enabled\n\n" +
            "You can now access the Archipelago menu from the main menu to connect to servers and start your multiworld adventures!",
            FlxColor.LIME,
            function() {
                MusicBeatState.switchState(new states.TitleState());
            }
        );

        openSubState(completionPanel);
    }

}
