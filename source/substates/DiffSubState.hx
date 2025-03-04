package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import backend.Song;
import backend.Highscore;

class DiffSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	public static var songChoices = [];
	public static var listChoices = [];
	var curSelected:Int = 0;

	var pausebg:FlxSprite;
	var pausebg1:FlxSprite;
	var iconBG:FlxSprite;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var selector:FlxText;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var rankTable:Array<String> = [
		'P-small', 'X-small', 'X--small', 'SS+-small', 'SS-small', 'SS--small', 'S+-small', 'S-small', 'S--small', 'A+-small', 'A-small', 'A--small',
		'B-small', 'C-small', 'D-small', 'E-small', 'NA'
	];
	var rank:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('rankings/NA'));

	public function new()
	{
		super();
		if (PlayState.instance != null)
			PlayState.instance.paused = true;

		if (!listChoices.contains('BACK'))
		{
			listChoices.push('BACK');
			songChoices.push('BACK');
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		if (!ClientPrefs.data.lowQuality)
		{
			pausebg = new FlxSprite().loadGraphic(Paths.image('pause/pausemenubg'));
			pausebg.color = 0xFF1E1E1E;
			pausebg.scrollFactor.set();
			pausebg.updateHitbox();
			pausebg.screenCenter();
			pausebg.antialiasing = ClientPrefs.data.antialiasing;
			add(pausebg);
			pausebg.x += 200;
			pausebg.y -= 200;
			pausebg.alpha = 0;
			FlxTween.tween(pausebg, {
				x: 0,
				y: 0,
				alpha: 1
			}, 1, {ease: FlxEase.quadOut});

			pausebg1 = new FlxSprite().loadGraphic(Paths.image('pause/iconbackground'));
			pausebg1.color = 0xFF141414;
			pausebg1.scrollFactor.set();
			pausebg1.updateHitbox();
			pausebg1.screenCenter();
			pausebg1.antialiasing = ClientPrefs.data.antialiasing;
			add(pausebg1);
			pausebg1.x -= 150;
			pausebg1.y += 150;
			pausebg1.alpha = 0;
			FlxTween.tween(pausebg1, {
				x: 0,
				y: 0,
				alpha: 1
			}, 0.9, {ease: FlxEase.quadOut});

			iconBG = new FlxSprite().loadGraphic(Paths.image('pause/iconbackground'));
			iconBG.flipX = true;
			iconBG.scrollFactor.set();
			iconBG.updateHitbox();
			iconBG.screenCenter();
			iconBG.antialiasing = ClientPrefs.data.antialiasing;
			add(iconBG);
			iconBG.x += 100;
			iconBG.y += 100;
			iconBG.alpha = 0;
			FlxTween.tween(iconBG, {
				x: 0,
				y: 0,
				alpha: 1
			}, 0.8, {ease: FlxEase.quadOut});
		}

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...listChoices.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, listChoices[i], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

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

		lerpSelected = curSelected;
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		FlxTween.tween(rank, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});

		states.FreeplayState.doChange = true;

		changeSelection();
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

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

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(FlxG.keys.justPressed.HOME)
		{
			curSelected = 0;
			changeSelection();
			holdTime = 0;
		}
		else if(FlxG.keys.justPressed.END)
		{
			curSelected = songChoices.length - 1;
			changeSelection();
			holdTime = 0;
		}
		if (controls.UI_UP_P)
		{
			changeSelection(-shiftMult);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(shiftMult);
			holdTime = 0;
		}

		if(controls.UI_DOWN || controls.UI_UP)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
		}

		if(FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
			changeSelection(-shiftMult * FlxG.mouse.wheel, false);
		}

		if (controls.UI_LEFT_P) changeDiff(-1);
		else if (controls.UI_RIGHT_P) changeDiff(1);

		var daSelected:String = songChoices[curSelected];

		if (controls.ACCEPT)
		{
			if (daSelected != 'BACK' && songChoices.contains(daSelected))
			{
				close();
				var name:String = daSelected;
				var poop = Highscore.formatSong(name, curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, name);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				TransitionState.transitionState(PlayState, {transitionType: "stickers"});
				FlxG.sound.music.volume = 0;
				PlayState.chartingMode = false;
				return;
			}

			switch (daSelected)
			{
				case 'BACK':
					close();
			}
			if (PlayState.instance != null)
				PlayState.instance.paused = false;
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songChoices[curSelected], curDifficulty);
		intendedRating = Highscore.getRating(songChoices[curSelected], curDifficulty);
		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(songChoices[curSelected], curDifficulty)]));
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
	}

	function changeSelection(change:Int = 0, playSound:Bool = true):Void
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;
		if (curSelected < 0)
			curSelected = songChoices.length - 1;
		if (curSelected >= songChoices.length)
			curSelected = 0;

		if (curSelected < 0)
			curSelected = songChoices.length - 1;
		if (curSelected >= songChoices.length)
			curSelected = 0;

		changeDiff();
		
		var bullShit:Int = 0;

		if (songChoices[curSelected] == "BACK")
		{
			scoreText.visible = false;
			scoreBG.visible = false;
			diffText.visible = false;
			rank.visible = false;
		}
		else
		{
			scoreText.visible = true;
			scoreBG.visible = true;
			diffText.visible = true;
			rank.visible = true;
		}

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}
