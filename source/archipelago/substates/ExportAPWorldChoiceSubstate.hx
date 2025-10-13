package archipelago.substates;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class ExportAPWorldChoiceSubstate extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var defaultButton:FlxSprite;
	var customButton:FlxSprite;
	var cancelButton:FlxSprite;
	var defaultText:FlxText;
	var customText:FlxText;
	var cancelText:FlxText;

	var onDefaultCallback:Void->Void;
	var onCustomCallback:Void->Void;

	public function new(onDefault:Void->Void, onCustom:Void->Void)
	{
		super();
		this.onDefaultCallback = onDefault;
		this.onCustomCallback = onCustom;
	}

	override function create()
	{
		super.create();

		// Dark overlay
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 120));
		add(bg);

		// Main panel
		panel = new FlxSprite(0, 0);
		panel.makeGraphic(500, 300, FlxColor.fromRGB(40, 40, 60));
		panel.screenCenter();
		add(panel);

		// Title
		titleText = new FlxText(panel.x, panel.y + 20, panel.width, "Export APWorld", 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Description
		descriptionText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40,
			"Choose where to export the APWorld file:\n\n" +
			"• Default: Exports to the root folder of the game\n" +
			"• Custom: Choose your own export location", 16);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		add(descriptionText);

		// Buttons
		var buttonWidth = 120;
		var buttonHeight = 40;
		var buttonY = panel.y + panel.height - 70;
		var buttonSpacing = 20;
		var totalButtonWidth = (buttonWidth * 3) + (buttonSpacing * 2);
		var startX = panel.x + (panel.width - totalButtonWidth) / 2;

		// Default button
		defaultButton = new FlxSprite(startX, buttonY);
		defaultButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
		add(defaultButton);

		defaultText = new FlxText(defaultButton.x, defaultButton.y + 10, defaultButton.width, "DEFAULT", 14);
		defaultText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		defaultText.borderSize = 1;
		add(defaultText);

		// Custom button
		customButton = new FlxSprite(startX + buttonWidth + buttonSpacing, buttonY);
		customButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.BLUE);
		add(customButton);

		customText = new FlxText(customButton.x, customButton.y + 10, customButton.width, "CUSTOM", 14);
		customText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		customText.borderSize = 1;
		add(customText);

		// Cancel button
		cancelButton = new FlxSprite(startX + (buttonWidth + buttonSpacing) * 2, buttonY);
		cancelButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
		add(cancelButton);

		cancelText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 14);
		cancelText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		cancelText.borderSize = 1;
		add(cancelText);

		// Animate in
		panel.scale.set(0, 0);
		FlxTween.tween(panel.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

		titleText.alpha = 0;
		FlxTween.tween(titleText, {alpha: 1}, 0.4, {startDelay: 0.1});

		descriptionText.alpha = 0;
		FlxTween.tween(descriptionText, {alpha: 1}, 0.4, {startDelay: 0.2});

		// Animate buttons
		var buttons = [defaultButton, customButton, cancelButton];
		var texts = [defaultText, customText, cancelText];
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

		// Handle mouse input
		if (FlxG.mouse.overlaps(defaultButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			if (onDefaultCallback != null) onDefaultCallback();
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

		// Handle keyboard input
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		// Hover effects
		handleHoverEffects();
	}

	function handleHoverEffects()
	{
		// Default button hover
		if (FlxG.mouse.overlaps(defaultButton))
		{
			defaultButton.color = FlxColor.fromRGB(80, 160, 80);
			defaultText.color = FlxColor.YELLOW;
		}
		else
		{
			defaultButton.color = FlxColor.GREEN;
			defaultText.color = FlxColor.WHITE;
		}

		// Custom button hover
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

		// Cancel button hover
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
