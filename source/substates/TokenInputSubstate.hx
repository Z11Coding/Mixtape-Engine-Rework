package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.system.Clipboard;
import openfl.events.KeyboardEvent;

class TokenInputSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var titleText:FlxText;
	var instructionText:FlxText;
	var tokenDisplay:FlxText;
	var currentToken:String = "";
	var maxLength:Int = 40; // GitHub tokens are usually 40 characters

	var onComplete:String->Void;
	var onCancel:Void->Void;

	public function new(onComplete:String->Void, onCancel:Void->Void) {
		super();
		this.onComplete = onComplete;
		this.onCancel = onCancel;
	}

	override function create() {
		super.create();

		FlxG.mouse.visible = true; // Enable mouse cursor

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var panel = new FlxSprite().makeGraphic(600, 300, FlxColor.WHITE);
		panel.screenCenter();
		add(panel);

		var panelBorder = new FlxSprite().makeGraphic(610, 310, FlxColor.BLACK);
		panelBorder.screenCenter();
		panelBorder.x -= 5;
		panelBorder.y -= 5;
		add(panelBorder);
		add(panel);

		titleText = new FlxText(0, panel.y + 20, panel.width, "Enter GitHub Token", 24);
		titleText.setFormat(Paths.font('funkin.ttf'), 24, FlxColor.BLACK, CENTER);
		titleText.x = panel.x;
		add(titleText);

		instructionText = new FlxText(panel.x + 20, titleText.y + 40, panel.width - 40,
			"Create a Personal Access Token at:\ngithub.com/settings/tokens\n\nRequired scopes: repo\n\nToken:", 16);
		instructionText.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.BLACK, LEFT);
		add(instructionText);

		var tokenBG = new FlxSprite(panel.x + 20, instructionText.y + 100).makeGraphic(Std.int(panel.width - 40), 30, FlxColor.GRAY);
		add(tokenBG);

		tokenDisplay = new FlxText(tokenBG.x + 5, tokenBG.y + 5, tokenBG.width - 10, "", 16);
		tokenDisplay.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(tokenDisplay);

		var controls = new FlxText(panel.x + 20, tokenBG.y + 50, panel.width - 40,
			"ENTER: Confirm | ESCAPE: Cancel | CTRL+V: Paste", 14);
		controls.setFormat(Paths.font('fnf1.ttf'), 14, FlxColor.BLACK, CENTER);
		add(controls);

		updateTokenDisplay();

		// Add keyboard listener
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		var key = event.keyCode;

		// Handle special keys
		if (key == 13) { // Enter
			if (currentToken.length > 0) {
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				close();
				onComplete(currentToken);
			}
			return;
		}

		if (key == 27) { // Escape
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			close();
			onCancel();
			return;
		}

		if (key == 8) { // Backspace
			if (currentToken.length > 0) {
				currentToken = currentToken.substring(0, currentToken.length - 1);
				updateTokenDisplay();
			}
			return;
		}

		// Handle Ctrl+V for paste
		if (event.ctrlKey && key == 86) { // V
			var clipboardText = Clipboard.text;
			if (clipboardText != null && clipboardText.length > 0) {
				// Add clipboard text to current token (up to max length)
				var remainingSpace = maxLength - currentToken.length;
				if (remainingSpace > 0) {
					var textToAdd = clipboardText.substring(0, Std.int(Math.min(clipboardText.length, remainingSpace)));
					currentToken += textToAdd;
					updateTokenDisplay();
				}
			}
			return;
		}

		// Handle regular character input
		if (currentToken.length < maxLength) {
			var char = String.fromCharCode(key);

			// Only allow alphanumeric characters and common token characters
			if (~/^[a-zA-Z0-9_-]$/.match(char)) {
				currentToken += char;
				updateTokenDisplay();
			}
		}
	}

	private function updateTokenDisplay():Void {
		if (currentToken.length == 0) {
			tokenDisplay.text = "Enter token here...";
			tokenDisplay.alpha = 0.5;
		} else {
			// Show asterisks for security, but show last 4 characters
			var maskedToken = "";
			for (i in 0...currentToken.length) {
				if (i < currentToken.length - 4) {
					maskedToken += "*";
				} else {
					maskedToken += currentToken.charAt(i);
				}
			}
			tokenDisplay.text = maskedToken;
			tokenDisplay.alpha = 1.0;
		}
	}

	override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}
}
