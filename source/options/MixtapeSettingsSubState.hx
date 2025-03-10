package options;

class MixtapeSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Mixtape Settings.';
		rpcTitle = 'Mixtape Settings'; // for Discord Rich Presence

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
			"BEAT! Engine", 
			"Kade Engine", 
			"ZoroForce EK", 
			"Mic'ed Up Engine", 
			"Andromeda Engine (legacy)",
			"YoshiEngine",
			"Kade Engine Community",
			"Rhythm"
		]);
		addOption(option);
		option.displayFormat = '< %v >';

		super();
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
