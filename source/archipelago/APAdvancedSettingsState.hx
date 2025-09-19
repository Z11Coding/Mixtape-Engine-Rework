package archipelago;

import archipelago.APEntryState;
import archipelago.APInfo;
import archipelago.APVersionSelectionState;
import archipelago.CustomAPLogic;
import archipelago.substates.NumberInputSubstate;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.WeekData;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import openfl.geom.Rectangle;
import options.*;
import states.*;
import substates.Prompt;
import yaml.Renderer;
import yaml.Yaml;

using yutautil.CollectionUtils;

// Callback function type for settings options
typedef SettingsCallback = Void->Void;

// Settings option structure
typedef SettingsOption = {
    var name:String;
    var description:String;
    var callback:SettingsCallback;
    var locked:Bool;
}

// State option structure for complex settings that open other states
typedef StateOption = {
    var name:String;
    var description:String;
    var stateClass:Class<MusicBeatState>;
    var stateArgs:Array<Dynamic>;
    var allowedStates:Array<Class<MusicBeatState>>; // State classes that are allowed, preventing return to AP settings
    var variablesToCapture:Array<String>; // Variables to capture from the state when returning
    var locked:Bool;
}

// Page structure for organizing settings
typedef SettingsPage = {
    var name:String;
    var description:String;
    var options:Array<SettingsOption>;
    var stateOptions:Array<StateOption>; // Separate array for state options
    var color:FlxColor;
}

// Slider control structure
typedef SliderControl = {
    var background:FlxSprite;
    var handle:FlxSprite;
    var valueText:FlxText;
    var minValue:Float;
    var maxValue:Float;
    var currentValue:Float;
    var stepSize:Float;
    var isDragging:Bool;
    var onUpdate:Int->Void;
}

class APAdvancedSettingsState extends MusicBeatState {
    // Core visual elements
    var bg:FlxSprite;
    var gradientOverlay:FlxSprite;
    var titleText:FlxText;
    var descriptionText:FlxText;
    var pageIndicator:FlxText;
    var statsPanel:FlxSprite;
    var statsText:FlxText;

    // Navigation elements
    var leftArrow:FlxSprite;
    var rightArrow:FlxSprite;
    var closeButton:FlxSprite;
    var exportButton:FlxSprite;

    // Animation elements
    var particles:FlxTypedGroup<FlxSprite>;
    var glowEffect:FlxSprite;

    // Pages system
    var pages:Array<SettingsPage> = [];
    var currentPage:Int = 0;
    var optionButtons:FlxTypedGroup<FlxSprite>;
    var optionTexts:FlxTypedGroup<FlxText>;

    // Button data tracking (since FlxSprite doesn't have setData/getData)
    var buttonData:Map<FlxSprite, Map<String, Dynamic>> = new Map();

    // Settings storage (similar to original)
    var progression_balancing:String = "normal";
    var accessibility:String = "full";
    var unlockType:String = "Per Song";
    var unlockMethod:String = "Song Completion";
    var gradeRequirement:String = "D";
    var accRequirement:String = "60%";
    var allowMods:Bool = false;
    var includeSecrets:Bool = true;
    var includeVanilla:Bool = true;
    var startingSong:String = "Tutorial";
    var victorySong:String = "Tutorial";
    var deathlink:Bool = false;

    // Navigation cooldown
    var navigationCooldown:Float = 0;
    var navigationDelay:Float = 0.15; // 150ms delay between navigation inputs
    var ticketPercent:Int = 25;
    var ticketWinPercent:Int = 75;
    var chartmodifierchance:Int = 5;
    var trapAmount:Int = 30;
    var songLimit:Int = 50;

    // Animation state
    var isAnimating:Bool = false;
    var transitionTime:Float = 0.3;

    // Temporary save system for state navigation
    static var tempSave:FlxSave;
    static var tempSaveData:Dynamic;

    // Slider controls
    var activeSliders:Map<String, SliderControl> = new Map();
    var selectedSlider:String = null;

    override function create() {
        super.create();

        // Initialize temporary save system
        initTempSave();

        // Check if we're returning from a state navigation
        if (tempSave != null && tempSave.data.shouldReturnToAdvancedSettings == true) {
            // Clear the return flag
            tempSave.data.shouldReturnToAdvancedSettings = false;
            tempSave.flush();
            // Load from temp data instead of regular settings
            loadFromTempData();
        }

        setupBackground();
        setupPages();
        setupUI();
        setupAnimations();

        // Load current settings (skip if we already loaded from temp)
        if (tempSave == null || tempSave.data.shouldReturnToAdvancedSettings != false) {
            loadCurrentSettings();
        }

        // Animate in
        animateIn();

        // Setup particle system
        setupParticles();
    }

