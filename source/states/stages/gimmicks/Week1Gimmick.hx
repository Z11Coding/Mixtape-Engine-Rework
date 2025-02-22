package states.stages.gimmicks;

import objects.Bar; 
import backend.modchart.SubModifier;
import flixel.tweens.FlxEase;

enum CrowdState
{
    MAD;
    UNHAPPY;
    NEUTRAL;
    HAPPY;
    VIBING;
    NONE; //for the lastState specifically
} 

class Week1Gimmick extends Bar 
{
    /**
     * The current amount the crowd is appeased
     */
    public var crowdAppeasment:Float = 50;

    /**
     * The current amount of drain that is applied
     * (WARNING! THIS WILL DRAIN THE BAR EVERY FRAME!)  
     */
    public var crowdAttentionLoss:Float = 0.02;
    
    /**
     * Toggles the health drain
     */
    public var allowDrain:Bool = false;
    
    /**
     * Toggles the ability to kill the player
     */
    public var canKill:Bool = true;

    /**
     * Toggles the clapping on beat (VIBING MODE ONLY!)
     */
    var enableClapping:Bool = true;

    /**
     * The Crowd "Boo" sfx
     */
    public var crowdBoo:FlxSound;
    /**
     * The Crowd "Cheer" sfx
     */
    public var crowdCheer:FlxSound;
    /**
     * The Crowd "Clap" sfx
     * do keep in mind, this plays on beat!
     */
    public var crowdClap:FlxSound;
    /**
     * The state the crowd is in. They can be either:
     * Vibing
     * Happy
     * Neutral
     * Unhappy
     * Mad
     */
    public var crowdState(default, set):CrowdState = NEUTRAL;    
    /**
     * Calls the "onCrowdMad" Callback
     */
    public var onCrowdMad:Void->Void;
    /**
     * Calls the "onCrowdUnhappy" Callback
     */
    public var onCrowdUnhappy:Void->Void;
    /**
     * Calls the "onCrowdNeutral" Callback
     */
    public var onCrowdNeutral:Void->Void;
    /**
     * Calls the "onCrowdHappy" Callback
     */
    public var onCrowdHappy:Void->Void;
    /**
     * Calls the "onCrowdVibing" Callback
     */
    public var onCrowdVibing:Void->Void;
    override public function new()
    {
        super(-30, 200, 'mechanics/week1/crowdPleaser', function() return crowdAppeasment, 0, 100);
        createGimmick();
    }

    public function createGimmick() 
    {
        if (PlayState.instance.modManager != null) PlayState.instance.modManager.quickRegister(new SubModifier('noteShake', PlayState.instance.modManager));
		if (PlayState.instance.modManager != null) PlayState.instance.modManager.setValue('noteShake', 0);
        angle = 90;
        setColors(FlxColor.BLACK, FlxColor.BLUE);
        leftToRight = false;
        regenerateClips();
        crowdAppeasment = 50;
        //precache the sounds
        crowdBoo = new FlxSound().loadEmbedded(Paths.sound('gimmicks/week1/crowdBoo'));
        crowdBoo.volume = 0.000000001;
        crowdBoo.play();
        crowdCheer = new FlxSound().loadEmbedded(Paths.sound('gimmicks/week1/crowdCheer'));
        crowdCheer.volume = 0.000000001;
        crowdCheer.play();
        crowdClap = new FlxSound().loadEmbedded(Paths.sound('gimmicks/week1/crowdClap'));
        crowdClap.volume = 0.000000001;
        crowdClap.play();
    }

    /**
     * Acutally starts the mechanic
     */
    public function startGimmick() {
        crowdAppeasment = 50;
        allowDrain = true;
    }

    /**
     * Pauses the mechanic
     */
    public function pauseGimmick() {
        allowDrain = false;
    }

    /**
     * Stops the mechanic completely and resets it.
     */
    public function stopGimmick() {
        canKill = false;
        allowDrain = false;
        crowdAppeasment = 50; 
    }

    /**
     * Does the claps. Because this is built into bar itself, I have to compromise.
     */
    public function doClap(beatHit:Int) {
        if (beatHit % 2 == 1 && enableClapping && doClapping)
        {
            crowdClap.volume = 1;
            crowdClap.play(true);
        }    
    }

