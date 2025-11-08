package states.freeplay.vslice.obj;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Backing card system for V-Slice freeplay
 * Shows character-specific backing cards behind the song list
 */
class BackingCard extends FlxSprite
{
    public var characterId:String = "bf";
    public var cardTween:FlxTween;

    public function new(x:Float = 0, y:Float = 0, ?character:String = "bf")
    {
        super(x, y);

        characterId = character;
        setupBackingCard();
    }

    private function setupBackingCard():Void
    {
        loadCardGraphic(characterId);
        antialiasing = ClientPrefs.data.antialiasing;

        // Start with card slightly faded
        alpha = 0.8;
    }

    private function loadCardGraphic(character:String):Void
    {
        // Try character-specific backing card first
        var cardPath = 'freeplay/cards/$character-card';
        var cardGraphic = Paths.image(cardPath, 'vslice');

        if (cardGraphic != null) {
            loadGraphic(cardGraphic);
            return;
        }

        // Try character backing textures
        var backingFrames = Paths.getSparrowAtlas('freeplay/backing-text-yeah/$character-backing', 'vslice');
        if (backingFrames != null) {
            frames = backingFrames;
            animation.addByPrefix('idle', 'backing idle', 24, true);
            animation.play('idle');
            return;
        }

        // Default backing card
        var defaultGraphic = Paths.image('freeplay/cards/default-card', 'vslice');
        if (defaultGraphic != null) {
            loadGraphic(defaultGraphic);
        } else {
            // Fallback graphic
            makeGraphic(400, 600, 0xFF9271FD);
        }
    }

    public function changeCard(newCharacter:String):Void
    {
        if (newCharacter == characterId) return;

        // Fade out current card
        if (cardTween != null) cardTween.cancel();

        cardTween = FlxTween.tween(this, {alpha: 0}, 0.3, {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
                // Change character and load new card
                characterId = newCharacter;
                loadCardGraphic(characterId);

                // Fade in new card
                cardTween = FlxTween.tween(this, {alpha: 0.8}, 0.3, {
                    ease: FlxEase.quadOut
                });
            }
        });
    }

    public function animateIn():Void
    {
        // Start from below screen
        y += 100;
        alpha = 0;

        if (cardTween != null) cardTween.cancel();

        // Slide up and fade in
        cardTween = FlxTween.tween(this, {y: y - 100, alpha: 0.8}, 0.8, {
            ease: FlxEase.quartOut
        });
    }

    public function animateOut():Void
    {
        if (cardTween != null) cardTween.cancel();

        // Slide down and fade out
        cardTween = FlxTween.tween(this, {y: y + 100, alpha: 0}, 0.5, {
            ease: FlxEase.quartIn
        });
    }

    public function pulse():Void
    {
        if (cardTween != null) cardTween.cancel();

        // Quick pulse animation
        cardTween = FlxTween.tween(this, {alpha: 1.0}, 0.1, {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
                cardTween = FlxTween.tween(this, {alpha: 0.8}, 0.2, {
                    ease: FlxEase.quadOut
                });
            }
        });
    }

    override function destroy():Void
    {
        if (cardTween != null) {
            cardTween.cancel();
            cardTween = null;
        }

        super.destroy();
    }
}
