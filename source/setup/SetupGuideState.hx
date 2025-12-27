package setup;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import setup.ArchipelagoSetupState;
import setup.BasicSettingsSetup;
import setup.EngineImportSetup;
import setup.SetupBaseState;

/**
 * Main setup guide state that orchestrates the entire setup process
 * Determines if user wants Archipelago setup or basic engine setup
 */
class SetupGuideState extends SetupBaseState {
    private var choiceButtons:Array<FlxSprite> = [];
    private var choiceTexts:Array<FlxText> = [];
    private var selectedChoice:Int = 0;

    // Setup paths
    private var setupPaths:Array<Dynamic> = [
        {
            title: "I'm using this for Archipelago",
            desc: "Set up the engine for Archipelago multiworld randomizer gaming",
            nextState: setup.ArchipelagoSetupState
        },
        {
            title: "I'm using this as a regular FNF engine",
            desc: "Set up basic engine settings and import from other engines",
            nextState: BasicSettingsSetup
        }
    ];

    override function create() {
        super.create();

        titleText.text = "Mixtape Engine Setup";
        descText.text = "Welcome to the Mixtape Engine Setup Guide!\n\nThis will help you configure the engine for your needs and import settings from other FNF engines.";

        totalSteps = 1; // This is just the choice screen
        currentStep = 0;
        updateProgress();

        createChoiceButtons();
    }

    function createChoiceButtons() {
        var startY = 300;
        var buttonHeight = 100;
        var buttonSpacing = 20;

        for (i in 0...setupPaths.length) {
            var path = setupPaths[i];
            var buttonY = startY + i * (buttonHeight + buttonSpacing);

            // Button background
            var button = new FlxSprite(FlxG.width * 0.1, buttonY);
            button.makeGraphic(Std.int(FlxG.width * 0.8), buttonHeight,
                i == selectedChoice ? FlxColor.fromRGB(80, 120, 180) : FlxColor.fromRGB(50, 50, 80));
            button.alpha = 0.8;
            add(button);
            choiceButtons.push(button);

            // Title text
            var titleText = new FlxText(button.x + 20, button.y + 15, button.width - 40, path.title);
            titleText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT);
            titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
            add(titleText);
            choiceTexts.push(titleText);

            // Description text
            var descText = new FlxText(button.x + 20, button.y + 45, button.width - 40, path.desc);
            descText.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.fromRGB(200, 200, 200), LEFT);
            descText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            descText.wordWrap = true;
            add(descText);
            choiceTexts.push(descText);
        }

        updateChoiceSelection();
    }

    function updateChoiceSelection() {
        for (i in 0...choiceButtons.length) {
            var isSelected = i == selectedChoice;
            choiceButtons[i].color = isSelected ? FlxColor.fromRGB(80, 120, 180) : FlxColor.fromRGB(50, 50, 80);

            // Animate selection
            FlxTween.cancelTweensOf(choiceButtons[i]);
            FlxTween.tween(choiceButtons[i], {alpha: isSelected ? 1.0 : 0.8}, 0.2, {ease: FlxEase.quadOut});
        }
    }

    override function update(elapsed:Float) {
        // Handle choice selection
        if (canNavigate) {
            if (controls.UI_UP_P || FlxG.keys.justPressed.UP) {
                selectedChoice = (selectedChoice - 1 + setupPaths.length) % setupPaths.length;
                updateChoiceSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }
            else if (controls.UI_DOWN_P || FlxG.keys.justPressed.DOWN) {
                selectedChoice = (selectedChoice + 1) % setupPaths.length;
                updateChoiceSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }

            // Mouse selection
            for (i in 0...choiceButtons.length) {
                if (FlxG.mouse.overlaps(choiceButtons[i])) {
                    if (selectedChoice != i) {
                        selectedChoice = i;
                        updateChoiceSelection();
                    }

                    if (FlxG.mouse.justPressed) {
                        selectChoice();
                        return;
                    }
                }
            }
        }

        super.update(elapsed);
    }

    override function onNext() {
        selectChoice();
    }

    function selectChoice() {
        if (!canNavigate) return;

        canNavigate = false;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        var selectedPath = setupPaths[selectedChoice];

        // Animate selection
        FlxTween.tween(choiceButtons[selectedChoice], {
            alpha: 1.2,
            "scale.x": 1.05,
            "scale.y": 1.05
        }, 0.3, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                // Store setup choice in ClientPrefs for later states to reference
                ClientPrefs.data.setupArchipelagoMode = (selectedChoice == 0);
                ClientPrefs.saveSettings();

                // Transition to next setup state
                MusicBeatState.switchState(Type.createInstance(selectedPath.nextState, []));
            }
        });
    }

    override function exitSetup() {
        // Show skip confirmation dialog
        showSkipConfirmation();
    }

    function showSkipConfirmation() {
        var skipDialog = new SkipSetupConfirmSubstate(
            function() {
                // Skip setup - mark as completed but skipped
                ClientPrefs.data.setupCompleted = true;
                ClientPrefs.data.setupSkipped = true;
                // Don't enable APWorld checking when skipping setup
                ClientPrefs.data.checkAPWorld = false;
                ClientPrefs.saveSettings();

                // Go to title state
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new states.TitleState());
            },
            function() {
                // Continue with setup - do nothing, dialog will close
            }
        );
        openSubState(skipDialog);
    }
}

