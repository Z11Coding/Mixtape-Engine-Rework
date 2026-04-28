package archipelago.substates;

import archipelago.PlandoData;
import archipelago.substates.APPlandoSongListSubstate;
import archipelago.substates.APPlandoLocalSongsSubstate;
import archipelago.substates.APPlandoBlocksSubstate;
import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * Substate for managing Plando configuration
 * Provides interface to configure song locations, item placement, and custom blocks
 */
class APPlandoSubstate extends MusicBeatSubstate
{
	// Plando data reference
	public var plandoData:PlandoData;

	// UI elements
	var titleText:FlxText;
	var descriptionText:FlxText;
	var selectedListText:FlxText;

	var optionButtons:flixel.group.FlxTypedGroup<flixel.FlxSprite> = new flixel.group.FlxTypedGroup<flixel.FlxSprite>();
	var optionTexts:flixel.group.FlxTypedGroup<FlxText> = new flixel.group.FlxTypedGroup<FlxText>();

	var currentSelection:Int = 0;

	// Option list
	var plandoOptions:Array<PlandoOption> = [];

	// Animation tracking
	var activeTweens:Array<FlxTween> = [];
	var isAnimating:Bool = false;
	var transitionTime:Float = 0.3;

	public function new(?plandoData:PlandoData)
	{
		super();

		// Use provided plando data or create new instance
		if (plandoData != null)
		{
			this.plandoData = plandoData;
		}
		else
		{
			this.plandoData = new PlandoData();
		}
	}

