package archipelago;
import Random;
import backend.Highscore;
import backend.Song;
import backend.WeekData;
import flixel.addons.ui.FlxUIInputText; // TODO: get rid of this in place of the psych varient
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import managers.APFreeplayManager;
import objects.Alphabet.DynamicAlphabet;
import objects.Alphabet.DynamicColoredAlphabet;
import objects.Alphabet;
import objects.Character;
import objects.HealthIcon;
import options.GameplayChangersSubstate;
import states.PlaylistState.PlaylistData;
import states.PlaylistState.SongMetadata;
import states.editors.PlaylistEditorState.PlaylistSelector;
import states.freeplay.backend.DifficultyStars;
import yutautil.AprilFools;

class APPlaylistState extends MusicBeatState {
	public static var apPlaylists:Array<APPlaylistMetadata> = [];
  public var loadedPlaylists:Array<APPlaylistMetadata> = [];
	var selectedPlaylist:APPlaylistMetadata = null;

  private static var curSelected:Int = 0;
  var lerpSelected:Float = 0;

  var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

  private var grpPlaylists:FlxTypedGroup<Alphabet>;
	private var iconList:FlxTypedGroup<HealthIcon>;
  private var iconArray:Array<HealthIcon> = [];
  var selected:Bool = false;
	var bg:FlxSprite;

  var randomText:Scrollable;
	var randomIcon:HealthIcon;

  var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;

  var difficultyStars:DifficultyStars;
  var rank:RankingManager;
  public static var doChange:Bool = false;

	var readyTxt:ColoredAlphabet;
	var mainBox:PsychUIBox;
	var settingsBox:PsychUIBox;
	var songListTxt:FlxText;
	var readyLettersInPosition:Bool = false;

	static var shufflePlaylist:Bool = false;

