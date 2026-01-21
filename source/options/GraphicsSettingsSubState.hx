package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Trash Mode', //Name
			'If checked, compresses graphics during gameplay for better performance\non older PCs. Only affects PlayState.', //Description
			'trashMode', //Save data variable name
			BOOL); //Variable type
		option.onChange = onChangeTrashMode; //Clear graphics when toggled
		addOption(option);

		var option:Option = new Option('144p Mode', //Name
			'If checked, Sets the video to', //Description
			'ultratrashMode', //Save data variable name
			BOOL); //Variable type
		option.onChange = onChangeTrashMode; //Clear graphics when toggled
		addOption(option);

		option = new Option('Wide Screen Mode',
			'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
			'wideScreen', BOOL);
		option.onChange = () -> {
			MobileScaleMode.enabled = ClientPrefs.data.wideScreen;
			FlxG.scaleMode = new MobileScaleMode();
		}
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker PCs.", //Description
			'shaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('GPU Caching', //Name
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.\n(WARNING! THIS TENDS TO BREAK THINGS AND CRASH THE GAME!\nTURN ON AT YOUR OWN RISK!)", //Description
			'cacheOnGPU',
			BOOL);
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			INT);
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 1;
		option.maxValue = 1000;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		var option:Option = new Option('Max FPS', //Name
			"If checked, the FPS limit will be set to 1000.\nThis setting makes the input timing more accurate, but in cost of minor graphical issues.", //Description
			'unlockFramerate',
			BOOL);
		option.onChange = onChangeFramerate;
		addOption(option);

		var option:Option = new Option('FPS Rework',
			"If checked, this works around the game becoming \"slow\" and \"smooth\" when the current FPS is lower than the FPS cap.",
			'fpsRework',
			BOOL);
		addOption(option);
		#end

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.unlockFramerate) {
			FlxG.updateFramerate = 1000;
			FlxG.drawFramerate = 1000;
			return;
		}

		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			if (ClientPrefs.data.fpsRework)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;
			else
			{
				FlxG.updateFramerate = ClientPrefs.data.framerate;
				FlxG.drawFramerate = ClientPrefs.data.framerate;
			}
		}
		else
		{
			if (ClientPrefs.data.fpsRework)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;
			else
			{
				FlxG.drawFramerate = ClientPrefs.data.framerate;
				FlxG.updateFramerate = ClientPrefs.data.framerate;
			}
		}
	}

	function onChangeTrashMode()
	{
		// Clear all cached graphics when trash mode is toggled
		// This ensures that the compression setting takes effect immediately
		for (effect in MusicBeatState.effectArray) {
			if (!ClientPrefs.data.ultratrashMode && effect != null) {
				effect.removeFilter(FlxG.sound.music);
				effect.clearEffects(true);
				remove(effect);
				effect.destroy();
			}
		}
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		Paths.freeGraphicsFromMemory();
		trace('Graphics cleared due to Trash Mode toggle. New setting: ${ClientPrefs.data.trashMode}');
		MusicBeatState.resetState();
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
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
