package stages;

import backend.FunkinSound;
import backend.pslice.ScaleMode;
import cutscenes.CutsceneHandler;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.misc.ColorTween;
import objects.Character.CharType;
import objects.Character;
import objects.FlxAtlasSprite;
import objects.FunkinSprite;
import shaders.DropShadowShader;
import shaders.SserafimShader;
import stages.objects.*;
import stages.objects.PerspectiveSprite;

class SserafimStage extends BaseStage
{
  var baseVisible:Array<Bool> = [true, false, false, false, false, false];
  var baseSinging:Array<Bool> = [false, false, false, false, false, false];

  // CHARACTERS
  var yunjin:Character;
  var chaewon:Character;
  var eunchae:Character;

  // VFX/SHADERS
  var characterShader:SserafimShader;
  var stageShader:SserafimShader;

  // SPRITES
  var perspectiveFloor:PerspectiveSprite = null;

  // CUTSCENE SHIT
  var hasPlayedCutscene:Bool;

  var SEEYOU1:FlxSprite;
  var SEEYOU2:FlxSprite;

  override function destroy()
  {
    hasPlayedCutscene = false;
    super.destroy();
  }

  var dust1:FlxBackdrop;
  var dust2:FlxBackdrop;
  var dust3:FlxBackdrop;
  var dust4:FlxBackdrop;

  override function create()
  {
    hasPlayedCutscene = seenCutscene;
    cutsceneSkipped = seenCutscene;
    canSkipCutscene = false;
    cutsceneHandler = null;

    super.create();
  }

  override function createPost() {
    game.camZooming = true; //So that the camera works lol
    setStartCallback(doCutsceneStuff);
    super.createPost();
    characterShader = new SserafimShader(true);
    stageShader = new SserafimShader();

    perspectiveFloor = new PerspectiveSprite(false);
    perspectiveFloor.sprite.loadGraphic(Paths.image('floor'));
    perspectiveFloor.setPositions(760, 1375, 790, 625);
    perspectiveFloor.setScrollFactors(1.05, 1.05, 0.93, 0.93);
    perspectiveFloor.shader = stageShader;
    add(perspectiveFloor);

    dust1 = new FlxBackdrop(Paths.image('dust/dustMid'), 0x01);
    dust1.setPosition(-650, -200);
    dust1.scrollFactor.set(1.1, 1.1);
    dust1.scale.set(1.5, 1.5);
    dust1.zIndex = 2000;
    dust1.alpha = 0.8;
    dust1.velocity.x = 350;
    dust1.shader = stageShader;

    dust2 = new FlxBackdrop(Paths.image('dust/dustBack'), 0x01);
    dust2.setPosition(-650, -250);
    dust2.scrollFactor.set(1.15, 1.15);
    dust2.scale.set(1.5, 1.5);
    dust2.zIndex = 2000;
    dust2.alpha = 0.9;
    dust2.velocity.x = -300;
    dust2.shader = stageShader;

    dust3 = new FlxBackdrop(Paths.image('dust/dustMid'), 0x01);
    dust3.setPosition(-650, -400);
    dust3.scrollFactor.set(1.2, 1.2);
    dust3.scale.set(2, 2);
    dust3.zIndex = 2000;
    dust3.alpha = 0.8;
    dust3.velocity.x = -200;
    dust3.shader = stageShader;

    dust4 = new FlxBackdrop(Paths.image('dust/dustBack'), 0x01);
    dust4.setPosition(-650, -1300);
    dust4.scrollFactor.set(1.25, 1.25);
    dust4.scale.set(3.5, 3.5);
    dust4.zIndex = 2000;
    dust4.alpha = 0.9;
    dust4.velocity.x = -150;
    dust4.shader = stageShader;

    game.addAbove(getStageObject("solidCover"), dust1);
    game.addAbove(getStageObject("solidCover"), dust2);
    game.addAbove(getStageObject("solidCover"), dust3);
    game.addAbove(getStageObject("solidCover"), dust4);

    dust1.color = 0xff98847d;
    dust2.color = 0xff8b6c63;
    dust3.color = 0xff6e645c;
    dust4.color = 0xff886a60;

    yunjin = new Character(0, 0, 'sserafim-yunjin', false, OTHER);
    chaewon = new Character(0, 0, 'sserafim-chaewon', false, OTHER);
    eunchae = new Character(0, 0, 'sserafim-eunchae', false, OTHER);

    game.dadGroup2.add(yunjin);
    game.gfGroup.add(chaewon);
    game.dadGroup2.add(eunchae);

    yunjin.scrollFactor.set(0.95, 0.95);
    chaewon.scrollFactor.set(0.95, 0.95);
    eunchae.scrollFactor.set(0.97, 0.97);

    yunjin.setPosition(-621 - yunjin.characterOrigin.x, 154 - yunjin.characterOrigin.y);
    chaewon.setPosition(687 - chaewon.characterOrigin.x, 98 - chaewon.characterOrigin.y);
    eunchae.setPosition(770 - eunchae.characterOrigin.x, 675 - eunchae.characterOrigin.y);

    setGirlsVisible(baseVisible);
    setGirlsSinging(baseSinging);
    setLightState(false);

    perspectiveFloor.sprite.shader = stageShader;
    yunjin.shader = characterShader;
    chaewon.shader = characterShader;
    eunchae.shader = characterShader;

    createCutsceneSprites();

    for (character in [game.boyfriend, game.gf, game.dad, yunjin, chaewon, eunchae]) {
      var targetIndex:Int = 0;
      switch (character.curCharacter)
      {
        case 'sserafim-yunjin':
          targetIndex = 0;
        case 'sserafim-kazuha':
          targetIndex = 1;
        case 'sserafim-chaewon':
          targetIndex = 2;
        case 'sserafim-eunchae':
          targetIndex = 3;
        case 'sserafim-sakura':
          targetIndex = 4;
        case 'sserafim-gf':
          targetIndex = 5;
        default:
      }

      character.charType = baseSinging[targetIndex] ? CharType.BF : CharType.DAD;
      character.visible = baseVisible[targetIndex];

      character.shader = characterShader;
    }
  }

