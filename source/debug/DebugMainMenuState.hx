package debug;

import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import objects.Alphabet;
import states.LoadingState;
import states.MainMenuState;
import states.editors.MasterEditorMenu;

class DebugMainMenuState extends MusicBeatState
{
    var debugOptions:Array<DebugOption> = [];
    var curSelected:Int = 0;

    var grpOptions:FlxTypedGroup<Alphabet>;
    var bg:FlxSprite;
    var titleText:FlxText;
    var descText:FlxText;
    var helpText:FlxText;

    override function create()
    {
        super.create();

        // Create background
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = FlxColor.fromRGB(50, 50, 100);
        add(bg);

        // Add title text
        titleText = new FlxText(0, 20, FlxG.width, "Debug Main Menu", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(titleText);

        grpOptions = new FlxTypedGroup<Alphabet>();
        add(grpOptions);

        // Description text
        descText = new FlxText(0, FlxG.height - 150, FlxG.width, "", 20);
        descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(descText);

        // Create help text
        helpText = new FlxText(0, FlxG.height - 80, FlxG.width,
            "UP/DOWN - Navigate | ENTER - Select | ESC - Back to Main Menu", 16);
        helpText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(helpText);

        setupDebugOptions();
        changeSelection(0);
    }

    function setupDebugOptions()
    {
        // Song & Music Debug Options
        addOption("Song Selector", "Play any song from the game", function() {
            FlxG.switchState(new debug.SongSelectorDebugState());
        });

        // Editor Debug Options
        addOption("Chart Editor", "Edit song charts", function() {
            ClientPrefs.openChartEditor();
        });

        addOption("Character Editor", "Create and edit characters", function() {
            LoadingState.loadAndSwitchState(new states.editors.CharacterEditorState('dad'));
        });

        addOption("Week Editor", "Create and edit weeks", function() {
            MusicBeatState.switchState(new states.editors.WeekEditorState());
        });

        addOption("Menu Character Editor", "Edit menu characters", function() {
            MusicBeatState.switchState(new states.editors.MenuCharacterEditorState());
        });

        addOption("Dialogue Portrait Editor", "Edit dialogue portraits", function() {
            LoadingState.loadAndSwitchState(new states.editors.DialogueCharacterEditorState(), false);
        });

        addOption("Dialogue Editor", "Edit dialogue boxes", function() {
            LoadingState.loadAndSwitchState(new states.editors.DialogueEditorState(), false);
        });

        addOption("Note Splash Debug", "Test note splash effects", function() {
            MusicBeatState.switchState(new states.editors.NoteSplashEditorState());
        });

        // Stage & Visual Debug Options
        addOption("Stage Editor", "Create and edit stages", function() {
            LoadingState.loadAndSwitchState(new states.editors.StageEditorState());
        });

        addOption("Character Animation Debug", "Test character animations", function() {
            LoadingState.loadAndSwitchState(new states.editors.CharacterEditorState('dad', false));
        });

        // State & System Debug Options
        addOption("Debug State Menu", "Browse all game states", function() {
            FlxG.switchState(new states.DebugStateMenu());
        });

        addOption("System Debug Info", "Show debug overlay", function() {
            debug.DebugManager.toggleDebugOverlay();
        });

        // Options & Settings Debug
        addOption("Options Menu", "Access game options", function() {
            LoadingState.loadAndSwitchState(new options.OptionsState());
        });

        // Mod & Content Debug Options
        addOption("Mod Tools Menu", "Access mod development tools", function() {
            FlxG.switchState(new states.editors.MasterEditorMenu());
        });

        #if MODS_ALLOWED
        addOption("Mods Menu", "Browse and manage mods", function() {
            FlxG.switchState(new states.ModsMenuState());
        });
        #end

        // Credits & Info
        addOption("Credits", "View game credits", function() {
            MusicBeatState.switchState(new states.CreditsState());
        });

        // Archipelago Debug Options (if available)
        #if archipelago
        addOption("Archipelago Debug", "Debug AP connection", function() {
            FlxG.switchState(new archipelago.APEntryState());
        });
        #end

        // Create alphabet items
        for (i in 0...debugOptions.length)
        {
            var optionText:Alphabet = new Alphabet(90, 320, debugOptions[i].name, true);
            optionText.isMenuItem = true;
            optionText.targetY = i;
            grpOptions.add(optionText);
        }
    }

    function addOption(name:String, description:String, action:Void->Void)
    {
        debugOptions.push({
            name: name,
            description: description,
            action: action
        });
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        var upP = controls.UI_UP_P;
        var downP = controls.UI_DOWN_P;
        var accepted = controls.ACCEPT;

        if (upP)
        {
            changeSelection(-1);
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        if (downP)
        {
            changeSelection(1);
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (accepted)
        {
            selectOption();
        }

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            FlxG.switchState(new MainMenuState());
        }
    }

    function changeSelection(change:Int = 0)
    {
        curSelected += change;

        if (curSelected < 0)
            curSelected = debugOptions.length - 1;
        if (curSelected >= debugOptions.length)
            curSelected = 0;

        // Update alphabet positions
        var bullShit:Int = 0;
        for (item in grpOptions.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;
            if (item.targetY == 0)
                item.alpha = 1;
        }

        // Update description
        if (debugOptions[curSelected] != null)
            descText.text = debugOptions[curSelected].description;

        // Change background color based on selection
        var colors = [
            FlxColor.fromRGB(50, 50, 100),   // Default blue
            FlxColor.fromRGB(100, 50, 50),   // Red for editors
            FlxColor.fromRGB(50, 100, 50),   // Green for tools
            FlxColor.fromRGB(100, 100, 50),  // Yellow for debug
            FlxColor.fromRGB(100, 50, 100),  // Purple for options
        ];

        var colorIndex = Std.int(curSelected / 4) % colors.length;
        FlxTween.color(bg, 0.3, bg.color, colors[colorIndex]);
    }

    function selectOption()
    {
        if (debugOptions[curSelected] != null)
        {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            debugOptions[curSelected].action();
        }
    }
}

typedef DebugOption = {
    var name:String;
    var description:String;
    var action:Void->Void;
}
