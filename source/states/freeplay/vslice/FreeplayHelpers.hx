package states.freeplay.vslice;

import backend.Highscore;
import backend.Song;
import backend.WeekData;
import backend.pslice.BPMCache;
import backend.pslice.UserErrorSubstate;
import haxe.Exception;
import openfl.utils.AssetType;
import options.GameplayChangersSubstate;
import stages.StageData;
import states.freeplay.VSliceFreeplayState;
import substates.ResetScoreSubState;

class FreeplayHelpers
{
	public static var BPM(get, set):Float;

	public static function set_BPM(value:Float)
	{
		Conductor.bpm = value;
		return value;
	}

	public static function get_BPM()
	{
		return Conductor.bpm;
	}

	public static function exitFreeplay()
	{
		BPMCache.instance.clearCache();
		Mods.loadTopMod();
		FlxG.signals.postStateSwitch.dispatch(); // ? for the screenshot plugin to clean itself
	}

	public inline static function openResetScoreState(state:VSliceFreeplayState, sng:FreeplaySongData, onScoreReset:() -> Void = null)
	{
		state.openSubState(new states.freeplay.vslice.ResetScoreSubState(sng.songName, sng.loadAndGetDiffId(), sng.songCharacter, -1, onScoreReset));
	}

	public inline static function openGameplayChanges(state:VSliceFreeplayState)
	{
		state.openSubState(new GameplayChangersSubstate());
	}

  public static function loadDiffsFromWeek(songData:FreeplaySongData)
	{
		Mods.currentModDirectory = songData.folder;
		PlayState.storyWeek = songData.levelId; // TODO
		Difficulty.loadFromWeek();
	}

  public static function moveToPlaystate(state:VSliceFreeplayState, cap:FreeplaySongData, currentDifficulty:String, ?targetInstId:String)
	{
		// FunkinSound.emptyPartialQueue();

		// Paths.setCurrentLevel(cap.songData.levelId);

    if (APEntryState.inArchipelagoMode) {
      var vicCheck:Bool = APFreeplayManager.isVictorySong(cap.getNativeSongId(), state.fpManager.songList[cap.levelId].folder) && APInfo.ticketCount >= APInfo.ticketWinCount;
      //You need the song AND the tickets.
      trace('can play victory song: ${vicCheck}');
      if (APFreeplayManager.isVictorySong(cap.getNativeSongId(), state.fpManager.songList[cap.levelId].folder) && !vicCheck) {

        // Check for hints first
        var hints = APFreeplayManager.getHintsForSong(cap.getNativeSongId(), state.fpManager.songList[cap.levelId].folder);

        if (hints.length > 0) {
          // Show hint panel first
          var hintContent = "Here are the hints for this song:\n\n";
          for (i in 0...hints.length) {
            hintContent += "• " + hints[i];
            if (i < hints.length - 1) hintContent += "\n\n";
          }

          archipelago.substates.InfoPanelSubstate.show(
            "Song Hints: " + cap.getNativeSongId(),
            hintContent,
            FlxColor.CYAN,
            function() {
              UserErrorSubstate.makeMessage("SONG NOT UNLOCKED!", 'You don\'t have enough tickets to play this victory song.\n\nRequired: ${APInfo.ticketWinCount}\nYou have: ${APInfo.ticketCount}');
              FlxG.sound.play(Paths.sound('cancelMenu'));
            }
          );
          return;
        } else {
          UserErrorSubstate.makeMessage("SONG NOT UNLOCKED!", 'You don\'t have enough tickets to play this victory song.\n\nRequired: ${APInfo.ticketWinCount}\nYou have: ${APInfo.ticketCount}');
          FlxG.sound.play(Paths.sound('cancelMenu'));
          return;
        }
      }

      // Check if song is locked (not in curUnlocked)
      var isUnlocked = APEntryState.inArchipelagoMode && [for (songObj in APFreeplayManager.curUnlocked) songObj.song.trim().toLowerCase().replace('-', ' ') == cap.getNativeSongId().trim().toLowerCase().replace('-', ' ') && songObj.mod == state.fpManager.songList[cap.levelId].folder].contains(true);
      var isLocked = APEntryState.inArchipelagoMode && !isUnlocked;

      if (isLocked) {
        trace('Song is locked (not in curUnlocked)!');

        // Check for hints first
        var hints = APFreeplayManager.getHintsForSong(cap.getNativeSongId(), state.fpManager.songList[cap.levelId].folder);

        if (hints.length > 0) {
          // Show hint panel first
          var hintContent = "Here are the hints for this song:\n\n";
          for (i in 0...hints.length) {
            hintContent += "• " + hints[i];
            if (i < hints.length - 1) hintContent += "\n\n";
          }

          archipelago.substates.InfoPanelSubstate.show(
            "Song Hints: " + cap.getNativeSongId(),
            hintContent,
            FlxColor.CYAN,
            function() {
              UserErrorSubstate.makeMessage("SONG NOT UNLOCKED!", "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.");
              FlxG.sound.play(Paths.sound('cancelMenu'));
            }
          );
          return;
        } else {
          UserErrorSubstate.makeMessage("SONG NOT UNLOCKED!", "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.");
          FlxG.sound.play(Paths.sound('cancelMenu'));
          return;
        }
      }

      if (APFreeplayManager.trueMissing.contains({song: cap.getNativeSongId(), mod: state.fpManager.songList[cap.levelId].folder}) && !APFreeplayManager.unplayedList.contains({song: cap.getNativeSongId(), mod: state.fpManager.songList[cap.levelId].folder})) {
        trace('Song is locked!');

        // Check for hints first
        var hints = APFreeplayManager.getHintsForSong(cap.getNativeSongId(), state.fpManager.songList[cap.levelId].folder);

        if (hints.length > 0) {
          // Show hint panel first
          var hintContent = "Here are the hints for this song:\n\n";
          for (i in 0...hints.length) {
            hintContent += "• " + hints[i];
            if (i < hints.length - 1) hintContent += "\n\n";
          }

          archipelago.substates.InfoPanelSubstate.show(
            "Song Hints: " + cap.getNativeSongId(),
            hintContent,
            FlxColor.CYAN,
            function() {
              UserErrorSubstate.makeMessage("SONG NOT UNLOCKED!", "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.");
              FlxG.sound.play(Paths.sound('cancelMenu'));
            }
          );
          return;
        } else {
          UserErrorSubstate.makeMessage("SONG NOT UNLOCKED!", "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.");
          FlxG.sound.play(Paths.sound('cancelMenu'));
          return;
        }
      }
    }

		state.persistentUpdate = false;
		Mods.currentModDirectory = cap.folder;

		var diffId = cap.loadAndGetDiffId();
		if (diffId == -1)
		{
			trace("SELECTED DIFFICULTY IS MISSING: " + currentDifficulty);
			diffId = 0;
		}

    var actualDifficulty:Int = diffId;

    // If unknownSongs is active, randomly select an actual difficulty
    if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
      var availableDifficulties:Array<Int> = [];
      // Try each difficulty to see which ones are valid
      for (i in 0...Difficulty.list.length) {
        try {
          var testPoop:String = Highscore.formatSong(cap.getNativeSongId(), i);
          // Test if the chart exists by trying to load it
          var testSong = Song.loadFromJson(testPoop, cap.getNativeSongId());
          if (testSong != null) {
            availableDifficulties.push(i);
          }
        } catch (e:Dynamic) {
          // This difficulty doesn't exist, skip it
          continue;
        }
      }

      if (availableDifficulties.length > 0) {
        // Randomly pick from available difficulties
        actualDifficulty = availableDifficulties[FlxG.random.int(0, availableDifficulties.length - 1)];
        trace('Unknown Songs: Randomly selected difficulty ${Difficulty.list[actualDifficulty]} (index $actualDifficulty)');
      } else {
        // If no difficulties are available, show a generic error
        UserErrorSubstate.makeMessage("ERROR!", "Unable to load song data");
        FlxG.sound.play(Paths.sound('cancelMenu'));
        return;
      }
    }
		if (targetInstId != null && targetInstId != "default")
		{
			var instPath = '${Paths.formatToSongPath(targetInstId)}/Inst.ogg';
			if (Paths.fileExists(instPath, AssetType.BINARY, false, "songs"))
			{
				//PlayState.altInstrumentals = targetInstId;
			}
			else
			{
				@:privateAccess
				state.capsuleOptionsMenu.busy = false;
				UserErrorSubstate.makeMessage("Missing instrumentals", 'Couldn\'t find Inst in \nsongs/${instPath}\nMake sure that there is a Inst.ogg file');
				return;
			}
		}
		//else
			//PlayState.altInstrumentals = null; // ? P-Slice

