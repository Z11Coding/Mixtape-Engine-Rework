package mechanics;

import objects.Bar;
import objects.Note;
import objects.StrumNote;
import objects.AttachedSprite;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxStringUtil;
import flixel.math.FlxVelocity;

class MechanicsPlaystate {

    public static var instance:MechanicsPlaystate;

    public function new() {
        instance = this;
    }

    public var burstTime:{min:Float, max:Float, value:Float} = null;
	public var allowBurstTween:Bool = true;

	public function burstNote():Void
	{
		if (burstTime == null)
		{
			burstTime = {min: 0, max: 5, value: 0};
		}
		var points:Float = MechanicManager.mechanics['burst_note'].points;

		var minimum:Float = FlxMath.remapToRange(points, 0, 20, 1, 2);
		var maximum:Float = FlxMath.remapToRange(points, 0, 20, 8, 14);
		var value:Float = FlxG.random.float((minimum + maximum / 2), maximum);

		PlayState.instance.mechanicsResult[2].value += value;

		burstTime = {min: minimum, max: maximum, value: value};
	}

	public var sleepTime:{max:Float, value:Float, lerpValue:Float} = null;
	public var sleepTimer:FlxTimer = null;

	public function sleepNote():Void
	{
		if (sleepTime == null)
		{
			var max = FlxMath.remapToRange(MechanicManager.mechanics['sleep_note'].points, 0, 20, 15, 7);
			var value = 1;
			sleepTime = {max: max, value: value, lerpValue: 0};

			sleepTimer = new FlxTimer().start(2.5, function(tmr:FlxTimer)
			{
				sleepTime.value -= FlxG.random.float(0.15, 0.25);
			}, 0);
		}
		else
		{
			var random:Float = FlxG.random.float(1, 1.25);
			PlayState.instance.mechanicsResult[5].value += random;
			sleepTime.value += random;
		}

		if (sleepTime.value >= sleepTime.max)
		{
			PlayState.instance.health = -40;
			PlayState.instance.doDeathCheck(true);
		}
	}

	public var lastHealth:Float = 0;
	public var healthTimer:FlxTimer;
	public var restoreActivated:Bool = false;

