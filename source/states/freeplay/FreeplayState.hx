package states.freeplay;

import archipelago.*;
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
import objects.MusicPlayer;
import options.GameplayChangersSubstate;
import states.editors.ChartingState;
import states.editors.ChartingStateOG;
import states.freeplay.backend.DifficultyStars;
import substates.Prompt;
import substates.ResetScoreSubState;
import yutautil.AprilFools;
import yutautil.ChanceSelector.Chance;
import yutautil.ChanceSelector;

class VictorySong extends DynamicColoredAlphabet
{

	public function new(x:Float, y:Float, text:String, color:Int, preserve:Bool)
	{
		super(x, y, text, color, preserve);
	}

	var e:Int = 0;

	override function update(elapsed:Float)
	{
		e++;
		super.update(elapsed);
		this.color = FlxColor.fromHSL(((e / 2) / 300 * 360) % 360, 1.0, 0.5 * 1.0);
	}
}
class FreeplayState extends MusicBeatState
{
	public static var instance:FreeplayState;

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconList:FlxTypedGroup<HealthIcon>;
	private var grpLocks:FlxTypedGroup<FlxSprite>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var listening:Bool = false;
	var selected:Bool = false;
	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var randomText:Scrollable;
	var randomIcon:HealthIcon;

	public var searchBar:FlxUIInputText;
	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	public static var SONG:SwagSong = null;

	public static var lastCategory:String;
	public static var giveSong:Bool = false;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	var songChoices:Array<String> = [];
	var listChoices:Array<String> = [];
	var multiSongs:Array<String> = [];

	public static var doChange:Bool = false;
	public static var multisong:Bool = false;

