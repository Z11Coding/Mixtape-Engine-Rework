package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;

using StringTools;

class CrossFadeSettingsSubState extends MusicBeatSubstate
{
	var boyfriend:Boyfriend;
	var crossfade:Boyfriend;
	var selectedOption:Int = 0;
	var selectedVertical:Int = 0;
	var lastOption:Int = 0; //we use this one so you can scroll inside the suboptions without scrolling the entire thing
	var crossfadeTween:FlxTween = null;
	var split:Bool = false;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpAttached:FlxTypedGroup<AttachedText>;
	final optionsShit:Map<String, Array<String>> = [
		'Mode' => ['Default', 'Static', 'Subtle', 'Eccentric', 'Off'],
		'Color' => ['Healthbar', 'RGB', 'HSB']
	];
	public function new()
	{
		super();

		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.screenCenter();
		add(bg);

		var bgScroll:FlxBackdrop = null;
		var bgScroll2:FlxBackdrop = null;
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('checker'));
			bgScroll.velocity.set(29, 30);
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('checker'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll2);
		}

		boyfriend = new Boyfriend(0, 0);
		add(boyfriend);
		resetBoyfriend();

		crossfade = new Boyfriend(boyfriend.x, boyfriend.y);
		insert(members.indexOf(boyfriend) - 1, crossfade);
		resetCrossfade();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpAttached = new FlxTypedGroup<AttachedText>();
		add(grpAttached);
		for (i=>name in ['Mode', /*'Color',*/ 'Alpha', 'Fade Time'])
		{
			var alphabet = new Alphabet(0, 500, name, true, false, 0.05, 1);
			alphabet.x = FlxG.width/2 - alphabet.width/2;
			alphabet.ID = i;
			alphabet.align = 'none';
			alphabet.targetY = 1.15;
			grpOptions.add(alphabet);
			switch (name) {
				case 'Mode':
					var attached = new AttachedText(ClientPrefs.crossFadeData[0], 0, 30, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);
				/*case 'Color':
					var attached = new AttachedText(ClientPrefs.crossFadeData[1], 0, 20, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);

					var attached = new AttachedText('Red: ' + ClientPrefs.crossFadeData[2][0], 0, 70, false, 0.7);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.alignAdd = -350;
					attached.targetY = 2;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);

					var attached = new AttachedText('Green: ' + ClientPrefs.crossFadeData[2][1], 0, 70, false, 0.7);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 2;
					attached.ID = 1;
					attached.yMult = i;
					grpAttached.add(attached);

					var attached = new AttachedText('Blue: ' + ClientPrefs.crossFadeData[2][2], 0, 70, false, 0.7);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.alignAdd = 350;
					attached.targetY = 2;
					attached.ID = 2;
					attached.yMult = i;
					grpAttached.add(attached);*/
				case 'Alpha':
					var attached = new AttachedText(ClientPrefs.crossFadeData[3], 0, 30, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);
				case 'Fade Time':
					var attached = new AttachedText(ClientPrefs.crossFadeData[4], 0, 30, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);
			}
		}
		updateRGBTexts();

		var titleText:FlxText = new FlxText(0, 20, 0, "Crossfade", 24);
		titleText.setFormat(Paths.font("calibri-regular.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xff59136d);
		titleText.x += 14;
		titleText.y -= 3;

		var titleBG:FlxSprite = new FlxSprite(0,30).loadGraphic(Paths.image('oscillators/optionsbg'));
		titleBG.setGraphicSize(Std.int(titleText.width*1.225), Std.int(titleText.height/1.26));
		titleBG.updateHitbox();
		add(titleBG);
		add(titleText);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
	}