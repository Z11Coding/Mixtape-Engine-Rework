package states.freeplay;

import substates.Prompt;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import archipelago.*;
import states.editors.ChartingStateOG;
import states.editors.ChartingState;

import flixel.addons.ui.FlxUIInputText;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import flixel.addons.transition.FlxTransitionableState;

import flixel.math.FlxMath;
import flixel.ui.FlxButton;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import yutautil.ChanceSelector;
import yutautil.ChanceSelector.Chance;
import objects.Alphabet.DynamicAlphabet;
import objects.Alphabet.DynamicColoredAlphabet;
import yutautil.AprilFools;
import objects.Character;

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

	public static var searchBar:FlxUIInputText;
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
		{item: "normal error", chance: 95}, // 95% chance to got the normal error screen
		{item: "small argument", chance: FlxG.save.data.gotsmallargument || APEntryState.inArchipelagoMode ? 0 : 5}, // 5% chance to play Small Argument if not already unlocked or in Archipelago Mode
		{item: "beat battle", chance: FlxG.save.data.gotbeatbattle || APEntryState.inArchipelagoMode ? 0 : 5}, // 5% chance to play Beat Battle if not already unlocked or in Archipelago Mode
		{item: "beat battle 2", chance: FlxG.save.data.gotbeatbattle2 || APEntryState.inArchipelagoMode ? 0 : 5} // 5% chance to do Beat Battle 2 if not already unlocked or in Archipelago Mode
	];

	var ticketCounter:FlxText = null;
	var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;
	override function create()
	{
		#if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end
		Cursor.cursorMode = Default;
		instance = this; // For Archipelago

		// Check if the Victory Song is cleared.	
		{
			FreeplayManager.checkVictory();
		}

		FreeplayManager.updateArchFreeplay();
		Highscore.reloadModifiers();
		Paths.clearStoredWithoutStickers();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
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

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
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
			bg.color = FreeplayManager.songList[curSelected].color[1][0];
			intendedColor = bg.color;
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

		FreeplayManager.reloadFreeplay(true);
		changeSelection();

		if (APEntryState.apGame != null && APEntryState.apGame.info() != null) {
			ticketCounter = new FlxText(FlxG.width - 470, FlxG.height - 630, 0, "0/0", 32);
			ticketCounter.setFormat(Paths.font("fnf1.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ticketCounter.scrollFactor.set();
			add(ticketCounter);
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				archipelago.APGameState.haventranyet = false;
			});
		}

		if (archipelago.APItem.activeItem?.condition.type == archipelago.APItem.ConditionType.PlayState)
			archipelago.APItem.activeItem = null;
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
			FreeplayManager.checkSongStatus();
			for (i in 0...FreeplayManager.songList.length)
			{
				var songName:String = '';
				var modName:String = '';
				var isMissing:Bool = false;
				var locationId:Array<Int> = [];
				var color:FlxColor = 0xFFFFFFFF;
				var someLocationsNotMissing:Bool = false;
				
				if (APEntryState.inArchipelagoMode) {
					songName = FreeplayManager.songList[i].songName;
					modName = FreeplayManager.songList[i].folder;
					locationId = APEntryState.apGame.locationData(songName, modName).concat(APEntryState.apGame.noteData(songName, modName));
					isMissing = [for (ID in locationId) APEntryState.apGame.isLocationMissing(APEntryState.apGame.info().get_location_name(ID))].indexOf(true) != -1 || locationId.length == 0;
					color = isMissing ? FlxColor.RED : FlxColor.GREEN;
				}

				
				var songText:Alphabet = null;
				if (APEntryState.inArchipelagoMode) {
					var isBronze:Bool = FlxG.random.bool(50); // Randomly decide between orange and bronze
					var bronzeOrOrangeColor:Int = isBronze ? 0xFFCD7F32 : 0xFFFFA500; // Bronze or Orange color
					songText = FreeplayManager.isVictorySong(songName, modName) ? 
						(isMissing ? 
							(someLocationsNotMissing ? 
								new DynamicColoredAlphabet(90, 320, songName, true, bronzeOrOrangeColor, true) 
								: new VictorySong(90, 320, songName, color, true)) 
							: new DynamicColoredAlphabet(90, 320, songName, true, 0xFFFFD700, true)) 
						: new DynamicColoredAlphabet(90, 320, songName, true, color, true);
				} else {
					songText = new DynamicAlphabet(90, 320, FreeplayManager.songList[i].songName, true, true);
				}
				songText.doShuffle = AprilFools.allowAF ? FlxG.random.bool(10) : false;
				songText.targetY = i;
				grpSongs.add(songText);

				FreeplayManager.callVictory = FreeplayManager.isVictorySong(songName, modName) && !isMissing && !someLocationsNotMissing;

				if (FreeplayManager.callVictory) {
					trace("Apparently, the victory song has been cleared, so... Goaling!");
					APEntryState.apGame.checkGoal(songName, modName);
				}

				songText.scaleX = Math.min(1, 980 / songText.width);
				songText.snapToPosition();

				Mods.currentModDirectory = FreeplayManager.songList[i].folder;
				
				songText.visible = songText.active = songText.isMenuItem = false;
				
				var isLock:Bool = APEntryState.inArchipelagoMode && CategoryState.loadWeekForce == "all" && isMissing && !FreeplayManager.unplayedList.contains(songName);
				var icon:HealthIcon = new HealthIcon(isLock ? "lock" : FreeplayManager.songList[i].songCharacter);
				icon.sprTracker = songText;
				icon.visible = icon.active = false;
				iconArray.push(icon);
				iconList.add(icon);
			}
			if (FreeplayManager.songList.length == -1 || FreeplayManager.songList.length == 0)
				FreeplayManager.addSong('SONG NOT FOUND', -999, 'face', [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);

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
		if (FreeplayManager.songList[curSelected] != null) 
		{
			switch(Paths.formatToSongPath(FreeplayManager.songList[curSelected].songName))
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
			FreeplayManager.reloadFreeplay(true);
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
				var songLowercase:String = Paths.formatToSongPath(FreeplayManager.songList[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);	
				Mods.currentModDirectory = FreeplayManager.songList[curSelected].folder;
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
			} catch (e:Dynamic) {
				trace('Error loading song: ' + e);
			}
			try {
				FreeplayManager.forceUnlockCheck(FreeplayManager.songList[curSelected].songName, WeekData.getCurrentWeek().folder);
			} catch (e:Dynamic) {
				trace("You can't check nothing, silly!");
			}
			MusicBeatState.resetState();
		}

		if (FlxG.keys.justPressed.H && APEntryState.inArchipelagoMode && !searchBar.hasFocus) {
			try {
				var SongInfo = APEntryState.apGame.getSongAndMod(FreeplayManager.songList[curSelected].songName + (FreeplayManager.songList[curSelected].folder != "" ? " (" + FreeplayManager.songList[curSelected].folder + ")" : ""));
				if (APEntryState.ap != null) {
					APEntryState.ap.Say("!hint " + SongInfo.song + ((SongInfo.mod != "" && SongInfo.mod != null) ? " (" + SongInfo.mod + ")" : ""));
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
			
			if(FreeplayManager.songList.length > 1)
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
					curSelected = FreeplayManager.songList.length - 1;
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
		if (FlxG.keys.justPressed.ANY && searchBar.hasFocus) FreeplayManager.reloadFreeplay(false, searchBar.text);

		if (searchBar.hasFocus == false || searchBar.text == null)
		{
			if (controls.BACK)
			{
				searchBar.hasFocus = false;
				if (player.playingMusic)
				{
					FlxG.sound.music.stop();
					FreeplayManager.destroyFreeplayVocals();
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
					if (APEntryState.inArchipelagoMode)
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
						var newSel = FlxG.random.int(0, FreeplayManager.songList.length - 1);
						if (newSel == -1)
							newSel = 0;
						curSelected = newSel;
						changeSelection();
						return;
					}

					searchBar.hasFocus = false;
					FreeplayManager.destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
	
					Mods.currentModDirectory = FreeplayManager.songList[curSelected].folder;
					var poop:String = Highscore.formatSong(FreeplayManager.songList[curSelected].songName.toLowerCase(), curDifficulty);
					Song.loadFromJson(poop, FreeplayManager.songList[curSelected].songName.toLowerCase());
					FreeplayManager.previewSong(PlayState.SONG.needsVoices);
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
					var newSel = FlxG.random.int(0, FreeplayManager.songList.length - 1);
					if (newSel == -1)
						newSel = 0;
					curSelected = newSel;
					changeSelection();
					lerpSelected = curSelected;
					return;
				}

				var vicCheck:Bool = FreeplayManager.isVictorySong(FreeplayManager.songList[curSelected].songName, FreeplayManager.songList[curSelected].folder) && APInfo.ticketCount >= APInfo.ticketWinCount;
				//You need the song AND the tickets.
				trace('can play victory song: ${vicCheck}');
				if (FreeplayManager.isVictorySong(FreeplayManager.songList[curSelected].songName, FreeplayManager.songList[curSelected].folder) && !vicCheck) {
					FlxG.camera.shake(0.005, 0.5);
					FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
					grpSongs.forEach(function(item:FlxSprite)
					{
						if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
					});
					grpLocks.forEach(function(item:FlxSprite)
					{
						if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
					});
					FlxTween.color(ticketCounter, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
					return;
				}
				
				if (FreeplayManager.trueMissing.contains(FreeplayManager.songList[curSelected].songName) && !FreeplayManager.unplayedList.contains(FreeplayManager.songList[curSelected].songName)) {
					FlxG.camera.shake(0.005, 0.5);
					FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
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
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(FreeplayManager.songList[curSelected].songName);
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
								case "beat battle":
									Song.loadFromJson('beat-battle-reasonable', 'beat-battle');
									FlxG.save.data.gotbeatbattle = true;
									FlxG.save.flush();
								case "beat battle 2":
									Song.loadFromJson('beat-battle-2-hard', 'beat-battle-2');
									FlxG.save.data.gotbeatbattle2 = true;
									FlxG.save.flush();
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
							PlayState.storyDifficulty = curDifficulty;

							trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
						}
					}
					catch(e:Dynamic)
					{
						trace('ERROR! $e');

						var errorStr:String = e.toString();
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
				
					if (FlxG.keys.pressed.SHIFT){
						ClientPrefs.openChartEditor();
					} else{
						if (!alreadyClicked)
						{
							alreadyClicked = true;
							MusicBeatState.reopen = false; //Fix a sticker bug
							LoadingState.prepareToSong();
							LoadingState.loadAndSwitchState(APEntryState.inArchipelagoMode ? new archipelago.APPlayState() : new states.PlayState());
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
						
				FreeplayManager.destroyFreeplayVocals();
				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
			else if(controls.RESET && !player.playingMusic)
			{
				searchBar.hasFocus = false;
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(FreeplayManager.songList[curSelected].songName, curDifficulty, FreeplayManager.songList[curSelected].songCharacter));
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
		FreeplayManager.destroyFreeplayVocals();
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty += change;

		if (curDifficulty < -1)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		if (FreeplayManager.songList[curSelected] == null)
			return;

		#if !switch
		intendedScore = Highscore.getScore(FreeplayManager.songList[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(FreeplayManager.songList[curSelected].songName, curDifficulty);
		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(FreeplayManager.songList[curSelected].songName, curDifficulty)]));
		rank.scale.x = rank.scale.y = 140 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = true;
		rank.scrollFactor.set();
		rank.y = 690 - rank.height;
		rank.x = -200 + FlxG.width - 50;
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		_updateSongLastDifficulty();

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < -1)
			curSelected = FreeplayManager.songList.length - 1;
		if (FreeplayManager.songList.length > 0 && curSelected >= FreeplayManager.songList.length)
			if (change > 0)
				curSelected = -1;
			else
			curSelected = FreeplayManager.songList.length - 1;

		if (curSelected == -1)
			playFreakyMusic('menuMusic/freeplayRandom');
		else if (!player.playingMusic) 
			playFreakyMusic();
		
		try {
			if (FreeplayManager.songList.length >= 0)
			{
				if (curSelected < -1)
					curSelected = FreeplayManager.songList.length - 1;
				if (curSelected >= FreeplayManager.songList.length)
					curSelected = -1;

				var newColor:Int = curSelected != -1 ? FreeplayManager.songList[curSelected].color[1][0] : FlxColor.fromString('#FD719B');
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
		
		if (FreeplayManager.songList[curSelected] != null)
		{
			Mods.currentModDirectory = FreeplayManager.songList[curSelected].folder;
			PlayState.storyWeek = FreeplayManager.songList[curSelected].week;
			try {Difficulty.loadFromWeek();} catch(e:Dynamic) {}
		}

		if (curSelected == -1) 
			diffText.visible = false;
		else
			diffText.visible = true;

		try {
			if (FreeplayManager.songList[curSelected] == null)
				return;

			if (FreeplayManager.songList[curSelected].songName != 'SONG NOT FOUND') 
			{
				Mods.currentModDirectory = FreeplayManager.songList[curSelected].folder;
				PlayState.storyWeek = FreeplayManager.songList[curSelected].week;

				switch (FreeplayManager.songList[curSelected].songName)
				{
					case 'Small Argument' | 'Beat Battle 2':
						Difficulty.list = ['Hard'];
					case "Beat Battle":
						Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
					default:
						Difficulty.loadFromWeek();
				}
				var savedDiff:String = FreeplayManager.songList[curSelected].lastDifficulty;
				var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
				if(FreeplayManager.songList[curSelected].songName != 'SONG NOT FOUND') savedDiff = WeekData.getCurrentWeek().difficulties.trim(); //Fuck you HTML5
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
				FreeplayManager.addSong('SONG NOT FOUND', -999, 'face', [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
				changeDiff();
				_updateSongLastDifficulty();
			}
		}
		catch(e)
		{
			trace("songs couldn't be found, even though there are songs??? adding SONG NOT FOUND just in case.");
			Difficulty.list = ['SONG NOT FOUND'];
			curDifficulty = 0;
			FreeplayManager.addSong('SONG NOT FOUND', -999, 'face', [[255, 255, 255], [FlxColor.fromRGB(255, 255, 255)]]);
		}

		changeDiff();
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	inline private function _updateSongLastDifficulty()
	{
		if (FreeplayManager.songList[curSelected] != null) FreeplayManager.songList[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
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

		var min:Int = Math.round(Math.max(0, Math.min(FreeplayManager.songList.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(FreeplayManager.songList.length, lerpSelected + _drawDistance)));
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
}