package stages.objects;

import backend.FunkinSound;
import cutscenes.CutsceneHandler;
class PicoDopplegangerSprite extends FunkinSprite
{

  public var isPlayer:Bool = false;
  var suffix:String = '';

  public function new(x:Float, y:Float)
  {
    super(x, y);
    loadTextureAtlas('philly/erect/cutscenes/pico_doppleganger', "week3");
  }

  var cutsceneSounds:FunkinSound = null;

  public function cancelSounds(){
    if(cutsceneSounds != null) cutsceneSounds.destroy();
  }

  public function doAnim(_suffix:String, shoot:Bool = false, explode:Bool = false, cutsceneHandler:CutsceneHandler){
    suffix = _suffix;

    trace('Doppelganger: doAnim(' + suffix + ', ' + shoot + ', ' + explode + ')');

    cutsceneHandler.timer(0.3, () -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoGasp'), 1.0, false, true, true);});

    if(shoot == true){
      anim.play("shoot" + suffix, true, false);

      cutsceneHandler.timer(6.29, () -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoShoot'), 1.0, false, true, true);});
      cutsceneHandler.timer(10.33, () -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoSpin'), 1.0, false, true, true);});
    }else{
      if(explode == true){
        anim.play("explode" + suffix, true, false);

        anim.onFinish.add(startLoop);

        cutsceneHandler.timer(3.7, () -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoCigarette2'), 1.0, false, true, true);});
        cutsceneHandler.timer(8.75, () -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoExplode'), 1.0, false, true, true);});
        cutsceneHandler.objects.remove(this);
      }else{
        anim.play("cigarette" + suffix, true, false);

        cutsceneHandler.timer(3.7, () -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoCigarette'), 1.0, false, true, true);});
      }
    }
  }

  function startLoop(x:String){
    anim.play("loop" + suffix, true, false);
  }
}
