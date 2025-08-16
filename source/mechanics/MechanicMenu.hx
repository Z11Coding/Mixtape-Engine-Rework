package mechanics;

import shaders.ColorSwap;
import shaders.ColorSwap.ColorSwapShader;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxGradient;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.util.FlxSort;
import flixel.ui.FlxBar;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.tweens.misc.VarTween;
import flixel.input.mouse.FlxMouseEvent;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import mechanics.MechanicPortrait.MechanicSprite;
import backend.AIPlayer;

class MechanicMenu extends MusicBeatState
{
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var vignette:FlxSprite;
	var blackGrid:FlxBackdrop;
	var gridBG:FlxBackdrop;
	var spawnedGrids:FlxTypedGroup<FlxSprite>;
	var spawnedRandoms:FlxTypedGroup<FlxSprite>;
	var randomTxt:FlxText;

	var mechanicGrp:FlxSpriteGroup;
	var mechanicTooltips:FlxTypedGroup<MechanicTooltip>;

	var camFollow:FlxObject;
	var smoothY:Float = 0;

	var pointTxt:Alphabet;
	var rightBG:FlxSprite;
	var globalPointTxt:FlxSprite;
	var pointArrowL:MechanicSprite;
	var pointArrowR:MechanicSprite;
	var setButton:MechanicSprite;
	var multiplierTxt:FlxText;
	var multiplierDisplay:FlxText;
	var multiplierBar:FlxBar;

	public static var AIDiffs:Array<String> = ['Baby Mode', 'Easy', 'Normal', 'Hard', 'Harder', 'Average FNF Player', 'Dont'];

	public var aiArrowL:MechanicSprite;
	public var aiArrowR:MechanicSprite;
	public var aiCurrentText:FlxText;
	public var aiTitleText:FlxText;

	static var globalPoints:Int = 0;
	public static var multiplierPoints:Float = 0;

	var multiPointsDisplay:Float = 0;

	var gridShader = new ColorSwap();

	private static var gridColors:Array<Int> = [0xC1DBEC, 0xAEF1F3, 0xA9B6F0];

