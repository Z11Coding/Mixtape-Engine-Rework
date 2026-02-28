package backend;

#if ARCHIPELAGO_ALLOWED
import archipelago.APEntryState;
#end

import backend.ui.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.AttachedSprite;
import objects.CheckboxThingie;
import objects.Note;
import options.GameplayChangersSubstate.GameplayOption;
import options.Option.OptionType;
import psychlua.LegacyFunkinLua;

/**
 * Universal gameplay options loader that creates GameplayOption objects
 * and can convert them to either substates elements or PsychUI elements
 */
class GameplayOptionsLoader {
    public static var instance:GameplayOptionsLoader;

    // Categories of options
    public static var ASSIST_CATEGORY = "Assist";
    public static var MODIFIERS_CATEGORY = "Modifiers";
    public static var ADVANCED_CATEGORY = "Advanced";

    // Store all options by category
    public var optionsByCategory:Map<String, Array<GameplayOption>> = new Map();

    public function new() {
        instance = this;
        initializeAllOptions();
    }

    /**
     * Initialize all gameplay options and organize by category
     */
    private function initializeAllOptions():Void {
        trace("GameplayOptionsLoader: initializeAllOptions() called");
        optionsByCategory.clear(); // Clear any existing options
        optionsByCategory.set(ASSIST_CATEGORY, createAssistOptions());
        optionsByCategory.set(MODIFIERS_CATEGORY, createModifierOptions());
        optionsByCategory.set(ADVANCED_CATEGORY, createAdvancedOptions());
        trace("GameplayOptionsLoader: initialized categories: " + [for (cat in optionsByCategory.keys()) cat + "(" + optionsByCategory.get(cat).length + " options)"]);
    }

    /**
     * Get all options for a specific category
     */
    public function getOptionsForCategory(category:String):Array<GameplayOption> {
        return optionsByCategory.get(category) ?? [];
    }

    /**
     * Create PsychUI elements for a category with pagination support
     */
    public function createPsychUIForCategory(category:String, container:FlxSpriteGroup, page:Int = 0, itemsPerPage:Int = 8):Int {
        var options = getOptionsForCategory(category);
        trace('=== GAMEPLAYOPTIONSLOADER DEBUG ===');
        trace('GameplayOptionsLoader: Creating UI for category $category, found ${options.length} options');
        trace('GameplayOptionsLoader: Received page parameter: $page (type: ${Type.getClassName(Type.getClass(page))})');

        var startIndex = page * itemsPerPage;
        var endIndex = Std.int(Math.min(startIndex + itemsPerPage, options.length));
        trace('GameplayOptionsLoader: Page $page, showing options $startIndex to $endIndex (startIndex=$startIndex, endIndex=$endIndex)');

        var yPos = 10.0;
        var spacing = 35.0;

        var dropdowns:Array<FlxSprite> = []; // Store dropdowns to add them last

        for (i in startIndex...endIndex) {
            var option = options[i];
            trace('GameplayOptionsLoader: Creating element for option: ${option.name} (${option.getVariable()})');
            var element = createPsychUIElement(option, 10, yPos);
            if (element != null) {
                trace('GameplayOptionsLoader: Element created successfully, adding to container');

                // Check if this element contains a dropdown (STRING type)
                if (option.type == STRING) {
                    dropdowns.push(element);
                } else {
                    container.add(element);
                }
                yPos += spacing;
            } else {
                trace('GameplayOptionsLoader: WARNING - Element creation returned null for ${option.name}');
            }
        }

        // Add dropdowns last so they render on top
        for (dropdown in dropdowns) {
            container.add(dropdown);
        }

        // Return total number of pages
        var totalPages = Math.ceil(options.length / itemsPerPage);
        trace('GameplayOptionsLoader: Total pages for $category: $totalPages');
        return totalPages;
    }

    /**
     * Create GameplayOption objects for substate use
     */
    public function createGameplayOptionsForCategory(category:String):Array<GameplayOption> {
        return getOptionsForCategory(category);
    }

