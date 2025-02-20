package states;

import flixel.addons.ui.FlxUIInputText;
import flash.events.KeyboardEvent;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flash.events.Event;
import flash.events.MouseEvent;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import Sys;
import backend.Achievements;
import backend.Highscore;
import objects.VideoSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
class CodeState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var codeInput:FlxUIInputText;
	var codeCheck:FlxButton;
	var curCode:Int = 0;
	var curVid:Int = 0;
	var checkingcode:Bool = false;
	var codelist:Array<String> = [];
	var songcodelist:Array<String> = [];
	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	public static var blackscreen:FlxSprite;
	var bg:FlxSprite;
	public var whatvideo:Bool = false;
	//Once Again, Thanks Mic'ed Up, Much Appreceated. (I bet you i spelt that wrong lol)
	var rankTable:Array<String> = [
		'P-small', 'X-small', 'X--small', 'SS+-small', 'SS-small', 'SS--small', 'S+-small', 'S-small', 'S--small', 'A+-small', 'A-small', 'A--small',
		'B-small', 'C-small', 'D-small', 'E-small', 'NA'
	];
	var rank:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('rankings/NA'));
	var debug:Bool;
	var rave:FlxTypedGroup<FlxSprite>;
	var ravemode:Bool = false;
	var curLight:Int = 0;
	var trueSongName:String;
	
	override function create()
	{	
		whatvideo = false;
		checkingcode = false;
		#if debug
		debug = true;
		#else
		debug = false;
		#end
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		//bg.color = FlxColor.BLACK;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.color = FlxColor.BLACK;
		add(bg);

		blackscreen = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackscreen.updateHitbox();
		blackscreen.screenCenter();
		blackscreen.antialiasing = true;
		blackscreen.scrollFactor.set(0, 0);
		blackscreen.alpha = 0;
		blackscreen.setGraphicSize(Std.int(blackscreen.width * 10.5));
		blackscreen.color = FlxColor.BLACK;

		codeInput = new FlxUIInputText(0, 0, 500, '', 20);
		codeInput.screenCenter(XY);
		codeInput.color = FlxColor.BLACK;
		add(codeInput);
		blockPressWhileTypingOn.push(codeInput);

		FlxG.mouse.visible = true;
		codeCheck = new FlxButton(codeInput.x, codeInput.y - 30, 'Submit', function()
		{
			checkCode();
		});
		add(codeCheck);
		rank.scale.x = rank.scale.y = 80 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = true;
		rank.scrollFactor.set();
		rank.y = 690 - rank.height;
		rank.x = -200 + FlxG.width - 50;
		add(rank);
		rank.antialiasing = true;

		if (FlxG.sound.music.playing)
			FlxG.sound.music.fadeOut(1, 0);

		//rank.alpha = 0;
		super.create();
		rave = new FlxTypedGroup<FlxSprite>();
		add(rave);
		for (i in 0...8)
		{
			var light2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('rave/ravelight' + i, 'rave'));
			light2.scrollFactor.set(0, 0);
			//light2.cameras = [FlxG.camera];
			light2.visible = false;
			light2.updateHitbox();
			light2.antialiasing = true;
			rave.add(light2);
		}
		add(blackscreen);
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			var cutscene:VideoSprite = new VideoSprite(fileName, forMidSong, canSkip, loop);

			// Finish callback
			cutscene.finishCallback = function()
			{
				return;
			};

			// Skip callback
			cutscene.onSkip = function()
			{
				return;
			};
			add(cutscene);

			if (playOnLoad)
				cutscene.videoSprite.play();
			return cutscene;
		}
		else FlxG.log.error("Video not found: " + fileName);
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	public static function nowWhat():Void
	{
		if (codeInput.text == 'jumpscare')
		{
			Sys.exit(0);
		}
		else
		{
			codeInput.text = '';
			FlxTween.tween(blackscreen, {alpha: 0}, 2, {ease: FlxEase.expoIn});
			FlxG.sound.playMusic(Paths.music('panixPress'));	
		}
	}

	override function update(elapsed:Float)
	{
		if (codeInput.text == 'jumpscare')
		{
			FlxG.sound.music.volume = 0;
		}
		else if (!whatvideo)
		{
			FlxG.sound.music.volume = 1;
		}
		if (blackscreen.alpha == 1 && !whatvideo && codeInput.text != 'jumpscare')
		{
			FlxTween.tween(blackscreen, {alpha: 0}, 4, {ease: FlxEase.expoIn});
			//FlxTween.tween(rank, {alpha: 0}, 0.5, {ease: FlxEase.quartInOut});
			checkingcode = false;
			FlxG.sound.music.volume = 1;
		}
		var blockInput:Bool = false;
		if (!blockInput || codeInput.text == '' || codeInput.text == null)
		{
			if (FlxG.keys.pressed.SHIFT && controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				FlxTween.tween(FlxG.camera, {zoom: 5}, 0.8, {ease: FlxEase.expoIn});
				//FlxTween.tween(bg, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
				FlxTween.tween(codeInput, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
				//FlxTween.tween(bg, {alpha: 0}, 0.8, {ease: FlxEase.expoIn});
				FlxTween.tween(codeInput, {alpha: 0}, 0.8, {ease: FlxEase.expoIn});
				//FlxTween.tween(rank, {alpha: 0}, 0.5, {ease: FlxEase.quartInOut});
				//FlxTween.tween(codeCheck, {angle: -45}, 0.8, {ease: FlxEase.expoIn});
				//FlxTween.tween(codeCheck, {alpha: 0}, 0.8, {ease: FlxEase.expoIn});	
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
			codeInput.hasFocus = false;
		}
		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
			else 
			{
				FlxG.sound.muteKeys = muteKeys;
				FlxG.sound.volumeDownKeys = volumeDownKeys;
				FlxG.sound.volumeUpKeys = volumeUpKeys;
				FlxG.keys.preventDefaultKeys = [TAB];
				blockInput = false;
				break;
			}
		}
		super.update(elapsed);
		switch (codeInput.text.toLowerCase())
		{
			default:
				trueSongName = codeInput.text.toLowerCase();
		}
		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(trueSongName, 4)]));
		rank.scale.x = rank.scale.y = 80 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = true;
		rank.scrollFactor.set();
		rank.y = 690 - rank.height;
		rank.x = -200 + FlxG.width - 50;
		if (FlxG.keys.justPressed.ENTER)
			checkCode();

		for (i in songcodelist)
		{
			if (codeInput.text == i)
			{
				FlxTween.tween(rank, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});
			}
			else {
				FlxTween.tween(rank, {alpha: 0}, 0.5, {ease: FlxEase.quartInOut});
			}
		}
	}

	/*function playstate() 
	{
		if (ClientPrefs.charSelect && !Main.godmode && !ClientPrefs.ostmode){
			trace(PlayState.SONG.song.toLowerCase());
			MusicBeatState.switchState(new CharMenu());
		}else{
			//MusicBeatState.switchState(new TrialsLoader());
			trace(PlayState.SONG.song.toLowerCase());
			openSubState(new DiffSubState());
		}
	}*/

	// public static function doCode(code:String):Void
	// {
	// 	codeInput.text = code;
	// 	checkCode();
	// }

	function checkCode():Void
	{
		FlxTween.tween(blackscreen, {alpha: 1}, 1, {ease: FlxEase.expoIn});
		if (!checkingcode)
		{
			if (codeInput.text == 'jumpscare')
			{
				blackscreen.alpha = 1;
			}
			else 
			{
				checkingcode = true;
				FlxTween.tween(blackscreen, {alpha: 1}, 1, {ease: FlxEase.expoIn});
			}
			new FlxTimer().start(1.5, function(tmr:FlxTimer) 
			{
				if (codeInput.text == 'jumpscare')
				{
					blackscreen.alpha = 1;
				}
			});
		}
		else 
		{
			lime.app.Application.current.window.alert('You Already Presssed It.', 'HEY, BOZO!');
			checkingcode = false;
		}
		if (codeInput.text == 'test')
			Sys.print('Ayo Idiot. It Works.');
		/*if(codeInput.text=="roast me"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				playCutscene('RatioBozo');	
				whatvideo = true;
				FlxG.sound.music.volume = 0;	
			});
		}
		if(codeInput.text=="mark"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video001');
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="milk"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video000');	
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="ip"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('sussy videos/FullSizeRender_2');
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="deez"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('sussy videos/video0-63');
					////videocodelist[4] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="battery"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('sussy videos/Videoleap-0388A819-545F-45BD-804E-02F362FC5979');
					//////videocodelist[5] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="4k"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('4k_1-1');	
					//////videocodelist[6] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="2d minecraft"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('5c8bc95f2b12c94bba353db29dd45e4a');
					//////videocodelist[7] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="welp"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('Dad_I_can_explain');
					//////videocodelist[8] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="did u hear"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('did_you_hear');	
					//////videocodelist[9] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="anided"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('Dog_shot');//fixed	
					//////videocodelist[10] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="huggy"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('hug');	
					//////videocodelist[11] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="dark edu"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('IMG_2061');//fixed	
					//////videocodelist[12] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="bro thats fire"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('M_8WEDxGTZ_V-SWP');
					//////videocodelist[13] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="tiky"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('man_but_hes-');	
					//////videocodelist[14] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="matt"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('matts_fucking_pissed-1');
					//////videocodelist[15] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="noone cares"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('no_one_gives_a_flying_fuck');
					//////videocodelist[16] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="rest"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('rest_here');	
					//////videocodelist[17] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="bye bye"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('say_goodbye');	
					//////videocodelist[18] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="stfu"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('Stfu');	
					//////videocodelist[19] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="dastick"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('talking_stick');	
					//////videocodelist[20] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="cant write"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('Terry-Vanegood_20210708_2');
					//////videocodelist[21] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="dasauce"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('The_sauce_sir');	
					////videocodelist[22] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="jumpscare"){
			////videocodelist[23] = true;
			switch FlxG.random.int(1, 6)
			{
				case 1:
					playCutscene('tjoc');
				case 2:
					playCutscene('ohlawd');
				case 3:
					playCutscene('boo');
				case 4:
					playCutscene('trim.61ABEAF6-8A9D-4AFB-B1C7-F3618B8741FA');
				case 5:
					playCutscene('671562870_278139223_402287191330816_2662421225296320148_n-8');
				case 6:
					playCutscene('redditsave.com_no_maidens-gzwgyug3s1z81-220');
			}		
			whatvideo = true;
			FlxG.sound.music.volume = 0;
		}
		if(codeInput.text=="kaboom"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('VID_20211111_172516_5781');
					////videocodelist[24] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="die anime"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_1 (1)');	
					////videocodelist[25] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="jojo reference"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_3');	
					////videocodelist[26] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="soder"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_4');//fixed	
					////videocodelist[27] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="pika"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_5');	
					////videocodelist[28] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="kfc"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_6');	//fixed
					////videocodelist[29] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="thighs"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_7');//fixed	
					////videocodelist[30] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="vaperohno"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_8');	
					////videocodelist[31] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="stay away"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0_12');	
					////videocodelist[32] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="ping"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0-2-2');	//fixed
					////videocodelist[33] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="giga chad"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0-10');	
					////videocodelist[34] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="magi"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0-23-1');	
					////videocodelist[35] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="cloaker"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0-33');	//fixed
					////videocodelist[36] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="whit"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0-51-1');	
					////videocodelist[37] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="snas"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video1');	
					////videocodelist[38] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="knight"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video3');	//fixed
					////videocodelist[39] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="booba"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('sussy videos/really sus/video0_1');
					////videocodelist[40] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="good morning"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('yt1s.com_-_Beautiful_Morning_Pops_Regular_Show');
					////videocodelist[41] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="flip"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('yt1s.com_-_JOJO_FLIP');
					////videocodelist[42] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="vocoded"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('FNAF_Beatbox_But_its_Vocoded_to_Gangstas_Paradise');
					////videocodelist[43] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="skill issue"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('video0-15');	
					////videocodelist[44] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;	
				});
			});
		}
		if(codeInput.text=="imma head out"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('Aight_Imma_head_out_Jesus_version');
					////videocodelist[45] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="now now now"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('RPReplay_Final1643434737');
					////videocodelist[46] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="sure it was"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('ezgif-5-63ff8e3690');
					////videocodelist[47] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="mattpatt"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('videoplayback (2)');
					////videocodelist[47] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="mattpatt2.0"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('videoplayback (1)');
					////videocodelist[47] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="mattpatt3.0"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					playCutscene('food');
					////videocodelist[47] = true;
					whatvideo = true;
					FlxG.sound.music.volume = 0;		
				});
			});
		}
		if(codeInput.text=="danger"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('danger-true', 'danger');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					CharMenu.diffallow = true;
					playstate();
				});
			});
		}
		if(codeInput.text=="forgotten"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('forgotten-hard', 'forgotten');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="thunderstorm"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					if (Main.godmode)
						PlayState.SONG = Song.loadFromJson('thunderstorm-god', 'thunderstorm');
					else
						PlayState.SONG = Song.loadFromJson('thunderstorm-hard', 'thunderstorm');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="termination"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSp riteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					if (Main.godmode)
						PlayState.SONG = Song.loadFromJson('termination-god', 'termination');
					else
						PlayState.SONG = Song.loadFromJson('termination-hard', 'termination');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="left ungined"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('left-ungined-gin', 'left-ungined');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="double up"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					if (Main.godmode)
						PlayState.SONG = Song.loadFromJson('double-up-god', 'double-up');
					else
						PlayState.SONG = Song.loadFromJson('double-up-Z11', 'double-up');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = false;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="expurgation"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('expurgation-true', 'expurgation');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="final destination"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('final-destination-true', 'final-destination');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = false;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="lights out"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('lights-out', 'lights-out');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="pixel gallery"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('pixel-gallery-pain', 'pixel-gallery');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="power trip"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('power-trip', 'power-trip');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="purgatory"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					switch FlxG.random.int(1, 3)
					{
						case 1:
							PlayState.SONG = Song.loadFromJson('purgatory-true', 'purgatory');
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = 4;
							PlayState.songMisses = 0;
							PlayState.marvelouses = 0;
							PlayState.sicks = 0;
							PlayState.goods = 0;
							PlayState.bads = 0;
							PlayState.shits = 0;
							PlayState.ratingPercent = 1;
							PlayState.campaignScore = 0;
							PlayState.isCode = true;
							CharMenu.bfOnly = true;
							trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
							trace('True Purg');
							playstate();
						case 2:
							PlayState.SONG = Song.loadFromJson('purgatory-wither', 'purgatory');
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = 4;
							PlayState.songMisses = 0;
							PlayState.marvelouses = 0;
							PlayState.sicks = 0;
							PlayState.goods = 0;
							PlayState.bads = 0;
							PlayState.shits = 0;
							PlayState.ratingPercent = 1;
							PlayState.campaignScore = 0;
							PlayState.isCode = true;
							CharMenu.bfOnly = true;
							trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
							trace("Wither's Purg");
							playstate();
						case 3:
							PlayState.SONG = Song.loadFromJson('purgatory-brayden', 'purgatory-alt');
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = 4;
							PlayState.songMisses = 0;
							PlayState.marvelouses = 0;
							PlayState.sicks = 0;
							PlayState.goods = 0;
							PlayState.bads = 0;
							PlayState.shits = 0;
							PlayState.ratingPercent = 1;
							PlayState.campaignScore = 0;
							PlayState.isCode = true;
							CharMenu.bfOnly = true;
							trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
							trace("Brayden's Purg");
							playstate();
					}	
				});
			});
		}
		if(codeInput.text=="replica"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('replica-pain', 'replica');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfsOnly = true;
					CoolUtil.difficulties = ['hard', 'pain', '9k'];
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="die magi"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('die-magi', 'die-magi');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="pyoro BETADCIU"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('pyoro-BETADCIU-hard', 'pyoro-BETADCIU');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="dreamy sky"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('dreamy-sky-lullaby', 'dreamy-sky');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.ginAllowed = false;
					CharMenu.bfOnly = false;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="reality breaker"){
			breakEverything();
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('reality-breaker-hard', 'reality-breaker');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="smokey rumble"){
			breakEverything();
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('smokey-rumble', 'smokey-rumble');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="bombastic"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('bombastic-master', 'bombastic');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="spectral spat"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('spectral-spat-hard', 'spectral-spat');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="power and worlds end"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('color-and-electricity-hard', 'color-and-electricity');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="nope"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('nope-hard', 'nope');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="endurance"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('endurance-true', 'endurance');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="gamer room"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('gamer-room', 'gamer-room');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="void trap"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('void-trap', 'secret');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="tex"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('tex', 'tex');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = false;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="corrupted god"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('Corrupted-Hero-hard', 'Corrupted-Hero');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="taste for power"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('taste-for-blood', 'taste-for-blood');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = false;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="nomthatdicc"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('nom-that-dicc-hard', 'nom-that-dicc');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					PlayState.specialDeath = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="nomthatdrip"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('nom-that-drip-hard', 'nom-that-drip');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					PlayState.specialDeath = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="!join party"){
			breakEverything();
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('stag-party-hard', 'stag-party');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="platform 9"){
			breakEverything();
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('platform-9-hard', 'platform-9');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="paralysis"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('paralysis', 'paralysis');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="hurricane"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('hurricane', 'hurricane');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="galaxy"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('galaxy-hard', 'galaxy');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}
		if(codeInput.text=="game"){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			
				//resetSpriteCache = true;
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					PlayState.SONG = Song.loadFromJson('game-hard', 'game');
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					PlayState.songMisses = 0;
					PlayState.marvelouses = 0;
					PlayState.sicks = 0;
					PlayState.goods = 0;
					PlayState.bads = 0;
					PlayState.shits = 0;
					PlayState.ratingPercent = 1;
					PlayState.campaignScore = 0;
					PlayState.isCode = true;
					CharMenu.bfOnly = true;
					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					playstate();
				});
			});
		}*/
		if(codeInput.text=="" && ClientPrefs.data.gotit || codeInput.text==" " && ClientPrefs.data.gotit || codeInput.text== null && ClientPrefs.data.gotit || codeInput.text=="" && debug){
			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				
				//resetSpriteCache = true;
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer) 
				{
					RPGState.area = "SaveM";
					if (ClientPrefs.data.progression == 0)
						ClientPrefs.data.progression = 1;
					RPGState.triggerMusic = true;
					MusicBeatState.switchState(new RPGState());
				});
			});
		}
	}

	function breakEverything()
	{
		FlxG.sound.play(Paths.sound('undSnap'));
		FlxG.sound.play(Paths.sound('snap'));
		FlxTween.tween(bg, {y: 1000, angle: 180}, 1, {ease: FlxEase.expoIn});
		FlxTween.tween(blackscreen, {y: -1000, angle: -180}, 1, {ease: FlxEase.expoIn});
		FlxTween.tween(codeInput, {y: 1000, angle: 180}, 1, {ease: FlxEase.expoIn});
		FlxTween.tween(codeCheck, {y: 1000, angle: -180}, 1, {ease: FlxEase.expoIn});
	}

	override function beatHit()
	{
		super.beatHit();
		if (ravemode && curBeat % 1 == 0 && ClientPrefs.data.flashing)
		{
			if (ClientPrefs.data.flashing) {
				rave.forEach(function(light2:FlxSprite)
				{
					light2.visible = false;
				});

				curLight++;
				if (curLight > rave.length - 1)
					curLight = 0;

				rave.members[curLight].visible = true;
				rave.members[curLight].alpha = 1;
				FlxTween.tween(rave.members[curLight], {alpha: 0}, 0.3, {
				});

			}
			FlxG.camera.zoom += 0.030;
		}
		else
		{
			rave.members[curLight].visible = false;
			rave.members[curLight].alpha = 0;
		}
	}
}
