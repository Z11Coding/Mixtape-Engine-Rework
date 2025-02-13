package substates;

import flixel.FlxSprite;
import haxe.Json;
import lime.utils.Assets;
import objects.FunkinSprite;
// import flxtyped group
import substates.MusicBeatSubstate;
import states.StoryMenuState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxSignal;
import states.menus.MainMenuState;
import flixel.addons.transition.FlxTransitionableState;
import openfl.display.BitmapData;
import states.FreeplayState;
import openfl.geom.Matrix;
//import backend.FunkinSound;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import flixel.FlxState;

using Lambda;
using StringTools;

class StickerSubState extends MusicBeatSubstate
{
  public static var grpStickers:FlxTypedGroup<StickerSprite>;

  // yes... a damn OpenFL sprite!!!
  public var dipshit:Sprite;

  /**
   * The state to switch to after the stickers are done.
   * This is a FUNCTION so we can pass it directly to `FlxG.switchState()`,
   * and we can add constructor parameters in the caller.
   */
  var targetState:StickerSubState->FlxState;

  // what "folders" to potentially load from (as of writing only "keys" exist)
  var soundSelections:Array<String> = [];
  // what "folder" was randomly selected
  var soundSelection:String = "";
  var sounds:Array<String> = [];

  public function new(?oldStickers:Array<StickerSprite>, ?targetState:StickerSubState->FlxState):Void
  {
    super();

    if (oldStickers == null && targetState == null) 
    {
      return;
    }
    this.targetState = (targetState == null) ? ((sticker) -> new MainMenuState()) : targetState;

    // todo still
    // make sure that ONLY plays mp3/ogg files
    // if there's no mp3/ogg file, then it regenerates/reloads the random folder

    var assetsInList = openfl.utils.Assets.list();

    var soundFilterFunc = function(a:String) {
      return a.startsWith('assets/shared/sounds/stickersounds/');
    };

    soundSelections = assetsInList.filter(soundFilterFunc);
    soundSelections = soundSelections.map(function(a:String) {
      return a.replace('assets/shared/sounds/stickersounds/', '').split('/')[0];
    });

    // cracked cleanup... yuchh...
    for (i in soundSelections)
    {
      while (soundSelections.contains(i))
      {
        soundSelections.remove(i);
      }
      soundSelections.push(i);
    }

    //trace(soundSelections);

    soundSelection = FlxG.random.getObject(soundSelections);

    var filterFunc = function(a:String) {
      return a.startsWith('assets/shared/sounds/stickersounds/' + soundSelection + '/');
    };
    var assetsInList3 = openfl.utils.Assets.list();
    sounds = assetsInList3.filter(filterFunc);
    for (i in 0...sounds.length)
    {
      sounds[i] = sounds[i].replace('assets/shared/sounds/', '');
      sounds[i] = sounds[i].substring(0, sounds[i].lastIndexOf('.'));
    }

    //trace(sounds);

    grpStickers = new FlxTypedGroup<StickerSprite>();
    add(grpStickers);

    // makes the stickers on the most recent camera, which is more often than not... a UI camera!!
    // grpStickers.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    grpStickers.cameras = FlxG.cameras.list;

    if (oldStickers != null)
    {
      for (sticker in oldStickers)
      {
        grpStickers.add(sticker);
      }

      degenStickers();
    }
    else
      regenStickers();
  }

  public function degenStickers():Void
  {
    grpStickers.cameras = FlxG.cameras.list;

    /*
      if (dipshit != null)
      {
        FlxG.removeChild(dipshit);
        dipshit = null;
      }
     */

    if (grpStickers.members == null || grpStickers.members.length == 0)
    {
      switchingState = false;
      close();
      return;
    }

    for (ind => sticker in grpStickers.members)
    {
      grpStickers.visible = false;
      new FlxTimer().start(sticker.timing, _ -> {
        sticker.visible = false;
        var daSound:String = FlxG.random.getObject(sounds);
        //FunkinSound.playOnce(Paths.sound(daSound));
        //if (!ClientPrefs.data.audioBreak) FlxG.sound.play(Paths.sound(daSound));
        //else FlxG.sound.play(Paths.sound(funny[FlxG.random.int(0,1)]));

        if (grpStickers == null || ind == grpStickers.members.length - 1)
        {
          MusicBeatState.emptyStickers = null;
          switchingState = false;
          close();
        }
      });
    }
  }

  function getRandomStickerSet(stickers:Map<String, Array<String>>):String {
    var stickerSets:Array<String> = [];
    for (stickerSet in stickers.keys()) {
      stickerSets.push(stickerSet);
    }
    var totalWeight:Int = 0;
    var weights:Array<Int> = [];

    for (stickerSet in stickerSets) {
      var weight:Int = stickers.get(stickerSet).length;
      totalWeight += weight;
      weights.push(totalWeight);
    }

    var randomValue:Int = FlxG.random.int(0, totalWeight - 1);

    for (i in 0...weights.length) {
      if (randomValue < weights[i]) {
      //trace(stickerSets[i]);
      return stickerSets[i];
      }
    }

    //trace("");
    return "";
    }

