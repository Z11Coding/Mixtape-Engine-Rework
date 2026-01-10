package substates;

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
import archipelago.APEntryState;
#end
import backend.WeekData;
import backend.pslice.Scoring;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.Exception;
import objects.FunkinCamera;
import objects.FunkinSprite;
import shaders.LeftMaskShader;
import states.PlaylistState;
import states.TitleState;
import states.freeplay.VSliceFreeplayState;
import states.freeplay.vslice.FreeplayHelpers;
import states.freeplay.vslice.PlayableCharacter;
import states.freeplay.vslice.PlayerData.PlayerFreeplayDJData;
import states.freeplay.vslice.PlayerData;
import states.freeplay.vslice.PlayerRegistry;
import states.freeplay.vslice.VsliceSubState as MusicBeatSubState;
import states.freeplay.vslice.obj.FlxAtlasSprite;
import substates.StickerSubState;
import substates.results.ClearPercentCounter;
import substates.results.ResultScore;
import substates.results.Tallies.SaveScoreData;
import substates.results.TallyCounter;


/**
 * The state for the results screen after a song or week is finished.
 */
//TODO  documented?
class ResultState extends MusicBeatSubState
{
  final params:ResultsStateParams;

  final rank:ScoringRank;
  final songName:FlxBitmapText;
  final difficulty:FlxBitmapText; //? turned this to text
  final clearPercentSmall:ClearPercentCounter;

  final maskShaderSongName:LeftMaskShader = new LeftMaskShader();
  final maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();

  final resultsAnim:FunkinSprite;
  final ratingsPopin:FunkinSprite;
  final scorePopin:FunkinSprite;

  final bgFlash:FlxSprite;

  final highscoreNew:FlxSprite;
  final score:ResultScore;

  var characterAtlasAnimations:Array<
    {
      sprite:FlxAtlasSprite,
      delay:Float,
      forceLoop:Bool,
      startFrameLabel:String,
      sound:String
    }> = [];
  var characterSparrowAnimations:Array<
    {
      sprite:FunkinSprite,
      delay:Float
    }> = [];

  var playerCharacterId:Null<String>;

  var rankBg:FunkinSprite;
  final cameraBG:FunkinCamera;
  final cameraScroll:FunkinCamera;
  final cameraEverything:FunkinCamera;

  public function new(params:ResultsStateParams)
  {
    super();

    this.params = params;

    rank = Scoring.calculateRank(params.scoreData) ?? SHIT;

    if (!PlayState.instance.cpuControlled && !params.playlistMode)
      backend.Highscore.saveRank(PlayState.SONG.song, ScoringRank.getValueFromRank(rank), PlayState.storyDifficulty);

    cameraBG = new FunkinCamera('resultsBG', 0, 0, FlxG.width, FlxG.height);
    cameraScroll = new FunkinCamera('resultsScroll', 0, 0, FlxG.width, FlxG.height);
    cameraEverything = new FunkinCamera('resultsEverything', 0, 0, FlxG.width, FlxG.height);

    // We build a lot of this stuff in the constructor, then place it in create().
    // This prevents having to do `null` checks everywhere.

    var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
    songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
    songName.text = params.title;
    songName.letterSpacing = -15;
    songName.angle = -4.4;
    songName.zIndex = 1000;
    var difColor = PlayState.storyDifficultyColor; //? support for difficulty text
    var fractal = difColor.redFloat*0.33;
    difColor.greenFloat = Math.max(difColor.greenFloat,fractal);

    difficulty = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
    difficulty.text = FreeplayHelpers.getDifficultyName();
    difficulty.color = difColor;
    difficulty.letterSpacing = -11; //!!!
    difficulty.angle = -4.4;
    difficulty.zIndex = 1000;

    clearPercentSmall = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
    clearPercentSmall.zIndex = 1000;
    clearPercentSmall.visible = false;

    bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);

    resultsAnim = FunkinSprite.createSparrow(FlxG.width -(1480 + (MobileScaleMode.gameCutoutSize.x / 2)), -10, "resultScreen/results");

    ratingsPopin = FunkinSprite.createSparrow(-135+ MobileScaleMode.gameNotchSize.x, 135, "resultScreen/ratingsPopin");

    scorePopin = FunkinSprite.createSparrow(-180+ MobileScaleMode.gameNotchSize.x, 515, "resultScreen/scorePopin");

    highscoreNew = new FlxSprite(44+ MobileScaleMode.gameNotchSize.x, 557);

    score = new ResultScore(35+ MobileScaleMode.gameNotchSize.x, 305, 10, params.scoreData.score);

    rankBg = new FunkinSprite(0, 0);

    var sngMeta = FreeplayManager.getPSliceMetadata(params.songId);

