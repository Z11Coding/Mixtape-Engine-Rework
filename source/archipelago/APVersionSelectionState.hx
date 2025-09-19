package archipelago;

import archipelago.APEntryState;
import archipelago.APStyledEntryState;
import backend.MusicBeatState;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import states.MainMenuState;

/**
 * State for choosing between different Archipelago entry state versions
 * Provides a clean selection interface with preview information
 */
class APVersionSelectionState extends MusicBeatState {
    // Visual elements
    var bg:FlxSprite;
    var gradientOverlay:FlxSprite;
    var titleText:FlxText;
    var subtitleText:FlxText;
    var backButton:FlxSprite;
    var backButtonText:FlxText;

    // Selection options
    var classicOption:FlxSprite;
    var classicTitle:FlxText;
    var classicDescription:FlxText;
    var classicPreview:FlxSprite;

    var styledOption:FlxSprite;
    var styledTitle:FlxText;
    var styledDescription:FlxText;
    var styledPreview:FlxSprite;

    // Animation elements
    var particles:FlxTypedGroup<FlxSprite>;
    var glowEffects:FlxTypedGroup<FlxSprite>;

    // Selection state
    var selectedOption:Int = 0; // 0 = classic, 1 = styled
    var isAnimating:Bool = false;
    var navigationCooldown:Float = 0;
    var navigationDelay:Float = 0.2;

    // Settings
    static var rememberChoice:Bool = false;
    static var lastChoice:Int = 1; // Default to styled version

    override function create() {
        super.create();

        if (!FlxG.sound.music.playing || FlxG.sound.music == null)
            MusicManager.playMenuMusic();

        Cursor.show();
        Cursor.cursorMode = Default;

        // Load saved preferences
        loadPreferences();

        setupBackground();
        setupUI();
        setupOptions();
        setupAnimations();

        // Set initial selection
        selectedOption = lastChoice;
        updateSelection();

        // Animate in
        animateIn();
    }

    function loadPreferences() {
        var save = new FlxSave();
        save.bind("APVersionSelection");

        if (save.data.rememberChoice != null) {
            rememberChoice = save.data.rememberChoice;
        }
        if (save.data.lastChoice != null) {
            lastChoice = save.data.lastChoice;
        }

        save.destroy();
    }

    function savePreferences() {
        var save = new FlxSave();
        save.bind("APVersionSelection");

        save.data.rememberChoice = rememberChoice;
        save.data.lastChoice = selectedOption;
        save.flush();
        save.destroy();
    }

