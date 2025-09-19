package states;

import archipelago.APGameState;
import archipelago.APVersionSelectionState;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.util.FlxGradient;
import lime.app.Application;
import options.OptionsState;
import states.DebugStateMenu;
import states.editors.MasterEditorMenu;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
	UPRIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var mixtapeEngineVersion:String = '4.8.2'; // this is used for Discord RPC
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	private var archButton:PsychUIButton;
	var allowMouse:Bool = true; //Turn this off to block mouse movement in menus

	public var ticker:yutautil.StateTick = new yutautil.StateTick(function() {
		// trace('[DEBUG] Tick in state: ${Type.getClassName(Type.getClass(FlxG.state))}');
	}, 30);

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;
	var archipelagoItem:FlxSprite;

	var checker:FlxBackdrop;
	var gradientBar:FlxSprite;

	//Centered/Text options
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits'
	];

	var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	var rightOption:String = 'options';
	var archipelagoOption:String = #if ARCHIPELAGO_ALLOWED 'archipelago' #else null #end;

	var logoBl:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = true;
	var usingDefaultLogo:Bool = false;
	override function create()
	{

		Cursor.cursorMode = Default;
		checker = new FlxBackdrop(Paths.image('mainmenu/Main_Checker'), XY, Std.int(0.2), Std.int(0.2));

		super.create();

				if (archipelago.APEntryState.inArchipelagoMode) {
			FlxG.switchState(new archipelago.APCategoryState(archipelago.APPlayState.apGame));
		}



		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Main Menu", null);
		#end

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image(ClientPrefs.getBGImage(true)));
		if (ClientPrefs.data.menuTheme == "Dark")
			bg.color = 0xFFFDE871;
		// Simple rainbow effect for Pride Month

		if (yutautil.ExtendedDate.global().isPrideMonth() && ClientPrefs.data.allowEvents)
		{
			trace("Happy Pride Month!");
			var oldBGColor = bg.color;
			var updateRainbowBG:Void->Void;
			updateRainbowBG = function() {
				var now = Date.now();
				var t = now.getSeconds() + (now.getTime() % 1000) / 1000;
				bg.color = FlxColor.fromHSB((t * 60) % 360, 1, 1);
				if (!yutautil.ExtendedDate.instance.isPrideMonth() && ClientPrefs.data.allowEvents)
				{
					bg.color = oldBGColor; // Reset to original color if not Pride Month
					FlxG.signals.postUpdate.remove(updateRainbowBG);
				}
			};
			bg.color = FlxColor.fromHSB((Date.now().getSeconds() * 6) % 360, 1, 1);
			FlxG.signals.postUpdate.add(updateRainbowBG);
		}
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		if (!ClientPrefs.data.lowQuality)
		{
			gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55AE59E4, 0xAAFFA319], 1, 90, true);
			gradientBar.y = FlxG.height - gradientBar.height;
			add(gradientBar);
			gradientBar.scrollFactor.set(0, 0);

			add(checker);
			checker.scrollFactor.set(0, 0.07);
		}

		magenta = new FlxSprite(-80).loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		try {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				var menuSpec:AudioDisplay = new AudioDisplay(FlxG.sound.music, 0, FlxG.height, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				menuSpec.scrollFactor.set(0, 0);
				add(menuSpec);
				menuSpec.alpha = ClientPrefs.data.visOpacity;
			}
		} catch(e) {
			trace("The music broke! Preventing this from loading so the game doesn't crash");
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, (num * 140) + 90);
			item.y += (4 - optionShit.length) * 70; // Offsets for when you have anything other than 4 items
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 60, 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}

		if (archipelagoOption != null)
		{
			archipelagoItem = createMenuItemArch(archipelagoOption, FlxG.width - 60, 260);
			archipelagoItem.x -= archipelagoItem.width;
		}

		logoBl = new FlxSprite(-100, -100);
		try {
			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		} catch (e:haxe.Exception) {
			trace('[ERROR] Failed to load logoBumpin atlas: ' + e.details());
			logoBl.frames = null;
		}
		if (logoBl.frames == null) {
			logoBl.frames = Paths.getSparrowAtlas('bump');
			usingDefaultLogo = true;
		}
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		if (usingDefaultLogo) logoBl.animation.addByPrefix('bump', 'bump', 24, false);
		else logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		if (usingDefaultLogo) logoBl.setGraphicSize(Std.int(logoBl.width * 0.4));
		logoBl.updateHitbox();

		logoBl.scrollFactor.set();
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.6));
		logoBl.alpha = 0;
		logoBl.angle = -4;
		logoBl.updateHitbox();
		if (optionShit.length < 3) add(logoBl);


		FlxTween.tween(logoBl, {
			y: logoBl.y + 10,
			x: logoBl.x + 480,
			angle: -4,
			alpha: 1
		}, 1.4, {ease: FlxEase.expoInOut});

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		var mixVer:FlxText = new FlxText(fnfVer.width + 12, FlxG.height - 24, 0, "Mixtape Engine v" + mixtapeEngineVersion, 12);
		mixVer.scrollFactor.set();
		mixVer.setFormat(Paths.font("comboFont.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(mixVer);
		var funnytext:FlxText = new FlxText(mixVer.x, FlxG.height - 44, 0, "", 12);
		funnytext.scrollFactor.set();
		funnytext.setFormat(Paths.font("comboFont.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(funnytext);
		changeItem();

		#if !debug
		mixVer.text = "Mixtape Engine v" + mixtapeEngineVersion;
		#else
		mixVer.text = "Mixtape Engine v" + mixtapeEngineVersion + ' (debug)';
		#end

		if (ClientPrefs.data.username)
		{
			funnytext.text = "HI " + CoolSystemStuff.getUsername() + " :)";
		}
		else funnytext.text = "You're safe, for now...";

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		FlxG.camera.follow(camFollow, null, 0.15);
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name' + (ClientPrefs.data.menuTheme == "Dark" ? '_dark' : ''));
		menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
		menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();

		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	function createMenuItemArch(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.frames = Paths.getSparrowAtlas('mainmenu/$name' + (ClientPrefs.data.menuTheme == "Dark" ? '_dark' : ''));
		menuItem.animation.addByPrefix('idle', 'archipellego logi0000', 24, true);
		menuItem.animation.addByPrefix('selected', 'selected', 15, false);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();

		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!FlxG.sound.music.playing)
			MusicManager.playMenuMusic();

		if (FlxG.keys.justPressed.DELETE) {
			FlxG.save.data.gotIntoAnArgument = false;
			FlxG.save.data.gotbeatbattle = false;
			FlxG.save.data.gotbeatbattle2 = false;
		}

		checker.x -= 0.45 / (ClientPrefs.data.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.data.framerate / 60);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P && curColumn != RIGHT)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			var allowMouse:Bool = allowMouse;
			if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)) //FlxG.mouse.deltaScreenX/Y checks is more accurate than FlxG.mouse.justMoved
			{
				allowMouse = false;
				Cursor.show();
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
					case UPRIGHT:
						selectedItem = archipelagoItem;
				}

				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					Cursor.cursorMode = Pointer;
					allowMouse = true;
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					Cursor.cursorMode = Pointer;
					allowMouse = true;
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else if(archipelagoItem != null && FlxG.mouse.overlaps(archipelagoItem))
				{
					Cursor.cursorMode = Pointer;
					allowMouse = true;
					if(selectedItem != archipelagoItem)
					{
						curColumn = UPRIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if(FlxG.mouse.overlaps(memb))
						{
							Cursor.cursorMode = Pointer;
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								allowMouse = true;
							}
						} else Cursor.cursorMode = Default;
					}

					if(distItem != -1 && selectedItem != menuItems.members[distItem])
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) Cursor.hide();
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

					if(controls.UI_UP_P)
					{
						curColumn = UPRIGHT;
						changeItem();
					}

				case UPRIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

					if(controls.UI_DOWN_P)
					{
						curColumn = RIGHT;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				Cursor.hide();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				Cursor.hide();

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				FlxTween.tween(FlxG.camera, {zoom: 5}, 2, {ease: FlxEase.expoIn, onComplete: function(twn:FlxTween)
				{
					FlxG.camera.zoom = 1;
				}});

				new FlxTimer().start(0.2, function(tmr:FlxTimer)
				{
					hideit(1);
				});

				var item:FlxSprite;
				var option:String;
				switch(curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];

					case LEFT:
						option = leftOption;
						item = leftItem;

					case RIGHT:
						option = rightOption;
						item = rightItem;

					case UPRIGHT:
						option = archipelagoOption;
						item = archipelagoItem;
				}

				FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new CategoryState());

						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end

						#if ACHIEVEMENTS_ALLOWED
						case 'achievements':
							MusicBeatState.switchState(new AchievementsMenuState());
						#end

						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						case 'donate':
							CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
							selectedSomethin = false;
							item.visible = true;
						case 'archipelago':
							archipelago.APVersionSelectionState.smartLaunch();
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
							item.visible = true;
					}
				});

				for (memb in menuItems)
				{
					if(memb == item)
						continue;

					FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}

			// Debug State Menu access with F3 or debug_2
			if (FlxG.keys.justPressed.F3 || controls.justPressed('debug_2'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new DebugStateMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch(curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
			case UPRIGHT:
				selectedItem = archipelagoItem;
		}
		selectedItem.animation.play('selected');
		selectedItem.centerOffsets();
		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}

	function hideit(time:Float)
	{
		menuItems.forEach(function(spr:FlxSprite)
		{
			FlxTween.tween(spr, {alpha: 0.0}, time, {ease: FlxEase.quadOut});
		});
		if (!ClientPrefs.data.lowQuality)
		{
			FlxTween.tween(checker, {alpha: 0}, time, {ease: FlxEase.expoIn});
			FlxTween.tween(gradientBar, {alpha: 0}, time, {ease: FlxEase.expoIn});
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (!selectedSomethin)
		{
			FlxG.camera.zoom = zoomies;

			FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
				ease: FlxEase.quadOut
			});
		}
	}
}
