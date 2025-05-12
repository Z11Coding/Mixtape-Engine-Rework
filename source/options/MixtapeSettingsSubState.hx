package options;

class MixtapeSettingsSubState extends BaseOptionsMenu
{
	public static var curBPMList:Array<Int> =  [0, 160, 105, 130, 100, 160, 180, 100, 125, 150, 140];
	public function new()
	{
		title = 'Mixtape Settings.';
		rpcTitle = 'Mixtape Settings'; // for Discord Rich Presence

		var option:Option = new Option('---GAMEPLAY---',
			"",
			'',
			LABEL);
		addOption(option);

		var option:Option = new Option('Ghost Doubles',
			"If checked, when hitting more than one note, a ghost of the character will appear.",
			'doubleGhosts',
			BOOL);
		addOption(option);

		var option:Option = new Option('Base Stage Gimmicks',
			"if checked, each weeks gimmick will activate.", 
			'stageGimmick',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health System Mode',
			"Switch how the health bar works\n(NA stands for Not Added)", 
			'healthMode',
			STRING,
			[
				"OG", 
				"Mixtape", 
				"Kade",
				"Tabi", 
				"Double (NA)", 
				"Lives (NA)", 
				"Lives + HealthBar (NA)", 
				"Random (NA)",
			]);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Input System', 
		"The input system you wish to use.", 
		'inputSystem', 
		STRING,
		[
			"Native", 
			"Native-old", 
			"Andromeda (legacy)",
			//"BEAT! Engine", 
			//"Kade Engine", 
			//"ZoroForce EK", 
			//"Mic'ed Up Engine",
			//"YoshiEngine",
			//"Kade Engine Community",
			//"Rhythm"
		]);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Intro Skip When', 
		"Choose when the intro can be skipped.", 
		'skipWhen',
		STRING,
		[
			"Freeplay",
			"Story",
			"Freeplay & Story",
			"None"
		]);
		addOption(option);
		option.displayFormat = '< %v >';
		
		var option:Option = new Option('Intro Skip To', 
		"The note skipped to when the intro is skipped.", 
		'skipMode', 
		STRING,
		[
			"First Note", 
			"First BF Note"
		]);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Mix-Up Mode',
			"Have you ever hear of Funky Friday/Friday Night Bloxin'?\nWell is essentially that, except it's single player.",
			'mixupMode',
			BOOL);
		//addOption(option);

		var option:Option = new Option('Opp. Difficulty',
			"ONLY WORKS IF MIX-UP MODE IS ON!!!\nSet the level of how badly the opponent beats your butt.",
			'aiDifficulty',
			STRING, 
			[
			"Baby Mode",
			"Easier",
			"Normal",
			"Harder",
			"Hardest",
			"Average FNF Player",
			"Dont"]
		);
		//addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('---MENUS---',
			"",
			'',
			LABEL);
		addOption(option);

		var option:Option = new Option('Freeplay Menu:',
			"Which freeplay menu do you prefer?\n(This has no effect on Archipelago Mode)\nBASE GAME DOES NOTHING FOR NOW!",
			'freeplayMenu',
			STRING,
			['Mixtape', 'Osu', 'Base Game']);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Menu Music:',
			"What song do you prefer for the Main Menu?\n(And like 90% of every other menu as well)",
			'menuSong',
			STRING,
			['None', 'Pause Menu', 'Panix Press', 'TitleMania', 'Base Game']);
		addOption(option);
		option.displayFormat = '< %v >';
		option.onChange = onChangeMenuMusic;
		
		var option:Option = new Option('Pause Music:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			['None', 'Breakfast', 'Tea Time', 'Celebration', 'Drippy Genesis', 'Reglitch', 'False Memory', 'Funky Genesis', 'Late Night Cafe', 'Late Night Jersey', 'Silly Little Sample Song']);
		addOption(option);
		option.displayFormat = '< %v >';
		option.onChange = onChangePauseMusic;

		var option:Option = new Option('Editor Music:',
			"What song do you prefer for the Editors?",
			'editorMusic',
			STRING,
			[
				'None', 
				'Pause Menu',
				FlxG.random.bool(0.3) ? 'Menu Menu' : "Menu Music",
				'Artistic Expression',
				'DSI Shop', 
				'Mii Theme', 
				'Wii Shop', 
				'Sneaky Adventure', 
				'SkyDecay 5', 
				'Ice Flow', 
				'Monkeys Spinning Monkeys', 
				'Quirky Dog', 
				'Carefree', 
				'Scheming Weasel', 
				'Local Forecast', 
				'Sneaky Snitch', 
				'Fluffing a Duck'
			]);
		addOption(option);
		option.displayFormat = '< %v >';
		option.onChange = onChangeEditorMusic;

		var option:Option = new Option('Editor Music Volume:',
			"How loud do you want the music to be?",
			'editorMusVol',
			FLOAT);
		option.scrollSpeed = 20;
		option.minValue = 0;
		option.maxValue = 5; // Because 1 just isn't enough sometimes
		option.decimals = 1;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('---MISC.---',
			"",
			'',
			LABEL);
		addOption(option);

		var option:Option = new Option('Allow Visualizers',
			"If unchecked, the visualizers will be turned off.",
			'allowVis',
			BOOL);
		addOption(option);

		var option:Option = new Option('Allow Visualizers on health bar',
			"If unchecked, the visualizers on the health bar will be turned off.",
			'healthVis',
			BOOL);
		addOption(option);

		var option:Option = new Option('Visualizer Opacity',
			"The opacity the visualizer. (THIS AFFECTS ALL VISUALIZERS!)",
			'visOpacity',
			FLOAT);
		option.scrollSpeed = 20;
		option.minValue = 0;
		option.maxValue = 1;
		option.decimals = 1;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Audio Display Quality',
			"The analytical quality of music data for the visualizer.",
			'audioDisplayQuality',
			INT);
		option.scrollSpeed = 20;
		option.minValue = 1;
		option.maxValue = 4;
		addOption(option);

		var option:Option = new Option('Audio Display Update',
			"The reaction interval of the music analyzer for the visualizer.",
			'audioDisplayUpdate',
			INT);
		option.displayFormat = '%vMS';
		option.scrollSpeed = 20;
		option.minValue = 0;
		option.maxValue = 200;
		addOption(option);

		var option:Option = new Option(
			'Silent Volume Noise', 
			"If checked, The volume wont make noise when you turn up/down the volume", 
			'silentVol', 
			'bool'
		);
		addOption(option);

		var option:Option = new Option(
			'Raise Volume Sound', 
			"The sound that plays when you change the volume.", 
			'volUp', 
			STRING, 
			[
			"beep",
			"bfBeep",
			"cancelMenu",
			"clickText",
			"confirmMenu",
			"dialogue",
			"dialogueClose",
			"GF_4",
			"hitsound",
			"Metronome_Tick",
			"pixelText",
			"scrollMenu",
			"snd_hurt1",
			"txtSans",
			"Volup"]
		);
		addOption(option);
		option.onChange = onChangeSoundUp;
		option.displayFormat = '< %v >';

		var option:Option = new Option(
			'Lower Volume Sound', 
			"The sound that plays when you change the volume.", 
			'volDown', 
			STRING, 
			[
			"beep",
			"bfBeep",
			"cancelMenu",
			"clickText",
			"confirmMenu",
			"dialogue",
			"dialogueClose",
			"GF_4",
			"hitsound",
			"Metronome_Tick",
			"pixelText",
			"scrollMenu",
			"snd_hurt1",
			"txtSans",
			"Voldown"]
		);
		addOption(option);
		option.onChange = onChangeSoundDown;
		option.displayFormat = '< %v >';

		var option:Option = new Option(
			'Max Volume Sound', 
			"The sound that plays when you reach max volume.", 
			'volMax', 
			STRING, 
			[
			"beep",
			"bfBeep",
			"cancelMenu",
			"clickText",
			"confirmMenu",
			"dialogue",
			"dialogueClose",
			"GF_4",
			"hitsound",
			"Metronome_Tick",
			"pixelText",
			"scrollMenu",
			"snd_hurt1",
			"txtSans",
			"VolMAX"]
		);
		addOption(option);
		option.onChange = onChangeSoundMax;
		option.displayFormat = '< %v >';

		var option:Option = new Option('Check the Archipelago World',
			"If checked, the engine will check the current version of the Friday Night Funkin Archipelago World at launch.",
			'checkAPWorld',
			BOOL);
		addOption(option);

		var option:Option = new Option('Allow Username Detection',
			"Uncheck this to prevent the game from leaking your computer name. Usually a good idea for streamers.",
			'username',
			BOOL);
		addOption(option);

		var option:Option = new Option('Break The Sticker Audio',
			"Literally just locks the sound to a funny bug I found.",
			'audioBreak',
			BOOL);
		addOption(option);

		var option:Option = new Option('---DEBUG---',
			"",
			'',
			LABEL);

		addOption(option);

		var option:Option = new Option('Ignore Tween Errors',
			"Disables the error message that appears when a tween is called on a non-existent object.",
			'ignoreTweenErrors',
			BOOL);

		addOption(option);

		var option:Option = new Option('Show Crash Dialogue',
			"Disables the crash dialogue that appears when the game crashes.",
			'showCrash',
			BOOL);

			addOption(option);

		var option:Option = new Option('Chart Editor Style',
			"Choose the style of the chart editor.",
			'chartEditorStyle',
			STRING,
			[
				'New',
				'Old'
			]);
		addOption(option);

		super();
	}

	var changedMusic:Bool = false;
	var indeed:Int = 0;
	function onChangePauseMusic()
	{
		switch (ClientPrefs.data.pauseMusic)
		{
			case 'None':
				indeed = 0;
			case 'Breakfast':
				indeed = 1;
			case 'Tea Time':
				indeed = 2;
			case 'Celebration':
				indeed = 3;
			case 'Drippy Genesis':
				indeed = 4;
			case 'Reglitch':
				indeed = 5;
			case 'False Memory':
				indeed = 6;
			case 'Funky Genesis':
				indeed = 7;
			case 'Late Night Cafe':
				indeed = 8;
			case 'Late Night Jersey':
				indeed = 9;
			case 'Silly Little Sample Song':
				indeed = 10;
		}
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}')));

		changedMusic = true;
		Conductor.bpm = curBPMList[indeed];
		ClientPrefs.data.pauseBPM = curBPMList[indeed];
	}

	function onChangeMenuMusic() {MusicManager.playMenuMusic(1); changedMusic = true;}
	function onChangeEditorMusic() {MusicManager.playEditorMusic(1); changedMusic = true;}

	function onChangeSoundDown()
	{
		if (!ClientPrefs.data.silentVol) FlxG.sound.play(Paths.sound('soundtray/'+ClientPrefs.data.volDown), 1);
	}

	function onChangeSoundUp()
	{
		if (!ClientPrefs.data.silentVol) FlxG.sound.play(Paths.sound('soundtray/'+ClientPrefs.data.volUp), 1);
	}

	function onChangeSoundMax()
	{
		if (!ClientPrefs.data.silentVol) FlxG.sound.play(Paths.sound('soundtray/'+ClientPrefs.data.volMax), 1);
	}

	override function update(e:Float)
	{
		super.update(e);
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	}

	override function beatHit()
	{
		super.beatHit();

		// FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});
	}

	override function destroy() {
		if (changedMusic) MusicManager.playMenuMusic(1);
		super.destroy();
	}
}
