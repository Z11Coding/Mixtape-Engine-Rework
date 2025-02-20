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
import shop.ShopData.MoneyPopup;

class RankingSubstate extends MusicBeatSubstate
{
	var pauseMusic:FlxSound;

	var rank:FlxSprite = new FlxSprite(-200, 730);
	var combo:FlxSprite = new FlxSprite(-200, 730);
	var comboRank:String = "NA";
	var ranking:String = "NA";
	var rankingNum:Int = 15;

	public function new(x:Float, y:Float)
	{
		super();

		generateRanking();

		if (!PlayState.instance.cpuControlled)
			backend.Highscore.saveRank(PlayState.SONG.song, rankingNum, PlayState.storyDifficulty);

		pauseMusic = new FlxSound().loadEmbedded(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

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

		/*if (PlayState.isStoryMode)
		{
			var stichValue:Int = Std.int(PlayState.campaignScore / 600);
			add(new MoneyPopup(stichValue, cameras[0]));
		}
		else
		{
			var stichValue:Int = Std.int(PlayState.instance.songScore / 600);
			add(new MoneyPopup(stichValue, cameras[0]));
		}*/
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5 * 1 / 100)
			pauseMusic.volume += 0.01 * 1 / 100 * elapsed;

		super.update(elapsed);

		if (FlxG.keys.justPressed.ANY || PlayState.instance.practiceMode)
		{
			//PlayState.endingSong = false;

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
		if (PlayState.instance.songMisses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0 && PlayState.sicks == 0 && ClientPrefs.data.useMarvs) // Marvelous Full Combo
			comboRank = "MFC";
		else if (PlayState.instance.songMisses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0) // Sick Full Combo
			comboRank = "SFC";
		else if (PlayState.instance.songMisses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods >= 1) // Good Full Combo (Nothing but Goods & Sicks)
			comboRank = "GFC";
		else if (PlayState.instance.songMisses == 0 && PlayState.bads >= 1 && PlayState.shits == 0 && PlayState.goods >= 0) // Alright Full Combo (Bads, Goods and Sicks)
			comboRank = "AFC";
		else if (PlayState.instance.songMisses == 0) // Regular FC
			comboRank = "FC";
		else if (PlayState.instance.songMisses < 10) // Single Digit Combo Breaks
			comboRank = "SDCB";

		var acc = backend.Highscore.floorDecimal(PlayState.instance.ratingPercent * 100, 2);

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
					case 1:
						ranking = "X";
					case 2:
						ranking = "X-";
					case 3:
						ranking = "SS+";
					case 4:
						ranking = "SS";
					case 5:
						ranking = "SS-";
					case 6:
						ranking = "S+";
					case 7:
						ranking = "S";
					case 8:
						ranking = "S-";
					case 9:
						ranking = "A+";
					case 10:
						ranking = "A";
					case 11:
						ranking = "A-";
					case 12:
						ranking = "B";
					case 13:
						ranking = "C";
					case 14:
						ranking = "D";
					case 15:
						ranking = "E";
				}

				if (PlayState.deathCounter >= 30 || acc == 0)
					ranking = "F";
				break;
			}
		}
		return ranking;
	}
}