    override public function create()
	{
		super.create();

		FlxG.mouse.visible = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.scrollFactor.set();
		add(camFollow);

		FlxG.camera.bgColor = FlxColor.GRAY;
		FlxG.camera.follow(camFollow, LOCKON, 1);

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.scrollFactor.set();
		bg.antialiasing = true;
		bg.scale.set(1.6, 1.6);
		bg.angle = FlxG.random.float(-15, 15);
		add(bg);

		var rotationSide:Int = 0;
		var maxRotations:Int = 5;

		var lockedAngles:{min:Float, max:Float} = {min: -15, max: 15};
		var state:Int = 1;
		/*
		 * 0 = small angles, increment rotationSide until maxRotations
		 * 1 = big angles, set rotationSide to 0 and random value for maxRotations
		 */

		var doTweenAngle:FlxTween->Void = null;

		doTweenAngle = function(tween:FlxTween)
		{
			switch (state)
			{
				case 0:
					{
						FlxTween.tween(bg, {angle: FlxG.random.float(lockedAngles.min, lockedAngles.max)}, FlxG.random.float(1, 2.25), {
							ease: FlxEase.backOut,
							onComplete: function(twn:FlxTween)
							{
								if (bg == null)
									return;

								if (rotationSide >= maxRotations)
									state = 1;
								else
									rotationSide++;

								doTweenAngle(twn);
							}
						});
					}
				case 1:
					{
						var newMin:Float = FlxG.random.float(-25, -20);
						var newMax:Float = FlxG.random.float(20, 25);

						lockedAngles = {min: newMin, max: newMax};

						FlxTween.tween(bg, {angle: FlxG.random.float(lockedAngles.min, lockedAngles.max)}, FlxG.random.float(1, 2.25), {
							ease: FlxEase.backOut,
							onComplete: function(twn:FlxTween)
							{
								if (bg == null)
									return;

								rotationSide = 0;
								maxRotations = FlxG.random.int(5, 10);

								doTweenAngle(twn);
							}
						});
					}
			}
		}

		var doTweenZoom:Void->Void = null;
		doTweenZoom = function()
		{
			var random:Float = FlxG.random.float(1.3, 1.6);
			FlxTween.tween(bg.scale, {x: random, y: random}, 3, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween)
				{
					if (bg == null)
						return;

					doTweenZoom();
				},
				startDelay: FlxG.random.float(2, 5)
			});
		};

		doTweenAngle(null);
		doTweenZoom();

		gradient = FlxGradient.createGradientFlxSprite(Math.floor(bg.width), Math.floor(bg.height), [randomColor(), randomColor()]);
		gradient.scrollFactor.set();
		gradient.antialiasing = true;
		gradient.blend = MULTIPLY;
		var gradientShader = new ColorSwap();
		gradient.shader = gradientShader.shader;
		gradientShader.hue = -1.0;
		add(gradient);

		FlxTween.tween(gradientShader, {hue: 1}, 20, {ease: FlxEase.linear, type: PINGPONG});

		vignette = new FlxSprite().loadGraphic(Paths.image('mechanicsMenu/bgVignette'));
		vignette.scrollFactor.set();
		vignette.antialiasing = true;
		add(vignette);

		gridBG = new FlxBackdrop(Paths.image('mechanicsMenu/checker'), XY, 0.2, 0.2);
		gridBG.scrollFactor.set(0.1, -0.1);
		gridBG.antialiasing = true;
		gridBG.alpha = 0.2;

		gridShader.hue = FlxG.random.int(-360, 360);
		gridBG.shader = gridShader.shader;
		add(gridBG);

		blackGrid = new FlxBackdrop(Paths.image('mechanicsMenu/bgGrid'), XY, 0.2, 0.2);
		blackGrid.y -= 2;
		blackGrid.alpha = 0.8;
		blackGrid.scrollFactor.set();
		blackGrid.antialiasing = true;
		add(blackGrid);

		spawnedRandoms = new FlxTypedGroup<FlxSprite>();
		add(spawnedRandoms);

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			var chanceSpawns:Int = 1;

			for (i in 0...4)
			{
				if (FlxG.random.bool(20))
					chanceSpawns++;
			}

			var maxTime:Float = 0;

			for (j in 0...Std.int(chanceSpawns))
			{
				var randState:Int = FlxG.random.int(0, 1);

				switch (randState)
				{
					case 0:
						{
							var newSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mechanicsMenu/menuRandom0'));
							newSpr.alpha = 0;
							newSpr.scrollFactor.set();
							newSpr.flipX = FlxG.random.bool();
							newSpr.flipY = FlxG.random.bool();
							spawnedRandoms.add(newSpr);

							var wantedHeight:Float = -newSpr.height;
							var fromHeight:Float = FlxG.height + 15;

							if (FlxG.random.bool())
							{
								var originalHeight:Float = cast(wantedHeight, Float);
								fromHeight = wantedHeight;
								wantedHeight = originalHeight;
							}

							newSpr.setPosition(FlxG.random.float(0, FlxG.width - newSpr.width), fromHeight);

							var time:Float = FlxG.random.float(15, 20);
							FlxTween.tween(newSpr, {y: wantedHeight}, time, {
								onComplete: function(twn:FlxTween)
								{
									spawnedRandoms.remove(newSpr);
									newSpr.destroy();
								}
							});

							maxTime = Math.max(time, maxTime);

							// needs 16 attempts
							var alphaAttempt:Int = 0;
							var doAlphas:Void->Void = null;
							var wantedAlpha:Float = 0.1;
							doAlphas = function()
							{
								if (alphaAttempt >= 16)
									return;

								FlxTween.tween(newSpr, {alpha: wantedAlpha}, time / 16, {
									ease: FlxEase.sineOut,
									onComplete: function(twn:FlxTween)
									{
										doAlphas();
									}
								});

								if (wantedAlpha == 0.2)
									wantedAlpha = 0.3;
								else if (wantedAlpha == 0.3)
									wantedAlpha = 0.2;
								alphaAttempt++;
							};

							doAlphas();
						}
					case 1:
						{
							var time:Float = FlxG.random.float(6, 12);
							for (i in 0...3)
							{
								var newSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mechanicsMenu/menuRandom1'));
								newSpr.alpha = 0;
								newSpr.scrollFactor.set();
								newSpr.flipX = Math.random() > 0.5;
								newSpr.flipY = Math.random() > 0.5;
								spawnedRandoms.add(newSpr);

								var posX:Int = Std.int(Math.random() * 12);
								var posY:Int = Std.int(Math.random() * 7);

								newSpr.setPosition((98 * posX) + 2.25, (91 * posY) - 2);

								var wantedDirection:String = FlxG.random.getObject(['left', 'down', 'up', 'right']);

								newSpr.scale.set((wantedDirection == 'left' || wantedDirection == 'right') ? 1 : 0,
									(wantedDirection == 'down' || wantedDirection == 'up') ? 1 : 0);

								FlxTween.tween(newSpr.scale, {x: 1, y: 1}, 1.3 + FlxG.random.float(0.2, 0.4), {
									ease: FlxEase.sineOut,
									onUpdate: function(twn:FlxTween)
									{
										newSpr.alpha = FlxMath.remapToRange((newSpr.scale.x + newSpr.scale.y) / 2, 0, 2, 0, 0.7);
									},
									onComplete: function(twn:FlxTween)
									{
										newSpr.alpha = FlxMath.remapToRange((newSpr.scale.x + newSpr.scale.y) / 2, 0, 2, 0, 0.7);
									}
								});

								new FlxTimer().start(time - 1.8, function(rTmr:FlxTimer)
								{
									FlxTween.tween(newSpr, {alpha: 0}, 1.3 + FlxG.random.float(0.2, 0.4), {
										ease: FlxEase.sineOut,
										onComplete: function(twn:FlxTween)
										{
											spawnedRandoms.remove(newSpr);
											newSpr.destroy();
										}
									});
								});

								maxTime = Math.max(time, maxTime);
							}
						}
				}
			}

			tmr.reset(maxTime + 1);
		});

		spawnedGrids = new FlxTypedGroup<FlxSprite>();
		add(spawnedGrids);

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			var elapsedTime:Float = FlxG.random.float(1.25, 3);

			new FlxTimer().start(elapsedTime - 0.3, function(daTmr:FlxTimer)
			{
				tmr.reset(FlxG.random.float(0.1, 0.3));
			});

			var len:Int = Math.floor(Math.random() * 16);
			if (len <= 5)
				len = 5;

			for (i in 0...len)
			{
				var posX:Int = FlxG.random.int(0, 12);
				var posY:Int = FlxG.random.int(0, 7);

				var gridSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mechanicsMenu/bgFilledGrid'));
				gridSprite.setPosition((98 * posX) + 2.25, (91 * posY) - 2);
				gridSprite.scrollFactor.set();
				gridSprite.alpha = 0;
				gridSprite.color = FlxG.random.getObject(gridColors);
				spawnedGrids.add(gridSprite);

				FlxTween.tween(gridSprite, {alpha: 0.4}, elapsedTime / 4, {
					ease: FlxEase.sineOut,
					onComplete: function(twn:FlxTween)
					{
						new FlxTimer().start((elapsedTime / 4) * 2, function(sprTmr:FlxTimer)
						{
							FlxTween.tween(gridSprite, {alpha: 0}, elapsedTime / 4, {
								ease: FlxEase.sineOut,
								onComplete: function(twn:FlxTween)
								{
									if (gridSprite != null)
									{
										remove(gridSprite);
										gridSprite.destroy();
									}
								}
							});
						});
					}
				});
			}
		});

		rightBG = new FlxSprite(FlxG.width * 0.75, 0);
		rightBG.makeGraphic(Std.int(FlxG.width * 0.25), FlxG.height, FlxColor.fromRGB(0, 0, 0));
		rightBG.alpha = 0.3;
		rightBG.scrollFactor.set();
		add(rightBG);

		mechanicGrp = new FlxSpriteGroup();
		mechanicGrp.scrollFactor.set(0, 0.4);
		add(mechanicGrp);

		mechanicTooltips = new FlxTypedGroup<MechanicTooltip>();
		add(mechanicTooltips);

		globalPointTxt = new FlxSprite(0, FlxG.height * 0.1).loadGraphic(Paths.image('mechanicsMenu/globalPoints'));
		globalPointTxt.x = rightBG.getGraphicMidpoint().x;
		globalPointTxt.x -= globalPointTxt.width / 2;
		globalPointTxt.scrollFactor.set();
		globalPointTxt.antialiasing = true;
		add(globalPointTxt);

		pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
		pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
		if (globalPoints >= 10)
		{
			pointTxt.x -= 22;
		}
		if (globalPoints >= 20)
		{
			pointTxt.x -= 10;
		}
		pointTxt.scrollFactor.set();
		pointTxt.antialiasing = true;
		add(pointTxt);

		pointArrowL = new MechanicSprite(1031.8, FlxG.height * 0.15);
		pointArrowL.loadGraphic(Paths.image('mechanicsMenu/mechanicArr'));

		pointArrowL.unselectedScale = 1.4;
		pointArrowL.selectedScale = 1.3;
		pointArrowL.selectedColor = 0.8;
		pointArrowL.unselectedColor = 1;

		pointArrowL.scale.set(1.4, 1.4);
		pointArrowL.updateHitbox();
		pointArrowL.scrollFactor.set();
		pointArrowL.antialiasing = true;
		add(pointArrowL);

		pointArrowR = new MechanicSprite(1168.2, FlxG.height * 0.15);
		pointArrowR.loadGraphic(Paths.image('mechanicsMenu/mechanicArr'));

		pointArrowR.unselectedScale = 1.4;
		pointArrowR.selectedScale = 1.3;
		pointArrowR.selectedColor = 0.8;
		pointArrowR.unselectedColor = 1;

		pointArrowR.scale.set(1.4, 1.4);
		pointArrowR.updateHitbox();
		pointArrowR.scrollFactor.set();
		pointArrowR.antialiasing = true;
		pointArrowR.flipX = true;
		add(pointArrowR);

		FlxMouseEvent.add(pointArrowL, function(spr:MechanicSprite)
		{
			if (globalPoints - 1 == -1)
				return;

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints - 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 22;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
			pointArrowL.holding = true;
		}, null, function(spr:MechanicSprite)
		{
			pointArrowL.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			pointArrowL.isSelected = false;
		});

		pointArrowL.holdFunction = function()
		{
			if (globalPoints - 1 == -1)
			{
				pointArrowL.forceStop = true;
				pointArrowL.holding = false;
				return;
			}

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints - 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 12;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 14;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
		}

		FlxMouseEvent.add(pointArrowR, function(spr:MechanicSprite)
		{
			if (globalPoints + 1 == 21)
				return;

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints + 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 22;
			}
			if (globalPoints >= 20)
			{
				pointTxt.x -= 6;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
			pointArrowR.holding = true;
		}, null, function(spr:MechanicSprite)
		{
			pointArrowR.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			pointArrowR.isSelected = false;
		});

		pointArrowR.holdFunction = function()
		{
			if (globalPoints + 1 == 21)
			{
				pointArrowR.forceStop = true;
				pointArrowR.holding = false;
				return;
			}

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints + 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 22;
			}
			if (globalPoints >= 20)
			{
				pointTxt.x -= 10;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
		}

		setButton = new MechanicSprite(globalPointTxt.getGraphicMidpoint().x, FlxG.height * 0.275);
		setButton.loadGraphic(Paths.image('mechanicsMenu/setAllPoints'));
		setButton.x = rightBG.getGraphicMidpoint().x;
		setButton.x -= globalPointTxt.width / 4;
		setButton.x += 10;
		setButton.scrollFactor.set();
		setButton.antialiasing = true;
		setButton.unselectedColor = 1;
		setButton.selectedColor = 0.7;
		setButton.colorSpeed *= 2.5;
		add(setButton);

		FlxMouseEvent.add(setButton, function(spr:MechanicSprite)
		{
			var changed:Bool = false;

			for (mechanic in MechanicManager.mechanics.keys())
			{
				if (MechanicManager.mechanics[mechanic].points == globalPoints)
					continue;

				changed = true;

				MechanicManager.mechanics[mechanic].points = globalPoints;
				if (MechanicManager.mechanics[mechanic].spriteParent != null)
					MechanicManager.mechanics[mechanic].spriteParent.text.text = '' + globalPoints;
			}

			if (changed)
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
			if (setButton != null) // no bitches?
			{
				FlxTween.cancelTweensOf(setButton.colorTransform);
				setButton.colorTransform.redOffset = 255;
				setButton.colorTransform.blueOffset = 255;
				setButton.colorTransform.greenOffset = 255;
				FlxTween.tween(setButton.colorTransform, {redOffset: 0, blueOffset: 0, greenOffset: 0}, 0.6, {ease: FlxEase.quadOut});
			}
		}, null, function(spr:MechanicSprite)
		{
			setButton.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			setButton.isSelected = false;
		});

		multiplierDisplay = new FlxText(0, FlxG.height * 0.4, 0, 'MULTIPLIER', 32);
		multiplierDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		multiplierDisplay.borderSize = 2;
		multiplierDisplay.updateHitbox();
		multiplierDisplay.scrollFactor.set();
		multiplierDisplay.antialiasing = true;
		multiplierDisplay.x = rightBG.getGraphicMidpoint().x - (multiplierDisplay.width / 2);
		multiplierDisplay.x += 4;
		add(multiplierDisplay);

		multiplierTxt = new FlxText(0, FlxG.height * 0.45, 0, '0.0X', 64);
		multiplierTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		multiplierTxt.borderSize = 3.5;
		multiplierTxt.updateHitbox();
		multiplierTxt.scrollFactor.set();
		multiplierTxt.antialiasing = true;
		multiplierTxt.x = rightBG.getGraphicMidpoint().x - (multiplierTxt.width / 2);
		multiplierTxt.x += 4;
		add(multiplierTxt);

		multiplierBar = new FlxBar(multiplierDisplay.x, multiplierTxt.y + multiplierTxt.height + 10, LEFT_TO_RIGHT, Std.int(multiplierDisplay.width), 8, this,
			'multiPointsDisplay', 1, 3.4);
		multiplierBar.scrollFactor.set();
		multiplierBar.antialiasing = true;
		multiplierBar.numDivisions = FlxG.width * 2;
		multiplierBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.WHITE, false, FlxColor.TRANSPARENT);
		add(multiplierBar);

		smoothY = 800;

		var i:Int = 0;

		var sortedMechanics:Array<MechanicManager.MechanicData> = [];
		var stackedTooltips:Array<MechanicTooltip> = [];

		for (mechanic in MechanicManager.mechanics.keys())
		{
			sortedMechanics.push(MechanicManager.mechanics[mechanic]);
		}

		var sortByValue = function(_1, _2)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, _1.ID, _2.ID);
		}

		sortedMechanics.sort(sortByValue);

		for (mechanic in sortedMechanics)
		{
			var mechanicSpr:MechanicPortrait;
			mechanicSpr = new MechanicPortrait(40 + (200 * (i % 4)) + 2, 180 + (360 * Math.floor(i / 4)), mechanic, null);
			mechanicSpr.scrollFactor.set(0, 0.4);
			mechanic.spriteParent = mechanicSpr;
			mechanicSpr.text.text = '' + mechanic.points;
			mechanicSpr.tooltip.scrollFactor.set(0, 0.4);

			FlxMouseEvent.add(mechanicSpr.arrowL, function(spr:MechanicSprite)
			{
				if (mechanic.points == 0)
				{
					return;
				}

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points - 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
				mechanicSpr.arrowL.holding = true;
			}, null, function(spr:MechanicSprite)
			{
				spr.isSelected = true;
			}, function(spr:MechanicSprite)
			{
				spr.isSelected = false;
			}, true);

			mechanicSpr.arrowL.holdFunction = function()
			{
				if (mechanic.points == 0)
				{
					mechanicSpr.arrowL.forceStop = true;
					mechanicSpr.arrowL.holding = false;
					return;
				}

				if (mechanic.points - 1 != -1 || (mechanic.points + 1 == 1 && mechanic.points == 0))
					FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points - 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
			};

			FlxMouseEvent.add(mechanicSpr.arrowR, function(spr:MechanicSprite)
			{
				if (mechanic.points == 20)
				{
					return;
				}

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points + 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
				mechanicSpr.arrowR.holding = true;
			}, null, function(spr:MechanicSprite)
			{
				spr.isSelected = true;
			}, function(spr:MechanicSprite)
			{
				spr.isSelected = false;
			}, true);

			mechanicSpr.arrowR.holdFunction = function()
			{
				if (mechanic.points == 20)
				{
					mechanicSpr.arrowR.forceStop = true;
					mechanicSpr.arrowR.holding = false;
					return;
				}

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points + 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
			};

			mechanicGrp.add(mechanicSpr);
			stackedTooltips.push(mechanicSpr.tooltip);

			i++;
		}

		for (tooltip in stackedTooltips)
		{
			mechanicTooltips.add(tooltip);
		}

		var center:FlxPoint = rightBG.getGraphicMidpoint();

		aiCurrentText = new FlxText(center.x, center.y, 0, 'Normal', 24);
		aiCurrentText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		aiCurrentText.scrollFactor.set();
		aiCurrentText.borderSize = 2;
		aiCurrentText.setPosition(center.x - (aiCurrentText.width / 2), center.y - (aiCurrentText.height / 2));
		aiCurrentText.y += 125;
		aiCurrentText.antialiasing = ClientPrefs.data.antialiasing;
		add(aiCurrentText);

		aiTitleText = new FlxText(center.x, center.y, 0, 'AI Difficulty', 28);
		aiTitleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		aiTitleText.scrollFactor.set();
		aiTitleText.borderSize = 2;
		aiTitleText.setPosition(center.x - (aiTitleText.width / 2), center.y - (aiTitleText.height / 2));
		aiTitleText.y += 75;
		aiTitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(aiTitleText);

		(aiArrowL = new MechanicSprite()).loadGraphic(Paths.image('mechanicsMenu/mechanicArr'));
		aiArrowL.scrollFactor.set();
		aiArrowL.setPosition(aiCurrentText.x - aiArrowL.width - 4, aiCurrentText.y - 12);
		aiArrowL.antialiasing = ClientPrefs.data.antialiasing;
		add(aiArrowL);

		(aiArrowR = new MechanicSprite()).loadGraphic(Paths.image('mechanicsMenu/mechanicArr'));
		aiArrowR.scrollFactor.set();
		aiArrowR.setPosition(aiCurrentText.x + aiCurrentText.width + 4, aiCurrentText.y - 12);
		aiArrowR.antialiasing = ClientPrefs.data.antialiasing;
		aiArrowR.flipX = true;
		add(aiArrowR);

		aiArrowL.unselectedScale = 1.0;
		aiArrowL.selectedScale = 0.9;
		aiArrowL.selectedColor = 0.8;
		aiArrowL.unselectedColor = 1;

		aiArrowR.unselectedScale = 1.0;
		aiArrowR.selectedScale = 0.9;
		aiArrowR.selectedColor = 0.8;
		aiArrowR.unselectedColor = 1;

		FlxMouseEvent.add(aiArrowL, function(spr:MechanicSprite)
		{
			if (!AIPlayer.active || AIPlayer.diff - 1 < 0)
			{
				return;
			}
			AIPlayer.diff = Std.int(CoolUtil.boundTo(AIPlayer.diff - 1, 0, AIDiffs.length - 1));
			aiCurrentText.text = AIDiffs[AIPlayer.diff];
			FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);

			aiCurrentText.setPosition(center.x - (aiCurrentText.width / 2), center.y - (aiCurrentText.height / 2));
			aiCurrentText.y += 125;
		}, null, function(spr:MechanicSprite)
		{
			if (AIPlayer.active)
				spr.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			if (AIPlayer.active)
				spr.isSelected = false;
		}, true);

		FlxMouseEvent.add(aiArrowR, function(spr:MechanicSprite)
		{
			if (!AIPlayer.active || AIPlayer.diff + 1 > AIDiffs.length)
			{
				return;
			}
			AIPlayer.diff = Std.int(CoolUtil.boundTo(AIPlayer.diff + 1, 0, AIDiffs.length - 1));
			aiCurrentText.text = AIDiffs[AIPlayer.diff];
			FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);

			aiCurrentText.setPosition(center.x - (aiCurrentText.width / 2), center.y - (aiCurrentText.height / 2));
			aiCurrentText.y += 125;
		}, null, function(spr:MechanicSprite)
		{
			if (AIPlayer.active)
				spr.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			if (AIPlayer.active)
				spr.isSelected = false;
		}, true);

		aiCurrentText.text = AIDiffs[AIPlayer.diff];
		aiCurrentText.setPosition(center.x - (aiCurrentText.width / 2), center.y - (aiCurrentText.height / 2) + 125);

		FlxMouseEvent.add(aiTitleText, function(txt:FlxText)
		{
			AIPlayer.active = !AIPlayer.active;

			var AIAlpha:Float = 1.0;

			if (!AIPlayer.active)
				AIAlpha = 0.7;

			aiCurrentText.alpha = aiTitleText.alpha = aiArrowL.alpha = aiArrowR.alpha = AIAlpha;

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
		});
	}

	var moveBG:Bool = true;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < FlxMath.remapToRange(1 / 10, 0, 1, 0, 0.8))
			{
				FlxG.sound.music.volume += 0.5 * elapsed;
			}
		}

		gridShader.hue += elapsed * 0.1;

		if (moveBG)
		{
			var multiplier:Float = 1.4;

			if (FlxG.mouse.getScreenPosition().y > FlxG.height * 0.8)
				smoothY += 420 * (elapsed * 2.2) * multiplier;
			else if (FlxG.mouse.getScreenPosition().y < FlxG.height * 0.2)
				smoothY -= 420 * (elapsed * 2.2) * multiplier;

			smoothY -= FlxG.mouse.wheel * 120;
		}

		smoothY = CoolUtil.boundTo(smoothY, 700, 4500);

		camFollow.y = FlxMath.lerp(camFollow.y, smoothY, CoolUtil.boundTo(elapsed * 3.5, 0, 1));

		pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;

		if (globalPoints >= 10)
		{
			pointTxt.x -= 22;
		}
		if (globalPoints >= 20)
		{
			pointTxt.x -= 10;
		}

		var multiplierInitial:Float = 0;

		for (mechanic in MechanicManager.mechanics.keys())
		{
			var points:Int = MechanicManager.mechanics[mechanic].points;
			if (points <= 0)
				points = 0;

			multiplierInitial += 1 * points;
		}

		multiplierInitial /= 2;

		MechanicManager.multiplier = multiplierPoints = 1 + FlxMath.roundDecimal(multiplierInitial / 100, 2);
		multiPointsDisplay = cast multiplierPoints;

		if (multiplierTxt != null)
		{
			multiplierTxt.text = '' + formatMulti(multiplierPoints) + 'X';
			multiplierTxt.x = rightBG.getGraphicMidpoint().x;
			multiplierTxt.x -= multiplierTxt.width / 2;
			multiplierTxt.x += 4;
		}

		moveBG = !(FlxG.mouse.getScreenPosition().x >= rightBG.x);

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            FlxG.switchState(new states.CategoryState());
        }
	}

	function formatMulti(num:Float):String
	{
		var conv:String = Std.string(num);

		while (conv.length < 4)
		{
			if (conv.length == 1)
				conv += '.';
			else
				conv += '0';
		}

		return conv;
	}

	override public function destroy()
	{
		for (mechanic in MechanicManager.mechanics.keys())
		{
			MechanicManager.mechanics[mechanic].spriteParent = null;
		}

		FlxG.camera.bgColor = 0;

		spawnedRandoms.forEachExists(function(spr:FlxSprite)
		{
			FlxTween.completeTweensOf(spr);
		});

		super.destroy();
	}

	function randomColor():FlxColor
	{
		return FlxColor.fromRGB(FlxG.random.int(165, 225), FlxG.random.int(165, 225), FlxG.random.int(165, 225), 255);
	}
}