  override function create()
	{
    #if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end
		Cursor.cursorMode = Default;
    Highscore.reloadModifiers();
    Paths.clearStoredWithoutStickers();

    persistentUpdate = true;
		PlayState.isStoryMode = false;

    #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Selecting Their Mixtape (AP MODE)...", null);
		#end

    Mods.loadTopMod();

    bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

    if (ClientPrefs.data.allowVis) {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				visual = new AudioDisplay(FlxG.sound.music, 0, FlxG.height, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				visual.scrollFactor.set(0, 0);
				add(visual);
				visual.alpha = ClientPrefs.data.visOpacity;

				vocalvisual = new AudioDisplay(FlxG.sound.music, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				vocalvisual.scrollFactor.set(0, 0);
				vocalvisual.flipY = true;
				add(vocalvisual);
				vocalvisual.alpha = ClientPrefs.data.visOpacity;

				oppvisual = new AudioDisplay(FlxG.sound.music, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				oppvisual.scrollFactor.set(0, 0);
				oppvisual.flipY = true;
				add(oppvisual);
				oppvisual.alpha = ClientPrefs.data.visOpacity;
			}
		}

    grpPlaylists = new FlxTypedGroup<Alphabet>();
		add(grpPlaylists);

    iconList = new FlxTypedGroup<HealthIcon>();
		add(iconList);

    randomText = new Alphabet(90, 320, "RANDOM", true);
		randomText.scaleX = Math.min(1, 980 / randomText.width);
		randomText.targetY = -1;
		randomText.snapToPosition();
		add(cast randomText);

		randomIcon = new HealthIcon('bf');
		randomIcon.sprTracker = cast randomText;
		randomIcon.scrollFactor.set(1, 1);
		add(randomIcon);

		difficultyStars = new DifficultyStars(930, -130);
		difficultyStars.alpha = 0;
    difficultyStars.scrollFactor.set();
    add(difficultyStars);

		reloadPlayLists();

		if (loadedPlaylists.length < 1) {
      FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO PLAYLISTS FOUND!\n\n\nPress ENTER or BACK to return to AP Category Menu.",
				function() MusicBeatState.switchState(new archipelago.APCategoryState(archipelago.APPlayState.apGame)),
				function() MusicBeatState.switchState(new archipelago.APCategoryState(archipelago.APPlayState.apGame))));
			return;
    }

    FlxG.mouse.visible = true;

		readyTxt = new ColoredAlphabet(0, -2000, 'READY?', true);
		readyTxt.screenCenter(X);
		add(readyTxt);

		mainBox = new PsychUIBox(3000, 0, 300, 320, ['Song List']);
		mainBox.canMove = false;
		mainBox.canMinimize = false;
		mainBox.selectedName = 'Song List';
		mainBox.scrollFactor.set();
		mainBox.screenCenter(Y);
		mainBox.y -= 50;
		add(mainBox);

		settingsBox = new PsychUIBox(3000, 0, 300, 320, ['Playlist Modifiers']);
		settingsBox.canMove = false;
		settingsBox.canMinimize = false;
		settingsBox.selectedName = 'Playlist Modifiers';
		settingsBox.scrollFactor.set();
		settingsBox.screenCenter(Y);
		settingsBox.y -= 50;
		add(settingsBox);

		makeModifierUI();

		songListTxt = new FlxText(25, 25, 300, '', 32);
		songListTxt.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
		songListTxt.scrollFactor.set();
		mainBox.getTab('Song List').menu.add(songListTxt);

    rank = new RankingManager('small');
		rank.updateHitbox();
		rank.screenCenter(XY);
		rank.y = 640 - rank.height;
		rank.x = FlxG.width/2 - 590;
    //add(rank);

    lerpSelected = curSelected;

    bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("playlist_tip", "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

    updateTexts();

    super.create();
    changeSelection();
  }

  override function closeSubState() {
		if (doChange)
		{
			changeSelection(0);
			doChange = false;
			Highscore.reloadModifiers();
		}
		persistentUpdate = true;
		super.closeSubState();
	}

	function changeSelection(change:Int = 0) {
    curSelected += change;
    if (curSelected < -1)
      curSelected = grpPlaylists.length - 1;
    else if (curSelected >= grpPlaylists.length)
      curSelected = -1;

		var bullShit:Int = 0;
    for (item in grpPlaylists.members)
		{
			bullShit++;
			item.alpha = 0.4;
			if (item.targetY == curSelected)
				item.alpha = 1;
			if (item is Scrollable) {
				if (cast(item, Scrollable).targetY == curSelected)
					item.alpha = 1;
				else
					item.alpha = 0.4;
			}
		}

    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
  }

	var holdTime:Float = 0;
	var choosePlaylist:Bool = false;
	var e:Float = 0;
	var songString:String = "";
	var songStringOG:String = "";
  override function update(elapse:Float) {
    super.update(elapse);
		e++;

		if (!choosePlaylist) {
			updateTexts(elapse);
			// Refresh playlist colors in AP mode to reflect location completion changes
			#if ARCHIPELAGO_ALLOWED
			if (archipelago.APInfo.inArchipelagoMode && archipelago.APInfo.apGame != null) {
				for (i in 0...grpPlaylists.members.length) {
					if (i < loadedPlaylists.length && grpPlaylists.members[i] != null) {
						var playlistColor = getPlaylistLocationColor(loadedPlaylists[i]);
						grpPlaylists.members[i].color = playlistColor;
					}
				}
			}
			#end
		}

		if (readyTxt != null)
			for (i in 0...readyTxt.letters.length) {
				readyTxt.letters[i].color = FlxColor.fromHSL((((e / 2) / 300 * 360) % 360)+(15*i), 1.0, 0.5*1.0);
				// Only apply wave effect if letters are in position
				if (readyLettersInPosition) {
					readyTxt.letters[i].y = readyTxt.y + readyTxt.letters[i].row * 85 + (Math.sin((e*0.01) * 2 + (0.5*i)) * 5);
				}
			}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}

		if (controls.ACCEPT)
    {
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			if (curSelected == -1) {
				curSelected = FlxG.random.int(0, grpPlaylists.length - 1);
				return;
			}
			// Check if this is a bundle without difficulties set
			if (!choosePlaylist && hasPlaylistEnabledBundles() && !playlistHasAllDifficultiesSet(loadedPlaylists[curSelected])) {
				// Open difficulty selection substate instead of proceeding
				persistentUpdate = false;
				openSubState(new BundleDifficultySelectionSubstate(loadedPlaylists[curSelected], function(updatedPlaylist:APPlaylistMetadata) {
					// Update the playlist with selected difficulties
					loadedPlaylists[curSelected] = updatedPlaylist;
					apPlaylists[curSelected] = updatedPlaylist;
					reloadPlayLists();
					persistentUpdate = true;
				}));
				return;
			}

			if (!choosePlaylist) {
				choosePlaylist = true;
				trace('Selected Playlist: ${loadedPlaylists[curSelected].toString()}');
				selectedPlaylist = loadedPlaylists[curSelected].copy();
				for (song in selectedPlaylist.songList)
					songString += '${song.songName}\n';

				songStringOG = songString;
				songListTxt.text = songString;
				mainBox.resize(Std.int(songListTxt.width + 50), Std.int(songListTxt.height + 50));
				for (item in grpPlaylists.members)
					FlxTween.tween(item, {alpha: 0, x: -3000}, 1, {ease: FlxEase.sineIn, startDelay: (0.2*item.targetY)});
				FlxTween.tween(randomText, {alpha: 0, x: 3000}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(difficultyStars, {alpha: 1}, 1, {ease: FlxEase.sineIn});
				// Tween each letter individually to its final position
				readyLettersInPosition = false;
				for (i in 0...readyTxt.letters.length) {
					var targetY = 550 + readyTxt.letters[i].row * 85;
					FlxTween.tween(readyTxt.letters[i], {y: targetY}, 2, {
						ease: FlxEase.elasticOut,
						startDelay: i * 0.05,
						onComplete: function(tween) {
							if (i == readyTxt.letters.length - 1) {
								readyTxt.y = 550;
								readyLettersInPosition = true;
							}
						}
					});
				}
				FlxTween.tween(settingsBox, {x: 930}, 1, {ease: FlxEase.elasticOut});
				mainBox.screenCenter();
				FlxG.sound.music.pause();
				FlxTimer.wait(0.25, playCurListPreview.bind(loadedPlaylists[curSelected].songList)); // Wait a little before trying to pull a Inst file
			} else {
				var curModDir = Mods.currentModDirectory;
				// Check songs for sanity.
				var missingItems:Array<String> = [];
				for (song in selectedPlaylist.songList) {
					// Load all songs, and check using the checker.
					Mods.currentModDirectory = song.folder != null ? song.folder : '';
					var missingData = archipelago.APInfo.apGame.checkSongCharactersAndStageUnlocked(Song.loadFromJson(Paths.formatToSongPath(song.songName + (song.difficulty.toLowerCase() != "normal" ? "-"+song.difficulty.toLowerCase() : "")), Paths.formatToSongPath(song.songName)));
					if (missingData.length > 0) {
						missingItems = missingItems.concat(missingData);
					}
				}
				inline function goBack() {
					MusicBeatState.switchState(new archipelago.APPlaylistState().funcAndReturn(function(thee) {
						thee.playCurListPreview(null);
					}));
				}

				if (missingItems.length > 0) {
					var errorMsg = "The following items required for this playlist are missing or locked:\n\n" + missingItems.join("\n") + "\n\nPlay more songs to unlock these items.";
					MusicBeatState.switchState(new states.ErrorState(errorMsg,
						function() goBack(),
						function() goBack()));
					}

				Mods.currentModDirectory = curModDir;
				PlayState.campaignMisses = 0;
				PlayState.campaignScore = 0;
				PlayState.isPlaylist = true;
				PlayState.altInstrumentals = null; // ? P-Slice
				Mods.loadTopMod();
				WeekData.reloadWeekFiles();
				if (shufflePlaylist) {
					selectedPlaylist = selectedPlaylist.copy();
					FlxG.random.shuffle(selectedPlaylist.songList);
				}

				var firstSong = selectedPlaylist.songList[0];
				var songLowercase:String = Paths.formatToSongPath(firstSong.songName);
				Mods.currentModDirectory = firstSong.folder != null ? firstSong.folder : '';

				// Set APPlayState variables for the current song
				APPlayState.currentSong = firstSong.songName;
				APPlayState.currentMod = firstSong.folder != null ? firstSong.folder : '';

				PlayState.storyWeek = firstSong.week;
				Song.loadFromJson('${songLowercase}${(firstSong.difficulty.toLowerCase() != "normal" ? "-"+firstSong.difficulty.toLowerCase() : "")}', songLowercase);
				LoadingState.prepareToSong();

				// Convert AP song list to normal song list using SongMetadata abstract
				var normalSongList:Array<states.PlaylistState.PlaylistSongMetadata> = [];
				for (apSong in selectedPlaylist.songList) {
					var songViaAbstract:states.PlaylistState.SongMetadata = apSong;
					var normalSong:states.PlaylistState.PlaylistSongMetadata = songViaAbstract;
					normalSongList.push(normalSong);
				}

				LoadingState.loadAndSwitchState(new APPlayState(selectedPlaylist, normalSongList));
			}
    }
    else if (controls.BACK)
    {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
			if (!choosePlaylist) {
				FlxTransitionableState.skipNextTransIn = true;
				MusicBeatState.switchState(new archipelago.APCategoryState(archipelago.APPlayState.apGame));
			} else {
				Mods.loadTopMod();
				Mods.currentModDirectory = '';
				PlayState.storyWeek = 0;
				songString = "";
				songStringOG = "";
				selectedPlaylist = null;
				for (item in grpPlaylists.members)
					FlxTween.tween(item, {alpha: 1, x: 0}, 1, {ease: FlxEase.elasticOut, startDelay: (0.2*item.targetY), onComplete: function(t:FlxTween) {
						updateTexts(elapse);
						changeSelection();
						choosePlaylist = false;
					}});
				FlxTween.tween(randomText, {alpha: 1, x: 90}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(difficultyStars, {alpha: 0}, 1, {ease: FlxEase.sineIn});
				// Stop wave effect and tween each letter individually off screen
				readyLettersInPosition = false;
				for (i in 0...readyTxt.letters.length) {
					FlxTween.tween(readyTxt.letters[i], {y: 3000}, 2, {
						ease: FlxEase.elasticInOut,
						startDelay: i * 0.03,
						onComplete: function(tween) {
							if (i == readyTxt.letters.length - 1) {
								readyTxt.y = 3000;
							}
						}
					});
				}
				FlxTween.tween(mainBox, {x: 3000}, 2, {ease: FlxEase.elasticInOut});
				FlxTween.tween(settingsBox, {x: 3000}, 2, {ease: FlxEase.sineIn});
				playCurListPreview(null);
				curSong = 0;
			}
    }

		if (controls.UI_UP_P && !choosePlaylist)
		{
			changeSelection(-shiftMult);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P && !choosePlaylist)
		{
			changeSelection(shiftMult);
			holdTime = 0;
		}

		if ((controls.UI_DOWN || controls.UI_UP) && !choosePlaylist)
    {
      var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapse;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
    }

		if (controls.justPressed('debug_1') && !choosePlaylist) {
			MusicBeatState.switchState(new states.editors.PlaylistEditorState());
		}
  }

  function reloadPlayLists() {
    grpPlaylists.clear();

    loadedPlaylists = apPlaylists;

		if (loadedPlaylists.length == 0) {
			// no need to do anything if there's nothing to do
			return;
		}

    for (i in 0...loadedPlaylists.length) {
		if (loadedPlaylists[i] != null) {
			var listText:Alphabet = null;

			// Check AP locations and color the playlist accordingly
			#if ARCHIPELAGO_ALLOWED
			if (archipelago.APInfo.inArchipelagoMode && archipelago.APInfo.apGame != null) {
				// Check if all song locations are already completed and send playlist location if so
				var checkedLocations = archipelago.APInfo.apGame.info().checkedLocations;
				var allSongsCompleted = true;
				if (loadedPlaylists[i].songLocations != null && loadedPlaylists[i].songLocations.length > 0) {
					for (songLocationId in loadedPlaylists[i].songLocations) {
						if (!checkedLocations.contains(songLocationId)) {
							allSongsCompleted = false;
							break;
						}
					}
				} else {
					allSongsCompleted = false; // No song locations to check
				}

				// If all songs are completed and we have a playlist location ID, send it
				if (allSongsCompleted && loadedPlaylists[i].location_id > 0) {
					trace('All songs in playlist "${loadedPlaylists[i].playlistName}" completed - sending playlist location ${loadedPlaylists[i].location_id}');
					archipelago.APPlayState.apGame.info().LocationChecks([loadedPlaylists[i].location_id]);
				}

				// Check if playlist contains victory song
				var containsVictorySong = false || loadedPlaylists[i].contains_victory; // Short-circuit with metadata flag to avoid unnecessary checks
				if (loadedPlaylists[i].songList != null && !containsVictorySong) {
					for (song in loadedPlaylists[i].songList) {
						if (APFreeplayManager.isVictorySong(song.songName, song.folder)) {
							containsVictorySong = true;
							break;
						}
					}
				}

				// Check completion status
				var allLocations:Array<Int> = [];
				if (loadedPlaylists[i].location_id > 0) {
					allLocations.push(loadedPlaylists[i].location_id);
				}
				if (loadedPlaylists[i].songLocations != null) {
					}

					var checkedCount = 0;
					for (locationId in allLocations) {
						if (archipelago.APInfo.apGame.info().checkedLocations.contains(locationId)) {
							checkedCount++;
						}
					}

					if (containsVictorySong) {
						if (checkedCount == 0 && allLocations.length > 0) {
							// Victory song with no checks - use VictorySong class (RAINBOW)
							listText = new VictorySong(90, 320, loadedPlaylists[i].playlistName, 0xFFFFFFFF, true);
						} else {
							// Other victory song states - use special colors
							var playlistColor = getPlaylistLocationColor(loadedPlaylists[i]);
							listText = new DynamicColoredAlphabet(90, 320, loadedPlaylists[i].playlistName, true, playlistColor, true);
						}
					} else {
						// Normal playlist - use standard colors
						var playlistColor = getPlaylistLocationColor(loadedPlaylists[i]);
						listText = new DynamicColoredAlphabet(90, 320, loadedPlaylists[i].playlistName, true, playlistColor, true);
					}
				} else {
					listText = new DynamicColoredAlphabet(90, 320, loadedPlaylists[i].playlistName, true, true);
				}
				#else
				listText = new DynamicColoredAlphabet(90, 320, loadedPlaylists[i].playlistName, true, true);
				#end

				listText.doShuffle = AprilFools.allowAF ? FlxG.random.bool(10) : false;
				listText.targetY = i;
				grpPlaylists.add(listText);
			} else {
				trace('Playlist ${loadedPlaylists[i]} at index ${i} was null!');
				trace('A PLAYLIST WAS NULL! REMOVING PLAYLIST FROM INTERNAL PLAYLISTS!');
				loadedPlaylists.remove(loadedPlaylists[i]);
			}
    }

    //if I need to do anything else, this function will be here
  }

  /**
	 * Check if bundles exist (we're in AP mode with playlists)
	 */
  function hasPlaylistEnabledBundles():Bool {
	#if ARCHIPELAGO_ALLOWED
	return archipelago.APInfo.inArchipelagoMode && archipelago.APInfo.apGame != null;
	#else
	return false;
	#end
  }

  /**
	 * Check if all songs in a playlist/bundle have difficulties set (not empty string)
	 */
  function playlistHasAllDifficultiesSet(playlist:APPlaylistMetadata):Bool {
	if (playlist.songList == null || playlist.songList.length == 0)
		return true; // Empty playlist is considered "set"
	for (song in playlist.songList) {
		if (song.difficulty == "" || song.difficulty == null || song.difficulty.indexOf(song.songName.toLowerCase()) >= 0) {
			return false; // Found a song without a valid difficulty
		}
	}
	return true;
  }

  /**
	 * Determines the color of a playlist based on AP item unlock status and location completion
	 * If the playlist contains victory songs, uses victory song colors
	 * PURPLE = bundle without difficulties set
	 * PINK = bundle with difficulties set but not all locations checked
	 * RED = locked (don't have the playlist item)
	 * WHITE = no locations checked
	 * GRAY = some locations checked
	 * GREEN = all locations checked
	 *
	 * Victory song coloring (if playlist contains victory song):
	 * RAINBOW = victory song, no checks
	 * ORANGE/BRONZE (random) = victory song, some checks
	 * GOLD = victory song, all checks complete
	 */
  function getPlaylistLocationColor(playlist:APPlaylistMetadata):FlxColor {
	  #if ARCHIPELAGO_ALLOWED
	  if (!archipelago.APInfo.inArchipelagoMode || archipelago.APInfo.apGame == null)
	      return FlxColor.WHITE;

	  // Check if this is a bundle without difficulties set - color purple
	  if (hasPlaylistEnabledBundles() && !playlistHasAllDifficultiesSet(playlist)) {
		  return 0xFF800080; // PURPLE
	  }

	  var apGame = archipelago.APInfo.apGame;
	  var allLocations:Array<Int> = [];

	  // Add the playlist's location_id
	  if (playlist.location_id > 0) {
	      allLocations.push(playlist.location_id);
	  }

	  // Add all song locations
	  if (playlist.songLocations != null) {
	      allLocations = allLocations.concat(playlist.songLocations);
	  }

	  // If no locations, return white
	  if (allLocations.length == 0) {
	      return FlxColor.WHITE;
	  }

	  // Count how many locations have been checked
	  var checkedCount = 0;
	  for (locationId in allLocations) {
	      if (apGame.info().checkedLocations.contains(locationId)) {
	          checkedCount++;
	      }
	  }

	  // Check if playlist contains victory song
	  var containsVictorySong = false || playlist.contains_victory; // Short-circuit with metadata flag to avoid unnecessary checks
	  if (playlist.songList != null && !containsVictorySong) {
	      for (song in playlist.songList) {
	          if (APFreeplayManager.isVictorySong(song.songName, song.folder)) {
	              containsVictorySong = true;
	              break;
	          }
	      }
	  }
			// Color logic using ternary expressions
			var noDifficultyColor = FlxColor.WHITE;

	  return containsVictorySong
	      ? (checkedCount == 0 ? 0xFFFFFFFF // RAINBOW - no checks
	          : checkedCount == allLocations.length ? 0xFFFFD700 // GOLD - all checks complete
	          : (FlxG.random.bool(50) ? 0xFFCD7F32 : 0xFFFFA500)) // ORANGE/BRONZE - some checks
	      : (checkedCount == allLocations.length ? FlxColor.WHITE // WHITE - all checks
	          : checkedCount > 0 ? FlxColor.GRAY // GRAY - some checks
	          : noDifficultyColor); // PINK (bundle with difficulties) or WHITE (default)
	  #else
	  return FlxColor.WHITE;
	  #end
  }

  function switchVisualizer(?hasVocals:Bool = false, ?vocalSND:FlxSound = null, ?oppSND:FlxSound = null) {
		if (ClientPrefs.data.allowVis) {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				if (visual != null) remove(visual);
				visual = new AudioDisplay(FlxG.sound.music, 0, FlxG.height, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.WHITE);
				visual.scrollFactor.set(0, 0);
				add(visual);
				visual.alpha = 0.7;

				if (hasVocals) {
					if (vocalSND != null) {
						if (vocalvisual != null) remove(vocalvisual);
						var color:Array<Int> = Character.grabCharInfo(PlayfieldManager.SONG.player1).get("Health Colors");
						vocalvisual = new AudioDisplay(vocalSND, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, color != null ? FlxColor.fromRGB(color[0], color[1], color[2]) : FlxColor.WHITE);
						vocalvisual.scrollFactor.set(0, 0);
						vocalvisual.flipY = true;
						add(vocalvisual);
						vocalvisual.alpha = 0.7;
					}

					if (oppSND != null) {
						if (oppvisual != null) remove(oppvisual);
						var color:Array<Int> = Character.grabCharInfo(PlayfieldManager.SONG.player2).get("Health Colors");
						oppvisual = new AudioDisplay(oppSND, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, FlxColor.fromRGB(color[0], color[1], color[2]));
						oppvisual.scrollFactor.set(0, 0);
						oppvisual.flipY = true;
						add(oppvisual);
						oppvisual.alpha = 0.7;
					}
				} else {
					if (vocalvisual != null) remove(vocalvisual);
					if (oppvisual != null) remove(oppvisual);
				}
			}
		}
	}

	public static function loadPlaylist(playlistItem:archipelago.APInfo.MixtapeItemData)
	{
		Mods.loadTopMod();
		WeekData.reloadWeekFiles();
		var newPlaylist:APPlaylistMetadata = new APPlaylistMetadata(
			playlistItem.name,
			playlistItem.item_id,
			playlistItem.location_id,
			Std.parseInt(playlistItem.name.charAt(playlistItem.name.length-1)),
			[],
			playlistItem.locations,
			playlistItem.contains_victory
		);
		var tempList:Array<APPlaylistSongMetadata> = [];
		for (song in playlistItem.songs) {
			trace('Loading song ${song} from playlist ${playlistItem.name}');
			var data = APInfo.apGame.getSongAndMod(song).funcAndReturn((d) -> {
				d.song = d.song != null ? d.song : song; // Fallback to song name if lookup fails
				d.mod = d.mod != null ? d.mod : ''; // Fallback to empty string if lookup fails
			});
			trace('Extracted data - Song: ${data.song}, Mod: ${data.mod}');
			/*var fileList:Array<String> = [];
			for (file in FileSystem.readDirectory('mods/${data.mod}/data/${data.song}/'))
			{
				var path = haxe.io.Path.join(['mods/${data.mod}/data/${data.song}/', file.trim()]);
				if (!FileSystem.isDirectory(path) && !file.startsWith('events.') && !file.startsWith('dialogue.'))
				{
					for (fileType in [".json"])
					{
						var fileToCheck:String = file.substr(0, file.length - fileType.length);
						if(fileToCheck.length > 0 && path.endsWith(fileType) && !fileList.contains(fileToCheck))
						{
							fileList.push(fileToCheck);
						}
					}
				}
			}
			trace('Difficulty List: ${fileList}');
			var diff:String = fileList[FlxG.random.int(0, fileList.length-1)].toLowerCase().replace('${data.song.toLowerCase()}', '');
			if (diff == '-') diff = ''; //Normal Difficulty
			else diff = diff.replace('-','');*/ //gonna comment this out so that yuta can do whatever he needs to
			//TODO: add a way to select the difficulty instead of always picking the "hardest" difficulty
			var newSong:APPlaylistSongMetadata = new APPlaylistSongMetadata(
				data.song,
				archipelago.APPlayState.apGame.getWeeksWithIndexForSong(data.song, data.mod)[0].weekIndex,
				"bf",
				[[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]],
				APGameState.instance.getDifficultiesForSong(data.song, data.mod)[-1] //Grab the hardest difficulty by default
			);
			newSong.folder = data.mod;
			tempList.push(newSong);
		}
		newPlaylist.songList = tempList;
		trace('new playlist: ${newPlaylist.toString()}');
		apPlaylists.push(newPlaylist);
	}

	private function updateScrollable(obj:Scrollable, elapsed:Float = 0.0) {
		obj.x = ((obj.targetY - lerpSelected) * obj.distancePerItem.x) + obj.startPosition.x;
		obj.y = ((obj.targetY - lerpSelected) * 1.3 * obj.distancePerItem.y) + obj.startPosition.y;

		if (selected)
			obj.alpha -= elapsed * 4;
		else
			obj.alpha = FlxMath.bound(obj.alpha + elapsed * 5, 0, 0.6);
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			if(grpPlaylists.members[i] != null) grpPlaylists.members[i].visible = grpPlaylists.members[i].active = false;
		}
		_lastVisibles = [];

		updateScrollable(randomText, elapsed);
		if (curSelected == -1)
			randomText.alpha = 1;
		randomIcon.alpha = randomText.alpha;

		var min:Int = Math.round(Math.max(0, Math.min(loadedPlaylists.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(loadedPlaylists.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (grpPlaylists.members[i] != null)
			{
				var item = grpPlaylists.members[i];
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				_lastVisibles.push(i);
			}
		}
	}

	var curSong:Int = 0;
	var curSongFormat = new FlxTextFormat(FlxColor.GREEN);
	public function playCurListPreview(daSongList:Array<APPlaylistSongMetadata>):Void
	{
		if (curSelected == -1 || daSongList == null)
		{
			MusicManager.playMenuMusic(0);
			FlxG.sound.music.fadeIn(2, 0, 0.7);
			switchVisualizer(false);
			curSong = 0;
		}
		else
		{
			Mods.currentModDirectory = daSongList[curSong].folder;
			PlayState.storyWeek = daSongList[curSong].week;
			FunkinSound.playMusic(daSongList[curSong].songName, {
				startingVolume: 0.0,
				overrideExisting: true,
				restartTrack: true,
				pathsFunction: INST,
				loop: false,
				partialParams: {
					loadPartial: true,
					start: 0,
					end: 0.2
				},
				onLoad: function()
				{
					// ? onLoad doesn't start plaing music automatically here
					var endVolume = 0.7;
					FlxG.sound.music.fadeIn(2, 0, endVolume);
					// ? set BPMs
					Mods.currentModDirectory = daSongList[curSong].folder;
					PlayState.storyWeek = daSongList[curSong].week;
					var newBPM = backend.Song.getChart('${daSongList[curSong].songName}${(daSongList[curSong].difficulty.toLowerCase() != "normal" ? '-'+daSongList[curSong].difficulty.toLowerCase() : "")}', daSongList[curSong].songName).bpm;
					Conductor.bpm = newBPM; // ? reimplementing

					var list:Array<String> = songStringOG.split('\n');
					list[curSong] = '?${list[curSong]}?';

					songString = list.join('\n');

					songListTxt.applyMarkup(songString, [new FlxTextFormatMarkerPair(curSongFormat, "?")]);

					//intendedScore = Highscore.getScore(daSongList[curSong].songName, daSongList[curSong].difficulty);

					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				},
				onComplete: function()
				{
					if (curSong < daSongList.length)
						curSong++;

					if (curSong >= daSongList.length - 1)
						curSong = 0;

					Mods.currentModDirectory = daSongList[curSong].folder;
					PlayState.storyWeek = daSongList[curSong].week;
					playCurListPreview(selectedPlaylist.songList);
				},
			});
			FlxTimer.wait(0.25, switchVisualizer.bind(false));
		}
	}

	var shuffleSongs:PsychUICheckBox;
	function makeModifierUI():Void
	{
		var tab_group = settingsBox.getTab('Playlist Modifiers').menu;
		var objX = 10;
		var objY = 10;

		shuffleSongs = new PsychUICheckBox(objX, objY, 'Shuffle Songs', 60, function()
		{
			shufflePlaylist = shuffleSongs.checked;
		});
		tab_group.add(shuffleSongs);
	}
}

@:structInit class APPlaylistSongMetadata extends managers.FreeplayManager.GlobalSongMetadata
{
	public var difficulty:String = "";
	public function new(song:String, week:Int, songCharacter:String, color:Array<Array<Dynamic>>, difficulty:String = "", ?charter:String = "???", ?artist:String = "???")
	{
		super(song, week, songCharacter, color);
		this.difficulty = difficulty;
		this.charter = charter;
		this.artist = artist;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}

	public function toString():String
	{
		return 'APPlaylistSongMetadata("${songName}", week: ${week}, difficulty: "${difficulty}", character: "${songCharacter}", artist: "${artist}", charter: "${charter}", folder: "${folder}")';
	}

}

@:structInit class APPlaylistMetadata
{
	public var playlistName:String = "";
	public var item_id:Int;
	public var location_id:Int;
	public var playlist_index:Int; // For organization
	public var songList:Array<APPlaylistSongMetadata> = [];
	public var songLocations:Array<Int>;
	public var contains_victory:Bool;
	public function new(?playlistName:String = 'unnamed playlist', ?item_id:Int = 0, ?location_id:Int = 0, ?playlist_index:Int = 0, ?songList:Array<APPlaylistSongMetadata>, ?songLocations:Array<Int>, ?contains_victory:Bool)
	{
		this.playlistName = playlistName;
		this.playlist_index = playlist_index;
		this.item_id = item_id;
		this.location_id = location_id;
		this.songList = songList;
		this.songLocations = songLocations;
		this.contains_victory = contains_victory;
	}

	//TODO: Optimize the actual frick out of this holy mother of duck tape and prayer
	public static function convertFromObject(data:APPlaylistMetadataObject):APPlaylistMetadata
	{
		var songList:Array<APPlaylistSongMetadataObject> = data.songList;
		var newSongList:Array<APPlaylistSongMetadata> = [];
		for (song in songList) {
			var newSong:APPlaylistSongMetadata = convertSongFromObject(song);
			newSong.folder = song.folder;
			newSongList.push(newSong);
			trace('added song ${newSong.songName}');
		}
		trace('New Song List: $newSongList');
		var playlist:APPlaylistMetadata = new APPlaylistMetadata(data.playlistName, newSongList);
		return playlist;
	}

	public static function convertSongFromObject(data:APPlaylistSongMetadataObject):APPlaylistSongMetadata
	{
		var song:APPlaylistSongMetadata = new APPlaylistSongMetadata(data.songName, data.week, data.songCharacter, data.color, data.difficulty);
		return song;
	}

	public static function convertFreeplaySong(data:managers.FreeplayManager.GlobalSongMetadata):APPlaylistSongMetadata
	{
		var song:APPlaylistSongMetadata = new APPlaylistSongMetadata(data.songName, data.week, data.songCharacter, data.color, "`");
		return song;
	}

	public inline function copy():APPlaylistMetadata
	{
		var playlist:APPlaylistMetadata = new APPlaylistMetadata(this.playlistName, this.item_id, this.location_id, this.playlist_index, this.songList.copy(), this.songLocations.copy(), this.contains_victory);
		return playlist;
	}

	public function toString():String
	{
		return 'APPlaylistMetadata("${playlistName}", item_id: "${item_id}", location_id: "${location_id}", playlist_index: "${playlist_index}", songs: ${songList}, songLocations: ${songLocations}, contains_victory: ${contains_victory})';
	}
}

//This is so that I can grab JSON data
typedef APPlaylistMetadataObject = {
	var playlistName:String;
	var item_id:Int;
	var location_id:Int;
	var playlist_index:Int; // For organization
	var songList:Array<APPlaylistSongMetadataObject>;
	var songLocations:Array<Int>;
	var contains_victory:Bool;
}

typedef APPlaylistSongMetadataObject = {
	var difficulty:String;
	var songName:String;
	var week:Int;
	var songCharacter:String;
	var color:Array<Array<Dynamic>>;
	var folder:String;
}

/**
 * Substate for selecting difficulties for each song in a bundle
 */
enum BundleDifficultyPhase {
	SONG_SELECTION;
	SUMMARY;
	COMPLETE;
}

class BundleDifficultySelectionSubstate extends MusicBeatSubstate {
	var playlist:APPlaylistMetadata;
	var onComplete:APPlaylistMetadata->Void;
	var currentPhase:BundleDifficultyPhase = SONG_SELECTION;
	var currentSongIndex:Int = 0;
	var songDifficulties:Map<Int, Array<{difficulty:String, weekIndexes:Array<Int>}>> = new Map();
	var selectedDifficulties:Map<Int, {difficulty:String, weekIndex:Int}> = new Map();

	// UI Elements
	var background:FlxSprite;
	var gradientOverlay:FlxSprite;
	var mainPanel:FlxSprite;
	var titleText:FlxText;
	var instructionText:FlxText;
	var songProgressText:FlxText;
	var difficultyButtonGroup:FlxTypedGroup<FlxSprite>;
	var difficultyTextGroup:FlxTypedGroup<FlxText>;
	var summaryText:FlxText;
	var confirmButtonText:FlxText;
	var cancelButtonText:FlxText;

	var navigationCooldown:Float = 0;
	var isAnimating:Bool = false;

	public function new(playlist:APPlaylistMetadata, onComplete:APPlaylistMetadata->Void) {
		super();
		this.playlist = playlist.copy();
		this.onComplete = onComplete;
	}

	override function create() {
		super.create();

		// Load difficulties for each song
		loadSongDifficulties();

		// Initialize selected difficulties with current values or first available
		initializeSelectedDifficulties();

		// Setup background
		setupBackground();

		// Setup main UI panel
		setupMainPanel();

		// Setup initial phase
		showSongSelection();
	}

	function setupBackground():Void {
		// Semi-transparent dark background
		background = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 200));
		background.scrollFactor.set();
		add(background);

		// Animated gradient overlay
		gradientOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			[0x00000000, 0x3300FFFF, 0x00000000], 1, 0);
		gradientOverlay.scrollFactor.set();
		gradientOverlay.alpha = 0.3;
		add(gradientOverlay);

		// Animate gradient
		FlxTween.tween(gradientOverlay, {alpha: 0.5}, 2, {
			type: PINGPONG,
			ease: FlxEase.sineInOut
		});
	}