	public function restoreNote():Void
	{
		if (restoreActivated)
			return;

		lastHealth = cast PlayState.instance.health;
		var calculateHealth:Float = FlxMath.remapToRange(lastHealth / 50, 0, PlayState.instance.MaxHP, PlayState.instance.minHealth, PlayState.instance.MaxHP);
		healthTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			PlayState.instance.noTriggerKarma = true;
			PlayState.instance.health -= calculateHealth;
			PlayState.instance.mechanicsResult[4].value += calculateHealth * 10;
			if (tmr.elapsedLoops > 15)
			{
				if (FlxG.random.bool(5 + (tmr.elapsedLoops * 1.25)))
				{
					var time:Float = 3100;
					if (PlayState.instance.songSpeed < 1)
						time /= PlayState.instance.songSpeed;
					var restoreNote:Note = new Note(Conductor.songPosition + time, FlxG.random.int(0, 3), null);

					restoreNote.mustPress = restoreNote.formerPress = true;
					restoreNote.scrollSpeed = PlayState.instance.songSpeed;
					restoreNote.noteType = 'Restore Note';
					restoreNote.x += FlxG.width / 2; // general offset
                    restoreNote.fieldIndex = 0;
                    restoreNote.field = PlayState.instance.playfields.members[0];
                    restoreNoteGroup.push(restoreNote);
                    PlayState.instance.allNotes.unshift(restoreNote);
					PlayState.instance.unspawnNotes.unshift(restoreNote);
                    PlayState.instance.playfields.members[0].queue(restoreNote);
				}
			}
			PlayState.instance.noTriggerKarma = false;

			calculateHealth = FlxMath.remapToRange(lastHealth / 50, 0, PlayState.instance.MaxHP, PlayState.instance.minHealth, PlayState.instance.MaxHP);
		}, 60);
		restoreActivated = true;

		FlxG.sound.play(Paths.sound('restoreActivate'));

		var vignetteAppear:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mechanics/mechanicsmod/effects/restoreVignette'));
		vignetteAppear.y = -vignetteAppear.height;
		vignetteAppear.cameras = [PlayState.instance.camOther];
		PlayState.instance.add(vignetteAppear);

		FlxTween.tween(vignetteAppear, {y: 0}, 0.5, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				FlxTween.tween(vignetteAppear, {alpha: 0.0}, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.remove(vignetteAppear);
						vignetteAppear.destroy();
					},
					startDelay: 2.5
				});
			}
		});
	}

	public var restoreNoteGroup:Array<Note> = [];

	public function restoreNoteHit():Void
	{
		FlxG.sound.play(Paths.sound('restoreActivate'), 0.6);

		if (healthTimer != null)
			healthTimer.cancel();
		for (restoreNote in restoreNoteGroup)
		{
			if (PlayState.instance.notes.members.contains(restoreNote))
				PlayState.instance.notes.remove(restoreNote, true);
			if (PlayState.instance.unspawnNotes.contains(restoreNote))
				PlayState.instance.unspawnNotes.remove(restoreNote);
            
            restoreNote.field.removeNote(restoreNote);
		}

		PlayState.instance.notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.noteType == 'Restore Note')
			{
				daNote.noteType = null;

				if (MechanicManager.mechanics['flashlight'].points > 0 && daNote.canBeHit && daNote.mustPress)
					PlayState.instance.goodNoteHit(daNote, daNote.field);
			}
		});

		healthTimer = null;
		PlayState.instance.health = cast lastHealth;
		restoreActivated = false;
	}

    public var noteSwapTweens:Array<FlxTween> = [];
	public var wasSwapped:Bool = false;
	public var swapCooldown:Int = 0;

	public function swapStrums():Void
	{
		if (wasSwapped)
		{
			PlayState.instance.playerStrums.forEachAlive(function(strum:StrumNote)
			{
				@:privateAccess
				{
					strum.positionData = strum.noteData;
				}
				noteSwapTweens.push(FlxTween.tween(strum, {x: strum.formerPosition.x, y: strum.formerPosition.y}, 0.4, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						noteSwapTweens.remove(twn);
					}
				}));
			});

			PlayState.instance.opponentStrums.forEachAlive(function(strum:StrumNote)
			{
				@:privateAccess
				{
					strum.positionData = strum.noteData;
				}
				noteSwapTweens.push(FlxTween.tween(strum, {x: strum.formerPosition.x, y: strum.formerPosition.y}, 0.4, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						noteSwapTweens.remove(twn);
					}
				}));
			});
			swapCooldown = FlxG.random.int(2, 8);
			wasSwapped = !wasSwapped;
			return;
		}

		var chosenStrum:Int = FlxG.random.int(0, 3);
		var tweenToStrum:Int = FlxG.random.int(0, 3, [chosenStrum]);

		PlayState.instance.playerStrums.members[chosenStrum].positionData = tweenToStrum;
		PlayState.instance.playerStrums.members[tweenToStrum].positionData = chosenStrum;

		noteSwapTweens.push(FlxTween.tween(PlayState.instance.playerStrums.members[chosenStrum],
			{x: PlayState.instance.playerStrums.members[tweenToStrum].formerPosition.x, y: PlayState.instance.playerStrums.members[tweenToStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));
		noteSwapTweens.push(FlxTween.tween(PlayState.instance.playerStrums.members[tweenToStrum],
			{x: PlayState.instance.playerStrums.members[chosenStrum].formerPosition.x, y: PlayState.instance.playerStrums.members[chosenStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));

		PlayState.instance.opponentStrums.members[chosenStrum].positionData = tweenToStrum;
		PlayState.instance.opponentStrums.members[tweenToStrum].positionData = chosenStrum;

		noteSwapTweens.push(FlxTween.tween(PlayState.instance.opponentStrums.members[chosenStrum],
			{x: PlayState.instance.opponentStrums.members[tweenToStrum].formerPosition.x, y: PlayState.instance.opponentStrums.members[tweenToStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));
		noteSwapTweens.push(FlxTween.tween(PlayState.instance.opponentStrums.members[tweenToStrum],
			{x: PlayState.instance.opponentStrums.members[chosenStrum].formerPosition.x, y: PlayState.instance.opponentStrums.members[chosenStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));

		swapCooldown = FlxG.random.int(4, 12);

		wasSwapped = !wasSwapped;
	}

	public var dodgeTimers:Array<FlxTimer> = [];
	public var canDodge:Bool = false;
	public var dodgeTimer:Float = 0;
	public var failedDodges:Int = 0;
	public var failedTotalDodges:Int = 0;
	public var dodgeWant:Float = 0;
	public var dodgeInput:Bool = false;
	public var dodged:Bool = false;
	public var forceDodge:Int = 16;

	// dodging is based on reaction time, frequency really isn't the main focus here
	public var dodgeSound:FlxSound = null;

	public function doDodge():Void
	{
		var formerFocus:String = PlayState.instance.whosTurn;
		var dodgeWindowTime:Float = FlxMath.remapToRange(MechanicManager.mechanics['dodging'].points, 0, 20, 2.5, 1);
		// originally 0.25 seconds to the max, but i nerfed it because it was faster than the human reaction time

		PlayState.instance.moveCamera(false);

		dodgeSound = FlxG.sound.load(Paths.soundRandom('dodgeStart', 0, 2));
		FlxG.sound.list.add(dodgeSound);
		dodgeSound.play();

		PlayState.instance.dodgeFog.alpha = 1;
		new FlxTimer().start(dodgeWindowTime + 2, function(tmr:FlxTimer)
		{
			PlayState.instance.dodgeFog.alpha = 0;
		});

		dodgeInput = true;
		dodgeTimers.push(new FlxTimer().start(dodgeWindowTime, function(tmr:FlxTimer)
		{
			if (dodged)
			{
				dodgeSound.play(true);
				failedDodges = 0;
			}
			else
			{
				failedDodge();
				if (++failedTotalDodges >= 3 || FlxG.save.data.firstTimeDodging == null)
				{
					FlxG.save.data.firstTimeDodging = true;
					failedTotalDodges = 0;

					FlxTween.tween(PlayState.instance.dodgeText, {alpha: 1}, 0.2, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							FlxTween.tween(PlayState.instance.dodgeText, {alpha: 0}, 0.5, {
								ease: FlxEase.quadOut,
								startDelay: 3
							});
						}
					});
				}
			}

			resetDodgeValues();
			FlxG.sound.list.remove(dodgeSound);
			PlayState.instance.moveCamera((formerFocus == 'dad' ? true : false));
		}));
	}

	public function resetDodgeValues():Void
	{
		dodgeTimers = [];
		dodgeInput = false;
		canDodge = false;

		PlayState.instance.dodgeFog.alpha = 0;

		dodgeTimer = 0;
		dodgeWant = FlxG.random.float(6, 18);
	}

	public function failedDodge():Void
	{
		PlayState.instance.noTriggerKarma = true;
		if (PlayState.instance.health < 0.4)
			PlayState.instance.die();
		else
			PlayState.instance.health /= 2;
		failedDodges++;
		PlayState.instance.noTriggerKarma = false;
		FlxTween.color(PlayState.instance.iconP1, 0.3, 0xFFFF0000, 0xFFFFFFFF, {ease: FlxEase.cubeOut});

		if (PlayState.instance.mechanicsResult[11] != null)
			PlayState.instance.mechanicsResult[11].value += 1;
	}
    
    public var ghostCursor:FlxSprite;
	public var cursorValue:Float = 0;
	public var cursorTimer:FlxTimer;
	public var cpuPos:FlxPoint = FlxPoint.get();

	public function fakeCursor():Void
	{
		ghostCursor = new FlxSprite().loadGraphic(Paths.image('mechanics/mechanicsmod/cursors/ghostCursor'));
		ghostCursor.scrollFactor.set();
		ghostCursor.antialiasing = ClientPrefs.data.antialiasing;
		ghostCursor.alpha = 0.6;
		ghostCursor.screenCenter();
		ghostCursor.cameras = [PlayState.instance.camOther];
		PlayState.instance.add(ghostCursor);

		cpuPos.set(FlxG.random.float(FlxG.width * 0.2, FlxG.width * 0.8), FlxG.random.float(FlxG.height * 0.2, FlxG.height * 0.8));

		PlayState.instance.mouseCursor.visible = true;

		FlxTween.tween(ghostCursor, {alpha: 0.35}, 0.5, {ease: FlxEase.quadOut});

		cursorTimer = new FlxTimer().start(Math.max(FlxMath.remapToRange(MechanicManager.mechanics['mouse_follower'].points, 1, 20, 3, 1), 0.002),
			function(tmr:FlxTimer)
			{
				var lerpValue:Float = 1 + (FlxG.elapsed * 3.7) * 2.5;

				FlxVelocity.moveTowardsObject(ghostCursor, PlayState.instance.mouseCursor, 175 * lerpValue, 0);

				if (FlxMath.distanceBetween(ghostCursor, PlayState.instance.mouseCursor) < 48)
				{
					ghostCursor.velocity.set();
					FlxTween.tween(ghostCursor, {x: PlayState.instance.mouseCursor.x, y: PlayState.instance.mouseCursor.y}, 0.25);
				}
				else
				{
					new FlxTimer().start(0.25, function(tmr:FlxTimer)
					{
						ghostCursor.velocity.set();
					});
				}
			}, 0);
	}

	public var timeActivated:Bool = false;
	public var timeBlockGroup:FlxSpriteGroup;
	public var timeBox:FlxSprite;
	public var overlapBox:FlxSprite;
	public var timeClickText:FlxText;
	public var timeNeed:Float = 0;
	public var timeSine:Float = 0;
	public var timeDisabled:Bool = false;
	public var timeAttempts:Int = 0;
	public var maximumAttempts:Int = 2;
	public var offsetPos:FlxPoint = FlxPoint.get();
	public var grabbedTime:Bool = false;
	public var timeTweenIsActive:Bool = false;

	public function updateTimeMechanic()
	{
		if (timeBlockGroup == null || timeDisabled)
			return;

		if (Conductor.songPosition - 1500 >= timeNeed) // +0.5 sec for pacifist
		{
			changeTime(2.5);
			timeAttempts++;
			changeMorale(0.9);
			if (PlayState.instance.mechanicsResult[15] != null)
				PlayState.instance.mechanicsResult[15].value += 1;
		}

		var wantedColor = FlxColor.BLACK;

		timeBox.setGraphicSize(Std.int(timeClickText.width + 8), Std.int(timeClickText.height + 8));
		timeBox.updateHitbox();
		timeBox.setPosition(timeBlockGroup.x, timeBlockGroup.y);

		overlapBox.setGraphicSize(Std.int(timeClickText.width + 8), Std.int(timeClickText.height + 8));
		overlapBox.updateHitbox();
		overlapBox.setPosition(timeBlockGroup.x, timeBlockGroup.y);

		timeClickText.setPosition(timeBlockGroup.x + 4, timeBlockGroup.y + 4);

		timeSine += FlxG.elapsed * 2.5;
		overlapBox.alpha = FlxMath.remapToRange(1 - Math.sin((Math.PI * timeSine)), 0, 1, 0.2, 0.8);

		var lastPosition = PlayState.instance.mouseCursor.getPosition();
		if (PlayState.instance?.cpuControlled)
		{
			if (Math.abs(Conductor.songPosition - timeNeed) < 1800 && !timeTweenIsActive) // allow a larger range
			{
				timeTweenIsActive = true;
				FlxTween.tween(PlayState.instance.mouseCursor, {x: timeBlockGroup.x + (overlapBox.width / 2), y: timeBlockGroup.y + (overlapBox.height / 2)}, 0.5, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(PlayState.instance.mouseCursor, {x: lastPosition.x, y: lastPosition.y}, 0.5, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								new FlxTimer().start(0.25, function(tmr:FlxTimer)
								{
									timeTweenIsActive = false;
								});
							}
						});
					}
				});
				changeTime(2.23);
			}
		}

		var keyPress:Bool = Controls.instance.justPressed('accept');

		var pos = !PlayState.instance.cpuControlled ? FlxG.mouse.getScreenPosition(PlayState.instance.camOther) : lastPosition;

		var wantX:Bool = (pos.x >= timeBox.x && pos.x <= timeBox.x + timeBox.width);
		var wantY:Bool = (pos.y >= timeBox.y && pos.y <= timeBox.y + timeBox.height);

		if ((overlapBox.visible = (wantX && wantY) || keyPress) || grabbedTime)
		{
			if (grabbedTime = FlxG.mouse.pressedMiddle && !PlayState.instance.cpuControlled)
			{
				if (FlxG.mouse.justPressedMiddle)
					offsetPos.set(pos.x - timeBlockGroup.x, pos.y - timeBlockGroup.y);

				timeBlockGroup.setPosition(CoolUtil.boundTo(Math.round(pos.x - offsetPos.x), 0, FlxG.width - timeBlockGroup.width),
					CoolUtil.boundTo(Math.round(pos.y - offsetPos.y), 0, FlxG.height - timeBlockGroup.height));
			}

			if ((FlxG.mouse.justPressed || keyPress) || (PlayState.instance.cpuControlled && Math.abs(Conductor.songPosition - timeNeed) < 1750))
			{
				var curTime:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;
				if (curTime < 0)
					curTime = 0;

				var songCalc:Float = (PlayState.instance.songLength - curTime);
				if (ClientPrefs.data.timeBarType == 'Time Elapsed')
					songCalc = curTime;

				var secondsTotal:Int = Math.floor(songCalc / 1000);
				if (secondsTotal < 0)
					secondsTotal = 0;

				if (Math.abs(Conductor.songPosition - timeNeed) < 1750) // allow a larger range
				{
					changeTime(2.23);
					changeMorale(1.025);
				}
				else
				{
					timeAttempts++;
					changeTime(1.5);
					changeMorale(0.8);

					if (PlayState.instance.mechanicsResult[15] != null)
						PlayState.instance.mechanicsResult[15].value += 1;
				}
			}

			if (!FlxG.mouse.pressedMiddle)
			{
				grabbedTime = false;
				offsetPos.set();
			}
		}

		if (Math.abs(Conductor.songPosition - timeNeed) < 1750)
			wantedColor = FlxColor.RED;

		timeBox.color = FlxColor.interpolate(timeBox.color, wantedColor, CoolUtil.boundTo(FlxG.elapsed * 27, 0, 1));
	}

	public function clickTime()
	{
		timeActivated = true;

		timeBlockGroup = new FlxSpriteGroup(FlxG.random.float(FlxG.width * 0.2, FlxG.width * 0.8), FlxG.random.float(FlxG.height * 0.2, FlxG.height * 0.8));
		timeBlockGroup.cameras = [PlayState.instance.camOther];

		if (PlayState.instance.mouseCursor != null)
			PlayState.instance.remove(PlayState.instance.mouseCursor);

		PlayState.instance.add(timeBlockGroup);

		if (PlayState.instance.mouseCursor != null)
			PlayState.instance.add(PlayState.instance.mouseCursor);

		timeBox = new FlxSprite().makeGraphic(60, 40, FlxColor.BLACK);
		timeBox.alpha = 0;
		timeBlockGroup.add(timeBox);

		overlapBox = new FlxSprite().makeGraphic(60, 40, FlxColor.WHITE);
		overlapBox.visible = false;
		timeBlockGroup.add(overlapBox);

		timeClickText = new FlxText(4, 4, 0, '', 24);
		timeClickText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeClickText.borderSize = 1.5;
		timeClickText.alpha = 0;
		timeBlockGroup.add(timeClickText);

		FlxTween.tween(timeBox, {alpha: 0.4}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(timeClickText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});

		maximumAttempts = Math.ceil(CoolUtil.boundTo(PlayState.instance.songLength / 100000, 4, 10) + 2);

		changeTime();
	}

	public function changeTime(multi:Float = 1)
	{
		var random:Float = FlxG.random.float(1, 3);
		random += FlxMath.remapToRange(MechanicManager.mechanics['click_time'].points, 0, 20, 5, 1);
		random *= multi;
		timeNeed += FlxG.random.float(Conductor.crochet * random * 3, Conductor.crochet * random * 8);
		if (timeNeed >= PlayState.instance.songLength)
		{
			timeDisabled = true;
			FlxTween.tween(timeBox, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});
			FlxTween.tween(timeClickText, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});
			FlxTween.tween(overlapBox, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});
		}

		timeNeed = Math.min(timeNeed, PlayState.instance.songLength);

		var calcTime:Float = PlayState.instance.songLength - timeNeed;
		if (ClientPrefs.data.timeBarType == 'Time Elapsed')
			calcTime = timeNeed;
		timeClickText.text = FlxStringUtil.formatTime(Math.floor(calcTime / 1000), false);

		PlayState.instance.noTriggerKarma = true;
		if (timeAttempts >= maximumAttempts)
		{
			// dont accidentally trigger it
			timeBlockGroup.setPosition(9999999, -9999999);
			PlayState.instance.die();
		}
		PlayState.instance.noTriggerKarma = false;
	}

	public var moraleActivated:Bool = false;
	public var moraleValue:Float = 20;
	public var moraleLerp:Float = 20;
	public var maxMoraleValue:Float = 35;
	public var badMoraleMulti:Float = 0.7;
	public var goodMoraleMulti:Float = 1;
	public var moraleBar:Bar;
	public var moraleTitle:FlxSprite;

	public function activateMorale()
	{
		moraleActivated = true;

		moraleBar = new Bar(87, 187, 'mechanics/mechanicsmod/ui/moraleBar', function() return moraleLerp, 0, maxMoraleValue);
		moraleBar.scrollFactor.set();
		moraleBar.cameras = [PlayState.instance.camHUD];
		moraleBar.antialiasing = ClientPrefs.data.antialiasing;
		moraleBar.alpha = 0;

		moraleBar.setColors(FlxColor.fromInt(0xFFFFFFFF), FlxColor.fromInt(0xFF8400FF));
		PlayState.instance.add(moraleBar);

		FlxTween.tween(moraleBar, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
	}

	public function updateMorale()
	{
		moraleLerp = FlxMath.lerp(moraleLerp, moraleValue, CoolUtil.boundTo(FlxG.elapsed * 3.775, 0, 1));

		moraleValue = CoolUtil.boundTo(moraleValue, -1, maxMoraleValue);
		if (moraleValue <= 0)
		{
			PlayState.instance.die();
		}
	}

	public function changeMorale(mod:Float = 1)
	{
		if (mod == 1 && !moraleActivated)
			return;

		if (mod > 1)
		{
			goodMoraleMulti += ((mod * 0.07) / MechanicManager.mechanics['morale'].points) / 48.0;
			badMoraleMulti -= ((mod * 0.07) * FlxMath.remapToRange(MechanicManager.mechanics['morale'].points, 0, 20, 0, 7.5)) / 48.0;
		}
		else if (mod < 1)
		{
			goodMoraleMulti -= ((mod * 0.07) * FlxMath.remapToRange(MechanicManager.mechanics['morale'].points, 0, 20, 0, 7.5)) / 24.0;
			badMoraleMulti += ((mod * 0.07) / MechanicManager.mechanics['morale'].points) / 12.0;
		}

		goodMoraleMulti = CoolUtil.boundTo(goodMoraleMulti, 0.7, 8);
		badMoraleMulti = CoolUtil.boundTo(badMoraleMulti, 1, 240);

		if (mod > 1)
			moraleValue += (mod * goodMoraleMulti) * 0.3;
		else
		{
			var lastMoraleValue:Float = moraleValue;

			moraleValue -= ((1 + mod) * badMoraleMulti) * 0.4;

			if (PlayState.instance.mechanicsResult[17] != null)
				PlayState.instance.mechanicsResult[17].value += Math.abs(moraleValue - lastMoraleValue);
		}
	}

	public var currentLetter:String = '';
	public var wantedLetter:String = '';
	public var atChance:Float = 10;
	public var letterTime:Float = 20;
	public var allowTime:Bool = true;
	public var failedTimes:Int = 0;

	public function letterMechanic():Void
	{
		if (MechanicManager.mechanics['letter_placement'].points > 0 && allowTime)
		{
			if (FlxG.random.bool(atChance))
			{
				atChance = 10;

				currentLetter = '';
				wantedLetter = KeyboardMechanic.generateLetter(MechanicManager.mechanics['letter_placement'].points * FlxG.random.float(2, 4),
					Math.floor(FlxMath.remapToRange(MechanicManager.mechanics['letter_placement'].points, 0, 20, 4, 7)));

				letterTime = FlxG.random.float(20, 30);

				createLetterMechanic();
			}
			else
				atChance += FlxG.random.float(MechanicManager.mechanics['letter_placement'].points / 20,
					MechanicManager.mechanics['letter_placement'].points / 10) / (Conductor.bpm / 100);
		}
	}

	public var letterMechanicGroup:FlxTypedGroup<FlxObject>;
	public var letterVignetteSprite:FlxSprite;
	public var letterVignetteTime:FlxText;
	public var letterVignetteText:Array<Alphabet> = [];

	public function createLetterMechanic():Void
	{
		letterMechanicActive = true;

		letterVignetteSprite = new FlxSprite().loadGraphic(Paths.image('mechanics/mechanicsmod/effects/keyboardVignette'));
		letterVignetteSprite.antialiasing = ClientPrefs.data.antialiasing;
		letterVignetteSprite.alpha = 0.0;
		letterVignetteSprite.cameras = [PlayState.instance.camOther];
		letterMechanicGroup.add(letterVignetteSprite);

		letterVignetteTime = new FlxText(0, 0, 0, "", 32);
		letterVignetteTime.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		letterVignetteTime.borderSize = 2;
		letterVignetteTime.antialiasing = ClientPrefs.data.antialiasing;
		letterVignetteTime.alpha = 0.0;
		letterVignetteTime.screenCenter();
		letterVignetteTime.cameras = [PlayState.instance.camOther];
		letterMechanicGroup.add(letterVignetteTime);

		for (i in 0...wantedLetter.length)
		{
			var letterText:Alphabet = new Alphabet(0, 0, wantedLetter.charAt(i), true);
			letterText.screenCenter();
			letterText.y = FlxG.height * 0.7;
			letterText.x += (100 * (i - (wantedLetter.length / 2))) + 50;
			letterText.ID = i;
			letterText.cameras = [PlayState.instance.camOther];
			letterVignetteText.push(letterText);
			letterMechanicGroup.add(letterText);
		}

		FlxTween.num(0.0, 1.0, 0.9, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				allowUpdate = true;
			}
		}, function(value:Float)
		{
			letterVignetteSprite.alpha = value;
			letterVignetteTime.alpha = value;
			for (mem in letterVignetteText)
			{
				mem.alpha = value;
			}
		});

		allowTime = false;
	}

	public var letterMechanicActive:Bool = false;
	public var allowUpdate:Bool = false;
	public var letterBotplayTime:Float = 0;

	public function updateLetterMechanic():Void
	{
		if (letterMechanicActive && allowUpdate)
		{
			letterTime -= FlxG.elapsed;
			letterBotplayTime += FlxG.elapsed;

			var fromColor:{r:Int, g:Int, b:Int} = {r: 255, g: 255, b: 255};
			var toColor:{r:Int, g:Int, b:Int} = {r: 255, b: 0, g: 0};
			var ratio:Float = FlxMath.remapToRange(letterTime, 30, 0, 0, 1);

			var convertColors:{r:Int, g:Int, b:Int} -> FlxColor = function(color)
			{
				return FlxColor.fromRGB(color.r, color.g, color.b, Math.floor(letterVignetteTime.alpha * 255));
			}

			letterVignetteTime.color = convertColors({
				r: FlxColor.interpolate(fromColor.r, toColor.r, ratio),
				g: FlxColor.interpolate(fromColor.g, toColor.g, ratio),
				b: FlxColor.interpolate(fromColor.b, toColor.b, ratio),
			});

			letterVignetteTime.text = '' + Math.floor(Math.max(letterTime, 0));

			if (!PlayState.instance.cpuControlled)
			{
				if (String.fromCharCode(FlxG.keys.firstJustPressed()).toLowerCase() == wantedLetter.charAt(currentLetter.length).toLowerCase())
				{
					currentLetter += String.fromCharCode(FlxG.keys.firstJustPressed()).toLowerCase();
				}
			}
			else
			{
				while (letterBotplayTime >= 0.2)
				{
					letterBotplayTime -= 0.2;
					if (wantedLetter.length >= 18)
					{
						for (i in 0...FlxG.random.int(2, 4))
						{
							if (currentLetter.length >= wantedLetter.length)
								break;
							currentLetter += wantedLetter.charAt(currentLetter.length).toLowerCase();
						}
					}
					else
					{
						currentLetter += wantedLetter.charAt(currentLetter.length).toLowerCase();
					}
				}
			}

			for (i in 0...currentLetter.length)
			{
				letterVignetteText[i].alpha = 0.6;
			}

			if (letterTime <= 0)
			{
				allowUpdate = false;

				letterFinishMechanic();

				if (++failedTimes >= 5)
					PlayState.instance.doDeathCheck(true);

				if (PlayState.instance.mechanicsResult[21] != null)
					PlayState.instance.mechanicsResult[21].value = failedTimes;
			}
			else if (currentLetter.toLowerCase() == wantedLetter.toLowerCase())
			{
				allowUpdate = false;
				letterFinishMechanic();
			}
		}
	}

	public function letterFinishMechanic():Void
	{
		FlxTween.num(1.0, 0.0, 0.9, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				letterMechanicGroup.remove(letterVignetteSprite);
				letterMechanicGroup.remove(letterVignetteTime);

				letterVignetteSprite.destroy();
				letterVignetteTime.destroy();

				for (mem in letterVignetteText)
				{
					letterVignetteText.remove(mem);
					letterMechanicGroup.remove(mem);

					mem.destroy();
				}

				FlxArrayUtil.clearArray(letterVignetteText);

				letterMechanicActive = false;
				new FlxTimer().start(5, function(tmr:FlxTimer)
				{
					allowTime = true;
				});
			}
		}, function(value:Float)
		{
			letterVignetteSprite.alpha = value;
			letterVignetteTime.alpha = value;
			for (mem in letterVignetteText)
			{
				mem.alpha = value * 0.6;
			}
		});
	}

	public var chosenMechanic:String = '';

	// luck mechanic does not affect score multiplier
	public function luckMechanic():Void
	{
		if (MechanicManager.mechanics['luck'].points > 0)
		{
			var listedMechanics:Array<String> = [];
			for (mechanic in MechanicManager.mechanics.keys())
			{
				if (mechanic != 'luck')
					listedMechanics.push(mechanic);
			}

			chosenMechanic = FlxG.random.getObject(listedMechanics);

			MechanicManager.mechanics[chosenMechanic].points += Std.int(MechanicManager.mechanics['luck'].points / 2);
		}
	}

	public function luckMechanicDestroy():Void
	{
		if (MechanicManager.mechanics['luck'].points > 0)
		{
			MechanicManager.mechanics[chosenMechanic].points -= Std.int(MechanicManager.mechanics['luck'].points / 2);
		}
	}

	public var rpsList:Map<String, {name:String, destroys:Array<String>, id:Int}> = [
		'rock' => {name: 'rock', destroys: ['scissors'], id: 0},
		'paper' => {name: 'paper', destroys: ['rock'], id: 1},
		'scissors' => {name: 'scissors', destroys: ['paper'], id: 2}
	];

	public var rpsSelect:Int = 0;
	public var rpsGroup:FlxTypedGroup<FlxSprite>;

	public function createRPS():Void
	{
		rpsGroup = new FlxTypedGroup<FlxSprite>();
		rpsGroup.memberAdded.add(function(sprite:FlxSprite)
		{
			sprite.cameras = [PlayState.instance.camOther];
		});
		PlayState.instance.add(rpsGroup);
	}
}