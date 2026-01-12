import backend.FunkinSound;
import backend.pslice.ScaleMode;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxTimerManager;
import funkin.modding.base.ScriptedFlxSpriteGroup;
import objects.Character.CharType;
import objects.FlxAtlasSprite;
import objects.FlxSprite3D; // I knew this would be useful eventually
import objects.FunkinSprite;
import shaders.DropShadowShader;

// import shaders.SserafimShader; dont have this just yet

var baseVisible:Array<Bool> = [true, false, false, false, false, false];
var baseSinging:Array<Bool> = [false, false, false, false, false, false];

// CHARACTERS
var yunjin:Character;
var chaewon:Character;
var eunchae:Character;

// VFX/SHADERS
//var characterShader:SserafimShader;
//var stageShader:SserafimShader;

// SPRITES
var perspectiveFloor:FlxSprite3D = null;

// CUTSCENE SHIT
var hasPlayedCutscene:Bool;

var SEEYOU1:FlxSprite;
var SEEYOU2:FlxSprite;

var hasHidden = false;

function onCreate():Void
{

  hasHidden = false;
  hasPlayedCutscene = false;
  cutsceneSkipped = false;
  canSkipCutscene = false;
  cutsceneTimerManager = null;
}

function onDestroy():Void
{
  hasHidden = false;
  hasPlayedCutscene = false;
}

var dust1:FlxBackdrop;
var dust2:FlxBackdrop;
var dust3:FlxBackdrop;
var dust4:FlxBackdrop;

function onCreatePost()
{
  //characterShader = new SserafimShader(true);
  //stageShader = new SserafimShader();

  perspectiveFloor = new FlxSprite3D(760, 1375);
  perspectiveFloor.loadGraphic(Paths.image('floor'));
  perspectiveFloor.scrollFactor.set(1.05, 1.05);

  perspectiveFloor.z = 11;
  game.addBehindGF(perspectiveFloor);

  dust1 = new FlxBackdrop(Paths.image('dust/dustMid'), 0x01);
  dust1.setPosition(-650, -200);
  dust1.scrollFactor.set(1.1, 1.1);
  dust1.scale.set(1.5, 1.5);
  dust1.alpha = 0.8;
  dust1.velocity.x = 350;

  dust2 = new FlxBackdrop(Paths.image('dust/dustBack'), 0x01);
  dust2.setPosition(-650, -250);
  dust2.scrollFactor.set(1.15, 1.15);
  dust2.scale.set(1.5, 1.5);
  dust2.alpha = 0.9;
  dust2.velocity.x = -300;

  dust3 = new FlxBackdrop(Paths.image('dust/dustMid'), 0x01);
  dust3.setPosition(-650, -400);
  dust3.scrollFactor.set(1.2, 1.2);
  dust3.scale.set(2, 2);
  dust3.alpha = 0.8;
  dust3.velocity.x = -200;

  dust4 = new FlxBackdrop(Paths.image('dust/dustBack'), 0x01);
  dust4.setPosition(-650, -1300);
  dust4.scrollFactor.set(1.25, 1.25);
  dust4.scale.set(3.5, 3.5);
  dust4.alpha = 0.9;
  dust4.velocity.x = -150;

  game.addBehindGF(dust1);
  game.addBehindGF(dust2);
  game.addBehindGF(dust3);
  game.addBehindGF(dust4);

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

  //perspectiveFloor.shader = stageShader;
  //yunjin.shader = characterShader;
  //chaewon.shader = characterShader;
  //eunchae.shader = characterShader;

  createCutsceneSprites();

  for (character in [game.boyfriend, game.girlfriend, game.dad, yunjin, chaewon, eunchae]) {
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

    character.characterType = baseSinging[targetIndex] ? CharType.BF : CharType.DAD;
    character.visible = baseVisible[targetIndex];

    //character.shader = characterShader;
  }
}

function hideOpponentStrumline()
{
  modManager.setValue('alpha', 1, 1);
}

/**
 * Called when the chart hits a song event.
 */
