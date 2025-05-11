package states.freeplay;

import flixel.input.keyboard.FlxKey;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import states.freeplay.osu.DifficultySelectorSubState;
import states.freeplay.osu.SongBox;

import sys.FileSystem;
import sys.io.File;

import haxe.Json;

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
#end

class OsuFreeplayState extends MusicBeatState
{
	public static var instance:OsuFreeplayState;

	var back:FlxSprite;
	var backHitbox:FlxSprite;
	var fakeLogo:FlxSprite;

	var searchTypeText:FlxText;
	var searchTypeTextHitbox:FlxSprite;
	var albumPhoto:FlxSprite;

	var isTyping:Bool = false;

	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

	var background:FlxSprite;

	private var songBox:FlxTypedGroup<SongBox>;
	private var iconGrp:FlxTypedGroup<HealthIcon>;
	private var textGrp:FlxTypedGroup<FlxText>;

	private static var curSelected:Int = 0;
	private static var maxSelected:Int = 0;

	var inSub:Bool = false;

	var staleBg:FlxSprite;
	var ticketCounterTop:FlxText = null;
	var ticketCounterBottom:FlxText = null;
	override function create()
	{
		#if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end

		instance = this; // For Archipelago

		Paths.clearStoredWithoutStickers();
		
		Cursor.cursorMode = Default;

		#if windows
		backend.window.CppAPI.resetAffixes();
		backend.window.CppAPI.resetTitle();
		#end

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		FlxG.mouse.visible = true;

		staleBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff646464);
		add(staleBg);

		songBox = new FlxTypedGroup<SongBox>();
		add(songBox);
		
		textGrp = new FlxTypedGroup<FlxText>();
		add(textGrp);

		iconGrp = new FlxTypedGroup<HealthIcon>();
		add(iconGrp);

		FreeplayManager.reloadFreeplay(true);

		var topBar:FlxSprite = new FlxSprite(0, -87).loadGraphic(Paths.image('OSUState/barTop'));
		topBar.setGraphicSize(1280, 152);
		topBar.screenCenter(X);
		add(topBar);

		var botBar:FlxSprite = new FlxSprite(0, 537).loadGraphic(Paths.image('OSUState/barbot'));
		botBar.setGraphicSize(1280, 119);
		botBar.screenCenter(X);
		add(botBar);
		
		var logo:FlxSprite = new FlxSprite(0, 460).loadGraphic(Paths.image('logo'));
		logo.setGraphicSize(200, 100);
		logo.screenCenter(X);
		add(logo);
		
		fakeLogo = new FlxSprite(0, 460).loadGraphic(Paths.image('logo'));
		fakeLogo.setGraphicSize(200, 100);
		fakeLogo.screenCenter(X);
		fakeLogo.alpha = 0;
		add(fakeLogo);

		var black:FlxSprite = new FlxSprite(0, 670).makeGraphic(70, 40, 0xff000000);
		add(black);

		back = new FlxSprite(-350, 565).loadGraphic(Paths.image('OSUState/back'));
		back.setGraphicSize(300, 89);
		add(back);

		backHitbox = new FlxSprite(30, 670).makeGraphic(100, 29, 0xffffffff);
		backHitbox.alpha = 0.0001;
		add(backHitbox);

		var yelSearch:FlxSprite = new FlxSprite(450, 45).loadGraphic(Paths.image('OSUState/search'));
		yelSearch.setGraphicSize(70, 16);
		add(yelSearch);

		searchTypeText = new FlxText(550, 48, FlxG.width * 10, 'Type Here To Search!', 20);
		searchTypeText.font = Paths.font('vcr.ttf');
		add(searchTypeText);

		searchTypeTextHitbox = new FlxSprite(550, 51).makeGraphic(290, 18, 0xffffffff);
		searchTypeTextHitbox.alpha = 0.0001;
		add(searchTypeTextHitbox);

