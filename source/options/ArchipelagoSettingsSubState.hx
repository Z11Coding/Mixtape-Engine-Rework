package options;

class ArchipelagoSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Archipelago Settings.';
		rpcTitle = 'Archipelago Settings'; // for Discord Rich Presence

		var option:Option = new Option('Send Popup Per Note Check',
			"If checked, a popup will appear on the top right of the screen to inform you of how many checks are left.\nWARNING: NOTE THAT THE POPUPS CAN STACK BELOW EACH OTHER.", 
			'notePopup', 
			'bool');
		addOption(option);

		var option:Option = new Option('Enable Deathlink',
			"if checked, you will die if anyone else with Deathlink dies.", 'deathlink',
			'bool');
		option.onChange = function()
		{
			if (archipelago.APEntryState.inArchipelagoMode)
			{
				archipelago.APEntryState.ap.toggleDeathLink(option.getValue());
			}
		};
		addOption(option);

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

		FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});
	}
}
