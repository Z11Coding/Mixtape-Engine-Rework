package states;

import Sys;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.filters.BitmapFilter;

class GodCode extends MusicBeatState
{
	var cmd_screen:FlxSprite;
	var cmd_text:FlxText;
	var camfilters:Array<BitmapFilter> = [];
	var ch = 2 / 1000;

	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("???", null);
		#end

		setStateScript('SecretState');

		FlxG.camera.setFilters(camfilters);
		FlxG.camera.filtersEnabled = true;
		camfilters.push(shaders.ShadersHandler.chromaticAberration);
		FlxG.sound.playMusic(Paths.music("WELCOME"), 0.5, true);
		FlxG.sound.playMusic(Paths.music("hello"), 1, true);
		cmd_screen = new FlxSprite(-500, -400).makeGraphic(FlxG.width * 4, FlxG.height * 4, FlxColor.BLACK);
		cmd_screen.scrollFactor.set();
		cmd_screen.alpha = 1;

		cmd_text = new FlxText(10, 10, 0, '', 20);
		cmd_text.scrollFactor.set();
		cmd_text.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		var daStatic:FlxSprite = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('effects/static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.alpha = 0.5;
		daStatic.animation.addByPrefix('static','lestatic',24, true);
		daStatic.animation.play('static');
		super.create();
		add(cmd_screen);
		add(daStatic);
		add(cmd_text);

	}

	var wiiMenuState = 2;
	var cmd_wait = 1;
	var cmd_ind = 0;
	//var accepted = false;

	override function update(elapsed:Float)
	{
		ch = FlxG.random.int(1,5) / 1000;
		ch = FlxG.random.int(1,5) / 1000;
		shaders.ShadersHandler.setChrome(ch);
		switch (wiiMenuState)
		{
			case 2:
				if (cmd_wait > 0) cmd_wait --
				else if (cmd_wait == 0)
				{
					var ltxt = cmd_text.text;
					cmd_text.text += cmd_list[cmd_ind] + '\n';
					switch (cmd_ind)
					{
						case 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9:
							cmd_wait = FlxG.random.int(0, 100);
						case 10:
							cmd_wait = 50;
						case 14:
							cmd_wait = 150;
						case 13 | 15:
							cmd_wait = 350;
						case 16 | 17:
							cmd_wait = 1080;
						case 19:
							cmd_wait = 2200;
						case 20:
							cmd_wait = -1;
						case 21:
							if (ltxt != '')
							{
								FlxG.switchState(new CategoryState());
								cmd_text.text = 'aweonao';
								cmd_wait = -2;
							}
							else
							{
								cmd_wait = 1200;
							}
						case 22:
							cmd_wait = 1020;
						case 24:
							cmd_wait = 1000;
						case 25:
							FlxG.save.data.specialbabygirl = true;
						case 40:
							MusicManager.playMenuMusic();
							FlxG.switchState(new CategoryState());
						default:
							cmd_wait = 2;
					}
					cmd_ind ++;
				}
				else
				{
					if (FlxG.keys.justPressed.Y)
					{
						cmd_text.text = '';
						cmd_wait = 1;
					}
					else if (FlxG.keys.justPressed.N)
					{
						cmd_text.text = 'Installation has been cancelled.\nClosing...';
						cmd_wait = 200;
					}
				}
		}
		super.update(elapsed);
	}
	var cmd_list:Array<String> = [
		'NOW LOADING',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'', //10
		'', //11
		'',
		'Clearing up enviroment... OK.', //13
		'WARNING: Extra VOID detected', //14
		'Opening VOID parser...:', //15
		"LOADING 'Reality-Modder' VOID...", //16
		'Done.', //17
		'VOID READY TO MOD!', //18
		"Reading 'Reality-Modder V3...'",
		'Running Install "Special" Category on ' + Sys.environment()["COMPUTERNAME"] + '? [y,n]', //20
		'Downloading files...',
		'Installing Special Category...',
		'..................................',
		'SUCCESS.',
		'Closing...'
	];

	var cmd_accept:Array<String> = [

	];
}
