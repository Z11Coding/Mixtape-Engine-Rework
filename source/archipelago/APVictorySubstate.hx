package archipelago;

import archipelago.APInfo;
import backend.COD;
import backend.ClientPrefs;
import backend.CoolUtil;
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
import managers.APFreeplayManager;
import objects.Character;
import psychlua.FunkinLua;
import states.MainMenuState;
import states.PlayState;
import states.StoryMenuState;
import states.freeplay.FreeplayState;
import substates.GameOverSubstate;
import substates.RankingSubstate; // For accessing ranking logic

using StringTools;

/**
 * High Quality Defeat Substate - shows when High Quality Trap is active
 * Replaces the regular ranking substate with a "death" that shows the rank
 * but treats it as a defeat from not being "high quality enough"
 */
class APVictorySubstate extends GameOverSubstate
{
	// Ranking system (same as RankingSubstate)
	var rank:String = "?";
	var rankMessage:String = "";
	var rankColor:FlxColor = FlxColor.WHITE;
	var rankingNum:Int = 15;
	var comboRank:String = "NA";

	// UI elements for ranking display
	var rankPanel:FlxSprite;
	var rankText:FlxText;
	var rankMessageText:FlxText;

	// High Quality specific behavior
	var isHighQualityDefeat:Bool = true;
	var hasShownRank:Bool = false;

	public function new(?leBoyfriend:Character)
	{
		// Set the cause of death for High Quality Trap
		COD.COD = "You were not high quality enough.";

		// Calculate actual rank using same logic as RankingSubstate
		calculateActualRank();

		// Determine where to return to
		determineReturnState();

		super(leBoyfriend, cast FreeplayManager.getNewFreeplayInstance(), cast FreeplayManager.getNewFreeplayInstance());

	}

	override function create()
	{
		// Prevent Death Link from being sent for High Quality defeats
		if (Std.is(PlayState.instance, APPlayState)) {
			var apPlayState = cast(PlayState.instance, APPlayState);
			// Temporarily disable death link for this "fake" death
			var originalDeathByLink = APPlayState.deathByLink;
			APPlayState.deathByLink = false;

			super.create();

			// Restore original state after creation
			APPlayState.deathByLink = originalDeathByLink;
		} else {
			super.create();
		}

		// Set up the ranking display but keep it hidden initially
		setupRankingDisplay();



	}

