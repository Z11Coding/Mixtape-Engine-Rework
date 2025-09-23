package yutautil.games.stealthmaze.objects;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import yutautil.games.stealthmaze.backend.MazeData.CollectibleType;
import yutautil.games.stealthmaze.backend.MazeData.MazeTileType;
import yutautil.games.stealthmaze.backend.MazeData;
import yutautil.games.stealthmaze.objects.MazePlayer;

/**
 * Collectible items in the maze
 */
class MazeCollectible extends FlxSprite {

    public var collectibleType:CollectibleType;
    public var isCollected:Bool = false;
    public var pulseAnimation:FlxTween;
    public var floatAnimation:FlxTween;
    private var originalY:Float;

    public function new(x:Float, y:Float, type:CollectibleType) {
        super(x, y);

        this.collectibleType = type;
        this.originalY = y;

        // Set appearance based on type
        switch (type) {
            case RED_OBJECTIVE:
                makeGraphic(20, 20, FlxColor.RED);
                // Red objective is slightly larger and more prominent

            case GOLDEN_BONUS:
                makeGraphic(16, 16, FlxColor.YELLOW);
        }

        // Center the sprite
        x -= width / 2;
        y -= height / 2;

        // Start animations
        startAnimations();
    }

    /**
     * Start visual animations for the collectible
     */
    private function startAnimations():Void {
        // Pulsing scale animation
        pulseAnimation = FlxTween.tween(scale, {x: 1.2, y: 1.2}, 1.0, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });

        // Floating up and down animation
        floatAnimation = FlxTween.tween(this, {y: y - 8}, 1.5, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    /**
     * Collect this item
     */
    public function collect():Void {
        if (isCollected) return;

        isCollected = true;

        // Stop animations
        if (pulseAnimation != null) {
            pulseAnimation.cancel();
        }
        if (floatAnimation != null) {
            floatAnimation.cancel();
        }

        // Play collection animation
        FlxTween.tween(this, {alpha: 0, y: y - 20}, 0.5, {
            ease: FlxEase.backIn,
            onComplete: function(tween) {
                kill();
            }
        });

        FlxTween.tween(scale, {x: 2.0, y: 2.0}, 0.3, {
            ease: FlxEase.backOut
        });
    }

    override public function destroy():Void {
        if (pulseAnimation != null) {
            pulseAnimation.cancel();
        }
        if (floatAnimation != null) {
            floatAnimation.cancel();
        }

        super.destroy();
    }
}

/**
 * Closet hiding spots in the maze
 */
class MazeCloset extends FlxSprite {

    public var closetType:MazeTileType;
    public var capacity:Int;
    public var currentOccupants:Int = 0;
    public var isPlayerInside:Bool = false;

    // Visual components
    private var doorSprite:FlxSprite;
    private var interactionPrompt:FlxSprite;

    public function new(x:Float, y:Float, type:MazeTileType) {
        super(x, y);

        this.closetType = type;
        this.capacity = (type == CLOSET_1P) ? 1 : 2;

        // Set appearance
        makeGraphic(32, 32, FlxColor.BROWN);

        // Create door sprite
        doorSprite = new FlxSprite(x + 2, y + 2);
        doorSprite.makeGraphic(28, 28, FlxColor.fromRGB(139, 69, 19)); // Darker brown for door

        // Create interaction prompt (initially hidden)
        interactionPrompt = new FlxSprite(x, y - 20);
        interactionPrompt.makeGraphic(32, 16, FlxColor.WHITE);
        // TODO: Add "Press E to hide" text
        interactionPrompt.visible = false;
    }

    /**
     * Check if closet can accommodate the player and their tail
     */
    public function canHidePlayer(tailLength:Int):Bool {
        // 1-person closets can't hide player if they have a tail
        if (closetType == CLOSET_1P && tailLength > 0) {
            return false;
        }

        // 2-person closets can hide player + tail
        var totalOccupancy = 1 + tailLength; // Player + tail segments
        return currentOccupants + totalOccupancy <= capacity;
    }

    /**
     * Hide the player in this closet
     */
    public function hidePlayer(player:MazePlayer):Bool {
        var tailLength = player.tailSegments.length;

        if (!canHidePlayer(tailLength)) {
            return false;
        }

        isPlayerInside = true;
        currentOccupants += 1 + tailLength;

        // Hide player
        player.hide();
        player.x = x + width/2 - player.width/2;
        player.y = y + height/2 - player.height/2;

        // Hide tail segments (or leave them visible if 1-person closet)
        if (closetType == CLOSET_2P) {
            for (segment in player.tailSegments) {
                segment.alpha = 0.3; // Make tail segments semi-transparent
            }
        }
        // For 1-person closets, tail segments remain fully visible (vulnerability)

        // Close door animation
        FlxTween.tween(doorSprite, {alpha: 0.8}, 0.3);

        return true;
    }

