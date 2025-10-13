package archipelago.substates;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class YAMLOptionsSubstate extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var generateButton:FlxSprite;
	var refreshButton:FlxSprite;
	var importButton:FlxSprite;
	var cancelButton:FlxSprite;
	var generateText:FlxText;
	var refreshText:FlxText;
	var importText:FlxText;
	var cancelText:FlxText;

	var onGenerateCallback:Void->Void;
	var onRefreshCallback:Void->Void;
	var onImportCallback:Void->Void;

	public function new(onGenerate:Void->Void, onRefresh:Void->Void, onImport:Void->Void)
	{
		super();
		this.onGenerateCallback = onGenerate;
		this.onRefreshCallback = onRefresh;
		this.onImportCallback = onImport;
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
		panel.makeGraphic(600, 350, FlxColor.fromRGB(40, 40, 60));
		panel.screenCenter();
		add(panel);

		// Title
		titleText = new FlxText(panel.x, panel.y + 20, panel.width, "YAML Options", 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Description
		descriptionText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40,
			"Choose what you'd like to do with YAML files:\n\n" +
			"• Generate: Create a new YAML with current settings\n" +
			"• Refresh: Import existing YAML and re-export with updated song list\n" +
			"• Import: Load settings from an existing YAML file", 16);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		add(descriptionText);

		// Buttons
		var buttonWidth = 120;
		var buttonHeight = 40;
		var buttonY = panel.y + panel.height - 80;
		var buttonSpacing = 15;
		var totalButtonWidth = (buttonWidth * 4) + (buttonSpacing * 3);
		var startX = panel.x + (panel.width - totalButtonWidth) / 2;

		// Generate button
		generateButton = new FlxSprite(startX, buttonY);
		generateButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
		add(generateButton);

		generateText = new FlxText(generateButton.x, generateButton.y + 10, generateButton.width, "GENERATE", 12);
		generateText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		generateText.borderSize = 1;
		add(generateText);

		// Refresh button
		refreshButton = new FlxSprite(startX + buttonWidth + buttonSpacing, buttonY);
		refreshButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.ORANGE);
		add(refreshButton);

		refreshText = new FlxText(refreshButton.x, refreshButton.y + 10, refreshButton.width, "REFRESH", 12);
		refreshText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		refreshText.borderSize = 1;
		add(refreshText);

		// Import button
		importButton = new FlxSprite(startX + (buttonWidth + buttonSpacing) * 2, buttonY);
		importButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.BLUE);
		add(importButton);

		importText = new FlxText(importButton.x, importButton.y + 10, importButton.width, "IMPORT", 12);
		importText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		importText.borderSize = 1;
		add(importText);

		// Cancel button
		cancelButton = new FlxSprite(startX + (buttonWidth + buttonSpacing) * 3, buttonY);
		cancelButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
		add(cancelButton);

		cancelText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 12);
		cancelText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
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
		var buttons = [generateButton, refreshButton, importButton, cancelButton];
		var texts = [generateText, refreshText, importText, cancelText];
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
		if (FlxG.mouse.overlaps(generateButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			if (onGenerateCallback != null) onGenerateCallback();
		}

		if (FlxG.mouse.overlaps(refreshButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			if (onRefreshCallback != null) onRefreshCallback();
		}

		if (FlxG.mouse.overlaps(importButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			if (onImportCallback != null) onImportCallback();
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
		// Generate button hover
		if (FlxG.mouse.overlaps(generateButton))
		{
			generateButton.color = FlxColor.fromRGB(80, 160, 80);
			generateText.color = FlxColor.YELLOW;
		}
		else
		{
			generateButton.color = FlxColor.GREEN;
			generateText.color = FlxColor.WHITE;
		}

		// Refresh button hover
		if (FlxG.mouse.overlaps(refreshButton))
		{
			refreshButton.color = FlxColor.fromRGB(255, 140, 80);
			refreshText.color = FlxColor.YELLOW;
		}
		else
		{
			refreshButton.color = FlxColor.ORANGE;
			refreshText.color = FlxColor.WHITE;
		}

		// Import button hover
		if (FlxG.mouse.overlaps(importButton))
		{
			importButton.color = FlxColor.fromRGB(80, 80, 160);
			importText.color = FlxColor.YELLOW;
		}
		else
		{
			importButton.color = FlxColor.BLUE;
			importText.color = FlxColor.WHITE;
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
