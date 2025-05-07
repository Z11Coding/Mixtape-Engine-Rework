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

class OsuFreeplayState extends MusicBeatState
{
	public static var instance:OsuFreeplayState;

	var songs:Array<SongShit> = [];

	var back:FlxSprite;
	var backHitbox:FlxSprite;
	var fakeLogo:FlxSprite;

	var searchTypeText:FlxText;
	var searchTypeTextHitbox:FlxSprite;

	var isTyping:Bool = false;

	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

	var background:FlxSprite;

	private var songBox:FlxTypedGroup<SongBox>;
	private var iconGrp:FlxTypedGroup<HealthIcon>;
	private var textGrp:FlxTypedGroup<FlxText>;

	private static var curSelected:Int = 0;
	private static var maxSelected:Int = 0;

	public static var inSub:Bool = false;

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

		var staleBg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff646464);
		add(staleBg);

		songBox = new FlxTypedGroup<SongBox>();
		add(songBox);
		
		textGrp = new FlxTypedGroup<FlxText>();
		add(textGrp);

		iconGrp = new FlxTypedGroup<HealthIcon>();
		add(iconGrp);

		loadSongArray(false);

		var topBar:FlxSprite = new FlxSprite(0, -87).loadGraphic(Paths.image('OSUState/barTop'));
		topBar.setGraphicSize(1280, 152);
		topBar.screenCenter(X);
		add(topBar);

		var botBar:FlxSprite = new FlxSprite(0, 537).loadGraphic(Paths.image('OSUState/barbot'));
		botBar.setGraphicSize(1280, 119);
		botBar.screenCenter(X);
		add(botBar);
		
		var logo:FlxSprite = new FlxSprite(0, 460).loadGraphic(Paths.image('OSUState/logo'));
		logo.setGraphicSize(200, 100);
		logo.screenCenter(X);
		add(logo);
		
		fakeLogo = new FlxSprite(0, 460).loadGraphic(Paths.image('OSUState/logo'));
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

		// logoTween();

		changeSong();

		super.create();
	}

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
			
			if(controls.UI_UP_P || controls.UI_DOWN_P)
				changeSong(controls.UI_UP_P? -1 : 1);
			else if(FlxG.keys.justPressed.HOME)
			{
				curSelected = 0;

				changeSong();
			}
			else if(FlxG.keys.justPressed.END)
			{
				curSelected = maxSelected - 1;

				changeSong();
			}
			else if(FlxG.keys.justPressed.PAGEUP || FlxG.keys.justPressed.PAGEDOWN)
				changeSong(FlxG.keys.justPressed.PAGEUP? -6 : 6);
			
			if(controls.ACCEPT)
			{
				inSub = true;
				Mods.currentModDirectory = songs[curSelected].folder;
				PlayState.storyWeek = songs[curSelected].week;
				Difficulty.loadFromWeek();
				openSubState(new DifficultySelectorSubState(songs[curSelected]));
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

	function logoTween()
	{
		fakeLogo.alpha = 1;

		FlxTween.tween(fakeLogo, {alpha: 0}, 0.6);
		FlxTween.tween(fakeLogo.scale, {x: 0.33, y: 0.33}, 0.6);
	}

	function changeSong(change:Int = 0)
	{
		curSelected += change;

		if(curSelected > maxSelected - 1)
			curSelected = 0;
		if(curSelected < 0)
			curSelected = maxSelected - 1;

		var i:Int = 0;
		for(item in songBox)
			item.posY = i++ - curSelected;

		if (songs[curSelected] != null)
		{
			Mods.currentModDirectory = songs[curSelected].folder;
			PlayState.storyWeek = songs[curSelected].week;
			try {Difficulty.loadFromWeek();} catch(e:Dynamic) {}
		}
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

		songs = [];

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

		for (i in 0...WeekData.weeksList.length) {

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];

			if(leWeek.hideFreeplay) continue;

			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
					colors = [146, 113, 253];

				var musician:String = 'unknown';
				if (FileSystem.exists(Paths.json(song[0].toLowerCase() + "/credits")))
					musician = File.getContent((Paths.json(song[0].toLowerCase() + "/credits")));

				if(searching)
				{
					var songSearch:String = song[0].toLowerCase();

					if(songSearch.contains(searchQuery.toLowerCase()))
						songs.push(new SongShit(song[0], song[1], musician, [colors], i));
				}
				else
					songs.push(new SongShit(song[0], song[1], musician, [colors], i));
			}
		}

		for (i in 0...songs.length)
		{
			var songBox:SongBox = new SongBox(320, 100);
			songBox.loadGraphic(Paths.image('OSUState/bars/background2'));
			songBox.setGraphicSize(650, 100);
			songBox.setColorTransform(-1, -1, -1, 1, songs[i].color[0][0], songs[i].color[0][1], songs[i].color[0][2], 1);
			songBox.ID = i;
			this.songBox.add(songBox);

			var icon:HealthIcon = new HealthIcon(songs[i].healthIcon, false);
			icon.setPosition(320, 100);
			icon.ID = i;
			icon.setGraphicSize(Std.int(icon.width / 1.7), Std.int(icon.height / 1.7));
			this.iconGrp.add(icon);

			var text:FlxText = new FlxText(0, 0, 500, '', 20);
			text.text = songs[i].songName + "\n" + songs[i].credits;
			text.alignment = 'left';
			text.ID = i;
			this.textGrp.add(text);
		}
		
		maxSelected = songBox.length;

		changeSong();
	}
}

class SongShit 
{
	public var songName:String = '';
	public var healthIcon:String = '';
	public var credits:String = '';
	public var color:Array<Array<Int>> = [];
	public var folder:String = "";
	public var week:Int = 0;

	public function new(songName:String, healthIcon:String, credits:String, color:Array<Array<Int>>, week:Int)
	{
		this.songName = songName;
		this.healthIcon = healthIcon;
		this.credits = credits;
		this.color = color;
		this.week = week;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}