package states.freeplay.vslice.capsule;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import shaders.Grayscale;
import states.freeplay.vslice.obj.PixelatedIcon;
import states.freeplay.vslice.obj.SngCapsuleData.FreeplaySongData;
import states.freeplay.vslice.obj.SngCapsuleData.FreeplayStyle;
import states.freeplay.vslice.obj.SngCapsuleData.ScoringRank;

#if !html5
import shaders.GaussianBlurShader;
import shaders.Grayscale;
import shaders.HSVShader;
#end

/**
 * Song menu item for V-Slice freeplay system
 * Adapted from P-Slice for Mixtape Engine
 */
class SongMenuItem extends FlxSpriteGroup
{
	public var capsule:FlxSprite;

	var pixelIcon:PixelatedIcon;

	/**
	 * Modify this by calling `init()`
	 * If `null`, assume this SongMenuItem is for the "Random Song" option.
	 */
	public var songData(default, null):Null<FreeplaySongData> = null;

	public var selected(default, set):Bool;

	public var doLerp(null, set):Bool;
	function set_doLerp(value:Bool):Bool {
		animBox.doLerp = value;
		return value;
	}

	public var animBox:CustomAnimControl;
	public var songText:CapsuleText;
	public var favIconBlurred:FlxSprite;
	public var favIcon:FlxSprite;

	public var ranking:FreeplayRank;
	public var blurredRanking:FreeplayRank;

	var fakeRankingInited:Bool = false;
	var fakeRanking:FreeplayRank;
	var fakeBlurredRanking:FreeplayRank;

	public var txtWeek:states.freeplay.vslice.AtlasText;

	public var targetPos:FlxPoint = FlxPoint.get();

	public var onConfirm:Void->Void;

	#if !html5
	public var grayscaleShader:Grayscale;
	public var hsvShader(default, set):HSVShader;
	#end

	// var diffRatingSprite:FlxSprite;
	public var bpmText:FlxSprite;
	public var difficultyText:FlxSprite;
	public var weekType:FlxSprite;

	public var newText:FlxSprite;

	// public var weekType:FlxSprite;
	public var bigNumbers:Array<CapsuleNumber> = [];

	public var smallNumbers:Array<CapsuleNumber> = [];

	var impactThing:FlxSprite;
	var grpHide:FlxGroup;
	public var sparkle:FlxSprite;

	var sparkleTimer:FlxTimer;

	var currentFpStyle:Null<FreeplayStyle> = null;

	#if !html5
	static var gaussianBlur:GaussianBlurShader = null;
	static var gaussianBlur_12:GaussianBlurShader = null;
	public static var static_hsvShader:HSVShader = null;
	#end

	public static function reloadGlobalItemData()
	{
		#if !html5
		if (ClientPrefs.data.shaders)
		{
			static_hsvShader = new HSVShader();
			gaussianBlur = new GaussianBlurShader(1);
			gaussianBlur_12 = new GaussianBlurShader(1.2);
		}
		else
		{
			static_hsvShader = null;
			gaussianBlur = null;
			gaussianBlur_12 = null;
		}
		#else
		static_hsvShader = null;
		gaussianBlur = null;
		gaussianBlur_12 = null;
		#end
	}

