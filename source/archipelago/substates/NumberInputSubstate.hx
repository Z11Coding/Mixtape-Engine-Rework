package archipelago.substates;

import backend.MusicBeatSubstate;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;

/**
 * Advanced number input substate with visual styling matching the advanced settings
 * Supports keyboard input, mouse input, validation, and animated feedback
 */
class NumberInputSubstate extends MusicBeatSubstate {
    // Visual elements
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var rangeText:FlxText;
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

    // Number pad (optional visual number pad)
    var numberPad:FlxTypedGroup<FlxSprite>;
    var numberPadTexts:FlxTypedGroup<FlxText>;

    // Animation elements
    var glowEffect:FlxSprite;
    var particles:FlxTypedGroup<FlxSprite>;

    // Input state
    var currentValue:String = "";
    var minValue:Float;
    var maxValue:Float;
    var stepSize:Float;
    var allowDecimals:Bool;
    var onConfirm:Float->Void;
    var onCancel:Void->Void;

    // Visual state
    var isAnimating:Bool = false;
    var hasError:Bool = false;
    var showNumberPad:Bool = true;

    // Properties
    var title:String;
    var description:String;
    var themeColor:FlxColor;

    public function new(
        title:String,
        currentVal:Float,
        min:Float,
        max:Float,
        ?callback:Float->Void,
        ?cancelCallback:Void->Void,
        ?stepSize:Float = 1,
        ?allowDecimals:Bool = false,
        ?description:String = "",
        ?themeColor:FlxColor = null,
        ?showNumberPad:Bool = true
    ) {
        super();

        this.title = title;
        this.description = description != "" ? description : 'Enter a value between $min and $max';
        this.minValue = min;
        this.maxValue = max;
        this.stepSize = stepSize;
        this.allowDecimals = allowDecimals;
        this.onConfirm = callback != null ? callback : function(v:Float) {};
        this.onCancel = cancelCallback != null ? cancelCallback : function() {};
        this.themeColor = themeColor != null ? themeColor : FlxColor.CYAN;
        this.showNumberPad = showNumberPad;

        // Set initial value
        if (allowDecimals) {
            this.currentValue = Std.string(currentVal);
        } else {
            this.currentValue = Std.string(Std.int(currentVal));
        }

        setupVisuals();
        setupButtons();
        if (showNumberPad) setupNumberPad();
        setupAnimations();
        animateIn();
    }

    function setupVisuals() {
        // Semi-transparent background
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);

        // Main panel with gradient
        panel = FlxGradient.createGradientFlxSprite(500, 400, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = Std.int((FlxG.width - panel.width) / 2);
        panel.y = Std.int((FlxG.height - panel.height) / 2);
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, themeColor, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Description/Range info
        rangeText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40, description, 16);
        rangeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        rangeText.borderSize = 1;
        add(rangeText);

        var rangeInfo = 'Range: $minValue - $maxValue';
        if (stepSize != 1) rangeInfo += ' (Step: $stepSize)';

        var fullRangeText = new FlxText(panel.x + 20, panel.y + 85, panel.width - 40, rangeInfo, 14);
        fullRangeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        fullRangeText.borderSize = 1;
        add(fullRangeText);

        // Input display with background
        var inputBg = new FlxSprite(panel.x + 50, panel.y + 120);
        inputBg.makeGraphic(Std.int(panel.width - 100), 50, FlxColor.fromRGB(10, 10, 30));
        add(inputBg);

        inputText = new FlxText(inputBg.x + 10, inputBg.y + 10, inputBg.width - 20, currentValue, 28);
        inputText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        inputText.borderSize = 2;
        add(inputText);

        // Current value indicator
        currentValueDisplay = new FlxText(panel.x + 20, panel.y + 180, panel.width - 40, "Current: " + currentValue, 16);
        currentValueDisplay.setFormat(Paths.font("vcr.ttf"), 16, themeColor, CENTER, OUTLINE, FlxColor.BLACK);
        currentValueDisplay.borderSize = 1;
        add(currentValueDisplay);

