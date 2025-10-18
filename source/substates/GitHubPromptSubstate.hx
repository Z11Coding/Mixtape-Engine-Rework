package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;

class GitHubPromptSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var darkOverlay:FlxSprite;
	var promptPanel:FlxSprite;
	var iconSprite:FlxSprite;
	var titleText:FlxText;
	var messageText:FlxText;
	var buttonGroup:Array<GitHubButton> = [];

	var selectedButton:Int = 0;

	public function new(title:String, message:String, buttons:Array<{text:String, callback:Void->Void, style:GitHubButtonStyle}>) {
		super();

		FlxG.mouse.visible = true; // Ensure mouse cursor is visible

		createBackground();
		createPrompt(title, message, buttons);
	}

	private function createBackground():Void {
		// Dark overlay
		darkOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x88000000);
		add(darkOverlay);

		// GitHub-style background with subtle pattern
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff0d1117);
		bg.alpha = 0.95;
		add(bg);
	}

	private function createPrompt(title:String, message:String, buttons:Array<{text:String, callback:Void->Void, style:GitHubButtonStyle}>):Void {
		// Main prompt panel with GitHub styling
		promptPanel = new FlxSprite().makeGraphic(500, 300, 0xff21262d);
		promptPanel.screenCenter();

		// Add border
		var border = new FlxSprite().makeGraphic(502, 302, 0xff30363d);
		border.screenCenter();
		border.x -= 1;
		border.y -= 1;
		add(border);
		add(promptPanel);

		// GitHub icon
		iconSprite = new FlxSprite(promptPanel.x + 20, promptPanel.y + 20);
		iconSprite.makeGraphic(32, 32, 0xff58a6ff);
		add(iconSprite);

		// Title with GitHub styling
		titleText = new FlxText(iconSprite.x + 45, iconSprite.y + 5, promptPanel.width - 75, title, 18);
		titleText.setFormat(Paths.font('funkin.ttf'), 18, 0xfff0f6fc, LEFT, OUTLINE, 0xff21262d);
		titleText.borderSize = 1;
		add(titleText);

		// Message text
		messageText = new FlxText(promptPanel.x + 20, titleText.y + 40, promptPanel.width - 40, message, 14);
		messageText.setFormat(Paths.font('fnf1.ttf'), 14, 0xffe6edf3, LEFT);
		add(messageText);

		// Create buttons
		var buttonY = promptPanel.y + promptPanel.height - 60;
		var buttonSpacing = 110;
		var startX = promptPanel.x + promptPanel.width - (buttons.length * buttonSpacing) + 10;

		for (i in 0...buttons.length) {
			var buttonData = buttons[i];
			var button = new GitHubButton(startX + (i * buttonSpacing), buttonY, buttonData.text, buttonData.callback, buttonData.style);
			buttonGroup.push(button);
			add(button);
		}

		// Animate in
		promptPanel.alpha = 0;
		titleText.alpha = 0;
		messageText.alpha = 0;
		for (button in buttonGroup) button.alpha = 0;

		FlxTween.tween(promptPanel, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(titleText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(messageText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.15});
		for (i in 0...buttonGroup.length) {
			FlxTween.tween(buttonGroup[i], {alpha: 1}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.2 + (i * 0.05)});
		}

		updateButtonSelection();
	}

	private function updateButtonSelection():Void {
		for (i in 0...buttonGroup.length) {
			buttonGroup[i].setSelected(i == selectedButton);
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Mouse input for buttons
		if (FlxG.mouse.justPressed) {
			for (i in 0...buttonGroup.length) {
				if (FlxG.mouse.overlaps(buttonGroup[i])) {
					selectedButton = i;
					updateButtonSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					buttonGroup[selectedButton].onClick();
					close();
					return;
				}
			}
		}

		// Mouse hover for buttons
		var hoveredButton = -1;
		for (i in 0...buttonGroup.length) {
			if (FlxG.mouse.overlaps(buttonGroup[i])) {
				hoveredButton = i;
				break;
			}
		}

		if (hoveredButton != -1 && hoveredButton != selectedButton) {
			selectedButton = hoveredButton;
			updateButtonSelection();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
		}

		if (controls.UI_LEFT_P && selectedButton > 0) {
			selectedButton--;
			updateButtonSelection();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (controls.UI_RIGHT_P && selectedButton < buttonGroup.length - 1) {
			selectedButton++;
			updateButtonSelection();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			buttonGroup[selectedButton].onClick();
			close();
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}
	}
}

enum GitHubButtonStyle {
	PRIMARY;    // Blue button
	SECONDARY;  // Gray button
	SUCCESS;    // Green button
	DANGER;     // Red button
}

class GitHubButton extends FlxSprite {
	var buttonText:FlxText;
	var callback:Void->Void;
	var style:GitHubButtonStyle;
	var isSelected:Bool = false;

	public function new(x:Float, y:Float, text:String, callback:Void->Void, style:GitHubButtonStyle = SECONDARY) {
		super(x, y);
		this.callback = callback;
		this.style = style;

		var bgColor = switch(style) {
			case PRIMARY: 0xff238636;
			case SUCCESS: 0xff238636;
			case DANGER: 0xffda3633;
			case SECONDARY: 0xff21262d;
		};

		makeGraphic(100, 32, bgColor);

		// Border
		var borderColor = switch(style) {
			case PRIMARY: 0xff2ea043;
			case SUCCESS: 0xff2ea043;
			case DANGER: 0xfff85149;
			case SECONDARY: 0xff30363d;
		};

		// Add border effect by creating a slightly larger background
		var border = new FlxSprite().makeGraphic(102, 34, borderColor);
		// This would need to be handled differently in actual implementation

		buttonText = new FlxText(0, 0, width, text, 12);
		buttonText.setFormat(Paths.font('fnf1.ttf'), 12, 0xfff0f6fc, CENTER);
		buttonText.x = x;
		buttonText.y = y + (height - buttonText.height) / 2;
	}

	public function setSelected(selected:Bool):Void {
		isSelected = selected;

		if (selected) {
			var highlightColor = switch(style) {
				case PRIMARY: 0xff2ea043;
				case SUCCESS: 0xff2ea043;
				case DANGER: 0xfff85149;
				case SECONDARY: 0xff30363d;
			};
			color = highlightColor;
			alpha = 1.0;
		} else {
			var normalColor = switch(style) {
				case PRIMARY: 0xff238636;
				case SUCCESS: 0xff238636;
				case DANGER: 0xffda3633;
				case SECONDARY: 0xff21262d;
			};
			color = normalColor;
			alpha = 0.8;
		}
	}

	public function onClick():Void {
		if (callback != null) {
			callback();
		}
	}

	override function draw() {
		super.draw();
		if (buttonText != null) {
			buttonText.draw();
		}
	}
}