    /**
     * Player exits the closet
     */
    public function exitPlayer(player:MazePlayer):Void {
        if (!isPlayerInside) return;

        isPlayerInside = false;
        var tailLength = player.tailSegments.length;
        currentOccupants -= (1 + tailLength);

        // Unhide player
        player.unhide();

        // Restore tail segment visibility
        for (segment in player.tailSegments) {
            segment.alpha = 0.8;
        }

        // Open door animation
        FlxTween.tween(doorSprite, {alpha: 0.5}, 0.3);
    }

    /**
     * Show interaction prompt when player is nearby
     */
    public function showPrompt():Void {
        interactionPrompt.visible = true;
        FlxTween.tween(interactionPrompt, {alpha: 1}, 0.2);
    }

    /**
     * Hide interaction prompt
     */
    public function hidePrompt():Void {
        FlxTween.tween(interactionPrompt, {alpha: 0}, 0.2, {
            onComplete: function(tween) {
                interactionPrompt.visible = false;
            }
        });
    }

    /**
     * Check if player can interact with this closet
     */
    public function isPlayerInRange(player:MazePlayer):Bool {
        var playerCenter = player.x + player.width/2;
        var playerCenterY = player.y + player.height/2;
        var closetCenter = x + width/2;
        var closetCenterY = y + height/2;

        var distance = Math.sqrt(
            (playerCenter - closetCenter) * (playerCenter - closetCenter) +
            (playerCenterY - closetCenterY) * (playerCenterY - closetCenterY)
        );

        return distance <= 40; // Interaction range
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Update door sprite position
        if (doorSprite != null) {
            doorSprite.x = x + 2;
            doorSprite.y = y + 2;
        }

        // Update prompt position
        if (interactionPrompt != null) {
            interactionPrompt.x = x;
            interactionPrompt.y = y - 20;
        }
    }

    override public function draw():Void {
        super.draw();

        // Draw door sprite
        if (doorSprite != null) {
            doorSprite.draw();
        }

        // Draw interaction prompt
        if (interactionPrompt != null && interactionPrompt.visible) {
            interactionPrompt.draw();
        }
    }

    override public function destroy():Void {
        if (doorSprite != null) {
            doorSprite.destroy();
        }
        if (interactionPrompt != null) {
            interactionPrompt.destroy();
        }

        super.destroy();
    }
}

/**
 * Exit points in the maze
 */
class MazeExit extends FlxSprite {

    public var isRealExit:Bool;
    public var isActive:Bool = false; // Only active when player has red objective
    private var glowAnimation:FlxTween;

    public function new(x:Float, y:Float, isReal:Bool = true) {
        super(x, y);

        this.isRealExit = isReal;

        // Set appearance
        if (isReal) {
            makeGraphic(32, 32, FlxColor.GREEN);
        } else {
            makeGraphic(32, 32, FlxColor.ORANGE); // Fake exits are orange
        }

        alpha = 0.6; // Initially dimmed

        // Start subtle glow animation
        startGlowAnimation();
    }

    /**
     * Start glow animation
     */
    private function startGlowAnimation():Void {
        glowAnimation = FlxTween.tween(this, {alpha: isActive ? 1.0 : 0.3}, 2.0, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    /**
     * Activate exit (when player collects red objective)
     */
    public function activate():Void {
        if (!isRealExit) return; // Only real exits can be activated

        isActive = true;

        // Bright activation animation
        FlxTween.tween(this, {alpha: 1.0}, 0.5, {
            ease: FlxEase.backOut
        });

        // Scale pulse
        FlxTween.tween(scale, {x: 1.2, y: 1.2}, 0.3, {
            type: PINGPONG,
            ease: FlxEase.backOut,
            onComplete: function(tween) {
                scale.set(1.0, 1.0);
            }
        });
    }

    /**
     * Check if player can use this exit
     */
    public function canPlayerExit(player:MazePlayer):Bool {
        if (!isRealExit) {
            return false; // Fake exits never work
        }

        return isActive; // Real exits work only when active
    }

    /**
     * Player attempts to use this exit
     */
    public function useExit(player:MazePlayer):Bool {
        if (!canPlayerExit(player)) {
            // Fake exit or inactive real exit
            if (!isRealExit) {
                // Flash red to indicate fake exit
                var originalColor = color;
                color = FlxColor.RED;
                FlxTween.color(this, 1.0, FlxColor.RED, originalColor);
            }
            return false;
        }

        // Successful exit
        FlxTween.tween(this, {alpha: 0}, 0.5);
        FlxTween.tween(scale, {x: 2.0, y: 2.0}, 0.5, {
            ease: FlxEase.backIn
        });

        return true;
    }

    override public function destroy():Void {
        if (glowAnimation != null) {
            glowAnimation.cancel();
        }

        super.destroy();
    }
}
