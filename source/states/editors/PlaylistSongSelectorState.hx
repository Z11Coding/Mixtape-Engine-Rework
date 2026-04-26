package states.editors;

import backend.Highscore;
import backend.Song;
import backend.WeekData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIInputText;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.ui.FlxButton;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import metadata.STMetaFile.MetadataFile;
import objects.Alphabet.DynamicAlphabet;
import objects.Alphabet.DynamicColoredAlphabet;
import objects.Character;
import objects.HealthIcon;
import options.GameplayChangersSubstate;
import states.PlaylistState.PlaylistMetadata;
import states.PlaylistState.PlaylistSongMetadata;
import states.editors.ChartingState;
import states.editors.ChartingStateOG;
import states.editors.PlaylistEditorState.PlaylistMetaDataEditor;
import states.freeplay.backend.DifficultyStars;
import substates.Prompt;
import substates.ResetScoreSubState;
import yutautil.AprilFools;
import yutautil.ChanceSelector.Chance;
import yutautil.ChanceSelector;

class PlaylistSongSelectorState extends MusicBeatState
{
  var curPlaylist:PlaylistMetadata;

  public static var instance:PlaylistSongSelectorState = null; // Guess I DO need this.

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconList:FlxTypedGroup<HealthIcon>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var selected:Bool = false;
	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var randomText:Scrollable;
	var randomIcon:HealthIcon;

	public var searchBar:FlxUIInputText;
	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	public static var SONG:SwagSong = null;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var songChoices:Array<String> = [];
	var listChoices:Array<String> = [];
	var multiSongs:Array<String> = [];

	public static var doChange:Bool = false;
	public static var multisong:Bool = false;

  var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;

	var albumPhoto:FlxSprite;
	var difficultyStars:DifficultyStars;

	public var fpManager:FreeplayManager;
	override function create()
	{
    curPlaylist = PlaylistMetaDataEditor.playlist; // Because PlaylistMetaDataEditor is the only way to access this state, assume the playlist is from there.
		#if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end
		Cursor.cursorMode = Default;

    instance = this; // for the manager

		fpManager = FreeplayManager.loadFPManager();

		Highscore.reloadModifiers();
		Paths.clearStoredWithoutStickers();

		persistentUpdate = true;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Selecting Songs for Playlist", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR SONG SELECTION\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Playlist Editor.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.editors.PlaylistEditorState(PlaylistMetaDataEditor.playlist))));
			return;
		}

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

		switchVisualizer();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

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


		WeekData.setDirectoryFromWeek();

		//Search bar my belovid
		searchBar = new FlxUIInputText(FlxG.height, 100, 800, '', 20);
		searchBar.screenCenter(X);
		//searchBar.x -= 200;
		add(searchBar);
		searchBar.backgroundColor = FlxColor.GRAY;
		searchBar.lines = 1;
		searchBar.autoSize = false;
		searchBar.alignment = FlxTextAlign.CENTER;
		searchBar.bold = true;
		searchBar.font = Paths.font("FridayNightFunkin.ttf");
		searchBar.alpha = 0.8;
		searchBar.text = 'CLICK TO SEARCH FREEPLAY!';
		searchBar.updateHitbox();
		//searchBar.blend = BlendMode.DARKEN;
		blockPressWhileTypingOn.push(searchBar);
		FlxG.mouse.visible = true;

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		// if(curSelected >= songs.length) curSelected = -1;
		try {
			if (APEntryState.inArchipelagoMode) {
				bg.color = FlxColor.fromString('#FD719B'); // Default pink color
				intendedColor = bg.color;
			} else {
				bg.color = fpManager.songList[curSelected].color[1][0];
				intendedColor = bg.color;
			}
		}
		catch(e)
		{
			bg.color = FlxColor.WHITE;
			intendedColor = bg.color;
		}
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = "Make sure to specify what difficulty you want BEFORE selecting your song!";
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		updateTexts();
		super.create();

