package archipelago.substates;

import archipelago.APInfo;
import backend.MusicBeatSubstate;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;

enum InputMode {
    BASIC;
    YAML;
    PASSWORD;
}

/**
 * Text input substate with visual styling matching the advanced settings
 * Supports keyboard input, mouse input, validation, and animated feedback
 */
class TextInputSubstate extends MusicBeatSubstate {
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

    // Animation elements
    var glowEffect:FlxSprite;
    var particles:FlxTypedGroup<FlxSprite>;

    // Input state
    var currentValue:String = "";
    var maxLength:Int;
    var allowedChars:String;
    var onConfirm:String->Void;
    var onCancel:Void->Void;
    var inputMode:InputMode = BASIC;

    // Visual state
    var isAnimating:Bool = false;
    var hasError:Bool = false;

    // Properties
    var title:String;
    var description:String;
    var themeColor:FlxColor;

    public function new(
        title:String,
        currentVal:String,
        ?callback:String->Void,
        ?cancelCallback:Void->Void,
        ?maxLength:Int = 50,
        ?allowedChars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_",
        ?description:String = "",
        ?themeColor:FlxColor = null,
        ?inputMode:InputMode = BASIC
    ) {
        super();

        this.title = title;
        var defaultDescription = 'Enter text (max $maxLength characters)';
        if (inputMode == YAML) {
            defaultDescription += "\nYAML-safe mode: Some special characters restricted";
        }
        this.description = description != "" ? description : defaultDescription;
        this.maxLength = maxLength;
        this.allowedChars = allowedChars;
        this.onConfirm = callback != null ? callback : function(v:String) {};
        this.onCancel = cancelCallback != null ? cancelCallback : function() {};
        this.themeColor = themeColor != null ? themeColor : FlxColor.CYAN;
        this.inputMode = inputMode;

        // Set initial value
        this.currentValue = currentVal != null ? currentVal : "";

        setupVisuals();
        setupButtons();
        setupAnimations();
        animateIn();
    }

    function setupVisuals() {
        // Semi-transparent background
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);

