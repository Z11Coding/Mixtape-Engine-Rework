package objects;

import flixel.sound.FlxSound;
import funkin.vis.dsp.SpectralAnalyzer;

//Yoinked from NovaFlare Engine
//This'll be fun to find excuses to use this
class AudioDisplay extends FlxSpriteGroup
{
    var analyzer:SpectralAnalyzer;

    public var snd:FlxSound;
    var _height:Int;
    var line:Int;

    public function new(snd:FlxSound = null, X:Float = 0, Y:Float = 0, Width:Int, Height:Int, line:Int, gap:Int, Color:FlxColor)
    {
      super(X, Y);
  
      this.snd = snd;
      this.line = line;

      for (i in 0...line)
      {
        var newLine = new FlxSprite().makeGraphic(Std.int(Width / line - gap), 1, Color);
        newLine.x = (Width / line) * i;
        add(newLine);
      }
      _height = Height;

      @:privateAccess
      if (snd != null) 
      {
        analyzer = new SpectralAnalyzer(snd._channel.__audioSource, Std.int(line * 1 + Math.abs(0.05 * (4 - ClientPrefs.data.audioDisplayQuality))), 1, 5);
        analyzer.fftN = 256 * ClientPrefs.data.audioDisplayQuality;  
      }
    }

    public var stopUpdate:Bool = false;
    var saveTime:Float = 0;    
    var getValues:Array<funkin.vis.dsp.Bar>;
    
    override function update(elapsed:Float)
    {
      if (stopUpdate) return;
      
      if (saveTime < ClientPrefs.data.audioDisplayUpdate) {
        saveTime += (elapsed * 1000);
        
        updateLine(elapsed);
        return;
      } else {
        saveTime = 0;
      }

      
      getValues = analyzer.getLevels();
      updateLine(elapsed);
      
      super.update(elapsed);
    }

    function addAnalyzer(snd:FlxSound) {
      @:privateAccess
      if (snd != null && analyzer == null) 
      {
        analyzer = new SpectralAnalyzer(snd._channel.__audioSource, Std.int(line * 1 + Math.abs(0.05 * (4 - ClientPrefs.data.audioDisplayQuality))), 1, 5);
        analyzer.fftN = 256 * ClientPrefs.data.audioDisplayQuality;       
      }
    }
    
    function updateLine(elapsed:Float) {
        if (getValues == null) return;
        
        for (i in 0...members.length)
        {
          if (flipY) {
            var animFrame:Int = Math.round(-getValues[i].value * _height);
        
            animFrame = Math.round(animFrame * FlxG.sound.volume);
        
            members[i].scale.y = FlxMath.lerp(animFrame, members[i].scale.y, Math.exp(-elapsed * 16));
            if (members[i].scale.y > _height / 40) members[i].scale.y = _height / 40;
            members[i].y = this.y -members[i].scale.y / 2;
          } else {
            var animFrame:Int = Math.round(getValues[i].value * _height);
        
            animFrame = Math.round(animFrame * FlxG.sound.volume);
        
            members[i].scale.y = FlxMath.lerp(animFrame, members[i].scale.y, Math.exp(-elapsed * 16));
            if (members[i].scale.y < _height / 40) members[i].scale.y = _height / 40;
            members[i].y = this.y -members[i].scale.y / 2;
          }
        }
    }

    public function changeAnalyzer(snd:FlxSound) 
    {
      @:privateAccess
      analyzer.changeSnd(snd._channel.__audioSource);

      stopUpdate = false;
    }

    public function clearUpdate() {
      for (i in 0...members.length)
      {
        members[i].scale.y = _height / 40;
        members[i].y = this.y -members[i].scale.y / 2;
      }
    }
}