package states.freeplay.vslice.obj;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

/**
 * DJ character for V-Slice freeplay
 * Handles character animations and interactions
 */
class FreeplayDJ extends FlxSprite
{
    public var characterId:String = "bf";

    // Animation states
    public var currentState:DJState = IDLE;

    public function new(x:Float = 0, y:Float = 0, ?character:String = "bf")
    {
        super(x, y);

        characterId = character;
        setupDJ();
    }

    private function setupDJ():Void
    {
        // Load DJ character frames
        var djFrames = getDJFrames(characterId);
        if (djFrames != null) {
            frames = djFrames;
            setupAnimations();
            animation.play('idle');
        } else {
            // Fallback graphic
            makeGraphic(200, 300, 0xFF31B0D1);
        }

        antialiasing = ClientPrefs.data.antialiasing;
    }

    private function getDJFrames(character:String):FlxAtlasFrames
    {
        // Try character-specific DJ frames first
        var charFrames = Paths.getSparrowAtlas('freeplay/freeplay-$character', 'vslice');
        if (charFrames != null) return charFrames;

        // Try generic freeplay boyfriend
        var bfFrames = Paths.getSparrowAtlas('freeplay/freeplay-boyfriend', 'vslice');
        if (bfFrames != null) return bfFrames;

        // Fallback to regular character
        return Paths.getSparrowAtlas('characters/$character', 'vslice');
    }

    private function setupAnimations():Void
    {
        // Setup standard DJ animations
        animation.addByPrefix('idle', 'idle', 24, true);
        animation.addByPrefix('confirm', 'confirm', 24, false);
        animation.addByPrefix('spamton', 'spamton', 24, true);
        animation.addByPrefix('charSelect', 'charSelect', 24, false);
        animation.addByPrefix('fistPump', 'fistPump', 24, false);

        // Try to add character-specific animations
        animation.addByPrefix('intro', 'intro', 24, false);
        animation.addByPrefix('transitionIn', 'transitionIn', 24, false);
        animation.addByPrefix('transitionOut', 'transitionOut', 24, false);
    }

    public function playIntro():Void
    {
        currentState = INTRO;
        if (animation.getByName('intro') != null) {
            animation.play('intro');
            animation.finishCallback = function(name:String) {
                playIdle();
                animation.finishCallback = null;
            };
        } else {
            playIdle();
        }
    }

    public function playIdle():Void
    {
        currentState = IDLE;
        animation.play('idle');
    }

    public function playConfirm():Void
    {
        currentState = CONFIRM;
        animation.play('confirm');
        animation.finishCallback = function(name:String) {
            playIdle();
            animation.finishCallback = null;
        };
    }

    public function playSpamton():Void
    {
        currentState = SPAMTON;
        animation.play('spamton');

        // Return to idle after a random time
        FlxTimer.wait(2.0 + (Math.random() * 3.0), function() {
            if (currentState == SPAMTON) {
                playIdle();
            }
        });
    }

    public function playCharSelect():Void
    {
        currentState = CHAR_SELECT;
        animation.play('charSelect');
        animation.finishCallback = function(name:String) {
            playIdle();
            animation.finishCallback = null;
        };
    }

    public function playFistPump():Void
    {
        currentState = FIST_PUMP;
        animation.play('fistPump');
        animation.finishCallback = function(name:String) {
            playIdle();
            animation.finishCallback = null;
        };
    }

    public function changeCharacter(newCharacter:String):Void
    {
        if (newCharacter == characterId) return;

        characterId = newCharacter;
        setupDJ();
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Random spamton animations
        if (currentState == IDLE && Math.random() < 0.001) {
            playSpamton();
        }
    }
}

enum DJState {
    IDLE;
    INTRO;
    CONFIRM;
    SPAMTON;
    CHAR_SELECT;
    FIST_PUMP;
}