function onEvent(eventName:String, value1:String, value2:String, strumTime:Float)
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
      var threekings:Array<String> = value2.split(':');
      var threekindoms:Array<Array<String>> = [];
      for (king in threekings)
        threekindoms.push(king.split(','));

      setLightState(parseBool(value1), threekindoms[0], parseFloatArray(threekindoms[1]),
        parseFloatArray(threekindoms[2]));
    case 'sserafimKick':
      if (parseBool(value1))
      {
        // play second kick anim + reset her idle back to normal
        yunjin.playAnimation('kick2', true, false);
        FunkinSound.playOnce(Paths.sound('doorKick2'), 1.0);
        yunjin.danceEvery = 1;

        // Show the opponent health icon at this point
        PlayState.instance.iconP2.visible = true;

        // hide the cutscene characters if theyre present!
        if (sserafimGf != null)
        {
          // and show the REAL gf
          PlayState.instance.gf?.visible = true;

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
        yunjin.playAnimation('kick1', true, false);
        FunkinSound.playOnce(Paths.sound('doorKick1'), 1.0);
      }
    case 'sserafimEnd':
      endStuff();
  }
}

function parseBoolArray(value:String):Array<Bool> {
  var sArr:Array<String> = value.trim().split(',');
  var bArr:Array<Bool> = [];
  for (b in sArr)
    bArr.push(b.toLowerCase() == "true" ? true : false);
  return bArr;
}

function parseFloatArray(value:String):Array<Float> {
  var sArr:Array<String> = value.trim().split(',');
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
  PlayState.instance.camGame.flash(0xFFFFFFFF, duration);
}

function setCoverVisible(visible:Bool)
{
  game.getLuaObject('solidCover').alpha = visible ? 1.0 : 0.0;
}

function setGirlsVisible(visibleArray:Array<Bool>)
{
  if (visibleArray.length < 5) return;

  yunjin.visible = visibleArray[0];

  PlayState.instance.dad?.visible = visibleArray[1];

  chaewon.visible = visibleArray[2];
  eunchae.visible = visibleArray[3];

  PlayState.instance.boyfriend?.visible = visibleArray[4];

  // gf visibility ISNT stored here, cause itd break a lot of stuff already in place and im kinda running out of time
}

function setGirlsSinging(singingArray:Array<Bool>)
{
  if (singingArray.length < 5) return;

  yunjin.characterType = singingArray[0] ? CharacterType.BF : CharacterType.DAD;

  PlayState.instance.currentStage.getDad()?.characterType = singingArray[1] ? CharacterType.BF : CharacterType.DAD;

  chaewon.characterType = singingArray[2] ? CharacterType.BF : CharacterType.DAD;
  eunchae.characterType = singingArray[3] ? CharacterType.BF : CharacterType.DAD;

  PlayState.instance.currentStage.getBoyfriend()?.characterType = singingArray[4] ? CharacterType.BF : CharacterType.DAD;

  PlayState.instance.currentStage.getGirlfriend()?.characterType = singingArray[5] ? CharacterType.BF : CharacterType.DAD;
}

override function addProp(prop:StageProp, ?name:String = null)
{
  super.addProp(prop, name);
  prop.shader = stageShader;

  switch (name)
  {
    case 'truckLight1':
      prop.shader = null;

      prop.blend = 12;
    case 'truckLight2':
      prop.shader = null;

    case 'backLightColor':
      prop.shader = null;

      prop.blend = 12;
      prop.color = 0xFFCC3300;
    case 'backLightWhite':
      prop.shader = null;

      prop.blend = 0;
    case 'truckTest':
      prop.shader = null;
    case 'solidCover':
      prop.shader = null;
  }
}

function setDarkenAmt(darkAmt:Float, duration:Float)
{
  FlxTween.cancelTweensOf(characterShader);
  FlxTween.cancelTweensOf(stageShader);

  FlxTween.tween(characterShader, {darkenAmount: darkAmt}, duration, {ease: FlxEase.sineInOut});
  FlxTween.tween(stageShader, {darkenAmount: darkAmt}, duration, {ease: FlxEase.sineInOut});
}