	function calculateActualRank()
	{
		// Use the same ranking logic as RankingSubstate
		var comboRankSetLimit:Int = APInfo.comboRankSetLimit;
		var accRankSetLimit:Int = APInfo.accRankSetLimit;

		// Calculate combo rank (same logic as RankingSubstate)
		if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits == 0 && PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits == 0) // Perfect Full Combo (Only Sicks)
			{ comboRank = "PFC"; }
		else if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits == 0 && PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits >= 1) // Sick Full Combo (Only Sicks & Goods)
			{ comboRank = "SFC"; }
		else if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits == 0 && PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits >= 1) // Good Full Combo (Nothing but Goods & Sicks)
			{ comboRank = "GFC"; }
		else if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits >= 1 && PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits >= 0) // Alright Full Combo (Bads, Goods and Sicks)
			{ comboRank = "AFC"; }
		else if (PlayState.instance.comboManager.songMisses == 0) // Regular Full Combo
			{ comboRank = "FC"; }
		else if (PlayState.instance.comboManager.songMisses < 10) // Single Digit Combo Breaks
			{ comboRank = "SDCB"; }
		else { comboRank = "Clear"; } // Good enough

		var acc = CoolUtil.floorDecimal(PlayState.instance.comboManager.ratingPercent * 100, 2);

		// WIFE ranking system (same as RankingSubstate)
		var wifeConditions:Array<Bool> = [
			acc >= 99.9935, // P
			acc >= 99.980, // X
			acc >= 99.950, // X-
			acc >= 99.90, // SS+
			acc >= 99.80, // SS
			acc >= 99.70, // SS-
			acc >= 99.50, // S+
			acc >= 99.25, // S
			acc >= 99.00, // S-
			acc >= 96.50, // A+
			acc >= 93.00, // A
			acc >= 90.00, // A-
			acc >= 85.00, // B
			acc >= 80.00, // C
			acc >= 70.00, // D
			acc >= 60.00, // D
			true // E or F
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				rankingNum = i;
				switch (i)
				{
					case 0: rank = "P"; rankColor = FlxColor.YELLOW;
					case 1: rank = "X"; rankColor = FlxColor.YELLOW;
					case 2: rank = "X-"; rankColor = FlxColor.YELLOW;
					case 3: rank = "SS+"; rankColor = FlxColor.WHITE;
					case 4: rank = "SS"; rankColor = FlxColor.WHITE;
					case 5: rank = "SS-"; rankColor = FlxColor.WHITE;
					case 6: rank = "S+"; rankColor = FlxColor.YELLOW;
					case 7: rank = "S"; rankColor = FlxColor.YELLOW;
					case 8: rank = "S-"; rankColor = FlxColor.YELLOW;
					case 9: rank = "A+"; rankColor = FlxColor.LIME;
					case 10: rank = "A"; rankColor = FlxColor.LIME;
					case 11: rank = "A-"; rankColor = FlxColor.LIME;
					case 12: rank = "B"; rankColor = FlxColor.CYAN;
					case 13: rank = "C"; rankColor = FlxColor.ORANGE;
					case 14: rank = "D"; rankColor = FlxColor.RED;
					case 15: rank = "D"; rankColor = FlxColor.RED;
					case 16: rank = "E"; rankColor = FlxColor.RED;
				}
				break;
			}
		}

		// Death penalty
		if (PlayState.deathCounter >= 30 || acc == 0) {
			rank = "F";
			rankColor = FlxColor.RED;
		}

		// Calculate message based on rank but with High Quality context
		calculateHighQualityMessage(rank);

		// Save rank if not CPU controlled
		if (!PlayState.instance.cpuControlled)
			backend.Highscore.saveRank(PlayState.SONG.song, rankingNum, PlayState.storyDifficulty);
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

	function calculateHighQualityMessage(rank:String)
	{
		// High Quality themed messages
		switch (rank.toUpperCase())
		{
			case "P" | "X" | "X-":
				rankMessage = "HIGH\nQUALITY!\nBut not\nhigh enough...";

			case "SS+" | "SS" | "SS-":
				rankMessage = "VERY GOOD!\nAlmost\nhigh quality...";

			case "S+" | "S" | "S-":
				rankMessage = "GOOD!\nBut needs more\nquality...";

			case "A+" | "A" | "A-":
				rankMessage = "DECENT!\nStill not\nhigh quality...";

			case "B":
				rankMessage = "OKAY!\nFar from\nhigh quality...";

			case "C":
				rankMessage = "POOR!\nVery low\nquality...";

			case "D":
				rankMessage = "BAD!\nNo quality\nat all...";

			case "E" | "F":
				rankMessage = "TERRIBLE!\nZero quality\ndetected...";

			default:
				rankMessage = "NOT HIGH\nQUALITY\nENOUGH!";
		}
	}

	function showRankingDisplay()
	{
		if (hasShownRank) return;
		hasShownRank = true;

		// Play a success sound (this happens when the GameOverSubstate allows interaction)
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

		// No need for separate instructions - GameOverSubstate handles input prompts
	}

	function determineReturnState()
	{
		// This is mainly for reference - GameOverSubstate will handle actual navigation
		// But we can set up any freeplay-specific return logic here if needed
		trace('APVictorySubstate: GameOverSubstate will handle navigation');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Check if this is APVictorySubstate and we're past the death animation
		var canShowRanking = (!boyfriend.isAnimationNull() &&
							  (boyfriend.getAnimationName() == 'deathLoop' ||
							   (boyfriend.getAnimationName() == 'firstDeath' && boyfriend.isAnimationFinished())));

		// Show ranking display when the death animation allows interaction
		// This happens at the same time the music starts and inputs become available
		if (canShowRanking && !hasShownRank)
		{
			showRankingDisplay();
		}

		// The GameOverSubstate will handle all the input logic
		// We just add our ranking UI on top of it
	}

	function sendArchipelagoLocationCheck()
	{
		// Send location check using the same logic as normal victories
		// This ensures progression continues even with High Quality "defeats"
		if (Std.is(PlayState.instance, APPlayState))
		{
			var apPlayState = cast(PlayState.instance, APPlayState);
			var currentMod = APPlayState.currentMod;
			var songName = APPlayState.currentSong;

			trace('APVictorySubstate: Checking ranking requirements for song: $songName, mod: $currentMod');

			// Use the same ranking requirements as RankingSubstate
			var comboRankSetLimit:Int = APInfo.comboRankSetLimit;
			var accRankSetLimit:Int = APInfo.accRankSetLimit;

			// Calculate current combo and accuracy ranks (same as RankingSubstate)
			var comboRankLimit = rankingNum; // We already calculated this in calculateActualRank()
			var accRankLimit = rankingNum;   // Same ranking system

			trace('Combo Gotten: $comboRankLimit\nCombo Required: $comboRankSetLimit');
			trace('Accuracy Gotten: $accRankLimit\nAccuracy Required: $accRankSetLimit');

			// Always send note checks regardless of ranking requirements
			trace("Sending checks for all checked notes (no ranking requirement)...");
			for (note in apPlayState.checkedNotes) {
				trace("Sending check for note: " + note);
				@:privateAccess{
					trace("Sending location: " + note.checkInfo.loc);
					APPlayState.apGame.info().LocationChecks([note.checkInfo.loc]);
				}
			}
			trace("All note checks sent.");

			// Only send main song location check if ranking requirements are met
			if (((!PlayState.instance.cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false)) || Sys.args().contains('-livereload')) && comboRankLimit >= comboRankSetLimit && accRankLimit >= accRankSetLimit) {
				trace("Ranking requirements met! Sending main location check...");

				// Send the main song location check (but don't force it - use the regular logic)
				if (APInfo.unlockMethod != "Note Checks") {
					trace("Sending main location check...");
					var locationIdInts = APEntryState.apGame.locationData(songName.trim(), currentMod.trim());
					trace('Location IDs: ' + locationIdInts);

					for (locationIdInt in locationIdInts) {
						if (locationIdInt != 0) {
							trace("Sending location check: " + locationIdInt);
							APPlayState.apGame.info().LocationChecks([locationIdInt]);
						}
					}
				}
			} else {
				trace("Ranking requirements not met - main location check will not be sent");
			}
		}
		else
		{
			trace('APVictorySubstate: Not in APPlayState, skipping location check');
		}
	}

	// Override to prevent normal restart behavior
	override function endBullshit()
	{

		// Stop using the High Quality Trap after showing the defeat
		if (HighQualityTrapManager.isTrapInUse()) {
			TrapLinkFunctions.stopHighQualityTrap();
		}
		sendArchipelagoLocationCheck();
		super.endBullshit();
	}
}