	public function new(x:Float, y:Float, styleData:FreeplayStyle)
	{
		super(x, y);
		animBox = new CustomAnimControl(this);

		capsule = new FlxSprite();
		initFreeplayStyle(styleData);
		add(capsule);

		bpmText = new FlxSprite(144, 87);
		var bpmImg = Paths.image('freeplay/freeplayCapsule/bpmtext', 'vslice');
		if (bpmImg != null) {
			bpmText.loadGraphic(bpmImg);
			bpmText.setGraphicSize(Std.int(bpmText.width * 0.9));
		} else {
			bpmText.makeGraphic(50, 20, 0xFF666666);
		}
		bpmText.antialiasing = ClientPrefs.data.antialiasing;
		add(bpmText);

		difficultyText = new FlxSprite(414, 87);
		var diffImg = Paths.image('freeplay/freeplayCapsule/difficultytext', 'vslice');
		if (diffImg != null) {
			difficultyText.loadGraphic(diffImg);
			difficultyText.setGraphicSize(Std.int(difficultyText.width * 0.9));
		} else {
			difficultyText.makeGraphic(50, 20, 0xFF666666);
		}
		difficultyText.antialiasing = ClientPrefs.data.antialiasing;
		add(difficultyText);

		newText = new FlxSprite(454, 9);
		newText.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/new', 'vslice');
		if (newText.frames != null) {
			newText.animation.addByPrefix('newAnim', 'NEW notif', 24, true);
			newText.animation.play('newAnim', true);
			newText.setGraphicSize(Std.int(newText.width * 0.9));
		} else {
			newText.makeGraphic(30, 15, 0xFFFF0000);
		}
		newText.antialiasing = ClientPrefs.data.antialiasing;
		add(newText);

		for (i in 0...2)
		{
			var bigNumber:CapsuleNumber = new CapsuleNumber(466 + (i * 30), 32, true, 0);
			add(bigNumber);

			bigNumbers.push(bigNumber);
		}

		for (i in 0...3)
		{
			var smallNumber:CapsuleNumber = new CapsuleNumber(185 + (i * 11), 88.5, false, 0);
			add(smallNumber);

			smallNumbers.push(smallNumber);
		}

		// doesn't get added, simply is here to help with visibility of things for the pop in!
		grpHide = new FlxGroup();

		ranking = new FreeplayRank(420, 41);
		add(ranking);

		blurredRanking = new FreeplayRank(420, 41);
		#if !html5
		if (gaussianBlur != null) {
			blurredRanking.shader = gaussianBlur;
		}
		#end
		add(blurredRanking);

		sparkle = new FlxSprite(ranking.x, ranking.y);
		sparkle.frames = Paths.getSparrowAtlas('freeplay/sparkle', 'vslice');
		if (sparkle.frames != null) {
			sparkle.animation.addByPrefix('sparkle', 'sparkle Export0', 24, false);
			sparkle.animation.play('sparkle', true);
		} else {
			sparkle.makeGraphic(30, 30, 0xFFFFFFFF);
		}
		sparkle.scale.set(0.8, 0.8);
		sparkle.blend = BlendMode.ADD;
		sparkle.antialiasing = ClientPrefs.data.antialiasing;

		sparkle.visible = false;
		sparkle.alpha = 0.7;

		add(sparkle);

        #if !html5
        if (ClientPrefs.data.shaders) {
            grayscaleShader = new Grayscale();
        }
        #end

		songText = new states.freeplay.vslice.CapsuleText(capsule.width * 0.26, 45, 'Random', Std.int(40 * animBox.realScaled));
		songText.applyStyle(styleData);
		add(songText);
		grpHide.add(songText);

		// TODO: Use value from metadata instead of random.
		updateDifficultyRating(0);
		// ? changed offsets
		pixelIcon = new PixelatedIcon(60, 14);
		add(pixelIcon);
		grpHide.add(pixelIcon);

		favIconBlurred = new FlxSprite(380, 40);
		favIconBlurred.frames = Paths.getSparrowAtlas('freeplay/favHeart', 'vslice');
		if (favIconBlurred.frames != null) {
			favIconBlurred.animation.addByPrefix('fav', 'favorite heart', 24, false);
			favIconBlurred.animation.play('fav');
		} else {
			favIconBlurred.makeGraphic(50, 50, 0xFFFF69B4);
		}

		favIconBlurred.setGraphicSize(50, 50);
		favIconBlurred.blend = BlendMode.ADD;
		favIconBlurred.antialiasing = ClientPrefs.data.antialiasing;
		#if !html5
		if (gaussianBlur_12 != null) {
			favIconBlurred.shader = gaussianBlur_12;
		}
		#end
		favIconBlurred.visible = false;
		add(favIconBlurred);

		favIcon = new FlxSprite(favIconBlurred.x, favIconBlurred.y);
		favIcon.frames = Paths.getSparrowAtlas('freeplay/favHeart', 'vslice');
		if (favIcon.frames != null) {
			favIcon.animation.addByPrefix('fav', 'favorite heart', 24, false);
			favIcon.animation.play('fav');
		} else {
			favIcon.makeGraphic(50, 50, 0xFFFF69B4);
		}
		favIcon.setGraphicSize(50, 50);
		favIcon.visible = false;
		favIcon.blend = BlendMode.ADD;
		favIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(favIcon);

		setVisibleGrp(false);
	}

	public function setFakeRanking(oldRank:Null<ScoringRank>)
	{
		if (!fakeRankingInited)
		{
			var index = members.indexOf(ranking);
			fakeRankingInited = true;

			fakeRanking = new FreeplayRank(420, 41);
			insert(index, fakeRanking);

			fakeRanking.visible = false;
		}
		fakeRanking.rank = oldRank;
	}

