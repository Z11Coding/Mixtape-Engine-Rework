package setup;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.ui.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

/**
 * Base class for setup-related states
 * Uses AP-style UI design patterns for consistency
 */
class SetupBaseState extends MusicBeatState {
    // Common UI elements based on AP styling
    public var bg:FlxSprite;
    public var titleText:FlxText;
    public var descText:FlxText;
    public var progressBar:FlxSprite;
    public var progressFill:FlxSprite;

    // Navigation
    public var backButton:FlxText;
    public var nextButton:FlxText;
    public var skipButton:FlxText;

    // State tracking
    public var currentStep:Int = 0;
    public var totalSteps:Int = 1;
    public var canNavigate:Bool = true;

    override function create() {
        super.create();

        setupBackground();
        setupUI();
        setupNavigation();

        FlxG.mouse.visible = true;
    }

    function setupBackground() {
        // Create gradient background similar to AP style
        bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [FlxColor.fromRGB(25, 25, 40), FlxColor.fromRGB(15, 15, 25)], 1, 90);
        bg.scrollFactor.set();
        add(bg);
    }

    function setupUI() {
        // Title text
        titleText = new FlxText(0, 60, FlxG.width, "Setup Guide");
        titleText.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE, CENTER);
        titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        titleText.scrollFactor.set();
        add(titleText);

        // Description text
        descText = new FlxText(50, 150, FlxG.width - 100, "Welcome to the Mixtape Engine Setup Guide!");
        descText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, CENTER);
        descText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        descText.wordWrap = true;
        descText.scrollFactor.set();
        add(descText);

        // Progress bar background
        progressBar = new FlxSprite(FlxG.width * 0.2, FlxG.height - 120);
        progressBar.makeGraphic(Std.int(FlxG.width * 0.6), 8, FlxColor.fromRGB(40, 40, 40));
        progressBar.scrollFactor.set();
        add(progressBar);

        // Progress bar fill
        progressFill = new FlxSprite(progressBar.x, progressBar.y);
        progressFill.makeGraphic(1, 8, FlxColor.fromRGB(100, 200, 255));
        progressFill.scrollFactor.set();
        add(progressFill);

        updateProgress();
    }

    function setupNavigation() {
        // Back button
        backButton = new FlxText(50, FlxG.height - 80, 0, "← BACK");
        backButton.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT);
        backButton.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        backButton.scrollFactor.set();
        add(backButton);

        // Next button
        nextButton = new FlxText(0, FlxG.height - 80, FlxG.width - 50, "NEXT →");
        nextButton.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, RIGHT);
        nextButton.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        nextButton.scrollFactor.set();
        add(nextButton);

        // Skip button
        skipButton = new FlxText(0, FlxG.height - 40, FlxG.width, "Press ESC to skip setup");
        skipButton.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.fromRGB(180, 180, 180), CENTER);
        skipButton.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        skipButton.scrollFactor.set();
        add(skipButton);
    }

    function updateProgress() {
        var progressPercent = currentStep / Math.max(totalSteps, 1);
        progressFill.scale.x = progressPercent * progressBar.width;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle navigation
        if (canNavigate) {
            if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
                onBack();
            }
            if (controls.ACCEPT || FlxG.keys.justPressed.ENTER) {
                onNext();
            }

            // Mouse interactions
            if (FlxG.mouse.justPressed) {
                if (FlxG.mouse.overlaps(backButton)) {
                    onBack();
                } else if (FlxG.mouse.overlaps(nextButton)) {
                    onNext();
                }
            }
        }
    }

    function onBack() {
        if (currentStep > 0) {
            currentStep--;
            updateStep();
        } else {
            // Exit setup or go to previous state
            exitSetup();
        }
    }

    function onNext() {
        if (currentStep < totalSteps - 1) {
            currentStep++;
            updateStep();
        } else {
            // Complete setup or go to next state
            completeSetup();
        }
    }

    function updateStep() {
        updateProgress();
        // Override in subclasses to handle step changes
    }

    function exitSetup() {
        // Override in subclasses for custom exit behavior
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new states.TitleState());
    }

    function completeSetup() {
        // Override in subclasses for custom completion behavior
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }

    // Utility functions for AP-style UI elements
    public static function createStyledButton(x:Float, y:Float, width:Float, height:Float, text:String, ?color:FlxColor):FlxSprite {
        if (color == null) color = FlxColor.fromRGB(50, 50, 80);

        var button = new FlxSprite(x, y);
        button.makeGraphic(Std.int(width), Std.int(height), color);

        var buttonText = new FlxText(x, y, width, text);
        buttonText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
        buttonText.y += (height - buttonText.height) / 2;

        return button;
    }

    public static function createInfoPanel(x:Float, y:Float, width:Float, height:Float, title:String, content:String):FlxGroup {
        var panel = new FlxGroup();

        // Background
        var bg = new FlxSprite(x, y);
        bg.makeGraphic(Std.int(width), Std.int(height), FlxColor.fromRGB(30, 30, 50, 200));
        panel.add(bg);

        // Title
        var titleText = new FlxText(x + 10, y + 10, width - 20, title);
        titleText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT);
        titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        panel.add(titleText);

        // Content
        var contentText = new FlxText(x + 10, y + 40, width - 20, content);
        contentText.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE, LEFT);
        contentText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        contentText.wordWrap = true;
        panel.add(contentText);

        return panel;
    }
}
