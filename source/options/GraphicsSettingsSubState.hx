package options;

import objects.Character;

var noteOptionID:Int = -1;
// stores the last judgement object
var lastRating:FlxSprite;
// stores the last combo sprite object
var lastCombo:FlxSprite;
// stores the last combo score objects in an array
var lastScore:Array<FlxSprite> = [];
class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool');
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker PCs.", //Description
			'shaders',
			'bool');
		addOption(option);

		var option:Option = new Option('GPU Caching', //Name
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.", //Description
			'cacheOnGPU',
			'bool');
		addOption(option);

		var hudSkins:Array<String> = Mods.mergeAllTextsNamed('images/HUD/list.txt');
		if(hudSkins.length > 0)
		{
			if(!hudSkins.contains(ClientPrefs.data.uiSkin))
				ClientPrefs.data.uiSkin = ClientPrefs.defaultData.uiSkin; //Reset to default if saved noteskin couldnt be found

			hudSkins.insert(0, ClientPrefs.defaultData.uiSkin); //Default skin always comes first
			var option:Option = new Option(
			'Judgement Skin', 
			"What should your judgements look like?", 
			'uiSkin', 
			'string',
			hudSkins);
			addOption(option);
			option.onChange = popUpScore;
			noteOptionID = optionsArray.length - 1;
		}

		var option:Option = new Option(
			'Optimized Holds', 
			"If checked, smooth holds will have fewer calls to the modchart system for position info.\nBest to leave this on, unless you have a high-end PC and require the highest accuracy rendering for, some reason.", 
			'optimizeHolds', 
			'bool'
		);
		addOption(option);
		
		var option:Option = new Option('Hold Subdivisons',
			"How many divisions are in a hold note with smooth holds.\nMore means smoother holds, but more of a performance hit.", 
			'holdSubdivs', 
			'int'
		);
		option.displayFormat = '%v';
		option.changeValue = 1;
		option.minValue = 1;
		option.maxValue = 8;
		addOption(option);

		var option:Option = new Option('Draw Dist. Mult',
			"A multiplier to note's draw distance. Higher number means notes can be seen from further away, less means closer.\nNote that with higher numbers, draw distance is still capped by the spawn distance (which is only modifiable by modcharts) so it's only recommended to lower this value for low-end PCs.\nKEEP IN MIND, ANYTHING PAST X2 IS UNTESTED AND WILL MOST LIKELY BREAK SOMETHING!\nYOU HAVE BEEN WARNED!!!", 
			'drawDistanceModifier', 
			'float');
		option.displayFormat = 'x%v';
		option.decimals = 1;
		option.changeValue = 0.1;
		option.minValue = 0.8;
		option.maxValue = 10;
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int');
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 1;
		option.maxValue = 9999;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		/*
		var option:Option = new Option('Persistent Cached Data',
			'If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
			'imagesPersist',
			'bool',
			false);
		option.onChange = onChangePersistentData; //Persistent Cached Data changes FlxGraphic.defaultPersist
		addOption(option);
		*/

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.globalAntialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.framerate == 1) Achievements.unlock('potato');
		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		if(noteOptionID < 0) return;
		boyfriend.visible = (antialiasingOption == BaseOptionsMenu.curSelected);

	}

	public static function getUiSkin(?uiSkin:String = 'base', ?file:String = '', ?alt:String = '', ?numSkin:Bool = false, ?num:Int = 0)
	{
		var path:String = 'HUD/'
			+ (numSkin ? 'numbers/' : '')
			+ uiSkin
			+ '/'
			+ (numSkin ? 'num' : file)
			+ (numSkin ? Std.string(num) : '')
			+ alt;
		if (!Paths.fileExists('images/' + path + '.png', IMAGE))
			path = 'HUD/'
				+ (numSkin ? 'numbers/' : '')
				+ 'base/'
				+ (numSkin ? 'num' : file)
				+ (numSkin ? Std.string(num) : '')
				+ alt;
		return path;
	}

	function popUpScore():Void
	{
		var combo = FlxG.random.int(0, 1000);
		var placement:String = Std.string(combo);
		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		/*var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}*/

		var uiSkin:String = '';
		var altPart:String = '';

		switch (ClientPrefs.data.uiSkin)
		{
			case 'Bedrock':
				uiSkin = 'bedrock';
			case 'BEAT!':
				uiSkin = 'beat';
			case 'BEAT! Gradient':
				uiSkin = 'beat-alt';
			case 'Psych Engine':
				uiSkin = 'psych';
			case 'Mixtape Engine':
				uiSkin = 'mixtape';
			case 'Base Game':
				uiSkin = 'base';
			default:
				uiSkin = ClientPrefs.data.uiSkin;
		}

		var randoRating = ['marv', 'sick', 'good', 'bad', 'shit'];

		rating.loadGraphic(Paths.image(getUiSkin(uiSkin, randoRating[FlxG.random.int(0,4)], altPart)));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.data.hideHud);
		//rating.x += ClientPrefs.data.comboOffset[0];
		//rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(getUiSkin(uiSkin, 'combo', altPart)));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300);
		comboSpr.velocity.y -= FlxG.random.int(140, 160);
		comboSpr.visible = (!ClientPrefs.data.hideHud);
		//comboSpr.x += ClientPrefs.data.comboOffset[0];
		//comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		add(rating);
		
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		rating.setGraphicSize(Std.int(rating.width * 0.85));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.85));

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 1000) % 10);
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		add(comboSpr);
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(getUiSkin(uiSkin, '', altPart, true, Std.int(i))));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			
			if (!ClientPrefs.data.comboStacking)
				lastScore.push(numScore);

			numScore.setGraphicSize(Std.int(numScore.width));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.data.hideHud;

			//if (combo >= 10 || combo == 0)
			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 5, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				}
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
			trace(combo);
			trace(seperatedScore);
			*/

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0, angle: FlxG.random.float(-15, 15)}, 5);

		FlxTween.tween(comboSpr, {alpha: 0, angle: FlxG.random.float(-15, 15)}, 5, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			}
		});
	}

	override function update(e:Float)
	{
		super.update(e);
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});
	}
}