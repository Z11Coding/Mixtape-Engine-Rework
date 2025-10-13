package archipelago;

import backend.Difficulty;
import backend.Highscore;
import backend.MusicBeatSubstate;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Character;
import psychlua.FunkinLua;
import states.FreeplayState;
import states.MainMenuState;
import states.PlayState;
import states.StoryMenuState;
import substates.GameOverSubstate;

using StringTools;

/**
 * Fake death screen that shows at the end of a song but counts as a win.
 * Shows the rank and message after the death animation, then returns to appropriate state.
 */
class APVictorySubstate extends GameOverSubstate
{
	// Ranking system
	var rank:String = "?";
	var rankMessage:String = "";
	var rankColor:FlxColor = FlxColor.WHITE;

	// UI elements for ranking display
	var rankPanel:FlxSprite;
	var rankText:FlxText;
	var rankMessageText:FlxText;

	// Victory-specific behavior
	var isVictoryMode:Bool = true;
	var hasShownRank:Bool = false;

	// Return destination tracking
	var returnToState:String = "freeplay"; // "freeplay", "story", "main"

	public function new(rank:String = "B", ?camera)
	{
		// Calculate rank and message based on performance
		this.rank = rank;
		calculateRankMessage(rank);

		// Determine where to return to
		determineReturnState();

		super(camera);
	}

	override function create()
	{
		super.create();

		// Set up the ranking display but keep it hidden initially
		setupRankingDisplay();

		// Override the default game over behavior
		setupVictoryBehavior();
	}

	function setupRankingDisplay()
	{
		// Create ranking panel (bottom right corner)
		rankPanel = new FlxSprite(FlxG.width - 280, FlxG.height - 120);
		rankPanel.makeGraphic(260, 100, FlxColor.fromRGB(20, 20, 40));
		rankPanel.alpha = 0;
		add(rankPanel);

		// Rank letter (large)
		rankText = new FlxText(rankPanel.x + 10, rankPanel.y + 10, 100, rank, 48);
		rankText.setFormat(Paths.font("vcr.ttf"), 48, rankColor, CENTER, OUTLINE, FlxColor.BLACK);
		rankText.borderSize = 2;
		rankText.alpha = 0;
		add(rankText);

		// Rank message
		rankMessageText = new FlxText(rankPanel.x + 120, rankPanel.y + 15, 130, rankMessage, 16);
		rankMessageText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		rankMessageText.borderSize = 1;
		rankMessageText.alpha = 0;
		add(rankMessageText);
	}

	function setupVictoryBehavior()
	{
		// Wait for the death animation to finish before showing rank
		new FlxTimer().start(3.0, function(_) {
			showRankingDisplay();
		});

		// Override the restart behavior to be return behavior
		// We'll handle input differently in the update function
	}

	function showRankingDisplay()
	{
		if (hasShownRank) return;
		hasShownRank = true;

		// Play a success sound
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Animate in the ranking display
		FlxTween.tween(rankPanel, {alpha: 0.9}, 0.5, {ease: FlxEase.quartOut});
		FlxTween.tween(rankText, {alpha: 1}, 0.5, {
			ease: FlxEase.quartOut,
			startDelay: 0.2,
			onComplete: function(_) {
				// Make the rank letter flicker for emphasis
				FlxFlicker.flicker(rankText, 1, 0.1, false);
			}
		});
		FlxTween.tween(rankMessageText, {alpha: 1}, 0.5, {
			ease: FlxEase.quartOut,
			startDelay: 0.4
		});

		// Show instructions after a delay
		new FlxTimer().start(2.0, function(_) {
			showReturnInstructions();
		});
	}

	function showReturnInstructions()
	{
		// Add instruction text
		var instructionText = new FlxText(0, FlxG.height - 50, FlxG.width, "Press ACCEPT to continue", 16);
		instructionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
		instructionText.borderSize = 1;
		instructionText.alpha = 0;
		add(instructionText);

		FlxTween.tween(instructionText, {alpha: 1}, 0.5);

		// Make it blink
		FlxFlicker.flicker(instructionText, 0, 0.5);
	}

