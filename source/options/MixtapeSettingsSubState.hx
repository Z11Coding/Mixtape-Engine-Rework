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
				"Kade (NA)",
				"Tabi (NA)", 
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

		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			['None', 'Breakfast', 'Tea Time', 'Celebration', 'Drippy Genesis', 'Reglitch', 'False Memory', 'Funky Genesis', 'Late Night Cafe', 'Late Night Jersey', 'Silly Little Sample Song']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		var option:Option = new Option('---MISC.---',
			"",
			'',
			LABEL);
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
		/*
		if (controls.UI_RIGHT_P)
			indeed++;
		if (controls.UI_LEFT_P)
			indeed--;
		if (indeed < 0)
			indeed = curBPMList.length - 1;
		if (indeed >= curBPMList.length)
			indeed = 0;
		*/
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
		Conductor.bpm = curBPMList[indeed];
		ClientPrefs.data.pauseBPM = curBPMList[indeed];
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
}
