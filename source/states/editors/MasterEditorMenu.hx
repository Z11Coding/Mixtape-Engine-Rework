package states.editors;

import backend.WeekData;

import objects.Character;

import states.MainMenuState;
import states.FreeplayState;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [];
	var optionsOG:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'Stage Editor',
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		/*'Note Splash Debug'*/ //Might bother with notesplash in general in the future. def not right now though
	];
	var dialogueChoices:Array<String> = [
		'OG Chart Editor',
		'Psych Chart Editor',
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		options = optionsOG;

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
			if (options == dialogueChoices) {
				options = optionsOG;
				regenMenu();
			}
			else MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			if (options[curSelected] != 'Chart Editor')
			{
				FlxG.sound.music.volume = 0;
				FreeplayState.destroyFreeplayVocals();
			}
			if (options == dialogueChoices)
			{
				switch (options[curSelected])
				{
					case 'OG Chart Editor':
						MusicBeatState.switchState(new ChartingStateOG());
					case 'Psych Chart Editor':
						MusicBeatState.switchState(new ChartingStatePsych());
				}
				FlxG.sound.music.volume = 0;
				#if PRELOAD_ALL
				FreeplayState.destroyFreeplayVocals();
				#end
			}
			else
			{
				switch(options[curSelected]) {
					case 'Chart Editor'://felt it would be cool maybe
						options = dialogueChoices;
						regenMenu();
					case 'Character Editor':
						FlxG.switchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
					case 'Stage Editor':
						FlxG.switchState(new StageEditorState());
					case 'Week Editor':
						FlxG.switchState(new WeekEditorState());
					case 'Menu Character Editor':
						FlxG.switchState(new MenuCharacterEditorState());
					case 'Dialogue Editor':
						FlxG.switchState(new DialogueEditorState());
					case 'Dialogue Portrait Editor':
						FlxG.switchState(new DialogueCharacterEditorState());
				}
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