	function setupMainPanel():Void {
		// Main gradient panel
		mainPanel = FlxGradient.createGradientFlxSprite(800, 500,
			[FlxColor.fromRGB(30, 30, 60), FlxColor.fromRGB(50, 30, 80)], 1, 90);
		mainPanel.x = (FlxG.width - mainPanel.width) / 2;
		mainPanel.y = (FlxG.height - mainPanel.height) / 2;
		mainPanel.scrollFactor.set();
		add(mainPanel);

		// Title
		titleText = new FlxText(mainPanel.x + 30, mainPanel.y + 30, mainPanel.width - 60, "", 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.scrollFactor.set();
		add(titleText);

		// Instruction/Info text
		instructionText = new FlxText(mainPanel.x + 30, mainPanel.y + 80, mainPanel.width - 60, "", 16);
		instructionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		instructionText.borderSize = 1;
		instructionText.scrollFactor.set();
		add(instructionText);

		// Progress text
		songProgressText = new FlxText(mainPanel.x + 30, mainPanel.y + 460, mainPanel.width - 60, "", 12);
		songProgressText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, RIGHT, OUTLINE, FlxColor.BLACK);
		songProgressText.borderSize = 1;
		songProgressText.scrollFactor.set();
		add(songProgressText);

		// Difficulty buttons group
		difficultyButtonGroup = new FlxTypedGroup<FlxSprite>();
		difficultyTextGroup = new FlxTypedGroup<FlxText>();
		add(difficultyButtonGroup);
		add(difficultyTextGroup);

		// Summary text (hidden initially)
		summaryText = new FlxText(mainPanel.x + 30, mainPanel.y + 120, mainPanel.width - 60, "", 14);
		summaryText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		summaryText.borderSize = 1;
		summaryText.scrollFactor.set();
		summaryText.active = false;
		add(summaryText);
	}

