package objects;

import backend.ClientPrefs;
import backend.Language;
import backend.Paths;
import backend.Rating;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class JudCounter extends FlxTypedGroup<FlxText>
{
  // Individual texts for each judgment
  var marvsText:FlxText;
  var sicksText:FlxText;
  var goodsText:FlxText;
  var badsText:FlxText;
  var shitsText:FlxText;
  var missesText:FlxText;
  var comboText:FlxText;
  var maxComboText:FlxText;

  // Colors for each judgment
  static final MARVS_COLOR:FlxColor = 0xFFA17FFF;  // Purple
  static final SICKS_COLOR:FlxColor = 0xFF7FC9FF;  // Cyan
  static final GOODS_COLOR:FlxColor = 0xFF7FFF8E;  // Green
  static final BADS_COLOR:FlxColor = 0xFF888888;   // Grey
  static final SHITS_COLOR:FlxColor = 0xFFFF7F7F;  // light red
  static final MISSES_COLOR:FlxColor = FlxColor.RED; // Red
  static final COMBO_COLOR:FlxColor = FlxColor.WHITE; // No color - white
  static final MAX_COMBO_COLOR:FlxColor = FlxColor.WHITE; // No color - white

  // Variables for the bump effect
  var bumpTweens:Map<FlxText, FlxTween> = new Map<FlxText, FlxTween>();

  // ← TRANSLATION CACHE FOR OPTIMIZATION
  var cachedLabels:Array<String> = [];
  var lastVisibilityState:Bool = false;
  var lastValues:Array<Int> = [-1, -1, -1, -1, -1, -1, -1, -1]; // Cache to avoid unnecessary updates

  // Configuration
  public var baseX:Float = 10;
  public var baseY:Float = 0;
  public var fontSize:Int = 20;
  public var spacing:Float = 22; // More together

  public function new(x:Float = 10, y:Float = 0)
  {
    super();

    baseX = x;
    baseY = y;

    // Calculate Y centered vertically
    if (baseY == 0)
      baseY = (FlxG.height / 2) - 100;

    // ← INITIALIZE TRANSLATION CACHE
    cacheLabels();
    createTexts();
    updateVisibility();
  }

  // ← NEW FUNCTION TO CACHE TRANSLATIONS -NOW OPTIMIZED
  function cacheLabels():Void {
    var keys = [
      'judgement_marvs', 'judgement_sicks', 'judgement_goods', 'judgement_bads',
      'judgement_shits', 'judgement_misses', 'judgement_combo', 'judgement_max_combo'
    ];
    var defaults = [
      'Marvs', 'Sicks', 'Goods', 'Bads', 'Shits', 'Misses', 'Combo', 'M. Combo'
    ];

    // ← USE THE NEW OPTIMIZED FEATURE OF THE Language SYSTEM
    cachedLabels = Language.cacheSpecificPhrases(keys, defaults);
  }

  function createTexts()
  {
    // ← USE CACHE INSTEAD OF REPEATED CALLS TO Language.getPhrase
    marvsText = createJudgmentText(cachedLabels[0] + ':  0', MARVS_COLOR, 0);
    sicksText = createJudgmentText(cachedLabels[1] + ':  0', SICKS_COLOR, 1);
    goodsText = createJudgmentText(cachedLabels[2] + ':  0', GOODS_COLOR, 2);
    badsText = createJudgmentText(cachedLabels[3] + ':   0', BADS_COLOR, 3);
    shitsText = createJudgmentText(cachedLabels[4] + ':  0', SHITS_COLOR, 4);
    missesText = createJudgmentText(cachedLabels[5] + ': 0', MISSES_COLOR, 5);
    comboText = createJudgmentText(cachedLabels[6] + ':    0', COMBO_COLOR, 6);
    maxComboText = createJudgmentText(cachedLabels[7] + ': 0', MAX_COMBO_COLOR, 7);

    // Add to group
    add(marvsText);
    add(sicksText);
    add(goodsText);
    add(badsText);
    add(shitsText);
    add(missesText);
    add(comboText);
    add(maxComboText);
  }

  function createJudgmentText(text:String, color:FlxColor, index:Int):FlxText
  {
    var judText = new FlxText(baseX, baseY + (spacing * index), 0, text, fontSize);
    judText.setFormat(Paths.font("vcr.ttf"), fontSize, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    judText.scrollFactor.set();
    judText.alpha = 1;
    judText.borderSize = 2;
    return judText;
  }

  public function updateCounter(ratingsData:Array<Rating>, songMisses:Int, combo:Int, maxCombo:Int)
  {
    var currentVisible = ClientPrefs.data.judgementCounter;

    // ← ONLY UPDATE VISIBILITY IF IT REALLY CHANGED
    if (currentVisible != lastVisibilityState) {
      updateVisibility();
    }

    if (!currentVisible) return;

    // ← VALUES CACHE TO AVOID UNNECESSARY UPDATES
    var newValues = [
      ratingsData[0].hits,
      ratingsData[1].hits,
      ratingsData[2].hits,
      ratingsData[3].hits,
      ratingsData[4].hits,
      songMisses,
      combo,
      maxCombo
    ];

    // ← ONLY UPDATE TEXTS THAT ACTUALLY CHANGED
    for (i in 0...newValues.length) {
      if (newValues[i] != lastValues[i]) {
        updateSingleText(i, newValues[i]);
        lastValues[i] = newValues[i];
      }
    }
  }

  // ← NEW OPTIMIZED FUNCTION TO UPDATE INDIVIDUAL TEXTS
  function updateSingleText(index:Int, value:Int):Void {
    switch (index) {
      case 0: marvsText.text = cachedLabels[0] + ': $value';
      case 1: sicksText.text = cachedLabels[1] + ': $value';
      case 2: goodsText.text = cachedLabels[2] + ': $value';
      case 3: badsText.text = cachedLabels[3] + ': $value';
      case 4: shitsText.text = cachedLabels[4] + ': $value';
      case 5: missesText.text = cachedLabels[5] + ': $value';
      case 6: comboText.text = cachedLabels[6] + ': $value';
      case 7: maxComboText.text = cachedLabels[7] + ': $value';
    }
  }

  public function updateVisibility()
  {
    var shouldShow = ClientPrefs.data.judgementCounter;
    forEach(function(text:FlxText) {
      text.visible = shouldShow;
    });
    lastVisibilityState = shouldShow;
  }

  // Bump effect when a note is hit
  public function doBump(judgmentIndex:Int)
  {
    if (!ClientPrefs.data.judgementCounter) return;

    var targetText:FlxText = null;

    switch(judgmentIndex) {
      case 0: targetText = marvsText;
      case 1: targetText = sicksText;
      case 2: targetText = goodsText;
      case 3: targetText = badsText;
      case 4: targetText = shitsText;
      default: return; // Invalid index
    }

    if (targetText == null) return;

    // ← OPTIMIZATION: Cancel previous tween more efficiently
    var existingTween = bumpTweens.get(targetText);
    if (existingTween != null) {
      existingTween.cancel();
      bumpTweens.remove(targetText);
    }

    // bump effect
    targetText.scale.set(1.5, 1.5);
    var bumpTween = FlxTween.tween(targetText.scale, {x: 1, y: 1}, 0.15, {
      ease: FlxEase.expoOut,
      onComplete: function(twn:FlxTween) {
        bumpTweens.remove(targetText);
      }
    });

    bumpTweens.set(targetText, bumpTween);
  }

  // Bump effect for combo
  public function doComboBump()
  {
    if (!ClientPrefs.data.judgementCounter) return;

    // ← OPTIMIZATION: Improve tween cancellation
    var existingTween = bumpTweens.get(comboText);
    if (existingTween != null) {
      existingTween.cancel();
      bumpTweens.remove(comboText);
    }

    comboText.scale.set(1.5, 1.5);
    var comboTween = FlxTween.tween(comboText.scale, {x: 1, y: 1}, 0.3, {
      ease: FlxEase.expoOut,
      onComplete: function(twn:FlxTween) {
        bumpTweens.remove(comboText);
      }
    });
    bumpTweens.set(comboText, comboTween);
  }

  // Bump effect for max combo
  public function doMaxComboBump()
  {
    if (!ClientPrefs.data.judgementCounter) return;

    var existingTween = bumpTweens.get(maxComboText);
    if (existingTween != null) {
      existingTween.cancel();
      bumpTweens.remove(maxComboText);
    }

    maxComboText.scale.set(1.5, 1.5);
    var maxTween = FlxTween.tween(maxComboText.scale, {x: 1, y: 1}, 0.3, {
      ease: FlxEase.expoOut,
      onComplete: function(twn:FlxTween) {
        bumpTweens.remove(maxComboText);
      }
    });
    bumpTweens.set(maxComboText, maxTween);
  }

  // Bump effect for missions
  public function doMissBump()
  {
    if (!ClientPrefs.data.judgementCounter) return;

    var existingTween = bumpTweens.get(missesText);
    if (existingTween != null) {
      existingTween.cancel();
      bumpTweens.remove(missesText);
    }

    missesText.scale.set(1.5, 1.5);
    var missTween = FlxTween.tween(missesText.scale, {x: 1, y: 1}, 0.3, {
      ease: FlxEase.elasticOut,
      onComplete: function(twn:FlxTween) {
        bumpTweens.remove(missesText);
      }
    });
    bumpTweens.set(missesText, missTween);
  }

  // Set up cameras
  public function setCameras(cameras:Array<flixel.FlxCamera>)
  {
    forEach(function(text:FlxText) {
      text.cameras = cameras;
    });
  }

  // ← NEW FEATURE TO UPDATE TRANSLATIONS WHEN THE LANGUAGE CHANGE
  public function refreshLanguage():Void {
    cacheLabels();
    // Force full update
    for (i in 0...lastValues.length) {
      lastValues[i] = -1;
    }
  }

  // Reset the counter
  public function setPosition(x:Float, y:Float)
  {
    baseX = x;
    baseY = y;

    var index = 0;
    forEach(function(text:FlxText) {
      text.setPosition(baseX, baseY + (spacing * index));
      index++;
    });
  }

  override function destroy()
  {
    // Clean tweens
    for (tween in bumpTweens) {
      if (tween != null) tween.cancel();
    }
    bumpTweens.clear();

    super.destroy();
  }
}
