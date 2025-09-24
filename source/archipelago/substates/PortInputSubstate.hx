package archipelago.substates;

import backend.MusicBeatSubstate;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;

/**
 * Specialized port number input substate with validation and presets
 */
class PortInputSubstate extends MusicBeatSubstate {
    // Visual elements
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var descriptionText:FlxText;
    var inputText:FlxText;
    var currentValueDisplay:FlxText;
    var errorText:FlxText;

    // Input buttons
    var confirmButton:FlxSprite;
    var cancelButton:FlxSprite;
    var clearButton:FlxSprite;
    var confirmButtonText:FlxText;
    var cancelButtonText:FlxText;
    var clearButtonText:FlxText;

    // Preset buttons
    var preset38281Button:FlxSprite;
    var preset38282Button:FlxSprite;
    var preset80Button:FlxSprite;
    var preset38281Text:FlxText;
    var preset38282Text:FlxText;
    var preset80Text:FlxText;

    // Animation elements
    var glowEffect:FlxSprite;
    var particles:FlxTypedGroup<FlxSprite>;

    // Input state
    var currentValue:String = "";
    var onConfirm:String->Void;
    var onCancel:Void->Void;

    // Visual state
    var isAnimating:Bool = false;
    var hasError:Bool = false;

    public function new(
        currentVal:String,
        callback:String->Void,
        ?cancelCallback:Void->Void
    ) {
        super();

        this.onConfirm = callback != null ? callback : function(v:String) {};
        this.onCancel = cancelCallback != null ? cancelCallback : function() {};

        // Set initial value
        this.currentValue = currentVal != null ? currentVal : "38281";

        setupVisuals();
        setupButtons();
        setupPresets();
        setupAnimations();
        animateIn();
    }

    function setupVisuals() {
        // Semi-transparent background
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);