	function initializeSelectedDifficulties():Void {
		for (i in 0...playlist.songList.length) {
			var currentDiff = playlist.songList[i].difficulty;
			if (currentDiff == "" || currentDiff == null) {
				// Pick first available difficulty with random week
				if (songDifficulties.exists(i) && songDifficulties[i].length > 0) {
					var diffEntry = songDifficulties[i][0];
					var randomWeekIndex = diffEntry.weekIndexes[FlxG.random.int(0, diffEntry.weekIndexes.length - 1)];
					selectedDifficulties[i] = {difficulty: diffEntry.difficulty, weekIndex: randomWeekIndex};
				}
			} else {
				// Find the difficulty entry matching the current difficulty (case-insensitive)
				if (songDifficulties.exists(i)) {
					for (diffEntry in songDifficulties[i]) {
						if (diffEntry.difficulty.toLowerCase() == currentDiff.toLowerCase()) {
							var randomWeekIndex = diffEntry.weekIndexes[FlxG.random.int(0, diffEntry.weekIndexes.length - 1)];
							selectedDifficulties[i] = {difficulty: diffEntry.difficulty, weekIndex: randomWeekIndex};
							break;
						}
					}
				}
			}
		}
	}

	function loadSongDifficulties():Void {
		for (i in 0...playlist.songList.length) {
			var song = playlist.songList[i];
			var difficultyEntries:Array<{difficulty:String, weekIndex:Int}> = [];

			// Get available difficulties with week indexes from the game
			#if ARCHIPELAGO_ALLOWED
			if (archipelago.APPlayState.apGame != null) {
				difficultyEntries = archipelago.APPlayState.apGame.getDifficultiesWithWeekIndexes(song.songName, song.folder);
			}
			#end
			trace("difficultyEntries: "+difficultyEntries);
			trace("difficultyList: "+archipelago.APPlayState.apGame.getDifficultiesWithWeekIndexes(song.songName, song.folder));

			// Fallback if no difficulties found
			if (difficultyEntries.length == 0) {
				difficultyEntries = [
					{difficulty: "easy", weekIndex: 0},
					{difficulty: "normal", weekIndex: 0},
					{difficulty: "hard", weekIndex: 0}
				];
			}

			// Deduplicate by difficulty name (case-insensitive) and group week indexes
			var uniqueDifficulties:Map<String, Array<Int>> = new Map();
			for (entry in difficultyEntries) {
				var diffLower = entry.difficulty.toLowerCase();
				if (!uniqueDifficulties.exists(diffLower)) {
					uniqueDifficulties.set(diffLower, []);
				}
				var weekIndexes = uniqueDifficulties.get(diffLower);
				if (weekIndexes.indexOf(entry.weekIndex) == -1) {
					weekIndexes.push(entry.weekIndex);
				}
			}

			// Convert back to array of unique difficulties with their week indexes
			var uniqueDiffArray:Array<{difficulty:String, weekIndexes:Array<Int>}> = [];
			for (diffLower => weekIndexes in uniqueDifficulties) {
				var originalDiff = "";
				for (entry in difficultyEntries) {
					if (entry.difficulty.toLowerCase() == diffLower) {
						originalDiff = entry.difficulty;
						break;
					}
				}
				uniqueDiffArray.push({difficulty: originalDiff, weekIndexes: weekIndexes});
			}

			songDifficulties[i] = uniqueDiffArray;
		}
	}