		albumPhoto = new FlxSprite(130, 0).loadGraphic(Paths.image('albums/NoCover'));
		albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
		albumPhoto.screenCenter(Y);
		albumPhoto.y += 20;
		add(albumPhoto);

		WeekData.setDirectoryFromWeek();

		// logoTween();

		changeSong();

		if (APEntryState.apGame != null && APEntryState.apGame.info() != null) {
			ticketCounterTop = new FlxText(albumPhoto.x - 130, albumPhoto.y - 230, 0, "0/0", 32);
			ticketCounterTop.setFormat(Paths.font("fnf1.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ticketCounterTop.scrollFactor.set();
			add(ticketCounterTop);

			ticketCounterBottom = new FlxText(backHitbox.x + 100, backHitbox.y, 0, "0/0", 32);
			ticketCounterBottom.setFormat(Paths.font("fnf1.ttf"), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ticketCounterBottom.scrollFactor.set();
			add(ticketCounterBottom);
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				archipelago.APGameState.haventranyet = false;
			});
		}

		if (archipelago.APItem.activeItem?.condition.type == archipelago.APItem.ConditionType.PlayState)
			archipelago.APItem.activeItem = null;

		super.create();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		Mods.loadTopMod();
	}

	var holdTime:Float = 0;
	var stopMusicPlay:Bool = false;
	var victoryColor:FlxColor;
	var e:Int = 0;
	override public function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		e++;
		FlxG.watch.addQuick('Search Text', searchTypeText.text);

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		for(item in songBox)
		{
			var coolEffect:Int = 0;

			if(item.ID < curSelected)
				coolEffect = ((item.ID - curSelected) * 30);
			else if (item.ID > curSelected)
				coolEffect = -((item.ID - curSelected) * 30);

			item.x = FlxMath.lerp(item.ID == curSelected? 280 : 320 - coolEffect, item.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		}

		#if ARCHIPELAGO_ALLOWED
		if (APEntryState.inArchipelagoMode) {
			victoryColor = FlxColor.fromHSL(((e / 2) / 300 * 360) % 360, 1.0, 0.5 * 1.0);

			for (i in 0...FreeplayManager.songList.length) {
				if (FreeplayManager.isVictorySong(FreeplayManager.songList[i].songName, FreeplayManager.songList[i].folder)) {
					songBox.members[i].color = victoryColor;
				}
			}

			if (FlxG.keys.justPressed.L && APEntryState.inArchipelagoMode && !isTyping)  {
				try { //Because this menu has no actual difficulty select, just assume it's the first difficulty
					var songLowercase:String = Paths.formatToSongPath(FreeplayManager.songList[curSelected].songName);
					var poop:String = Highscore.formatSong(songLowercase, 0);
					Mods.currentModDirectory = FreeplayManager.songList[curSelected].folder;
					Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 0;
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

			if (FlxG.keys.justPressed.H && APEntryState.inArchipelagoMode && !isTyping) {
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
		}
		#end

		persistentUpdate = true;
		PlayState.isStoryMode = false;

		for(icon in iconGrp)
		{
			var theY:Float = 0;
			var theX:Float = 0;
			for(item in songBox)
				if(item.ID == icon.ID) {
					theY = item.y;
					theX = item.x;
				}

			icon.y = theY + 25;
			icon.x = theX + 360;
		}

		for(text in textGrp)
		{
			var theY:Float = 0;
			var theX:Float = 0;
			for(item in songBox)
				if(item.ID == text.ID) {
					theY = item.y;
					theX = item.x;
				}

			text.y = theY + 70;
			text.x = theX + 480;
		}

		if(!isTyping && !inSub)
		{
			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

			if(FlxG.mouse.overlaps(backHitbox))
				back.setColorTransform(-1, -1, -1, 1, 246, 190, 0);
			if(!FlxG.mouse.overlaps(backHitbox))
				back.setColorTransform(1, 1, 1, 1, 1, 1, 1, 0);

			if(controls.BACK || FlxG.mouse.overlaps(backHitbox) && FlxG.mouse.justPressed)
				MusicBeatState.switchState(new CategoryState());

			if(FlxG.mouse.overlaps(searchTypeTextHitbox))
			{
				if(FlxG.mouse.justPressed)
				{
					isTyping = true;

					if(searchTypeText.text == 'Type Here To Search!')
						searchTypeText.text = '';
				}
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSong(-shiftMult * FlxG.mouse.wheel, false);
			}

			if (controls.UI_UP_P)
			{
				changeSong(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P)
			{
				changeSong(shiftMult);
				holdTime = 0;
			}
			
			if(controls.UI_UP || controls.UI_DOWN) {
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSong((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}
			else if(FlxG.keys.justPressed.HOME)
			{
				curSelected = 0;
				holdTime = 0;
				changeSong();
			}
			else if(FlxG.keys.justPressed.END)
			{
				curSelected = maxSelected - 1;
				holdTime = 0;
				changeSong();
			}
			else if(FlxG.keys.justPressed.PAGEUP || FlxG.keys.justPressed.PAGEDOWN)
				changeSong(FlxG.keys.justPressed.PAGEUP? -6 : 6);
			
			if(controls.ACCEPT)
			{
				var vicCheck:Bool = FreeplayManager.isVictorySong(FreeplayManager.songList[curSelected].songName, FreeplayManager.songList[curSelected].folder) && APInfo.ticketCount >= APInfo.ticketWinCount;
				//You need the song AND the tickets.
				trace('can play victory song: ${vicCheck}');
				if (FreeplayManager.isVictorySong(FreeplayManager.songList[curSelected].songName, FreeplayManager.songList[curSelected].folder) && !vicCheck) {
					FlxG.camera.shake(0.005, 0.5);
					FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
					var ogColor = songBox.members[curSelected].color;
					songBox.forEach(function(item:FlxSprite)
					{
						if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, ogColor, {ease: FlxEase.sineIn});
					});
					FlxTween.color(ticketCounterTop, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
					return;
				}
				
				if (FreeplayManager.trueMissing.contains(FreeplayManager.songList[curSelected].songName) && !FreeplayManager.unplayedList.contains(FreeplayManager.songList[curSelected].songName)) {
					FlxG.camera.shake(0.005, 0.5);
					FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
					var ogColor = songBox.members[curSelected].color;
					songBox.forEach(function(item:FlxSprite)
					{
						if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, ogColor, {ease: FlxEase.sineIn});
					});
					return;
				}
				
				reloadSongArray();
				//inSub = true;
				//openSubState(new DifficultySelectorSubState(FreeplayManager.songList[curSelected]));
			}

			if(FlxG.keys.justPressed.TAB)
			{
				inSub = true;
				openSubState(new GameplayChangersSubstate());
			}
		}

		if(isTyping)
		{
			if(!FlxG.mouse.overlaps(searchTypeTextHitbox) && FlxG.mouse.justPressed)
			{
				isTyping = false;
				if(searchTypeText.text == '')
					searchTypeText.text = 'Type Here To Search!';
			}

			if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					if(FlxG.keys.pressed.SHIFT)
						searchTypeText.text += keyName.toUpperCase();
					else
						searchTypeText.text += keyName.toLowerCase();
				}
			}

			if(FlxG.keys.pressed.BACKSPACE)
				searchTypeText.text = searchTypeText.text.substring(0, searchTypeText.text.length - 1);
			if(FlxG.keys.justPressed.SPACE)
				searchTypeText.text += ' ';
			if(FlxG.keys.justPressed.ENTER)
			{
				isTyping = false;
				if(searchTypeText.text == '') {
					searchTypeText.text = 'Type Here To Search!';
					FreeplayManager.reloadFreeplay(true);
				}
				else
					FreeplayManager.reloadFreeplay(false, searchTypeText.text);
			}
		}

		super.update(elapsed);

		if (ticketCounterTop != null && ticketCounterBottom != null) {
			ticketCounterTop.text = 'Current ticket amount: ${APInfo.ticketCount}\n' +
				'Tickets Needed: ${APInfo.ticketWinCount}\n' +
				'Tickets Left: ${Std.int(APInfo.ticketWinCount - APInfo.ticketCount)}\n';
			ticketCounterBottom.text = 'Hint Points Available: ${APInfo.hintPoints}' +
				'   Hint Cost: ${APInfo.hintCost}' +
				'   (L) to release song' +
				'   (H) to hint song';
		}
	}

	override function closeSubState() {
		inSub = false;
		super.closeSubState();
	}

	function logoTween()
	{
		fakeLogo.alpha = 1;

		FlxTween.tween(fakeLogo, {alpha: 0}, 0.6);
		FlxTween.tween(fakeLogo.scale, {x: 0.33, y: 0.33}, 0.6);
	}

	public static var metadata:Dynamic = null;
	function changeSong(change:Int = 0, playSound:Bool = true)
	{
		curSelected += change;

		if(curSelected > maxSelected - 1)
			curSelected = 0;
		if(curSelected < 0)
			curSelected = maxSelected - 1;

		var i:Int = 0;
		for(item in songBox)
			item.posY = i++ - curSelected;

		if (FreeplayManager.songList[curSelected] != null)
		{
			WeekData.setDirectoryFromWeek();
			Mods.currentModDirectory = FreeplayManager.songList[curSelected].folder;
			PlayState.storyWeek = FreeplayManager.songList[curSelected].week;
			try {
				switch (FreeplayManager.songList[curSelected].songName)
				{
					case 'Small Argument' | 'Beat Battle 2':
						Difficulty.list = ['Hard'];
					case "Beat Battle":
						Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
					default:
						Difficulty.loadFromWeek();
				}
			} catch(e:Dynamic) {}
			try {metadata = FreeplayManager.metadata.get(FreeplayManager.songList[curSelected].songName.toLowerCase());}
			catch(e) {metadata = null;}

			if (metadata != null && metadata.freeplay != null) {
				if (metadata.freeplay.bg != null && metadata.freeplay.bg != '') {
					staleBg.loadGraphic(Paths.image(metadata.freeplay.bg));
					staleBg.screenCenter();
				} else {
					staleBg.makeGraphic(FlxG.width, FlxG.height, 0xff646464);
					staleBg.screenCenter();
				}

				if (albumPhoto != null) {
					if (metadata.freeplay.album != null && metadata.freeplay.album != '') {
						albumPhoto.loadGraphic(Paths.image('albums/${Std.string(metadata.freeplay.album)}'));
						albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
						albumPhoto.screenCenter(Y);
						albumPhoto.x = 130;
						albumPhoto.y += 20;
					} else {
						albumPhoto.loadGraphic(Paths.image('albums/NoCover'));
						albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
						albumPhoto.screenCenter(Y);
						albumPhoto.x = 130;
						albumPhoto.y += 20;
					}
				}
			} else { // Return to default
				staleBg.makeGraphic(FlxG.width, FlxG.height, 0xff646464);
				staleBg.screenCenter();

				if (albumPhoto != null) {
					albumPhoto.loadGraphic(Paths.image('albums/NoCover'));
					albumPhoto.setGraphicSize(Std.int(albumPhoto.width * 1.6));
					albumPhoto.screenCenter(Y);
					albumPhoto.x = 130;
					albumPhoto.y += 20;
				}
			}
		}
		if(playSound) 
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	public static var vocals:FlxSound = null;

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	override function destroy() {
		super.destroy();
		FlxG.mouse.visible = false;
		instance = null;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			MusicManager.playMenuMusic(1);
	}

	function loadDiffs(song:Dynamic) {
		var week:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[FreeplayManager.songList[curSelected].week]);
		Difficulty.loadFromWeek(week);

		var diffInt:Int = 0;
		for (j in 0...Difficulty.list.length)
		{			
			var songBox:SongBox = new SongBox(320, 100);
			songBox.loadGraphic(Paths.image('OSUState/bars/background2'));
			songBox.setGraphicSize(650, 50);
			songBox.setColorTransform(-1, -1, -1, 1, FreeplayManager.songList[curSelected].color[0][0], FreeplayManager.songList[curSelected].color[0][1], FreeplayManager.songList[curSelected].color[0][2], 1);
			songBox.ID = song.ID + diffInt;
			this.songBox.add(songBox);

			//try {metadata = FreeplayManager.metadata.get(FreeplayManager.songList[i].songName.toLowerCase());}
			//catch(e) {metadata = null;}

			var text:FlxText = new FlxText(0, 0, 500, '', 20);
			text.text = Difficulty.list[j];
			text.alignment = 'left';
			text.ID = song.ID + diffInt;
			this.textGrp.add(text);
		}
	}

	function loadSongArray(reset:Bool, searching:Bool = false, searchQuery:String = '')
	{
		if(reset)
			curSelected = 0;

		songBox.clear();
		iconGrp.clear();
		textGrp.clear();

		var trueInt:Int = 0;

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

			Mods.currentModDirectory = FreeplayManager.songList[i].folder;

			var songBox:SongBox = new SongBox(320, 100);
			songBox.loadGraphic(Paths.image('OSUState/bars/background2'));
			songBox.setGraphicSize(650, 100);
			
			if (APEntryState.inArchipelagoMode) {
				var isBronze:Bool = FlxG.random.bool(50); // Randomly decide between orange and bronze
				var bronzeOrOrangeColor:Int = isBronze ? 0xFFCD7F32 : 0xFFFFA500; // Bronze or Orange color
				songBox.color = FreeplayManager.isVictorySong(songName, modName) ? 
					(isMissing ? 
						(someLocationsNotMissing ? 
							songBox.color = bronzeOrOrangeColor 
							: songBox.color = victoryColor) 
						: songBox.color = 0xFFFFD700) 
					: songBox.color = color;
			} else {
				songBox.setColorTransform(-1, -1, -1, 1, FreeplayManager.songList[i].color[0][0], FreeplayManager.songList[i].color[0][1], FreeplayManager.songList[i].color[0][2], 1);
			}
			songBox.ID = i;
			this.songBox.add(songBox);

			var isLock:Bool = APEntryState.inArchipelagoMode && CategoryState.loadWeekForce == "all" && isMissing && !FreeplayManager.unplayedList.contains(songName);
			var icon:HealthIcon = new HealthIcon(isLock ? "lock" : FreeplayManager.songList[i].songCharacter, false);
			icon.setPosition(320, 100);
			icon.ID = i;
			icon.setGraphicSize(Std.int(icon.width / 1.7), Std.int(icon.height / 1.7));
			iconGrp.add(icon);

			try {metadata = FreeplayManager.metadata.get(FreeplayManager.songList[i].songName.toLowerCase());}
			catch(e) {metadata = null;}

			var text:FlxText = new FlxText(0, 0, 500, '', 20);
			if (metadata != null)
				text.text = FreeplayManager.songList[i].songName + '\nBy ${metadata.song.artist}';
			else
				text.text = FreeplayManager.songList[i].songName + '\nBy Unknown';
			text.alignment = 'left';
			text.ID = i;
			textGrp.add(text);
		}
		
		maxSelected = songBox.length;

		changeSong();
	}

	var trueInt:Int = 0;
	function reloadSongArray()
	{
		songBox.clear();
		iconGrp.clear();
		textGrp.clear();

		trueInt = 0;

		if (APEntryState.inArchipelagoMode) 
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

			Mods.currentModDirectory = FreeplayManager.songList[i].folder;

			var songBox:SongBox = new SongBox(320, 100);
			songBox.loadGraphic(Paths.image('OSUState/bars/background2'));
			songBox.setGraphicSize(650, 100);
			
			if (APEntryState.inArchipelagoMode) {
				var isBronze:Bool = FlxG.random.bool(50); // Randomly decide between orange and bronze
				var bronzeOrOrangeColor:Int = isBronze ? 0xFFCD7F32 : 0xFFFFA500; // Bronze or Orange color
				songBox.color = FreeplayManager.isVictorySong(songName, modName) ? 
					(isMissing ? 
						(someLocationsNotMissing ? 
							songBox.color = bronzeOrOrangeColor 
							: songBox.color = victoryColor) 
						: songBox.color = 0xFFFFD700) 
					: songBox.color = color;
			} else {
				songBox.setColorTransform(-1, -1, -1, 1, FreeplayManager.songList[i].color[0][0], FreeplayManager.songList[i].color[0][1], FreeplayManager.songList[i].color[0][2], 1);
			}
			songBox.ID = i + trueInt;
			this.songBox.add(songBox);

			var isLock:Bool = APEntryState.inArchipelagoMode && CategoryState.loadWeekForce == "all" && isMissing && !FreeplayManager.unplayedList.contains(songName);
			var icon:HealthIcon = new HealthIcon(isLock ? "lock" : FreeplayManager.songList[i].songCharacter, false);
			icon.setPosition(320, 100);
			icon.ID = i + trueInt;
			icon.setGraphicSize(Std.int(icon.width / 1.7), Std.int(icon.height / 1.7));
			iconGrp.add(icon);

			try {metadata = FreeplayManager.metadata.get(FreeplayManager.songList[i].songName.toLowerCase());}
			catch(e) {metadata = null;}

			var text:FlxText = new FlxText(0, 0, 500, '', 20);
			if (metadata != null)
				text.text = FreeplayManager.songList[i].songName + '\nBy ${metadata.song.artist}';
			else
				text.text = FreeplayManager.songList[i].songName + '\nBy Unknown';
			text.alignment = 'left';
			text.ID = i + trueInt;
			textGrp.add(text);

			var week:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[FreeplayManager.songList[i].week]);
			Difficulty.loadFromWeek(week);

			if (FreeplayManager.songList[i].songName == FreeplayManager.songList[curSelected].songName) {
				trace(songName);
				trueInt = i+1;
				for (j in 0...Difficulty.list.length)
				{
					
					var songBox:SongBox = new SongBox(320, 100);
					songBox.loadGraphic(Paths.image('OSUState/bars/background2'));
					songBox.setGraphicSize(650, 100);
					songBox.setColorTransform(-1, -1, -1, 1, FreeplayManager.songList[i].color[0][0], FreeplayManager.songList[i].color[0][1], FreeplayManager.songList[i].color[0][2], 1);
					songBox.ID = trueInt;
					this.songBox.add(songBox);

					var icon:HealthIcon = new HealthIcon(FreeplayManager.songList[i].songCharacter, false);
					icon.setPosition(320, 100);
					icon.ID = trueInt;
					icon.setGraphicSize(Std.int(icon.width / 1.7), Std.int(icon.height / 1.7));
					this.iconGrp.add(icon);

					try {metadata = FreeplayManager.metadata.get(FreeplayManager.songList[i].songName.toLowerCase());}
					catch(e) {metadata = null;}

					var text:FlxText = new FlxText(0, 0, 500, '', 20);
					text.text = FreeplayManager.songList[i].songName + '\n' + Difficulty.list[j];
					text.alignment = 'left';
					text.ID = trueInt;
					this.textGrp.add(text);

					trueInt++;
				}
			} else {
				//trace(FreeplayManager.songList[i].songName);
				//trace(FreeplayManager.songList[curSelected].songName);
			}
		}
		
		maxSelected = songBox.length;

		changeSong();
	}
}