        // Main panel with gradient - made wider for presets
        panel = FlxGradient.createGradientFlxSprite(600, 400, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = Std.int((FlxG.width - panel.width) / 2);
        panel.y = Std.int((FlxG.height - panel.height) / 2);
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, "SERVER PORT", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Description
        descriptionText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40,
            "Enter server port (1-65535). Most Archipelago servers use 38281.", 16);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);

        // Current value display
        currentValueDisplay = new FlxText(panel.x + 20, panel.y + 120, panel.width - 40, currentValue, 32);
        currentValueDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        currentValueDisplay.borderSize = 2;
        add(currentValueDisplay);

        // Input instruction
        inputText = new FlxText(panel.x + 20, panel.y + 170, panel.width - 40,
            "Type numbers or use presets below", 14);
        inputText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, CENTER, OUTLINE, FlxColor.BLACK);
        inputText.borderSize = 1;
        add(inputText);

        // Error text (hidden initially)
        errorText = new FlxText(panel.x + 20, panel.y + 190, panel.width - 40, "", 14);
        errorText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        errorText.borderSize = 1;
        errorText.visible = false;
        add(errorText);

        updateDisplays();
    }

    function setupButtons() {
        var buttonY = panel.y + panel.height - 60;
        var buttonWidth = 120;
        var buttonHeight = 40;

        // Confirm button
        confirmButton = new FlxSprite(panel.x + 50, buttonY);
        confirmButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
        add(confirmButton);

        confirmButtonText = new FlxText(confirmButton.x, confirmButton.y + 10, buttonWidth, "CONFIRM", 16);
        confirmButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        confirmButtonText.borderSize = 1;
        add(confirmButtonText);

        // Cancel button
        cancelButton = new FlxSprite(panel.x + panel.width - 170, buttonY);
        cancelButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
        add(cancelButton);

        cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 10, buttonWidth, "CANCEL", 16);
        cancelButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelButtonText.borderSize = 1;
        add(cancelButtonText);

        // Clear button
        clearButton = new FlxSprite(panel.x + (panel.width - buttonWidth) / 2, buttonY);
        clearButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.ORANGE);
        add(clearButton);

        clearButtonText = new FlxText(clearButton.x, clearButton.y + 10, buttonWidth, "CLEAR", 16);
        clearButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        clearButtonText.borderSize = 1;
        add(clearButtonText);
    }

    function setupPresets() {
        var presetY = panel.y + 220;
        var presetWidth = 120;
        var presetHeight = 35;
        var spacing = (panel.width - (presetWidth * 3)) / 4;

        // 38281 preset (most common)
        preset38281Button = new FlxSprite(panel.x + spacing, presetY);
        preset38281Button.makeGraphic(presetWidth, presetHeight, FlxColor.BLUE);
        add(preset38281Button);

        preset38281Text = new FlxText(preset38281Button.x, preset38281Button.y + 8, presetWidth, "38281\n(Default)", 12);
        preset38281Text.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        preset38281Text.borderSize = 1;
        add(preset38281Text);

        // 38282 preset (alternative)
        preset38282Button = new FlxSprite(panel.x + spacing * 2 + presetWidth, presetY);
        preset38282Button.makeGraphic(presetWidth, presetHeight, FlxColor.PURPLE);
        add(preset38282Button);

        preset38282Text = new FlxText(preset38282Button.x, preset38282Button.y + 8, presetWidth, "38282\n(Alt)", 12);
        preset38282Text.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        preset38282Text.borderSize = 1;
        add(preset38282Text);

        // 80 preset (HTTP)
        preset80Button = new FlxSprite(panel.x + spacing * 3 + presetWidth * 2, presetY);
        preset80Button.makeGraphic(presetWidth, presetHeight, FlxColor.fromRGB(128, 64, 0));
        add(preset80Button);

        preset80Text = new FlxText(preset80Button.x, preset80Button.y + 8, presetWidth, "80\n(HTTP)", 12);
        preset80Text.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        preset80Text.borderSize = 1;
        add(preset80Text);
    }

    function setupAnimations() {
        // Glow effect
        glowEffect = new FlxSprite(titleText.x - 5, titleText.y - 5);
        glowEffect.makeGraphic(Std.int(titleText.width + 10), Std.int(titleText.height + 10), FlxColor.CYAN);
        glowEffect.alpha = 0;
        insert(members.indexOf(titleText), glowEffect);

        // Particle effects
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        for (i in 0...10) {
            var particle = new FlxSprite(
                panel.x + FlxG.random.float(0, panel.width),
                panel.y + FlxG.random.float(0, panel.height)
            );
            particle.makeGraphic(2, 2, FlxColor.CYAN);
            particle.alpha = FlxG.random.float(0.3, 0.7);
            particles.add(particle);

            FlxTween.tween(particle, {
                y: particle.y - FlxG.random.float(20, 40),
                alpha: 0
            }, FlxG.random.float(2, 4), {
                type: LOOPING,
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    particle.y = panel.y + panel.height;
                    particle.x = panel.x + FlxG.random.float(0, panel.width);
                    particle.alpha = FlxG.random.float(0.3, 0.7);
                }
            });
        }
    }

    function animateIn() {
        isAnimating = true;

        // Scale and fade in
        panel.scale.set(0.8, 0.8);
        panel.alpha = 0;

        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                isAnimating = false;
                FlxTween.tween(glowEffect, {alpha: 0.4}, 1, {
                    type: PINGPONG,
                    ease: FlxEase.sineInOut
                });
            }
        });

        // Fade in other elements
        for (member in members) {
            if (member != background && member != panel && member != particles && member != glowEffect) {
                if (Std.isOfType(member, FlxSprite)) {
                    var sprite:FlxSprite = cast(member, FlxSprite);
                    sprite.alpha = 0;
                    FlxTween.tween(sprite, {alpha: 1}, 0.3, {
                        ease: FlxEase.sineOut,
                        startDelay: 0.2
                    });
                }
            }
        }
    }

    function animateOut() {
        if (isAnimating) return;
        isAnimating = true;

        FlxTween.tween(panel, {"scale.x": 0.7, "scale.y": 0.7, alpha: 0}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                close();
            }
        });

        FlxTween.tween(background, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
    }

    function updateDisplays() {
        currentValueDisplay.text = currentValue.length > 0 ? currentValue : "0";

        // Validate port
        var port = Std.parseInt(currentValue);
        if (currentValue.length > 0) {
            if (port == null || port <= 0 || port > 65535) {
                showError("Port must be between 1 and 65535");
            } else {
                hideError();
            }
        } else {
            hideError();
        }
    }

    function showError(message:String) {
        hasError = true;
        errorText.text = message;
        errorText.visible = true;
        currentValueDisplay.color = FlxColor.RED;
        confirmButton.color = FlxColor.fromRGB(100, 50, 50);
        FlxFlicker.flicker(errorText, 1, 0.1);
    }

    function hideError() {
      try {
          hasError = false;
          errorText.visible = false;
          currentValueDisplay.color = FlxColor.WHITE;
          confirmButton.color = FlxColor.GREEN;
      } catch (e:haxe.Exception) {
          FlxG.log.error("Error hiding error message: " + e.message);
      }
    }

    function addDigit(digit:String) {
        if (currentValue.length < 5) { // Max 5 digits for port numbers
            currentValue += digit;
            updateDisplays();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }

    function removeLastDigit() {
        if (currentValue.length > 0) {
            currentValue = currentValue.substr(0, currentValue.length - 1);
            updateDisplays();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }

    function clearValue() {
        currentValue = "";
        updateDisplays();
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    function setPreset(value:String) {
        currentValue = value;
        updateDisplays();
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }

    function confirm() {
        if (hasError || currentValue.length == 0) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));
        onConfirm(currentValue);
        animateOut();
    }

    function cancel() {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        onCancel();
        animateOut();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (isAnimating) return;

        // Handle keyboard input using the same pattern as TextInputSubstate
        var keys = FlxG.keys.justPressed;

        // Number row keys
        if (keys.ZERO) addDigit("0");
        if (keys.ONE) addDigit("1");
        if (keys.TWO) addDigit("2");
        if (keys.THREE) addDigit("3");
        if (keys.FOUR) addDigit("4");
        if (keys.FIVE) addDigit("5");
        if (keys.SIX) addDigit("6");
        if (keys.SEVEN) addDigit("7");
        if (keys.EIGHT) addDigit("8");
        if (keys.NINE) addDigit("9");

        // Numpad keys
        if (keys.NUMPADZERO) addDigit("0");
        if (keys.NUMPADONE) addDigit("1");
        if (keys.NUMPADTWO) addDigit("2");
        if (keys.NUMPADTHREE) addDigit("3");
        if (keys.NUMPADFOUR) addDigit("4");
        if (keys.NUMPADFIVE) addDigit("5");
        if (keys.NUMPADSIX) addDigit("6");
        if (keys.NUMPADSEVEN) addDigit("7");
        if (keys.NUMPADEIGHT) addDigit("8");
        if (keys.NUMPADNINE) addDigit("9");

        // Backspace
        if (keys.BACKSPACE) {
            removeLastDigit();
        }

        // Enter to confirm
        if (keys.ENTER) {
            confirm();
        }

        // Escape to cancel
        if (keys.ESCAPE) {
            cancel();
        }

        // Mouse input
        handleMouseInput();
    }

    function handleMouseInput() {
        // Button hover effects and clicks
        if (FlxG.mouse.overlaps(confirmButton)) {
            confirmButton.color = hasError ? FlxColor.fromRGB(120, 60, 60) : FlxColor.fromRGB(150, 255, 150);
            if (FlxG.mouse.justPressed) confirm();
        } else {
            confirmButton.color = hasError ? FlxColor.fromRGB(100, 50, 50) : FlxColor.GREEN;
        }

        if (FlxG.mouse.overlaps(cancelButton)) {
            cancelButton.color = FlxColor.fromRGB(255, 150, 150);
            if (FlxG.mouse.justPressed) cancel();
        } else {
            cancelButton.color = FlxColor.RED;
        }

        if (FlxG.mouse.overlaps(clearButton)) {
            clearButton.color = FlxColor.fromRGB(255, 200, 100);
            if (FlxG.mouse.justPressed) clearValue();
        } else {
            clearButton.color = FlxColor.ORANGE;
        }

        // Preset buttons
        if (FlxG.mouse.overlaps(preset38281Button)) {
            preset38281Button.color = FlxColor.fromRGB(150, 150, 255);
            if (FlxG.mouse.justPressed) setPreset("38281");
        } else {
            preset38281Button.color = FlxColor.BLUE;
        }

        if (FlxG.mouse.overlaps(preset38282Button)) {
            preset38282Button.color = FlxColor.fromRGB(255, 150, 255);
            if (FlxG.mouse.justPressed) setPreset("38282");
        } else {
            preset38282Button.color = FlxColor.PURPLE;
        }

        if (FlxG.mouse.overlaps(preset80Button)) {
            preset80Button.color = FlxColor.fromRGB(180, 120, 60);
            if (FlxG.mouse.justPressed) setPreset("80");
        } else {
            preset80Button.color = FlxColor.fromRGB(128, 64, 0);
        }
    }

    override function destroy() {
        onConfirm = null;
        onCancel = null;
        super.destroy();
    }
}
