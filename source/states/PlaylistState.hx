package states;
import backend.Highscore;
import backend.Song;
import backend.WeekData;
import flixel.addons.ui.FlxUIInputText; // TODO: get rid of this in place of the psych varient
import flixel.math.FlxRandom;
import objects.Alphabet.DynamicAlphabet;
import objects.Character;
import objects.HealthIcon;
import options.GameplayChangersSubstate;
import states.PlaylistState.PlaylistMetadata;
import states.freeplay.backend.DifficultyStars;
import yutautil.AprilFools;
class PlaylistState extends MusicBeatState {
  public var loadedPlaylists:Array<PlaylistMetadata> = [];
	var selectedPlaylist:PlaylistMetadata = null;

  private static var curSelected:Int = 0;
  var lerpSelected:Float = 0;

  var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var lerpDeaths:Int = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedDeaths:Int = 0;

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

  public var searchBar:FlxUIInputText;

  var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;

  var albumPhoto:FlxSprite;
	var difficultyStars:DifficultyStars;
  var rank:RankingManager;
  public static var doChange:Bool = false;

	var readyTxt:ColoredAlphabet;
	var mainBox:PsychUIBox;
	var settingsBox:PsychUIBox;
	var songListTxt:FlxText;

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
		DiscordClient.changePresence("Selecting Their Mixtape...", null);
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

		albumPhoto = new FlxSprite(930, 0).loadGraphic(Paths.image('albums/NoCover'));
		albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
		albumPhoto.screenCenter(Y);
		albumPhoto.y += 20;
		add(albumPhoto);
		albumPhoto.alpha = 0.6;

		difficultyStars = new DifficultyStars(albumPhoto.x, albumPhoto.y - 130);
		difficultyStars.visible = true;
    difficultyStars.scrollFactor.set();
    add(difficultyStars);

		reloadPlayLists();

		if (loadedPlaylists.length < 1) {
      FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO PLAYLISTS FOUND!\n\nPress ACCEPT to go to the Playlist Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.PlaylistEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
    }

    //Search bar my belovid
		searchBar = new FlxUIInputText(FlxG.height, 100, 800, '', 20);
		searchBar.screenCenter(X);
		//searchBar.x -= 200;
		//add(searchBar);
		searchBar.backgroundColor = FlxColor.GRAY;
		searchBar.lines = 1;
		searchBar.autoSize = false;
		searchBar.alignment = FlxTextAlign.CENTER;
		searchBar.bold = true;
		searchBar.font = Paths.font("FridayNightFunkin.ttf");
		searchBar.alpha = 0.8;
		searchBar.text = '';
		searchBar.updateHitbox();

    FlxG.mouse.visible = true;

    scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		//add(diffText);

		add(scoreText);

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

