package states;

import substates.Prompt;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import archipelago.ArchPopup;
import archipelago.APEntryState;

import states.editors.ChartingStateOG;

import flixel.addons.ui.FlxUIInputText;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import flixel.addons.transition.FlxTransitionableState;

import flixel.math.FlxMath;
import flixel.ui.FlxButton;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import archipelago.PacketTypes.ClientStatus;

class FreeplayState extends MusicBeatState
{
	public static var instance:FreeplayState;

	var songs:Array<SongMetadata> = [];
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
	public var camGame:FlxCamera;
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

	public static var curUnlocked:Map<String, String> = new Map<String, String>();
	public static var trueUnlocked:Array<String> = [];
	public static var doChange:Bool = false;
	public static var multisong:Bool = false;
	public static var callVictory:Bool = false;
	var h:String;
	var mismatched:String = "";
	var rankTable:Array<String> = [
		'P-small', 'X-small', 'X--small', 'SS+-small', 'SS-small', 'SS--small', 'S+-small', 'S-small', 'S--small', 'A+-small', 'A-small', 'A--small',
		'B-small', 'C-small', 'D-small', 'E-small', 'NA'
	];
	var rank:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('rankings/NA'));

	var hh:Array<Chance> = [
		{item: "normal error", chance: 95}, // 95% chance to got the normal error screen
		{item: "small argument", chance: 5}, // 5% chance to play Small Argument
		{item: "beat battle", chance: 5}, // 5% chance to play Beat Battle
		{item: "beat battle 2", chance: 5} // 5% chance to do Beat Battle 2
	];
	
	override function create()
	{
		instance = this; // For Archipelago

		if (lastCategory != CategoryState.loadWeekForce)
		{
			//so it doesn't do weird things. might rework later
			//update: I reworked it
			curSelected = 0;
			lastCategory = CategoryState.loadWeekForce;
		} 

		if (APEntryState.gonnaRunSync && APEntryState.inArchipelagoMode) {
			new FlxTimer().start(3, function(tmr:FlxTimer)
			{
				APEntryState.gonnaRunSync = false;
			});
		}

		if (APEntryState.apGame != null && APEntryState.apGame.info() != null) {
			APEntryState.apGame.info().Sync();

			function getLastParenthesesContent(input:String):String {
				var lastParenIndex = input.lastIndexOf("(");
				if (lastParenIndex != -1) {
					var endIndex = input.indexOf(")", lastParenIndex);
					if (endIndex != -1) {
						return input.substring(lastParenIndex + 1, endIndex);
					}
				}
				return "";
			}

			if (curUnlocked.exists(APEntryState.victorySong) && callVictory)
			{
				callVictory = false;
				APEntryState.apGame.info().clientStatus = ClientStatus.GOAL;
				openSubState(new Prompt("Congradulations! You Win!", 0, 
				function()
				{
					collectAndRelease();
					MusicBeatState.switchState(new APEntryState());
					APEntryState.inArchipelagoMode = false;
				},
				function()
				{
					collectAndRelease();
					MusicBeatState.switchState(new MainMenuState());
					APEntryState.inArchipelagoMode = false;
				}, false, "Return to Archipelago Menu", "Return to Main Menu"));
			}
		}
		Highscore.reloadModifiers();
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		#if sys
		ArtemisIntegration.setGameState ("menu");
		ArtemisIntegration.resetModName ();
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

		/*for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var categoryWhaat:String = leWeek.category;
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				if (categoryWhaat.toLowerCase() == CategoryState.loadWeekForce || (CategoryState.loadWeekForce == "mods" && categoryWhaat == null) || CategoryState.loadWeekForce == "all")
				{
					if (APEntryState.inArchipelagoMode)
					{
						for (songName in curUnlocked.keys())
						{
							if ((song[0] == songName || checkStringCombinations(songName, song[0])) && leWeek.folder == curUnlocked.get(songName))
								for (comb in getAllStringCombinations(songName))
									addSong(comb, i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
						}
					}
					else addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				}
			}
		}*/

		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		iconList = new FlxTypedGroup<HealthIcon>();
		add(iconList);

		// if (!ClientPrefs.data.disableFreeplayAlphabet)
		randomText = new Alphabet(90, 320, "RANDOM", true);
		// else
		// 	randomText = new online.objects.AlphaLikeText(90, 320, "RANDOM");
		randomText.scaleX = Math.min(1, 980 / randomText.width);
		randomText.targetY = -1;
		randomText.snapToPosition();
		add(cast randomText);

		randomIcon = new HealthIcon('bf');
		randomIcon.sprTracker = cast randomText;
		randomIcon.scrollFactor.set(1, 1);
		add(randomIcon);

		/*for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			// but over on mixtape engine we do arrays better
			iconArray.push(icon);
			iconList.add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}*/
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

		if(curSelected >= songs.length) curSelected = -1;
		try {
			bg.color = songs[curSelected].color;
			intendedColor = bg.color;
			#if sys
			ArtemisIntegration.setBackgroundFlxColor (intendedColor);
			#end
		}
		catch(e)
		{
			bg.color = FlxColor.WHITE;
			intendedColor = bg.color;
			#if sys
			ArtemisIntegration.setBackgroundFlxColor (intendedColor);
			#end
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
		
		changeSelection();
		updateTexts();
		super.create();
		FlxTween.tween(rank, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});
		FlxTween.tween(searchBar, {y: 100}, 0.6, {
			ease: FlxEase.elasticInOut, 
			onComplete: function(twn:FlxTween){
				searchBar.updateHitbox();
		}});

		// Main.simulateIntenseMaps();
		trace(hh);

		reloadSongs(true);
	}

	public function checkStringCombinations(input:String, target:String):Bool {
		var combinations:Array<String> = [];
		var chars:Array<String> = input.split('');
		
		// Generate all combinations of capital letters
		for (i in 0...Std.int(Math.pow(2, chars.length))) {
			var combination:String = '';
			for (j in 0...chars.length) {
				if ((i >> j) & 1 == 1) {
					combination += chars[j].toUpperCase();
				} else {
					combination += chars[j].toLowerCase();
				}
			}
			combinations.push(combination);
		}

		// Generate combinations with dashes and spaces
		var finalCombinations:Array<String> = [];
		for (comb in combinations) {
			finalCombinations.push(comb);
			finalCombinations.push(comb.replace('-', ' '));
			finalCombinations.push(comb.replace(' ', '-'));
		}

		// Check if target matches any combination
		for (comb in finalCombinations) {
			if (comb == target) {
				return true;
			}
		}
		return false;
	}
	public function getAllStringCombinations(input:String):Array<String> {
		var combinations:Array<String> = [];
		var chars:Array<String> = input.split('');
		
		// Generate all combinations of capital letters
		for (i in 0...Std.int(Math.pow(2, chars.length))) {
			var combination:String = '';
			for (j in 0...chars.length) {
				if ((i >> j) & 1 == 1) {
					combination += chars[j].toUpperCase();
				} else {
					combination += chars[j].toLowerCase();
				}
			}
			combinations.push(combination);
		}

		// Generate combinations with dashes and spaces
		var finalCombinations:Array<String> = [];
		for (comb in combinations) {
			finalCombinations.push(comb);
			finalCombinations.push(comb.replace('-', ' '));
			finalCombinations.push(comb.replace(' ', '-'));
		}

		return finalCombinations;
	}

	function collectAndRelease()
	{
		APEntryState.apGame.info().Say("!release");
		APEntryState.apGame.info().Say("!collect");
		APEntryState.apGame.info().poll();
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

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	public function reloadSongs(?refresh:Bool = false)
	{
		if (instance != null)
		{
			grpSongs.clear();
			songs = [];
			iconArray = [];
			iconList.clear();
			
			for (i in 0...iconArray.length)
			{
				iconArray.pop();
			}

			for (i in 0...WeekData.weeksList.length) {
				if(weekIsLocked(WeekData.weeksList[i]) && !APEntryState.inArchipelagoMode) continue;

				var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
				var leSongs:Array<String> = [];
				var leChars:Array<String> = [];

				for (j in 0...leWeek.songs.length)
				{
					leSongs.push(leWeek.songs[j][0]);
					leChars.push(leWeek.songs[j][1]);
				}

				WeekData.setDirectoryFromWeek(leWeek);
				for (song in leWeek.songs)
				{
					var categoryWhaat:String = leWeek.category;
					var colors:Array<Int> = song[2];
					if(colors == null || colors.length < 3)
					{
						colors = [146, 113, 253];
					}
					if (categoryWhaat.toLowerCase() == CategoryState.loadWeekForce || (CategoryState.loadWeekForce == "mods" && categoryWhaat == null) || CategoryState.loadWeekForce == "all")
					{
						if (refresh)
						{
							var colors:Array<Int> = song[2];
							if(colors == null || colors.length < 3)
							{
								colors = [146, 113, 253];
							}
							if (categoryWhaat.toLowerCase() == CategoryState.loadWeekForce || (CategoryState.loadWeekForce == "mods" && categoryWhaat == null) || CategoryState.loadWeekForce == "all")
							{
								if (APEntryState.inArchipelagoMode)
								{
									var songNameThing:String = song[0];
									for (songName in curUnlocked.keys())
									{
										if ((songNameThing.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == curUnlocked.get(songName))
											addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
									}
								}
								else addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
							}
						}
						else
						{	
							if (Std.string(song[0]).toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()))
							{
								var colors:Array<Int> = song[2];
								if(colors == null || colors.length < 3)
								{
									colors = [146, 113, 253];
								}
								if (categoryWhaat.toLowerCase() == CategoryState.loadWeekForce || (CategoryState.loadWeekForce == "mods" && categoryWhaat == null) || CategoryState.loadWeekForce == "all")
								{
									if (APEntryState.inArchipelagoMode)
									{
										var songNameThing:String = song[0];
										for (songName in curUnlocked.keys())
										{
											if ((songNameThing.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ')) && leWeek.folder == curUnlocked.get(songName))
												addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
										}
									}
									else addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
								}
							}
						}
					}
				}
			}

			if (APEntryState.inArchipelagoMode)
			{
				if (refresh)
				{
					for (songName in curUnlocked.keys()) {
						if (songName.trim().toLowerCase().replace('-', ' ') == 'small argument'.trim().toLowerCase().replace('-', ' ') && curUnlocked.get(songName) == '')
							addSong('Small Argument', 0, "gfchibi", FlxColor.fromRGB(235, 100, 161));
						if (songName.trim().toLowerCase().replace('-', ' ') == 'beat battle'.trim().toLowerCase().replace('-', ' ') && curUnlocked.get(songName) == '')
							addSong('Beat Battle', 0, "gf", FlxColor.fromRGB(165, 0, 77));
						if (songName.trim().toLowerCase().replace('-', ' ') == 'beat battle 2'.trim().toLowerCase().replace('-', ' ') && curUnlocked.get(songName) == '')
							addSong('Beat Battle 2', 0, "gf", FlxColor.fromRGB(165, 0, 77));
					}
				}
				else
				{
					if (curUnlocked.exists('Small Argument'.toLowerCase()) && Std.string('Small Argument').toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()) && FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Small Argument', 0, "gfchibi", FlxColor.fromRGB(235, 100, 161));
					if (curUnlocked.exists('Beat Battle'.toLowerCase()) && Std.string('Beat Battle').toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Beat Battle', 0, "gf", FlxColor.fromRGB(165, 0, 77));
					if (curUnlocked.exists('Beat Battle 2'.toLowerCase()) && Std.string('Beat Battle 2').toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Beat Battle 2', 0, "gf", FlxColor.fromRGB(165, 0, 77));
				}
			}
			else
			{
				if (refresh)
				{
					if (FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Small Argument', 0, "gfchibi", FlxColor.fromRGB(235, 100, 161));
					if (FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Beat Battle', 0, "gf", FlxColor.fromRGB(165, 0, 77));
					if (FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Beat Battle 2', 0, "gf", FlxColor.fromRGB(165, 0, 77));
				}
				else
				{
					if (Std.string('Small Argument').toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()) && FlxG.save.data.gotIntoAnArgument && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Small Argument', 0, "gfchibi", FlxColor.fromRGB(235, 100, 161));
					if (Std.string('Beat Battle').toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Beat Battle', 0, "gf", FlxColor.fromRGB(165, 0, 77));
					if (Std.string('Beat Battle 2').toLowerCase().trim().contains(searchBar.text.toLowerCase().trim()) && FlxG.save.data.gotbeatbattle2 && (CategoryState.loadWeekForce == "secrets" || CategoryState.loadWeekForce == "all")) 
						addSong('Beat Battle 2', 0, "gf", FlxColor.fromRGB(165, 0, 77));
				}
			}
			
			for (i in 0...songs.length)
			{
				var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
				songText.targetY = i;
				grpSongs.add(songText);

				songText.scaleX = Math.min(1, 980 / songText.width);
				songText.snapToPosition();

				Mods.currentModDirectory = songs[i].folder;
				var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
				icon.sprTracker = songText;

				
				// too laggy with a lot of songs, so i had to recode the logic for it
				songText.visible = songText.active = songText.isMenuItem = false;
				icon.visible = icon.active = false;

				// using a FlxGroup is too much fuss!
				// but over on mixtape engine we do arrays better
				iconArray.push(icon);
				iconList.add(icon);

				// songText.x += 40;
				// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
				// songText.screenCenter(X);
			}
			WeekData.setDirectoryFromWeek();
			if (songs.length == -1 || songs.length == 0)
			{
				addSong('SONG NOT FOUND', -999, 'face', FlxColor.fromRGB(255, 255, 255));

			}
			changeSelection();
			updateTexts();
			changeDiff();
			if (PlayState.SONG != null) Conductor.bpm = PlayState.SONG.bpm;
		}
	} 

	var instPlaying:Int = -1;
	var trackPlaying:String = null;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	public static var gfVocals:FlxSound = null;
	var holdTime:Float = 0;
	var stopMusicPlay:Bool = false;

	function forceUnlockCheck(songName:String, modName:String):Void {
		var locationId = songName;
		trace(modName);
		if (modName.trim() != "") {
			locationId += " (" + modName + ")";
		}
		trace(locationId.trim());
		var locationIdInt = archipelago.APEntryState.apGame.info().get_location_id(locationId.trim());
		trace('Location ID: ' + locationIdInt);
	
		if (locationIdInt == null || locationIdInt <= 0) {
			for (song in WeekData.getCurrentWeek().songs) {
				if ((cast song[0] : String).toLowerCase().trim() == songName.trim().toLowerCase() ||
					(cast song[0] : String).toLowerCase().trim().replace(" ", "-") == songName.trim().toLowerCase().replace(" ", "-")) {
					locationIdInt = modName.trim() != ""
						? archipelago.APEntryState.apGame.info().get_location_id(song[0] + " (" + modName + ")")
						: archipelago.APEntryState.apGame.info().get_location_id(song[0]);
					locationId = modName.trim() != ""
						? song[0] + " (" + modName + ")"
						: song[0];
					break;
				}
			}
		}
	
		if (locationIdInt <= 0 || locationIdInt == null) {
			for (song in WeekData.getCurrentWeek().songs) {
				var songPath = modName.trim() != ""
					? "mods/" + modName + "/data/" + song[0] + "/" + song[0] + "-" + Difficulty.getString(PlayState.storyDifficulty) + ".json"
					: "assets/shared" + (song[0] + Difficulty.getFilePath());
				var songJson:SwagSong = null;
				var jsonStuff:Array<String> = Paths.crawlDirectoryOG("mods/" + modName + "/data", ".json");
	
				for (json in jsonStuff) {
					if (json.trim().toLowerCase().replace(" ", "-") == songPath.trim().toLowerCase().replace(" ", "-")) {
						songJson = Song.parseJSON(File.getContent(json));
						if (songJson != null) {
							if (songJson.song.trim().toLowerCase().replace(" ", "-") == songName.trim().toLowerCase().replace(" ", "-")) {
								locationIdInt = modName.trim() != ""
									? archipelago.APEntryState.apGame.info().get_location_id(song[0] + " (" + modName + ")")
									: archipelago.APEntryState.apGame.info().get_location_id(song[0]);
								locationId = modName.trim() != "" ? song[0] + " (" + modName + ")" : song[0];
								break;
							}
						}
					}
				}
			}
		}
		trace(APEntryState.apGame.info().LocationChecks([locationIdInt]));
		trace(APEntryState.apGame.info().get_location_name(locationIdInt));
		trace(songName);
		archipelago.ArchPopup.startPopupCustom("You've sent " + APEntryState.apGame.info().get_location_name(locationIdInt) + " to Archipelago!", "Go check it out!", "archColor", function() {
			FlxG.sound.playMusic(Paths.sound('secret'));
		});
	
		locationIdInt = APEntryState.apGame.info().get_location_id(locationId.trim());
		if (locationIdInt != null && APEntryState.apGame.info().get_location_name(locationIdInt).trim().toLowerCase().replace(" ", "-") == APEntryState.victorySong.trim().toLowerCase().replace(" ", "-")) {
			archipelago.ArchPopup.startPopupCustom("You've completed your goal!", "You win!", "archColor", function() {
				FlxG.sound.playMusic(Paths.sound('secret'));
			});
			APEntryState.apGame.info().set_goal();
		}
	}

	override function update(elapsed:Float)
	{
		if (songs[curSelected] != null) 
		{
			switch(Paths.formatToSongPath(songs[curSelected].songName))
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

		if (instPlaying != -1 && iconList.members[instPlaying] != null) {
			var mult:Float = FlxMath.lerp(1, iconList.members[instPlaying].scale.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			iconList.members[instPlaying].scale.set(mult, mult);
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
			reloadSongs();
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

		if (FlxG.keys.justPressed.L && APEntryState.inArchipelagoMode)  {
			try {
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);	
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
			} catch (e:Dynamic) {
				trace('Error loading song: ' + e);
			}
			forceUnlockCheck(songs[curSelected].songName, WeekData.getCurrentWeek().folder);
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
			
			if(songs.length > 1)
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
					curSelected = songs.length - 1;
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
		if (FlxG.keys.justPressed.ANY && searchBar.hasFocus) reloadSongs();

		if (searchBar.hasFocus == false || searchBar.text == null)
		{
			if (controls.BACK)
			{
				searchBar.hasFocus = false;
				if (player.playingMusic)
				{
					FlxG.sound.music.stop();
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
					instPlaying = -1;

					player.playingMusic = false;
					player.switchPlayMusic();

					FlxG.sound.playMusic(Paths.music('panixPress'), 0);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
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
						var newSel = FlxG.random.int(0, songs.length - 1);
						if (newSel == -1)
							newSel = 0;
						curSelected = newSel;
						changeSelection();
						return;
					}

					searchBar.hasFocus = false;
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
	
					Mods.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					if (PlayState.SONG.needsVoices)
					{
						vocals = new FlxSound();
						try
						{
							var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
							var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
							if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
							
							if(loadedVocals != null)
							{
								vocals.loadEmbedded(loadedVocals);
								FlxG.sound.list.add(vocals);
								vocals.persist = vocals.looped = true;
								vocals.volume = 0.8;
								vocals.play();
								vocals.pause();
							}
							else vocals = FlxDestroyUtil.destroy(vocals);
						}
						catch(e:Dynamic)
						{
							vocals = FlxDestroyUtil.destroy(vocals);
						}
						
						opponentVocals = new FlxSound();
						gfVocals = new FlxSound();
						try
						{
							//trace('please work...');
							var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
							var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
							var loadedgfVocals = Paths.voices(PlayState.SONG.song, 'gf');
							
							if(loadedVocals != null)
							{
								opponentVocals.loadEmbedded(loadedVocals);
								FlxG.sound.list.add(opponentVocals);
								opponentVocals.persist = opponentVocals.looped = true;
								opponentVocals.volume = 0.8;
								opponentVocals.play();
								opponentVocals.pause();
								//trace('yaaay!!');
							}
							else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);

							if(loadedgfVocals != null)
							{
								gfVocals.loadEmbedded(loadedgfVocals);
								FlxG.sound.list.add(gfVocals);
								gfVocals.persist = gfVocals.looped = true;
								gfVocals.volume = 0.8;
								gfVocals.play();
								gfVocals.pause();
								//trace('yaaay!!');
							}
							else gfVocals = FlxDestroyUtil.destroy(gfVocals);
						}
						catch(e:Dynamic)
						{
							//trace('FUUUCK');
							opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
							gfVocals = FlxDestroyUtil.destroy(gfVocals);
						}
					}
	
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
					FlxG.sound.music.pause();
					instPlaying = curSelected;
					trackPlaying = poop;
					player.playingMusic = true;
					player.curTime = 0;
					player.switchPlayMusic();
					player.pauseOrResume(true);
				}
				else if (instPlaying == curSelected && player.playingMusic)
				{
					player.pauseOrResume(!player.playing);
				}
			}
			else if (controls.ACCEPT && !player.playingMusic && !searchBar.hasFocus)
			{
				if (curSelected == -1) {
					var newSel = FlxG.random.int(0, songs.length - 1);
					if (newSel == -1)
						newSel = 0;
					curSelected = newSel;
					changeSelection();
					lerpSelected = curSelected;
					return;
				}

				searchBar.hasFocus = false;
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
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
						TransitionState.transitionState(ChartingStateOG, {transitionType: "stickers"});
					} else{
						if (!CacheState.didPreCache)
						{
							if (!alreadyClicked)
							{
								LoadingState.loadNextDirectory();
								alreadyClicked = true;
								MusicBeatState.reopen = false; //Fix a sticker bug
								TransitionState.transitionState(APEntryState.inArchipelagoMode ? archipelago.APPlayState : states.PlayState, {transitionType: "instant"});
								/*LoadingState.prepareToSong();
								LoadingState.loadAndSwitchState(new states.PlayState());*/
							}
							else TransitionState.transitionState(APEntryState.inArchipelagoMode ? archipelago.APPlayState : states.PlayState, {transitionType: "instant"});
						}
						else TransitionState.transitionState(APEntryState.inArchipelagoMode ? archipelago.APPlayState : states.PlayState, {transitionType: "instant"});
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
						
				destroyFreeplayVocals();
				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
			else if(controls.RESET && !player.playingMusic)
			{
				searchBar.hasFocus = false;
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
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

	var alreadyClicked:Bool = false;
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public function playFreakyMusic(?musName:String = 'panixPress', ?bpm:Float = 102) {
		if (trackPlaying == musName)
			return;

		FlxG.sound.playMusic(Paths.music(musName), 0);
		FlxG.sound.music.fadeIn(3, 0, 0.7);
		Conductor.bpm = bpm;
		listening = false;
		instPlaying = -1;
		trackPlaying = musName;
		destroyFreeplayVocals();
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		if (songs[curSelected] == null)
			return;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(songs[curSelected].songName, curDifficulty)]));
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
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < -1)
			curSelected = songs.length - 1;
		if (songs.length > 0 && curSelected >= songs.length)
			curSelected = -1;

		if (curSelected == -1)
			playFreakyMusic('freeplayRandom');
		else if (!player.playingMusic)
			playFreakyMusic('panixPress', TitleState.globalBPM);
		
		try {
			if (songs.length >= 0)
			{
				if (curSelected < -1)
					curSelected = songs.length - 1;
				if (curSelected >= songs.length)
					curSelected = -1;

				var newColor:Int = curSelected != -1 ? songs[curSelected].color : FlxColor.fromString('#FD719B');
				if(newColor != intendedColor) {
					if(colorTween != null) {
						colorTween.cancel();
					}
					intendedColor = newColor;
					#if sys
					ArtemisIntegration.setBackgroundFlxColor (intendedColor);
					#end
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

		try {
			for (i in 0...iconArray.length)
			{
				if (iconArray[i] != null && iconArray[i].animation != null)
				{
					iconArray[i].alpha = 0.4;
					switch (iconArray[i].type) {
						case SINGLE: iconArray[i].animation.curAnim.curFrame = 0;
						case WINNING: iconArray[i].animation.curAnim.curFrame = 0;
						default: iconArray[i].animation.curAnim.curFrame = 0;
					}
				}
			}

			if (iconArray[curSelected] != null)
			{
				iconArray[curSelected].alpha = 1;
				switch (iconArray[curSelected].type) {
					case SINGLE: iconArray[curSelected].animation.curAnim.curFrame = 0;
					case WINNING: iconArray[curSelected].animation.curAnim.curFrame = 1;
					default: iconArray[curSelected].animation.curAnim.curFrame = 0;
				}
			}
		}
		catch(e)
		{
			trace("Your icon broke! Skipping...");
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
		
		if (songs[curSelected] != null)
		{
			Mods.currentModDirectory = songs[curSelected].folder;
			PlayState.storyWeek = songs[curSelected].week;
			try {Difficulty.loadFromWeek();} catch(e:Dynamic) {}
		}

		if (curSelected == -1) 
			diffText.visible = false;
		else
			diffText.visible = true;

		try {
			if (songs[curSelected] == null)
				return;

			if (songs[curSelected].songName != 'SONG NOT FOUND') 
			{
				Mods.currentModDirectory = songs[curSelected].folder;
				PlayState.storyWeek = songs[curSelected].week;

				switch (songs[curSelected].songName)
				{
					case 'Small Argument' | 'Beat Battle 2':
						Difficulty.list = ['Hard'];
					case "Beat Battle":
						Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
					default:
						Difficulty.loadFromWeek();
				}
				var savedDiff:String = songs[curSelected].lastDifficulty;
				var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
				if(songs[curSelected].songName != 'SONG NOT FOUND') savedDiff = WeekData.getCurrentWeek().difficulties.trim(); //Fuck you HTML5
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
				addSong('SONG NOT FOUND', -999, 'face', FlxColor.fromRGB(255, 255, 255));
				changeDiff();
				_updateSongLastDifficulty();
			}
		}
		catch(e)
		{
			trace("songs couldn't be found, even though there are songs??? adding SONG NOT FOUND just in case.");
			Difficulty.list = ['SONG NOT FOUND'];
			curDifficulty = 0;
			addSong('SONG NOT FOUND', -999, 'face', FlxColor.fromRGB(255, 255, 255));
		}

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		if (songs[curSelected] != null) songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
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
			if(iconArray[i] != null) iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		updateScrollable(randomText, elapsed);
		if (curSelected == -1)
			randomText.alpha = 1;
		randomIcon.alpha = randomText.alpha;

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
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
				icon.visible = icon.active = true;
				_lastVisibles.push(i);
			}
		}
	}

	override function beatHit()
	{
		camGame.zoom = zoomies;

		FlxTween.tween(camGame, {zoom: 1}, Conductor.crochet / 1300, {
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
			FlxG.sound.playMusic(Paths.music('panixPress'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}