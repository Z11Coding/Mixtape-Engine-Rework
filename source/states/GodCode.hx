package states;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.filters.BitmapFilter;
import flixel.addons.transition.FlxTransitionableState;
import Sys;

class GodCode extends MusicBeatState
{
	var cmd_screen:FlxSprite;
	var cmd_text:FlxText;
	var camfilters:Array<BitmapFilter> = [];
	var ch = 2 / 1000;
	
	override function create()
	{	
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
						case 10:
							cmd_wait = 20;
						case 13 | 14 | 15:
							cmd_wait = 30;
						case 16 | 17:
							cmd_wait = 60;
						case 18:
							cmd_wait = 100;
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
								cmd_wait = 100;
							}
						case 22:
							cmd_wait = 120;
						case 24:
							cmd_wait = 300;
						case 25:
							FlxG.save.data.enableCodes = true;
						case 40:
							FlxG.switchState(new CodeState());
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
		'Install "Codes" Category on ' + Sys.environment()["COMPUTERNAME"] + '? [y,n]', //20
		'Downloading files...',
		'Installing Reality-Destroyer V3...',
		'..................................',
		'SUCCESS.',
		'Closing...'
	];
	
	var cmd_accept:Array<String> = [
	
	];
}