    function setupBackground() {
        // Dynamic gradient background
        bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0xFF0d1a2e, 0xFF1a2e42, 0xFF2e4256], 1, 90);
        bg.scrollFactor.set();
        add(bg);

        // Animated overlay
        gradientOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0x00000000, 0x336b35ff, 0x00000000], 1, 0);
        gradientOverlay.scrollFactor.set();
        gradientOverlay.alpha = 0.4;
        add(gradientOverlay);

        // Animate overlay
        FlxTween.tween(gradientOverlay, {alpha: 0.6}, 3, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function setupUI() {
        // Title
        titleText = new FlxText(50, 40, FlxG.width - 100, "CHOOSE ARCHIPELAGO INTERFACE", 42);
        titleText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 3;
        add(titleText);

        // Subtitle
        subtitleText = new FlxText(50, 90, FlxG.width - 100, "Select your preferred Archipelago experience", 18);
        subtitleText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        subtitleText.borderSize = 1;
        add(subtitleText);

        // Back button
        backButton = new FlxSprite(50, FlxG.height - 70);
        backButton.makeGraphic(150, 50, FlxColor.RED);
        add(backButton);

        backButtonText = new FlxText(backButton.x, backButton.y + 12, backButton.width, "BACK TO MENU", 16);
        backButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        backButtonText.borderSize = 1;
        add(backButtonText);
    }

    function setupOptions() {
        var optionWidth = 350;
        var optionHeight = 400;
        var spacing = 50;
        var startX = (FlxG.width - (optionWidth * 2 + spacing)) / 2;
        var startY = 150;

        // Classic option
        classicOption = new FlxSprite(startX, startY);
        classicOption.makeGraphic(optionWidth, optionHeight, FlxColor.fromRGB(30, 30, 50));
        add(classicOption);

        classicTitle = new FlxText(classicOption.x + 10, classicOption.y + 20, optionWidth - 20, "CLASSIC", 28);
        classicTitle.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        classicTitle.borderSize = 2;
        add(classicTitle);

        classicDescription = new FlxText(classicOption.x + 15, classicOption.y + 60, optionWidth - 30,
            "Original Archipelago interface\n\n" +
            "• Familiar layout\n" +
            "• Straightforward design\n" +
            "• Quick access to settings\n" +
            "• Minimal visual effects\n" +
            "• Classic FNF styling\n\n" +
            "Perfect for users who prefer\na simple, functional interface.", 14);
        classicDescription.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
        classicDescription.borderSize = 1;
        add(classicDescription);

        // Classic preview (simple representation)
        classicPreview = new FlxSprite(classicOption.x + 20, classicOption.y + 260);
        classicPreview.makeGraphic(optionWidth - 40, 80, FlxColor.fromRGB(50, 50, 70));
        add(classicPreview);

        var classicPreviewText = new FlxText(classicPreview.x + 5, classicPreview.y + 5, classicPreview.width - 10,
            "HOST: [___________]\nPORT: [_____]\nSLOT: [___________]", 12);
        classicPreviewText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        classicPreviewText.borderSize = 1;
        add(classicPreviewText);

        // Styled option
        styledOption = new FlxSprite(startX + optionWidth + spacing, startY);
        styledOption.makeGraphic(optionWidth, optionHeight, FlxColor.fromRGB(30, 30, 50));
        add(styledOption);

        styledTitle = new FlxText(styledOption.x + 10, styledOption.y + 20, optionWidth - 20, "MODERN", 28);
        styledTitle.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        styledTitle.borderSize = 2;
        add(styledTitle);

        styledDescription = new FlxText(styledOption.x + 15, styledOption.y + 60, optionWidth - 30,
            "Advanced styled interface\n\n" +
            "• Multi-page navigation\n" +
            "• Animated visual effects\n" +
            "• Contextual information\n" +
            "• Theme-based colors\n" +
            "• Professional design\n\n" +
            "Recommended for users who\nenjoy modern UI experiences.", 14);
        styledDescription.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
        styledDescription.borderSize = 1;
        add(styledDescription);

        // Styled preview (gradient representation)
        styledPreview = FlxGradient.createGradientFlxSprite(optionWidth - 40, 80,
            [0xFF1a0d2e, 0xFF16213e], 1, 90);
        styledPreview.x = styledOption.x + 20;
        styledPreview.y = styledOption.y + 260;
        add(styledPreview);

        var styledPreviewText = new FlxText(styledPreview.x + 5, styledPreview.y + 5, styledPreview.width - 10,
            "◄ CONNECTION ►\n[■■■■■■■■■■■■■■■■■■]\n✓ Info Panel  ⚙ Settings", 12);
        styledPreviewText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
        styledPreviewText.borderSize = 1;
        add(styledPreviewText);

        // Selection indicators (will be positioned in updateSelection)
        var selectionFrameClassic = new FlxSprite();
        selectionFrameClassic.makeGraphic(optionWidth + 10, optionHeight + 10, FlxColor.TRANSPARENT);
        selectionFrameClassic.makeGraphic(optionWidth + 10, optionHeight + 10, FlxColor.TRANSPARENT);
        // Create border effect manually since FlxSprite doesn't have a direct border method
        selectionFrameClassic.makeGraphic(optionWidth + 10, 5, FlxColor.WHITE); // Top
        add(selectionFrameClassic);

        var selectionFrameStyled = new FlxSprite();
        selectionFrameStyled.makeGraphic(optionWidth + 10, optionHeight + 10, FlxColor.TRANSPARENT);
        add(selectionFrameStyled);

        // Remember choice checkbox
        var rememberLabel = new FlxText(FlxG.width - 250, FlxG.height - 100, 200, "Remember my choice", 14);
        rememberLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        rememberLabel.borderSize = 1;
        add(rememberLabel);

        var rememberCheckbox = new FlxSprite(FlxG.width - 270, FlxG.height - 95);
        rememberCheckbox.makeGraphic(20, 20, rememberChoice ? FlxColor.GREEN : FlxColor.GRAY);
        add(rememberCheckbox);

        var checkmarkText = new FlxText(rememberCheckbox.x + 2, rememberCheckbox.y + 2, 16, rememberChoice ? "✓" : "", 12);
        checkmarkText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        add(checkmarkText);
    }

    function setupAnimations() {
        // Glow effects for selection
        glowEffects = new FlxTypedGroup<FlxSprite>();
        add(glowEffects);

        var classicGlow = new FlxSprite(classicOption.x - 5, classicOption.y - 5);
        classicGlow.makeGraphic(Std.int(classicOption.width + 10), Std.int(classicOption.height + 10), FlxColor.WHITE);
        classicGlow.alpha = 0;
        glowEffects.add(classicGlow);

        var styledGlow = new FlxSprite(styledOption.x - 5, styledOption.y - 5);
        styledGlow.makeGraphic(Std.int(styledOption.width + 10), Std.int(styledOption.height + 10), FlxColor.CYAN);
        styledGlow.alpha = 0;
        glowEffects.add(styledGlow);

        // Particle system
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        for (i in 0...15) {
            var particle = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
            particle.makeGraphic(2, 2, FlxColor.WHITE);
            particle.alpha = FlxG.random.float(0.2, 0.6);
            particles.add(particle);

            FlxTween.tween(particle, {y: particle.y - FlxG.random.float(50, 150)}, FlxG.random.float(3, 8), {
                type: LOOPING,
                ease: FlxEase.sineInOut,
                onComplete: function(_) {
                    particle.y = FlxG.height + 10;
                    particle.x = FlxG.random.float(0, FlxG.width);
                }
            });
        }
    }

    function updateSelection() {
        // Update glow effects
        glowEffects.forEachAlive(function(glow:FlxSprite) {
            glow.alpha = 0;
        });

        var selectedGlow = glowEffects.members[selectedOption];
        if (selectedGlow != null) {
            FlxTween.tween(selectedGlow, {alpha: 0.4}, 0.3, {
                type: PINGPONG,
                ease: FlxEase.sineInOut
            });
        }

        // Update colors
        if (selectedOption == 0) {
            classicTitle.color = FlxColor.YELLOW;
            styledTitle.color = FlxColor.CYAN;
        } else {
            classicTitle.color = FlxColor.WHITE;
            styledTitle.color = FlxColor.YELLOW;
        }

        // Play selection sound
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
    }

    function animateIn() {
        isAnimating = true;

        // Title animation
        titleText.y = -100;
        FlxTween.tween(titleText, {y: 40}, 0.8, {ease: FlxEase.backOut});

        // Subtitle fade in
        subtitleText.alpha = 0;
        FlxTween.tween(subtitleText, {alpha: 1}, 1.2, {ease: FlxEase.sineOut});

        // Options slide in from sides
        classicOption.x = -classicOption.width;
        styledOption.x = FlxG.width;

        var targetClassicX = (FlxG.width - (350 * 2 + 50)) / 2;
        var targetStyledX = targetClassicX + 350 + 50;

        FlxTween.tween(classicOption, {x: targetClassicX}, 1, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                isAnimating = false;
            }
        });
        FlxTween.tween(styledOption, {x: targetStyledX}, 1, {ease: FlxEase.backOut});

        // Animate related elements
        FlxTween.tween(classicTitle, {x: targetClassicX + 10}, 1, {ease: FlxEase.backOut});
        FlxTween.tween(classicDescription, {x: targetClassicX + 15}, 1, {ease: FlxEase.backOut});
        FlxTween.tween(classicPreview, {x: targetClassicX + 20}, 1, {ease: FlxEase.backOut});

        FlxTween.tween(styledTitle, {x: targetStyledX + 10}, 1, {ease: FlxEase.backOut});
        FlxTween.tween(styledDescription, {x: targetStyledX + 15}, 1, {ease: FlxEase.backOut});
        FlxTween.tween(styledPreview, {x: targetStyledX + 20}, 1, {ease: FlxEase.backOut});

        // Bottom elements slide up
        backButton.y = FlxG.height + 50;
        FlxTween.tween(backButton, {y: FlxG.height - 70}, 1.2, {ease: FlxEase.backOut});
        FlxTween.tween(backButtonText, {y: FlxG.height - 58}, 1.2, {ease: FlxEase.backOut});
    }

    function animateOut(onComplete:Void->Void) {
        isAnimating = true;

        // Title slides up and fades
        FlxTween.tween(titleText, {y: -100, alpha: 0}, 0.4, {ease: FlxEase.backIn});
        FlxTween.tween(subtitleText, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});

        // Options slide out to sides
        FlxTween.tween(classicOption, {x: -classicOption.width - 50}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(styledOption, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn});

        // Animate related elements
        FlxTween.tween(classicTitle, {x: -classicTitle.width - 50}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(classicDescription, {x: -classicDescription.width - 50}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(classicPreview, {x: -classicPreview.width - 50}, 0.5, {ease: FlxEase.backIn});

        FlxTween.tween(styledTitle, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(styledDescription, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(styledPreview, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn});

        // Bottom elements slide down
        FlxTween.tween(backButton, {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});
        FlxTween.tween(backButtonText, {y: FlxG.height + 62}, 0.4, {ease: FlxEase.backIn});

        // Background fade out
        FlxTween.tween(bg, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});
        FlxTween.tween(gradientOverlay, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});

        // Particles fade out
        particles.forEachAlive(function(particle:FlxSprite) {
            FlxTween.tween(particle, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
        });

        // Glow effects fade out
        glowEffects.forEachAlive(function(glow:FlxSprite) {
            FlxTween.tween(glow, {alpha: 0}, 0.2, {ease: FlxEase.sineIn});
        });

        // Call completion after longest animation
        new FlxTimer().start(0.6, function(_) {
            if (onComplete != null) onComplete();
        });
    }

    function selectOption() {
        if (isAnimating) return;

        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Save preferences if remember is checked
        if (rememberChoice) {
            savePreferences();
        }

        // Animate out all elements
        animateOut(function() {
            if (selectedOption == 0) {
                FlxG.switchState(new APEntryState());
            } else {
                FlxG.switchState(new APStyledEntryState());
            }
        });

        // Visual feedback
        var selectedOptionSprite = selectedOption == 0 ? classicOption : styledOption;
        FlxFlicker.flicker(selectedOptionSprite, 0.5, 0.1);
    }

    function toggleRememberChoice() {
        rememberChoice = !rememberChoice;
        FlxG.sound.play(Paths.sound('scrollMenu'));

        // Update checkbox visual (you'd need to track and update the checkbox sprite)
        // This is simplified - in practice you'd update the actual checkbox sprite
    }

    function goBack() {
        FlxG.sound.play(Paths.sound('cancelMenu'));

        animateOut(function() {
            FlxG.switchState(new MainMenuState());
        });
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Update navigation cooldown
        if (navigationCooldown > 0) {
            navigationCooldown -= elapsed;
        }

        if (isAnimating || subState != null) return;

        // Handle navigation
        if (navigationCooldown <= 0) {
            if (controls.UI_LEFT || FlxG.keys.justPressed.LEFT) {
                if (selectedOption > 0) {
                    selectedOption--;
                    updateSelection();
                    navigationCooldown = navigationDelay;
                }
            }

            if (controls.UI_RIGHT || FlxG.keys.justPressed.RIGHT) {
                if (selectedOption < 1) {
                    selectedOption++;
                    updateSelection();
                    navigationCooldown = navigationDelay;
                }
            }
        }

        // Handle selection
        if (controls.ACCEPT || FlxG.keys.justPressed.ENTER) {
            selectOption();
        }

        // Handle back
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            goBack();
        }

        // Handle remember choice toggle
        if (FlxG.keys.justPressed.R) {
            toggleRememberChoice();
        }

        // Handle mouse input
        handleMouseInput();

        // Color cycling for title
        var time = Date.now().getTime() / 1000;
        titleText.color = FlxColor.fromHSL((time * 30) % 360, 0.8, 0.7);
    }

    function handleMouseInput() {
        if (!FlxG.mouse.justPressed || isAnimating) return;

        // Check option selections
        if (FlxG.mouse.overlaps(classicOption)) {
            selectedOption = 0;
            updateSelection();
            selectOption();
        } else if (FlxG.mouse.overlaps(styledOption)) {
            selectedOption = 1;
            updateSelection();
            selectOption();
        }

        // Check back button
        if (FlxG.mouse.overlaps(backButton)) {
            goBack();
        }

        // Check remember choice (simplified - you'd check the actual checkbox area)
        if (FlxG.mouse.x >= FlxG.width - 270 && FlxG.mouse.x <= FlxG.width - 250 &&
            FlxG.mouse.y >= FlxG.height - 95 && FlxG.mouse.y <= FlxG.height - 75) {
            toggleRememberChoice();
        }
    }

    /**
     * Static method to check if user has a remembered choice
     * @return Int -1 if no choice remembered, 0 for classic, 1 for styled
     */
    public static function getRememberedChoice():Int {
        var save = new FlxSave();
        save.bind("APVersionSelection");

        var result = -1;
        if (save.data.rememberChoice == true && save.data.lastChoice != null) {
            result = save.data.lastChoice;
        }

        save.destroy();
        return result;
    }

    /**
     * Static method to directly launch the remembered choice or show selection
     */
    public static function smartLaunch():Void {
        var rememberedChoice = getRememberedChoice();

        if (rememberedChoice >= 0) {
            // User has a remembered choice, use it directly
            if (rememberedChoice == 0) {
                FlxG.switchState(new APEntryState());
            } else {
                FlxG.switchState(new APStyledEntryState());
            }
        } else {
            // No remembered choice, show selection
            FlxG.switchState(new APVersionSelectionState());
        }
    }

    /**
     * Static method to clear remembered choice (for settings/reset purposes)
     */
    public static function clearRememberedChoice():Void {
        var save = new FlxSave();
        save.bind("APVersionSelection");

        save.data.rememberChoice = false;
        save.data.lastChoice = null;
        save.flush();
        save.destroy();
    }
}