    var doRainbow:Bool = false;
    var e:Int = 0;
    var healthDrainMult:Float = 0; //The amount of drain. Shouldn't be messed with.
    var doClapping:Bool = false; //The amount of drain. Shouldn't be messed with.
    override function update(elapsed:Float)
    {
        e++;
        if (doRainbow && crowdAppeasment > 100) setColors(FlxColor.BLACK, FlxColor.fromHSL(((e / (20 * 0.1)) / 300 * 360) % 360, 1.0, 0.5*1.0));
        if (allowDrain) crowdAppeasment -= crowdAttentionLoss / (ClientPrefs.data.framerate / 120);
        if (canKill && crowdAppeasment <= 0) 
        {
            COD.setCOD(null, 'The crowd got bored and left.\n[pause:0.5](And BF got pelted by a tomato)');
            PlayState.instance.die();
        }
        if (allowDrain && canKill) PlayState.instance.health -= healthDrainMult / (ClientPrefs.data.framerate / 120); //for consistancy
        if (crowdAppeasment >= 0 && crowdAppeasment <= 9) crowdState = MAD;
        if (crowdAppeasment >= 10 && crowdAppeasment <= 39) crowdState = UNHAPPY;
        if (crowdAppeasment >= 40 && crowdAppeasment <= 59) crowdState = NEUTRAL;
        if (crowdAppeasment >= 60 && crowdAppeasment <= 89) crowdState = HAPPY;
        if (crowdAppeasment >= 90 && crowdAppeasment <= 100) crowdState = VIBING;
        if (crowdAppeasment > 150) crowdAppeasment = 150; // Cap
        super.update(elapsed);
        for (note in 0...3)
            PlayState.instance.modManager.setValue('transform'+note+'X', FlxG.random.float(-PlayState.instance.modManager.getValue('noteShake', -1), PlayState.instance.modManager.getValue('noteShake', -1)), -1);
    }

    var lastState:CrowdState = NONE;
    function set_crowdState(crowdMood:CrowdState){
        if (crowdMood != lastState)
        {
            switch (crowdMood)
            {
                case MAD:
                    crowdBoo.volume = 0.9;
                    crowdBoo.play();
                    lastState = MAD;
                    PlayState.instance.modManager.setValue('noteShake', 8);
                    trace('Crowd Mood: Mad');
                    setColors(FlxColor.BLACK, FlxColor.RED);
                    healthDrainMult = 0.01;
                    if (onCrowdMad != null) onCrowdMad();
                case UNHAPPY:
                    if (crowdBoo.playing)
                        crowdBoo.fadeOut(2, 0);
                    lastState = UNHAPPY;
                    PlayState.instance.modManager.setValue('noteShake', 4);
                    trace('Crowd Mood: Unhappy');
                    setColors(FlxColor.BLACK, FlxColor.fromRGB(102, 4, 4));
                    healthDrainMult = 0.004;
                    if (onCrowdUnhappy != null) onCrowdUnhappy();
                case NEUTRAL:
                    if (crowdBoo.playing)
                        crowdBoo.fadeOut(0.5, 0);
                    if (crowdCheer.playing)
                        crowdCheer.fadeOut(0.5, 0);
                    lastState = NEUTRAL;
                    PlayState.instance.modManager.setValue('noteShake', 0);
                    trace('Crowd Mood: Neutral');
                    setColors(FlxColor.BLACK, FlxColor.BLUE);
                    if (onCrowdNeutral != null) onCrowdNeutral();
                case HAPPY:
                    doClapping = false;
                    lastState = HAPPY;
                    trace('Crowd Mood: Happy');
                    doRainbow = false;
                    healthDrainMult = 0;
                    setColors(FlxColor.BLACK, FlxColor.fromRGB(0, 85, 0));
                    if (onCrowdHappy != null) onCrowdHappy();
                case VIBING:
                    crowdCheer.volume = 0.9;
                    crowdCheer.play();
                    doClapping = true;
                    lastState = VIBING;
                    trace('Crowd Mood: Vibing');
                    doRainbow = true;
                    healthDrainMult -= 0.001;
                    setColors(FlxColor.BLACK, FlxColor.GREEN);
                    if (onCrowdVibing != null) onCrowdVibing();
                case NONE:
                    //literally nothing
            }
        }
		return crowdMood;
	}
}