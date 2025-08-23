package games.uno;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import backend.MusicBeatSubstate;
import backend.ClientPrefs;
import backend.ui.*;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoRules;
import objects.Alphabet;
import yutautil.save.MixSaveWrapper;
import yutautil.save.MixSave;

/**
 * UNO Options SubState - A comprehensive options menu for UNO gameplay
 * Provides tabs for different categories of options like colors, rules, etc.
 */
class UnoOptionsSubState extends MusicBeatSubstate
{
    // UI Elements
    private var bg:FlxSprite;
    private var titleText:FlxText;
    private var optionsBox:PsychUIBox;
    
    // Option categories and their data
    private var customColors:Array<UnoColor> = [];
    
    // Save system
    private var saveWrapper:MixSaveWrapper;
    private static inline var SAVE_PATH:String = "uno_options";
    
    // Color management UI
    private var colorGroup:FlxTypedGroup<FlxSprite>;
    private var colorPickers:Array<PsychUIColorPicker> = [];
    private var addColorButton:PsychUIButton;
    private var removeColorButton:PsychUIButton;
    
    // Rules UI
    private var stackingCheckbox:PsychUICheckBox;
    private var jumpInCheckbox:PsychUICheckBox;
    private var sevenZeroCheckbox:PsychUICheckBox;
    private var forcePlayCheckbox:PsychUICheckBox;
    private var wildChallengeCheckbox:PsychUICheckBox;
    private var scoreLimitStepper:PsychUINumericStepper;
    
    // Callbacks
    public var onColorsChanged:Array<UnoColor>->Void;
    public var onRulesChanged:Void->Void;
    
    override function create()
    {
        super.create();
        
        // Initialize save system
        initializeSaveSystem();
        
        // Initialize default values from save system
        loadCurrentSettings();
        
        setupBackground();
        setupUI();
        setupTabs();
        
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }
    
    private function initializeSaveSystem():Void
    {
        saveWrapper = new MixSaveWrapper(null, SAVE_PATH);
        
        // Since FuncEmbed doesn't work properly with MixSave yet, 
        // we'll handle the custom colors manually in the save/load functions
        
        // Load existing data
        saveWrapper.load();
    }
    
    private function loadCurrentSettings():Void
    {
        // Load custom UNO colors from MixSaveWrapper
        // Since FuncEmbed doesn't work properly, we'll handle colors manually
        var savedColorsJson = saveWrapper.getItem("customColors");
        if (savedColorsJson != null)
        {
            try {
                var colorData:Array<Dynamic> = haxe.Json.parse(savedColorsJson);
                customColors = [];
                for (item in colorData) {
                    customColors.push(UnoColor.CUSTOM(FlxColor.fromInt(item.color), item.name));
                }
            } catch (e:Dynamic) {
                trace("Error loading custom colors: " + e);
                // Fall back to defaults
                customColors = [
                    UnoColor.CUSTOM(FlxColor.PURPLE, "Purple"),
                    UnoColor.CUSTOM(FlxColor.PINK, "Pink"),
                    UnoColor.CUSTOM(FlxColor.ORANGE, "Orange"),
                    UnoColor.CUSTOM(FlxColor.CYAN, "Cyan")
                ];
            }
        }
        else
        {
            // Initialize with default custom colors if none exist
            customColors = [
                UnoColor.CUSTOM(FlxColor.PURPLE, "Purple"),
                UnoColor.CUSTOM(FlxColor.PINK, "Pink"),
                UnoColor.CUSTOM(FlxColor.ORANGE, "Orange"),
                UnoColor.CUSTOM(FlxColor.CYAN, "Cyan")
            ];
        }
        
        // Load UNO rules from MixSaveWrapper or use current UnoRules values
        var allowStacking = saveWrapper.getItem("allowStacking");
        if (allowStacking != null) UnoRules.ALLOW_STACKING = allowStacking;
        
        var allowJumpIn = saveWrapper.getItem("allowJumpIn");
        if (allowJumpIn != null) UnoRules.ALLOW_JUMP_IN = allowJumpIn;
        
        var sevenZeroRule = saveWrapper.getItem("sevenZeroRule");
        if (sevenZeroRule != null) UnoRules.SEVEN_ZERO_RULE = sevenZeroRule;
        
        var forcePlay = saveWrapper.getItem("forcePlay");
        if (forcePlay != null) UnoRules.FORCE_PLAY = forcePlay;
        
        var wildChallenge = saveWrapper.getItem("wildChallenge");
        if (wildChallenge != null) UnoRules.WILD_DRAW_FOUR_CHALLENGE = wildChallenge;
        
        var winningScore = saveWrapper.getItem("winningScore");
        if (winningScore != null) UnoRules.WINNING_SCORE = winningScore;
    }
    
