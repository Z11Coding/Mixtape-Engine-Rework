package psychlua.states;

class PlayStateFunctions {
  public static function implement(funk:FunkinLua)
  {
    var lua:State = funk.lua;
    var game = PlayState.instance;
    // Song/Week shit
		funk.set('curBpm', Conductor.bpm);
		funk.set('bpm', PlayfieldManager.SONG.bpm);
		funk.set('scrollSpeed', PlayfieldManager.SONG.speed);
		funk.set('crochet', Conductor.crochet);
		funk.set('stepCrochet', Conductor.stepCrochet);
		funk.set('songLength', FlxG.sound.music?.length ?? 0);
		funk.set('songName', PlayfieldManager.SONG.song);
		funk.set('songPath', Paths.formatToSongPath(PlayfieldManager.SONG.song));
		funk.set('loadedSongName', Song.loadedSongName);
		funk.set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		funk.set('chartPath', Song.chartPath);
		funk.set('startedCountdown', false);
		funk.set('curStage', PlayfieldManager.SONG.stage);
		funk.set('isStoryMode', PlayState.isStoryMode);

		funk.set('difficulty', PlayState.storyDifficulty);
		funk.set('difficultyName', Difficulty.getString(false));
		funk.set('difficultyPath', Difficulty.getFilePath());
		funk.set('difficultyNameTranslation', Difficulty.getString(true));

		funk.set('weekRaw', PlayState.storyWeek);
		funk.set('week', WeekData.weeksList[PlayState.storyWeek]);
		funk.set('seenCutscene', PlayState.seenCutscene);
		funk.set('hasVocals', PlayfieldManager.SONG.needsVoices);

    if(game != null)
    @:privateAccess
    {
      var curSection:SwagSection = PlayfieldManager.SONG.notes[MegaManager.conductor.currentMeasure];
      funk.set('curSection', MegaManager.conductor.currentMeasure);
      funk.set('curBeat', MegaManager.conductor.currentBeat);
      funk.set('curStep', MegaManager.conductor.currentStep);
      funk.set('curDecBeat', MegaManager.conductor.beatLengthMs);
      funk.set('curDecStep', MegaManager.conductor.stepLengthMs);

      funk.set('score', game.comboManager?.songScore);
      funk.set('misses', game.comboManager?.songMisses);
      funk.set('hits', game.comboManager?.songHits);
      funk.set('combo', game.comboManager?.combo);
      funk.set('deaths', PlayState.deathCounter);

      funk.set('rating', game.comboManager?.ratingPercent);
      funk.set('ratingName', game.comboManager?.ratingName);
      funk.set('ratingFC', game.comboManager?.ratingFC);
      funk.set('totalPlayed', game.comboManager?.totalPlayed);
      funk.set('totalNotesHit', game.comboManager?.totalNotesHit);

      //Backwards compat
      funk.set('songScore', game.comboManager?.songScore);
      funk.set('songMisses', game.comboManager?.songMisses);
      funk.set('ratingPercent', game.comboManager?.ratingPercent);

      funk.set('inGameOver', GameOverSubstate.instance != null);
      funk.set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
      funk.set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
      funk.set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

      funk.set('healthGainMult', game.healthGain);
      funk.set('healthLossMult', game.healthLoss);

      #if FLX_PITCH
      funk.set('playbackRate', game.playbackRate);
      #else
      funk.set('playbackRate', 1);
      #end

      funk.set('guitarHeroSustains', game.guitarHeroSustains);
      funk.set('instakillOnMiss', game.instakillOnMiss);
      funk.set('botPlay', game.cpuControlled);
      funk.set('botPlay', ClientPrefs.getGameplaySetting('showcase', false));
      funk.set('practice', game.practiceMode);
      funk.set('practice', PlayState.changedDifficulty);

      // Default character data
      funk.set('defaultBoyfriendX', game.BF_X);
      funk.set('defaultBoyfriendY', game.BF_Y);
      funk.set('defaultOpponentX', game.DAD_X);
      funk.set('defaultOpponentY', game.DAD_Y);
      funk.set('defaultGirlfriendX', game.GF_X);
      funk.set('defaultGirlfriendY', game.GF_Y);

      funk.set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayfieldManager.SONG.player1);
      funk.set('dadName', game.dad != null ? game.dad.curCharacter : PlayfieldManager.SONG.player2);
      funk.set('gfName', game.gf != null ? game.gf.curCharacter : PlayfieldManager.SONG.gfVersion);

      // Noteskin/Splash
      funk.set('noteSkin', ClientPrefs.data.noteSkin);
      funk.set('noteSkinPostfix', Note.getNoteSkinPostfix());
      funk.set('splashSkin', ClientPrefs.data.splashSkin);
      funk.set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
      funk.set('splashAlpha', ClientPrefs.data.splashAlpha);
    }

