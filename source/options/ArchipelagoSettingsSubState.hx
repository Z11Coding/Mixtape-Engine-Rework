package options;

class ArchipelagoSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Archipelago Settings.';
		rpcTitle = 'Archipelago Settings'; // for Discord Rich Presence

		// var option:Option = new Option('Send Popup Per Note Check',
		// 	"If checked, a popup will appear on the top right of the screen to inform you of how many checks are left.\nWARNING: NOTE THAT THE POPUPS CAN STACK BELOW EACH OTHER.",
		// 	'notePopup',
		// 	'bool');
		// addOption(option);

		var option:Option = new Option('Enable Deathlink',
			"if checked, you will die if anyone else with Deathlink dies.",
			'deathlink',
			BOOL);
		option.onChange = function()
		{
			if (archipelago.APInfo.inArchipelagoMode)
			{
				archipelago.APInfo.ap.toggleDeathLink(option.getValue());
				ClientPrefs.data.deathlink = option.getValue(); // Fixed: was incorrectly setting traplink
				ClientPrefs.saveSettings(); // Ensure settings are saved immediately
			}
		};
		addOption(option);

		var option:Option = new Option('Enable Trap Link',
			"if checked, you will be affected by traps that other players activate.",
			'traplink',
			BOOL);
		option.onChange = function()
		{
			if (archipelago.APInfo.inArchipelagoMode)
			{
				archipelago.APInfo.ap.toggleTrapLink(option.getValue());
				ClientPrefs.data.traplink = option.getValue();
				ClientPrefs.saveSettings(); // Ensure settings are saved immediately
			}
		};
		addOption(option);

		var noticeStyleOption:Option = new Option('Notice Style',
			"Choose the style of popup notifications for Archipelago items.\nNotification: Simple alert dialog\nAchievement: Psych Achievement-style popup",
			'apNoticeStyle',
			STRING,
			["Notification", "Achievement"]);
		addOption(noticeStyleOption);

		var itemTextureOption:Option = new Option('Item Textures on Notes',
			"If checked, Archipelago check notes will display item sprites from the corresponding game instead of the default AP note texture.",
			'apNoteItemTextures',
			BOOL);
		itemTextureOption.onChange = function()
		{
			ClientPrefs.data.apNoteItemTextures = itemTextureOption.getValue();
			ClientPrefs.saveSettings();
		};
		addOption(itemTextureOption);

		var flip:Option = new Option('Flip Screen',
			"if checked, the screen will be flipped upside down.\nWARNING: THIS MAY CAUSE ISSUES WITH THE GAME.",
			'flipScreen',
			BOOL);
		flip.onChange = function()
		{
			if (archipelago.APInfo.inArchipelagoMode)
			{
				var targetAngle = flip.getValue() ? 180 : 0;
				FlxTween.tween(FlxG.camera, {angle: targetAngle}, 0.5, {
					ease: FlxEase.quadOut
				});
				backend.MusicBeatState.APFlip = flip.getValue();
			}
		};
		addOption(flip);

		super();
	}

	override function update(e:Float)
	{
		super.update(e);
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	}
}