	function showSongSelection():Void {
		currentPhase = SONG_SELECTION;
		difficultyButtonGroup.clear();
		difficultyTextGroup.clear();
		summaryText.active = false;

		if (currentSongIndex < 0 || currentSongIndex >= playlist.songList.length) {
			showSummary();
			return;
		}

		var song = playlist.songList[currentSongIndex];
		titleText.text = song.songName.toUpperCase();
		songProgressText.text = 'Song ${currentSongIndex + 1} of ${playlist.songList.length}';
		instructionText.text = "Use LEFT/RIGHT arrows to select difficulty\nPress ENTER to confirm, ESC to cancel";

		var difficulties = songDifficulties.get(currentSongIndex);
		var currentSelection = selectedDifficulties.get(currentSongIndex);

		if (difficulties != null && difficulties.length > 0) {
			// Calculate button layout
			var availableWidth = mainPanel.width - 60;
			var buttonWidth = 100;
			var buttonHeight = 80;
			var spacing = 15;
			var totalWidth = (buttonWidth * difficulties.length) + (spacing * (difficulties.length - 1));
			var startX = mainPanel.x + 30 + ((availableWidth - totalWidth) / 2);
			var buttonY = mainPanel.y + 180;

			for (i in 0...difficulties.length) {
				var diffEntry = difficulties[i];
				var isSelected = currentSelection != null && diffEntry.difficulty == currentSelection.difficulty;

				// Button background
				var buttonX = startX + (i * (buttonWidth + spacing));
				var button = new FlxSprite(buttonX, buttonY);
				var buttonColor = isSelected ? FlxColor.fromRGB(0, 200, 255) : FlxColor.fromRGB(80, 80, 100);
				button.makeGraphic(buttonWidth, buttonHeight, buttonColor);
				button.scrollFactor.set();
				difficultyButtonGroup.add(button);

				// Button text
				var text = new FlxText(button.x, button.y + 22, button.width, diffEntry.difficulty.toUpperCase(), 20);
				var textColor = isSelected ? FlxColor.BLACK : FlxColor.WHITE;
				text.setFormat(Paths.font("vcr.ttf"), 20, textColor, CENTER, OUTLINE, FlxColor.BLACK);
				text.borderSize = 1;
				text.scrollFactor.set();
				difficultyTextGroup.add(text);
			}
		}
	}

