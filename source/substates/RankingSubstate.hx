package substates;

import sys.FileSystem;
import sys.io.File;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import backend.Song;
import flixel.addons.transition.FlxTransitionableState;
import archipelago.APEntryState;
import backend.WeekData;

class RankingSubstate extends MusicBeatSubstate
{
	var pauseMusic:FlxSound;

	var rank:FlxSprite = new FlxSprite(-200, 730);
	var combo:FlxSprite = new FlxSprite(-200, 730);
	var comboRank:String = "NA";
	var ranking:String = "NA";
	var rankingNum:Int = 15;

	var comboRankLimit:Int = 0;
	public static var comboRankSetLimit:Int = 0;
	var accRankLimit:Int = 0;
	public static var accRankSetLimit:Int = 0;
	public function new()
	{
		super();
		// PlayState.songEndTriggered = false;
		Conductor.songPosition = 0;

		generateRanking();

		if (!PlayState.instance.cpuControlled)
			backend.Highscore.saveRank(PlayState.SONG.song, rankingNum, PlayState.storyDifficulty);
	}

	override function create()
	{
		pauseMusic = new FlxSound().loadEmbedded(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		// PlayState.instance.canPause = false;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		rank = new FlxSprite(-20, 40).loadGraphic(Paths.image('rankings/$ranking'));
		rank.scrollFactor.set();
		add(rank);
		rank.antialiasing = true;
		rank.setGraphicSize(0, 450);
		rank.updateHitbox();
		rank.screenCenter();

		combo = new FlxSprite(-20, 40).loadGraphic(Paths.image('rankings/$comboRank'));
		combo.scrollFactor.set();
		combo.screenCenter();
		combo.x = rank.x - combo.width / 2;
		combo.y = rank.y - combo.height / 2;
		add(combo);
		combo.antialiasing = true;
		combo.setGraphicSize(0, 130);

		var press:FlxText = new FlxText(20, 15, 0, "Press ANY to continue.", 32);
		press.scrollFactor.set();
		press.setFormat(Paths.font("vcr.ttf"), 32);
		press.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		press.updateHitbox();
		add(press);

		var hint:FlxText = new FlxText(20, 15, 0, "You passed. Try getting under 10 misses for SDCB", 32);
		hint.scrollFactor.set();
		hint.setFormat(Paths.font("vcr.ttf"), 32);
		hint.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		hint.updateHitbox();
		add(hint);

		switch (comboRank)
		{
			case 'MFC':
				hint.text = "Congrats! You're perfect!";
			case 'GFC':
				hint.text = "You're doing great! Try getting only sicks for MFC";
			case 'FC':
				hint.text = "Good job. Try getting goods at minimum for GFC.";
			case 'SDCB':
				hint.text = "Nice. Try not missing at all for FC.";
		}

		if (PlayState.instance.cpuControlled)
		{
			hint.y -= 35;
			hint.text = "If you wanna gather that rank, disable botplay.";
		}

		if (PlayState.deathCounter >= 30)
		{
			hint.text = "skill issue\nnoob";
		}

		hint.screenCenter(X);

		hint.alpha = press.alpha = 0;

		press.screenCenter();
		press.y = 670 - press.height;

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(press, {alpha: 1, y: 690 - press.height}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(hint, {alpha: 1, y: 645 - hint.height}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5 * 1 / 100)
			pauseMusic.volume += 0.01 * 1 / 100 * elapsed;

		super.update(elapsed);

		if (FlxG.keys.justPressed.ANY || PlayState.instance.practiceMode)
		{
			PlayState.instance.paused = false;
			switch (PlayState.gameplayArea)
			{
				case "Story":
					if (PlayState.storyPlaylist.length <= 0)
					{
						Mods.loadTopMod();
						FlxG.sound.playMusic(Paths.music('panixPress'));
						TransitionState.transitionState(states.StoryMenuState, {transitionType: "stickers"});
					}
					else
					{
						var difficulty:String = Difficulty.getFilePath();

						trace('LOADING NEXT SONG');
						trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
						FlxG.sound.music.stop();
						TransitionState.transitionState(states.PlayState, {transitionType: "stickers"});
					}
				case "Freeplay":
					trace('WENT BACK TO FREEPLAY??');
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('panixPress'));
					TransitionState.transitionState(states.FreeplayState, {transitionType: "stickers"});
				case "APFreeplay":
					trace('WENT BACK TO ARCHIPELAGO FREEPLAY??');
					FlxG.sound.playMusic(Paths.music('panixPress'));
					TransitionState.transitionState(states.FreeplayState, {transitionType: "stickers"});
					var locationId = (PlayState.SONG.song);
					trace('Combo Required:' + comboRankLimit + " Combo Required: " + comboRankSetLimit);
					trace('Accuracy Required:' + accRankLimit + " Accuracy Required: " + accRankSetLimit);
					trace(archipelago.APPlayState.currentMod);
					if (archipelago.APPlayState.currentMod.trim() != "")
					{
						locationId += " (" + archipelago.APPlayState.currentMod + ")";
					}
					trace(locationId.trim());
					var locationIdInt = archipelago.APEntryState.apGame.info().get_location_id(locationId.trim());
					trace('Location ID: ' + locationIdInt);

					if (locationIdInt == null || locationIdInt <= 0)
					{
						// trace('First if: locationIdInt is 0');
						for (song in WeekData.getCurrentWeek().songs)
						{
							// trace("Current Week: " + WeekData.getCurrentWeek().songs);
							// trace("Object: " + WeekData.getCurrentWeek());
							// trace("Checking song: " + song[0]);
							// trace("Comparing: " + (cast song[0] : String).toLowerCase().trim() + " to " + PlayState.SONG.song.trim().toLowerCase());
							if ((cast song[0] : String).toLowerCase().trim() == PlayState.SONG.song.trim().toLowerCase() ||
								(cast song[0] : String).toLowerCase().trim().replace(" ", "-") == PlayState.SONG.song.trim().toLowerCase().replace(" ", "-"))
							{
								locationIdInt = archipelago.APPlayState.currentMod.trim() != ""
									? archipelago.APEntryState.apGame.info().get_location_id(song[0] + " (" + archipelago.APPlayState.currentMod + ")")
									: archipelago.APEntryState.apGame.info().get_location_id(song[0]);
								// trace('First if: Found matching song, locationIdInt set to ' + locationIdInt);
								locationId = archipelago.APPlayState.currentMod.trim() != ""
									? song[0] + " (" + archipelago.APPlayState.currentMod + ")"
									: song[0];
								break;
							}
						}
					}

					if (locationIdInt <= 0 || locationIdInt == null)
					{
						// trace('Second if: locationIdInt is still 0');
						for (song in WeekData.getCurrentWeek().songs)
						{
							var songPath = archipelago.APPlayState.currentMod.trim() != ""
								? "mods/" + archipelago.APPlayState.currentMod + "/data/" + song[0] + "/" + song[0] + "-" + Difficulty.getString(PlayState.storyDifficulty) + ".json"
								: "assets/shared" + (song[0] + Difficulty.getFilePath());
							var songJson:SwagSong = null;
							var jsonStuff:Array<String> = Paths.crawlDirectoryOG("mods/" + archipelago.APPlayState.currentMod + "/data", ".json");

							for (json in jsonStuff)
							{
								// trace("Checking: " + json); trace("Comparing to: " + songPath);
								if (json.trim().toLowerCase().replace(" ", "-") == songPath.trim().toLowerCase().replace(" ", "-"))
								{
									songJson = Song.parseJSON(File.getContent(json));
									// trace('Second if: Found matching song, testing...');
									// trace("Song: " + songJson.song); trace("Song File: " + songJson);
									if (songJson != null)
									{
										// trace("Song: " + songJson.song); trace("Comparing to: " + PlayState.SONG.song);
										// trace("Song: " + songJson.song.trim().toLowerCase().replace(" ", "-")); trace("Comparing to: " + PlayState.SONG.song.trim().toLowerCase().replace(" ", "-"));
										if (songJson.song.trim().toLowerCase().replace(" ", "-") == PlayState.SONG.song.trim().toLowerCase().replace(" ", "-"))
										{
											// trace('Second if: Found matching song, locationIdInt set to ' + locationIdInt);
											locationIdInt = archipelago.APPlayState.currentMod.trim() != ""
												? archipelago.APEntryState.apGame.info().get_location_id(song[0] + " (" + archipelago.APPlayState.currentMod + ")")
												: archipelago.APEntryState.apGame.info().get_location_id(song[0]);
											locationId = archipelago.APPlayState.currentMod.trim() != "" ? song[0] + " (" + archipelago.APPlayState.currentMod + ")" : song[0];
											break;
										}
									}
								} 
							}
						}
					}
					trace(APEntryState.apGame.info().LocationChecks([locationIdInt]));
					trace(APEntryState.apGame.info().get_location_name(locationIdInt));
					trace(PlayState.SONG.song);
					archipelago.ArchPopup.startPopupCustom("You've sent " + APEntryState.apGame.info().get_location_name(locationIdInt) + " to Archipelago!", "Go check it out!", "archipelago", function() {
						FlxG.sound.playMusic(Paths.sound('secret'));
					});

					var locationIdInt = APEntryState.apGame.info().get_location_id(locationId.trim());
					if (locationIdInt != null && APEntryState.apGame.info().get_location_name(locationIdInt).trim().toLowerCase().replace(" ", "-") == APEntryState.victorySong.trim().toLowerCase().replace(" ", "-"))
					{
						archipelago.ArchPopup.startPopupCustom("You've completed your goal!", "You win!", "archipelago", function() {
							FlxG.sound.playMusic(Paths.sound('secret'));
						});
						APEntryState.apGame.info().set_goal();
					}						
					Mods.loadTopMod();
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function generateRanking():String
	{
		if (PlayState.instance.songMisses == 0 && PlayState.instance.ratingsData[2].hits == 0 && PlayState.instance.ratingsData[3].hits == 0 && PlayState.instance.ratingsData[1].hits == 0 && PlayState.instance.ratingsData[0].hits == 0 && ClientPrefs.data.useMarvs) // Marvelous Full Combo
			{ comboRank = "MFC"; comboRankLimit = 1; }
		else if (PlayState.instance.songMisses == 0 && PlayState.instance.ratingsData[2].hits == 0 && PlayState.instance.ratingsData[3].hits == 0 && PlayState.instance.ratingsData[1].hits == 0) // Sick Full Combo
			{ comboRank = "SFC"; comboRankLimit = 2; }
		else if (PlayState.instance.songMisses == 0 && PlayState.instance.ratingsData[2].hits == 0 && PlayState.instance.ratingsData[3].hits == 0 && PlayState.instance.ratingsData[1].hits >= 1) // Good Full Combo (Nothing but Goods & Sicks)
			{ comboRank = "GFC"; comboRankLimit = 3; }
		else if (PlayState.instance.songMisses == 0 && PlayState.instance.ratingsData[2].hits >= 1 && PlayState.instance.ratingsData[3].hits == 0 && PlayState.instance.ratingsData[1].hits >= 0) // Alright Full Combo (Bads, Goods and Sicks)
			{ comboRank = "AFC"; comboRankLimit = 4; }
		else if (PlayState.instance.songMisses == 0) // Regular FC
			{ comboRank = "FC"; comboRankLimit = 5; }
		else if (PlayState.instance.songMisses < 10) // Single Digit Combo Breaks
			{ comboRank = "SDCB"; comboRankLimit = 6; }

		var acc = CoolUtil.floorDecimal(PlayState.instance.ratingPercent * 100, 2);

		// WIFE TIME :)))) (based on Wife3)
		var wifeConditions:Array<Bool> = [
			acc >= 99.9935, // P
			acc >= 99.980, // X
			acc >= 99.950, // X-
			acc >= 99.90, // SS+
			acc >= 99.80, // SS
			acc >= 99.70, // SS-
			acc >= 99.50, // S+
			acc >= 99, // S
			acc >= 96.50, // S-
			acc >= 93, // A+
			acc >= 90, // A
			acc >= 85, // A-
			acc >= 80, // B
			acc >= 70, // C
			acc >= 60, // D
			acc < 60 // E
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				rankingNum = i;
				switch (i)
				{
					case 0:
						ranking = "P";
						accRankLimit = 1;
					case 1:
						ranking = "X";
						accRankLimit = 2;
					case 2:
						ranking = "X-";
						accRankLimit = 3;
					case 3:
						ranking = "SS+";
						accRankLimit = 4;
					case 4:
						ranking = "SS";
						accRankLimit = 5;
					case 5:
						ranking = "SS-";
						accRankLimit = 6;
					case 6:
						ranking = "S+";
						accRankLimit = 7;
					case 7:
						ranking = "S";
						accRankLimit = 8;
					case 8:
						ranking = "S-";
						accRankLimit = 9;
					case 9:
						ranking = "A+";
						accRankLimit = 10;
					case 10:
						ranking = "A";
						accRankLimit = 11;
					case 11:
						ranking = "A-";
						accRankLimit = 11;
					case 12:
						ranking = "B";
						accRankLimit = 12;
					case 13:
						ranking = "C";
						accRankLimit = 13;
					case 14:
						ranking = "D";
						accRankLimit = 14;
					case 15:
						ranking = "E";
						accRankLimit = 15;
				}

				if (PlayState.deathCounter >= 30 || acc == 0)
					ranking = "F";
				break;
			}
		}
		return ranking;
	}
}