	function calculateRankMessage(rank:String)
	{
		switch (rank.toUpperCase())
		{
			case "S":
				rankMessage = "PERFECT!\nIncredible\nperformance!";
				rankColor = FlxColor.GOLD;
			case "A":
				rankMessage = "EXCELLENT!\nGreat job!";
				rankColor = FlxColor.LIME;
			case "B":
				rankMessage = "GOOD!\nNice work!";
				rankColor = FlxColor.CYAN;
			case "C":
				rankMessage = "OKAY!\nYou did it!";
				rankColor = FlxColor.YELLOW;
			case "D":
				rankMessage = "POOR!\nTry harder\nnext time!";
				rankColor = FlxColor.ORANGE;
			case "F":
				rankMessage = "FAILED!\nKeep\npracticing!";
				rankColor = FlxColor.RED;
			default:
				rankMessage = "COMPLETE!\nSong\nfinished!";
				rankColor = FlxColor.WHITE;
		}
	}

	function determineReturnState()
	{
		// Check the current state context to determine where to return
		if (PlayState.isStoryMode)
		{
			returnToState = "story";
		}
		else if (states.FreeplayState.vocals != null) // Freeplay context
		{
			returnToState = "freeplay";
		}
		else
		{
			returnToState = "main";
		}

		trace('APVictorySubstate: Will return to $returnToState');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Override the default game over input handling
		if (hasShownRank && (controls.ACCEPT || controls.BACK))
		{
			returnToAppropriateState();
		}
	}

	function returnToAppropriateState()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Animate out the ranking display
		FlxTween.tween(rankPanel, {alpha: 0}, 0.3);
		FlxTween.tween(rankText, {alpha: 0}, 0.3);
		FlxTween.tween(rankMessageText, {alpha: 0}, 0.3);

		// Handle the actual state transition after animation
		new FlxTimer().start(0.5, function(_) {
			performStateTransition();
		});
	}

	function performStateTransition()
	{
		// Similar logic to ranking substate but adapted for AP context
		switch (returnToState)
		{
			case "story":
				// Return to story mode - check if there are more songs
				handleStoryModeReturn();

			case "freeplay":
				// Return to freeplay
				FlxG.switchState(new FreeplayState());

			case "main":
				// Return to main menu
				FlxG.switchState(new MainMenuState());

			default:
				// Fallback to main menu
				FlxG.switchState(new MainMenuState());
		}
	}

	function handleStoryModeReturn()
	{
		// Story mode logic - check if there are more songs in the week
		var currentWeek = WeekData.getCurrentWeek();

		if (PlayState.storyPlaylist.length > 0)
		{
			// More songs in the week, continue to next song
			var difficulty:String = Difficulty.getFilePath();

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0].toLowerCase());
			FlxG.switchState(new PlayState());
		}
		else
		{
			// Week completed, return to story menu with completion logic
			if (PlayState.storyWeek >= 0)
			{
				// Mark week as completed and save progress
				StoryMenuState.weekCompleted.set(WeekData.weeksList[PlayState.storyWeek], true);
				Highscore.saveWeekScore(WeekData.getWeekFileName(), PlayState.campaignScore, PlayState.storyWeek);

				FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
				FlxG.save.flush();
			}

			FlxG.switchState(new StoryMenuState());
		}
	}

	// Override the default game over restart behavior
	override function doDeathActions()
	{
		// Don't call super() - we want to skip the default death actions
		// Instead, just play the death animation without the restart logic

		if (boyfriend.animOffsets.exists('firstDeath'))
		{
			boyfriend.playAnim('firstDeath');
		}

		// Play death sound
		FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
	}

	// Override to prevent restarting
	override function endBullshit()
	{
		// Don't call super() - we don't want the default restart behavior
		// The victory behavior will handle everything
	}
}