    function setupBackground() {
        // Dynamic gradient background
        bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0xFF1a0d2e, 0xFF16213e, 0xFF0f3460], 1, 90);
        bg.scrollFactor.set();
        add(bg);

        // Animated overlay
        gradientOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0x00000000, 0x33ff6b35, 0x00000000], 1, 0);
        gradientOverlay.scrollFactor.set();
        gradientOverlay.alpha = 0.6;
        add(gradientOverlay);

        // Animate overlay
        FlxTween.tween(gradientOverlay, {alpha: 0.8}, 2, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function setupPages() {
        // Main Settings Page
        var mainOptions:Array<SettingsOption> = [
            {
                name: "Progression Balancing",
                description: "How items are distributed: disabled, normal, or extreme",
                callback: () -> cycleProgressionBalancing(),
                locked: false
            },
            {
                name: "Accessibility",
                description: "full or minimal accessibility features",
                callback: () -> cycleAccessibility(),
                locked: false
            },
            {
                name: "Unlock Type",
                description: "Per Song or Per Week unlocking",
                callback: () -> cycleUnlockType(),
                locked: false
            },
            {
                name: "Unlock Method",
                description: "Note Checks, Song Completion, or Both",
                callback: () -> cycleUnlockMethod(),
                locked: false
            },
            {
                name: "DeathLink",
                description: "Enable/disable death synchronization",
                callback: () -> deathlink = !deathlink,
                locked: false
            }
        ];

        // Songs & Content Page
        var songsOptions:Array<SettingsOption> = [
            {
                name: "Allow Mods",
                description: "Include modded songs in the pool",
                callback: () -> { allowMods = !allowMods; updateSongStats(); },
                locked: false
            },
            {
                name: "Include Secrets",
                description: "Include secret songs in the pool",
                callback: () -> { includeSecrets = !includeSecrets; updateSongStats(); },
                locked: false
            },
            {
                name: "Include Vanilla",
                description: "Include base game songs (Base, Erect, Pico)",
                callback: () -> { includeVanilla = !includeVanilla; updateSongStats(); },
                locked: false
            },
            {
                name: "Starting Song",
                description: "Choose which song you start with",
                callback: () -> selectStartingSong(),
                locked: false
            },
            {
                name: "Victory Song",
                description: "Choose the final song for victory",
                callback: () -> selectVictorySong(),
                locked: false
            },
            {
                name: "Grade Requirement",
                description: "Minimum grade needed to complete songs",
                callback: () -> cycleGradeRequirement(),
                locked: false
            }
        ];

        // Advanced & Traps Page
        var trapsOptions:Array<SettingsOption> = [
            {
                name: "Trap Amount",
                description: "Total number of trap items (0-60)",
                callback: () -> adjustTrapAmount(),
                locked: false
            },
            {
                name: "Chart Modifier Chance",
                description: "Chance of getting chart modifiers (0-10)",
                callback: () -> adjustChartModifier(),
                locked: false
            },
            {
                name: "Ticket Percentage",
                description: "Percentage of checks that are tickets (10-50%)",
                callback: () -> adjustTicketPercent(),
                locked: false
            },
            {
                name: "Song Limit",
                description: "Maximum number of songs in your run",
                callback: () -> adjustSongLimit(),
                locked: false
            },
            {
                name: "Complex Settings",
                description: "Open advanced configuration with state data capture",
                callback: () -> openComplexSettings(),
                locked: false
            }
        ];

        // Example state options (you can add actual complex settings states here)
        var exampleStateOptions:Array<StateOption> = [
            createStateOption(
                "Song Selection",
                "Open advanced song selection interface",
                cast states.freeplay.FreeplayState, // Example: open freeplay for song selection
                [], // No constructor args
                [cast options.OptionsState, cast states.MainMenuState], // Allow navigation to these states
                ["selectedSongs", "difficulty"] // Variables to capture
            )
        ];

        pages = [
            {
                name: "MAIN SETTINGS",
                description: "Core game configuration options",
                options: mainOptions,
                stateOptions: [],
                color: FlxColor.CYAN
            },
            {
                name: "SONGS & CONTENT",
                description: "Configure which songs and content to include",
                options: songsOptions,
                stateOptions: [],
                color: FlxColor.LIME
            },
            {
                name: "ADVANCED & TRAPS",
                description: "Fine-tune difficulty and trap settings",
                options: trapsOptions,
                stateOptions: exampleStateOptions, // Add state options to this page
                color: FlxColor.ORANGE
            }
        ];
    }

    function setupUI() {
        // Title
        titleText = new FlxText(50, 30, FlxG.width - 100, "ARCHIPELAGO SETTINGS", 48);
        titleText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 3;
        add(titleText);

        // Description
        descriptionText = new FlxText(50, 90, FlxG.width - 100, "", 20);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);

        // Page indicator
        pageIndicator = new FlxText(50, FlxG.height - 140, FlxG.width - 100, "", 16);
        pageIndicator.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        pageIndicator.borderSize = 1;
        add(pageIndicator);

        // Navigation arrows
        leftArrow = new FlxSprite(30, Std.int(FlxG.height / 2) - 25);
        leftArrow.makeGraphic(50, 50, FlxColor.TRANSPARENT);
        leftArrow.loadGraphic(Paths.image("ui/arrow-left")); // You'll need arrow graphics
        if (leftArrow.pixels == null) {
            leftArrow.makeGraphic(40, 30, FlxColor.WHITE);
        }
        add(leftArrow);

        rightArrow = new FlxSprite(Std.int(FlxG.width - 80), Std.int(FlxG.height / 2) - 25);
        rightArrow.makeGraphic(50, 50, FlxColor.TRANSPARENT);
        rightArrow.loadGraphic(Paths.image("ui/arrow-right"));
        if (rightArrow.pixels == null) {
            rightArrow.makeGraphic(40, 30, FlxColor.WHITE);
        }
        add(rightArrow);

        // Bottom buttons
        exportButton = new FlxSprite(Std.int(FlxG.width / 2) - 200, Std.int(FlxG.height - 80));
        exportButton.makeGraphic(180, 50, FlxColor.GREEN);
        add(exportButton);

        var exportText = new FlxText(exportButton.x, exportButton.y + 10, exportButton.width, "EXPORT YAML", 16);
        exportText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        exportText.borderSize = 1;
        add(exportText);

        closeButton = new FlxSprite(Std.int(FlxG.width / 2) + 20, Std.int(FlxG.height - 80));
        closeButton.makeGraphic(180, 50, FlxColor.RED);
        add(closeButton);

        var closeText = new FlxText(closeButton.x, closeButton.y + 10, closeButton.width, "CLOSE", 16);
        closeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        closeText.borderSize = 1;
        add(closeText);

        // Stats panel
        setupStatsPanel();

        // Option buttons group
        optionButtons = new FlxTypedGroup<FlxSprite>();
        add(optionButtons);

        optionTexts = new FlxTypedGroup<FlxText>();
        add(optionTexts);

        // Load initial page
        loadPage(0);
    }

    function setupStatsPanel() {
        statsPanel = new FlxSprite(FlxG.width - 300, 120);
        statsPanel.makeGraphic(280, 200, FlxColor.BLACK);
        statsPanel.alpha = 0.7;
        add(statsPanel);

        statsText = new FlxText(statsPanel.x + 10, statsPanel.y + 10, 260, "", 12);
        statsText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        statsText.borderSize = 1;
        add(statsText);

        updateSongStats();
    }

    function setupAnimations() {
        // Glow effect for title
        glowEffect = new FlxSprite(titleText.x - 10, titleText.y - 10);
        glowEffect.makeGraphic(Std.int(titleText.width + 20), Std.int(titleText.height + 20), FlxColor.CYAN);
        glowEffect.alpha = 0;
        insert(members.indexOf(titleText), glowEffect);

        FlxTween.tween(glowEffect, {alpha: 0.3}, 1.5, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function setupParticles() {
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        // Create floating particles
        for (i in 0...20) {
            var particle = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
            particle.makeGraphic(3, 3, FlxColor.WHITE);
            particle.alpha = FlxG.random.float(0.1, 0.5);
            particles.add(particle);

            // Animate particles
            FlxTween.tween(particle, {y: particle.y - FlxG.random.float(100, 300)}, FlxG.random.float(5, 10), {
                type: LOOPING,
                ease: FlxEase.sineInOut,
                onComplete: function(_) {
                    particle.y = FlxG.height + 10;
                    particle.x = FlxG.random.float(0, FlxG.width);
                }
            });
        }
    }

    function loadPage(pageIndex:Int) {
        if (pageIndex < 0 || pageIndex >= pages.length) return;

        currentPage = pageIndex;
        var page = pages[currentPage];

        // Clear existing options
        optionButtons.clear();
        optionTexts.clear();

        // Update page info
        descriptionText.text = page.description;
        pageIndicator.text = '${currentPage + 1} / ${pages.length} - ${page.name}';

        // Change title color based on page
        titleText.color = page.color;
        if (glowEffect != null) {
            glowEffect.color = page.color;
        }

        // Create option buttons (both regular and state options)
        var startY:Float = 140;
        var spacing:Float = 50;
        var optionIndex = 0;

        // Add regular options
        for (i in 0...page.options.length) {
            var option = page.options[i];
            var yPos = startY + (optionIndex * spacing);

            // Create button - start off-screen for animation
            var button = new FlxSprite(FlxG.width, yPos);
            button.makeGraphic(FlxG.width - 350, 40, option.locked ? FlxColor.GRAY : FlxColor.fromRGB(40, 40, 80));
            button.ID = optionIndex;
            // Store button data using our custom system
            buttonData.set(button, ["type" => "regular", "index" => i]);
            optionButtons.add(button);

            // Create text - start off-screen for animation
            var text = new FlxText(FlxG.width + 10, yPos + 10, button.width - 20, option.name, 16);
            text.setFormat(Paths.font("vcr.ttf"), 16, option.locked ? FlxColor.GRAY : FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
            text.borderSize = 1;
            text.ID = optionIndex;
            optionTexts.add(text);

            // Add current value display
            var valueText = getCurrentValueText(option.name);
            if (valueText != "") {
                var valueDisplay = new FlxText(FlxG.width + 10, yPos + 10, 140, valueText, 14);
                valueDisplay.setFormat(Paths.font("vcr.ttf"), 14, page.color, RIGHT, OUTLINE, FlxColor.BLACK);
                valueDisplay.borderSize = 1;
                valueDisplay.ID = optionIndex + 1000; // Use different ID range for value displays
                optionTexts.add(valueDisplay);
            }
            optionIndex++;
        }

        // Add state options
        for (i in 0...page.stateOptions.length) {
            var stateOption = page.stateOptions[i];
            var yPos = startY + (optionIndex * spacing);

            // Create button (different color to distinguish state options) - start off-screen for animation
            var button = new FlxSprite(FlxG.width, yPos);
            button.makeGraphic(FlxG.width - 350, 40, stateOption.locked ? FlxColor.GRAY : FlxColor.fromRGB(60, 40, 80));
            button.ID = optionIndex;
            // Store button data using our custom system
            buttonData.set(button, ["type" => "state", "index" => i]);
            optionButtons.add(button);

            // Create text with indicator - start off-screen for animation
            var text = new FlxText(FlxG.width + 10, yPos + 10, button.width - 20, stateOption.name + " →", 16);
            text.setFormat(Paths.font("vcr.ttf"), 16, stateOption.locked ? FlxColor.GRAY : FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
            text.borderSize = 1;
            text.ID = optionIndex;
            optionTexts.add(text);

            optionIndex++;
        }

        // Animate page transition
        animatePageTransition();
    }

    function getCurrentValueText(optionName:String):String {
        return switch (optionName) {
            case "Progression Balancing": progression_balancing;
            case "Accessibility": accessibility;
            case "Unlock Type": unlockType;
            case "Unlock Method": unlockMethod;
            case "DeathLink": deathlink ? "ON" : "OFF";
            case "Allow Mods": allowMods ? "ON" : "OFF";
            case "Include Secrets": includeSecrets ? "ON" : "OFF";
            case "Include Vanilla": includeVanilla ? "ON" : "OFF";
            case "Starting Song": startingSong;
            case "Victory Song": victorySong;
            case "Grade Requirement": gradeRequirement;
            case "Trap Amount": Std.string(trapAmount);
            case "Chart Modifier Chance": Std.string(chartmodifierchance);
            case "Ticket Percentage": ticketPercent + "%";
            case "Song Limit": Std.string(songLimit);
            default: "";
        }
    }

    function animatePageTransition() {
        if (isAnimating) return;
        isAnimating = true;

        var completedAnimations = 0;
        var totalAnimations = optionButtons.members.length;

        if (totalAnimations == 0) {
            isAnimating = false;
            return;
        }

        // Animate buttons
        for (i in 0...optionButtons.members.length) {
            var button = optionButtons.members[i];

            if (button != null) {
                button.x = FlxG.width;
                FlxTween.tween(button, {x: 100}, transitionTime + (i * 0.05), {
                    ease: FlxEase.backOut,
                    onComplete: function(_) {
                        completedAnimations++;
                        if (completedAnimations == totalAnimations) {
                            isAnimating = false;
                        }
                    }
                });
            }
        }

        // Animate all text elements separately
        for (i in 0...optionTexts.members.length) {
            var text = optionTexts.members[i];

            if (text != null) {
                text.x = FlxG.width + 10;
                // Determine target X based on text content and positioning
                var targetX:Float = 110; // Default for main option text
                // If this is a value display (right-aligned text), position it accordingly
                if (text.alignment == RIGHT) {
                    targetX = 100 + (FlxG.width - 350) - 150; // Button X + Button width - value display width
                }

                FlxTween.tween(text, {x: targetX}, transitionTime + (i * 0.05), {
                    ease: FlxEase.backOut
                });
            }
        }
    }    function animateIn() {
        // Animate UI elements in
        titleText.y = -100;
        FlxTween.tween(titleText, {y: 30}, 0.8, {ease: FlxEase.backOut});

        descriptionText.alpha = 0;
        FlxTween.tween(descriptionText, {alpha: 1}, 1.2, {ease: FlxEase.sineOut});

        leftArrow.x = -100;
        rightArrow.x = FlxG.width + 100;
        FlxTween.tween(leftArrow, {x: 30}, 1, {ease: FlxEase.backOut});
        FlxTween.tween(rightArrow, {x: FlxG.width - 80}, 1, {ease: FlxEase.backOut});

        exportButton.y = FlxG.height + 50;
        closeButton.y = FlxG.height + 50;
        FlxTween.tween(exportButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut});
        FlxTween.tween(closeButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut});
    }

    // Settings adjustment functions
    function cycleProgressionBalancing() {
        var options = ["disabled", "normal", "extreme"];
        var current = options.indexOf(progression_balancing);
        progression_balancing = options[(current + 1) % options.length];
        FlxG.sound.play(Paths.sound('scrollMenu'));
        refreshCurrentPage();
    }

    function cycleAccessibility() {
        var options = ["full", "minimal"];
        var current = options.indexOf(accessibility);
        accessibility = options[(current + 1) % options.length];
        FlxG.sound.play(Paths.sound('scrollMenu'));
        refreshCurrentPage();
    }

    function cycleUnlockType() {
        var options = ["Per Song", "Per Week"];
        var current = options.indexOf(unlockType);
        unlockType = options[(current + 1) % options.length];
        FlxG.sound.play(Paths.sound('scrollMenu'));
        refreshCurrentPage();
    }

    function cycleUnlockMethod() {
        var options = ["Note Checks", "Song Completion", "Both"];
        var current = options.indexOf(unlockMethod);
        unlockMethod = options[(current + 1) % options.length];
        FlxG.sound.play(Paths.sound('scrollMenu'));
        updateSongStats();
        refreshCurrentPage();
    }

    function cycleGradeRequirement() {
        var options = APInfo.gradeList;
        var current = options.indexOf(gradeRequirement);
        gradeRequirement = options[(current + 1) % options.length];
        FlxG.sound.play(Paths.sound('scrollMenu'));
        refreshCurrentPage();
    }

    function adjustTrapAmount() {
        openSliderControl("Trap Amount", trapAmount, 0, 60, 5, function(value:Float) {
            trapAmount = Std.int(value);
            refreshCurrentPage();
        });
    }

    function adjustChartModifier() {
        openSliderControl("Chart Modifier Chance", chartmodifierchance, 0, 10, 1, function(value:Float) {
            chartmodifierchance = Std.int(value);
            refreshCurrentPage();
        });
    }

    function adjustTicketPercent() {
        openSliderControl("Ticket Percentage", ticketPercent, 10, 50, 5, function(value:Float) {
            ticketPercent = Std.int(value);
            refreshCurrentPage();
        });
    }

    function adjustSongLimit() {
        var maxSongs = calculateMaxAvailableSongs();
        openSliderControl("Song Limit", songLimit, 5, maxSongs, 5, function(value:Float) {
            songLimit = Std.int(value);
            updateSongStats();
            refreshCurrentPage();
        });
    }

    function selectStartingSong() {
        // This would open a song selection submenu
        FlxG.sound.play(Paths.sound('confirmMenu'));
        // For now, cycle through some options
        var songs = ["Tutorial", "Bopeebo", "Fresh", "Dadbattle"];
        var current = songs.indexOf(startingSong);
        startingSong = songs[(current + 1) % songs.length];
        refreshCurrentPage();
    }

    function selectVictorySong() {
        // This would open a song selection submenu
        FlxG.sound.play(Paths.sound('confirmMenu'));
        var songs = ["Tutorial", "Bopeebo", "Fresh", "Dadbattle"];
        var current = songs.indexOf(victorySong);
        victorySong = songs[(current + 1) % songs.length];
        refreshCurrentPage();
    }

    function refreshCurrentPage() {
        loadPage(currentPage);
        updateSongStats();
        saveTempData(); // Save changes
    }

    function updateSongStats() {
        // Calculate song counts and stats
        var totalSongs = 0;
        var totalChecks = 0;
        var modCount = backend.Mods.parseList().enabled.length;

        // Base game songs
        if (includeVanilla) {
            totalSongs += APInfo.baseGame.length + APInfo.baseErect.length + APInfo.basePico.length;
        }

        // Secret songs
        if (includeSecrets) {
            totalSongs += APInfo.secrets.length;
        }

        // Mod songs (approximate)
        if (allowMods) {
            totalSongs += modCount * 3; // Rough estimate
        }

        // Calculate checks based on unlock method
        switch (unlockMethod) {
            case "Song Completion":
                var calc1 = totalSongs * 2;
                var calc2 = songLimit * 2;
                totalChecks = Std.int(Math.min(calc1, calc2));
            case "Note Checks":
                var calc1 = totalSongs * 3;
                var calc2 = songLimit * 3;
                totalChecks = Std.int(Math.min(calc1, calc2));
            case "Both":
                var calc1 = totalSongs * 5;
                var calc2 = songLimit * 5;
                totalChecks = Std.int(Math.min(calc1, calc2));
            default: totalChecks = songLimit;
        }

        var statsString = "=== CURRENT STATS ===\n\n";
        statsString += "Available Songs: " + totalSongs + "\n";
        statsString += "Song Limit: " + songLimit + "\n";
        statsString += "Expected Checks: " + totalChecks + "\n";
        statsString += "Trap Items: " + trapAmount + "\n";
        statsString += "Mods Enabled: " + modCount + "\n\n";

        statsString += "Content Included:\n";
        statsString += "• Vanilla: " + (includeVanilla ? "YES" : "NO") + "\n";
        statsString += "• Secrets: " + (includeSecrets ? "YES" : "NO") + "\n";
        statsString += "• Mods: " + (allowMods ? "YES" : "NO") + "\n\n";

        statsString += "Victory Condition:\n";
        statsString += "Complete: " + victorySong + "\n";

        statsText.text = statsString;
    }

    function openComplexSettings() {
        // Example: Open a state for complex configuration and capture results
        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Create a more complex settings state (example for song selection, keybinding, etc.)
        openSubState(new Prompt(
            "Complex Settings\n\nThis would open a complex settings state.\n\nWhen closed, variables from that state would be automatically captured and used here.\n\nUseful for:\n• Song selection screens\n• Key binding configuration\n• Multi-step setup wizards\n• Color pickers\n• File selectors",
            0, // defaultSelected
            function() {
                // Simulate capturing data from closed state
                var capturedData = "Example: Selected songs [Tutorial, Bopeebo, Fresh]";
                showCaptureResult(capturedData);
            },
            null,
            false,
            'Simulate Capture',
            'Cancel'
        ));
    }

    function showCaptureResult(data:String) {
        openSubState(new Prompt("State Data Captured\n\nCaptured from closed state:\n\n" + data, 0, null, null, false));
    }

    // State option system for complex settings
    // This will be handled by MusicBeatState's tracking system

    /**
     * Creates a state option that opens another state with proper tracking
     * @param name Display name for the option
     * @param description Description of what the option does
     * @param stateClass The state class to switch to
     * @param stateArgs Arguments to pass to the state constructor
     * @param allowedStates Additional state classes that are allowed (prevents return loop)
     * @param variablesToCapture Variables to capture when returning from the state
     * @return StateOption that can be added to a page
     */
    static function createStateOption(
        name:String,
        description:String,
        stateClass:Class<MusicBeatState>,
        ?stateArgs:Array<Dynamic>,
        ?allowedStates:Array<Class<MusicBeatState>>,
        ?variablesToCapture:Array<String>
    ):StateOption {
        if (stateArgs == null) stateArgs = [];
        if (allowedStates == null) allowedStates = [];
        if (variablesToCapture == null) variablesToCapture = [];

        // Automatically add the source state (APAdvancedSettingsState) to allowed states
        allowedStates.push(APAdvancedSettingsState);

        return {
            name: name,
            description: description,
            stateClass: stateClass,
            stateArgs: stateArgs,
            allowedStates: allowedStates,
            variablesToCapture: variablesToCapture,
            locked: false
        };
    }

    /**
     * Switches to a state with AP options tracking
     * @param stateOption The state option to execute
     */
    function executeStateOption(stateOption:StateOption) {
        if (stateOption.locked) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            FlxG.camera.shake(0.01, 0.2);
            return;
        }

        // Save current state before switching
        saveTempData();

        // For now, disable the problematic MusicBeatState tracking and use a simpler approach
        // Set a flag that other states can check
        APAdvancedSettingsState.tempSave.data.shouldReturnToAdvancedSettings = true;
        APAdvancedSettingsState.tempSave.flush();

        // Create and switch to the target state
        var targetState = Type.createInstance(stateOption.stateClass, stateOption.stateArgs);
        FlxG.sound.play(Paths.sound('confirmMenu'));
        MusicBeatState.switchState(targetState);
    }

    function loadCurrentSettings() {
        // Load from APEntryState.gameSettings.FNF
        if (APEntryState.gameSettings != null && APEntryState.gameSettings.FNF != null) {
            var settings = APEntryState.gameSettings.FNF;
            progression_balancing = settings.progression_balancing;
            accessibility = settings.accessibility;
            unlockType = settings.unlock_type;
            unlockMethod = settings.unlock_method;
            gradeRequirement = settings.graderequirement;
            accRequirement = settings.accrequirement;
            deathlink = settings.deathlink;
            ticketPercent = settings.ticket_percentage;
            ticketWinPercent = settings.ticket_win_percentage;
            chartmodifierchance = settings.chart_modifier_change_chance;
            trapAmount = settings.trapAmount;
            songLimit = settings.song_limit;

            // Existing settings
            allowMods = settings.mods_enabled;

            // New settings with defaults if they don't exist
            includeSecrets = Reflect.hasField(settings, "include_secrets") ? settings.include_secrets : true;
            includeVanilla = Reflect.hasField(settings, "include_vanilla") ? settings.include_vanilla : true;
            startingSong = settings.starting_song != null ? settings.starting_song : "Tutorial";
            victorySong = settings.victory_song != null ? settings.victory_song : "Tutorial";
        }
    }

    function saveCurrentSettings() {
        // Save to APEntryState.gameSettings.FNF
        if (APEntryState.gameSettings != null && APEntryState.gameSettings.FNF != null) {
            var settings = APEntryState.gameSettings.FNF;
            settings.progression_balancing = progression_balancing;
            settings.accessibility = accessibility;
            settings.unlock_type = unlockType;
            settings.unlock_method = unlockMethod;
            settings.graderequirement = gradeRequirement;
            settings.accrequirement = accRequirement;
            settings.deathlink = deathlink;
            settings.ticket_percentage = ticketPercent;
            settings.ticket_win_percentage = ticketWinPercent;
            settings.chart_modifier_change_chance = chartmodifierchance;
            settings.trapAmount = trapAmount;
            settings.song_limit = songLimit;
            settings.mods_enabled = allowMods;

            // Save new settings
            settings.include_secrets = includeSecrets;
            settings.include_vanilla = includeVanilla;
            settings.starting_song = startingSong;
            settings.victory_song = victorySong;
        }
    }

    function exportYAML() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Save current settings
        saveCurrentSettings();

        // Show export animation
        FlxFlicker.flicker(exportButton, 0.5, 0.1);

        // Create animated dialog
        var exportDialog = new FlxText(Std.int(FlxG.width / 2) - 200, Std.int(FlxG.height / 2) - 50, 400, "EXPORTING YAML...", 24);
        exportDialog.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        exportDialog.borderSize = 2;
        exportDialog.alpha = 0;
        add(exportDialog);

        FlxTween.tween(exportDialog, {alpha: 1}, 0.3, {
            onComplete: function(_) {
                // Perform actual export (using similar logic to original)
                try {
                    performYAMLExport();

                    exportDialog.text = "EXPORT COMPLETED!";
                    exportDialog.color = FlxColor.GREEN;

                    new FlxTimer().start(1.5, function(_) {
                        FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
                            onComplete: function(_) {
                                remove(exportDialog);
                            }
                        });
                    });
                } catch (e:Dynamic) {
                    exportDialog.text = "EXPORT FAILED!";
                    exportDialog.color = FlxColor.RED;
                    trace('Export error: $e');

                    new FlxTimer().start(2, function(_) {
                        FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
                            onComplete: function(_) {
                                remove(exportDialog);
                            }
                        });
                    });
                }
            }
        });
    }

    function performYAMLExport() {
        // Use the same export logic as the original APSettingsSubState
        APSettingsSubState.generateSongList();

        var yamlThing = {};
        for (thing in Reflect.fields(APEntryState.gameSettings.FNF)) {
            Reflect.setField(yamlThing, thing, Reflect.field(APEntryState.gameSettings.FNF, thing));
        }

        // Add new settings
        Reflect.setField(yamlThing, "include_secrets", includeSecrets);
        Reflect.setField(yamlThing, "include_vanilla", includeVanilla);
        Reflect.setField(yamlThing, "starting_song", startingSong);
        Reflect.setField(yamlThing, "victory_song", victorySong);

        APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;
        FlxG.random.shuffle(APEntryState.gameSettings.FNF.songList);

        var mainSettings = {
            name: APEntryState.yamlName,
            description: APEntryState.gameSettings.description,
            game: APEntryState.gameSettings.game
        };

        var document = Yaml.render(mainSettings, Renderer.options().setFlowLevel(1));

        // Create enhanced comment with stats
        var comment = generateYAMLComment(yamlThing);

        var yamlString = "Friday Night Funkin:\n";
        for (key in Reflect.fields(yamlThing)) {
            yamlString += "  " + key + ": " + Reflect.field(yamlThing, key) + "\n";
        }

        var finalDocument = document + comment + yamlString;

        #if sys
        if (!sys.FileSystem.exists("./PlayerSettings/"))
            sys.FileSystem.createDirectory("./PlayerSettings/");

        sys.io.File.saveContent("PlayerSettings/" + APEntryState.yamlName + ".yaml", finalDocument);
        #end
    }

    function generateYAMLComment(yamlThing:Dynamic):String {
        var comment = "\n# Generated by Mixtape Engine Advanced Settings\n";
        comment += "# Export Date: " + Date.now().toString() + "\n";

        var songCount = Reflect.field(yamlThing, "songList") != null ?
            Reflect.field(yamlThing, "songList").length : 0;

        comment += "# Songs in pool: " + songCount + "\n";
        comment += "# Song limit: " + songLimit + "\n";

        var totalChecks = switch (unlockMethod) {
            case "Song Completion": songLimit * 2;
            case "Note Checks": songLimit * 3;
            case "Both": songLimit * 5;
            default: songLimit;
        }

        comment += "# Expected checks: " + totalChecks + "\n";
        comment += "# Trap items: " + trapAmount + "\n";

        comment += "# Content includes:\n";
        comment += "#   - Vanilla songs: " + (includeVanilla ? "YES" : "NO") + "\n";
        comment += "#   - Secret songs: " + (includeSecrets ? "YES" : "NO") + "\n";
        comment += "#   - Modded songs: " + (allowMods ? "YES" : "NO") + "\n";

        comment += "# Victory song: " + victorySong + "\n";
        comment += "# Starting song: " + startingSong + "\n\n";

        return comment;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Update navigation cooldown
        if (navigationCooldown > 0) {
            navigationCooldown -= elapsed;
        }

        // Don't handle input if a substate is open or a slider is active
        if (subState != null || selectedSlider != null) return;

        // Handle input with cooldown
        if (navigationCooldown <= 0) {
            if (controls.UI_LEFT || FlxG.keys.justPressed.LEFT) {
                if (currentPage > 0) {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    animatePageOut(-1, function() {
                        loadPage(currentPage - 1);
                    });
                    navigationCooldown = navigationDelay;
                }
            }

            if (controls.UI_RIGHT || FlxG.keys.justPressed.RIGHT) {
                if (currentPage < pages.length - 1) {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    animatePageOut(1, function() {
                        loadPage(currentPage + 1);
                    });
                    navigationCooldown = navigationDelay;
                }
            }
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            closeSettings();
        }

        // Handle option selection
        if (controls.ACCEPT || FlxG.keys.justPressed.ENTER) {
            handleOptionClick();
        }

        // Handle mouse clicks
        handleMouseInput();
    }

    function handleOptionClick() {
        var selectedOption = 0; // You'd implement proper selection tracking
        if (selectedOption < pages[currentPage].options.length) {
            var option = pages[currentPage].options[selectedOption];
            if (!option.locked) {
                option.callback();
            } else {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                FlxG.camera.shake(0.01, 0.2);
            }
        }
    }

    function handleMouseInput() {
        // Don't handle input if a substate is open or a slider is active
        if (subState != null || selectedSlider != null) return;

        var mousePos = FlxG.mouse.getPosition();

        // Check option button clicks
        optionButtons.forEachAlive(function(button:FlxSprite) {
            if (FlxG.mouse.overlaps(button) && FlxG.mouse.justPressed) {
                var data = buttonData.get(button);
                if (data != null) {
                    var type:String = data.get("type");
                    var index:Int = data.get("index");

                    if (type == "regular") {
                        var option = pages[currentPage].options[index];
                        if (!option.locked) {
                            option.callback();
                        } else {
                            FlxG.sound.play(Paths.sound('cancelMenu'));
                            FlxG.camera.shake(0.01, 0.2);
                        }
                    } else if (type == "state") {
                        var stateOption = pages[currentPage].stateOptions[index];
                        executeStateOption(stateOption);
                    }
                }
            }
        });

        // Check navigation arrows
        if (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justPressed && currentPage > 0 && navigationCooldown <= 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            animatePageOut(-1, function() {
                loadPage(currentPage - 1);
            });
            navigationCooldown = navigationDelay;
        }

        if (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justPressed && currentPage < pages.length - 1 && navigationCooldown <= 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            animatePageOut(1, function() {
                loadPage(currentPage + 1);
            });
            navigationCooldown = navigationDelay;
        }

        // Check bottom buttons
        if (FlxG.mouse.overlaps(exportButton) && FlxG.mouse.justPressed) {
            exportYAML();
        }

        if (FlxG.mouse.overlaps(closeButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            closeSettings();
        }
    }

    // Temporary save system for state navigation
    function initTempSave() {
        if (tempSave == null) {
            tempSave = new FlxSave();
            tempSave.bind("APAdvancedSettingsTemp");
        }
        saveTempData();
    }

    function saveTempData() {
        tempSaveData = {
            progression_balancing: progression_balancing,
            accessibility: accessibility,
            unlockType: unlockType,
            unlockMethod: unlockMethod,
            gradeRequirement: gradeRequirement,
            accRequirement: accRequirement,
            allowMods: allowMods,
            includeSecrets: includeSecrets,
            includeVanilla: includeVanilla,
            startingSong: startingSong,
            victorySong: victorySong,
            deathlink: deathlink,
            ticketPercent: ticketPercent,
            ticketWinPercent: ticketWinPercent,
            chartmodifierchance: chartmodifierchance,
            trapAmount: trapAmount,
            songLimit: songLimit
        };

        if (tempSave != null) {
            tempSave.data.settings = tempSaveData;
            tempSave.flush();
        }
    }

    function loadFromTempData() {
        if (tempSave != null && tempSave.data.settings != null) {
            var data = tempSave.data.settings;
            progression_balancing = data.progression_balancing;
            accessibility = data.accessibility;
            unlockType = data.unlockType;
            unlockMethod = data.unlockMethod;
            gradeRequirement = data.gradeRequirement;
            accRequirement = data.accRequirement;
            allowMods = data.allowMods;
            includeSecrets = data.includeSecrets;
            includeVanilla = data.includeVanilla;
            startingSong = data.startingSong;
            victorySong = data.victorySong;
            deathlink = data.deathlink;
            ticketPercent = data.ticketPercent;
            ticketWinPercent = data.ticketWinPercent;
            chartmodifierchance = data.chartmodifierchance;
            trapAmount = data.trapAmount;
            songLimit = data.songLimit;
        }
    }

    // Page transition animations
    function animatePageOut(direction:Int, onComplete:Void->Void) {
        if (isAnimating) return;
        isAnimating = true;

        var targetX = direction > 0 ? -FlxG.width : FlxG.width;
        var completedAnimations = 0;
        var totalAnimations = optionButtons.members.length;

        if (totalAnimations == 0) {
            isAnimating = false;
            onComplete();
            return;
        }

        for (i in 0...optionButtons.members.length) {
            var button = optionButtons.members[i];
            var text = optionTexts.members[i];

            if (button != null) {
                FlxTween.tween(button, {x: targetX}, transitionTime * 0.5, {
                    ease: FlxEase.backIn,
                    onComplete: function(_) {
                        completedAnimations++;
                        if (completedAnimations == totalAnimations) {
                            isAnimating = false; // Reset before calling onComplete
                            onComplete();
                        }
                    }
                });
            }

            if (text != null) {
                FlxTween.tween(text, {x: targetX + 10}, transitionTime * 0.5, {
                    ease: FlxEase.backIn
                });
            }
        }
    }

    // Slider control system
    function openSliderControl(name:String, currentValue:Float, minValue:Float, maxValue:Float, stepSize:Float, onUpdate:Float->Void) {
        var sliderBg = new FlxSprite(0, 0);
        sliderBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 120));
        add(sliderBg);

        var panel = new FlxSprite(Std.int(FlxG.width / 2) - 300, Std.int(FlxG.height / 2) - 100);
        panel.makeGraphic(600, 200, FlxColor.fromRGB(20, 20, 40));
        add(panel);

        var titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, name, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Slider track
        var sliderTrack = new FlxSprite(panel.x + 50, panel.y + 80);
        sliderTrack.makeGraphic(Std.int(panel.width - 100), 10, FlxColor.GRAY);
        add(sliderTrack);

        // Slider handle
        var sliderHandle = new FlxSprite(0, sliderTrack.y - 10);
        sliderHandle.makeGraphic(20, 30, FlxColor.WHITE);
        add(sliderHandle);

        // Value text
        var valueText = new FlxText(panel.x + 20, panel.y + 120, panel.width - 40, "", 20);
        valueText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        valueText.borderSize = 1;
        add(valueText);

        // Update slider position and value
        var updateSlider = function(value:Float) {
            var normalizedValue = (value - minValue) / (maxValue - minValue);
            sliderHandle.x = sliderTrack.x + (normalizedValue * (sliderTrack.width - sliderHandle.width));
            valueText.text = Std.string(Std.int(value));
        };

        updateSlider(currentValue);

        // Input text button
        var inputButton = new FlxSprite(panel.x + 50, panel.y + 150);
        inputButton.makeGraphic(100, 30, FlxColor.GREEN);
        add(inputButton);

        var inputButtonText = new FlxText(inputButton.x, inputButton.y + 5, inputButton.width, "TYPE VALUE", 12);
        inputButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        inputButtonText.borderSize = 1;
        add(inputButtonText);

        // Close button
        var closeButton = new FlxSprite(panel.x + panel.width - 150, panel.y + 150);
        closeButton.makeGraphic(100, 30, FlxColor.RED);
        add(closeButton);

        var closeButtonText = new FlxText(closeButton.x, closeButton.y + 5, closeButton.width, "CLOSE", 12);
        closeButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        closeButtonText.borderSize = 1;
        add(closeButtonText);

        var isDragging = false;
        var currentVal = currentValue;

        // Update function
        var updateFunc = function(elapsed:Float) {
            if (FlxG.mouse.pressed && FlxG.mouse.overlaps(sliderTrack)) {
                isDragging = true;
            }

            if (isDragging && FlxG.mouse.pressed) {
                var mouseX = FlxG.mouse.x;
                var relativeX = mouseX - sliderTrack.x;
                var normalizedX = Math.max(0, Math.min(1, relativeX / sliderTrack.width));
                currentVal = minValue + (normalizedX * (maxValue - minValue));
                currentVal = Math.round(currentVal / stepSize) * stepSize;
                updateSlider(currentVal);
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
            }

            if (!FlxG.mouse.pressed) {
                isDragging = false;
            }

            // Button clicks
            if (FlxG.mouse.overlaps(inputButton) && FlxG.mouse.justPressed) {
                openSubState(new NumberInputSubstate(
                    name,
                    currentVal,
                    minValue,
                    maxValue,
                    function(newValue:Float) {
                        currentVal = newValue;
                        updateSlider(currentVal);
                    },
                    null, // no cancel callback needed
                    stepSize, // use the provided step size
                    stepSize != Std.int(stepSize), // allow decimals if step size is not integer
                    'Enter a value between $minValue and $maxValue',
                    pages[currentPage].color, // use current page theme color
                    true // show number pad
                ));
            }

            if (FlxG.mouse.overlaps(closeButton) && FlxG.mouse.justPressed) {
                onUpdate(currentVal);
                FlxG.sound.play(Paths.sound('confirmMenu'));

                // Remove all slider elements
                remove(sliderBg);
                remove(panel);
                remove(titleText);
                remove(sliderTrack);
                remove(sliderHandle);
                remove(valueText);
                remove(inputButton);
                remove(inputButtonText);
                remove(closeButton);
                remove(closeButtonText);
            }
        };

        // Add update function to a temporary timer
        new FlxTimer().start(0.01, function(timer:FlxTimer) {
            if (members.indexOf(sliderBg) != -1) {
                updateFunc(timer.timeLeft);
                timer.reset();
            }
        }, 0);
    }

    function openValueInput(name:String, currentValue:Float, minValue:Float, maxValue:Float, onUpdate:Float->Void) {
        openSubState(new NumberInputSubstate(
            name,
            currentValue,
            minValue,
            maxValue,
            onUpdate,
            null, // no cancel callback needed
            1, // step size
            false, // no decimals for most AP settings
            'Enter a value between $minValue and $maxValue',
            pages[currentPage].color, // use current page theme color
            true // show number pad
        ));
    }

    function calculateMaxAvailableSongs():Int {
        var total = 0;
        if (includeVanilla) {
            total += APInfo.baseGame.length + APInfo.baseErect.length + APInfo.basePico.length;
        }
        if (includeSecrets) {
            total += APInfo.secrets.length;
        }
        if (allowMods) {
            total += backend.Mods.parseList().enabled.length * 3;
        }
        return Std.int(Math.max(5, total));
    }

    public static function restoreFromTemp():APAdvancedSettingsState {
        var state = new APAdvancedSettingsState();
        if (tempSave != null && tempSave.data.settings != null) {
            var data = tempSave.data.settings;
            state.progression_balancing = data.progression_balancing;
            state.accessibility = data.accessibility;
            state.unlockType = data.unlockType;
            state.unlockMethod = data.unlockMethod;
            state.gradeRequirement = data.gradeRequirement;
            state.accRequirement = data.accRequirement;
            state.allowMods = data.allowMods;
            state.includeSecrets = data.includeSecrets;
            state.includeVanilla = data.includeVanilla;
            state.startingSong = data.startingSong;
            state.victorySong = data.victorySong;
            state.deathlink = data.deathlink;
            state.ticketPercent = data.ticketPercent;
            state.ticketWinPercent = data.ticketWinPercent;
            state.chartmodifierchance = data.chartmodifierchance;
            state.trapAmount = data.trapAmount;
            state.songLimit = data.songLimit;
        }
        return state;
    }

    public static function returnToAdvancedSettings() {
        if (tempSave != null) {
            tempSave.data.shouldReturnToAdvancedSettings = true;
            tempSave.flush();
        }
        MusicBeatState.switchState(new APAdvancedSettingsState());
    }

    function closeSettings() {
        saveCurrentSettings();

        // Clean up temporary save
        if (tempSave != null) {
            tempSave.data.shouldReturnToAdvancedSettings = false;
            tempSave.data.settings = null;
            tempSave.flush();
        }

        // Clear AP tracking
        MusicBeatState.clearAPOptionsTracking();

        // Animate out all elements
        animateOut(function() {
            archipelago.APVersionSelectionState.smartLaunch();
        });
    }

    function animateOut(onComplete:Void->Void) {
        // Title and description slide up and fade
        FlxTween.tween(titleText, {y: titleText.y - 100, alpha: 0}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(descriptionText, {y: descriptionText.y - 100, alpha: 0}, 0.4, {ease: FlxEase.backIn});
        FlxTween.tween(pageIndicator, {y: pageIndicator.y - 80, alpha: 0}, 0.4, {ease: FlxEase.backIn});

        // Navigation arrows fade out
        FlxTween.tween(leftArrow, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
        FlxTween.tween(rightArrow, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});

        // Option buttons slide down and fade
        optionButtons.forEachAlive(function(button:FlxSprite) {
            FlxTween.tween(button, {y: button.y + 50, alpha: 0}, FlxG.random.float(0.3, 0.6), {ease: FlxEase.backIn});
        });

        optionTexts.forEachAlive(function(text:FlxText) {
            FlxTween.tween(text, {y: text.y + 50, alpha: 0}, FlxG.random.float(0.3, 0.6), {ease: FlxEase.backIn});
        });

        // Stats panel slides out
        if (statsPanel != null) {
            FlxTween.tween(statsPanel, {x: FlxG.width + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});
        }
        if (statsText != null) {
            FlxTween.tween(statsText, {x: FlxG.width + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});
        }

        // Close button slides down
        FlxTween.tween(closeButton, {y: FlxG.height + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});
        FlxTween.tween(exportButton, {y: FlxG.height + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});

        // Background fade
        FlxTween.tween(bg, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});
        FlxTween.tween(gradientOverlay, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});

        // Particles fade out
        if (particles != null) {
            particles.forEachAlive(function(particle:FlxSprite) {
                FlxTween.tween(particle, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
            });
        }

        // Glow effect fade out
        if (glowEffect != null) {
            FlxTween.tween(glowEffect, {alpha: 0}, 0.2, {ease: FlxEase.sineIn});
        }

        // Call completion after longest animation
        new FlxTimer().start(0.6, function(_) {
            if (onComplete != null) onComplete();
        });
    }
}