	function sparkleEffect(timer:FlxTimer):Void
	{
		sparkle.setPosition(FlxG.random.float(ranking.x - 20, ranking.x + 3), FlxG.random.float(ranking.y - 29, ranking.y + 4));
		if (sparkle?.animation != null)
		{ // ? don't play sparkle anim if it's destroyed
			sparkle.animation.play('sparkle', true);
			sparkleTimer = new FlxTimer().start(FlxG.random.float(1.2, 4.5), sparkleEffect);
		}
	}

	/**
	 * Checks whether the song is favorited, and/or has a rank, and adjusts the clipping
	 * for the scenario when the text could be too long
	 */
	public function checkClip():Void
	{
		var clipSize:Int = 290;
		var clipType:Int = 0;

		if (ranking.visible)
		{
			favIconBlurred.x = this.x + 370;
			favIcon.x = favIconBlurred.x;
			clipType += 1;
		}
		else
		{
			favIconBlurred.x = favIcon.x = this.x + 405;
		}

		if (favIcon.visible)
			clipType += 1;

		switch (clipType)
		{
			case 2:
				clipSize = 210;
			case 1:
				clipSize = 245;
		}
		songText.clipWidth = clipSize;
	}

	function updateBPM(newBPM:Int):Void
	{
		if (newBPM <= 0)
		{
			for (item in smallNumbers)
				item.visible = false;
			bpmText.visible = false;
			return;
		}
		else
		{
			for (item in smallNumbers)
				item.visible = true;
			bpmText.visible = true;
		}

		var shiftX:Float = 191;
		var tempShift:Float = 0;

		if (Math.floor(newBPM / 100) == 1)
		{
			shiftX = 186;
		}

		for (i in 0...smallNumbers.length)
		{
			smallNumbers[i].x = this.x + (shiftX + (i * 11));
			switch (i)
			{
				case 0:
					if (newBPM < 100)
					{
						smallNumbers[i].digit = 0;
					}
					else
					{
						smallNumbers[i].digit = Math.floor(newBPM / 100) % 10;
					}

				case 1:
					if (newBPM < 10)
					{
						smallNumbers[i].digit = 0;
					}
					else
					{
						smallNumbers[i].digit = Math.floor(newBPM / 10) % 10;

						if (Math.floor(newBPM / 10) % 10 == 1)
							tempShift = -4;
					}
				case 2:
					smallNumbers[i].digit = newBPM % 10;
				default:
					trace('why the fuck is this being called');
			}
			smallNumbers[i].x += tempShift;
		}
	}

	var evilTrail:FlxTrail;