		FlxTween.tween(searchBar, {y: 100}, 0.6, {
			ease: FlxEase.elasticInOut,
			onComplete: function(twn:FlxTween){
				searchBar.updateHitbox();
		}});

		fpManager.reloadPlaylistSelect();
		changeSelection();

		MegaManager.conductor.addBeatCallback((curBeat:Int, backward:Bool) ->
		{
			FlxG.camera.zoom = zoomies;
			FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet*0.001*16, {
				ease: FlxEase.quadOut
			});

			if (trackPlaying == 'freeplayRandom') {
				randomIcon.scale.set(1.2, 1.2);
				return;
			}

			if (iconList.members[curSelected] != null)
				iconList.members[curSelected].scale.set(1.2, 1.2);
		});
	}

	public function setDifficultyStars(?difficulty:Int):Void
	{
		if (difficulty == null) return;
		difficultyStars.setNumber(archipelago.APItem.unknownSongs ? 100 : difficulty);
		showStars();
	}

	/**
	 * Make the album stars visible.
	 * I thought this was pointless.
	 * Turns out, this DOES have a reason to exist
	 */
	public function showStars():Void
	{
		difficultyStars.visible = true; // true;
	}

	override function closeSubState() {
		if (doChange)
		{
			changeSelection(0, false);
			doChange = false;
			Highscore.reloadModifiers();
		}
		persistentUpdate = true;
		super.closeSubState();
	}

	// TODO: Find a way to safely thread this
	// or at least make it handle a larger amount of songs without taking forever to load
	public function reloadSongs()
	{
		grpSongs.clear();
    iconArray = [];
    iconList.clear();

    for (i in 0...iconArray.length)
    {
      iconArray.pop();
    }

    for (i in 0...fpManager.songList.length)
    {
      var color:FlxColor = 0xFFFF0000;

			for (song in curPlaylist.songList) {
				if (song.songName.toLowerCase().replace("-", " ") == fpManager.songList[i].songName.toLowerCase().replace("-", " ")) {
					color = 0xFF00FF00;
					break;
				}
			}

      var songText:Alphabet = null;
      songText = new DynamicColoredAlphabet(90, 320, fpManager.songList[i].songName, true, color, true);
      songText.doShuffle = AprilFools.allowAF ? FlxG.random.bool(10) : false;
      songText.targetY = i;
      grpSongs.add(songText);

      songText.scaleX = Math.min(1, 980 / songText.width);
      songText.snapToPosition();

      Mods.currentModDirectory = fpManager.songList[i].folder;

      songText.visible = songText.active = songText.isMenuItem = false;

      var icon:HealthIcon = new HealthIcon(fpManager.songList[i].songCharacter);
      icon.sprTracker = songText;
      icon.visible = icon.active = false;
      iconArray.push(icon);
      iconList.add(icon);

			if (fpManager.songList.length == -1 || fpManager.songList.length == 0)
				fpManager.addSong('SONG NOT FOUND', -999, 'face', [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);

			changeSelection();
			updateTexts();
			changeDiff();
			if (PlayState.SONG != null) Conductor.bpm = PlayState.SONG.bpm;
		}
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


	var instPlaying:Int = -1;
	var trackPlaying:String = null;
	var holdTime:Float = 0;
	var stopMusicPlay:Bool = false;

	override function update(elapsed:Float)
	{
		if (fpManager.songList[curSelected] != null)
		{
			switch(Paths.formatToSongPath(fpManager.songList[curSelected].songName))
			{
				default:
					diffText.visible = true;
					multisong = false;
			}
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (curSelected != -1 && iconList.members[curSelected] != null) {
			var mult:Float = FlxMath.lerp(1, iconList.members[curSelected].scale.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			iconList.members[curSelected].scale.set(mult, mult);
		}
		else {
			var mult:Float = FlxMath.lerp(1, randomIcon.scale.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			randomIcon.scale.set(mult, mult);
		}

		if (searchBar.text == 'CLICK TO SEARCH FREEPLAY!' && searchBar.hasFocus)
		{
			searchBar.text = '';
			searchBar.updateHitbox();
		}
		if (!searchBar.hasFocus)
		{
			if (searchBar.y == 100)
				FlxTween.tween(searchBar, {y: 0}, 0.6, {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween){
					searchBar.updateHitbox();
				}});
			searchBar.updateHitbox();
			searchBar.text = 'CLICK TO SEARCH FREEPLAY!';
		}
		else
		{
			if (searchBar.y == 0)
				FlxTween.tween(searchBar, {y: 100}, 0.6, {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween){
					searchBar.updateHitbox();
				}});
			searchBar.updateHitbox();
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (searchBar.hasFocus == false || searchBar.text == null)
		{
			scoreText.text = 'Select the song to add';
			positionHighscore();

			if(fpManager.songList.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = -1;
					changeSelection();
					holdTime = 0;
					searchBar.hasFocus = false;
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = fpManager.songList.length - 1;
					changeSelection();
					holdTime = 0;
					searchBar.hasFocus = false;
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
					searchBar.hasFocus = false;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
					searchBar.hasFocus = false;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					searchBar.hasFocus = false;
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
					searchBar.hasFocus = false;
				}
			}

			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
				searchBar.hasFocus = false;
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
				searchBar.hasFocus = false;
			}
		}
		if (FlxG.keys.pressed.SHIFT || FlxG.keys.pressed.ALT)
		{
			searchBar.hasFocus = false;
		}
		if (FlxG.keys.pressed.SHIFT || FlxG.keys.pressed.ALT)
		{
			searchBar.hasFocus = false;
		}
		if (controls.justPressed('accept') && searchBar.hasFocus) fpManager.reloadFreeplay(false, searchBar.text);

		if (searchBar.hasFocus == false || searchBar.text == null)
		{
			if (controls.BACK)
			{
				searchBar.hasFocus = false;
				persistentUpdate = false;
        if(colorTween != null) {
          colorTween.cancel();
        }
        FlxG.sound.play(Paths.sound('cancelMenu'));
        states.editors.PlaylistEditorState.autoOpenMetaEditor = true;
        FlxG.switchState(new states.editors.PlaylistEditorState(curPlaylist));
			}

			if (FlxG.keys.justPressed.ALT)
			{
				searchBar.hasFocus = false;
			}

			if (controls.ACCEPT && !searchBar.hasFocus)
			{
				if (curSelected == -1) {
					var newSel = FlxG.random.int(0, fpManager.songList.length - 1);
					if (newSel == -1)
						newSel = 0;
					curSelected = newSel;
					changeSelection();
					updateTexts();
					return;
				}

				searchBar.hasFocus = false;
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(fpManager.songList[curSelected].songName);

				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				trace(poop);
				//ill softcode this eventually
				switch(songLowercase)
				{
					default:
						songChoices = [];
						listChoices = [];
				}

				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				if (!multisong)
				{
					selected = true;
					try
					{
						if (songLowercase == "song-not-found")
						{
							trace('ERROR! NO SONGS FOUND!');

              missingText.text = 'ERROR! NO SONGS FOUND!';
              missingText.screenCenter(Y);
              missingText.visible = true;
              missingTextBG.visible = true;
              FlxG.sound.play(Paths.sound('cancelMenu'));

              updateTexts(elapsed);
              super.update(elapsed);
              return;
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = curDifficulty;
						}
						else
						{
							PlayState.storyDifficulty = curDifficulty;
							Mods.currentModDirectory = FreeplayManager.instance.songList[curSelected].folder;
						}
					}
					catch(e:Dynamic)
					{
						trace('ERROR! $e');

						var errorStr:String;
						errorStr = e.toString();
						if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart

						missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));

						updateTexts(elapsed);
						super.update(elapsed);
						return;
					}

					// Run a quick scan of the list just to be sure
					var hasSong:Bool = false;
					var curVictim:PlaylistSongMetadata = null;
					for (song in curPlaylist.songList) {
						if (song.songName.toLowerCase() == songLowercase) {
							hasSong = true;
							curVictim = song;
							break;
						}
					}

					var curSong:PlaylistSongMetadata = new PlaylistSongMetadata(songLowercase, FreeplayManager.instance.songList[curSelected].week, fpManager.songList[curSelected].songCharacter, fpManager.songList[curSelected].color, Difficulty.getString());
          if (!hasSong)
            curPlaylist.songList.push(curSong);
          else if (hasSong && curVictim != null)
            curPlaylist.songList.remove(curVictim);
          reloadSongs();
				} else {
					substates.DiffSubState.songChoices = songChoices;
					substates.DiffSubState.listChoices = listChoices;
					openSubState(new substates.DiffSubState());
				}

				FlxG.sound.music.volume = 0;

				fpManager.destroyFreeplayVocals();
				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
			else if(controls.RESET)
			{
				searchBar.hasFocus = false;
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(fpManager.songList[curSelected].songName, curDifficulty, fpManager.songList[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus)
				{
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
			searchBar.hasFocus = false;
		}
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				break;
			}
			else
			{
				FlxG.sound.muteKeys = FirstCheckState.muteKeys;
				FlxG.sound.volumeDownKeys = FirstCheckState.volumeDownKeys;
				FlxG.sound.volumeUpKeys = FirstCheckState.volumeUpKeys;
				FlxG.keys.preventDefaultKeys = [TAB];
				break;
			}
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	public function playFreakyMusic(?musName:String, ?bpm:Float = 145) {
		if (trackPlaying == musName)
			return;

		if (musName == null) {
			if (trackPlaying != 'menu') MusicManager.playMenuMusic(0);
			trackPlaying = 'menu';
			if (musName == null)
				return;
			switchVisualizer();
		} else {
			FlxG.sound.playMusic(Paths.music(musName), 0);
			FlxG.sound.music.fadeIn(3, 0, 0.7);
			switchVisualizer();
			Conductor.bpm = bpm;
			instPlaying = -1;
			trackPlaying = musName;
		}
		fpManager.destroyFreeplayVocals();
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);

		if (fpManager.songList[curSelected] == null)
			return;

		// I really don't wanna talk about it
		try {
			var ratingValue:Dynamic = metadata.freeplay.ratings;
			var actualRating:Map<String, Int> = new Map<String, Int>();

			for (item in Reflect.fields(ratingValue)) {
					if (item == 'normal' || item == 'easy' || item == 'hard') {
						actualRating.set(item, Reflect.field(ratingValue, item));
					} else {
						actualRating.set(item.toLowerCase(), Reflect.field(ratingValue, item));
					}
			}

			var curDiff:String = Difficulty.list[curDifficulty].toLowerCase();
			setDifficultyStars(actualRating.get(curDiff));
			setDifficultyStars(actualRating.get(curDiff));
		} catch(e) {
			difficultyStars.visible = false;
			trace("No Metadata Found!");
		}

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
		else
			diffText.text = displayDiff.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
		//reloadSongs();
	}

	public var metadata:MetadataFile = null;
	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		_updateSongLastDifficulty();

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < -1)
			curSelected = fpManager.songList.length - 1;
		if (fpManager.songList.length > 0 && curSelected >= fpManager.songList.length)
			if (change > 0)
				curSelected = -1;
			else
			curSelected = fpManager.songList.length - 1;

		if (curSelected == -1)
			playFreakyMusic('menuMusic/freeplayRandom');
		else
			playFreakyMusic();

		try {
			if (fpManager.songList.length >= 0)
			{
				if (curSelected < -1)
					curSelected = fpManager.songList.length - 1;
				if (curSelected >= fpManager.songList.length)
					curSelected = -1;

				var newColor:Int = FlxColor.fromString('#FD719B'); // Default color
				newColor = curSelected != -1 ? fpManager.songList[curSelected].color[1][0] : FlxColor.fromString('#FD719B');
				if(newColor != intendedColor) {
					if(colorTween != null) {
						colorTween.cancel();
					}
					intendedColor = newColor;
					colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
						onComplete: function(twn:FlxTween) {
							colorTween = null;
						}
					});
				}
			}
			Mods.currentModDirectory = fpManager.songList[curSelected].folder;
		}
		catch(e)
		{
			trace('NO SONGS FOUND! Running Freeplay anyway...');
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			if (iconArray[i] != null && iconArray[i].animation != null && iconArray[i].animation.curAnim != null)
			{
				iconArray[i].alpha = 0.4;
				switch (iconArray[i].type) {
					case SINGLE: iconArray[i].animation.curAnim.curFrame = 0;
					case WINNING: iconArray[i].animation.curAnim.curFrame = 2;
					default: iconArray[i].animation.curAnim.curFrame = 0;
				}
			}

			if (iconArray[curSelected] != null && iconArray[curSelected].animation != null && iconArray[curSelected].animation.curAnim != null)
			{
				iconArray[curSelected].alpha = 1;
				switch (iconArray[curSelected].type) {
					case SINGLE: iconArray[curSelected].animation.curAnim.curFrame = 0;
					case WINNING: iconArray[curSelected].animation.curAnim.curFrame = 1;
					default: iconArray[curSelected].animation.curAnim.curFrame = 1;
				}
			}
		}

		for (item in grpSongs.members)
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

		if (fpManager.songList[curSelected] != null)
		{
			WeekData.setDirectoryFromWeek();
			Mods.currentModDirectory = fpManager.songList[curSelected].folder;
			PlayState.storyWeek = fpManager.songList[curSelected].week;
			try {Difficulty.loadFromWeek();} catch(e:Dynamic) {}
			try {metadata = fpManager.metadata.get(fpManager.songList[curSelected].songName.toLowerCase());}
			catch(e) {metadata = null;}
		}

		if (curSelected == -1)
			diffText.visible = false;
		else
			diffText.visible = true;

		try {
			if (fpManager.songList[curSelected] == null)
				return;

			if (fpManager.songList[curSelected].songName != 'SONG NOT FOUND')
			{
				Mods.currentModDirectory = fpManager.songList[curSelected].folder;
				PlayState.storyWeek = fpManager.songList[curSelected].week;

				switch (fpManager.songList[curSelected].songName)
				{
					case 'Small Argument' | 'Beat Battle 2' | 'GeoStar' | 'Zeventeen' | 'Tag And Seek' | 'Rawr' | 'Funky Fanta' | 'Fightback' | 'Fangirl Frenzy' | 'Slowdown' | 'Pack-A-Punch':
						Difficulty.list = ['Hard'];
					case 'Rise' | 'Test Field' | 'Pack A Punch' | 'Driller':
						Difficulty.list = ['Normal'];
					case "Beat Battle":
						Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
					case "Testimony":
						Difficulty.list = ["4K", "Canon"];
					default:
						Difficulty.loadFromWeek();
				}
				var savedDiff:String = fpManager.songList[curSelected].lastDifficulty;
				var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
				if(fpManager.songList[curSelected].songName != 'SONG NOT FOUND') savedDiff = WeekData.getCurrentWeek().difficulties.trim(); //Fuck you HTML5
				else savedDiff = 'SONG NOT FOUND!'; //and you too search bar
				if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
					curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
				else if(lastDiff > -1)
					curDifficulty = lastDiff;
				else if(Difficulty.list.contains(Difficulty.getDefault()))
					curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
				else
					curDifficulty = 0;

				curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
			}
			else
			{
				Difficulty.list = ['SONG NOT FOUND'];
				curDifficulty = 0;
				fpManager.addSong('SONG NOT FOUND', -999, 'face', [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
				changeDiff();
				_updateSongLastDifficulty();
			}
		}
		catch(e)
		{
			trace("songs couldn't be found, even though there are songs??? adding SONG NOT FOUND just in case.");
			Difficulty.list = ['SONG NOT FOUND'];
			curDifficulty = 0;
			fpManager.addSong('SONG NOT FOUND', -999, 'face', [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
		}

		if (metadata != null && metadata.freeplay != null) {
			// Always use default background if songs are hidden
			if (!archipelago.APItem.unknownSongs && metadata.freeplay.bg != null && metadata.freeplay.bg != '') {
				bg.loadGraphic(Paths.image(metadata.freeplay.bg));
				bg.screenCenter();
			} else {
				bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
				bg.screenCenter();
			}

			if (albumPhoto != null) {
				// Always use default album if songs are hidden
				if (!archipelago.APItem.unknownSongs && metadata.freeplay.album != null && metadata.freeplay.album != '') {
					albumPhoto.loadGraphic(Paths.image('albums/${Std.string(metadata.freeplay.album)}'));
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
		} else { // Return to default
			bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
			bg.screenCenter();

			if (albumPhoto != null) {
				albumPhoto.loadGraphic(Paths.image('albums/NoCover'));
				albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
				albumPhoto.screenCenter(Y);
				albumPhoto.y += 20;
			}
		}

		changeDiff();
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	inline private function _updateSongLastDifficulty()
	{
		if (fpManager.songList[curSelected] != null) fpManager.songList[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
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
			if(grpSongs.members[i] != null) grpSongs.members[i].visible = grpSongs.members[i].active = false;
			try{if(iconArray[i] != null) iconArray[i].visible = iconArray[i].active = false;}
			catch(e) {trace("Failed to update the icons!");}
		}
		_lastVisibles = [];

		updateScrollable(randomText, elapsed);
		if (curSelected == -1)
			randomText.alpha = 1;
		randomIcon.alpha = randomText.alpha;

		var min:Int = Math.round(Math.max(0, Math.min(fpManager.songList.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(fpManager.songList.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (grpSongs.members[i] != null)
			{
				if (!(grpSongs.members[i] is Scrollable)) {
					continue;
				}

				var item:Scrollable = cast(grpSongs.members[i], Scrollable);
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				var icon:HealthIcon = iconArray[i];
				if (icon != null) icon.visible = icon.active = true;
				_lastVisibles.push(i);
			}
		}
	}

	override function destroy():Void
	{
		super.destroy();

    instance = null;

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			MusicManager.playMenuMusic(0);
	}

	// public static function addInternetModSource(url:String):Void {
	// 	Mods.addInternetModSource(url);
	// 	reloadSongs(true);
	// }

	// public static function removeInternetModSource(url:String):Void {
	// 	Mods.removeInternetModSource(url);
	// 	reloadSongs(true);
	// }

	// public static function addGithubModSource(repoUrl:String):Void {
	// 	Mods.addGithubModSource(repoUrl);
	// 	reloadSongs(true);
	// }

	// public static function removeGithubModSource(repoUrl:String):Void {
	// 	Mods.removeGithubModSource(repoUrl);
	// 	reloadSongs(true);
	// }

	// Accessor methods for Legacy Lua subclass
	public function getCurrentSelected():Int {
		return curSelected;
	}

	public function setCurrentSelected(value:Int):Void {
		curSelected = value;
	}

	public function getGrpSongs():FlxTypedGroup<Alphabet> {
		return grpSongs;
	}

	public function getCurDifficulty():Int {
		return curDifficulty;
	}

	public function setCurDifficulty(value:Int):Void {
		curDifficulty = value;
	}

	public function getSelected():Bool {
		return selected;
	}

	public function setSelected(value:Bool):Void {
		selected = value;
	}

	public function getStopMusicPlay():Bool {
		return stopMusicPlay;
	}

	public function setStopMusicPlay(value:Bool):Void {
		stopMusicPlay = value;
	}
}
