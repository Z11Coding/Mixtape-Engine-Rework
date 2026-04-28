package archipelago.substates;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/**
 * Substate for inputting numeric values for plando configuration
 */
class APPlandoNumberInputSubstate extends MusicBeatSubstate
{
	var title:String;
	var description:String;
	var currentValue:Int;
	var minValue:Int;
	var maxValue:Int;
	var onValueChanged:Int->Void;

	var titleText:FlxText;
	var descriptionText:FlxText;
	var valueText:FlxText;
	var rangeText:FlxText;

	var increaseButton:FlxButton;
	var decreaseButton:FlxButton;
	var confirmButton:FlxButton;
	var backButton:FlxButton;

	public function new(title:String, description:String, currentValue:Int, minValue:Int, maxValue:Int,
		onValueChanged:Int->Void)
	{
		super();
		this.title = title;
		this.description = description;
		this.currentValue = Math.max(minValue, Math.min(maxValue, currentValue));
		this.minValue = minValue;
		this.maxValue = maxValue;
		this.onValueChanged = onValueChanged;
	}

	override function create()
	{
		super.create();

		// Semi-transparent background
		var bg = new flixel.FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.5;
		add(bg);

		// Title
		titleText = new FlxText(50, Std.int(FlxG.height / 2) - 150, FlxG.width - 100, title, 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Description
		descriptionText = new FlxText(50, Std.int(FlxG.height / 2) - 80, FlxG.width - 100, description, 16);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		add(descriptionText);

		// Value display
		valueText = new FlxText(50, Std.int(FlxG.height / 2), FlxG.width - 100, Std.string(currentValue), 64);
		valueText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
		valueText.borderSize = 2;
		add(valueText);

		// Range display
		rangeText = new FlxText(50, Std.int(FlxG.height / 2) + 80, FlxG.width - 100,
			'Range: $minValue - $maxValue', 14);
		rangeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
		rangeText.borderSize = 1;
		add(rangeText);

		// Instructions
		var instructionsY = FlxG.height - 140;
		var instructionsText = new FlxText(50, instructionsY, FlxG.width - 100,
			"LEFT/RIGHT: Decrease/Increase | ENTER/NUM_PLUS: +1 | BACKSPACE/NUM_MINUS: -1\nCONFIRM: Save | BACK: Cancel", 12);
		instructionsText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.LIGHT_GRAY, CENTER, OUTLINE, FlxColor.BLACK);
		instructionsText.borderSize = 1;
		add(instructionsText);

		// Buttons
		decreaseButton = new FlxButton(100, FlxG.height - 60, "◄ DECREASE", onDecrease);
		decreaseButton.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxColor.RED);
		add(decreaseButton);

		increaseButton = new FlxButton(FlxG.width - 300, FlxG.height - 60, "INCREASE ►", onIncrease);
		increaseButton.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxColor.GREEN);
		add(increaseButton);

		confirmButton = new FlxButton(50, FlxG.height - 120, "CONFIRM", onConfirm);
		confirmButton.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, FlxColor.GREEN);
		add(confirmButton);

		backButton = new FlxButton(FlxG.width - 150, FlxG.height - 120, "CANCEL", onBack);
		backButton.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, FlxColor.BLACK);
		add(backButton);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var changed = false;

		// Decrease value
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.MINUS)
		{
			if (currentValue > minValue)
			{
				currentValue--;
				changed = true;
			}
		}

		// Increase value
		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.PLUS)
		{
			if (currentValue < maxValue)
			{
				currentValue++;
				changed = true;
			}
		}

		// Set to min
		if (FlxG.keys.justPressed.HOME)
		{
			currentValue = minValue;
			changed = true;
		}

		// Set to max
		if (FlxG.keys.justPressed.END)
		{
			currentValue = maxValue;
			changed = true;
		}

		// Confirm
		if (FlxG.keys.justPressed.ENTER)
		{
			onConfirm();
		}

		// Back
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			onBack();
		}

		if (changed)
		{
			updateDisplay();
		}
	}

	function updateDisplay():Void
	{
		valueText.text = Std.string(currentValue);
	}

	function onIncrease():Void
	{
		if (currentValue < maxValue)
		{
			currentValue++;
			updateDisplay();
		}
	}

	function onDecrease():Void
	{
		if (currentValue > minValue)
		{
			currentValue--;
			updateDisplay();
		}
	}

	function onConfirm():Void
	{
		if (onValueChanged != null)
		{
			onValueChanged(currentValue);
		}
		close();
	}

	function onBack():Void
	{
		close();
	}
}