	function showSummary():Void {
		currentPhase = SUMMARY;
		difficultyButtonGroup.clear();
		difficultyTextGroup.clear();
		summaryText.active = true;

		titleText.text = "CONFIRM SELECTIONS";
		instructionText.text = "Review your selections below. Press ENTER to confirm, ESC to go back and change selections.";
		songProgressText.text = "";

		// Build summary text
		var summaryContent = "SONG DIFFICULTY SETTINGS:\n\n";
		for (i in 0...playlist.songList.length) {
			var song = playlist.songList[i];
			var selection = selectedDifficulties.get(i);
			var diffText = selection != null ? selection.difficulty : "Not set";
			summaryContent += '${i + 1}. ${song.songName} → $diffText\n';
		}

		summaryText.text = summaryContent;
		summaryText.y = mainPanel.y + 120;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		navigationCooldown -= elapsed;

		switch (currentPhase) {
			case SONG_SELECTION:
				updateSongSelection(elapsed);
			case SUMMARY:
				updateSummary(elapsed);
			case COMPLETE:
				// Nothing to do, just waiting to close
		}
	}

	function updateSongSelection(elapsed:Float):Void {
		if (isAnimating) return;

		if (currentSongIndex < 0 || currentSongIndex >= playlist.songList.length) {
			showSummary();
			return;
		}

		var difficulties = songDifficulties.get(currentSongIndex);
		var currentSelection = selectedDifficulties.get(currentSongIndex);

		if (difficulties != null && difficulties.length > 0) {
			// Find current index
			var currentIndex = -1;
			if (currentSelection != null) {
				for (i in 0...difficulties.length) {
					if (difficulties[i].difficulty == currentSelection.difficulty) {
						currentIndex = i;
						break;
					}
				}
			}
			if (currentIndex == -1) currentIndex = 0;

			// Navigate difficulties
			if (FlxG.keys.justPressed.LEFT && navigationCooldown <= 0) {
				currentIndex--;
				if (currentIndex < 0) currentIndex = difficulties.length - 1;
				var diffEntry = difficulties[currentIndex];
				var randomWeekIndex = diffEntry.weekIndexes[FlxG.random.int(0, diffEntry.weekIndexes.length - 1)];
				selectedDifficulties[currentSongIndex] = {difficulty: diffEntry.difficulty, weekIndex: randomWeekIndex};
				showSongSelection();
				navigationCooldown = 0.15;
			}

			if (FlxG.keys.justPressed.RIGHT && navigationCooldown <= 0) {
				currentIndex++;
				if (currentIndex >= difficulties.length) currentIndex = 0;
				var diffEntry = difficulties[currentIndex];
				var randomWeekIndex = diffEntry.weekIndexes[FlxG.random.int(0, diffEntry.weekIndexes.length - 1)];
				selectedDifficulties[currentSongIndex] = {difficulty: diffEntry.difficulty, weekIndex: randomWeekIndex};
				showSongSelection();
				navigationCooldown = 0.15;
			}
		}

		// Confirm and move to next song
		if (FlxG.keys.justPressed.ENTER && navigationCooldown <= 0) {
			currentSongIndex++;
			if (currentSongIndex >= playlist.songList.length) {
				showSummary();
			} else {
				showSongSelection();
			}
			navigationCooldown = 0.2;
		}

		// Cancel
		if (FlxG.keys.justPressed.ESCAPE) {
			close();
		}
	}

	function updateSummary(elapsed:Float):Void {
		if (FlxG.keys.justPressed.ENTER) {
			// Apply all selections and complete
			for (i in 0...playlist.songList.length) {
				if (selectedDifficulties.exists(i)) {
					var selection = selectedDifficulties[i];
					playlist.songList[i].difficulty = selection.difficulty;
					playlist.songList[i].week = selection.weekIndex;
				}
			}
			onComplete(playlist);
			close();
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			// Go back to first song
			currentSongIndex = 0;
			showSongSelection();
		}
	}
}