	public function fadeAnim():Void
	{
		impactThing = new FlxSprite(0, 0);
		impactThing.frames = capsule.frames;
		impactThing.frame = capsule.frame;
		impactThing.updateHitbox();

		impactThing.alpha = 0;
		add(impactThing);
		FlxTween.tween(impactThing.scale, {x: 2.5, y: 2.5}, 0.5);

		evilTrail = new FlxTrail(impactThing, null, 15, 2, 0.01, 0.069);
		evilTrail.blend = BlendMode.ADD;
		FlxTween.tween(evilTrail, {alpha: 0}, 0.6, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				remove(evilTrail);
			}
		});
		add(evilTrail);

		switch (ranking.rank)
		{
			case SHIT:
				evilTrail.color = 0xFF6044FF;
			case GOOD:
				evilTrail.color = 0xFFEF8764;
			case GREAT:
				evilTrail.color = 0xFFEAF6FF;
			case EXCELLENT:
				evilTrail.color = 0xFFFDCB42;
			case PERFECT:
				evilTrail.color = 0xFFFF58B4;
			case PERFECT_GOLD:
				evilTrail.color = 0xFFFFB619;
		}
	}

	public function getTrailColor():FlxColor
	{
		return evilTrail.color;
	}

	/**
	 * Refreshes all displayed items by this card.
	 * Use only for changing the song data on this card.
	 */
	function refreshDisplayFull():Void
	{
		if (songData == null)
		{
			songText.text = 'Random';
			pixelIcon.visible = false;
		}
		else
		{
			songText.text = songData.songName;
			if (songData.songCharacter != null)
				pixelIcon.setCharacter(songData.songCharacter);
			pixelIcon.visible = true;
			updateWeekText(songData?.songWeekName ?? "");
		}
		refreshDisplayDifficulty();
	}

	/**
	 * Updates difficulty on this song.
	 *
	 * Call this if you've changed the current difficulty for this song.
	 */
	public function refreshDisplayDifficulty()
	{
		if (songData == null)
		{
			updateScoringRank(null);
			ranking.visible = false;
			blurredRanking.visible = false;
			favIcon.visible = false;
			favIconBlurred.visible = false;
			newText.visible = false;
		}
		else
		{
			updateBPM(Std.int(songData.songStartingBpm) ?? 0);
			updateDifficultyRating(songData.difficultyRating ?? 0);
			updateScoringRank(songData.scoringRank);
			newText.visible = songData.isNew;
			if (newText.visible)
			{
				newText.animation.play('newAnim', true);
				newText.animation.curAnim.curFrame = 45 - ((ID * 4) % 45);
			}
			favIcon.visible = songData.isFav;
			favIconBlurred.visible = songData.isFav;
			checkClip();
		}
		updateSelected();

		// I think this ends the "favorite" anim early
		try {
			favIcon.animation.curAnim.curFrame = favIcon.animation.curAnim.numFrames - 1;
		} catch (e:Dynamic) {
			// Animation not available or not initialized
		}
		try {
			favIconBlurred.animation.curAnim.curFrame = favIconBlurred.animation.curAnim.numFrames - 1;
		} catch (e:Dynamic) {
			// Animation not available or not initialized
		}
	}

	/**
	 * Updated the week text at the bottom of the capsule
	 * @param newText A new value for the text
	 */
	public function updateWeekText(newText:String = "")
	{
		if (txtWeek != null)
		{
			if (newText == txtWeek.text)
				return;
			remove(txtWeek);
			txtWeek.destroy();
		}
		if (newText == "")
			return;
		txtWeek = new states.freeplay.vslice.AtlasText(298, 91, newText, states.freeplay.vslice.AtlasText.AtlasFont.CAPSULE_TEXT);
		add(txtWeek);
	}

	var prevRating:Int = -1;

	function updateDifficultyRating(newRating:Int):Void
	{
		if (prevRating == newRating)
			return;
		else
			prevRating = newRating;

		if (newRating < 0)
		{
			for (item in bigNumbers)
				item.visible = false;
			difficultyText.visible = false;
			return;
		}
		else
		{
			for (item in bigNumbers)
				item.visible = true;
			difficultyText.visible = true;
		}

		var ratingPadded:String = newRating < 10 ? '0$newRating' : '$newRating';

		for (i in 0...bigNumbers.length)
		{
			switch (i)
			{
				case 0:
					if (newRating < 10)
					{
						bigNumbers[i].digit = 0;
					}
					else
					{
						bigNumbers[i].digit = Math.floor(newRating / 10);
					}
				case 1:
					bigNumbers[i].digit = newRating % 10;
				default:
					trace('why the fuck is this being called');
			}
		}
		// diffRatingSprite.loadGraphic(Paths.image('freeplay/diffRatings/diff${ratingPadded}'));
		// diffRatingSprite.visible = false;
	}

	function updateScoringRank(newRank:Null<ScoringRank>):Void
	{
		if (sparkleTimer != null)
			sparkleTimer.cancel();
		sparkle.visible = false;

		this.ranking.rank = newRank;
		this.blurredRanking.rank = newRank;

		if (newRank == PERFECT_GOLD)
		{
			sparkleTimer = new FlxTimer().start(1, sparkleEffect);
			sparkle.visible = true;
		}
		checkClip();
	}

	#if !html5
	function set_hsvShader(value:HSVShader):HSVShader
	{
		this.hsvShader = value;
		if (ClientPrefs.data.shaders) {
			capsule.shader = hsvShader;
			songText.shader = hsvShader;
		}
		return value;
	}
	#end

	function textAppear():Void
	{
		songText.scale.x = 1.7;
		songText.scale.y = 0.2;

		new FlxTimer().start(1 / 24, function(_)
		{
			songText.scale.x = 0.4;
			songText.scale.y = 1.4;
		});

		new FlxTimer().start(2 / 24, function(_)
		{
			songText.scale.x = songText.scale.y = 1;
		});
		// ? Attempting fallback in case the previous one fails!
		new FlxTimer().start(4 / 24, function(_)
		{
			songText.scale.x = songText.scale.y = 1;
		});
	}

	public function setVisibleGrp(value:Bool):Void
	{
		for (spr in grpHide.members)
		{
			spr.visible = value;
		}

		if (value)
			textAppear();

		updateSelected();
	}

	/**
	 * Reconstructs all the data in this card based on the parameters frovided. Use only when fully recycling!
	 * @param x
	 * @param y
	 */
	public function initPosition(?x:Float, ?y:Float):Void
	{
		if (x != null)
			this.x = x;
		if (y != null)
			this.y = y;
	}

	public function applySongData(songData:Null<FreeplaySongData>)
	{
		this.songData = songData;
		refreshDisplayFull();
	}

	/**
	 * Initialises new freeplay style on this card.
	 *
	 * To be honest we don't even seed this!
	 */
	public function initFreeplayStyle(styleData:FreeplayStyle)
	{
		if (styleData == currentFpStyle)
			return;

		currentFpStyle = styleData;

		capsule.frames = Paths.getSparrowAtlas(styleData.getCapsuleAssetKey(), 'vslice');

		// Create fallback if frames don't exist
		if (capsule.frames == null) {
			capsule.makeGraphic(500, 100, 0xFF666666);
		} else {
			// This applies new style in case we change it
			capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
			capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
		}

		capsule.antialiasing = ClientPrefs.data.antialiasing;

		songText?.applyStyle(styleData);
	}

	var capsuleAnimation:SongCapsuleAnim = JUMPIN;

	public function setCapsuleAnimation(anim:SongCapsuleAnim)
	{
		capsuleAnimation = anim;
		switch (anim)
		{
			case JUMPIN:
				animBox.initJumpIn(0, false);
			case JUMPIN_FORCE:
				animBox.initJumpIn(0, true);
			case SLIDE_LEFT | SLIDE_RIGHT:
				animBox.forcePosition();
		}
	}
	override function update(elapsed:Float) {
		if (impactThing != null)
			impactThing.angle = capsule.angle;
		animBox.update(elapsed);

		super.update(elapsed);
	}
	public function setCapsuleAnimInitPosition()
	{
		switch (capsuleAnimation)
		{
			case SLIDE_LEFT:
				x = -800; // This is starting position on X
				y = targetPos.y; // This is starting position on X
			case SLIDE_RIGHT:
				x = FlxG.width; // This is starting position on X
				y = targetPos.y; // This is starting position on X
			default:
		}
	}
	public function playJumpOut() {
		animBox.doJumpIn = false;
		animBox.doLerp = false;
		animBox.doJumpOut = true;
	}

	override function destroy()
	{
		targetPos.put();
		updateWeekText("");
		super.destroy();
	}

	/**
	 * Play any animations associated with selecting this song.
	 */
	public function confirm():Void
	{
		if (songText != null)
			songText.flickerText();
		if (pixelIcon != null && pixelIcon.visible)
		{
			pixelIcon.animation.play('confirm');
		}
	}

	public function intendedY(index:Float):Float
	{
		return index * ((height * animBox.realScaled) + 10) + 120;
	}

	public function intendedX(index:Float):Float
	{
		return 270 + (60 * (FlxMath.fastSin(index)));
	}

	function set_selected(value:Bool):Bool
	{
		// cute one liners, lol!
		selected = value;
		updateSelected();
		return selected;
	}

	function updateSelected():Void
	{
		#if !html5
		if (grayscaleShader != null) {
			grayscaleShader.setAmount(this.selected ? 0 : 0.8);
		}
		#end

		songText.alpha = this.selected ? 1 : 0.6;
		songText.blurredText.visible = this.selected ? true : false;
		capsule.offset.x = this.selected ? 0 : -5;

		if (capsule.animation != null) {
			capsule.animation.play(this.selected ? "selected" : "unselected");
		}

		ranking.alpha = this.selected ? 1 : 0.7;
		favIcon.alpha = this.selected ? 1 : 0.6;
		favIconBlurred.alpha = this.selected ? 1 : 0;
		ranking.color = this.selected ? 0xFFFFFFFF : 0xFFAAAAAA;

		if (songText.tooLong)
			songText.resetText();

		if (selected && songText.tooLong)
			songText.initMove();
	}
}

enum SongCapsuleAnim
{
	SLIDE_LEFT;
	SLIDE_RIGHT;
	JUMPIN;
	JUMPIN_FORCE;
}
