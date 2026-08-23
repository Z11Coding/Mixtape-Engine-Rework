package substates;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class AssetLocationChoiceSubstate extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var detectButton:FlxSprite;
	var customButton:FlxSprite;
	var cancelButton:FlxSprite;
	var detectText:FlxText;
	var customText:FlxText;
	var cancelText:FlxText;

	var onDetectCallback:Void->Void;
	var onCustomCallback:Void->Void;

	public function new(onDetect:Void->Void, onCustom:Void->Void)
	{
		super();
		this.onDetectCallback = onDetect;
		this.onCustomCallback = onCustom;
	}

	override function create()
	{
		super.create();

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 120));
		add(bg);

		panel = new FlxSprite(0, 0);
		panel.makeGraphic(540, 320, FlxColor.fromRGB(40, 40, 60));
		panel.screenCenter();
		add(panel);

		titleText = new FlxText(panel.x, panel.y + 20, panel.width, "Asset Location", 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		descriptionText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40,
			"Choose how Mixtape should find assets:\n\n" +
			"- Detect Executable Path: Use the folder containing the running executable\n" +
			"- Choose Folder: Pick the Mixtape folder manually", 16);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		add(descriptionText);

		var buttonWidth = 150;
		var buttonHeight = 40;
		var buttonY = panel.y + panel.height - 70;
		var buttonSpacing = 15;
		var totalButtonWidth = (buttonWidth * 3) + (buttonSpacing * 2);
		var startX = panel.x + (panel.width - totalButtonWidth) / 2;

		detectButton = new FlxSprite(startX, buttonY);
		detectButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
		add(detectButton);

		detectText = new FlxText(detectButton.x, detectButton.y + 10, detectButton.width, "DETECT", 14);
		detectText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		detectText.borderSize = 1;
		add(detectText);

		customButton = new FlxSprite(startX + buttonWidth + buttonSpacing, buttonY);
		customButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.BLUE);
		add(customButton);

		customText = new FlxText(customButton.x, customButton.y + 10, customButton.width, "CUSTOM", 14);
		customText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		customText.borderSize = 1;
		add(customText);

		cancelButton = new FlxSprite(startX + (buttonWidth + buttonSpacing) * 2, buttonY);
		cancelButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
		add(cancelButton);

		cancelText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 14);
		cancelText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		cancelText.borderSize = 1;
		add(cancelText);

		panel.scale.set(0, 0);
		FlxTween.tween(panel.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

		titleText.alpha = 0;
		FlxTween.tween(titleText, {alpha: 1}, 0.4, {startDelay: 0.1});

		descriptionText.alpha = 0;
		FlxTween.tween(descriptionText, {alpha: 1}, 0.4, {startDelay: 0.2});

		var buttons = [detectButton, customButton, cancelButton];
		var texts = [detectText, customText, cancelText];
		for (i in 0...buttons.length)
		{
			buttons[i].alpha = 0;
			texts[i].alpha = 0;
			FlxTween.tween(buttons[i], {alpha: 1}, 0.3, {startDelay: 0.3 + (i * 0.1)});
			FlxTween.tween(texts[i], {alpha: 1}, 0.3, {startDelay: 0.3 + (i * 0.1)});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(detectButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			if (onDetectCallback != null) onDetectCallback();
		}

		if (FlxG.mouse.overlaps(customButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			if (onCustomCallback != null) onCustomCallback();
		}

		if (FlxG.mouse.overlaps(cancelButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		handleHoverEffects();
	}

	function handleHoverEffects()
	{
		if (FlxG.mouse.overlaps(detectButton))
		{
			detectButton.color = FlxColor.fromRGB(80, 160, 80);
			detectText.color = FlxColor.YELLOW;
		}
		else
		{
			detectButton.color = FlxColor.GREEN;
			detectText.color = FlxColor.WHITE;
		}

		if (FlxG.mouse.overlaps(customButton))
		{
			customButton.color = FlxColor.fromRGB(80, 80, 160);
			customText.color = FlxColor.YELLOW;
		}
		else
		{
			customButton.color = FlxColor.BLUE;
			customText.color = FlxColor.WHITE;
		}

		if (FlxG.mouse.overlaps(cancelButton))
		{
			cancelButton.color = FlxColor.fromRGB(160, 80, 80);
			cancelText.color = FlxColor.YELLOW;
		}
		else
		{
			cancelButton.color = FlxColor.RED;
			cancelText.color = FlxColor.WHITE;
		}
	}
}