  var funny = ['AB1', 'AB2'];
  function regenStickers():Void
  {
    if (grpStickers.members.length > 0)
    {
      grpStickers.clear();
    }

    var stickerInfo:StickerInfo = new StickerInfo('stickers-set-1');
    var stickers:Map<String, Array<String>> = new Map<String, Array<String>>();
    for (stickerSets in stickerInfo.getPack("all"))
    {
      stickers.set(stickerSets, stickerInfo.getStickers(stickerSets));
    }

    var xPos:Float = -100;
    var yPos:Float = -100;
    //var loopCount:Int = 0; // Add a loop count variable
    while (xPos <= FlxG.width /*&& loopCount < 100*/) // Add a condition to limit the loop count
    {
      var stickerSet:String = getRandomStickerSet(stickers);
      var sticker:String = FlxG.random.getObject(stickers.get(stickerSet));
      var sticky:StickerSprite = new StickerSprite(0, 0, stickerInfo.name, sticker);


      sticky.visible = false;

      sticky.x = xPos;
      sticky.y = yPos;
      xPos += sticky.frameWidth * 0.5;

      if (xPos >= FlxG.width)
      {
        if (yPos <= FlxG.height)
        {
          xPos = -100;
          yPos += FlxG.random.float(70, 120);
        }
      }

      sticky.angle = FlxG.random.int(-60, 70);
      grpStickers.add(sticky);

      //loopCount++; // Increment the loop count
    }

    FlxG.random.shuffle(grpStickers.members);

    for (ind => sticker in grpStickers.members)
    {
      sticker.timing = FlxMath.remapToRange(ind, 0, grpStickers.members.length, 0, 0.9);

      new FlxTimer().start(sticker.timing, _ -> {
        if (grpStickers == null) return;

        sticker.visible = true;
        var daSound:String = FlxG.random.getObject(sounds);
        if (!backend.ClientPrefs.data.audioBreak) FlxG.sound.play(Paths.sound(daSound));
        else FlxG.sound.play(Paths.sound(funny[FlxG.random.int(0,1)]));

        var frameTimer:Int = FlxG.random.int(0, 2);

        if (ind == grpStickers.members.length - 1) frameTimer = 2;

        new FlxTimer().start((1 / 24) * frameTimer, _ -> {
          if (sticker == null) return;

          sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);

          if (ind == grpStickers.members.length - 1)
          {
            switchingState = true;

            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;

            FlxG.switchState(() -> {
              FunkinSprite.preparePurgeCache();
              FunkinSprite.purgeCache();
              MusicBeatState.emptyStickers = new StickerSubState(grpStickers.members);
              MusicBeatState.reopen = true;

              backend.TransitionState.currenttransition = null;
              return targetState(this);
            });
          }
        });
      });
   
    }

    grpStickers.sort((ord, a, b) -> {
      return FlxSort.byValues(ord, a.timing, b.timing);
    });

    var lastOne:StickerSprite = grpStickers.members[grpStickers.members.length - 1];
    lastOne.updateHitbox();
    lastOne.angle = 0;
    lastOne.screenCenter();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // if (FlxG.keys.justPressed.ANY)
    // {
    //   regenStickers();
    // }
  }

  var switchingState:Bool = false;

  override public function close():Void
  {
    if (switchingState) return;
    super.close();
  }

  override public function destroy():Void
  {
    if (switchingState) return;
    super.destroy();
  }
}

class StickerSprite extends objects.FunkinSprite
{
  public var timing:Float = 0;

  public function new(x:Float, y:Float, stickerSet:String, stickerName:String):Void
  {
    super(x, y);
    loadSticker('' + stickerSet + '/' + stickerName);
    updateHitbox();
    scrollFactor.set();
  }
}

class StickerInfo
{
  public var name:String;
  public var artist:String;
  public var stickers:Map<String, Array<String>>;
  public var stickerPacks:Map<String, Array<String>>;

  public function new(stickerSet:String):Void
  {
    var path = Paths.file('images/transitionSwag/' + stickerSet + '/stickers.json');
    var json = Json.parse(Assets.getText(path));

    // doin this dipshit nonsense cuz i dunno how to deal with casting a json object with
    // a dash in its name (sticker-packs)
    var jsonInfo:StickerShit = cast json;

    this.name = jsonInfo.name;
    this.artist = jsonInfo.artist;

    stickerPacks = new Map<String, Array<String>>();

    for (field in Reflect.fields(json.stickerPacks))
    {
      var stickerFunny = json.stickerPacks;
      var stickerStuff = Reflect.field(stickerFunny, field);

      stickerPacks.set(field, cast stickerStuff);
    }

    // creates a similar for loop as before but for the stickers
    stickers = new Map<String, Array<String>>();

    for (field in Reflect.fields(json.stickers))
    {
      var stickerFunny = json.stickers;
      var stickerStuff = Reflect.field(stickerFunny, field);

      stickers.set(field, cast stickerStuff);
    }
  }

  public function getStickers(stickerName:String):Array<String>
  {
    return this.stickers[stickerName];
  }

  public function getPack(packName:String):Array<String>
  {
    return this.stickerPacks[packName];
  }
}

// somethin damn cute just for the json to cast to!
typedef StickerShit =
{
  name:String,
  artist:String,
  stickers:Map<String, Array<String>>,
  stickerPacks:Map<String, Array<String>>
}