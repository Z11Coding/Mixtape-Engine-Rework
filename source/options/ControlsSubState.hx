package options;

import backend.InputFormatter;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import objects.AttachedSprite;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	//Show on gamepad - Display name - Save file key - Rebind display name
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[false, '1 KEY'],
		[false, 'Center', 'note_one1'],
		[false],
		[false, '2 KEYS'],
		[false, 'Left',  'note_two1'],
		[false, 'Right', 'note_two2'],
		[false],
		[false, '3 KEYS'],
		[false, 'Left',   'note_three1'],
		[false, 'Center', 'note_three2'],
		[false, 'Right',  'note_three3'],
		[false],
		[false, '4 KEYS'],
		[false, 'Left',  'note_left'],
		[false, 'Down',  'note_down'],
		[false, 'Up', 	  'note_up'],
		[false, 'Right', 'note_right'],
		[false],
		[false, '5 KEYS'],
		[false, 'Left', 	'note_five1'],
		[false, 'Down', 	'note_five2'],
		[false, 'Center',  'note_five3'],
		[false, 'Up', 	  	'note_five4'],
		[false, 'Right', 	'note_five5'],
		[false],
		[false, '6 KEYS'],
		[false, 'Left 1', 	'note_six1'],
		[false, 'Up', 		'note_six2'],
		[false, 'Right 1', 'note_six3'],
		[false, 'Left 2', 	'note_six4'],
		[false, 'Down', 	'note_six5'],
		[false, 'Right 2', 'note_six6'],
		[false],
		[false, '7 KEYS'],
		[false, 'Left 1',  'note_seven1'],
		[false, 'Up', 		'note_seven2'],
		[false, 'Right 1', 'note_seven3'],
		[false, 'Center',  'note_seven4'],
		[false, 'Left 2',  'note_seven5'],
		[false, 'Down', 	'note_seven6'],
		[false, 'Right 2', 'note_seven7'],
		[false],
		[false, '8 KEYS'],
		[false, 'Left 1',  'note_eight1'],
		[false, 'Down 1',  'note_eight2'],
		[false, 'Up 1', 	'note_eight3'],
		[false, 'Right 1', 'note_eight4'],
		[false, 'Left 2',  'note_eight5'],
		[false, 'Down 2',  'note_eight6'],
		[false, 'Up 2', 	'note_eight7'],
		[false, 'Right 2', 'note_eight8'],
		[false],
		[false, '9 KEYS'],
		[false, 'Left 1',  'note_nine1'],
		[false, 'Down 1',  'note_nine2'],
		[false, 'Up 1',    'note_nine3'],
		[false, 'Right 1', 'note_nine4'],
		[false, 'Center',  'note_nine5'],
		[false, 'Left 2',  'note_nine6'],
		[false, 'Down 2',  'note_nine7'],
		[false, 'Up 2',    'note_nine8'],
		[false, 'Right 2', 'note_nine9'],
		[false],
		[false, 'Good Luck With These'],
		[false],
		[false, '10 KEYS'],
		[false, 'Left 1',  'note_ten1'],
		[false, 'Down 1',  'note_ten2'],
		[false, 'Up 1', 	'note_ten3'],
		[false, 'Right 1', 'note_ten4'],
		[false, 'Center 1','note_ten5'],
		[false, 'Center 2','note_ten6'],
		[false, 'Left 2',  'note_ten7'],
		[false, 'Down 2',  'note_ten8'],
		[false, 'Up 2', 	'note_ten9'],
		[false, 'Right 2', 'note_ten10'],
		[false, '11 KEYS'],
		[false, 'Left 1',  'note_elev1'],
		[false, 'Down 1',  'note_elev2'],
		[false, 'Up 1',    'note_elev3'],
		[false, 'Right 1', 'note_elev4'],
		[false, 'Down 3',  'note_elev5'],
		[false, 'Center',  'note_elev6'],
		[false, 'Up 3', 	'note_elev7'],
		[false, 'Left 2',  'note_elev8'],
		[false, 'Down 2',  'note_elev9'],
		[false, 'Up 2', 	'note_elev10'],
		[false, 'Right 2', 'note_elev11'],
		[false],
		[false, 'Oh, And These Too'],
		[false],
		[false, '12 KEYS'],
		[false, 'Left 1', 	'note_twel1'],
		[false, 'Down 1', 	'note_twel2'],
		[false, 'Up 1', 	'note_twel3'],
		[false, 'Right 1', 'note_twel4'],
		[false, 'Left 2', 	'note_twel5'],
		[false, 'Down 2', 	'note_twel6'],
		[false, 'Up 2', 	'note_twel7'],
		[false, 'Right 2', 'note_twel8'],
		[false, 'Left 3', 	'note_twel9'],
		[false, 'Down 3', 	'note_twel10'],
		[false, 'Up 3', 	'note_twel11'],
		[false, 'Right 3', 'note_twel12'],
		[false],
		[false, '13 KEYS'],
		[false, 'Left 1', 'note_thir1'],
		[false, 'Down 1', 'note_thir2'],
		[false, 'Up 1', 'note_thir3'],
		[false, 'Right 1', 'note_thir4'],
		[false, 'Left 2', 'note_thir5'],
		[false, 'Down 2', 'note_thir6'],
		[false, 'Center', 'note_thir7'],
		[false, 'Up 2', 'note_thir8'],
		[false, 'Right 2', 'note_thir9'],
		[false, 'Left 3', 'note_thir10'],
		[false, 'Down 3', 'note_thir11'],
		[false, 'Up 3', 'note_thir12'],
		[false, 'Right 3', 'note_thir13'],
		[false],
		[false, '14 KEYS'],
		[false, 'Left 1', 	'note_fort1'],
		[false, 'Down 1', 	'note_fort2'],
		[false, 'Up 1', 	'note_fort3'],
		[false, 'Right 1', 'note_fort4'],
		[false, 'Center 1','note_fort5'],
		[false, 'Left 2',  'note_fort6'],
		[false, 'Down 2',  'note_fort7'],
		[false, 'Up 2', 	'note_fort8'],
		[false, 'Right 2', 'note_fort9'],
		[false, 'Center 2','note_fort10'],
		[false, 'Left 3', 	'note_fort11'],
		[false, 'Down 3', 	'note_fort12'],
		[false, 'Up 3', 	'note_fort13'],
		[false, 'Right 3', 'note_fort14'],
		[false],
		[false, '15 KEYS'],
		[false, 'Left 1', 'note_fift1'],
		[false, 'Down 1', 'note_fift2'],
		[false, 'Up 1', 'note_fift3'],
		[false, 'Right 1', 'note_fift4'],
		[false, 'Left 2', 'note_fift5'],
		[false, 'Down 2', 'note_fift6'],
		[false, 'Center 1', 'note_fift7'],
		[false, 'Center 2', 'note_fift8'],
		[false, 'Center 3', 'note_fift9'],
		[false, 'Up 2', 'note_fift10'],
		[false, 'Right 2', 'note_fift11'],
		[false, 'Left 3', 'note_fift12'],
		[false, 'Down 3', 'note_fift13'],
		[false, 'Up 3', 'note_fift14'],
		[false, 'Right 3', 'note_fift15'],
		[false],
		[false, '16 KEYS'],
		[false, 'Left 1', 'note_sixt1'],
		[false, 'Down 1', 'note_sixt2'],
		[false, 'Up 1', 'note_sixt3'],
		[false, 'Right 1', 'note_sixt4'],
		[false, 'Left 2', 'note_sixt5'],
		[false, 'Down 2', 'note_sixt6'],
		[false, 'Up 2', 'note_sixt7'],
		[false, 'Right 2', 'note_sixt8'],
		[false, 'Left 3', 'note_sixt9'],
		[false, 'Down 3', 'note_sixt10'],
		[false, 'Up 3', 'note_sixt11'],
		[false, 'Right 3', 'note_sixt12'],
		[false, 'Left 4', 'note_sixt13'],
		[false, 'Down 4', 'note_sixt14'],
		[false, 'Up 4', 'note_sixt15'],
		[false, 'Right 4', 'note_sixt16'],
		[false],
		[false, '17 KEYS'],
		[false, 'Left 1', 'note_sevt1'],
		[false, 'Down 1', 'note_sevt2'],
		[false, 'Up 1', 'note_sevt3'],
		[false, 'Right 1', 'note_sevt4'],
		[false, 'Left 2', 'note_sevt5'],
		[false, 'Down 2', 'note_sevt6'],
		[false, 'Up 2', 'note_sevt7'],
		[false, 'Right 2', 'note_sevt8'],
		[false, 'Center', 'note_sevt9'],
		[false, 'Left 3', 'note_sevt10'],
		[false, 'Down 3', 'note_sevt11'],
		[false, 'Up 3', 'note_sevt12'],
		[false, 'Right 3', 'note_sevt13'],
		[false, 'Left 4', 'note_sevt14'],
		[false, 'Down 4', 'note_sevt15'],
		[false, 'Up 4', 'note_sevt17'],
		[false, 'Right 4', 'note_sevt17'],
		[false],
		[false, '18 KEYS'],
		[false, 'Left 1', 	'note_ate1'],
		[false, 'Down 1', 	'note_ate2'],
		[false, 'Up 1',   	'note_ate3'],
		[false, 'Right 1',	'note_ate4'],
		[false, 'Left 2', 	'note_ate5'],
		[false, 'Down 2', 	'note_ate6'],
		[false, 'Up 2',   	'note_ate7'],
		[false, 'Right 2',	'note_ate8'],
		[false, 'Space 1',	'note_ate9'],
		[false, 'Space 2',	'note_ate10'],
		[false, 'Left 3', 	'note_ate11'],
		[false, 'Down 3', 	'note_ate12'],
		[false, 'Up 3', 	'note_ate13'],
		[false, 'Right 3', 'note_ate14'],
		[false, 'Left 4', 	'note_ate15'],
		[false, 'Down 4', 	'note_ate16'],
		[false, 'Up 4', 	'note_ate17'],
		[false, 'Right 4', 'note_ate18'],
		[true, 'Left', 'note_left', 'Note Left'],
		[true, 'Down', 'note_down', 'Note Down'],
		[true, 'Up', 'note_up', 'Note Up'],
		[true, 'Right', 'note_right', 'Note Right'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2'],
		[false],
		[false, 'Extras'],
		[false, 'FullScreen', 'fullscreen', 'Fullscreen'],
		[true,  'Sidebar',    'sidebar',    'Sidebar'],
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	var gamepadColor:FlxColor = 0xff7543ff;
	var keyboardColor:FlxColor = 0xffff9924;
	var onKeyboardMode:Bool = true;
	
	var controllerSpr:FlxSprite;
	
	public function new()
	{
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Controls Menu", null);
		#end

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = keyboardColor;
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.screenCenter();
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		controllerSpr = new FlxSprite(50, 40).loadGraphic(Paths.image('controllertype'), true, 82, 60);
		controllerSpr.antialiasing = ClientPrefs.data.globalAntialiasing;
		controllerSpr.animation.add('keyboard', [0], 1, false);
		controllerSpr.animation.add('gamepad', [1], 1, false);
		add(controllerSpr);

		var text:Alphabet = new Alphabet(60, 90, 'CTRL', false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);

		createTexts();
	}

	var lastID:Int = 0;
	function createTexts()
	{
		curOptions = [];
		curOptionsValid = [];
		grpDisplay.forEachAlive(function(text:Alphabet) text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite) black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet) text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet) text.destroy());
		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;
		for (i => option in options)
		{
			if(onKeyboardMode || option[0])
			{
				if(option.length > 1)
				{
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey);

					var str:String = option[1];
					var keyStr:String = option[2];
					if(isDefaultKey) str = Language.getPhrase(str);
					var text:Alphabet = new Alphabet(200, 300, !isDisplayKey ? Language.getPhrase('key_$keyStr', str) : Language.getPhrase('keygroup_$str', str), !isDisplayKey);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					if(isDisplayKey)
						grpDisplay.add(text);
					else {
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);
					}
					text.ID = myID;
					lastID = myID;

					if(isCentered) addCenteredText(text, option, myID);
					else addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.screenCenter(X);
		text.y -= 55;
		text.startPosition.y -= 55;
	}
	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		for (n in 0...2)
		{
			var textX:Float = 350 + n * 300;

			var key:String = null;
			if(onKeyboardMode)
			{
				var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
				key = InputFormatter.getKeyName((savKey[n] != null) ? savKey[n] : NONE);
			}
			else
			{
				var savKey:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option[2]);
				key = InputFormatter.getGamepadName((savKey[n] != null) ? savKey[n] : NONE);
			}

			var attach:Alphabet = new Alphabet(textX + 210, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			playstationCheck(attach);
			attach.scaleX = Math.min(1, 230 / attach.width);
			//attach.text = key;

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -6;
			black.xAdd = textX;
			grpBlacks.add(black);
		}
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(onKeyboardMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];
		if(model == PS4)
		{
			switch(alpha.text)
			{
				case '[', ']': //Square and Triangle respectively
					letter.image = 'alphabet_playstation';
					letter.updateHitbox();
					
					letter.offset.x += 4;
					letter.offset.y -= 5;
			}
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;
		
		playstationCheck(attach);
		attach.scaleX = Math.min(1, 230 / attach.width);
		//attach.text = text;

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	var timeForMoving:Float = 0.1;
	override function update(elapsed:Float)
	{
		if(timeForMoving > 0) //Fix controller bug
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if(!binding)
		{
			if(FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(B))
			{
				close();
				return;
			}
			if(FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(RIGHT_SHOULDER)) swapMode();

			if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_LEFT) || FlxG.gamepads.anyJustPressed(DPAD_RIGHT) ||
				FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT)) updateAlt(true);

			if(FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP)) updateText(-1);
			else if(FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN)) updateText(1);

			if(FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(START) || FlxG.gamepads.anyJustPressed(A))
			{
				if(options[curOptions[curSelected]][1] != defaultKey)
				{
					bindingBlack = new FlxSprite().makeGraphic(1, 1, /*FlxColor.BLACK*/ FlxColor.WHITE);
					bindingBlack.scale.set(FlxG.width, FlxG.height);
					bindingBlack.updateHitbox();
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
					add(bindingBlack);

					bindingText = new Alphabet(FlxG.width / 2, 160, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [options[curOptions[curSelected]][3]]), false);
					bindingText.alignment = CENTERED;
					add(bindingText);
					
					bindingText2 = new Alphabet(FlxG.width / 2, 340, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'), true);
					bindingText2.alignment = CENTERED;
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
				{
					// Reset to Default
					ClientPrefs.resetKeys(!onKeyboardMode);
					ClientPrefs.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
		else
		{
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];
			if(FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
			{
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
			{
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, onKeyboardMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else
			{
				holdingEsc = 0;
				var changed:Bool = false;
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);
				var curButtons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(curOption[2]);

				if(onKeyboardMode)
				{
					if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
					{
						var keyPressed:Int = FlxG.keys.firstJustPressed();
						var keyReleased:Int = FlxG.keys.firstJustReleased();
						if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
						{
							curKeys[altNum] = keyPressed;
							changed = true;
						}
						else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
						{
							curKeys[altNum] = keyReleased;
							changed = true;
						}
					}
				}
				else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
				{
					var keyPressed:Null<FlxGamepadInputID> = NONE;
					var keyReleased:Null<FlxGamepadInputID> = NONE;
					if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
					else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
					else
					{
						for (i in 0...FlxG.gamepads.numActiveGamepads)
						{
							var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
							if(gamepad != null)
							{
								keyPressed = gamepad.firstJustPressedID();
								keyReleased = gamepad.firstJustReleasedID();

								if(keyPressed == null) keyPressed = NONE;
								if(keyReleased == null) keyReleased = NONE;
								if(keyPressed != NONE || keyReleased != NONE) break;
							}
						}
					}

					if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
					{
						curButtons[altNum] = keyPressed;
						changed = true;
					}
					else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
					{
						curButtons[altNum] = keyReleased;
						changed = true;
					}
				}

				if(changed)
				{
					if (onKeyboardMode)
					{
						if(curKeys[altNum] == curKeys[1 - altNum])
							curKeys[1 - altNum] = FlxKey.NONE;
					}
					else
					{
						if(curButtons[altNum] == curButtons[1 - altNum])
							curButtons[1 - altNum] = FlxGamepadInputID.NONE;
					}

					var option:String = options[curOptions[curSelected]][2];
					ClientPrefs.clearInvalidKeys(option);
					for (n in 0...2)
					{
						var key:String = null;
						if(onKeyboardMode)
						{
							var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
							key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
						}
						else
						{
							var savKey:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option);
							key = InputFormatter.getGamepadName(savKey[n] != null ? savKey[n] : NONE);
						}
						updateBind(Math.floor(curSelected * 2) + n, key);
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}
		super.update(elapsed);
	}

	function closeBinding()
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?move:Int = 0)
	{
		if(move != 0)
		{
			//var dir:Int = Math.round(move / Math.abs(move));
			curSelected += move;

			if(curSelected < 0) curSelected = curOptions.length - 1;
			else if (curSelected >= curOptions.length) curSelected = 0;
		}

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if(num < 3) addNum = 3 - num;
		else if(num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet) {
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});
		grpBinds.forEachAlive(function(item:Alphabet)
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	var colorTween:FlxTween;
	function swapMode()
	{
		if(colorTween != null) colorTween.destroy();
		colorTween = FlxTween.color(bg, 0.5, bg.color, onKeyboardMode ? gamepadColor : keyboardColor, {ease: FlxEase.linear});
		onKeyboardMode = !onKeyboardMode;

		curSelected = 0;
		curAlt = false;
		controllerSpr.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');
		createTexts();
	}

	function updateAlt(?doSwap:Bool = false)
	{
		if(doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}
}