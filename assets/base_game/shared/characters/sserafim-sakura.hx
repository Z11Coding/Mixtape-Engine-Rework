import animate.internal.elements.FlxSpriteElement;
import funkin.play.character.CharacterType;
import stages.objects.SserafimLipSyncSprite;

typedef LipSyncData = {
  offset:Array<Int>,
  angle:Int
}

var lipSyncSprite:SserafimLipSyncSprite;

/**
 * A map of animation names to lip sync data.
 * This is so it gets offset properly!
 */
final LIP_SYNC_OFFSETS:Map<String, LipSyncData> = [
  'idle' =>
  {
    offset: [7, 2],
    angle: -14
  },
  'singUP' =>
  {
    offset: [8, 1],
    angle: -15
  },
  'singRIGHT' =>
  {
    offset: [7, 2],
    angle: -15
  },
  'singDOWN' =>
  {
    offset: [6, 3],
    angle: -15
  },
  'singLEFT' =>
  {
    offset: [7, 2],
    angle: -14
  },
  'singUP-joint' =>
  {
    offset: [10, -1],
    angle: -14
  },
  'singRIGHT-joint' =>
  {
    offset: [6, 3],
    angle: -15
  },
  'singDOWN-joint' =>
  {
    offset: [5, 5],
    angle: -15
  },
  'singLEFT-joint' =>
  {
    offset: [7, 2],
    angle: -16
  }
];

function onCreatePost()
{
  lipSyncSprite = new SserafimLipSyncSprite(0, 0);
  lipSyncSprite.flipX = true;

  var element:FlxSpriteElement = new FlxSpriteElement(lipSyncSprite);
  element.active = false; // We disable the element here so we can control when it updates.

  for (frame in boyfriend.getFramesWithKeyword("mouth edit"))
  {
    frame.add(element);
  }
}

function goodNoteHitPre(note:Note)
{
  // Override the hit note animation.
  switch (note.noteType)
  {
    case "sakura-joint": // joint animations, sakura and bf sing
      note.noAnimation = true;
    case "sakura-bf1": // bf animations, only bf sings
      note.noAnimation = true;
    case "sakura-bf2": // alternate bf poses
      note.noAnimation = true;

  }
}

function goodNoteHit(note:Note)
{
  // Override the hit note animation.
  switch (note.noteType)
  {
    case "sakura-joint": // joint animations, sakura and bf sing
      holdTimer = 0;
      game.playAnim(note, boyfriend, Note.keysShit.get(PlayState.mania).get("anims")[note.column]+'-both', false);
    case "sakura-bf1": // bf animations, only bf sings
      holdTimer = 0;
      game.playAnim(note, boyfriend, Note.keysShit.get(PlayState.mania).get("anims")[note.column]+'-bf', false);
    case "sakura-bf2": // alternate bf poses
      holdTimer = 0;
      game.playAnim(note, boyfriend, Note.keysShit.get(PlayState.mania).get("anims")[note.column]+'-bfA', false);
  }
}

function preNoteMiss(note:Note)
{
  // Override the miss note animation.
  switch (note.noteType)
  {
    case "sakura-joint": // joint animations, sakura and bf sing
      note.animSuffix = '-both';
    case "sakura-bf1" || "sakura-bf2": // bf animations, only bf sings
      note.animSuffix = '-bf';
  }
}

function onPlayAnim(name:String, forced:Bool, restart:Bool, frame:Int)
{
  if (LIP_SYNC_OFFSETS.exists(name) && lipSyncSprite != null)
  {
    var data:LipSyncData = LIP_SYNC_OFFSETS.get(name);

    lipSyncSprite.offset.set(data.offset[0], data.offset[1]);
    lipSyncSprite.angle = data.angle;
  }

  if (name == "firstDeath")
  {
    if (!boyfriend.visible)
    {
      boyfriend.visible = true;
    }

    // Hide the opponent health icon so it doesn't show up briefly when the song restarts
    game.iconP2.visible = false;

    // Clear out any shaders this character might have.
    boyfriend.shader = null;
  }
}

function update(elapsed:Float)
{
  lipSyncSprite.update(elapsed);

  lipSyncSprite.shouldSing = boyfriend.characterType == CharType.BF;

  synchronizeShader();
}

var currentShader = null;

function synchronizeShader()
{
  if (currentShader == boyfriend.shader) return;

  currentShader = boyfriend.shader;

  lipSyncSprite.shader = currentShader;

  trace("Synchronized shader between children!");
}

function hideDefaultMouth()
{
  var symbolItem:SymbolItem = boyfriend.library.getSymbol('mouth default');
  var layer:Layer = symbolItem.timeline.getLayer(0);

  layer.forEachFrame((frame) -> {
    frame.forEachElement((element) -> {
      element.visible = false;
    });
  });
}
