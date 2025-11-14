package options;
import states.freeplay.vslice.PlayerRegistry;
class MixtapeSettingsSubState extends BaseOptionsMenu
{
	public static var curBPMList:Array<Int> =  [0, 160, 160, 88, 160, 90, 105, 130, 100, 160, 180, 100, 125, 170, 140];
	var perfOpt:Option;
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
			"Switch how the health bar works",
			'healthMode',
			STRING,
			[
				"OG",
				"Mixtape",
				"Kade",
				"Tabi",
				"Double",
				"Lives",
				"Lives + HealthBar",
				"Random",
			]);
		if (Achievements.isUnlocked('freaky_bar'))
			option.options.insert(7, "Amalgam");
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Icon Bop',
			"How do you prefer the icons to bop",
			'iconBounce',
			STRING,
			[
				"Base",
				"Mixtape",
				"Dave and Bambi",
				"Old Psych",
				"Strident Crisis",
				"Plank Engine",
				"Golden Apple",
				"VS Steve",
			]);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Chart Preload',
			"How do you prefer the charts load?",
			'chartPreload',
			STRING,
			[
				"Off",
				"No Threadding",
				"On"
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
			"Troll Engine"
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

		var option:Option = new Option('No Antimash',
			"If checked, Antimash will be disabled. (Does nothing...for now...)\n(dont worry there is no antimashing...yet...)", 'noAntimash', BOOL);
		addOption(option);

		var option:Option = new Option(
			'Optimized Holds',
			"If checked, smooth holds will have fewer calls to the modchart system for position info.\nBest to leave this on, unless you have a high-end PC and require the highest accuracy rendering for, some reason.",
			'optimizeHolds',
			BOOL
		);
		addOption(option);

		var option:Option = new Option('Hold Subdivisions',
			"How many divisions are in a hold note with smooth holds.\nMore means smoother holds, but more of a performance hit.",
			'holdSubdivs',
			INT
		);
		option.displayFormat = '%v';
		option.changeValue = 1;
		option.minValue = 1;
		option.maxValue = 8;
		option.scrollSpeed = 20;
		addOption(option);

		var option:Option = new Option('Draw Dist. Mult',
			"A multiplier to note's draw distance. Higher number means notes can be seen from further away, less means closer.\nNote that with higher numbers, draw distance is still capped by the spawn distance (which is only modifiable by modcharts) so it's only recommended to lower this value for low-end PCs.\nKEEP IN MIND, ANYTHING PAST X2 IS UNTESTED AND WILL MOST LIKELY BREAK SOMETHING!\nYOU HAVE BEEN WARNED!!!",
			'drawDistanceModifier',
			FLOAT);
		option.displayFormat = 'x%v';
		option.decimals = 1;
		option.changeValue = 0.1;
		option.minValue = 0.8;
		option.maxValue = 10;
		option.scrollSpeed = 20;
		addOption(option);

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

		var option:Option = new Option('Show Keybinds on Start Song',
			"If checked, your keybinds will be shown on the strum that they correspond to when you start a song.",
			'showKeybindsOnStart',
			BOOL);
		addOption(option);

		var option:Option = new Option('In-Game Rating',
			"If checked, the ratings will be in-game instead of on the hud.",
			'inGameRatings',
			BOOL);
		addOption(option);

		var option:Option = new Option('Start Hidden',
			"If checked, the hud will be invisible during the countdown.",
			'startHidden',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Rendered Text',
			"If checked, adds text that shows\nthe amount of notes loaded currently/Max amount of notes loaded total/Max amount of notes currently in the notes array.",
			'showRenderText',
			BOOL);
		addOption(option);

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

		var option:Option = new Option('---FREEPLAY---',
			"",
			'',
			LABEL);
		addOption(option);

		var freemenus:Array<String> = ['Mixtape', 'Osu', 'Base Game'];
		//for (theme in Mods.mergeAllTextsNamed('menus/'))
		var option:Option = new Option('Freeplay Menu:',
			"Which freeplay menu do you prefer?\n(This has no effect on Archipelago Mode)\nBase Game: V-Slice style menu with enhanced features",
			'freeplayMenu',
			STRING,
			freemenus);
		addOption(option);
		option.displayFormat = '< %v >';

		var playerIds:Array<String> = PlayerRegistry.instance.listAllEntryIds();
		var option:Option = new Option('DJ Character:',
			"Which freeplay DJ do you prefer?\n(This has no effect on Archipelago Mode)",
			'djCharacter',
			STRING,
			playerIds);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('---MENUS---',
			"",
			'',
			LABEL);
		addOption(option);

		var option:Option = new Option('Chart Editor Style',
			"Choose the style of the chart editor.\nNew: Modern Psych Engine editor\nOld: Original chart editor\nMixtape: Advanced editor with Archipelago-style UI, animations, and analytics",
			'chartEditorStyle',
			STRING,
			[
				'New',
				'Old',
				'Mixtape'
			]);
		addOption(option);
		option.displayFormat = '< %v >';

		var loadingThemes:Array<String> = ['Psych', 'Mixtape'];
		var option:Option = new Option('Loading Screen Theme:',
			"Which loading screen theme do you prefer?\nPsych: The classic loading screen\nMixtape: A new loading screen based on the splash screen with animated logo",
			'loadingScreenTheme',
			STRING,
			loadingThemes);
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
			['None', 'Breakfast', 'Breakfast (Pixel)', 'Breakfast (Pico)', 'girlfriendsRingtone', 'stayFunky', 'Tea Time', 'Celebration', 'Drippy Genesis', 'Reglitch', 'False Memory', 'Funky Genesis', 'Late Night Cafe', 'Late Night Jersey', 'Silly Little Sample Song']);
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

		var option:Option = new Option('Menu Theme',
			"Select the theme you want to use\n(Has not effect on the chart editor theme)",
			'menuTheme',
			STRING,
			["Light", "Dark"]);
		option.displayFormat = '< %v >';
		option.onChange = function() {if (ClientPrefs.data.menuTheme == "Dark") Achievements.unlock('much_better');};
		addOption(option);

		var option:Option = new Option('---MISC.---',
			"",
			'',
			LABEL);
		addOption(option);

		var option = new Option('Wide Screen Mode',
			'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
			'wideScreen', BOOL);
		option.onChange = () -> MobileScaleMode.enabled = ClientPrefs.data.wideScreen;
		addOption(option);

		var option:Option = new Option('Enable Garbage Collection',
			"If checked, Your memory usage will be normalized, but you'll have lag spikes.\nBut, unchecked, little to no lag spikes, but higher average memory usage.",
			'garbageCollection',
			BOOL);
		option.onChange = function() {MemoryUtil.init();};
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
			BOOL
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

		var option:Option = new Option('Enable Time-Specific Events',
			"If checked, things that are day/month related (Pride Month, Christmas, etc.) will be turned off.\n(ANY SONGS THAT ARE SPECIFIC TO AN EVENT/HOLIDAY WILL ALWAYS BE ABLE AVAILABLE IF THIS IS TURNED OFF!).",
			'allowEvents',
			BOOL);
		addOption(option);

		var option:Option = new Option(
			'Loading Preference: ',
			"When a song is loading, select how much to load.",
			'loadingState',
			STRING,
			[
			"Nothing",
			"Song Only",
			"Everything"]
		);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Enable Artemis', // even tho only one person asked, it here
			"Got An RGB Keyboard Like A Razer Cynosa Chroma Gaming Keyboard?\n
			Turn This Bad Boy On To Get Your Keyboard In The Action Too!\n
			(YOU MUST HAVE ARTEMIS INSTALLED AND THE PROFILE SET TO MIXTAPE FOR IT TO WORK!)\n
			(YOU WILL BE SENT TO THE TITLE SCREEN WHEN YOU LEAVE IF THIS IS ON!)", 'enableArtemis', BOOL);
		//addOption(option); maybe one day
		var option:Option = new Option('---EXPERIMENTAL---',
			"These settings are experimental and may not work correctly!",
			'',
			LABEL);
		addOption(option);

		var option:Option = new Option('Use Experimental Note Pool',
			"If checked, all notes will be generated and managed through an optimized NotePool system for better performance.\nWARNING: This is experimental and may cause issues!",
			'useExperimentalNotePool',
			BOOL);
		addOption(option);
		option.onChange = onChangeExperimentalNotePool;

		var option:Option = new Option('---DEBUG---',
			"",
			'',
			LABEL);

		addOption(option);



		var option:Option = new Option('Disable Debug Traces',
			"If checked, debug trace outputs will be disabled for better performance.",
			'disableDebugTraces',
			BOOL);
		addOption(option);

		var option:Option = new Option('Disable Haxe Traces',
			"If checked, Haxe trace() function calls will be disabled for better performance.",
			'disableHaxeTraces',
			BOOL);
		addOption(option);

		var option:Option = new Option('Trace Mode',
			"Choose where traces appear: Console (traditional), Game (in-game viewer), or Both",
			'traceMode',
			STRING,
			['CONSOLE', 'GAME', 'BOTH']);
		addOption(option);
		option.displayFormat = '< %v >';

		var option:Option = new Option('Max In-Game Traces',
			"Maximum number of traces to keep in the in-game viewer (higher = more memory)",
			'maxInGameTraces',
			INT
		);
		option.displayFormat = '%v traces';
		option.changeValue = 10;
		option.minValue = 50;
		option.maxValue = 500;
		option.scrollSpeed = 20;
		addOption(option);

		var option:Option = new Option('Performance Counter', 'Toggle through the options for your performance counter', 'performanceCounter', STRING,
			['hide', 'fps', 'fps-mem', 'fps-mem-peak']);
		addOption(option);
		option.onChange = function()
		{
			onChangePerformanceCounter();
			switch (ClientPrefs.data.performanceCounter)
			{
				case 'hide':
					{
						option.text = 'Hide FPS';
					}
				case 'fps':
					{
						option.text = 'FPS Only';
					}
				case 'fps-mem':
					{
						option.text = 'FPS With Memory';
						@:privateAccess
						{
							for (i in 0...option.text.length)
							{
								if (option.child.members[i] != null)
								{
									if (i >= 7)
									{
										option.child.members[i].y += 40;
										option.child.members[i].x -= 280;
									}
									else
										option.child.members[i].y -= 15;
								}
							}
						}
					}
				case 'fps-mem-peak':
					{
						option.text = 'FPS With Memory Peak';
						@:privateAccess
						{
							for (i in 0...option.text.length)
							{
								if (option.child.members[i] != null)
								{
									if (i >= 7)
									{
										option.child.members[i].y += 40;
										option.child.members[i].x -= 360;
									}
									else
										option.child.members[i].y -= 15;
								}
							}
						}
					}
			}
		};

		perfOpt = option;

		var option:Option = new Option('Show Rendered Text',
			"If checked, debug information about rendered objects will be displayed during gameplay.",
			'showRenderedText',
			BOOL);
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

		var option:Option = new Option('AP Server Compression',
		'Tell the Engine to ask for compressed data. (WIP)',
		'apCompressed', BOOL);
		addOption(option);

		if (Sys.args().indexOf('-livereload') != -1)
		{

			var option:Option = new Option('---Compiler Options---', '', '', LABEL);
			addOption(option);

			var option:Option = new Option('Assess Initial Memory',
				"Checks the initial memory usage of the game.",
				'showInitialMemoryUsage',
				BOOL);
			addOption(option);

			var option:Option = new Option('Show CMD Progress',
				"Shows the progress of the memory usage in the command line.",
				'showProgressInCMD',
				BOOL);
			addOption(option);

			var option:Option.EnumOption<yutautil.CollectionUtils.Size> = new Option.EnumOption<yutautil.CollectionUtils.Size>('Size Accuracy',
				"Sets the accuracy of the size measurement.",
				'SizeAccuracy',
				yutautil.CollectionUtils.Size
			);
			addOption(option);

		}

		super();
	}

	function onChangePerformanceCounter()
	{
		if (Main.fpsVar != null)
		{
			Main.fpsVar.visible = true;
			switch (ClientPrefs.data.performanceCounter)
			{
				case 'hide':
					Main.fpsVar.visible = false;
			}
			Main.fpsVar.forceUpdateText = true;
		}
	}

	var changedMusic:Bool = false;
	var indeed:Int = 0;
	function onChangePauseMusic()
	{
		//TODO: find a better way to do this lol
		switch (ClientPrefs.data.pauseMusic)
		{
			case 'None':
				indeed = 0;
			case 'Breakfast':
				indeed = 1;
			case 'Breakfast (Pixel)':
				indeed = 2;
			case 'Breakfast (Pico)':
				indeed = 3;
			case 'girlfriendsRingtone':
				indeed = 4;
			case 'stayFunky':
				indeed = 5;
			case 'Tea Time':
				indeed = 6;
			case 'Celebration':
				indeed = 7;
			case 'Drippy Genesis':
				indeed = 8;
			case 'Reglitch':
				indeed = 9;
			case 'False Memory':
				indeed = 10;
			case 'Funky Genesis':
				indeed = 11;
			case 'Late Night Cafe':
				indeed = 12;
			case 'Late Night Jersey':
				indeed = 13;
			case 'Silly Little Sample Song':
				indeed = 14;
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

		if (perfOpt != null)
			perfOpt.onChange();
	}

	override function beatHit()
	{
		super.beatHit();

		// FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});
	}

	function onChangeExperimentalNotePool()
	{
		if (ClientPrefs.data.useExperimentalNotePool) {
			// Update pool settings when enabled
			managers.NotePoolManager.updatePoolSettings();
			trace('Experimental NotePool enabled');
		} else {
			trace('Experimental NotePool disabled');
		}
	}

	override function destroy() {
		if (changedMusic) MusicManager.playMenuMusic(1);
		super.destroy();
	}
}