    //stupid bietch ass functions
		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0) {
			game.comboManager.songScore += value;
			game.comboManager.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0) {
			game.comboManager.songMisses += value;
			game.comboManager.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0) {
			game.comboManager.songHits += value;
			game.comboManager.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0) {
			game.comboManager.songScore = value;
			game.comboManager.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0) {
			game.comboManager.songMisses = value;
			game.comboManager.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0) {
			game.comboManager.songHits = value;
			game.comboManager.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 1) game.health = value);
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0) game.health += value);
		Lua_helper.add_callback(lua, "damage", function(value:Float = 0, ?lethal:Bool = true, ?causeOfDeath:String = null) {
			// Calculate potential new health value
			var newHealth = game.health - value;

			// Check if damage would be lethal
			if (lethal && newHealth <= 0) {
				// Set cause of death if provided
				if (causeOfDeath != null && causeOfDeath.trim() != "") {
					backend.COD.setCOD(null, causeOfDeath);
				} else {
					backend.COD.setCOD(null, 'Took lethal damage. (${this.scriptName})');
				}

				// Apply damage and trigger death
				game.health = newHealth;
				game.doDeathCheck(true);
			} else if (!lethal) {
				// Non-lethal damage: don't let health go below a small positive value
				game.health = Math.max(newHealth, 0.001);
			} else {
				// Normal damage that could be lethal but health won't drop to 0 or below
				game.health = newHealth;
			}
		});
		Lua_helper.add_callback(lua, "getHealth", function() return game.health);

    Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			game.addCharacterToList(name, charType);
		});

    // others
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, ?value1:String = '', ?value2:String = '') {
			game.triggerEvent(name, value1, value2, Conductor.songPosition);
			//trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
			return true;
		});

		Lua_helper.add_callback(lua, "startCountdown", function() {
			game.startCountdown();
			return true;
		});
		Lua_helper.add_callback(lua, "endSong", function() {
			game.KillNotes();
			game.endSong();
			return true;
		});
		Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false) {
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			if(PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				FreeplayManager.openFreeplay();

			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			MusicManager.playMenuMusic();
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});

    Lua_helper.add_callback(lua, "getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});
		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String) {
			switch(target.trim().toLowerCase())
			{
				case 'gf', 'girlfriend':
					game.moveCameraToGirlfriend();
				case 'dad', 'opponent':
					game.moveCamera(true);
				default:
					game.moveCamera(false);
			}
		});

    Lua_helper.add_callback(lua, "setCameraFollowPoint", function(x:Float, y:Float) game.camFollow.setPosition(x, y));
		Lua_helper.add_callback(lua, "addCameraFollowPoint", function(?x:Float = 0, ?y:Float = 0) {
			game.camFollow.x += x;
			game.camFollow.y += y;
		});
    Lua_helper.add_callback(lua, "getCameraFollowX", () -> game.camFollow.x);
		Lua_helper.add_callback(lua, "getCameraFollowY", () -> game.camFollow.y);

    Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float) {
			game.comboManager.ratingPercent = value;
			game.setOnScripts('rating', game.comboManager.ratingPercent);
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String) {
			game.comboManager.ratingName = value;
			game.setOnScripts('ratingName', game.comboManager.ratingName);
		});
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String) {
			game.comboManager.ratingFC = value;
			game.setOnScripts('ratingFC', game.comboManager.ratingFC);
		});

    Lua_helper.add_callback(lua, "characterDance", function(character:String) {
			switch(character.toLowerCase()) {
				case 'dad': game.dad.dance();
				case 'gf' | 'girlfriend': if(game.gf != null) game.gf.dance();
				default: game.boyfriend.dance();
			}
		});

    Lua_helper.add_callback(lua, "updateScoreText", function() game.updateScoreText());

    Lua_helper.add_callback(lua, "setHealthBarColors", function(left:String, right:String) {
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.healthBar.setColors(left_color, right_color);
		});
		Lua_helper.add_callback(lua, "setTimeBarColors", function(left:String, right:String) {
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.timeBar.setColors(left_color, right_color);
		});

    Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, ?music:String = null) {
			var path:String;
			var songPath:String = Paths.formatToSongPath(Song.loadedSongName);
			#if TRANSLATIONS_ALLOWED
			path = Paths.getPath('data/$songPath/${dialogueFile}_${ClientPrefs.data.language}.json', TEXT);
			#if MODS_ALLOWED
			if(!FileSystem.exists(path))
			#else
			if(!Assets.exists(path, TEXT))
			#end
			#end
				path = Paths.getPath('data/$songPath/$dialogueFile.json', TEXT);

			luaTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path, TEXT))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			}
			else
			{
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if(game.endingSong)
					game.endSong();
				else
					game.startCountdown();
			}
			return false;
		});
		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile)))
			{
				if(game.videoCutscene != null)
				{
					game.remove(game.videoCutscene);
					game.videoCutscene.destroy();
				}
				game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
				return true;
			}
			else
			{
				luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			}
			return false;

			#else
			PlayState.instance.inCutscene = true;
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				PlayState.instance.inCutscene = false;
				if(game.endingSong)
					game.endSong();
				else
					game.startCountdown();
			});
			return true;
			#end
		});
  }
}