		var songLowercase:String = Paths.formatToSongPath(cap.getNativeSongId());
		var poop:String = Highscore.formatSong(songLowercase, diffId); // TODO //currentDifficulty);
		/*#if MODS_ALLOWED
			if(!NativeFileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !NativeFileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
		}*/
		trace(poop);

    // Check if required characters and stage are unlocked via sanity system
    if (APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
      trace('Missing Items for this song: ${archipelago.APEntryState.apGame.checkSongCharactersAndStageUnlocked(PlayState.SONG)}');
      var missingItems = archipelago.APEntryState.apGame.checkSongCharactersAndStageUnlocked(PlayState.SONG);
      if (missingItems.length > 0) {
        trace('Song requires unlocked sanity items: ' + missingItems.join(", "));

        var itemList = "";
        for (i in 0...missingItems.length) {
          itemList += "• " + missingItems[i];
          if (i < missingItems.length - 1) itemList += "\n";
        }

        UserErrorSubstate.makeMessage("Cannot Play Song!", 'This song requires unlocked characters or stages:\n\n' + itemList + '\n\nPlay other songs to unlock these items!');
        FlxG.sound.play(Paths.sound('cancelMenu'));

        return;
      }
    }

		try
		{
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			if(PlayState.SONG == null) throw "Song parsing failed!";
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = diffId;

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			// @:privateAccess
			// if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			// {
			// 	trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
			// 	Paths.freeGraphicsFromMemory();
			// }
			#if STRICT_LOADING_SCREEN
			if (!backend.ClientPrefs.data.strictLoadingScreen)
				LoadingState.prepareToSong();
			#end

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
		}
		catch (e:Exception)
		{
			trace('ERROR! $e');
			UserErrorSubstate.makeMessage("Failed to load a song", '${e.message}\n\n${e.details()}');
			@:privateAccess {
				state.busy = false;
				state.letterSort.inputEnabled = true;
			}
			return;
		}

		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		LoadingState.loadAndSwitchState(new PlayState(), true);

		FlxG.sound.music.volume = 0;

		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}
}
