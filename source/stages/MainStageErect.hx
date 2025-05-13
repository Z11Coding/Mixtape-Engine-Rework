package stages;

import stages.PicoCapableStage;
import openfl.display.BlendMode;
import shaders.AdjustColorShader;
import stages.objects.StageSpotlight;
import objects.Character;
import objects.Note;

class MainStageErect extends BaseStage {
   
	var peeps:BGSprite;
	override function create()
	{
        new StageSpotlight(200,-50);
		var bg:BGSprite = new BGSprite('erect/backDark', 729, -170);
		add(bg);

        if(!ClientPrefs.data.lowQuality) {
            peeps = new BGSprite('erect/crowd', 560, 290,0.8,0.8,["Symbol 2 instance 10"],true);
            peeps.animation.curAnim.frameRate = 12;
            add(peeps);

            var lightSmol = new BGSprite('erect/brightLightSmall',967, -103,1.2,1.2);
            lightSmol.blend = BlendMode.ADD;
            add(lightSmol);
        }

		var stageFront:BGSprite = new BGSprite('erect/bg', -603, -187);
		add(stageFront);

        var server:BGSprite = new BGSprite('erect/server', -361, 205);
		add(server);

		if(!ClientPrefs.data.lowQuality) {
			var greenLight:BGSprite = new BGSprite('erect/lightgreen', -171, 242);
            greenLight.blend = BlendMode.ADD;
			add(greenLight);

            var redLight:BGSprite = new BGSprite('erect/lightred', -101, 560);
            redLight.blend = BlendMode.ADD;
			add(redLight);

            var orangeLight:BGSprite = new BGSprite('erect/orangeLight', 189, -195);
            orangeLight.blend = BlendMode.ADD;
			add(orangeLight);
		}

        var beamLol:BGSprite = new BGSprite('erect/lights', -601, -147,1.2,1.2);
		add(beamLol);

        if(!ClientPrefs.data.lowQuality) {
			var TheOneAbove:BGSprite = new BGSprite('erect/lightAbove', 804, -117);
            TheOneAbove.blend = BlendMode.ADD;
			add(TheOneAbove);
        }
	}

    override function createPost() {
        super.createPost();
        if(ClientPrefs.data.shaders){
            gf.shader = makeCoolShader(-9,0,-30,-4);
            dad.shader = makeCoolShader(-32,0,-33,-23);
            boyfriend.shader = makeCoolShader(12,0,-23,7);
            PicoCapableStage.instance?.applyABotShader(makeCoolShader(-9,0,-30,-4));
        }
    }

    function makeCoolShader(hue:Float,sat:Float,bright:Float,contrast:Float) {
        var coolShader = new AdjustColorShader();
        coolShader.hue = hue;
        coolShader.saturation = sat;
        coolShader.brightness = bright;
        coolShader.contrast = contrast;
        return coolShader;
    }
}