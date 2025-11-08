package states.freeplay.vslice.obj;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import openfl.utils.AssetType;

/**
 * The icon that gets used for Freeplay capsules and char select
 * Adapted from P-Slice for Mixtape Engine
 * NOT to be confused with the CharIcon class, which is for the in-game icons
 */
class PixelatedIcon extends FlxSprite
{
  private inline static final ICON_FRAMERATE = 10;
	public var type:IconType;
  public function new(x:Float, y:Float)
  {
    super(x, y);
    this.makeGraphic(32, 32, 0x00000000);
    this.antialiasing = false;
    this.active = false;
  }

  public function setCharacter(char:String):Void
  {
    if (char.startsWith("icon-")) char = char.replace("icon-","");

    // First try V-Slice style pixel icons
    var vslicePixelPath = 'freeplay/icons/${char}pixel';
    if (Paths.fileExists('images/${vslicePixelPath}.xml', AssetType.TEXT, false, 'vslice')) {
        // Animated V-Slice icon
        type = ANIMATED;
        frames = Paths.getSparrowAtlas(vslicePixelPath, 'vslice');
        this.active = true;
        this.scale.x = this.scale.y = 2;
        this.updateHitbox();
        this.animation.addByPrefix('idle', 'idle0', ICON_FRAMERATE, true);
        this.animation.addByPrefix('confirm', 'confirm0', ICON_FRAMERATE, false);
        this.animation.addByPrefix('confirm-hold', 'confirm-hold0', ICON_FRAMERATE, true);

        this.animation.finishCallback = function(name:String):Void {
          if (name == 'confirm') this.animation.play('confirm-hold');
        };
        this.origin.x = 25;
    }
    else if (Paths.fileExists('images/${vslicePixelPath}.png', IMAGE, false, 'vslice')) {
        // Static V-Slice pixel icon
        type = PIXEL;
        var image = Paths.image(vslicePixelPath, 'vslice');
        this.loadGraphic(image);
        this.scale.x = this.scale.y = 2;
        this.updateHitbox();
        animation.add("idle",[0],ICON_FRAMERATE,false);
        animation.add("confirm",[0],ICON_FRAMERATE,false);
        this.origin.x = 25;
    }
    else {
        // Fallback to legacy FNF icon
        type = LEGACY;
        var charPath = 'icons/icon-${char}';
        var image = Paths.image(charPath);

        if (image == null) {
          trace('[WARN] Character ${char} has no freeplay icon.');
          image = Paths.image("icons/icon-face");
        }

        this.loadGraphic(image, true, Math.floor(image.width / 2), Math.floor(image.height));
        animation.add("idle",[0],ICON_FRAMERATE,false);
        animation.add("confirm",[1],ICON_FRAMERATE,false);
        this.scale.x = this.scale.y = 0.58;
        this.updateHitbox();
        this.origin.x = 100;
    }

    animation.play("idle");
  }
}
enum IconType {
  LEGACY;
  PIXEL;
  ANIMATED;
}
