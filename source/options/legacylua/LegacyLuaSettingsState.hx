package options.legacylua;

import options.legacylua.LegacyLuaCategoryState;
import options.legacylua.LegacyLuaSettingsManager.LegacyLuaSetting;

class LegacyLuaSettingsState extends MusicBeatState {
    // Static flag to indicate when Legacy Lua settings are being actively edited
    public static var inLegacyLuaSettingsMode:Bool = false;

    private var grpOptions:FlxTypedGroup<Alphabet>;
    private var menuOptions:Array<String> = [
        "Mod Settings",
        "Song Settings"
    ];
    private var curSelected:Int = 0;

    override function create():Void {
        super.create();

        // Set flag to indicate we're in Legacy Lua settings mode
        inLegacyLuaSettingsMode = true;

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Legacy Lua Settings", null);
        #end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.color = 0xFFea71fd;
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        grpOptions = new FlxTypedGroup<Alphabet>();
        add(grpOptions);

        for (i in 0...menuOptions.length) {
            var optionText:Alphabet = new Alphabet(-300, 350, menuOptions[i], true);
            optionText.isMenuItem = true;
            optionText.targetY = i;
            optionText.ID = i;
            grpOptions.add(optionText);
        }

        // Add instructional text
        var instructText:FlxText = new FlxText(50, FlxG.height - 120, FlxG.width - 100,
            "Legacy Lua Settings System\n\n" +
            "This allows you to set Legacy Lua mode on a per-mod or per-song basis.\n" +
            "Song settings take priority over mod settings and player choice.\n\n" +
            "Colors: White = Player Choice, Green = Force On, Red = Force Off", 16);
        instructText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        instructText.scrollFactor.set();
        add(instructText);

        changeSelection();

        MegaManager.conductor.addBeatCallback((curBeat:Int, backward:Bool) ->
		{
			FlxG.camera.zoom = zoomies;
			FlxTween.tween(FlxG.camera, {zoom: 1}, RConductor.crochet / 1300, {
				ease: FlxEase.quadOut
			});
		});
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

            switch (curSelected) {
                case 0: // Mod Settings
                    // Set up for mod settings mode
                    states.CategoryState.legacyLuaMode = LegacyLuaCategoryState.LegacyLuaSettingsMode.MOD_SETTINGS;
                    LegacyLuaCategoryState.legacyLuaMode = LegacyLuaCategoryState.LegacyLuaSettingsMode.MOD_SETTINGS;
                    options.legacylua.LegacyLuaFreeplayState.inLegacyLuaMode = true;
                    MusicBeatState.switchState(new LegacyLuaCategoryState());

                case 1: // Song Settings
                    // Set up for song settings mode
                    states.CategoryState.legacyLuaMode = LegacyLuaCategoryState.LegacyLuaSettingsMode.SONG_SETTINGS;
                    LegacyLuaCategoryState.legacyLuaMode = LegacyLuaCategoryState.LegacyLuaSettingsMode.SONG_SETTINGS;
                    options.legacylua.LegacyLuaFreeplayState.inLegacyLuaMode = true;
                    MusicBeatState.switchState(new LegacyLuaCategoryState());
            }
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            // Reset the main settings mode flag when explicitly going back
            inLegacyLuaSettingsMode = false;
            states.PlayState.isLegacyLuaTest = false; // Reset testing flag
            MusicBeatState.switchState(new options.OptionsState());
        }

        // Update positions
        for (item in grpOptions.members) {
            var coolEffect:Int = 0;

            if (item.ID < curSelected) {
                coolEffect = ((item.ID - curSelected) * 90);
            } else if (item.ID > curSelected) {
                coolEffect = -((item.ID - curSelected) * 90);
            }

            item.x = FlxMath.lerp(item.ID == curSelected ? 380 : -2010 + coolEffect, item.x,
                CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
        }
    }

    function changeSelection(change:Int = 0):Void {
        curSelected = FlxMath.wrap(curSelected + change, 0, menuOptions.length - 1);

        for (num => item in grpOptions.members) {
            item.targetY = num - curSelected;
            item.alpha = 0.6;
            if (item.targetY == 0) {
                item.alpha = 1;
            }
        }

        if (change != 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }

    override function destroy():Void {
        // Only reset other flags if we're not in Legacy Lua settings mode anymore
        // This prevents resetting flags when transitioning between Legacy Lua states
        if (!inLegacyLuaSettingsMode) {
            states.CategoryState.legacyLuaMode = null;
            options.legacylua.LegacyLuaFreeplayState.inLegacyLuaMode = false;
            states.PlayState.isLegacyLuaTest = false;
        }
        super.destroy();
    }
}
