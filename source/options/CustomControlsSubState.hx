package options;

import backend.InputFormatter;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;
import flixel.input.keyboard.FlxKey;
import objects.AttachedSprite;
import objects.Note;

class CustomControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;
	var mania:Int = 18; // Default mania for custom controls

	var options:Array<Dynamic> = [];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	var gamepadColor:FlxColor = 0xfffd7194;
	var keyboardColor:FlxColor = 0xFFE6E6FA;

	// Helper function to get mania name
	function getManiaName(mania:Int):String {
		switch (mania) {
			case 0: return "one";
			case 1: return "two";
			case 2: return "three";
			case 3: return "four";
			case 4: return "five";
			case 5: return "six";
			case 6: return "seven";
			case 7: return "eight";
			case 8: return "nine";
			case 9: return "ten";
			case 10: return "eleven";
			case 11: return "twelve";
			case 12: return "thirteen";
			case 13: return "fourteen";
			case 14: return "fifteen";
			case 15: return "sixteen";
			case 16: return "seventeen";
			case 17: return "eighteen";
			default: return '${mania + 1}k'; // For anything beyond 18K
		}
	}
	var onKeyboardMode:Bool = true;

	var controllerSpr:FlxSprite;
	var titleText:Alphabet;

	public function new(targetMania:Int = 18)
	{
		super();

		this.mania = targetMania;

		// Ensure support for this mania count
		Note.ensureManiaSupport(mania);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Custom Controls Menu", null);
		#end

		// Build options for this specific mania
		buildOptions();

		bg = new FlxSprite().loadGraphic(ClientPrefs.getBGImage());
		bg.color = keyboardColor;
		bg.antialiasing = ClientPrefs.data.antialiasing;
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
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		controllerSpr = new FlxSprite(50, 40).loadGraphic(Paths.image('controllertype'), true, 82, 60);
		controllerSpr.antialiasing = ClientPrefs.data.antialiasing;
		controllerSpr.animation.add('keyboard', [0], 1, false);
		controllerSpr.animation.add('gamepad', [1], 1, false);
		add(controllerSpr);

		selectSpr = new AttachedSprite();
		selectSpr.xAdd = -30;
		selectSpr.yAdd = -1;
		selectSpr.alphaMult = 0.5;
		add(selectSpr);

		// Title text
		titleText = new Alphabet(0, 40, '${mania + 1}K Custom Controls', true);
		titleText.scaleX = 0.6;
		titleText.scaleY = 0.6;
		titleText.x = FlxG.width - titleText.width - 20;
		titleText.color = keyboardColor;
		add(titleText);

		updateOptionsDisplay();
		changeSelection();

		super.create();
	}

	private function buildOptions():Void {
		options = [];

		// Add title
		options.push([true, '${mania + 1}K CONTROLS']);
		options.push([true]);

		// Add individual key bindings
		for (i in 0...mania + 1) {
			var displayName = 'Key ${i + 1}';
			var keyName = 'note_${getManiaName(mania)}${i + 1}';
			options.push([false, displayName, keyName, displayName]);
		}

		options.push([true]);
		options.push([true, defaultKey]);
	}

	var leaving:Bool = false;
	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:AttachedSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	override function update(elapsed:Float) {
		if(!bindingKey) {
			if (FlxG.keys.justPressed.ESCAPE) {
				close();
				return;
			}

			if(FlxG.keys.justPressed.UP) changeSelection(-1);
			if(FlxG.keys.justPressed.DOWN) changeSelection(1);
			if(FlxG.keys.justPressed.LEFT) changeAlt(-1);
			if(FlxG.keys.justPressed.RIGHT) changeAlt(1);

			if(FlxG.keys.justPressed.ENTER || (FlxG.keys.justPressed.SPACE && curSelected != 0)) {
				if(curSelected >= curOptions.length || curOptions[curSelected] < 0) return;

				var optionChosen:Int = curOptions[curSelected];
				var option:Array<Dynamic> = options[optionChosen];
				if(option[0] == true) {
					if(option[1] == defaultKey) {
						ClientPrefs.resetKeysForMania(mania);
						updateOptionsDisplay();
						FlxG.sound.play(Paths.sound('cancelMenu'));
						return;
					}
					return;
				}

				bindingKey = true;
				holdingEsc = 0;
				ClientPrefs.toggleVolumeKeys(false);
				FlxG.sound.play(Paths.sound('scrollMenu'));

				var bullShit:Int = curOptions[curSelected];

				bindingBlack = new AttachedSprite();
				bindingBlack.sprTracker = grpOptions.members[curSelected];
				bindingBlack.makeGraphic(1, 1, FlxColor.WHITE);
				bindingBlack.setGraphicSize(980, 72);
				bindingBlack.updateHitbox();
				bindingBlack.color = FlxColor.BLACK;
				bindingBlack.alpha = 0.6;
				add(bindingBlack);

				bindingText = new Alphabet(0, 0, "Press any key to rebind. ESC to cancel.", false);
				bindingText.isMenuItem = true;
				bindingText.targetY = curSelected;
				bindingText.snapToPosition();
				bindingText.x += 200;
				add(bindingText);

				bindingText2 = new Alphabet(0, 0, "Hold ESC for 1 second to delete", false);
				bindingText2.isMenuItem = true;
				bindingText2.targetY = curSelected;
				bindingText2.snapToPosition();
				bindingText2.x += 200;
				bindingText2.y += 50;
				bindingText2.alpha = 0.6;
				add(bindingText2);
			}
		} else {
			if(FlxG.keys.pressed.ESCAPE) {
				holdingEsc += elapsed;
				if(holdingEsc > 1) {
					FlxG.sound.play(Paths.sound('confirmMenu'));
					deleteBinding();
				}
			} else if (FlxG.keys.justReleased.ESCAPE) {
				holdingEsc = 0;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			} else if(FlxG.keys.justPressed.ANY) {
				var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
				if(keyPressed != FlxKey.ESCAPE) {
					FlxG.sound.play(Paths.sound('confirmMenu'));
					setBinding(keyPressed);
				}
			}
		}

		if(FlxG.keys.anyJustPressed([F1])) {
			onKeyboardMode = !onKeyboardMode;
			reloadKeys();
		}

		super.update(elapsed);
	}

	function deleteBinding() {
		if(curSelected >= curOptions.length) return;

		var optionChosen:Int = curOptions[curSelected];
		var option:Array<Dynamic> = options[optionChosen];
		if(option.length < 3) return;

		var keyIndex = curSelected - 2; // Adjust for title and empty line
		if (keyIndex >= 0 && keyIndex < mania + 1) {
			ClientPrefs.setKeyForMania(mania, keyIndex, [NONE, NONE]);
		}

		closeBinding();
		updateOptionsDisplay();
	}

	function setBinding(newKey:FlxKey) {
		if(curSelected >= curOptions.length) return;

		var optionChosen:Int = curOptions[curSelected];
		var option:Array<Dynamic> = options[optionChosen];
		if(option.length < 3) return;

		var keyIndex = curSelected - 2; // Adjust for title and empty line
		if (keyIndex >= 0 && keyIndex < mania + 1) {
			var currentKeys = ClientPrefs.getKeyForMania(mania, keyIndex);
			if (!curAlt) {
				currentKeys[0] = newKey;
			} else {
				currentKeys[1] = newKey;
			}
			ClientPrefs.setKeyForMania(mania, keyIndex, currentKeys);
		}

		closeBinding();
		updateOptionsDisplay();
	}

	function closeBinding() {
		bindingKey = false;
		bindingBlack.destroy();
		remove(bindingBlack);
		bindingText.destroy();
		remove(bindingText);
		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.toggleVolumeKeys(true);
	}

	function changeSelection(change:Int = 0) {
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = curOptions.length - 1;
			if (curSelected >= curOptions.length)
				curSelected = 0;
		} while(curOptions[curSelected] < 0);

		var optionChosen:Int = curOptions[curSelected];
		var option:Array<Dynamic> = options[optionChosen];

		curAlt = false;
		updateAlt(false);

		selectSpr.sprTracker = grpOptions.members[curSelected];
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeAlt(change:Int = 0) {
		curAlt = !curAlt;
		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateAlt(doSwap:Bool = true) {
		var optionChosen:Int = curOptions[curSelected];
		var option:Array<Dynamic> = options[optionChosen];

		if(option[0] != true) {
			var keyIndex = curSelected - 2;
			if (keyIndex >= 0 && keyIndex < mania + 1) {
				var keys = ClientPrefs.getKeyForMania(mania, keyIndex);
				var chosen:FlxKey = !curAlt ? keys[0] : keys[1];
				grpBinds.members[curSelected].text = InputFormatter.getKeyName(chosen);
			}
		}
	}

	function updateOptionsDisplay() {
		grpDisplay.clear();
		grpOptions.clear();
		grpBlacks.clear();
		grpBinds.clear();

		curOptions = [];
		curOptionsValid = [];

		var num:Int = 0;
		for (i in 0...options.length) {
			var option:Array<Dynamic> = options[i];
			if(option[0] != !onKeyboardMode) {
				if(option[0] != true) {
					var keyIndex = i - 2; // Adjust for title
					if (keyIndex >= 0 && keyIndex < mania + 1) {
						var keys = ClientPrefs.getKeyForMania(mania, keyIndex);
						var chosen:FlxKey = !curAlt ? keys[0] : keys[1];

						var text1 = new Alphabet(0, 0, option[1], false);
						text1.isMenuItem = true;
						text1.targetY = num;
						text1.snapToPosition();
						grpOptions.add(text1);

						var text2 = new Alphabet(0, 0, InputFormatter.getKeyName(chosen), false);
						text2.isMenuItem = true;
						text2.targetY = num;
						text2.snapToPosition();
						text2.x += 400;
						grpBinds.add(text2);

						var black:AttachedSprite = new AttachedSprite();
						black.sprTracker = text1;
						black.makeGraphic(1, 1, FlxColor.BLACK);
						black.xAdd = -20;
						black.yAdd = -6;
						black.alphaMult = 0.4;
						black.setGraphicSize(980, 72);
						black.updateHitbox();
						grpBlacks.add(black);

						curOptions.push(i);
						curOptionsValid.push(i);
					}
				} else {
					var isCentered:Bool = false;
					var isDisplay:Bool = false;
					var text:String = option[1];
					if(text == null) text = '';

					if(text != '') {
						isCentered = true;
						isDisplay = true;
					}

					var text1 = new Alphabet(0, 0, text, !isCentered);
					text1.isMenuItem = !isDisplay;
					text1.targetY = num;
					text1.changeX = isCentered;
					text1.snapToPosition();
					if(isCentered) {
						text1.snapToPosition();
						text1.x = (FlxG.width / 2) - (text1.width / 2);
						text1.x = -200;
					}
					if(isDisplay) text1.alpha = 0.5;

					grpDisplay.add(text1);
					grpOptions.add(text1);
					curOptions.push(i);
					if(!isDisplay) curOptionsValid.push(i);
				}
				num++;
			} else {
				curOptions.push(-1);
			}
		}

		curSelected = Math.floor(FlxMath.bound(curSelected, 0, curOptionsValid.length-1));
		changeSelection();
	}

	function reloadKeys() {
		while(FlxG.keys.justPressed.ANY) FlxG.keys.reset();
		while(FlxG.keys.justReleased.ANY) FlxG.keys.reset();

		updateOptionsDisplay();
		FlxG.sound.play(Paths.sound('scrollMenu'));

		var char:String = onKeyboardMode ? 'Keyboard' : 'Gamepad';
		controllerSpr.animation.play(char.toLowerCase());

		var color:FlxColor = onKeyboardMode ? keyboardColor : gamepadColor;
		bg.color = color;
		titleText.color = color;
	}
}
