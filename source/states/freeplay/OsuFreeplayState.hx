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

	override function create()
	{
		instance = this; // For Archipelago
		
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

		super.create();
	}

	var holdTime:Float = 0;
	override public function update(elapsed:Float)
	{
		FlxG.watch.addQuick('Search Text', searchTypeText.text);

		for(item in songBox)
		{
			var coolEffect:Int = 0;

			if(item.ID < curSelected)
				coolEffect = ((item.ID - curSelected) * 30);
			else if (item.ID > curSelected)
				coolEffect = -((item.ID - curSelected) * 30);

			item.x = FlxMath.lerp(item.ID == curSelected? 280 : 320 - coolEffect, item.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		}

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
				inSub = true;
				openSubState(new DifficultySelectorSubState(FreeplayManager.songList[curSelected]));
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
					loadSongArray(true, false);
				}
				else
					loadSongArray(true, true, searchTypeText.text);
			}
		}

		super.update(elapsed);
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
			try {Difficulty.loadFromWeek();} catch(e:Dynamic) {}
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
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
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
		FlxG.mouse.visible = false;
	}

	function loadSongArray(reset:Bool, searching:Bool = false, searchQuery:String = '')
	{
		if(reset)
			curSelected = 0;

		//run this 100 times cause running once only removes half of the items in the group!!??
		for(i in 0...100)
		{
			if(songBox.length != 0)
			{
				songBox.forEach(function(box:SongBox)
				{
					songBox.remove(box, true);
					box.kill();
					box.destroy();
				});

				for(icon in iconGrp) {
					iconGrp.remove(icon, true);
					icon.kill();
					icon.destroy();
				}

				for(text in textGrp) {
					textGrp.remove(text, true);
					text.kill();
					text.destroy();
				}
			}
		}

		for (i in 0...FreeplayManager.songList.length)
		{

			var songBox:SongBox = new SongBox(320, 100);
			songBox.loadGraphic(Paths.image('OSUState/bars/background2'));
			songBox.setGraphicSize(650, 100);
			songBox.setColorTransform(-1, -1, -1, 1, FreeplayManager.songList[i].color[0][0], FreeplayManager.songList[i].color[0][1], FreeplayManager.songList[i].color[0][2], 1);
			songBox.ID = i;
			this.songBox.add(songBox);

			var icon:HealthIcon = new HealthIcon(FreeplayManager.songList[i].songCharacter, false);
			icon.setPosition(320, 100);
			icon.ID = i;
			icon.setGraphicSize(Std.int(icon.width / 1.7), Std.int(icon.height / 1.7));
			this.iconGrp.add(icon);

			try {metadata = FreeplayManager.metadata.get(FreeplayManager.songList[i].songName.toLowerCase());}
			catch(e) {metadata = null;}

			var text:FlxText = new FlxText(0, 0, 500, '', 20);
			if (metadata != null)
				text.text = FreeplayManager.songList[i].songName + '\nBy ${metadata.song.artist}';
			else
				text.text = FreeplayManager.songList[i].songName + '\nBy Unknown';
			text.alignment = 'left';
			text.ID = i;
			this.textGrp.add(text);
		}
		
		maxSelected = songBox.length;

		changeSong();
	}
}