	var h:String;
	var mismatched:String = "";
	var rankTable:Array<String> = [
		'P-small', 'X-small', 'X--small', 'SS+-small', 'SS-small', 'SS--small', 'S+-small', 'S-small', 'S--small', 'A+-small', 'A-small', 'A--small',
		'B-small', 'C-small', 'D-small', 'E-small', 'NA'
	];
	var rank:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('rankings/NA'));

	var hh:Array<Chance> = [
		{item: "normal error", chance: 95} // 95% chance to got the normal error screen
	];

	var ticketCounter:FlxText = null;
	var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;

	var albumPhoto:FlxSprite;
	var difficultyStars:DifficultyStars;

	public var fpManager:FreeplayManager;
	override function create()
	{
		#if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end
		Cursor.cursorMode = Default;
		instance = this; // For Archipelago

		fpManager = FreeplayManager.loadFPManager();

		// Check if the Victory Song is cleared.
		if (APEntryState.inArchipelagoMode) {
			trace(APEntryState.victorySong);
			APFreeplayManager.updateArchFreeplay();
			APFreeplayManager.checkVictory();
		}



		Highscore.reloadModifiers();
		Paths.clearStoredWithoutStickers();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In Mixtape Freeplay", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
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

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

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

		rank.scale.x = rank.scale.y = 80 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = true;
		rank.scrollFactor.set();
		rank.y = 690 - rank.height;
		rank.x = -200 + FlxG.width - 50;
		add(rank);
		rank.antialiasing = true;

		rank.alpha = 0;


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
			// Use default color if songs are hidden to avoid identifying the song
			if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
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

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		player = new MusicPlayer(this);
		add(player);

		updateTexts();
		super.create();

		FlxTween.tween(rank, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});
		FlxTween.tween(searchBar, {y: 100}, 0.6, {
			ease: FlxEase.elasticInOut,
			onComplete: function(twn:FlxTween){
				searchBar.updateHitbox();
		}});

		trace(hh);

		fpManager.reloadFreeplay(true);
		changeSelection();

		if (!FlxG.save.data.gotIntoAnArgument && !APEntryState.inArchipelagoMode)
			hh.push({item: "small argument", chance: 5}); // 5% chance to play Small Argument if not already unlocked or in Archipelago Mode
		if (!FlxG.save.data.gotbeatbattle && !APEntryState.inArchipelagoMode)
			hh.push({item: "beat battle", chance: 5}); // 5% chance to play Beat Battle if not already unlocked or in Archipelago Mode
		if (!FlxG.save.data.gotbeatbattle2 && !APEntryState.inArchipelagoMode)
			hh.push({item: "beat battle 2", chance: 5}); // 5% chance to do Beat Battle 2 if not already unlocked or in Archipelago Mode
		if (!FlxG.save.data.gotgeostar && !APEntryState.inArchipelagoMode)
			hh.push({item: "geostar", chance: 5}); // 5% chance to do GeoStar if not already unlocked or in Archipelago Mode

		if (APEntryState.apGame != null && APEntryState.apGame.info() != null) {
			ticketCounter = new FlxText(FlxG.width - 470, FlxG.height - 630, 0, "0/0", 32);
			ticketCounter.setFormat(Paths.font("fnf1.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ticketCounter.scrollFactor.set();
			add(ticketCounter);
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				archipelago.APGameState.haventranyet = false;
			});
		}

	// 	if (archipelago.APItem.activeItem?.condition.type == archipelago.APItem.ConditionType.PlayState)
	// 		archipelago.APItem.activeItem = null;
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
			mismatched = "";
			Highscore.reloadModifiers();
		}
		persistentUpdate = true;
		super.closeSubState();
	}

	// TODO: Find a way to safely thread this
	// or at least make it handle a larger amount of songs without taking forever to load
	public function reloadSongs(?refresh:Bool = false)
	{
		if (instance != null)
		{
			grpSongs.clear();
			iconArray = [];
			iconList.clear();
			grpLocks.clear();

			for (i in 0...iconArray.length)
			{
				iconArray.pop();
			}

			// trace (curUnlocked);
			if (APEntryState.inArchipelagoMode) APFreeplayManager.checkSongStatus();
			for (i in 0...fpManager.songList.length)
			{
				var songName:String = '';
				var modName:String = '';
				var isMissing:Bool = false;
				var locationId:Array<Int> = [];
				var color:FlxColor = 0xFFFFFFFF;
				var someLocationsNotMissing:Bool = false;

			if (APEntryState.inArchipelagoMode) {
				songName = fpManager.songList[i].songName;
				modName = fpManager.songList[i].folder;
				locationId = APEntryState.apGame.locationData(songName, modName).concat(APEntryState.apGame.noteData(songName, modName));
				isMissing = [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].indexOf(true) != -1 || locationId.length == 0;

				// Check if song is unlocked (in curUnlocked)
				var isUnlocked = [for (songObj in APFreeplayManager.curUnlocked) songObj.song.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ') && songObj.mod == modName].contains(true);

				// Color logic based on requirements:
				// RED = not unlocked (locked)
				// WHITE = unlocked with all locations missing
				// GRAY = unlocked with some locations missing
				// GREEN = unlocked with no locations missing (completed)
				if (!isUnlocked) {
					color = FlxColor.RED; // Locked song
				} else {
					if (!isMissing) {
						color = FlxColor.GREEN; // Fully completed
					} else {
						// Check if some locations are not missing (partially completed)
						someLocationsNotMissing = [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].contains(false);
						color = someLocationsNotMissing ? FlxColor.GRAY : FlxColor.WHITE;
					}
				}
			}
				var songText:Alphabet = null;
				if (APEntryState.inArchipelagoMode) {
					var isBronze:Bool = FlxG.random.bool(50); // Randomly decide between orange and bronze
					var bronzeOrOrangeColor:Int = isBronze ? 0xFFCD7F32 : 0xFFFFA500; // Bronze or Orange color
					var displayName = archipelago.APItem.unknownSongs ? "Unknown" : songName;
					songText = APFreeplayManager.isVictorySong(songName, modName) ?
						(isMissing ?
							(someLocationsNotMissing ?
								new DynamicColoredAlphabet(90, 320, displayName, true, bronzeOrOrangeColor, true)
								: new VictorySong(90, 320, displayName, color, true))
							: new DynamicColoredAlphabet(90, 320, displayName, true, 0xFFFFD700, true))
						: new DynamicColoredAlphabet(90, 320, displayName, true, color, true);
				} else {
					songText = new DynamicAlphabet(90, 320, fpManager.songList[i].songName, true, true);
				}
				songText.doShuffle = AprilFools.allowAF ? FlxG.random.bool(10) : false;
				songText.targetY = i;
				grpSongs.add(songText);

				if (APEntryState.inArchipelagoMode) {
					APFreeplayManager.callVictory = APFreeplayManager.isVictorySong(songName, modName) && !isMissing && !someLocationsNotMissing;

					if (APFreeplayManager.callVictory) {
						trace("Apparently, the victory song has been cleared, so... Goaling!");
						APEntryState.apGame.checkGoal(songName, modName);
					}
				}

				songText.scaleX = Math.min(1, 980 / songText.width);
				songText.snapToPosition();

				Mods.currentModDirectory = fpManager.songList[i].folder;

				songText.visible = songText.active = songText.isMenuItem = false;

				var isLock:Bool = false;
				var iconName:String = "";

				if (APEntryState.inArchipelagoMode) {
					// Song is locked if it's not in curUnlocked
					var isUnlocked = [for (songObj in APFreeplayManager.curUnlocked) songObj.song.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ') && songObj.mod == modName].contains(true);
					isLock = !isUnlocked;
					iconName = isLock ? "lock" : (archipelago.APItem.unknownSongs ? "face" : fpManager.songList[i].songCharacter);
				} else {
					iconName = fpManager.songList[i].songCharacter;
				}

				var icon:HealthIcon = new HealthIcon(iconName);
				icon.sprTracker = songText;
				icon.visible = icon.active = false;
				iconArray.push(icon);
				iconList.add(icon);
			}
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
		// If Legacy Lua settings are being edited, switch to Legacy Lua version
		if (options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode && !(this is options.legacylua.LegacyLuaFreeplayState)) {
			FlxG.switchState(new options.legacylua.LegacyLuaFreeplayState());
			return;
		}

		if (fpManager.songList[curSelected] != null)
		{
			switch(Paths.formatToSongPath(fpManager.songList[curSelected].songName))
			{
				default:
					diffText.visible = true;
					multisong = false;
			}
		}

		if (APEntryState.inArchipelagoMode)
				APEntryState.apGame.info().poll();


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

		if (multisong) FlxTween.tween(rank, {alpha: 0}, 0.5, {ease: FlxEase.quartInOut});
		else FlxTween.tween(rank, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});

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

		if (FlxG.keys.justPressed.L && APEntryState.inArchipelagoMode && !searchBar.hasFocus)  {
			try {
				var songLowercase:String = Paths.formatToSongPath(fpManager.songList[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				Mods.currentModDirectory = fpManager.songList[curSelected].folder;
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
			} catch (e:Dynamic) {
				trace('Error loading song: ' + e);
			}
			try {
				APFreeplayManager.forceUnlockCheck(fpManager.songList[curSelected].songName, WeekData.getCurrentWeek().folder);
			} catch (e:Dynamic) {
				trace("You can't check nothing, silly!");
			}
			MusicBeatState.resetState();
		}

		if (FlxG.keys.justPressed.H && APEntryState.inArchipelagoMode && !searchBar.hasFocus) {
			try {
				var SongInfo = APEntryState.apGame.getSongAndMod(fpManager.songList[curSelected].songName + (fpManager.songList[curSelected].folder != "" ? " (" + fpManager.songList[curSelected].folder + ")" : ""));
				if (APEntryState.ap != null) {
					// Check if this is the victory song and if it's already unlocked
					if (APFreeplayManager.isVictorySong(SongInfo.song, SongInfo.mod) && APInfo.ticketCount >= APInfo.ticketWinCount && (APFreeplayManager.curUnlocked.filter(function(entry:{song:String, mod:String}) {
						return entry.song == SongInfo.song && entry.mod == (SongInfo.mod != null ? SongInfo.mod : "");
					}).length != 0)) {
						APEntryState.ap.Say("!hint Ticket");
					} else {
						APEntryState.ap.Say("!hint " + SongInfo.song + ((SongInfo.mod != "" && SongInfo.mod != null) ? " (" + SongInfo.mod + ")" : ""));
					}
					archipelago.console.SideUI.instance.active = true;
				}
			} catch (e:Dynamic) {
				trace("You can't hint nothing, silly!");
			}
		}
		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}

		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic && (searchBar.hasFocus == false || searchBar.text == null))
		{
			if (curSelected == -1)
				scoreText.text = 'RANDOM SONG';
			else
				scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
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
				// Block difficulty navigation if unknown songs is active
				if (!(APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs)) {
					changeDiff(-1);
					_updateSongLastDifficulty();
				}
				searchBar.hasFocus = false;
			}
			else if (controls.UI_RIGHT_P)
			{
				// Block difficulty navigation if unknown songs is active
				if (!(APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs)) {
					changeDiff(1);
					_updateSongLastDifficulty();
				}
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
				if (player.playingMusic)
				{
					FlxG.sound.music.stop();
					fpManager.destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
					instPlaying = -1;

					player.playingMusic = false;
					player.switchPlayMusic();

					MusicManager.playMenuMusic(0);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
					switchVisualizer();
				}
				else
				{
					persistentUpdate = false;
					if(colorTween != null) {
						colorTween.cancel();
					}
					FlxG.sound.play(Paths.sound('cancelMenu'));
					// Don't switch to AP versions if we're in LegacyLua mode
					if (APEntryState.inArchipelagoMode && !options.legacylua.LegacyLuaFreeplayState.inLegacyLuaMode)
						FlxG.switchState(new archipelago.APCategoryState(APEntryState.apGame, APEntryState.ap));
					else
						FlxG.switchState(new CategoryState());
				}
			}

			if (FlxG.keys.justPressed.ALT)
			{
				searchBar.hasFocus = false;
			}

			if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
			{
				searchBar.hasFocus = false;
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(FlxG.keys.justPressed.SPACE && !searchBar.hasFocus)
			{
				if(instPlaying != curSelected && !player.playingMusic)
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

					if (archipelago.APItem.unknownSongs && APEntryState.inArchipelagoMode) {
						FlxG.camera.shake(0.005, 0.5);
						// 1 in 20 chance to play metal_pipe instead of badnoise
						FlxG.sound.play(
							FlxG.random.int(1, 20) == 1
								? Paths.sound("metal_pipe")
								: Paths.sound("badnoise" + FlxG.random.int(1, 3)),
							1
						);
						grpSongs.forEach(function(item:FlxSprite)
						{
							if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
						});
						grpLocks.forEach(function(item:FlxSprite)
						{
							if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
						});
						return;
					}

					searchBar.hasFocus = false;
					fpManager.destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;

					Mods.currentModDirectory = fpManager.songList[curSelected].folder;
					var poop:String = Highscore.formatSong(fpManager.songList[curSelected].songName.toLowerCase(), curDifficulty);
					Song.loadFromJson(poop, fpManager.songList[curSelected].songName.toLowerCase());
					fpManager.previewSong(PlayState.SONG.needsVoices);
					instPlaying = curSelected;
					trackPlaying = poop;
					player.playingMusic = true;
					player.curTime = 0;
					player.switchPlayMusic();
					player.pauseOrResume(true);
					switchVisualizer(true, FreeplayManager.vocals, FreeplayManager.opponentVocals);
				}
				else if (instPlaying == curSelected && player.playingMusic)
				{
					player.pauseOrResume(!player.playing);
				}
			}
			else if (controls.ACCEPT && !player.playingMusic && !searchBar.hasFocus)
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

				var vicCheck:Bool = APFreeplayManager.isVictorySong(fpManager.songList[curSelected].songName, fpManager.songList[curSelected].folder) && APInfo.ticketCount >= APInfo.ticketWinCount;
				//You need the song AND the tickets.
				trace('can play victory song: ${vicCheck}');
				if (APFreeplayManager.isVictorySong(fpManager.songList[curSelected].songName, fpManager.songList[curSelected].folder) && !vicCheck) {

					// Check for hints first
					var hints = APFreeplayManager.getHintsForSong(fpManager.songList[curSelected].songName, fpManager.songList[curSelected].folder);

					if (hints.length > 0) {
						// Show hint panel first
						var hintContent = "Here are the hints for this song:\n\n";
						for (i in 0...hints.length) {
							hintContent += "• " + hints[i];
							if (i < hints.length - 1) hintContent += "\n\n";
						}

						archipelago.substates.InfoPanelSubstate.show(
							"Song Hints: " + fpManager.songList[curSelected].songName,
							hintContent,
							FlxColor.CYAN,
							function() {
								// After hint panel closes, show the missing text
								missingText.text = 'You don\'t have enough tickets to play this victory song.\n\nRequired: ${APInfo.ticketWinCount}\nYou have: ${APInfo.ticketCount}';
								missingText.screenCenter(Y);
								missingText.visible = true;
								missingTextBG.visible = true;
								FlxG.sound.play(Paths.sound('cancelMenu'));
							}
						);
						return;
					} else {
						// No hints, show missing text immediately
						missingText.text = 'You don\'t have enough tickets to play this victory song.\n\nRequired: ${APInfo.ticketWinCount}\nYou have: ${APInfo.ticketCount}';
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));
						return;
					}
				}

				// Check if song is locked (not in curUnlocked)
				var isUnlocked = APEntryState.inArchipelagoMode && [for (songObj in APFreeplayManager.curUnlocked) songObj.song.trim().toLowerCase().replace('-', ' ') == fpManager.songList[curSelected].songName.trim().toLowerCase().replace('-', ' ') && songObj.mod == fpManager.songList[curSelected].folder].contains(true);
				var isLocked = APEntryState.inArchipelagoMode && !isUnlocked;

				if (isLocked) {
					trace('Song is locked (not in curUnlocked)!');

					// Check for hints first
					var hints = APFreeplayManager.getHintsForSong(fpManager.songList[curSelected].songName, fpManager.songList[curSelected].folder);

					if (hints.length > 0) {
						// Show hint panel first
						var hintContent = "Here are the hints for this song:\n\n";
						for (i in 0...hints.length) {
							hintContent += "• " + hints[i];
							if (i < hints.length - 1) hintContent += "\n\n";
						}

						archipelago.substates.InfoPanelSubstate.show(
							"Song Hints: " + fpManager.songList[curSelected].songName,
							hintContent,
							FlxColor.CYAN,
							function() {
								// After hint panel closes, show the missing text
								missingText.text = "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.";
								missingText.screenCenter(Y);
								missingText.visible = true;
								missingTextBG.visible = true;
								FlxG.sound.play(Paths.sound('cancelMenu'));
							}
						);
						return;
					} else {
						// No hints, show missing text immediately
						missingText.text = "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.";
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));
						return;
					}
				}

				if (APFreeplayManager.trueMissing.contains({song: fpManager.songList[curSelected].songName, mod: fpManager.songList[curSelected].folder}) && !APFreeplayManager.unplayedList.contains({song: fpManager.songList[curSelected].songName, mod: fpManager.songList[curSelected].folder})) {
					trace('Song is locked!');

					// Check for hints first
					var hints = APFreeplayManager.getHintsForSong(fpManager.songList[curSelected].songName, fpManager.songList[curSelected].folder);

					if (hints.length > 0) {
						// Show hint panel first
						var hintContent = "Here are the hints for this song:\n\n";
						for (i in 0...hints.length) {
							hintContent += "• " + hints[i];
							if (i < hints.length - 1) hintContent += "\n\n";
						}

						archipelago.substates.InfoPanelSubstate.show(
							"Song Hints: " + fpManager.songList[curSelected].songName,
							hintContent,
							FlxColor.CYAN,
							function() {
								// After hint panel closes, show the missing text
								missingText.text = "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.";
								missingText.screenCenter(Y);
								missingText.visible = true;
								missingTextBG.visible = true;
								FlxG.sound.play(Paths.sound('cancelMenu'));
							}
						);
						return;
					} else {
						// No hints, show missing text immediately
						missingText.text = "This song isn't unlocked yet.\n\nYou need to complete the required objectives to unlock it.";
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));
						return;
					}
				}

				searchBar.hasFocus = false;
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(fpManager.songList[curSelected].songName);

				var actualDifficulty:Int = curDifficulty;

				// If unknownSongs is active, randomly select an actual difficulty
				if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
					var availableDifficulties:Array<Int> = [];
					// Try each difficulty to see which ones are valid
					for (i in 0...Difficulty.list.length) {
						try {
							var testPoop:String = Highscore.formatSong(songLowercase, i);
							// Test if the chart exists by trying to load it
							var testSong = Song.loadFromJson(testPoop, songLowercase);
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
						missingText.text = 'ERROR:\nUnable to load song data.';
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));
						updateTexts(elapsed);
						super.update(elapsed);
						return;
					}
				}

				var poop:String = Highscore.formatSong(songLowercase, actualDifficulty);
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
					//I'll make it look pretty later
					if(ClientPrefs.getGameplaySetting('bothMode', false) && (ClientPrefs.getGameplaySetting('opponentplay', false) || ClientPrefs.getGameplaySetting('gfMode', false)))
						mismatched = "you can't have \"Play Both Sides\" and \"GF Mode\" or \"Opponent Mode\" on at the same time!";
					else mismatched = "";
					if(ClientPrefs.getGameplaySetting('opponentplay', false) && ClientPrefs.getGameplaySetting('gfMode', false))
						mismatched = "you can't have \"GF Mode\" and \"Opponent Mode\" on at the same time!";
					else mismatched = "";
					if(ClientPrefs.getGameplaySetting('loopMode', false) && ClientPrefs.getGameplaySetting('loopModeC', false))
						mismatched = "you can't have \"Loop Mode\" and \"Loop Challenge Mode\" on at the same time!";
					else mismatched = "";
					try
					{
						if (songLowercase == "song-not-found")
						{
							h = ChanceSelector.selectOption(hh, false, true, true);
							if (APEntryState.inArchipelagoMode) {
								h = "normal error";
							}
							switch (h)
							{
								case "small argument":
									Song.loadFromJson('small-argument-hard', 'small-argument');
									FlxG.save.data.gotIntoAnArgument = true;
									FlxG.save.flush();
									Achievements.addScore("search_songs");
								case "beat battle":
									Song.loadFromJson('beat-battle-reasonable', 'beat-battle');
									FlxG.save.data.gotbeatbattle = true;
									FlxG.save.flush();
									Achievements.addScore("search_songs");
								case "beat battle 2":
									Song.loadFromJson('beat-battle-2-hard', 'beat-battle-2');
									FlxG.save.data.gotbeatbattle2 = true;
									FlxG.save.flush();
									Achievements.addScore("search_songs");
								case "geostar":
									Song.loadFromJson('geostar-hard', 'geostar');
									FlxG.save.data.gotgeostar = true;
									FlxG.save.flush();
									Achievements.addScore("search_songs");
								case "normal error":
									trace('ERROR! NO SONGS FOUND!');

									missingText.text = 'ERROR! NO SONGS FOUND!';
									missingText.screenCenter(Y);
									missingText.visible = true;
									missingTextBG.visible = true;
									FlxG.sound.play(Paths.sound('cancelMenu'));

									updateTexts(elapsed);
									super.update(elapsed);
									return;
							}
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = curDifficulty;
						}
						else if (mismatched != "")
						{
							trace('ERROR! Modifiers are on that shouldn\'t be!');

							missingText.text = 'ERROR! '+mismatched.toUpperCase();
							missingText.screenCenter(Y);
							missingText.visible = true;
							missingTextBG.visible = true;
							FlxG.sound.play(Paths.sound('cancelMenu'));

							updateTexts(elapsed);
							super.update(elapsed);
							return;
						}
						else
						{

							Song.loadFromJson(poop, songLowercase);
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = actualDifficulty;
							Mods.currentModDirectory = FreeplayManager.instance.songList[curSelected].folder;


							trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
						}
					}
					catch(e:Dynamic)
					{
						trace('ERROR! $e');

						var errorStr:String;
						// If unknownSongs is active, show anonymous error message
						if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
							errorStr = 'Unable to load song data.';
						} else {
							errorStr = e.toString();
							if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
						}

						missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));

						updateTexts(elapsed);
						super.update(elapsed);
						return;
					}

					if (FlxG.keys.pressed.SHIFT){
						ClientPrefs.openChartEditor();
					} else{
						if (!alreadyClicked)
						{
							alreadyClicked = true;
							MusicBeatState.reopen = false; //Fix a sticker bug
							LoadingState.prepareToSong();
							LoadingState.loadAndSwitchState(APEntryState.inArchipelagoMode ? new archipelago.APPlayState().funcAndReturn(function(ps:archipelago.APPlayState) {
								archipelago.APPlayState.currentSong = fpManager.songList[curSelected].songName;
								archipelago.APPlayState.currentMod = fpManager.songList[curSelected].folder;
							}) : new PlayState());
						}
						#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
						stopMusicPlay = true;
					}
				}
				else {
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
			else if(controls.RESET && !player.playingMusic)
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

		if (ticketCounter != null) {
			ticketCounter.text = 'Current ticket amount: ${APInfo.ticketCount}\n' +
				'Tickets Needed: ${APInfo.ticketWinCount}\n' +
				'Tickets Left: ${Std.int(APInfo.ticketWinCount - APInfo.ticketCount)}\n' +
				'Hint Points Available: ${APInfo.hintPoints}\n' +
				'Hint Cost: ${APInfo.hintCost}\n' +
				'(L) to release song\n' +
				'(H) to hint song';
		}

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpSongs.members[lock.ID].y;
			lock.x = grpSongs.members[lock.ID].width + 10 + grpSongs.members[lock.ID].x;
		});
	}

	var alreadyClicked:Bool = false;

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
			listening = false;
			instPlaying = -1;
			trackPlaying = musName;
		}
		fpManager.destroyFreeplayVocals();
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		// If unknownSongs trap is active, don't allow difficulty navigation
		if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
			// Keep difficulty at 0 and update display to show "Unknown"
			curDifficulty = 0;
			updateUnknownDifficultyDisplay();
			return;
		}

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);

		#if ARCHIPELAGO_ALLOWED
		// Validate that the selected difficulty is available for SiivaGunner content
		if (archipelago.HighQualityTrapManager.isTrapInUse() && fpManager.songList[curSelected] != null) {
			var songName = fpManager.songList[curSelected].songName;
			var modName = fpManager.songList[curSelected].folder;
			var selectedDiff = Difficulty.getString(curDifficulty, false);

			// If the selected difficulty is not available for this SiivaGunner song, find the next available one
			if (!managers.APFreeplayManager.isDifficultyAvailableForSong(songName, modName, selectedDiff)) {
				var availableDiffs = managers.APFreeplayManager.getAvailableDifficultiesForSong(songName, modName);
				if (availableDiffs.length > 0) {
					// Find the closest available difficulty
					var targetIndex = change > 0 ? 0 : availableDiffs.length - 1;
					for (i in 0...Difficulty.list.length) {
						if (availableDiffs.contains(Difficulty.list[i])) {
							if (change > 0 && i > curDifficulty) {
								targetIndex = i;
								break;
							} else if (change < 0 && i < curDifficulty) {
								targetIndex = i;
							}
						}
					}
					curDifficulty = targetIndex;
				}
			}
		}
		#end

		if (fpManager.songList[curSelected] == null)
			return;

		#if !switch
		intendedScore = Highscore.getScore(fpManager.songList[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(fpManager.songList[curSelected].songName, curDifficulty);
		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(fpManager.songList[curSelected].songName, curDifficulty)]));
		rank.scale.x = rank.scale.y = 140 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = true;
		rank.scrollFactor.set();
		rank.y = 690 - rank.height;
		rank.x = -200 + FlxG.width - 50;
		#end

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
	}

	function updateUnknownDifficultyDisplay()
	{
		// Update difficulty text to show "Unknown"
		lastDifficultyName = "Unknown";

		// Update UI to show "Unknown" difficulty
		diffText.text = '< UNKNOWN >';

		// Hide difficulty stars since we don't want to give away difficulty info
		if (difficultyStars != null) {
			difficultyStars.visible = false;
		}

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	public var metadata:MetadataFile = null;
	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

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
		else if (!player.playingMusic)
			playFreakyMusic();

		try {
			if (fpManager.songList.length >= 0)
			{
				if (curSelected < -1)
					curSelected = fpManager.songList.length - 1;
				if (curSelected >= fpManager.songList.length)
					curSelected = -1;

				var newColor:Int = FlxColor.fromString('#FD719B'); // Default color
				if (!APEntryState.inArchipelagoMode || !archipelago.APItem.unknownSongs) {
					newColor = curSelected != -1 ? fpManager.songList[curSelected].color[1][0] : FlxColor.fromString('#FD719B');
				}
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
						#if ARCHIPELAGO_ALLOWED
						// Check if SiivaGunner trap is in use and load difficulties accordingly
						if (archipelago.HighQualityTrapManager.isTrapInUse()) {
							var songName = fpManager.songList[curSelected].songName;
							var modName = fpManager.songList[curSelected].folder;

							// Try to get SiivaGunner specific difficulties
							var siivaDiffs = managers.APFreeplayManager.getAvailableDifficultiesForSong(songName, modName);
							if (siivaDiffs != null && siivaDiffs.length > 0) {
								Difficulty.list = siivaDiffs.copy();
							} else {
								Difficulty.loadFromWeek();
							}
						} else {
							Difficulty.loadFromWeek();
						}
						#else
						Difficulty.loadFromWeek();
						#end
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

	override function beatHit()
	{
		FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});

		super.beatHit();
		if (trackPlaying == 'freeplayRandom') {
			randomIcon.scale.set(1.2, 1.2);
			return;
		}

		if (listening && instPlaying > -1 && iconList.members[instPlaying] != null)
			iconList.members[instPlaying].scale.set(1.2, 1.2);
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

	public function getAlreadyClicked():Bool {
		return alreadyClicked;
	}

	public function setAlreadyClicked(value:Bool):Void {
		alreadyClicked = value;
	}
}
