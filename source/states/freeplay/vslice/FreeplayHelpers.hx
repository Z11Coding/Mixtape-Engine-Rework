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
				PlayState.altInstrumentals = targetInstId;
			}
			else
			{
				@:privateAccess
				state.capsuleOptionsMenu.busy = false;
				UserErrorSubstate.makeMessage("Missing instrumentals", 'Couldn\'t find Inst in \nsongs/${instPath}\nMake sure that there is a Inst.ogg file');
				return;
			}
		}
		else
			PlayState.altInstrumentals = null; // ? P-Slice

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
		LoadingState.prepareToSong();
    LoadingState.loadAndSwitchState(APEntryState.inArchipelagoMode ? new archipelago.APPlayState().funcAndReturn(function(ps:archipelago.APPlayState) {
      archipelago.APPlayState.currentSong = cap.getNativeSongId();
      archipelago.APPlayState.currentMod = cap.folder;
    }) : new PlayState());

		FlxG.sound.music.volume = 0;

		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}

	public static function getDifficultyName()
	{
		return Difficulty.list[PlayState.storyDifficulty].toUpperCase();
	}
}
