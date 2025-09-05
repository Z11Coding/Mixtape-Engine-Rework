package options.legacylua;

import options.legacylua.LegacyLuaSettingsManager.LegacyLuaSetting;

class LegacyLuaSettingsSubState extends MusicBeatSubstate {
    private var modName:String;
    private var songName:Null<String>;
    private var currentSetting:Null<LegacyLuaSetting>;
    private var onComplete:LegacyLuaSetting->Void;

    private var grpOptions:FlxTypedGroup<Alphabet>;
    private var options:Array<{name:String, setting:LegacyLuaSetting}> = [];
    private var curSelected:Int = 0;

    private var titleText:FlxText;
    private var descText:FlxText;

    public function new(modName:String, ?songName:String, currentSetting:Null<LegacyLuaSetting>, onComplete:LegacyLuaSetting->Void) {
        super();

        this.modName = modName;
        this.songName = songName;
        this.currentSetting = currentSetting;
        this.onComplete = onComplete;

        // Setup options
        options = [
            { name: "Player Choice", setting: PLAYER_CHOICE },
            { name: "Force Legacy Lua ON", setting: FORCE_ON },
            { name: "Force Legacy Lua OFF", setting: FORCE_OFF }
        ];

        // Find current selection
        for (i in 0...options.length) {
            if (options[i].setting == currentSetting) {
                curSelected = i;
                break;
            }
        }
    }

    override function create():Void {
        super.create();

        // Background
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        // Title
        var title = songName != null ?
            'Legacy Lua Setting for "$songName"\n(Mod: $modName)' :
            'Legacy Lua Setting for Mod "$modName"';

        titleText = new FlxText(0, 150, FlxG.width, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        titleText.scrollFactor.set();
        add(titleText);

        // Description
        var desc = "Choose how Legacy Lua mode should behave:\n\n" +
            "Player Choice: Use the setting from Gameplay Changers\n" +
            "Force ON: Always use Legacy Lua for this " + (songName != null ? "song" : "mod") + "\n" +
            "Force OFF: Never use Legacy Lua for this " + (songName != null ? "song" : "mod") + "\n\n" +
            (songName != null ? "Song settings take priority over mod settings." : "Mod settings can be overridden by song-specific settings.");

        descText = new FlxText(50, 250, FlxG.width - 100, desc, 16);
        descText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        descText.scrollFactor.set();
        add(descText);

        // Options
        grpOptions = new FlxTypedGroup<Alphabet>();
        add(grpOptions);

        for (i in 0...options.length) {
            var optionText:Alphabet = new Alphabet(200, 450 + (i * 80), options[i].name, true);
            optionText.isMenuItem = true;
            optionText.targetY = i;
            optionText.ID = i;
            optionText.setScale(0.8, 0.8);
            grpOptions.add(optionText);
        }

        changeSelection();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (controls.UI_UP_P) {
            changeSelection(-1);
        }

        if (controls.UI_DOWN_P) {
            changeSelection(1);
        }

        if (controls.ACCEPT) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            var selectedSetting = options[curSelected].setting;
            onComplete(selectedSetting);
            close();
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
        }
    }

    private function changeSelection(change:Int = 0):Void {
        curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

        for (num => item in grpOptions.members) {
            item.targetY = num - curSelected;
            item.alpha = 0.6;
            if (item.targetY == 0) {
                item.alpha = 1;

                // Update color based on setting
                var color:FlxColor = switch (options[num].setting) {
                    case PLAYER_CHOICE: FlxColor.WHITE;
                    case FORCE_ON: FlxColor.GREEN;
                    case FORCE_OFF: FlxColor.RED;
                }
                item.color = color;
            } else {
                item.color = FlxColor.WHITE;
            }
        }

        if (change != 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }
}