    private function setupBackground():Void
    {
        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.6));
        add(bg);
        
        titleText = new FlxText(0, 50, FlxG.width, "UNO Game Options", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);
    }
    
    private function setupUI():Void
    {
        colorGroup = new FlxTypedGroup<FlxSprite>();
        add(colorGroup);
        
        // Create main options box with tabs
        optionsBox = new PsychUIBox(FlxG.width * 0.5 - 400, 120, 800, 450, ['Colors', 'Rules', 'Gameplay', 'Advanced']);
        optionsBox.selectedName = 'Colors';
        add(optionsBox);
    }
    
    private function setupTabs():Void
    {
        setupColorsTab();
        setupRulesTab();
        setupGameplayTab();
        setupAdvancedTab();
    }
    
    private function setupColorsTab():Void
    {
        var tab = optionsBox.getTab('Colors').menu;
        var yPos = 20;
        
        // Title
        var colorsTitle = new FlxText(20, yPos, 760, "Custom Colors", 18);
        colorsTitle.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
        tab.add(colorsTitle);
        yPos += 35;
        
        // Description
        var colorsDesc = new FlxText(20, yPos, 760, "Add unlimited custom colors to your UNO deck. You can also import from the standard 4-key note colors as a starting point.", 12);
        colorsDesc.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, LEFT);
        tab.add(colorsDesc);
        yPos += 30;
        
        // Option to import from note colors
        var importNoteColorsButton = new PsychUIButton(20, yPos, "Import 4-Key Colors", function() {
            importFromNoteColors();
        }, 160, 25);
        tab.add(importNoteColorsButton);
        yPos += 35;
        
        // Color pickers area (temporarily disabled due to type issues)
        // refreshColorPickers(tab);
        
        // Placeholder text
        var placeholderText = new FlxText(20, yPos + 10, 700, "Color picker functionality coming soon!", 16);
        placeholderText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT);
        tab.add(placeholderText);
        
        // Add/Remove buttons
        addColorButton = new PsychUIButton(20, 350, "Add Color", function() {
            addNewColor();
        }, 120, 30);
        tab.add(addColorButton);
        
        removeColorButton = new PsychUIButton(160, 350, "Remove Last", function() {
            removeLastColor();
        }, 120, 30);
        tab.add(removeColorButton);
        
        // Reset to defaults button
        var resetColorsButton = new PsychUIButton(300, 350, "Reset to Default", function() {
            resetToDefaultColors();
        }, 140, 30);
        tab.add(resetColorsButton);
    }
    
    private function setupRulesTab():Void
    {
        var tab = optionsBox.getTab('Rules').menu;
        var yPos = 20;
        
        // Title
        var rulesTitle = new FlxText(20, yPos, 760, "Game Rules", 18);
        rulesTitle.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
        tab.add(rulesTitle);
        yPos += 40;
        
        // Stacking rule
        stackingCheckbox = new PsychUICheckBox(20, yPos, 'Allow Card Stacking', 200);
        stackingCheckbox.checked = UnoRules.ALLOW_STACKING;
        stackingCheckbox.onClick = function() {
            UnoRules.ALLOW_STACKING = stackingCheckbox.checked;
            saveRulesSettings();
        };
        tab.add(stackingCheckbox);
        
        var stackingDesc = new FlxText(240, yPos + 5, 520, "Allows stacking draw cards (+2 on +2, +4 on +4)", 10);
        stackingDesc.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, LEFT);
        tab.add(stackingDesc);
        yPos += 50;
        
        // Jump-in rule
        jumpInCheckbox = new PsychUICheckBox(20, yPos, 'Allow Jump-In', 200);
        jumpInCheckbox.checked = UnoRules.ALLOW_JUMP_IN;
        jumpInCheckbox.onClick = function() {
            UnoRules.ALLOW_JUMP_IN = jumpInCheckbox.checked;
            saveRulesSettings();
        };
        tab.add(jumpInCheckbox);
        
        var jumpInDesc = new FlxText(240, yPos + 5, 520, "Allows players to play out of turn if they have an identical card", 10);
        jumpInDesc.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, LEFT);
        tab.add(jumpInDesc);
        yPos += 50;
        
        // Seven-Zero rule
        sevenZeroCheckbox = new PsychUICheckBox(20, yPos, 'Seven-Zero Rule', 200);
        sevenZeroCheckbox.checked = UnoRules.SEVEN_ZERO_RULE;
        sevenZeroCheckbox.onClick = function() {
            UnoRules.SEVEN_ZERO_RULE = sevenZeroCheckbox.checked;
            saveRulesSettings();
        };
        tab.add(sevenZeroCheckbox);
        
        var sevenZeroDesc = new FlxText(240, yPos + 5, 520, "Playing a 7 swaps hands with another player, playing a 0 rotates all hands", 10);
        sevenZeroDesc.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, LEFT);
        tab.add(sevenZeroDesc);
        yPos += 50;
        
        // Force play rule
        forcePlayCheckbox = new PsychUICheckBox(20, yPos, 'Force Play', 200);
        forcePlayCheckbox.checked = UnoRules.FORCE_PLAY;
        forcePlayCheckbox.onClick = function() {
            UnoRules.FORCE_PLAY = forcePlayCheckbox.checked;
            saveRulesSettings();
        };
        tab.add(forcePlayCheckbox);
        
        var forcePlayDesc = new FlxText(240, yPos + 5, 520, "Players must play a card if they have a playable one", 10);
        forcePlayDesc.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, LEFT);
        tab.add(forcePlayDesc);
        yPos += 50;
        
        // Wild Draw Four Challenge rule
        wildChallengeCheckbox = new PsychUICheckBox(20, yPos, 'Wild +4 Challenge', 200);
        wildChallengeCheckbox.checked = UnoRules.WILD_DRAW_FOUR_CHALLENGE;
        wildChallengeCheckbox.onClick = function() {
            UnoRules.WILD_DRAW_FOUR_CHALLENGE = wildChallengeCheckbox.checked;
            saveRulesSettings();
        };
        tab.add(wildChallengeCheckbox);
        
        var wildChallengeDesc = new FlxText(240, yPos + 5, 520, "Allow challenging Wild Draw Four cards", 10);
        wildChallengeDesc.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, LEFT);
        tab.add(wildChallengeDesc);
    }
    
    private function setupGameplayTab():Void
    {
        var tab = optionsBox.getTab('Gameplay').menu;
        var yPos = 20;
        
        // Title
        var gameplayTitle = new FlxText(20, yPos, 760, "Gameplay Settings", 18);
        gameplayTitle.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
        tab.add(gameplayTitle);
        yPos += 40;
        
        // Score limit
        var scoreLimitLabel = new FlxText(20, yPos, 200, "Winning Score:", 14);
        scoreLimitLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
        tab.add(scoreLimitLabel);
        
        scoreLimitStepper = new PsychUINumericStepper(240, yPos - 5, 50, UnoRules.WINNING_SCORE, 100, 2000);
        scoreLimitStepper.onValueChange = function() {
            UnoRules.WINNING_SCORE = Std.int(scoreLimitStepper.value);
            saveRulesSettings();
        };
        tab.add(scoreLimitStepper);
        
        var scoreLimitDesc = new FlxText(400, yPos + 5, 360, "Points needed to win the entire game", 10);
        scoreLimitDesc.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.GRAY, LEFT);
        tab.add(scoreLimitDesc);
    }
    
    private function setupAdvancedTab():Void
    {
        var tab = optionsBox.getTab('Advanced').menu;
        var yPos = 20;
        
        // Title
        var advancedTitle = new FlxText(20, yPos, 760, "Advanced Settings", 18);
        advancedTitle.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
        tab.add(advancedTitle);
        yPos += 40;
        
        // Export/Import settings
        var exportButton = new PsychUIButton(20, yPos, "Export Settings", function() {
            exportSettings();
        }, 150, 30);
        tab.add(exportButton);
        
        var importButton = new PsychUIButton(190, yPos, "Import Settings", function() {
            importSettings();
        }, 150, 30);
        tab.add(importButton);
        yPos += 50;
        
        // Reset all settings
        var resetAllButton = new PsychUIButton(20, yPos, "Reset All to Default", function() {
            resetAllSettings();
        }, 200, 30);
        resetAllButton.normalStyle.bgColor = FlxColor.RED;
        resetAllButton.normalStyle.textColor = FlxColor.WHITE;
        tab.add(resetAllButton);
    }
    
    private function refreshColorPickers(tab:Dynamic):Void
    {
        // Clear existing color pickers
        for (picker in colorPickers)
        {
            tab.remove(picker);
        }
        colorPickers = [];
        
        var startY = 80;
        var perRow = 4;
        
        for (i in 0...customColors.length)
        {
            var row = Math.floor(i / perRow);
            var col = i % perRow;
            var x = 20 + (col * 180);
            var y = startY + (row * 60);
            
            var colorPicker = new PsychUIColorPicker(x, y, customColors[i]);
            colorPicker.onColorChange = function(newColor:UnoColor) {
                customColors[i] = newColor;
                saveColorSettings();
            };
            tab.add(colorPicker);
            colorPickers.push(colorPicker);
        }
    }
    
    private function importFromNoteColors():Void
    {
        if (ClientPrefs.data.arrowRGB == null || ClientPrefs.data.arrowRGB.length == 0)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }
        
        // Import colors from arrowRGB WITHOUT modifying the original data
        var noteColorNames:Array<String> = ["Left Arrow", "Down Arrow", "Up Arrow", "Right Arrow"];
        var importedColors:Array<UnoColor> = [];
        for (i in 0...ClientPrefs.data.arrowRGB.length)
        {
            var colorData = ClientPrefs.data.arrowRGB[i];
            var colorName = i < noteColorNames.length ? noteColorNames[i] : "Note Color " + (i + 1);
            
            // Create UNO color from note color data (read-only operation)
            // Use the first color from the RGB array (the main color)
            var noteColor = colorData[0];
            importedColors.push(UnoColor.CUSTOM(noteColor, colorName));
        }
        
        // Add imported colors to existing UNO colors (don't replace)
        for (color in importedColors)
        {
            customColors.push(color);
        }
        
        // Save UNO colors to separate storage
        saveColorSettings();
        
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }

    private function addNewColor():Void
    {
        // Predefined color names for better variety
        var colorNames:Array<String> = [
            "Magenta", "Violet", "Indigo", "Teal", "Lime", "Coral", 
            "Salmon", "Turquoise", "Lavender", "Mint", "Peach", "Rose",
            "Gold", "Silver", "Bronze", "Crimson", "Maroon", "Navy",
            "Olive", "Tan", "Beige", "Ivory", "Khaki", "Plum", "Ruby", "Emerald"
        ];
        
        var colorIndex = customColors.length;
        var colorName = colorNames[colorIndex % colorNames.length];
        
        // Generate a nice color based on the index
        var hue = (colorIndex * 137.5) % 360; // Golden angle for good distribution
        var saturation = 0.7 + (colorIndex % 3) * 0.1; // Vary saturation slightly
        var brightness = 0.8 + (colorIndex % 2) * 0.1; // Vary brightness slightly
        
        var newColor = UnoColor.CUSTOM(FlxColor.fromHSB(hue, saturation, brightness), colorName);
        
        customColors.push(newColor);
        // refreshColorPickers(optionsBox.getTab('Colors').menu);
        saveColorSettings();
        
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    private function removeLastColor():Void
    {
        if (customColors.length <= 0)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }
        
        customColors.pop();
        // refreshColorPickers(optionsBox.getTab('Colors').menu);
        saveColorSettings();
        
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    private function resetToDefaultColors():Void
    {
        customColors = [
            UnoColor.CUSTOM(FlxColor.PURPLE, "Purple"),
            UnoColor.CUSTOM(FlxColor.PINK, "Pink"),
            UnoColor.CUSTOM(FlxColor.ORANGE, "Orange"),
            UnoColor.CUSTOM(FlxColor.CYAN, "Cyan")
        ];
        // refreshColorPickers(optionsBox.getTab('Colors').menu);
        saveColorSettings();
        
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    private function resetAllSettings():Void
    {
        resetToDefaultColors();
        
        // Reset UnoRules to default values
        UnoRules.ALLOW_STACKING = true;
        UnoRules.ALLOW_JUMP_IN = false;
        UnoRules.FORCE_PLAY = false;
        UnoRules.SEVEN_ZERO_RULE = false;
        UnoRules.WILD_DRAW_FOUR_CHALLENGE = true;
        UnoRules.WINNING_SCORE = 500;
        
        // Update UI elements to reflect the changes
        if (stackingCheckbox != null) stackingCheckbox.checked = UnoRules.ALLOW_STACKING;
        if (jumpInCheckbox != null) jumpInCheckbox.checked = UnoRules.ALLOW_JUMP_IN;
        if (sevenZeroCheckbox != null) sevenZeroCheckbox.checked = UnoRules.SEVEN_ZERO_RULE;
        if (forcePlayCheckbox != null) forcePlayCheckbox.checked = UnoRules.FORCE_PLAY;
        if (wildChallengeCheckbox != null) wildChallengeCheckbox.checked = UnoRules.WILD_DRAW_FOUR_CHALLENGE;
        if (scoreLimitStepper != null) scoreLimitStepper.value = UnoRules.WINNING_SCORE;
        
        saveAllSettings();
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    private function saveColorSettings():Void
    {
        // Save custom UNO colors using MixSaveWrapper
        // Since FuncEmbed doesn't work properly, we'll serialize manually
        var colorData = [];
        for (color in customColors)
        {
            switch(color)
            {
                case CUSTOM(flxColor, name):
                    colorData.push({
                        color: flxColor.to24Bit(),
                        name: name != null ? name : "Unnamed"
                    });
                case _:
                    // Skip standard colors - only save custom ones
            }
        }
        
        saveWrapper.addItem("customColors", haxe.Json.stringify(colorData));
        saveWrapper.save();
        
        if (onColorsChanged != null)
            onColorsChanged(customColors);
    }
    
    private function saveRulesSettings():Void
    {
        // Save UNO rules using MixSaveWrapper
        saveWrapper.addItem("allowStacking", UnoRules.ALLOW_STACKING);
        saveWrapper.addItem("allowJumpIn", UnoRules.ALLOW_JUMP_IN);
        saveWrapper.addItem("sevenZeroRule", UnoRules.SEVEN_ZERO_RULE);
        saveWrapper.addItem("forcePlay", UnoRules.FORCE_PLAY);
        saveWrapper.addItem("wildChallenge", UnoRules.WILD_DRAW_FOUR_CHALLENGE);
        saveWrapper.addItem("winningScore", UnoRules.WINNING_SCORE);
        saveWrapper.save();
        
        if (onRulesChanged != null)
            onRulesChanged();
    }
    
    private function saveAllSettings():Void
    {
        saveColorSettings();
        saveRulesSettings();
    }
    
    private function exportSettings():Void
    {
        // TODO: Implement settings export to file
        trace("Export settings functionality - TODO");
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    private function importSettings():Void
    {
        // TODO: Implement settings import from file
        trace("Import settings functionality - TODO");
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
        }
    }
    
    public function UIEvent(id:String, sender:Dynamic):Void
    {
        // Handle PsychUI events if needed
        trace('UNO Options UI Event: $id from $sender');
    }
}