    rank.doTween('in');
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
			}
		}

		if (curSelected != -1 || loadedPlaylists[curSelected] != null) {
			if (loadedPlaylists[curSelected]?.bg != null && loadedPlaylists[curSelected]?.bg != '') {
				bg.loadGraphic(Paths.image(loadedPlaylists[curSelected].bg));
				bg.screenCenter();
			} else {
				bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
				bg.screenCenter();
			}

			if (albumPhoto != null) {
				albumPhoto.visible = true;
				if (loadedPlaylists[curSelected]?.album != null && loadedPlaylists[curSelected]?.album != '') {
					albumPhoto.loadGraphic(Paths.image('albums/${Std.string(loadedPlaylists[curSelected].album)}'));
					albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
					albumPhoto.screenCenter(Y);
					albumPhoto.y += 20;
				} else {
					albumPhoto.loadGraphic(Paths.image('albums/NoCover'));
					albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
					albumPhoto.screenCenter(Y);
					albumPhoto.y += 20;
				}
			}

			difficultyStars.setNumber(loadedPlaylists[curSelected]?.difficulty ?? 0);
			difficultyStars.visible = true;
		} else {
			bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
			bg.screenCenter();
			if (albumPhoto != null)
				albumPhoto.visible = false;
			difficultyStars.setNumber(0);
			difficultyStars.visible = false;
		}

		intendedScore = Highscore.getPlaylistScore(loadedPlaylists[curSelected]?.playlistName);
		//intendedRating = Highscore.getRating(fpManager.songList[curSelected].songName, curDifficulty);
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
  }

	var holdTime:Float = 0;
	var choosePlaylist:Bool = false;
	var e:Float = 0;
	var songString:String = "";
	var songStringOG:String = "";
  override function update(elapse:Float) {
    super.update(elapse);

		if (!choosePlaylist)
			updateTexts(elapse);

		e++;
		if (readyTxt != null)
			for (i in 0...readyTxt.letters.length) {
				readyTxt.letters[i].color = FlxColor.fromHSL((((e / 2) / 300 * 360) % 360)+(15*i), 1.0, 0.5*1.0);
				readyTxt.letters[i].offset.y = (Math.sin((e*0.001) * 2) * 5)+(15*i);
			}

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapse * 24)));
		//lerpDeaths = Math.floor(FlxMath.lerp(intendedDeaths, lerpDeaths, Math.exp(-elapsed * 24)));
		//lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		/*if (Math.abs(lerpDeaths - intendedDeaths) <= 10)
			lerpDeaths = intendedDeaths;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;*/

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}

		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		try {
		if (curSelected == -1)
			scoreText.text = 'RANDOM SONG';
		else
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1}', [lerpScore]);
		} catch(e) {trace("it broke????\nError: "+e);}

		diffText.text = 'Deaths: $lerpDeaths';
		positionHighscore();

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
			if (!choosePlaylist) {
				choosePlaylist = true;
				selectedPlaylist = loadedPlaylists[curSelected].copy();
				for (song in selectedPlaylist.songList)
					songString += '${song.songName}\n';

				songStringOG = songString;
				songListTxt.text = songString;
				mainBox.resize(Std.int(songListTxt.width + 50), Std.int(songListTxt.height + 50));
				for (item in grpPlaylists.members)
					FlxTween.tween(item, {alpha: 0, x: -3000}, 1, {ease: FlxEase.sineIn, startDelay: (0.2*item.targetY)});
				//FlxTween.tween(rank, {alpha: 0, x: -3000}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(randomText, {alpha: 0, x: 3000}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(albumPhoto, {alpha: 0, x: 3000}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(difficultyStars, {alpha: 0, x: 3000}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(readyTxt, {y: 550}, 2, {ease: FlxEase.elasticOut});
				FlxTween.tween(settingsBox, {x: 930}, 1, {ease: FlxEase.elasticOut});
				//FlxTween.tween(searchBar, {y: -3000}, 1, {ease: FlxEase.elasticOut});
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
				PlayState.curPlaylist = selectedPlaylist;
				PlayState.curSonglist = selectedPlaylist.songList;
				var songLowercase:String = Paths.formatToSongPath(selectedPlaylist.songList[0].songName);
				Mods.currentModDirectory = selectedPlaylist.songList[0].folder != null ? selectedPlaylist.songList[0].folder : '';
				PlayState.storyWeek = selectedPlaylist.songList[0].week;
				Song.loadFromJson('${songLowercase}${(selectedPlaylist.songList[0].difficulty.toLowerCase() != "normal" ? "-"+selectedPlaylist.songList[0].difficulty.toLowerCase() : "")}', songLowercase);
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState());
			}
    }
    else if (controls.BACK)
    {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
			if (!choosePlaylist) {
				FlxTransitionableState.skipNextTransIn = true;
				MusicBeatState.switchState(new MainMenuState());
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
				//FlxTween.tween(rank, {alpha: 1, x: 90}, 2, {ease: FlxEase.sineIn});
				FlxTween.tween(randomText, {alpha: 1, x: 90}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(albumPhoto, {alpha: 1, x: 930}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(difficultyStars, {alpha: 1, x: 930}, 1, {ease: FlxEase.sineIn});
				FlxTween.tween(readyTxt, {y: 3000}, 2, {ease: FlxEase.elasticInOut});
				FlxTween.tween(mainBox, {x: 3000}, 2, {ease: FlxEase.elasticInOut});
				FlxTween.tween(settingsBox, {x: 3000}, 2, {ease: FlxEase.sineIn});
				//FlxTween.tween(searchBar, {y: 100}, 1, {ease: FlxEase.elasticOut});
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

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

  function reloadPlayLists() {
    grpPlaylists.clear();

    loadedPlaylists = loadPlaylists();

		if (loadedPlaylists.length == 0) {
			// no need to do anything if there's nothing to do
			return;
		}

    for (i in 0...loadedPlaylists.length) {
			if (loadedPlaylists[i] != null) {
				var listText:Alphabet = null;
				listText = new DynamicAlphabet(90, 320, loadedPlaylists[i].playlistName, true, true);
				listText.doShuffle = AprilFools.allowAF ? FlxG.random.bool(10) : false;
				listText.targetY = i;
				grpPlaylists.add(listText);
			} else {
				trace('A PLAYLIST WAS NULL! REMOVING PLAYLIST FROM INTERNAL PLAYLISTS!');
				loadedPlaylists.remove(loadedPlaylists[i]);
				ClientPrefs.data.playLists.remove(loadedPlaylists[i]);
				ClientPrefs.saveSettings();
			}
    }

    //if I need to do anything else, this function will be here
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

	public static function loadPlaylists():Array<PlaylistMetadata>
	{
		var playlists:Array<PlaylistMetadata> = [];
		playlists.pushMany(ClientPrefs.data.playLists ?? []); // GOD how DUMB AM I?????

		// mod-specific playlist support maybe??? idk could be cool
		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('playlists/'),
			Paths.mods(Mods.currentModDirectory + '/playlists/'),
			Paths.getSharedPath('playlists/')
		];
		for (mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/playlists/'));
		for (directory in directories)
		{
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var playlistData:PlaylistMetadata = loadPlaylistFile(path);
						//trace('Playlist: ${playlistData}');
						if(playlistData != null)
						{
							var isDupe:Bool = false;
							//TODO: find a better way to check for dupes
							/*for (playlist in playlists)
							{
								if (playlist.playlistName == playlistData.playlistName)
								{
									trace('Playlist "' + playlistData.playlistName + '" already exists! Skipping duplicate from ' + path);
									isDupe = true;
									break;
								}
							}*/
							if (!isDupe) {
								playlists.push(playlistData);
								trace('Added ${playlistData.playlistName}');
							}
						} else {
							if (playlistData == null)
								trace('PLAYLIST WAS NULL!');
							else
								trace('PLAYLIST WAS FINE BUT ERRORED ANYWAY SOMEHOW!');
						}
					}
				}
			}
		}
		#end
		return playlists;
	}

	public static function loadPlaylistFile(path:String):PlaylistMetadata
	{
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			//trace('Raw: ${rawJson}');
			//trace('Result: ${haxe.Json.parse(rawJson)}');
			var playlistObject:PlaylistMetadataObject = cast haxe.Json.parse(rawJson);
			//trace(playlistObject);
			var playlistResult:PlaylistMetadata = PlaylistMetadata.convertFromObject(playlistObject);
			return playlistResult;
		} else {
			if(rawJson == null)
				trace('Json file was null!');
			else if (rawJson != null && rawJson.length <= 0)
				trace('Json file was empty!\nJson: ${rawJson}');
		}
		return null;
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
	public function playCurListPreview(daSongList:Array<PlaylistSongMetadata>):Void
	{
		if (curSelected == -1 || daSongList == null)
		{
			FunkinSound.playMusic(Paths.formatToSongPath(ClientPrefs.data.menuSong), {
        pathsFunction: BASE,
				startingVolume: 0.0,
				overrideExisting: true,
				restartTrack: false
			});
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

					FlxTimer.wait(FlxG.sound.music.length-2000, FlxG.sound.music.fadeIn.bind(0, 2, 0));
				},
				onComplete: function()
				{
					if (curSong < daSongList.length)
						curSong++;

					if (curSong >= daSongList.length - 1)
						curSong = 0;

					trace('curSongIndex: $curSong');

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

class PlaylistSongMetadata extends managers.FreeplayManager.GlobalSongMetadata
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

}

class PlaylistMetadata
{
	public var playlistName:String = "";
	public var bg:String = "";
	public var icon:String = "";
	public var album:String = "";
	public var difficulty:Int = -1;
	public var color:Array<Dynamic> = [];
	public var songList:Array<PlaylistSongMetadata> = [];
	public function new(?playlistName:String = 'unnamed playlist', ?bg:String = 'menuDesat', ?icon:String = 'bf', ?album:String = 'nocover', ?color:Array<Dynamic>, ?songList:Array<PlaylistSongMetadata>)
	{
		this.playlistName = playlistName;
		this.bg = bg;
		this.icon = icon;
		this.album = album;
		this.color = color;
		this.songList = songList;
	}

	//TODO: Optimize the actual frick out of this holy mother of duck tape and prayer
	public static function convertFromObject(data:PlaylistMetadataObject):PlaylistMetadata
	{
		var songList:Array<PlaylistSongMetadataObject> = data.songList;
		var newSongList:Array<PlaylistSongMetadata> = [];
		for (song in songList) {
			var newSong:PlaylistSongMetadata = convertSongListFromObject(song);
			newSong.folder = song.folder;
			newSongList.push(newSong);
			trace('added song ${newSong.songName}');
		}
		trace('New Song List: $newSongList');
		var playlist:PlaylistMetadata = new PlaylistMetadata(data.playlistName, data.bg, data.icon, data.album, data.color, newSongList);
		return playlist;
	}

	public static function convertSongListFromObject(data:PlaylistSongMetadataObject):PlaylistSongMetadata
	{
		var songlist:PlaylistSongMetadata = new PlaylistSongMetadata(data.songName, data.week, data.songCharacter, data.color, data.difficulty);
		return songlist;
	}

	public inline function copy():PlaylistMetadata
	{
		var playlist:PlaylistMetadata = new PlaylistMetadata(this.playlistName, this.bg, this.icon, this.album, this.color, this.songList);
		return playlist;
	}
}

//This is so that I can grab JSON data
typedef PlaylistMetadataObject = {
	var playlistName:String;
	var bg:String;
	var icon:String;
	var album:String;
	var difficulty:Int;
	var color:Array<Dynamic>;
	var songList:Array<PlaylistSongMetadataObject>;
}

typedef PlaylistSongMetadataObject = {
	var difficulty:String;
	var songName:String;
	var week:Int;
	var songCharacter:String;
	var color:Array<Array<Dynamic>>;
	var folder:String;
}
