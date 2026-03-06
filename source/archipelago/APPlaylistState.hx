package archipelago;
import Random;
import backend.Highscore;
import backend.Song;
import backend.WeekData;
import flixel.addons.ui.FlxUIInputText; // TODO: get rid of this in place of the psych varient
import flixel.util.FlxColor;
import managers.APFreeplayManager;
import objects.Alphabet.DynamicAlphabet;
import objects.Alphabet.DynamicColoredAlphabet;
import objects.Alphabet;
import objects.Character;
import objects.HealthIcon;
import options.GameplayChangersSubstate;
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

		if (!choosePlaylist) {
			updateTexts(elapse);
			// Refresh playlist colors in AP mode to reflect location completion changes
			#if ARCHIPELAGO_ALLOWED
			if (archipelago.APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
				for (i in 0...grpPlaylists.members.length) {
					if (i < loadedPlaylists.length && grpPlaylists.members[i] != null) {
						var playlistColor = getPlaylistLocationColor(loadedPlaylists[i]);
						grpPlaylists.members[i].color = playlistColor;
					}
				}
			}
			#end
		}

		e++;
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
				PlayState.campaignMisses = 0;
				PlayState.campaignScore = 0;
				PlayState.isPlaylist = true;
				PlayState.altInstrumentals = null; // ? P-Slice
				Mods.loadTopMod();
				WeekData.reloadWeekFiles();
				if (shufflePlaylist) {
					FlxG.random.shuffle(selectedPlaylist.songList);
				}
				// PlayState.curPlaylist = selectedPlaylist;
				// PlayState.curSonglist = selectedPlaylist.songList;
				var songLowercase:String = Paths.formatToSongPath(selectedPlaylist.songList[0].songName);
				Mods.currentModDirectory = selectedPlaylist.songList[0].folder != null ? selectedPlaylist.songList[0].folder : '';
				PlayState.storyWeek = selectedPlaylist.songList[0].week;
				Song.loadFromJson('${songLowercase}${(selectedPlaylist.songList[0].difficulty.toLowerCase() != "normal" ? "-"+selectedPlaylist.songList[0].difficulty.toLowerCase() : "")}', songLowercase);
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new APPlayState());
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
				if (archipelago.APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
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
						allLocations = allLocations.concat(loadedPlaylists[i].songLocations);
					}

					var checkedCount = 0;
					for (locationId in allLocations) {
						if (archipelago.APEntryState.apGame.info().checkedLocations.contains(locationId)) {
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
	 * Determines the color of a playlist based on AP item unlock status and location completion
	 * If the playlist contains victory songs, uses victory song colors
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
	  if (!archipelago.APEntryState.inArchipelagoMode || archipelago.APEntryState.apGame == null)
	      return FlxColor.WHITE;

	  var apGame = archipelago.APEntryState.apGame;
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
	  return containsVictorySong
	      ? (checkedCount == 0 ? 0xFFFFFFFF // RAINBOW - no checks
	          : checkedCount == allLocations.length ? 0xFFFFD700 // GOLD - all checks complete
	          : (FlxG.random.bool(50) ? 0xFFCD7F32 : 0xFFFFA500)) // ORANGE/BRONZE - some checks
	      : (checkedCount == allLocations.length ? FlxColor.GREEN // GREEN - all checks
	          : checkedCount > 0 ? FlxColor.GRAY // GRAY - some checks
	          : FlxColor.WHITE); // WHITE - no checks
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
						var color:Array<Int> = Character.grabCharInfo(PlayState.SONG.player1).get("Health Colors");
						vocalvisual = new AudioDisplay(vocalSND, 0, 0, FlxG.width, Std.int(FlxG.height / 2), 100, 4, color != null ? FlxColor.fromRGB(color[0], color[1], color[2]) : FlxColor.WHITE);
						vocalvisual.scrollFactor.set(0, 0);
						vocalvisual.flipY = true;
						add(vocalvisual);
						vocalvisual.alpha = 0.7;
					}

					if (oppSND != null) {
						if (oppvisual != null) remove(oppvisual);
						var color:Array<Int> = Character.grabCharInfo(PlayState.SONG.player2).get("Health Colors");
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
			var data = APEntryState.apGame.getSongAndMod(song);
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
			var newSong:APPlaylistSongMetadata = new APPlaylistSongMetadata(
				data.song,
				WeekData.weeksList.indexOf(data.mod),
				"bf",
				[[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]],
				"" //diff
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
		return 'APPlaylistSongMetadata("${songName}", week: ${week}, difficulty: "${difficulty}", character: "${songCharacter}", artist: "${artist}", charter: "${charter}")';
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
