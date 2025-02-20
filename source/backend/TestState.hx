package backend;

import states.What;
import backend.WeekData;

import objects.Character;

import states.MainMenuState;
import states.FreeplayState;

// import ct.CompileTime;

import StateMap;
// @:build(backend.macros.FlxStateMacro.build())
class TestState extends MusicBeatState
{
    public static var stateOptions:Array<String>;
    public static var stateMap:Map<String, Class<Dynamic>>;

    var options:Array<String> = [];
    private var grpTexts:FlxTypedGroup<Alphabet>;
    private var directories:Array<String> = [null];

    private var curSelected = 0;
    private var curDirectory = 0;
    private var directoryTxt:FlxText;

    override function create()
    {
        // ct.CompileTimeClassList.initialise();
        // for (musicalState in CompileTime.getAllClasses(MusicBeatState))
        // {
        //    var name = (Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1]);
        //     stateMap.set(name, musicalState);
        // }

        stateMap = StateMap.getAllFlxStateClasses();
        FlxG.camera.bgColor = FlxColor.BLACK;
        #if DISCORD_ALLOWED
        // Updating Discord Rich Presence
        DiscordClient.changePresence("Debug Menu", null);
        #end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set();
        bg.color = 0xFF353535;
        add(bg);

        grpTexts = new FlxTypedGroup<Alphabet>();
        add(grpTexts);

        for (state in stateMap.keys())
        {
            stateOptions.push(state);
        }


        options = stateOptions;

        for (i in 0...options.length)
        {
            var leText:Alphabet = new Alphabet(90, 320, options[i], true);
            leText.isMenuItem = true;
            leText.targetY = i;
            grpTexts.add(leText);
            leText.snapToPosition();
        }
        
        #if MODS_ALLOWED
        var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
        textBG.alpha = 0.6;
        add(textBG);

        directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
        directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        directoryTxt.scrollFactor.set();
        add(directoryTxt);
        
        for (folder in Mods.getModDirectories())
        {
            directories.push(folder);
        }

        var found:Int = directories.indexOf(Mods.currentModDirectory);
        if(found > -1) curDirectory = found;
        changeDirectory();
        #end
        changeSelection();

        FlxG.mouse.visible = false;
        super.create();
    }

    override function update(elapsed:Float)
    {
        if (controls.UI_UP_P)
        {
            changeSelection(-1);
        }
        if (controls.UI_DOWN_P)
        {
            changeSelection(1);
        }
        #if MODS_ALLOWED
        if(controls.UI_LEFT_P)
        {
            changeDirectory(-1);
        }
        if(controls.UI_RIGHT_P)
        {
            changeDirectory(1);
        }
        #end

        if (controls.BACK)
        {
            FlxG.switchState(new What());
        }

        if (controls.ACCEPT)
        {
            var selectedOption = options[curSelected];
            var selectedState = stateMap[selectedOption];
            if (selectedState != null)
            {
                FlxG.switchState(Type.createInstance(selectedState, []));
            }
        }
        
        var bullShit:Int = 0;
        for (item in grpTexts.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;
            // item.setGraphicSize(Std.int(item.width * 0.8));

            if (item.targetY == 0)
            {
                item.alpha = 1;
                // item.setGraphicSize(Std.int(item.width));
            }
        }
        super.update(elapsed);
    }

    function regenMenu():Void
    {
        for (i in 0...grpTexts.members.length) {
            var obj = grpTexts.members[0];
            obj.kill();
            grpTexts.remove(obj, true);
            obj.destroy();
        }

        for (i in 0...options.length)
        {
            var leText:Alphabet = new Alphabet(90, 320, options[i], true);
            leText.isMenuItem = true;
            leText.targetY = i;
            grpTexts.add(leText);
            leText.snapToPosition();
        }
        curSelected = 0;
        changeSelection();
    }

    function changeSelection(change:Int = 0)
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curSelected += change;

        if (curSelected < 0)
            curSelected = options.length - 1;
        if (curSelected >= options.length)
            curSelected = 0;
    }

    #if MODS_ALLOWED
    function changeDirectory(change:Int = 0)
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curDirectory += change;

        if(curDirectory < 0)
            curDirectory = directories.length - 1;
        if(curDirectory >= directories.length)
            curDirectory = 0;
    
        WeekData.setDirectoryFromWeek();
        if(directories[curDirectory] == null || directories[curDirectory].length < 1)
            directoryTxt.text = '< No Mod Directory Loaded >';
        else
        {
            Mods.currentModDirectory = directories[curDirectory];
            directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
        }
        directoryTxt.text = directoryTxt.text.toUpperCase();
    }
    #end
}