    private function createAssistOptions():Array<GameplayOption> {
        var options = [];

        // Only include options that actually exist in gameplaySettings
        options.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
        options.push(new GameplayOption('Botplay', 'botplay', BOOL, false));
        options.push(new GameplayOption('Opponent Mode', 'opponentplay', BOOL, false));
        options.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false));
        options.push(new GameplayOption('GF Mode', 'gfMode', BOOL, false));
        options.push(new GameplayOption('Mix-Up Mode', 'mixMode', BOOL, false));

        var aiDifficulty = new GameplayOption('Opponent Difficulty', 'oppDifficulty', INT, 1);
        aiDifficulty.scrollSpeed = 20;
        aiDifficulty.minValue = 0;
        aiDifficulty.maxValue = 6;
        options.push(aiDifficulty);

        return options;
    }

    private function createModifierOptions():Array<GameplayOption> {
        var options = [];

        // Scroll options
        options.push(new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ["multiplicative", "constant"]));

        var scrollSpeed = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1.0);
        scrollSpeed.scrollSpeed = 2.0;
        scrollSpeed.minValue = 0.35;
        scrollSpeed.maxValue = 4.0;
        scrollSpeed.changeValue = 0.05;
        scrollSpeed.decimals = 2;
        options.push(scrollSpeed);

        // Health modifiers
        var healthGain = new GameplayOption('Health Gain', 'healthgain', FLOAT, 1.0);
        healthGain.minValue = 0.0;
        healthGain.maxValue = 5.0;
        healthGain.changeValue = 0.1;
        healthGain.decimals = 1;
        options.push(healthGain);

        var healthLoss = new GameplayOption('Health Loss', 'healthloss', FLOAT, 1.0);
        healthLoss.minValue = 0.0;
        healthLoss.maxValue = 5.0;
        healthLoss.changeValue = 0.1;
        healthLoss.decimals = 1;
        options.push(healthLoss);

        return options;
    }

    private function createAdvancedOptions():Array<GameplayOption> {
        var options = [];

        #if FLX_PITCH
        var songSpeed = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1.0);
        songSpeed.scrollSpeed = 1;
        songSpeed.minValue = 0.5;
        songSpeed.maxValue = 20.0;
        songSpeed.changeValue = 0.05;
        songSpeed.displayFormat = '%vX';
        songSpeed.decimals = 2;
        options.push(songSpeed);

        var randomSpeed = new GameplayOption('Random Playback Rate', 'randomspeedchange', BOOL, false);
        options.push(randomSpeed);
        #end

        #if ARCHIPELAGO_ALLOWED
        // Mixtape-specific options
        if (!APEntryState.inArchipelagoMode) {
            var chartModifier = new GameplayOption('Chart Modifier', 'chartModifier', STRING, 'Normal',
                ["Normal", "Random", "RandomBasic", "RandomComplex", 'Flip', "4K Only", "ManiaConverter", "Stairs", "Wave", "Trills", "Amalgam"]);
            options.push(chartModifier);

            var convertMania = new GameplayOption('Convert Mania', 'convertMania', INT, 3);
            convertMania.scrollSpeed = 2.5;
            convertMania.minValue = Note.minMania;
            convertMania.maxValue = Note.maxMania;
            options.push(convertMania);
        }
        #end

        var showcase = new GameplayOption('Showcase Mode', 'showcase', BOOL, false);
        options.push(showcase);

        var maniaMode = new GameplayOption('Mania Mode', 'maniaMode', BOOL, false);
        options.push(maniaMode);

        var bothMode = new GameplayOption('Play Both Sides', 'bothMode', BOOL, false);
        options.push(bothMode);

        var loopMode = new GameplayOption('Loop Mode', 'loopMode', BOOL, false);
        options.push(loopMode);

        var loopModeC = new GameplayOption('Loop Challenge Mode', 'loopModeC', BOOL, false);
        options.push(loopModeC);

        var loopMult = new GameplayOption('Challenge Mode Mult.', 'loopPlayMult', FLOAT, 1.05);
        loopMult.scrollSpeed = 1;
        loopMult.minValue = 1.05;
        loopMult.maxValue = 2;
        loopMult.changeValue = 0.05;
        loopMult.displayFormat = '%vX';
        loopMult.decimals = 2;
        options.push(loopMult);

        var legacyMode = new GameplayOption('Legacy Psych Mode', 'legacyMode', BOOL, false);
        options.push(legacyMode);

        var legacyType = new GameplayOption('Legacy Emulated Version', 'legacyType', STRING, '0.6.3',
            LegacyFunkinLua.emulatableVersions.concat(["None"]));
        options.push(legacyType);

        return options;
    }

    /**
     * Create appropriate PsychUI element based on GameplayOption type
     */
    private function createPsychUIElement(option:GameplayOption, x:Float, y:Float):FlxSprite {
        var currentValue = option.getValue();

        switch (option.type) {
            case BOOL:
                // Checkbox already has built-in label
                var checkbox = new PsychUICheckBox(Std.int(x), Std.int(y), option.name, 100, null);
                checkbox.onClick = function() {
                    option.setValue(checkbox.checked);
                    ClientPrefs.saveSettings();
                };
                checkbox.checked = currentValue;
                return checkbox;

            case FLOAT | INT | PERCENT:
                // Create a group with label and stepper
                var group = new FlxSpriteGroup(x, y);

                // Add label
                var label = new PsychUILabel(0, 0, option.name, 120);
                group.add(label);

                var step:Float = (option.type == INT ? 1 : 0.1);
                if (option.changeValue != null) step = option.changeValue;
                var decimals:Int = (option.type == INT ? 0 : 1);
                if (option.decimals > 0) decimals = option.decimals;

                var minVal:Float = -999;
                var maxVal:Float = 999;
                if (option.minValue != null) minVal = option.minValue;
                if (option.maxValue != null) maxVal = option.maxValue;

                var stepper = new PsychUINumericStepper(130, 0, step, currentValue, minVal, maxVal, decimals);
                stepper.onValueChange = function() {
                    option.setValue(stepper.value);
                    ClientPrefs.saveSettings();
                };
                group.add(stepper);
                return group;

            case STRING:
                if (option.options != null && option.options.length > 0) {
                    // Create a group with label and dropdown
                    var group = new FlxSpriteGroup(x, y);

                    // Add label
                    var label = new PsychUILabel(0, 0, option.name, 120);
                    group.add(label);

                    var currentIndex = option.options.indexOf(Std.string(currentValue));
                    if (currentIndex == -1) currentIndex = 0;

                    var dropdown = new PsychUIDropDownMenu(130, 0, option.options, function(index:Int, label:String) {
                        if (index >= 0 && index < option.options.length) {
                            option.setValue(option.options[index]);
                            ClientPrefs.saveSettings();
                        }
                    });
                    dropdown.selectedIndex = currentIndex;
                    group.add(dropdown);

                    return group;
                }

            case KEYBIND:
                // Keybind UI already includes the label
                var keybindUI = new PsychUIKeybind(Std.int(x), Std.int(y), option.name, option.getVariable());
                keybindUI.onKeybindChange = function(newKey:String) {
                    ClientPrefs.saveSettings();
                };
                return keybindUI;

            case LABEL:
                // Create a text label (non-interactive)
                var label = new PsychUILabel(Std.int(x), Std.int(y), option.name);
                return label;
        }

        return null;
    }

    /**
     * Get all options for use in GameplayChangersSubstate
     * This replaces the hardcoded getOptions() method
     */
    public function getAllOptionsForSubstate():Array<GameplayOption> {
        var allOptions = [];

        // Add all categories
        allOptions = allOptions.concat(getOptionsForCategory(ASSIST_CATEGORY));
        allOptions = allOptions.concat(getOptionsForCategory(MODIFIERS_CATEGORY));
        allOptions = allOptions.concat(getOptionsForCategory(ADVANCED_CATEGORY));

        return allOptions;
    }
}