	override function create()
	{
		super.create();

		// Semi-transparent background
		var bg = new flixel.FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.5;
		add(bg);

		// Title
		titleText = new FlxText(50, 30, FlxG.width - 100, "PLANDO CONFIGURATION", 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Description
		descriptionText = new FlxText(50, 75, FlxG.width - 100,
			"Configure custom item placement and song restrictions\nUP/DOWN: Navigate | ENTER: Select | C: Clear All", 14);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		add(descriptionText);

		// Setup plando options
		setupPlandoOptions();

		// Add option groups
		add(optionButtons);
		add(optionTexts);

		// Load and display options
		loadOptions();
	}

	function setupPlandoOptions():Void
	{
		plandoOptions = [
			{
				name: "Exclude Song Locations",
				description: "Songs where important items should NOT be randomized",
				action: function() {
					openExcludeSongLocationsSubstate();
				}
			},
			{
				name: "Priority Song Locations",
				description: "Songs that should have important items placed",
				action: function() {
					openPrioritySongLocationsSubstate();
				}
			},
			{
				name: "Always Include Songs",
				description: "Songs always included in the randomized pool",
				action: function() {
					openAlwaysIncludeSongsSubstate();
				}
			},
			{
				name: "Potential Victory Songs",
				description: "Only these songs can be selected as victory songs",
				action: function() {
					openPotentialVictorySongsSubstate();
				}
			},
			{
				name: "Extra Starting Songs",
				description: "Songs that should be in the pool from the start",
				action: function() {
					openExtraStartingSongsSubstate();
				}
			},
			{
				name: "Local/Non-Local Songs",
				description: "Configure local and non-local song placement",
				action: function() {
					openLocalSongsSubstate();
				}
			},
			{
				name: "Plando Blocks",
				description: "Create custom item placement rules",
				action: function() {
					openPlandoBlocksSubstate();
				}
			}
		];
	}

	function loadOptions():Void
	{
		optionButtons.clear();
		optionTexts.clear();

		var startY:Float = 140;
		var spacing:Float = 50;
		var buttonWidth = FlxG.width - 200;

		for (i in 0...plandoOptions.length)
		{
			var option = plandoOptions[i];
			var yPos:Float = startY + (i * spacing);

			// Create button - start off-screen for animation
			var button = new flixel.FlxSprite(FlxG.width, yPos);
			button.makeGraphic(Std.int(buttonWidth), 45, FlxColor.fromRGB(40, 40, 80));
			button.ID = i;
			optionButtons.add(button);

			// Create text - start off-screen for animation
			var text = new FlxText(FlxG.width + 10, yPos + 10, buttonWidth - 20, option.name, 18);
			text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			text.ID = i;
			optionTexts.add(text);
		}

		// Animate buttons in
		animateButtonsIn();
	}

	function animateButtonsIn():Void
	{
		if (isAnimating)
			return;
		isAnimating = true;

		var completedAnimations = 0;
		var totalAnimations = optionButtons.members.length;

		if (totalAnimations == 0)
		{
			isAnimating = false;
			return;
		}

		var buttonWidth = FlxG.width - 200;
		var targetX:Float = 100;

		// Animate buttons
		for (i in 0...optionButtons.members.length)
		{
			var button = optionButtons.members[i];
			if (button != null)
			{
				button.x = FlxG.width;
				var tween = FlxTween.tween(button, {x: targetX}, transitionTime + (i * 0.05), {
					ease: FlxEase.backOut,
					onComplete: function(tween:FlxTween)
					{
						completedAnimations++;
						activeTweens.remove(tween);
						if (completedAnimations == totalAnimations)
						{
							isAnimating = false;
						}
					}
				});
				activeTweens.push(tween);
			}
		}

		// Animate text
		for (i in 0...optionTexts.members.length)
		{
			var text = optionTexts.members[i];
			if (text != null)
			{
				text.x = FlxG.width + 10;
				var tween = FlxTween.tween(text, {x: targetX + 10}, transitionTime + (i * 0.05), {
					ease: FlxEase.backOut
				});
				activeTweens.push(tween);
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isAnimating)
			return;

		// Navigation
		if (FlxG.keys.justPressed.UP)
		{
			currentSelection = Std.int(Math.max(0, currentSelection - 1));
			updateSelection();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			currentSelection = Std.int(Math.min(plandoOptions.length - 1, currentSelection + 1));
			updateSelection();
		}

		// Select option
		if (FlxG.keys.justPressed.ENTER)
		{
			plandoOptions[currentSelection].action();
		}

		// Back
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			close();
		}
	}

	function updateSelection():Void
	{
		for (i in 0...optionButtons.members.length)
		{
			var button = optionButtons.members[i];
			if (i == currentSelection)
			{
				button.color = FlxColor.YELLOW;
			}
			else
			{
				button.color = FlxColor.fromRGB(40, 40, 80);
			}
		}
	}

	// Substate opening functions
	function openExcludeSongLocationsSubstate():Void
	{
		openSubState(new APPlandoSongListSubstate(plandoData, "excludeSongLocations", plandoData.excludeSongLocations));
	}

	function openPrioritySongLocationsSubstate():Void
	{
		openSubState(new APPlandoSongListSubstate(plandoData, "prioritySongLocations", plandoData.prioritySongLocations));
	}

	function openAlwaysIncludeSongsSubstate():Void
	{
		openSubState(new APPlandoSongListSubstate(plandoData, "alwaysIncludeSongs", plandoData.alwaysIncludeSongs));
	}

	function openPotentialVictorySongsSubstate():Void
	{
		openSubState(new APPlandoSongListSubstate(plandoData, "potentialVictorySongs", plandoData.potentialVictorySongs));
	}

	function openExtraStartingSongsSubstate():Void
	{
		openSubState(new APPlandoSongListSubstate(plandoData, "extraStartingSongs", plandoData.extraStartingSongs));
	}

	function openLocalSongsSubstate():Void
	{
		openSubState(new APPlandoLocalSongsSubstate(plandoData, plandoData.localSongs, plandoData.nonLocalSongs));
	}

	function openPlandoBlocksSubstate():Void
	{
		openSubState(new APPlandoBlocksSubstate(plandoData, plandoData.plandoBlocks));
	}
}

typedef PlandoOption = {
	var name:String;
	var description:String;
	var action:Void->Void;
}