function flashTruckLights(amount:Float, duration:Float):Void
{
  FlxTween.cancelTweensOf(getNamedProp('truckLight1'));
  FlxTween.cancelTweensOf(getNamedProp('truckLight2'));

  HapticUtil.vibrate(0, duration / 2, amount / 2, 0);

  getNamedProp('truckLight1').alpha = amount;
  getNamedProp('truckLight2').alpha = amount;

  characterShader.truckLightStrength = amount;
  stageShader.truckLightStrength = amount;

  FlxTween.tween(getNamedProp('truckLight1'), {alpha: 0}, duration,
    {
      ease: FlxEase.cubeInOut,
      onUpdate: function(tween:FlxTween) {
        characterShader.truckLightStrength = getNamedProp('truckLight1').alpha;
        stageShader.truckLightStrength = getNamedProp('truckLight1').alpha;
      },
      onComplete: function(tween:FlxTween) {
        characterShader.truckLightStrength = 0;
        stageShader.truckLightStrength = 0;
      }
    });
  FlxTween.tween(getNamedProp('truckLight2'), {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
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
  FlxTween.cancelTweensOf(getNamedProp('backLightColor'));
  FlxTween.cancelTweensOf(getNamedProp('backLightWhite'));

  getNamedProp('backLightColor').color = color;

  getNamedProp('backLightColor').alpha = amount * 0.8;
  getNamedProp('backLightWhite').alpha = amount * 0.7;

  characterShader.pulseLightColor = color;
  stageShader.pulseLightColor = color;

  characterShader.pulseLightStrength = getNamedProp('backLightColor').alpha;
  stageShader.pulseLightStrength = getNamedProp('backLightColor').alpha;

  FlxTween.tween(getNamedProp('backLightColor'), {alpha: 0}, duration,
    {
      ease: FlxEase.cubeInOut,
      onUpdate: function(tween:FlxTween) {
        characterShader.pulseLightStrength = getNamedProp('backLightColor').alpha;
        stageShader.pulseLightStrength = getNamedProp('backLightColor').alpha;
      },
      onComplete: function(tween:FlxTween) {
        characterShader.pulseLightStrength = 0;
        stageShader.pulseLightStrength = 0;
      }
    });
  FlxTween.tween(getNamedProp('backLightWhite'), {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
}

function onBeatHit()
{
    // flash lights behind truck
  if (lightsEnabled) flashBackLight(lightsIntensities[event.beat % lightsIntensities.length], lightsDurations[event.beat % lightsDurations.length],
    lightsColors[event.beat % lightsColors.length]);
}

function onUpdate(elapsed:Float):Void
{
  if (cutsceneTimerManager != null) cutsceneTimerManager.update(event.elapsed);

  if (!this.hasHidden)
  {
    this.hasHidden = true;
    hideOpponentStrumline();
    // PlayState.instance.comboPopUps.offsets = [510, 320]; actual values for if we ever wanna use it
    game.comboOffsetCustom = [9999, -50, 9999, -50, 9999, -50];
  }

  if (keyJustPressed('accept') && !cutsceneSkipped)
  {
    if (!canSkipCutscene)
    {
      trace('cant skip yet!');
      if (skipText != null)
      {
        FlxTween.tween(skipText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        new FlxTimer().start(0.5, _ -> {
          canSkipCutscene = true;
          trace('can skip!');
        });
      }
    }
  }
  if (keyJustPressed('accept') && !cutsceneSkipped && canSkipCutscene)
  {
    skipCutscene();
    trace('skipped');
  }

  // i cant bear the weight of deleting you debugShitLol you can stay here just so i can remember how useful you were
  // debugShitLol();
}

// ----------------- CUTSCENE LOGIC -----------------
var sserafimCutscene:FlxAtlasSprite;
var sserafimBf:FlxAtlasSprite;
var sserafimGf:FlxAtlasSprite;
var cutsceneSounds:Null<FunkinSound> = null;

var skipText:FlxText;
var cutsceneSkipped:Bool = false;
var canSkipCutscene:Bool = false;
var cutsceneTimerManager:FlxTimerManager;

function cancelCutsceneSounds():Void
{
  if (cutsceneSounds != null) cutsceneSounds.destroy();
}

function onStartCountdown()
{
  if (PlayState.chartingMode && !hasPlayedCutscene)
  {
    hasPlayedCutscene = true;
    cutsceneSkipped = true;
    playCutsceneFromRestart();
  }

  if (!hasPlayedCutscene)
  {
    trace('Pausing countdown to play in game cutscene');

    hasPlayedCutscene = true;

    game.camHUD.visible = false;

    setCutsceneVisibility(true);
    introCutscene();

    return Function_Stop;
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

  game.getLuaObject('truck').visible = !inCutscene;
  game.getLuaObject('truckDoor').visible = false;
  game.getLuaObject('backTables').visible = !inCutscene;
  game.getLuaObject('backStools').visible = !inCutscene;
  game.getLuaObject('frontStool').visible = !inCutscene;
  hideDust(!inCutscene);

  perspectiveFloor.loadGraphic(Paths.image(inCutscene ? 'cutscene/floor-cutscene' : 'floor'));

  game.getLuaObject('backTablesCutscene').visible = inCutscene;
  game.getLuaObject('burgerCutscene').visible = inCutscene;

  // gf will be hidden at the start + in the cutscene so we can just do this here
  PlayState.instance.gf?.visible = false;

  if (sserafimCutscene != null) sserafimCutscene.visible = inCutscene;
}

function createCutsceneSprites()
{
  sserafimCutscene = new FlxAtlasSprite(-395, 10, 'assets/sserafim/images/cutscene/cutsceneMain', {
    FrameRate: 24.0,
    Reversed: false,
    // ?OnComplete:Void -> Void,
    ShowPivot: false,
    Antialiasing: true,
    ScrollFactor: new FlxPoint(0.94, 0.94),
  });
  sserafimCutscene.showPivot = false;
	sserafimCutscene.antialiasing = ClientPrefs.data.antialiasing;
  //sserafimCutscene.shader = characterShader;
  //sserafimCutscene.zIndex = 25;

  sserafimGf = new FlxAtlasSprite(655, -104, 'assets/sserafim/images/cutscene/gfGetUp', {
    FrameRate: 24.0,
    Reversed: false,
    // ?OnComplete:Void -> Void,
    ShowPivot: false,
    Antialiasing: true,
    ScrollFactor: new FlxPoint(0.95, 0.95),
  });
  sserafimGf.showPivot = false;
	sserafimGf.antialiasing = ClientPrefs.data.antialiasing;
  //sserafimGf.shader = characterShader;
  sserafimGf.alpha = 0.5;
  //sserafimGf.zIndex = 25;
  sserafimGf.visible = false;

  sserafimBf = new FlxAtlasSprite(1220, 531, 'assets/sserafim/images/cutscene/bfGetUp', {
    FrameRate: 24.0,
    Reversed: false,
    // ?OnComplete:Void -> Void,
    ShowPivot: false,
    Antialiasing: true,
    ScrollFactor: new FlxPoint(0.95, 0.95),
  });
  sserafimBf.showPivot = false;
	sserafimBf.antialiasing = ClientPrefs.data.antialiasing;
  //sserafimBf.shader = characterShader;
  //sserafimBf.zIndex = 305;
  sserafimBf.visible = false;

  game.addBehindDad(sserafimGf);
  game.addBehindBF2(sserafimBf);
  game.add(sserafimCutscene);

  SEEYOU1 = new FlxSprite().loadGraphic(Paths.image('end/end1'));
  SEEYOU1.scale.set(0.67, 0.67);
  SEEYOU1.cameras = [game.camHUD];
  SEEYOU1.updateHitbox();
  SEEYOU1.screenCenter();


  SEEYOU2 = new FlxSprite().loadGraphic(Paths.image('end/end2'));
  SEEYOU2.scale.set(0.67, 0.67);
  SEEYOU2.cameras = [game.camHUD];
  SEEYOU2.updateHitbox();
  SEEYOU2.setPosition(FlxG.width - 40 - SEEYOU2.width, FlxG.height - 40 - SEEYOU2.height);


  game.add(SEEYOU1);
  game.add(SEEYOU2);

  SEEYOU1.visible = false;
  SEEYOU2.visible = false;

}

function endStuff()
{
  FunkinSound.playOnce(Paths.sound('cutscene/end1'), 1.0);

  new FlxTimer().start(0.05, function(tmr) {
    SEEYOU1.visible = true;
    game.getLuaObject('solidCover').alpha = 1;
    game.camHUD.visible = false;
    PlayState.instance.canPause = false;
    PlayState.instance.inCutscene = true;
    PlayState.instance.canReset = false;
  });

  new FlxTimer().start(4, function(tmr) {
    SEEYOU1.visible = false;
    SEEYOU2.visible = true;
    FunkinSound.playOnce(Paths.sound('cutscene/end2'), 1.0);
  });

  new FlxTimer().start(8, function(tmr) {
    SEEYOU1.visible = false;
    SEEYOU2.visible = false;
  });

  new FlxTimer().start(9, function(tmr) {
    PlayState.instance.endSong();
  });
}

function playCutsceneFromRestart()
{
  setCutsceneVisibility(false);
  resetClear();

  FlxTween.tween(FlxG.camera, {zoom: 0.55}, 1, {ease: FlxEase.circOut});
  FlxTween.tween(FlxG.camera, {x: 1070, 470}, 1, {ease: FlxEase.circOut});

  sserafimGf.visible = true;
  sserafimBf.visible = true;

  sserafimGf.playAnimation("bf gf sit up intro(1)", true, true);
  sserafimBf.playAnimation("bf gf sit up intro(1)", true, true);

  sserafimGf.animation.curAnim.curFrame = 23;
  sserafimBf.animation.curAnim.curFrame = 23;
}

function introCutscene()
{
  PlayState.instance.inCutscene = true;
  PlayState.instance.canPause = false;
  PlayState.instance.canReset = false;

  skipText = new FlxText(936 * ScaleMode.wideScale.x, 618 * ScaleMode.wideScale.y, 0,
    'Skip [ ' + InputFormatter.getKeyName(ClientPrefs.keyBinds.get('accept')) + ' ]', 20);
  skipText.setFormat(Paths.font('vcr.ttf'), 40, 0xFFFFFFFF, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
  skipText.scrollFactor.set();
  skipText.borderSize = 2;
  skipText.alpha = 0;
  add(skipText);

  skipText.cameras = [PlayState.instance.camOther];

  cutsceneTimerManager = new FlxTimerManager();

  sserafimCutscene.playAnimation("LSFM intro ((Funni Final cs4))", true, true, true);

  FlxG.camera.zoom = 0.5;
  FlxG.camera.x = 660;
  FlxG.camera.y:-200;

  game.camGame.fade(0xFF000000, 3, true, null, true);

  new FlxTimer(cutsceneTimerManager).start(20 / 24, function(tmr) {
    cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/startCutscene'), 1.0, false, true, true);
  });

  FlxTween.tween(FlxG.camera, {zoom: 0.7}, 3, {ease: FlxEase.circOut});
  FlxTween.tween(FlxG.camera, {x: 660, y:300}, 3, {ease: FlxEase.circOut});

  // gf taps herself
  new FlxTimer(cutsceneTimerManager).start(245 / 24, function(tmr) {
    setDarkenAmt(0.2, 0.01);
  });

  new FlxTimer(cutsceneTimerManager).start(251 / 24, function(tmr) {
    setDarkenAmt(0, 0.8);
  });

  // gf taps bf
  new FlxTimer(cutsceneTimerManager).start(406 / 24, function(tmr) {
    setDarkenAmt(0.2, 0.01);
  });

  new FlxTimer(cutsceneTimerManager).start(411 / 24, function(tmr) {
    setDarkenAmt(0, 0.8);
  });

  // truck starts getting closer
  new FlxTimer(cutsceneTimerManager).start(499 / 24, function(tmr) {
    cutsceneSkipped = true;
    canSkipCutscene = false;
    FlxTween.tween(skipText, {alpha: 0}, 0.5,
      {
        ease: FlxEase.quadIn,
        onComplete: _ -> {
          skipText.visible = false;
        }
      });
    // cutting off skipping here. really dont think its needed after this point and it saves problems from happening

    //FlxTween.cancelTweensOf(stageShader);
    //FlxTween.cancelTweensOf(characterShader);

    /*FlxTween.tween(stageShader,
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
      }, 49 / 24, {ease: FlxEase.sineOut});*/
  });

  // truck gets really close
  new FlxTimer(cutsceneTimerManager).start(548 / 24, function(tmr) {
    //FlxTween.cancelTweensOf(stageShader);
    //FlxTween.cancelTweensOf(characterShader);

    /*FlxTween.tween(stageShader,
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
      }, 15 / 24, {ease: FlxEase.expoIn});*/
  });

  var offsetLol:Float = 562;

  // car crash + flash
  new FlxTimer(cutsceneTimerManager).start(563 / 24, function(tmr) {
    //FlxTween.cancelTweensOf(stageShader);
    //FlxTween.cancelTweensOf(characterShader);

    //stageShader.setAdjustColor(0, 0, 0, 0);
    //characterShader.setAdjustColor(0, 0, 0, 0);
    game.camGame.fade(0xFFFFFFFF, 30 / 24, true, null, true);
    game.getLuaObject('solidCover').alpha = 1;

    setCutsceneVisibility(false);
  });

  // fade out from black and add dust
  new FlxTimer(cutsceneTimerManager).start(650 / 24, function(tmr) {
    FlxTween.cancelTweensOf(FlxG.camera);
    FlxG.camera.zoom = 0.7;
    FlxTween.tween(FlxG.camera, {zoom: 0.55}, 3, {ease: FlxEase.circOut});
    FlxG.camera.x = 1070;
    FlxG.camera.y = 470;

    resetClear();
    FlxTween.tween(game.getLuaObject('solidCover'), {alpha: 0}, 3, {ease: FlxEase.sineOut});

    sserafimGf.visible = true;
    sserafimBf.visible = true;
    sserafimGf.playAnimation("bf gf sit up intro(1)", true);
    sserafimBf.playAnimation("bf gf sit up intro(1)", true);
  });

  new FlxTimer(cutsceneTimerManager).start(710 / 24, function(tmr) {
    sserafimGf.playAnimation("bf gf sit up intro(1)", true, true);
    sserafimBf.playAnimation("bf gf sit up intro(1)", true, true);
  });

  // actually start song
  new FlxTimer(cutsceneTimerManager).start(730 / 24, function(tmr) {
    PlayState.instance.inCutscene = false;
    PlayState.instance.startCountdown();

    PlayState.instance.canPause = true;
    PlayState.instance.canReset = true;
  });
}

function skipCutscene()
{
  cutsceneSkipped = true;
  hasPlayedCutscene = true;
  PlayState.instance.camOther.fade(0xFF000000, 0.5, false, null, true);

  if (cutsceneSounds != null) cutsceneSounds.fadeOut(0.5, 0);

  new FlxTimer().start(0.5, _ -> {
    PlayState.instance.camOther.fade(0xFF000000, 0.5, true, null, true);

    cutsceneTimerManager.clear();
    cutsceneSounds.stop();

    PlayState.instance.inCutscene = false;
    PlayState.instance.canPause = true;
    PlayState.instance.canReset = true;
    PlayState.instance.startCountdown();

    skipText.visible = false;

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
  yunjin.playAnimation('doorclosed', true, true);
  yunjin.danceEvery = 0;

  game.getLuaObject('truckDoor').visible = false;

  for (thing in [
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
  ])
  {
    FlxTween.cancelTweensOf(thing);
  }

  //stageShader.setAdjustColor(-24, 6, -26, -74);
  //characterShader.setAdjustColor(-24, 6, -26, -74);

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
  /*FlxTween.tween(stageShader,
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
    }, 6.0 * 4, {ease: FlxEase.sineOut});*/

  FlxTween.tween(dust1, {alpha: 0, y: dust1.y + 100}, 5.0 * 4, {ease: FlxEase.sineOut});
  FlxTween.tween(dust2, {alpha: 0, y: dust2.y + 200}, 4.0 * 4, {ease: FlxEase.sineOut});
  FlxTween.tween(dust3, {alpha: 0, y: dust3.y + 150}, 6.0 * 4, {ease: FlxEase.sineOut});
  FlxTween.tween(dust4, {alpha: 0, y: dust4.y + 100}, 4.0 * 4, {ease: FlxEase.sineOut});

  FlxTween.tween(dust1.velocity, {x: 0}, 5.0 * 4, {ease: FlxEase.sineOut});
  FlxTween.tween(dust2.velocity, {x: 0}, 4.0 * 4, {ease: FlxEase.sineOut});
  FlxTween.tween(dust3.velocity, {x: 0}, 6.0 * 4, {ease: FlxEase.sineOut});
  FlxTween.tween(dust4.velocity, {x: 0}, 4.0 * 4, {ease: FlxEase.sineOut});
}