  function hideOpponentStrumline()
  {
    game.modManager.setValue('alpha', 1, 1);
  }

  /**
   * Called when the chart hits a song event.
   */
  override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
  {
    switch (eventName)
    {
      case 'sserafimShow':
        setGirlsVisible(parseBoolArray(value1));
      case 'sserafimSing':
        setGirlsSinging(parseBoolArray(value1));
      case 'sserafimDark':
        setDarkenAmt(Std.parseFloat(value1), Std.parseFloat(value2));
      case 'sserafimLights':
        flashTruckLights(Std.parseFloat(value1), Std.parseFloat(value2));
      case 'sserafimCover':
        setCoverVisible(parseBool(value1));
      case 'sserafimFlash':
        flashScreen(Std.parseFloat(value1));
      case 'sserafimPulseLights':
        var threekings:Array<String> = value1.replace('[', '').replace(']', '').split(',');
        var throneDur:Array<Float> = [];
        var kingInt:Array<Float> = [];
        for (king in 0...threekings.length) {
          throneDur.push(Conductor.stepCrochet*0.001*8);
          kingInt.push(0.6);
        }
        setLightState(parseBool(value2), threekings, throneDur, kingInt);
      case 'sserafimKick':
        if (parseBool(value1))
        {
          // play second kick anim + reset her idle back to normal
          yunjin.playAnim('yunjin intro', true, false);
          FunkinSound.playOnce('doorKick2', 1.0);
          yunjin.danceEveryNumBeats = 1;

          // Show the opponent health icon at this point
          game.iconP2.visible = true;

          // hide the cutscene characters if theyre present!
          if (sserafimGf != null)
          {
            // and show the REAL gf
            game.gf.visible = true;

            sserafimGf.visible = false;
            sserafimBf.visible = false;
          }

          yunjin.animation.onFrameChange.removeAll();

          yunjin.animation.onFrameChange.add(function(animName:String, frameNumber:Int, index:Int) {
            // at this point in the animation, the door is no longer part of her animation...
            // show a static one!
            if (frameNumber == 23) game.getLuaObject('truckDoor').visible = true;
          });

          yunjin.animation.onFinish.addOnce(function(animName:String) {
            yunjin.animation.onFrameChange.removeAll();
          });

          // start the dust clearing
          startClear();
        }
        else
        {
          // play first kick anim
          yunjin.playAnim('yunjin intro', true, false);
          FunkinSound.playOnce('doorKick1', 1.0);
        }
        case 'sserafimEnd':
          endStuff();
      }

    super.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime);
  }

  function parseBoolArray(value:String):Array<Bool> {
    var sArr:Array<String> = value.replace('[', '').replace(']', '').trim().split(',');
    var bArr:Array<Bool> = [];
    for (b in sArr)
      bArr.push(b.toLowerCase() == "true" ? true : false);
    return bArr;
  }

  function parseFloatArray(value:Array<String>):Array<Float> {
    var sArr:Array<String> = value;
    var fArr:Array<Float> = [];
    for (f in sArr)
      fArr.push(Std.parseFloat(f));
    return fArr;
  }

  function parseBool(value:String):Bool {
    return value.trim().toLowerCase() == "true" ? true : false;
  }

  function flashScreen(duration:Float)
  {
    camGame.flash(0xFFFFFFFF, duration);
  }

  function setCoverVisible(visible:Bool)
  {
    getStageObject('solidCover').alpha = visible ? 1.0 : 0.0;
  }

  function setGirlsVisible(visibleArray:Array<Bool>)
  {
    if (visibleArray.length < 5) return;

    yunjin.visible = visibleArray[0];

    game.dad.visible = visibleArray[1];

    chaewon.visible = visibleArray[2];
    eunchae.visible = visibleArray[3];

    game.boyfriend.visible = visibleArray[4];

    // gf visibility ISNT stored here, cause itd break a lot of stuff already in place and im kinda running out of time
  }

  function setGirlsSinging(singingArray:Array<Bool>)
  {
    if (singingArray.length < 5) return;

    yunjin.charType = singingArray[0] ? CharType.BF : CharType.DAD;

    dad.charType = singingArray[1] ? CharType.BF : CharType.DAD;

    chaewon.charType = singingArray[2] ? CharType.BF : CharType.DAD;
    eunchae.charType = singingArray[3] ? CharType.BF : CharType.DAD;

    boyfriend.charType = singingArray[4] ? CharType.BF : CharType.DAD;

    gf.charType = singingArray[5] ? CharType.BF : CharType.DAD;
  }

  var hasHidden = false;

  function setDarkenAmt(darkAmt:Float, duration:Float)
  {
    FlxTween.cancelTweensOf(characterShader);
    FlxTween.cancelTweensOf(stageShader);

    FlxTween.tween(characterShader, {darkenAmount: darkAmt}, duration, {ease: FlxEase.sineInOut});
    FlxTween.tween(stageShader, {darkenAmount: darkAmt}, duration, {ease: FlxEase.sineInOut});
  }

  function flashTruckLights(amount:Float, duration:Float):Void
  {
    FlxTween.cancelTweensOf(getStageObject('truckLight1'));
    FlxTween.cancelTweensOf(getStageObject('truckLight2'));

    getStageObject('truckLight1').alpha = amount;
    getStageObject('truckLight2').alpha = amount;

    characterShader.truckLightStrength = amount;
    stageShader.truckLightStrength = amount;

    FlxTween.tween(getStageObject('truckLight1'), {alpha: 0}, duration,
    {
      ease: FlxEase.cubeInOut,
      onUpdate: function(tween:FlxTween) {
        characterShader.truckLightStrength = getStageObject('truckLight1').alpha;
        stageShader.truckLightStrength = getStageObject('truckLight1').alpha;
      },
      onComplete: function(tween:FlxTween) {
        characterShader.truckLightStrength = 0;
        stageShader.truckLightStrength = 0;
      }
    });
    FlxTween.tween(getStageObject('truckLight2'), {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
  }

  var lightsColors:Array<FlxColor> = [];
  var lightsDurations:Array<Float> = [];
  var lightsIntensities:Array<Float> = [];
  var lightsEnabled:Bool = false;

  function setLightState(enabled:Bool = false, ?colors:Array<String>, ?durations:Array<Float>, ?intensities:Array<Float>)
  {
    lightsEnabled = enabled;
    if (colors == null || durations == null || intensities == null) return;

    lightsColors = [for (i in 0...colors.length) FlxColor.fromString(colors[i])];
    lightsDurations = durations;
    lightsIntensities = intensities;
  }

  function flashBackLight(amount:Float, duration:Float, color:FlxColor)
  {
    FlxTween.cancelTweensOf(getStageObject('backLightColor'));
    FlxTween.cancelTweensOf(getStageObject('backLightWhite'));

    getStageObject('backLightColor').color = color;

    getStageObject('backLightColor').alpha = amount * 0.8;
    getStageObject('backLightWhite').alpha = amount * 0.7;

    characterShader.pulseLightColor = color;
    stageShader.pulseLightColor = color;

    characterShader.pulseLightStrength = getStageObject('backLightColor').alpha;
    stageShader.pulseLightStrength = getStageObject('backLightColor').alpha;

    FlxTween.tween(getStageObject('backLightColor'), {alpha: 0}, duration,
      {
        ease: FlxEase.cubeInOut,
        onUpdate: function(tween:FlxTween) {
          characterShader.pulseLightStrength = getStageObject('backLightColor').alpha;
          stageShader.pulseLightStrength = getStageObject('backLightColor').alpha;
        },
        onComplete: function(tween:FlxTween) {
          characterShader.pulseLightStrength = 0;
          stageShader.pulseLightStrength = 0;
        }
      });
    FlxTween.tween(getStageObject('backLightWhite'), {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
  }

  override function beatHit()
  {
    super.beatHit();

    // flash lights behind truck
    if (lightsEnabled) flashBackLight(lightsIntensities[curBeat % lightsIntensities.length], lightsDurations[curBeat % lightsDurations.length],
      lightsColors[curBeat % lightsColors.length]);
    if (chaewon != null && curBeat % Math.round(game.gfSpeed * chaewon.danceEveryNumBeats) == 0 && !chaewon.getAnimationName().startsWith('sing') && !chaewon.stunned)
			chaewon.dance();
    if (yunjin != null && curBeat % Math.round(game.gfSpeed * yunjin.danceEveryNumBeats) == 0 && !yunjin.getAnimationName().startsWith('sing') && !yunjin.stunned)
			yunjin.dance();
    if (eunchae != null && curBeat % Math.round(game.gfSpeed * eunchae.danceEveryNumBeats) == 0 && !eunchae.getAnimationName().startsWith('sing') && !eunchae.stunned)
			eunchae.dance();
  }

  var isMobilePauseButtonPressed:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (!this.hasHidden)
    {
      this.hasHidden = true;
      hideOpponentStrumline();
      if (!isStoryMode)
        game.comboOffsetCustom = [510, 320]; // actual values for if we ever wanna use it
      else
        game.comboOffsetCustom = [9999, -50];
    }

    if (perspectiveFloor != null)
    {
      perspectiveFloor.updateSkew(camGame);
    }

    // i cant bear the weight of deleting you debugShitLol you can stay here just so i can remember how useful you were
    // debugShitLol();
  }

  // ----------------- CUTSCENE LOGIC -----------------
  var sserafimCutscene:SserafimCutsceneSprite;
  var sserafimBf:SserafimBfSprite;
  var sserafimGf:SserafimGfSprite;
  var cutsceneSounds:Null<FunkinSound> = null;

  var cutsceneSkipped:Bool = false;
  var canSkipCutscene:Bool = false;
  var cutsceneHandler:CutsceneHandler;

  public function cancelCutsceneSounds():Void
  {
    if (cutsceneSounds != null) cutsceneSounds.destroy();
  }

  function doCutsceneStuff()
  {
    if (PlayState.chartingMode && !hasPlayedCutscene)
    {
      hasPlayedCutscene = true;
      cutsceneSkipped = true;
      playCutsceneFromRestart();
      startCountdown();
      return;
    }

    if (!hasPlayedCutscene)
    {
      trace('playing in-game cutscene');

      hasPlayedCutscene = true;

      camHUD.visible = false;

      setCutsceneVisibility(true);
      introCutscene();
    }
  }

  // helper function cause i really dont wanna have to manually do this twice
  function setCutsceneVisibility(inCutscene:Bool):Void
  {
    if (inCutscene)
    {
      setGirlsVisible([!inCutscene, !inCutscene, !inCutscene, !inCutscene, !inCutscene]);
    }
    else
    {
      setGirlsVisible(baseVisible);
    }

    getStageObject('truck').visible = !inCutscene;
    getStageObject('truckDoor').visible = false;
    getStageObject('backTables').visible = !inCutscene;
    getStageObject('backStools').visible = !inCutscene;
    getStageObject('frontStool').visible = !inCutscene;
    hideDust(!inCutscene);

    perspectiveFloor.sprite.loadGraphic(Paths.image(inCutscene ? 'cutscene/floor-cutscene' : 'floor'));

    getStageObject('backTablesCutscene').visible = inCutscene;
    getStageObject('burgerCutscene').visible = inCutscene;

    // gf will be hidden at the start + in the cutscene so we can just do this here
    game.gf.visible = false;

    if (sserafimCutscene != null) sserafimCutscene.visible = inCutscene;
  }

  function createCutsceneSprites()
  {
    cutsceneHandler = new CutsceneHandler();
    cutsceneHandler.endTime = 30; // set it here so the cutscene doesn't end immediently

    cutsceneHandler.finishCallback = () ->{
      inCutscene = false;
      startCountdown();
      canPause = true;
      camHUD.visible = true;
    }

    cutsceneHandler.skipCallback = skipCutscene;

    sserafimCutscene = new SserafimCutsceneSprite(0, 0);
    sserafimCutscene.setPosition(-395, 10);
    sserafimCutscene.scrollFactor.set(0.94, 0.94);
    sserafimCutscene.shader = characterShader;
    sserafimCutscene.zIndex = 25;

    sserafimGf = new SserafimGfSprite(0, 0);
    sserafimGf.setPosition(655, -104);
    sserafimGf.scrollFactor.set(0.95, 0.95);
    sserafimGf.shader = characterShader;
    sserafimGf.alpha = 0.5;
    sserafimGf.zIndex = 25;
    sserafimGf.visible = false;

    sserafimBf = new SserafimBfSprite(0, 0);
    sserafimBf.setPosition(1220, 531);
    sserafimBf.scrollFactor.set(0.99, 0.99);
    sserafimBf.shader = characterShader;
    sserafimBf.zIndex = 305;
    sserafimBf.visible = false;

    add(sserafimGf);
    add(sserafimBf);
    add(sserafimCutscene);

    SEEYOU1 = new FlxSprite().loadGraphic(Paths.image('end/end1'));
    SEEYOU1.scale.set(0.67, 0.67);
    SEEYOU1.updateHitbox();
    SEEYOU1.screenCenter();
    SEEYOU1.zIndex = 10000;

    SEEYOU2 = new FlxSprite().loadGraphic(Paths.image('end/end2'));
    SEEYOU2.scale.set(0.67, 0.67);
    SEEYOU2.updateHitbox();
    SEEYOU2.setPosition(FlxG.width - 40 - SEEYOU2.width, FlxG.height - 40 - SEEYOU2.height);
    SEEYOU2.zIndex = 10000;

    add(SEEYOU1);
    add(SEEYOU2);

    SEEYOU1.cameras = [camOther];
    SEEYOU2.cameras = [camOther];

    SEEYOU1.visible = false;
    SEEYOU2.visible = false;
  }

  function endStuff()
  {
    FunkinSound.playOnce('cutscene/end1', 1.0);

    new FlxTimer().start(0.05, function(tmr) {
      SEEYOU1.visible = true;
      getStageObject('solidCover').alpha = 1;
      camHUD.visible = false;
      inCutscene = true;
      canPause = false;
    });

    new FlxTimer().start(4, function(tmr) {
      SEEYOU1.visible = false;
      SEEYOU2.visible = true;
      FunkinSound.playOnce('cutscene/end2', 1.0);
    });

    new FlxTimer().start(8, function(tmr) {
      SEEYOU1.visible = false;
      SEEYOU2.visible = false;
    });

    new FlxTimer().start(9, function(tmr) {
      endSong();
    });
  }

  function playCutsceneFromRestart()
  {
    setCutsceneVisibility(false);
    resetClear();

    tweenCameraZoom(0.55, 1, true, FlxEase.circOut);
    tweenCameraToPosition(1070, 470, 1, FlxEase.circOut);

    sserafimGf.visible = true;
    sserafimBf.visible = true;

    sserafimGf.doAnim();
    sserafimBf.doAnim();

    //sserafimGf.animation.curAnim.curFrame = 23;
    //sserafimBf.animation.curAnim.curFrame = 23;
  }

  function introCutscene()
  {
    inCutscene = true;
    canPause = false;

    Paths.sound('cutscene/startCutscene');

    sserafimCutscene.doAnim();

    tweenCameraZoom(0.5, 0, true);
    tweenCameraToPosition(660, -200, 0);

    camGame.fade(0xFF000000, 3, true, null, true);

    cutsceneHandler.timer(20 / 24, function() {
      sserafimCutscene.doAnim();
      cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/startCutscene'), 1.0, false, true, true);
    });

    tweenCameraZoom(0.7, 3, true, FlxEase.circOut);
    tweenCameraToPosition(660, 300, 3, FlxEase.circOut);

    // gf taps herself
    cutsceneHandler.timer(245 / 24, function() {
      setDarkenAmt(0.2, 0.01);
    });

    cutsceneHandler.timer(251 / 24, function() {
      setDarkenAmt(0, 0.8);
    });

    // gf taps bf
    cutsceneHandler.timer(406 / 24, function() {
      setDarkenAmt(0.2, 0.01);
    });

    cutsceneHandler.timer(411 / 24, function() {
      setDarkenAmt(0, 0.8);
    });

    // truck starts getting closer
    cutsceneHandler.timer(499 / 24, function() {
      cutsceneHandler._canSkip = false;
      cutsceneSkipped = true;
      canSkipCutscene = false;
      // cutting off skipping here. really dont think its needed after this point and it saves problems from happening

      FlxTween.cancelTweensOf(stageShader);
      FlxTween.cancelTweensOf(characterShader);

      FlxTween.tween(stageShader,
      {
        baseBrightness: 55,
        baseHue: 0,
        baseContrast: -30,
        baseSaturation: 0
      }, 49 / 24, {ease: FlxEase.sineOut});
      FlxTween.tween(characterShader,
      {
        baseBrightness: 55,
        baseHue: 0,
        baseContrast: -30,
        baseSaturation: 0
      }, 49 / 24, {ease: FlxEase.sineOut});
    });

    // truck gets really close
    cutsceneHandler.timer(548 / 24, function() {
      FlxTween.cancelTweensOf(stageShader);
      FlxTween.cancelTweensOf(characterShader);

      FlxTween.tween(stageShader,
      {
        baseBrightness: 66,
        baseHue: 10,
        baseContrast: -17,
        baseSaturation: 0
      }, 15 / 24, {ease: FlxEase.expoIn});
      FlxTween.tween(characterShader,
      {
        baseBrightness: 66,
        baseHue: 10,
        baseContrast: -17,
        baseSaturation: 0
      }, 15 / 24, {ease: FlxEase.expoIn});
    });

    var offsetLol:Float = 562;

    // car crash + flash
    cutsceneHandler.timer(563 / 24, function() {
      FlxTween.cancelTweensOf(stageShader);
      FlxTween.cancelTweensOf(characterShader);

      stageShader.setAdjustColor(0, 0, 0, 0);
      characterShader.setAdjustColor(0, 0, 0, 0);
      camGame.fade(0xFFFFFFFF, 30 / 24, true, null, true);
      getStageObject('solidCover').alpha = 1;

      setCutsceneVisibility(false);
    });

    // fade out from black and add dust
    cutsceneHandler.timer(650 / 24, function() {
      tweenCameraZoom(0.7, 0, true);
      tweenCameraZoom(0.55, 3, true, FlxEase.circOut);
      tweenCameraToPosition(1070, 470, 0);

      resetClear();
      //FlxTween.tween(getStageObject('solidCover'), {alpha: 0}, 3, {ease: FlxEase.sineOut});

      sserafimGf.visible = true;
      sserafimBf.visible = true;
      sserafimGf.resetAnim();
      sserafimBf.resetAnim();
    });

    cutsceneHandler.timer(710 / 24, function() {
      sserafimGf.doAnim();
      sserafimBf.doAnim();
    });
  }

  function skipCutscene()
  {
    cutsceneSkipped = true;
    hasPlayedCutscene = true;
    camOther.fade(0xFF000000, 0.5, false, null, true);

    if (cutsceneSounds != null) cutsceneSounds.fadeOut(0.5, 0);

    new FlxTimer().start(0.5, _ -> {
      camOther.fade(0xFF000000, 0.5, true, null, true);

      if (cutsceneSounds != null) cutsceneSounds.stop();

      inCutscene = false;
      canPause = true;
      startCountdown();
      camHUD.visible = true;

      playCutsceneFromRestart();
    });
  }

  function hideDust(visible:Bool)
  {
    if (dust1 == null) return;

    dust1.visible = visible;
    dust2.visible = visible;
    dust3.visible = visible;
    dust4.visible = visible;
  }

  function resetClear()
  {
    yunjin.playAnim('doorclosed', true, true);
    yunjin.danceEveryNumBeats = 0;

    getStageObject('truckDoor').visible = false;

    final things:Array<Dynamic> = [
      stageShader,
      characterShader,
      dust1,
      dust1.velocity,
      dust2,
      dust2.velocity,
      dust3,
      dust3.velocity,
      dust4,
      dust4.velocity
    ];

    for (thing in things)
    {
      FlxTween.cancelTweensOf(thing);
    }

    stageShader.setAdjustColor(-24, 6, -26, -74);
    characterShader.setAdjustColor(-24, 6, -26, -74);

    dust1.setPosition(-650, -400);
    dust2.setPosition(-650, -450);
    dust3.setPosition(-650, -600);
    dust4.setPosition(-650, -1500);

    dust1.velocity.x = 350;
    dust2.velocity.x = -300;
    dust3.velocity.x = -200;
    dust4.velocity.x = -150;

    dust1.alpha = 1;
    dust2.alpha = 1;
    dust3.alpha = 1;
    dust4.alpha = 1;
  }

  function startClear()
  {
    FlxTween.tween(stageShader,
    {
      baseBrightness: 0,
      baseHue: 0,
      baseContrast: 0,
      baseSaturation: 0
    }, 6.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(characterShader,
    {
      baseBrightness: 0,
      baseHue: 0,
      baseContrast: 0,
      baseSaturation: 0
    }, 6.0 * 4, {ease: FlxEase.sineOut});

    FlxTween.tween(dust1, {alpha: 0, y: dust1.y + 100}, 5.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(dust2, {alpha: 0, y: dust2.y + 200}, 4.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(dust3, {alpha: 0, y: dust3.y + 150}, 6.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(dust4, {alpha: 0, y: dust4.y + 100}, 4.0 * 4, {ease: FlxEase.sineOut});

    FlxTween.tween(dust1.velocity, {x: 0}, 5.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(dust2.velocity, {x: 0}, 4.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(dust3.velocity, {x: 0}, 6.0 * 4, {ease: FlxEase.sineOut});
    FlxTween.tween(dust4.velocity, {x: 0}, 4.0 * 4, {ease: FlxEase.sineOut});
  }

  //Things from base game
  // TODO: CamUtil maybe?
  /**
   * An FlxTween that zooms the camera to the desired amount.
  */
  public var cameraZoomTween:Null<FlxTween>;

  /**
   * An FlxTween that tweens the camera to the follow point.
   * Only used when tweening the camera manually, rather than tweening via follow.
   */
  public var cameraFollowTween:Null<FlxTween>;

  public function resetCameraZoom():Void
  {
    // Apply camera zoom level from stage data.
    defaultCamZoom = game.defaultStageZoom;
    FlxG.camera.zoom = defaultCamZoom;

    // Reset bop multiplier.
    game.camZoomingMult = 1.0;
  }

  /**
 * Resets the camera's zoom level and focus point.
 */
  public function resetCamera(resetZoom:Bool = true, cancelTweens:Bool = true, snap:Bool = true):Void
  {
    // Cancel camera tweens if any are active.
    if (cancelTweens)
    {
      cancelAllCameraTweens();
    }

    FlxG.camera.follow(camFollow, LOCKON, 0.04);
    FlxG.camera.targetOffset.set();

    if (resetZoom)
    {
      resetCameraZoom();
    }

    // Snap the camera to the follow point immediately.
    if (snap) FlxG.camera.focusOn(camFollow.getPosition());
  }

  /**
     * Sets the camera follow point's position and tweens the camera there.
     */
  public function tweenCameraToPosition(x:Float = 0, y:Float = 0, duration:Float = 0, ?ease:Null<Float->Float>):Void
  {
    camFollow.setPosition(x, y);
    tweenCameraToFollowPoint(duration, ease);
  }

  /**
     * Disables camera following and tweens the camera to the follow point manually.
     */
  public function tweenCameraToFollowPoint(duration:Float = 0, ?ease:Null<Float->Float>):Void
  {
    // Cancel the current tween if it's active.
    cancelCameraFollowTween();

    if (duration == 0)
    {
      // Instant movement. Just reset the camera to force it to the follow point.
      resetCamera(false, false);
    }
    else
    {
      // Disable camera following for the duration of the tween.
      @:nullSafety(Off)
      FlxG.camera.target = null;

      // Follow tween! Caching it so we can cancel/pause it later if needed.
      var followPos:FlxPoint = camFollow.getPosition() - FlxPoint.weak(FlxG.camera.width * 0.5, FlxG.camera.height * 0.5);
      cameraFollowTween = FlxTween.tween(FlxG.camera.scroll, {x: followPos.x, y: followPos.y}, duration,
      {
        ease: ease,
        onComplete: function(_) {
          resetCamera(false, false); // Re-enable camera following when the tween is complete.
        }
      });
    }
  }

  public function cancelCameraFollowTween()
  {
    if (cameraFollowTween != null)
    {
      cameraFollowTween.cancel();
    }
  }

  /**
   * Tweens the camera zoom to the desired amount.
   */
  public function tweenCameraZoom(zoom:Float = 1, duration:Float = 0, direct:Bool = false, ?ease:Null<Float->Float>):Void
  {
    // Cancel the current tween if it's active.
    cancelCameraZoomTween();

    // Direct mode: Set zoom directly.
    // Stage mode: Set zoom as a multiplier of the current stage's default zoom.
    var targetZoom = zoom * (direct ? FlxCamera.defaultZoom : game.defaultStageZoom);

    if (duration == 0)
    {
      // Instant zoom. No tween needed.
      defaultCamZoom = targetZoom;
    }
    else
    {
      // Zoom tween! Caching it so we can cancel/pause it later if needed.
      cameraZoomTween = FlxTween.tween(this, {defaultCamZoom: targetZoom}, duration, {ease: ease});
    }
  }

  public function cancelCameraZoomTween():Void
  {
    if (cameraZoomTween != null)
    {
      cameraZoomTween.cancel();
    }
  }

  /**
   * Cancel all active camera tweens simultaneously.
  */
  public function cancelAllCameraTweens()
  {
    cancelCameraFollowTween();
    cancelCameraZoomTween();
  }
}