        // Error text (initially hidden)
        errorText = new FlxText(panel.x + 20, panel.y + 200, panel.width - 40, "", 14);
        errorText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        errorText.borderSize = 1;
        errorText.visible = false;
        add(errorText);
    }

    function setupButtons() {
        var buttonY = panel.y + panel.height - 70;
        var buttonWidth = 120;
        var buttonHeight = 40;
        var buttonSpacing = 20;

        // Calculate button positions
        var totalWidth = (buttonWidth * 3) + (buttonSpacing * 2);
        var startX = panel.x + (panel.width - totalWidth) / 2;

        // Confirm button
        confirmButton = new FlxSprite(startX, buttonY);
        confirmButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
        add(confirmButton);

        confirmButtonText = new FlxText(confirmButton.x, confirmButton.y + 10, confirmButton.width, "CONFIRM", 16);
        confirmButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        confirmButtonText.borderSize = 1;
        add(confirmButtonText);

        // Clear button
        clearButton = new FlxSprite(startX + buttonWidth + buttonSpacing, buttonY);
        clearButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.YELLOW);
        add(clearButton);

        clearButtonText = new FlxText(clearButton.x, clearButton.y + 10, clearButton.width, "CLEAR", 16);
        clearButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        clearButtonText.borderSize = 1;
        add(clearButtonText);

        // Cancel button
        cancelButton = new FlxSprite(startX + (buttonWidth + buttonSpacing) * 2, buttonY);
        cancelButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
        add(cancelButton);

        cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 16);
        cancelButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelButtonText.borderSize = 1;
        add(cancelButtonText);
    }

    function setupNumberPad() {
        numberPad = new FlxTypedGroup<FlxSprite>();
        numberPadTexts = new FlxTypedGroup<FlxText>();
        add(numberPad);
        add(numberPadTexts);

        var padStartX = panel.x + 60;
        var padStartY = panel.y + 220;
        var buttonSize = 50;
        var buttonSpacing = 10;

        // Create 3x4 number pad layout (1-9, *, 0, #)
        var numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "←", "0", "."];

        for (i in 0...12) {
            var row = Std.int(i / 3);
            var col = i % 3;

            var button = new FlxSprite(
                padStartX + col * (buttonSize + buttonSpacing),
                padStartY + row * (buttonSize + buttonSpacing)
            );

            var isSpecial = (numbers[i] == "←" || numbers[i] == ".");
            button.makeGraphic(buttonSize, buttonSize, isSpecial ? FlxColor.ORANGE : FlxColor.fromRGB(40, 40, 80));
            button.ID = i;
            numberPad.add(button);

            var text = new FlxText(button.x, button.y + 15, button.width, numbers[i], 20);
            text.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
            text.borderSize = 1;
            text.ID = i;
            numberPadTexts.add(text);
        }
    }

    function setupAnimations() {
        // Glow effect for input area
        glowEffect = new FlxSprite(inputText.x - 5, inputText.y - 5);
        glowEffect.makeGraphic(Std.int(inputText.width + 10), Std.int(inputText.height + 10), themeColor);
        glowEffect.alpha = 0;
        insert(members.indexOf(inputText), glowEffect);

        // Particle system
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        for (i in 0...8) {
            var particle = new FlxSprite(
                FlxG.random.float(panel.x, panel.x + panel.width),
                FlxG.random.float(panel.y, panel.y + panel.height)
            );
            particle.makeGraphic(2, 2, themeColor);
            particle.alpha = FlxG.random.float(0.3, 0.7);
            particles.add(particle);

            FlxTween.tween(particle, {
                y: particle.y - FlxG.random.float(20, 50),
                alpha: 0
            }, FlxG.random.float(2, 4), {
                type: LOOPING,
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    particle.y = panel.y + panel.height;
                    particle.x = FlxG.random.float(panel.x, panel.x + panel.width);
                    particle.alpha = FlxG.random.float(0.3, 0.7);
                }
            });
        }
    }

    function animateIn() {
        isAnimating = true;

        // Scale in animation for panel
        panel.scale.set(0.5, 0.5);
        panel.alpha = 0;

        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                isAnimating = false;
            }
        });

        // Fade in other elements with delay
        for (member in members) {
            if (member != background && member != panel && member != particles) {
                // Only apply alpha to visual objects that support it
                if (Std.isOfType(member, FlxSprite)) {
                    var sprite:FlxSprite = cast(member, FlxSprite);
                    sprite.alpha = 0;
                    FlxTween.tween(sprite, {alpha: 1}, 0.3, {
                        startDelay: 0.2,
                        ease: FlxEase.sineOut
                    });
                } else if (Std.isOfType(member, FlxText)) {
                    var text:FlxText = cast(member, FlxText);
                    text.alpha = 0;
                    FlxTween.tween(text, {alpha: 1}, 0.3, {
                        startDelay: 0.2,
                        ease: FlxEase.sineOut
                    });
                }
            }
        }

        // Glow effect pulse
        FlxTween.tween(glowEffect, {alpha: 0.3}, 1, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function animateOut(onComplete:Void->Void) {
        isAnimating = true;

        // Count animations to know when we're done
        var animationCount = 0;
        var totalAnimations = 0;

        // Count how many elements we'll animate
        for (member in members) {
            if (member != background && member != particles) {
                if (Std.isOfType(member, FlxSprite) || Std.isOfType(member, FlxText)) {
                    totalAnimations++;
                } else if (Std.isOfType(member, FlxTypedGroup)) {
                    var group:FlxTypedGroup<Dynamic> = cast member;
                    totalAnimations += group.members.length;
                }
            }
        }

        var onAnimationComplete = function() {
            animationCount++;
            if (animationCount >= totalAnimations) {
                onComplete();
            }
        };

        // Animate out all visual elements
        for (member in members) {
            if (member != background && member != particles) {
                if (Std.isOfType(member, FlxSprite)) {
                    var sprite:FlxSprite = cast(member, FlxSprite);
                    FlxTween.tween(sprite, {alpha: 0}, 0.3, {
                        ease: FlxEase.sineIn,
                        onComplete: function(_) onAnimationComplete()
                    });
                } else if (Std.isOfType(member, FlxText)) {
                    var text:FlxText = cast(member, FlxText);
                    FlxTween.tween(text, {alpha: 0}, 0.3, {
                        ease: FlxEase.sineIn,
                        onComplete: function(_) onAnimationComplete()
                    });
                } else if (Std.isOfType(member, FlxTypedGroup)) {
                    var group:FlxTypedGroup<Dynamic> = cast member;
                    group.forEachAlive(function(groupMember:Dynamic) {
                        if (Std.isOfType(groupMember, FlxSprite)) {
                            var sprite:FlxSprite = cast(groupMember, FlxSprite);
                            FlxTween.tween(sprite, {alpha: 0}, 0.3, {
                                ease: FlxEase.sineIn,
                                onComplete: function(_) onAnimationComplete()
                            });
                        } else if (Std.isOfType(groupMember, FlxText)) {
                            var text:FlxText = cast(groupMember, FlxText);
                            FlxTween.tween(text, {alpha: 0}, 0.3, {
                                ease: FlxEase.sineIn,
                                onComplete: function(_) onAnimationComplete()
                            });
                        }
                    });
                }
            }
        }

        // Animate background separately (faster fade)
        FlxTween.tween(background, {alpha: 0}, 0.2, {
            ease: FlxEase.sineIn
        });

        // Safety fallback in case animation counting fails
        new FlxTimer().start(0.5, function(_) {
            if (isAnimating) {
                onComplete();
            }
        });
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (isAnimating) return;

        // Handle keyboard input
        handleKeyboardInput();

        // Handle mouse input
        handleMouseInput();

        // Update displays
        updateDisplays();
    }

    function handleKeyboardInput() {
        // Number input
        for (i in 0...10) {
            var key = Reflect.field(FlxG.keys.justPressed, 'NUMPAD$i');
            var regularKey = Reflect.field(FlxG.keys.justPressed, Std.string(i));

            if (key || regularKey) {
                addDigit(Std.string(i));
            }
        }

        // Decimal point (if allowed)
        if (allowDecimals && FlxG.keys.justPressed.PERIOD) {
            addDecimal();
        }

        // Backspace
        if (FlxG.keys.justPressed.BACKSPACE) {
            removeLastDigit();
        }

        // Enter to confirm
        if (FlxG.keys.justPressed.ENTER) {
            confirmInput();
        }

        // Escape to cancel
        if (FlxG.keys.justPressed.ESCAPE) {
            cancelInput();
        }

        // Clear
        if (FlxG.keys.justPressed.DELETE) {
            clearInput();
        }
    }

    function handleMouseInput() {
        if (!FlxG.mouse.justPressed) return;

        // Check main buttons
        if (FlxG.mouse.overlaps(confirmButton)) {
            confirmInput();
        } else if (FlxG.mouse.overlaps(cancelButton)) {
            cancelInput();
        } else if (FlxG.mouse.overlaps(clearButton)) {
            clearInput();
        }

        // Check number pad (if visible)
        if (showNumberPad) {
            numberPad.forEachAlive(function(button:FlxSprite) {
                if (FlxG.mouse.overlaps(button)) {
                    var numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "←", "0", "."];
                    var value = numbers[button.ID];

                    switch (value) {
                        case "←":
                            removeLastDigit();
                        case ".":
                            if (allowDecimals) addDecimal();
                        default:
                            addDigit(value);
                    }

                    // Visual feedback
                    FlxFlicker.flicker(button, 0.1, 0.05);
                }
            });
        }
    }

    function addDigit(digit:String) {
        if (currentValue.length < 10) { // Reasonable limit
            currentValue += digit;
            playInputSound();
            clearError();
        }
    }

    function addDecimal() {
        if (currentValue.indexOf(".") == -1) { // Only one decimal point
            if (currentValue == "") currentValue = "0";
            currentValue += ".";
            playInputSound();
            clearError();
        }
    }

    function removeLastDigit() {
        if (currentValue.length > 0) {
            currentValue = currentValue.substr(0, currentValue.length - 1);
            playInputSound();
            clearError();
        }
    }

    function clearInput() {
        currentValue = "";
        playInputSound();
        clearError();
    }

    function updateDisplays() {
        inputText.text = currentValue == "" ? "0" : currentValue;

        var displayValue = currentValue == "" ? "0" : currentValue;
        currentValueDisplay.text = "Current: " + displayValue;

        // Validate and update colors
        var isValid = validateInput();
        inputText.color = isValid ? FlxColor.WHITE : FlxColor.RED;
        currentValueDisplay.color = isValid ? themeColor : FlxColor.RED;

        // Update confirm button state
        confirmButton.color = isValid ? FlxColor.GREEN : FlxColor.GRAY;
        confirmButtonText.color = isValid ? FlxColor.WHITE : FlxColor.GRAY;
    }

    function validateInput():Bool {
        if (currentValue == "") return false;

        var value = Std.parseFloat(currentValue);
        if (Math.isNaN(value)) return false;

        return value >= minValue && value <= maxValue;
    }

    function confirmInput() {
        if (!validateInput()) {
            showError("Invalid input! Please enter a value between " + minValue + " and " + maxValue);
            return;
        }

        var value = Std.parseFloat(currentValue);

        // Apply step size if needed
        if (stepSize != 1) {
            value = Math.round(value / stepSize) * stepSize;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));

        animateOut(function() {
            onConfirm(value);
            close();
        });
    }

    function cancelInput() {
        FlxG.sound.play(Paths.sound('cancelMenu'));

        animateOut(function() {
            onCancel();
            close();
        });
    }

    function showError(message:String) {
        errorText.text = message;
        errorText.visible = true;
        hasError = true;

        FlxG.sound.play(Paths.sound('cancelMenu'));
        FlxG.camera.shake(0.01, 0.2);

        // Flash input red
        FlxFlicker.flicker(inputText, 0.5, 0.1, true);

        // Hide error after 3 seconds
        new FlxTimer().start(3, function(_) {
            clearError();
        });
    }

    function clearError() {
        if (hasError) {
            errorText.visible = false;
            hasError = false;
        }
    }

    function playInputSound() {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }

    override function destroy() {
        // Clean up callbacks
        onConfirm = null;
        onCancel = null;

        super.destroy();
    }
}
