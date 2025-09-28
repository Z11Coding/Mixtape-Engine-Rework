package options;

import stages.StageData;
import states.MainMenuState;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay',
		#if TRANSLATIONS_ALLOWED 'Language', #end
		"Mixtape Settings",
		"Save Management",
		"UNO Options",
		"Legacy Lua Settings"
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubState(new options.LanguageSubState());
			case 'Archipelago':
				openSubState(new options.ArchipelagoSettingsSubState());
			case 'Mixtape Settings':
				openSubState(new options.MixtapeSettingsSubState());
			case 'Save Management':
				MusicBeatState.switchState(new states.SaveManagementState());
			case 'UNO Options':
				openSubState(new games.uno.UnoOptionsSubState());
			case 'Legacy Lua Settings':
				MusicBeatState.switchState(new options.legacylua.LegacyLuaSettingsState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	public function new(?onPlayState:Bool = false)
	{
		this.onPlayState = onPlayState;
		super();
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		if (archipelago.APEntryState.inArchipelagoMode) options.push('Archipelago');


		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(-300, 350, Language.getPhrase('options_$option', option), true);
			optionText.isMenuItem = true;
			optionText.targetY = num;
			optionText.ID = num;
			//optionText.y += (92 * (num - (options.length / 2))) + 45;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		//add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		//selectorRight.scrollFactor.set();
		//add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);

		for(item in grpOptions.members)
		{
			var coolEffect:Int = 0;

			if(item.ID < curSelected)
				coolEffect = ((item.ID - curSelected) * 90);
			else if (item.ID > curSelected)
				coolEffect = -((item.ID - curSelected) * 90);

			item.x = FlxMath.lerp(item.ID == curSelected? 380 : -2010 + coolEffect, item.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