        // Main panel with gradient
        panel = FlxGradient.createGradientFlxSprite(500, 350, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = Std.int((FlxG.width - panel.width) / 2);
        panel.y = Std.int((FlxG.height - panel.height) / 2);
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, themeColor, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Description
        descriptionText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40, description, 16);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);

        var lengthInfo = 'Max Length: $maxLength characters';
        var lengthText = new FlxText(panel.x + 20, panel.y + 85, panel.width - 40, lengthInfo, 14);
        lengthText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        lengthText.borderSize = 1;
        add(lengthText);

        // Input display with background
        var inputBg = new FlxSprite(panel.x + 20, panel.y + 120);
        inputBg.makeGraphic(Std.int(panel.width - 40), 50, FlxColor.fromRGB(10, 10, 30));
        add(inputBg);

        // Initialize with masked text if password mode
        var initialDisplayText = currentValue;
        if (inputMode == PASSWORD && currentValue.length > 0) {
            initialDisplayText = "";
            for (i in 0...currentValue.length) {
                initialDisplayText += "•";
            }
        }

        inputText = new FlxText(inputBg.x + 10, inputBg.y + 10, inputBg.width - 20, initialDisplayText, 20);
        inputText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        inputText.borderSize = 2;
        add(inputText);

        // Current value indicator
        currentValueDisplay = new FlxText(panel.x + 20, panel.y + 180, panel.width - 40, "Length: " + currentValue.length + "/" + maxLength, 16);
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
        // Character input
        var inputText = FlxG.keys.getIsDown().join("");

        // Check each pressed key
        var keys = FlxG.keys.justPressed;
        var keysPressed = [];

        // Check alphanumeric keys
        if (keys.A) keysPressed.push("A");
        if (keys.B) keysPressed.push("B");
        if (keys.C) keysPressed.push("C");
        if (keys.D) keysPressed.push("D");
        if (keys.E) keysPressed.push("E");
        if (keys.F) keysPressed.push("F");
        if (keys.G) keysPressed.push("G");
        if (keys.H) keysPressed.push("H");
        if (keys.I) keysPressed.push("I");
        if (keys.J) keysPressed.push("J");
        if (keys.K) keysPressed.push("K");
        if (keys.L) keysPressed.push("L");
        if (keys.M) keysPressed.push("M");
        if (keys.N) keysPressed.push("N");
        if (keys.O) keysPressed.push("O");
        if (keys.P) keysPressed.push("P");
        if (keys.Q) keysPressed.push("Q");
        if (keys.R) keysPressed.push("R");
        if (keys.S) keysPressed.push("S");
        if (keys.T) keysPressed.push("T");
        if (keys.U) keysPressed.push("U");
        if (keys.V) keysPressed.push("V");
        if (keys.W) keysPressed.push("W");
        if (keys.X) keysPressed.push("X");
        if (keys.Y) keysPressed.push("Y");
        if (keys.Z) keysPressed.push("Z");

        // Only add numbers if SHIFT is not pressed (to avoid conflict with special chars)
        if (!FlxG.keys.pressed.SHIFT) {
            if (keys.ZERO) keysPressed.push("0");
            if (keys.ONE) keysPressed.push("1");
            if (keys.TWO) keysPressed.push("2");
            if (keys.THREE) keysPressed.push("3");
            if (keys.FOUR) keysPressed.push("4");
            if (keys.FIVE) keysPressed.push("5");
            if (keys.SIX) keysPressed.push("6");
            if (keys.SEVEN) keysPressed.push("7");
            if (keys.EIGHT) keysPressed.push("8");
            if (keys.NINE) keysPressed.push("9");
        }

        if (keys.SPACE) keysPressed.push(" ");
        if (keys.MINUS) {
            if (FlxG.keys.pressed.SHIFT) {
                keysPressed.push("_"); // SHIFT+MINUS = underscore
            } else {
                keysPressed.push("-");
            }
        }

        if (keys.PERIOD) keysPressed.push(".");
        if (keys.COMMA) keysPressed.push(",");

        // Add support for common special characters (in password and YAML modes)
        if (inputMode == PASSWORD || inputMode == YAML) {
            if (keys.SEMICOLON) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push(":"); // SHIFT+SEMICOLON = colon
                } else {
                    keysPressed.push(";");
                }
            }
            if (keys.QUOTE) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("\""); // SHIFT+QUOTE = double quote
                } else {
                    keysPressed.push("'");
                }
            }
            if (keys.SLASH) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("?"); // SHIFT+SLASH = question mark
                } else {
                    keysPressed.push("/");
                }
            }

            // Number row special characters (SHIFT + number keys)
            if (FlxG.keys.pressed.SHIFT) {
                if (keys.ONE) keysPressed.push("!");
                if (keys.TWO) keysPressed.push("@");
                if (keys.THREE) keysPressed.push("#");
                if (keys.FOUR) keysPressed.push("$");
                if (keys.FIVE) keysPressed.push("%");
                if (keys.SIX) keysPressed.push("^");
                if (keys.SEVEN) keysPressed.push("&");
                if (keys.EIGHT) keysPressed.push("*");
                if (keys.NINE) keysPressed.push("(");
                if (keys.ZERO) keysPressed.push(")");
            }

            // Equals and plus/minus
            if (keys.PLUS) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("+"); // SHIFT+PLUS = plus
                } else {
                    keysPressed.push("=");
                }
            }
        }

        // Additional characters only allowed in password mode
        if (inputMode == PASSWORD) {
            if (keys.LBRACKET) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("{"); // SHIFT+LBRACKET = left brace
                } else {
                    keysPressed.push("[");
                }
            }
            if (keys.RBRACKET) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("}"); // SHIFT+RBRACKET = right brace
                } else {
                    keysPressed.push("]");
                }
            }
            if (keys.BACKSLASH) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("|"); // SHIFT+BACKSLASH = pipe
                } else {
                    keysPressed.push("\\");
                }
            }
            if (keys.GRAVEACCENT) {
                if (FlxG.keys.pressed.SHIFT) {
                    keysPressed.push("~"); // SHIFT+GRAVEACCENT = tilde
                } else {
                    keysPressed.push("`");
                }
            }
        }


        // Process each key
        for (key in keysPressed) {
            var char = key;

            // Only apply lowercase conversion to letters when SHIFT is not pressed
            // Don't convert special characters or symbols
            if (!FlxG.keys.pressed.SHIFT && char.length == 1) {
                var charCode = char.charCodeAt(0);
                // Only convert A-Z to lowercase
                if (charCode >= 65 && charCode <= 90) {
                    char = char.toLowerCase();
                }
            }

            // Character validation based on mode
            switch (inputMode) {
                case YAML:
                    if (isValidYamlCharacterForTyping(char, currentValue.length)) {
                        addCharacter(char);
                    }
                case PASSWORD:
                    var charCode = char.charCodeAt(0);
                    if (charCode >= 32 && charCode <= 126) {
                        addCharacter(char);
                    }
                case BASIC:
                    if (allowedChars.indexOf(char) != -1) {
                        addCharacter(char);
                    }
            }
        }

        // Backspace
        if (FlxG.keys.justPressed.BACKSPACE) {
            removeLastCharacter();
        }

        // Enter to confirm
        if (FlxG.keys.justPressed.ENTER) {
            confirmInput();
        }

        // Escape to cancel
        if (FlxG.keys.justPressed.ESCAPE) {
            cancelInput();
        }

        // Delete to clear
        if (FlxG.keys.justPressed.DELETE) {
            clearInput();
        }

        // Paste functionality (Ctrl+V)
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V) {
            handlePaste();
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
    }

    function isValidYamlCharacterForTyping(char:String, position:Int):Bool {
        // Check if character is in the general escape map (not allowed anywhere)
        for (escapedChar in APInfo.YAMLEscapeMap.keys()) {
            if (APInfo.YAMLEscapeMap.get(escapedChar) == char) {
                return false; // Never allowed in YAML mode
            }
        }

        // Check if character is in the start escape map (not allowed at start)
        if (position == 0) {
            for (escapedChar in APInfo.YAMLStartEscapeMap.keys()) {
                if (APInfo.YAMLStartEscapeMap.get(escapedChar) == char) {
                    return false; // Never allowed at start
                }
            }
        }

        // Don't check end map during typing - allow end characters to be typed
        // End validation will be handled during final validation

        // Allow all other printable characters
        var charCode = char.charCodeAt(0);
        return (charCode >= 32 && charCode <= 126);
    }

    function isValidYamlCharacterForValidation(char:String, position:Int, stringLength:Int):Bool {
        // Check if character is in the general escape map (not allowed anywhere)
        for (escapedChar in APInfo.YAMLEscapeMap.keys()) {
            if (APInfo.YAMLEscapeMap.get(escapedChar) == char) {
                return false;
            }
        }

        // Check if character is in the start escape map (not allowed at start)
        if (position == 0) {
            for (escapedChar in APInfo.YAMLStartEscapeMap.keys()) {
                if (APInfo.YAMLStartEscapeMap.get(escapedChar) == char) {
                    return false;
                }
            }
        }

        // Check if character is in the end escape map (not allowed at end)
        if (position == stringLength - 1 && stringLength > 0) {
            for (escapedChar in APInfo.YAMLEndEscapeMap.keys()) {
                if (APInfo.YAMLEndEscapeMap.get(escapedChar) == char) {
                    return false;
                }
            }
        }

        return true;
    }

    function isValidYamlCharacter(char:String, position:Int, stringLength:Int):Bool {
        // Check if character is in the general escape map (not allowed anywhere)
        for (escapedChar in APInfo.YAMLEscapeMap.keys()) {
            if (APInfo.YAMLEscapeMap.get(escapedChar) == char) {
                // Only allow in password mode
                return inputMode == PASSWORD;
            }
        }

        // Check if character is in the start escape map (not allowed at start)
        if (position == 0) {
            for (escapedChar in APInfo.YAMLStartEscapeMap.keys()) {
                if (APInfo.YAMLStartEscapeMap.get(escapedChar) == char) {
                    return inputMode == PASSWORD; // Only allow in password mode
                }
            }
        }

        // Check if character is in the end escape map (not allowed at end)
        if (position == stringLength - 1 && stringLength > 0) {
            for (escapedChar in APInfo.YAMLEndEscapeMap.keys()) {
                if (APInfo.YAMLEndEscapeMap.get(escapedChar) == char) {
                    return inputMode == PASSWORD; // Only allow in password mode
                }
            }
        }

        // Allow all other printable characters in password mode, or use allowedChars in normal mode
        if (inputMode == PASSWORD) {
            var charCode = char.charCodeAt(0);
            return (charCode >= 32 && charCode <= 126);
        } else {
            return allowedChars.indexOf(char) != -1;
        }
    }

    function addCharacter(char:String) {
        if (currentValue.length < maxLength) {
            currentValue += char;
            playInputSound();
            clearError();
        }
    }

    function removeLastCharacter() {
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

    function handlePaste() {
        #if desktop
        try {
            // Use openfl clipboard for cross-platform compatibility
            var clipboardText = lime.system.Clipboard.text;

            if (clipboardText != null && clipboardText.length > 0) {
                // Filter the clipboard text to only allowed characters
                var filteredText = "";
                for (i in 0...clipboardText.length) {
                    var char = clipboardText.charAt(i);
                    // Use appropriate validation based on mode
                    switch (inputMode) {
                        case YAML:
                            if (isValidYamlCharacterForTyping(char, filteredText.length)) {
                                filteredText += char;
                            }
                        case PASSWORD:
                            var charCode = char.charCodeAt(0);
                            if (charCode >= 32 && charCode <= 126) {
                                filteredText += char;
                            }
                        case BASIC:
                            if (allowedChars == "" || allowedChars.indexOf(char) != -1) {
                                filteredText += char;
                            }
                    }
                }

                // Replace current value or append depending on context
                // For simplicity, let's replace the current value
                if (filteredText.length > maxLength) {
                    filteredText = filteredText.substring(0, maxLength);
                }

                currentValue = filteredText;
                playInputSound();
                clearError();
            }
        } catch (e:Dynamic) {
            // Clipboard access failed, silently ignore
            trace("Paste failed: " + e);
        }
        #end
    }

    function updateDisplays() {
        // Display masked text if in password mode
        var displayText = currentValue;
        if (inputMode == PASSWORD && currentValue.length > 0) {
            displayText = "";
            for (i in 0...currentValue.length) {
                displayText += "•";
            }
        }
        inputText.text = displayText == "" ? "" : displayText;
        currentValueDisplay.text = "Length: " + currentValue.length + "/" + maxLength;

        // Validate and update colors
        var isValid = validateInput();
        inputText.color = isValid ? FlxColor.WHITE : FlxColor.RED;
        currentValueDisplay.color = isValid ? themeColor : FlxColor.RED;

        // Update confirm button state
        confirmButton.color = isValid ? FlxColor.GREEN : FlxColor.GRAY;
        confirmButtonText.color = isValid ? FlxColor.WHITE : FlxColor.GRAY;
    }

    function validateInput():Bool {
        if (currentValue.length == 0) return false;
        if (currentValue.length > maxLength) return false;

        switch (inputMode) {
            case YAML:
                return isValidYamlString(currentValue);
            case PASSWORD:
                // Just check for basic printable ASCII range (space to tilde)
                for (i in 0...currentValue.length) {
                    var charCode = currentValue.charCodeAt(i);
                    if (charCode < 32 || charCode > 126) {
                        return false;
                    }
                }
            case BASIC:
                // Check if all characters are allowed
                for (i in 0...currentValue.length) {
                    var char = currentValue.charAt(i);
                    if (allowedChars.indexOf(char) == -1) {
                        return false;
                    }
                }
        }

        return true;
    }

    function isValidYamlString(str:String):Bool {
        if (str.length == 0) return false;

        // Validate each character with its position context
        for (i in 0...str.length) {
            var char = str.charAt(i);
            if (!isValidYamlCharacterForValidation(char, i, str.length)) {
                return false;
            }
        }

        return true;
    }

    function confirmInput() {
        if (!validateInput()) {
            var errorMsg = "Invalid input! Please enter valid text (max " + maxLength + " characters)";
            if (inputMode == YAML) {
                errorMsg = "Invalid YAML input! Avoid special characters at start/end and use allowed characters only.";
            }
            showError(errorMsg);
            return;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));

        animateOut(function() {
            if (onConfirm != null) onConfirm(currentValue);
            close();
        });
    }

    function cancelInput() {
        FlxG.sound.play(Paths.sound('cancelMenu'));

        animateOut(function() {
            if (onCancel != null) onCancel();
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