/**
 * Custom substate for skip setup confirmation with Archipelago-style theming
 */
class SkipSetupConfirmSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var messageText:FlxText;
    var skipButton:FlxSprite;
    var skipButtonText:FlxText;
    var continueButton:FlxSprite;
    var continueButtonText:FlxText;

    var onSkip:Void->Void;
    var onContinue:Void->Void;
    var selectedButton:Int = 1; // Default to continue

    public function new(onSkip:Void->Void, onContinue:Void->Void) {
        super();
        this.onSkip = onSkip;
        this.onContinue = onContinue;
    }

    override function create() {
        super.create();

        // Semi-transparent background
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);

        // Main panel with gradient (Archipelago style)
        panel = FlxGradient.createGradientFlxSprite(500, 300, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = (FlxG.width - panel.width) / 2;
        panel.y = (FlxG.height - panel.height) / 2;
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, "Skip Setup?", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.ORANGE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Message
        messageText = new FlxText(panel.x + 20, panel.y + 70, panel.width - 40,
            "⚠️ Are you sure you want to skip the setup process?\n\n" +
            "You can always run it later from the Options menu, but you'll miss out on:\n" +
            "• Importing settings from other engines\n" +
            "• Archipelago multiworld configuration\n" +
            "• Optimized engine settings", 16);
        messageText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        messageText.borderSize = 1;
        add(messageText);

        // Buttons
        var buttonY = panel.y + panel.height - 60;
        var buttonWidth = 140;
        var buttonHeight = 40;

        // Skip button (left)
        skipButton = new FlxSprite(panel.x + 50, buttonY);
        skipButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
        add(skipButton);

        skipButtonText = new FlxText(skipButton.x, skipButton.y + 10, buttonWidth, "SKIP SETUP", 16);
        skipButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        skipButtonText.borderSize = 1;
        add(skipButtonText);

        // Continue button (right)
        continueButton = new FlxSprite(panel.x + panel.width - 50 - buttonWidth, buttonY);
        continueButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
        add(continueButton);

        continueButtonText = new FlxText(continueButton.x, continueButton.y + 10, buttonWidth, "CONTINUE SETUP", 16);
        continueButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        continueButtonText.borderSize = 1;
        add(continueButtonText);

        updateButtonSelection();
        animateIn();
    }

    function animateIn() {
        // Scale in animation
        panel.scale.set(0.5, 0.5);
        panel.alpha = 0;
        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {ease: FlxEase.backOut});

        // Fade in text elements
        for (member in members) {
            if (member != background && member != panel && Std.isOfType(member, FlxText)) {
                var text:FlxText = cast member;
                text.alpha = 0;
                FlxTween.tween(text, {alpha: 1}, 0.3, {startDelay: 0.2});
            }
        }
    }

    function updateButtonSelection() {
        // Update button appearances based on selection
        skipButton.alpha = selectedButton == 0 ? 1.0 : 0.7;
        continueButton.alpha = selectedButton == 1 ? 1.0 : 0.7;

        skipButtonText.color = selectedButton == 0 ? FlxColor.YELLOW : FlxColor.WHITE;
        continueButtonText.color = selectedButton == 1 ? FlxColor.YELLOW : FlxColor.WHITE;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Keyboard navigation
        if (controls.UI_LEFT_P && selectedButton > 0) {
            selectedButton--;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.UI_RIGHT_P && selectedButton < 1) {
            selectedButton++;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        // Accept/Cancel
        if (controls.ACCEPT) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            if (selectedButton == 0) {
                onSkip();
            } else {
                onContinue();
            }
            close();
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            onContinue(); // Back means continue setup
            close();
        }

        // Mouse interactions
        if (FlxG.mouse.overlaps(skipButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            onSkip();
            close();
        }

        if (FlxG.mouse.overlaps(continueButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            onContinue();
            close();
        }

        // Mouse hover
        if (FlxG.mouse.overlaps(skipButton) && selectedButton != 0) {
            selectedButton = 0;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
        }

        if (FlxG.mouse.overlaps(continueButton) && selectedButton != 1) {
            selectedButton = 1;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
        }
    }
}