    if(sngMeta != null && sngMeta.freeplayCharacter != '' ){
      playerCharacterId = sngMeta.freeplayCharacter;
    }
    else if (!PlayState.isStoryMode){
      var mod_char = FreeplayThings.LAST_MOD;
      playerCharacterId = mod_char.char_name;
      Mods.loadModDir(mod_char.mod_dir);
    }
    else{
      playerCharacterId = "bf";
    }
    //? moved this line so we can edit it in debug options
  }

  override function create():Void
  {
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // We need multiple cameras so we can put one at an angle.
    cameraScroll.angle = -3.8;

    cameraBG.bgColor = FlxColor.MAGENTA;
    cameraScroll.bgColor = FlxColor.TRANSPARENT;
    cameraEverything.bgColor = FlxColor.TRANSPARENT;

    FlxG.cameras.add(cameraBG, false);
    FlxG.cameras.add(cameraScroll, false);
    FlxG.cameras.add(cameraEverything, false);

    FlxG.cameras.setDefaultDrawTarget(cameraEverything, true);
    this.camera = cameraEverything;

    // Reset the camera zoom on the results screen.
    FlxG.camera.zoom = 1.0;

    var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
    bg.scrollFactor.set();
    bg.zIndex = 10;
    bg.cameras = [cameraBG];
    add(bg);

    bgFlash.scrollFactor.set();
    bgFlash.visible = false;
    bgFlash.zIndex = 20;
    // bgFlash.cameras = [cameraBG];
    add(bgFlash);

    // The sound system which falls into place behind the score text. Plays every time!
    var soundSystem:FlxSprite = FunkinSprite.createSparrow(-15+ MobileScaleMode.gameNotchSize.x, -180, 'resultScreen/soundSystem');
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.visible = false;
    new FlxTimer().start(8 / 24, _ -> {
      soundSystem.animation.play("idle");
      soundSystem.visible = true;
    });
    soundSystem.zIndex = 1100;
    add(soundSystem);

    // Fetch playable character data. Default to BF on the results screen if we can't find it.
    //? changed a little code here


    var playerCharacter:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playerCharacterId ?? 'bf');

    //trace('Got playable character: ${playerCharacter?.getName()}');
    // Query JSON data based on the rank, then use that to build the animation(s) the player sees.
    var playerAnimationDatas:Array<PlayerResultsAnimationData> = playerCharacter != null ? playerCharacter.getResultsAnimationDatas(rank) : [];

    for (animData in playerAnimationDatas)
    {
      if (animData == null) continue;

      //? Rework available flags
      switch (animData.filter){
        case ""|"both"|null: // Do nothing
        case "naughty":
          if(!ClientPrefs.data.naughtyness) continue;
        case "safe":
          if(ClientPrefs.data.naughtyness) continue;
        default:
          trace(animData.filter+" is not a valid filter!");
          continue;
      }

      var animPath:String = "";
      var animLibrary:String = "";

      if (animData.assetPath != null)
      {
        animPath = Paths.stripLibrary(animData.assetPath);
        animLibrary = "";
      }
      var offsets = animData.offsets ?? [0, 0];
      try{


      switch (animData.renderType)
      {
        case 'animateatlas':
          //? Scaling offsets because Pico decided to be annoying

          // var xDiff = offsets[0] - (offsets[0]* (animData.scale ?? 1.0));
          // var yDiff = offsets[1] - (offsets[1]* (animData.scale ?? 1.0));
          // offsets[0] -= xDiff*1.8;
          // offsets[1] -= yDiff*1.8;

          var animation:FlxAtlasSprite = new FlxAtlasSprite(offsets[0] + MobileScaleMode.gameNotchSize.x, offsets[1], animPath);
          animation.zIndex = animData.zIndex ?? 500;
          animation.scale.set(animData.scale ?? 1.0, animData.scale ?? 1.0);

          if (!(animData.looped ?? true))
            {
              // Animation is not looped.
              animation.onAnimationComplete.add((_name:String) -> {
                trace("AHAHAH 2");
                if (animation != null)
                {
                  animation.anim.pause();
                }
              });
            }
            else if (animData.loopFrameLabel != null)
            {
              animation.onAnimationComplete.add((_name:String) -> {
                trace("AHAHAH 2");
                if (animation != null)
                {
                  animation.playAnimation(animData.loopFrameLabel ?? '', true, false, true); // unpauses this anim, since it's on PlayOnce!
                }
              });
            }
            else if (animData.loopFrame != null)
            {
              animation.onAnimationComplete.add((_name:String) -> {
                if (animation != null)
                {
                  trace("AHAHAH");
                  animation.anim.curFrame = animData.loopFrame ?? 0;
                  animation.anim.play(); // unpauses this anim, since it's on PlayOnce!
                }
              });
            }

          // Hide until ready to play.
          animation.visible = false;
          // Queue to play.
          characterAtlasAnimations.push(
            {
              sprite: animation,
              delay: animData.delay ?? 0.0,
              forceLoop: (animData.loopFrame ?? -1) == 0,
              startFrameLabel: (animData.startFrameLabel ?? ""),
              sound: (animData.sound ?? "")
            });
          // Add to the scene.
          add(animation);
        case 'sparrow':
          var animation:FunkinSprite = FunkinSprite.createSparrow(offsets[0] + MobileScaleMode.gameNotchSize.x, offsets[1], animPath);
          animation.animation.addByPrefix('idle', '', 24, false, false, false);

          if (animData.loopFrame != null)
          {
            animation.animation.finishCallback = (_name:String) -> {
              if (animation != null)
              {
                animation.animation.play('idle', true, false, animData.loopFrame ?? 0);
              }
            }
          }

          // Hide until ready to play.
          animation.visible = false;
          // Queue to play.
          characterSparrowAnimations.push(
            {
              sprite: animation,
              delay: animData.delay ?? 0.0
            });
          // Add to the scene.
          add(animation);
      }
      }
      catch(error:Exception){
        trace("Failed to load "+animPath);
        trace(error);
      }
    }

    var diffSpr:String = 'diff_${params?.difficultyId ?? 'Normal'}';
    difficulty.loadGraphic(Paths.image("resultScreen/" + diffSpr));
    add(difficulty);

    add(songName);

    var angleRad = songName.angle * Math.PI / 180;
    speedOfTween.x = -1.0 * Math.cos(angleRad);
    speedOfTween.y = -1.0 * Math.sin(angleRad);

    timerThenSongName(1.0, false);
    //! Watch out with this one
    //songName.shader = maskShaderSongName;
    //difficulty.shader = maskShaderDifficulty;

    // maskShaderSongName.swagMaskX = difficulty.x - 15;
    //maskShaderDifficulty.swagMaskX = difficulty.x - 15;

    var blackTopBar:FlxSprite = new FlxSprite().loadGraphic(backend.pslice.BitmapUtil.createResultsBar());
    blackTopBar.y = -blackTopBar.height;
    FlxTween.tween(blackTopBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24});
    blackTopBar.zIndex = 1010;
    add(blackTopBar);

    resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
    resultsAnim.visible = false;
    resultsAnim.zIndex = 1200;
    add(resultsAnim);
    new FlxTimer().start(6 / 24, _ -> {
      resultsAnim.visible = true;
      resultsAnim.animation.play("result");
    });

    ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
    ratingsPopin.visible = false;
    ratingsPopin.zIndex = 1200;
    add(ratingsPopin);
    new FlxTimer().start(21 / 24, _ -> {
      ratingsPopin.visible = true;
      ratingsPopin.animation.play("idle");
    });

    scorePopin.animation.addByPrefix("score", "tally score", 24, false);
    scorePopin.visible = false;
    scorePopin.zIndex = 1200;
    add(scorePopin);
    new FlxTimer().start(36 / 24, _ -> {
      scorePopin.visible = true;
      scorePopin.animation.play("score");
      scorePopin.animation.finishCallback = anim -> {};
    });

    new FlxTimer().start(37 / 24, _ -> {
      score.visible = true;
      score.animateNumbers();
      startRankTallySequence();
    });

    new FlxTimer().start(rank.getBFDelay(), _ -> {
      afterRankTallySequence();
    });

    new FlxTimer().start(rank.getFlashDelay(), _ -> {
      displayRankText();
    });

    highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
    highscoreNew.animation.addByPrefix("new", "highscoreAnim0", 24, false);
    highscoreNew.visible = false;
    // highscoreNew.setGraphicSize(Std.int(highscoreNew.width * 0.8));
    highscoreNew.updateHitbox();
    highscoreNew.zIndex = 1200;
    add(highscoreNew);

    new FlxTimer().start(rank.getHighscoreDelay(), _ -> {
      if (params.isNewHighscore ?? false)
      {
        highscoreNew.visible = true;
        highscoreNew.animation.play("new");
        highscoreNew.animation.finishCallback = _ -> highscoreNew.animation.play("new", true, false, 16);
      }
      else
      {
        highscoreNew.visible = false;
      }
    });

    var hStuf:Int = 50;

    var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
    ratingGrp.zIndex = 1200;
    add(ratingGrp);

    /**
     * NOTE: We display how many notes were HIT, not how many notes there were in total.
     *
     */
    var totalHit:TallyCounter = new TallyCounter(375 + MobileScaleMode.gameNotchSize.x, hStuf * 3, params.scoreData.totalNotesHit);
    ratingGrp.add(totalHit);

    var maxCombo:TallyCounter = new TallyCounter(375 + MobileScaleMode.gameNotchSize.x, hStuf * 4, params.scoreData.maxCombo);
    ratingGrp.add(maxCombo);

    hStuf += 2;
    var extraYOffset:Float = 7;

    hStuf += 2;

    var tallySick:TallyCounter = new TallyCounter(230 + MobileScaleMode.gameNotchSize.x, (hStuf * 5) + extraYOffset, params.scoreData.sick, 0xFF89E59E);
    ratingGrp.add(tallySick);

    var tallyGood:TallyCounter = new TallyCounter(210+ MobileScaleMode.gameNotchSize.x, (hStuf * 6) + extraYOffset, params.scoreData.good, 0xFF89C9E5);
    ratingGrp.add(tallyGood);

    var tallyBad:TallyCounter = new TallyCounter(190 + MobileScaleMode.gameNotchSize.x, (hStuf * 7) + extraYOffset, params.scoreData.bad, 0xFFE6CF8A);
    ratingGrp.add(tallyBad);

    var tallyShit:TallyCounter = new TallyCounter(220 + MobileScaleMode.gameNotchSize.x, (hStuf * 8) + extraYOffset, params.scoreData.shit, 0xFFE68C8A);
    ratingGrp.add(tallyShit);

    var tallyMissed:TallyCounter = new TallyCounter(260 + MobileScaleMode.gameNotchSize.x, (hStuf * 9) + extraYOffset, params.scoreData.missed, 0xFFC68AE6);
    ratingGrp.add(tallyMissed);

    score.visible = false;
    score.zIndex = 1200;
    add(score);

    for (ind => rating in ratingGrp.members)
    {
      rating.visible = false;
      new FlxTimer().start((0.3 * ind) + 1.20, _ -> {
        rating.visible = true;
        FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
      });
    }

    new FlxTimer().start(rank.getMusicDelay(), _ -> {
      //? Changed a little sound loading
      var introMusic:String = getMusicPath(playerCharacter, rank) + '/' + getMusicPath(playerCharacter, rank) + '-intro';
      if (Paths.exists('music/$introMusic.ogg'))
      {
        // Play the intro music.
        FlxG.sound.music = FunkinSound.load(Paths.music(introMusic), 1.0, false, true, true, () -> {
          FunkinSound.playMusic(getMusicPath(playerCharacter, rank),
            {
              startingVolume: 1.0,
              overrideExisting: true,
              restartTrack: true
            });
        });
      }
      else
      {
        FunkinSound.playMusic(getMusicPath(playerCharacter, rank),
          {
            startingVolume: 1.0,
            overrideExisting: true,
            restartTrack: true
          });
      }
    });

    rankBg.makeSolidColor(FlxG.width, FlxG.height, 0xFF000000);
    rankBg.zIndex = 99999;
    add(rankBg);

    rankBg.alpha = 0;

    refresh();

    super.create();

    #if ARCHIPELAGO_ALLOWED
    archipelago.APItem.waitingForTransition = true;
    #end
  }

  function getMusicPath(playerCharacter:Null<PlayableCharacter>, rank:ScoringRank):String
  {
    return playerCharacter?.getResultsMusicPath(rank) ?? 'resultsNORMAL';
  }

  var rankTallyTimer:Null<FlxTimer> = null;
  var clearPercentTarget:Int = 100;
  var clearPercentLerp:Int = 0;

  function startRankTallySequence():Void
  {
    bgFlash.visible = true;
    FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);
    var clearPercentFloat = (params.scoreData.accPoints/params.scoreData.totalNotesHit)* 100; //? different rating system
    if(params.scoreData.totalNotesHit == 0) clearPercentFloat = 0;
    clearPercentTarget = Math.floor(clearPercentFloat);

    // Prevent off-by-one errors.

    clearPercentLerp = Std.int(Math.max(0, clearPercentTarget - 36));

    trace('Clear percent target: ' + clearPercentFloat + ', round: ' + clearPercentTarget);

    var clearPercentCounter:ClearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 190, FlxG.height / 2 - 70, clearPercentLerp);
    FlxTween.tween(clearPercentCounter, {curNumber: clearPercentTarget}, 58 / 24,
      {
        ease: FlxEase.quartOut,
        onUpdate: _ -> {
          // Only play the tick sound if the number increased.
          if (clearPercentLerp != clearPercentCounter.curNumber)
          {
            clearPercentLerp = clearPercentCounter.curNumber;
            FunkinSound.playOnce('scrollMenu');
          }
        },
        onComplete: _ -> {
          // Play confirm sound.
          FunkinSound.playOnce('confirmMenu');

          // Just to be sure that the lerp didn't mess things up.
          clearPercentCounter.curNumber = clearPercentTarget;

          clearPercentCounter.flash(true);
          new FlxTimer().start(0.4, _ -> {
            clearPercentCounter.flash(false);
          });

          // displayRankText();

          // previously 2.0 seconds
          new FlxTimer().start(0.25, _ -> {
            FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5,
              {
                startDelay: 0.5,
                ease: FlxEase.quartOut,
                onComplete: _ -> {
                  remove(clearPercentCounter);
                }
              });

            // afterRankTallySequence();
          });
        }
      });
    clearPercentCounter.zIndex = 450;
    add(clearPercentCounter);

    if (ratingsPopin == null)
    {
      trace("Could not build ratingsPopin!");
    }
    else
    {
      // ratingsPopin.animation.play("idle");
      // ratingsPopin.visible = true;

      ratingsPopin.animation.finishCallback = anim -> {
        // scorePopin.animation.play("score");

        // scorePopin.visible = true;

        if (params.isNewHighscore ?? false)
        {
          highscoreNew.visible = true;
          highscoreNew.animation.play("new");
        }
        else
        {
          highscoreNew.visible = false;
        }
      };
    }

    refresh();
  }

  function displayRankText():Void
  {
    bgFlash.visible = true;
    bgFlash.alpha = 1;
    FlxTween.tween(bgFlash, {alpha: 0}, 14 / 24);

    var rankTextVert:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getVerTextAsset()), Y, 0, 30);
    rankTextVert.x = FlxG.width - 44;
    rankTextVert.y = 100;
    rankTextVert.zIndex = 990;
    add(rankTextVert);

    FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);

    // Scrolling.
    new FlxTimer().start(30 / 24, _ -> {
      rankTextVert.velocity.y = -80;
    });

    for (i in 0...12)
    {
      var rankTextBack:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getHorTextAsset()), X, 10, 0);
      rankTextBack.x = FlxG.width / 2 - 320;
      rankTextBack.y = 50 + (135 * i / 2) + 10;
      // rankTextBack.angle = -3.8;
      rankTextBack.zIndex = 100;
      rankTextBack.cameras = [cameraScroll];
      add(rankTextBack);

      // Scrolling.
      rankTextBack.velocity.x = (i % 2 == 0) ? -7.0 : 7.0;
    }

    refresh();
  }

  function afterRankTallySequence():Void
  {
    showSmallClearPercent();

    for (atlas in characterAtlasAnimations)
    {
      new FlxTimer().start(atlas.delay, _ -> {
        if (atlas.sprite == null) return;
        atlas.sprite.visible = true;
        atlas.sprite.playAnimation(atlas.startFrameLabel);
        if (atlas.sound != "")
        {
          var sndPath:String = Paths.stripLibrary(atlas.sound);
          var sndLibrary:String = "";

          FunkinSound.playOnce(sndPath, 1.0);
        }
      });
    }

    for (sprite in characterSparrowAnimations)
    {
      new FlxTimer().start(sprite.delay, _ -> {
        if (sprite.sprite == null) return;
        sprite.sprite.visible = true;
        sprite.sprite.animation.play('idle', true);
      });
    }
  }

  function timerThenSongName(timerLength:Float = 3.0, autoScroll:Bool = true):Void
  {
    movingSongStuff = false;

    difficulty.x = 555 + MobileScaleMode.gameNotchSize.x;

    var diffYTween:Float = 122;

    difficulty.y = -difficulty.height;
    FlxTween.tween(difficulty, {y: diffYTween}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});

    if (clearPercentSmall != null)
    {
      clearPercentSmall.x = (difficulty.x + difficulty.width) + 60;
      clearPercentSmall.y = -clearPercentSmall.height;
      FlxTween.tween(clearPercentSmall, {y: 122 - 5}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.85});
    }

    songName.y = -songName.height;
    var fuckedupnumber = (10) * (songName.text.length / 15);
    FlxTween.tween(songName, {y: diffYTween - 25 - fuckedupnumber}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
    songName.x = clearPercentSmall.x + 94;

    new FlxTimer().start(timerLength, _ -> {
      var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);

      speedOfTween.set(0, 0);
      FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});

      movingSongStuff = (autoScroll);
    });
  }

  function showSmallClearPercent():Void
  {
    if (clearPercentSmall != null)
    {
      add(clearPercentSmall);
      clearPercentSmall.visible = true;
      clearPercentSmall.flash(true);
      new FlxTimer().start(0.4, _ -> {
        clearPercentSmall.flash(false);
      });

      clearPercentSmall.curNumber = clearPercentTarget;
      clearPercentSmall.zIndex = 1000;
      refresh();
    }

    new FlxTimer().start(2.5, _ -> {
      movingSongStuff = true;
    });
  }

  var movingSongStuff:Bool = false;
  var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);

  override function draw():Void
  {
    super.draw();

    songName.clipRect = FlxRect.get(Math.max(0, 520 - songName.x), 0, FlxG.width, songName.height);

    // PROBABLY SHOULD FIX MEMORY FREE OR WHATEVER THE PUT() FUNCTION DOES !!!! FEELS LIKE IT STUTTERS!!!

    // if (songName != null && songName.frame != null)
    // maskShaderSongName.frameUV = songName.frame.uv;
  }

  override function update(elapsed:Float):Void
  {
    maskShaderDifficulty.swagSprX = difficulty.x;

    if (movingSongStuff)
    {
      var deltaScale = elapsed*190; //? fix framerate
      songName.x += speedOfTween.x*deltaScale;
      difficulty.x += speedOfTween.x*deltaScale;
      clearPercentSmall.x += speedOfTween.x*deltaScale;
      songName.y += speedOfTween.y*deltaScale;
      difficulty.y += speedOfTween.y*deltaScale;
      clearPercentSmall.y += speedOfTween.y*deltaScale;

      if (songName.x + songName.width < 100)
      {
        timerThenSongName();
      }
    }

    if (FlxG.keys.justPressed.RIGHT) speedOfTween.x += 0.1;

    if (FlxG.keys.justPressed.LEFT)
    {
      speedOfTween.x -= 0.1;
    }

    if (controls.PAUSE)
    {
      if (FlxG.sound.music != null)
      {
        FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.8);
        FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1,
        {
          onComplete: _ -> {
            FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.4);
          }
        });
      }

      // Determining the target state(s) to go to.
      // Default to main menu because that's better than `null`.
      var targetState:flixel.FlxState = new states.MainMenuState(); //TODO Why do we create a state here???
      var shouldTween = false;
      var shouldUseSubstate = false;

      #if ARCHIPELAGO_ALLOWED
      // Handle Archipelago mode logic
      if (APEntryState.inArchipelagoMode && PlayState.gameplayArea == "APFreeplay")
      {
        trace('WENT BACK TO ARCHIPELAGO FREEPLAY FROM RESULTS??');

        // Handle Archipelago location checking logic (same as RankingSubstate)
        trace('Combo Gotten: ' + generateComboRank() + '\nCombo Required: ' + comboRankSetLimit);
        trace('Accuracy Gotten: ' + generateAccuracyRank() + '\nAccuracy Required: ' + accRankSetLimit);

        // Always send note checks regardless of ranking requirements
        trace("Sending checks for all checked notes (no ranking requirement)...");
        if (archipelago.APPlayState.instance != null) {
          for (note in archipelago.APPlayState.instance.checkedNotes) {
            trace("Sending check for note: " + note);
            @:privateAccess{
              trace("Sending location: " + note.checkInfo.loc);
              archipelago.APPlayState.apGame.info().LocationChecks([note.checkInfo.loc]);
            }
          }
        }
        trace("All note checks sent.");

        // Only send main song location check if ranking requirements are met
        var comboRankLimit = getComboRankLimit();
        var accRankLimit = getAccuracyRankLimit();

        if (((!PlayState.instance.cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false)) || Sys.args().contains('-livereload')) &&
            comboRankLimit >= comboRankSetLimit && accRankLimit >= accRankSetLimit) {
          trace("Ranking requirements met! Sending main location check...");

          var locationId = (archipelago.APPlayState.currentSong != null && archipelago.APPlayState.currentSong.trim() != "")
            ? archipelago.APPlayState.currentSong
            : PlayState.SONG.song;

          if (APInfo.unlockMethod != "Note Checks") {
            trace(archipelago.APPlayState.currentMod);
            trace("Starting location ID processing for: " + locationId.trim());
            var locationIdInts = APEntryState.apGame.locationData(locationId.trim(), archipelago.APPlayState.currentMod.trim());
            trace('Initial Location IDs: ' + locationIdInts);

            // Location ID processing logic (same as RankingSubstate)
            if (locationIdInts == null || locationIdInts.length == 0 || locationIdInts.indexOf(0) != -1) {
              trace("Location ID not found or invalid, attempting to match song in current week...");
              for (song in WeekData.getCurrentWeek().songs) {
                trace("Checking song: " + song[0]);
                if ((cast song[0] : String).toLowerCase().trim() == PlayState.SONG.song.trim().toLowerCase() ||
                    (cast song[0] : String).toLowerCase().trim().replace(" ", "-") == PlayState.SONG.song.trim().toLowerCase().replace(" ", "-")) {
                  trace("Match found for song: " + song[0]);
                  locationId = song[0];
                  locationIdInts = APEntryState.apGame.locationData(locationId.trim(), archipelago.APPlayState.currentMod.trim());
                  trace("Updated Location IDs: " + locationIdInts);
                  break;
                }
              }
            }

            trace("Final Location IDs: " + locationIdInts);
            for (locationIdInt in locationIdInts) {
              trace("Processing Location ID: " + locationIdInt);
              trace("Location Check Result: " + APEntryState.apGame.info().LocationChecks([locationIdInt]));
              trace("Location Name: " + APEntryState.apGame.info().get_location_name(locationIdInt));
            }
            trace("Current Song: " + PlayState.SONG.song);

            archipelago.console.obj.Alert.alert("You've completed a Song Check!", "Good Job!", function() {
              trace("Popup triggered for sending location to Archipelago.");
              FlxG.sound.playMusic(Paths.sound('secret'));
            });
          }

          if (archipelago.APItem.activeItem != null)
            archipelago.APItem.activeItem = null;

          // Clear active effects
          archipelago.APItem.clearActiveEffects();

          if (archipelago.APEntryState.inArchipelagoMode) {
            ClientPrefs.data.gameplaySettings.set('chartModifier', 'Normal');
          }

          // Check sanity locations on beating if enabled
          if (archipelago.APEntryState.apGame != null) {
            var songName = PlayState.SONG.song;
            var modName = archipelago.APPlayState.currentMod != null && archipelago.APPlayState.currentMod.trim() != "" ? archipelago.APPlayState.currentMod.trim() : null;
            archipelago.APEntryState.apGame.checkSanityLocationsOnBeating(songName, modName);
          }

          if (archipelago.APEntryState.apGame.checkGoal(PlayState.SONG.song, archipelago.APPlayState.currentMod)) {
            archipelago.console.obj.Alert.alert("Congratulations! You've achieved your goal!", "Well Done!");
            trace("Goal achievement popup triggered.");
            FlxG.sound.playMusic(Paths.sound('You Win'));
          }
        } else {
          trace("Ranking requirements not met - main location check will not be sent");
        }

        Mods.loadTopMod();

        // Set target to AP freeplay
        FlxG.sound.pause();
        shouldTween = false;
        shouldUseSubstate = false;
        targetState = FreeplayManager.getNewFreeplayInstance();
      }
      else
      #end
      if (params.storyMode || params.playlistMode)
      {
        FlxG.sound.pause(); //? fix sound
        //TODO re-enable this
        // if (PlayerRegistry.instance.hasNewCharacter())
        // {
        //   // New character, display the notif.
        //   targetState = new StoryMenuState(null);

        //   var newCharacters = PlayerRegistry.instance.listNewCharacters();

        //   for (charId in newCharacters)
        //   {
        //     shouldTween = true;
        //     // This works recursively, ehe!
        //     targetState = new funkin.ui.charSelect.CharacterUnlockState(charId, targetState);
        //   }
        // }
        // else
        // {
          // No new characters.
          shouldTween = false;
          shouldUseSubstate = true;
          targetState = new StickerSubState(null, (sticker) -> params.storyMode ? new states.StoryMenuState() : new states.PlaylistState());
        //}
      }
      else
      {
        if (rank > params.prevScoreRank) //? refactor this???
        {
          trace('THE RANK IS Higher.....');

          shouldTween = true;
          if (PlayState.gameplayArea == "Playlist")
            targetState = new StickerSubState(null, (sticker) -> new PlaylistState());
          else if (PlayState.gameplayArea == "Warmup")
            targetState = new StickerSubState(null, (sticker) -> new TitleState());
          else {
            states.CategoryState.instaFreeplay = true;
            states.CategoryState.freeplayStuff.fromResults = {
              oldRank: params.prevScoreRank,
              newRank: rank,
              songId: params.songId,
              difficultyId: params.difficultyId,
              playRankAnim: true
            };
            targetState = FreeplayManager.getNewFreeplayInstance();
          }
          controls.isInSubstate = FlxTransitionableState.skipNextTransOut = true;
        }
        else
        {
          FlxG.sound.pause(); //? fix sound
          shouldTween = false;
          controls.isInSubstate = shouldUseSubstate = true;
          if (PlayState.gameplayArea == "Playlist")
            targetState = new StickerSubState(null, (sticker) -> new PlaylistState());
          else if (PlayState.gameplayArea == "Warmup")
            targetState = new StickerSubState(null, (sticker) -> new TitleState());
          else
            targetState = new StickerSubState(null, (sticker) -> FreeplayManager.getNewFreeplayInstance());
        }
      }

      if (shouldTween)
      {
        FlxTween.tween(rankBg, {alpha: 1}, 0.5,
          {
            ease: FlxEase.expoOut,
            onComplete: function(_) {
              if (shouldUseSubstate && targetState is FlxSubState)
              {
                openSubState(cast targetState);
              }
              else
              {
                FlxG.sound.pause(); //? fix sound
                FlxG.switchState(targetState);
              }
            }
          });
      }
      else
      {
        if (shouldUseSubstate && targetState is FlxSubState)
        {
          openSubState(cast targetState);
        }
        else
        {
          FlxG.switchState(targetState);
        }
      }
    }

    super.update(elapsed);
  }

  #if ARCHIPELAGO_ALLOWED
  // Helper variables for Archipelago ranking (matching RankingSubstate)
  var comboRankSetLimit:Int = 7;
  var accRankSetLimit:Int = 15;

  function generateComboRank():String {
    if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits == 0 &&
        PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits == 0 &&
        PlayState.instance.comboManager.ratingsData[0].hits == 0) // Marvelous Full Combo
      return "MFC";
    else if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits == 0 &&
             PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits == 0) // Sick Full Combo
      return "SFC";
    else if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits == 0 &&
             PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits >= 1) // Good Full Combo
      return "GFC";
    else if (PlayState.instance.comboManager.songMisses == 0 && PlayState.instance.comboManager.ratingsData[2].hits >= 1 &&
             PlayState.instance.comboManager.ratingsData[3].hits == 0 && PlayState.instance.comboManager.ratingsData[1].hits >= 0) // Alright Full Combo
      return "AFC";
    else if (PlayState.instance.comboManager.songMisses == 0) // Regular Full Combo
      return "FC";
    else if (PlayState.instance.comboManager.songMisses < 10) // Single Digit Combo Breaks
      return "SDCB";
    else return "Clear"; // Good enough
  }

  function getComboRankLimit():Int {
    var comboRank = generateComboRank();
    switch(comboRank) {
      case "MFC": return 1;
      case "SFC": return 2;
      case "GFC": return 3;
      case "AFC": return 4;
      case "FC": return 5;
      case "SDCB": return 6;
      case "Clear": return 7;
      default: return 7;
    }
  }

  function generateAccuracyRank():String {
    var acc = CoolUtil.floorDecimal(PlayState.instance.comboManager.ratingPercent * 100, 2);
    if (acc >= 99.9935) return "P";
    else if (acc >= 99.980) return "X";
    else if (acc >= 99.950) return "X-";
    else if (acc >= 99.90) return "SS+";
    else if (acc >= 99.80) return "SS";
    else if (acc >= 99.70) return "SS-";
    else if (acc >= 99.50) return "S+";
    else if (acc >= 99) return "S";
    else if (acc >= 96.50) return "S-";
    else if (acc >= 93) return "A+";
    else if (acc >= 90) return "A";
    else if (acc >= 85) return "A-";
    else if (acc >= 80) return "B";
    else if (acc >= 70) return "C";
    else if (acc >= 60) return "D";
    else return "E";
  }

  function getAccuracyRankLimit():Int {
    var accRank = generateAccuracyRank();
    switch(accRank) {
      case "P": return 1;
      case "X": return 2;
      case "X-": return 3;
      case "SS+": return 4;
      case "SS": return 5;
      case "SS-": return 6;
      case "S+": return 7;
      case "S": return 8;
      case "S-": return 9;
      case "A+": return 10;
      case "A": return 11;
      case "A-": return 11;
      case "B": return 12;
      case "C": return 13;
      case "D": return 14;
      default: return 15;
    }
  }
  #end
}

typedef ResultsStateParams =
{
  /**
   * True if results are for a level, false if results are for a single song.
   */
  var storyMode:Bool;

  /**
   * True if results are for a playlist, false if results are for legit anything else.
   */
  var playlistMode:Bool;

  /**
   * Either "Song Name by Artist Name" or "Week Name"
   */
  var title:String;

  var songId:String;

  /**
   * The character ID for the song we just played.
   * @default `bf`
   */
   var ?characterId:String;

  /**
   * Whether the displayed score is a new highscore
   */
  var ?isNewHighscore:Bool;

  /**
   * The difficulty ID of the song/week we just played.
   * @default Normal
   */
  var ?difficultyId:String;

  /**
   * The score, accuracy, and judgements.
   */
  var scoreData:SaveScoreData;

  /**
   * The previous score data, used for rank comparision.
   */
  var prevScoreRank:ScoringRank; //? Added this field
};
