package yutautil.examples;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import yutautil.FlowAnimation;
import yutautil.FlowSprite;
import yutautil.FlowSpriteManager;
import yutautil.FlowState;

/**
 * Example implementation of FlowState system
 * This demonstrates how to create states that extend BaseFlowState
 */
class ExampleFlowState extends BaseFlowState {
    private var backgroundSprite:FlowSprite;
    private var titleText:FlxText;
    private var menuButton:FlowSprite;
    private var instructionText:FlxText;

    override public function create():Void {
        super.create();

        // Create background with fade-in animation
        backgroundSprite = new FlowSprite(0, 0);
        backgroundSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
        backgroundSprite.fadeIn(1.0, FlxEase.quadOut);
        backgroundSprite.fadeOut(0.8, FlxEase.quadIn);
        addFlowSprite(backgroundSprite);

        // Create title text (regular FlxSprite) with custom animations
        titleText = new FlxText(0, 100, FlxG.width, "FlowState Demo", 32);
        titleText.alignment = CENTER;
        titleText.color = FlxColor.WHITE;

        // Add custom enter and exit animations for the regular sprite
        FlowSpriteManager.addEnterAnimation(titleText, FlowSpriteManager.createSlideIn("top", 200, 0.8, FlxEase.backOut));
        FlowSpriteManager.addExitAnimation(titleText, FlowSpriteManager.createSlideOut("top", 200, 0.6, FlxEase.backIn));
        addSprite(titleText);

        // Add instruction text
        instructionText = new FlxText(0, FlxG.height - 120, FlxG.width, "SPACE = Next State | ESCAPE = Back to Menu", 16);
        instructionText.alignment = CENTER;
        instructionText.color = FlxColor.WHITE;
        FlowSpriteManager.addEnterAnimation(instructionText, FlowSpriteManager.createFadeIn(1.2));
        FlowSpriteManager.addExitAnimation(instructionText, FlowSpriteManager.createFadeOut(0.4));
        addSprite(instructionText);

        // Create menu button with multiple animations
        menuButton = new FlowSprite(FlxG.width / 2 - 50, 300);
        menuButton.makeGraphic(100, 50, FlxColor.GREEN);

        // Chain multiple enter animations
        menuButton.scaleIn(0.5, FlxEase.backOut);
        menuButton.addEnterAnimation(FlowAnimation.createDelay(0.5)); // Wait before next animation
        menuButton.addEnterAnimation(FlowAnimation.createCustom(function(sprite:FlxSprite, callback:Void->Void) {
            // Custom animation: make it bounce
            FlxTween.tween(sprite, {y: sprite.y - 20}, 0.3, {
                ease: FlxEase.quadOut,
                type: PINGPONG,
                onComplete: function(t:FlxTween) callback()
            });
        }));

        // Exit animations
        menuButton.fadeOut(0.4, FlxEase.quadIn);
        menuButton.scaleOut(0.4, FlxEase.backIn);

        addFlowSprite(menuButton);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Add keyboard controls
        if (FlxG.keys.justPressed.SPACE) {
            FlowStateExample.transitionToSecondState();
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            FlowStateExample.transitionBackToMain();
        }
    }
}

/**
 * Another example state to demonstrate transitions
 */
class SecondExampleFlowState extends BaseFlowState {
    private var backgroundSprite:FlowSprite;
    private var messageText:FlxText;
    private var instructionText:FlxText;

    override public function create():Void {
        super.create();

        // Different colored background
        backgroundSprite = new FlowSprite(0, 0);
        backgroundSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.RED);
        backgroundSprite.slideInFrom("right", FlxG.width, 1.0, FlxEase.quadOut);
        backgroundSprite.slideOutTo("left", FlxG.width, 0.8, FlxEase.quadIn);
        addFlowSprite(backgroundSprite);

        // Message text
        messageText = new FlxText(0, FlxG.height / 2 - 50, FlxG.width, "Second State!", 48);
        messageText.alignment = CENTER;
        messageText.color = FlxColor.WHITE;

        // Custom animation using FlowSpriteManager
        FlowSpriteManager.addEnterAnimation(messageText, FlowSpriteManager.createCombined([
            FlowSpriteManager.createFadeIn(0.6),
            FlowSpriteManager.createScaleIn(0.6, FlxEase.elasticOut)
        ]));

        FlowSpriteManager.addExitAnimation(messageText, FlowSpriteManager.createCombined([
            FlowSpriteManager.createFadeOut(0.4),
            FlowSpriteManager.createScaleOut(0.4)
        ]));

        addSprite(messageText);

        // Add instruction text
        instructionText = new FlxText(0, FlxG.height - 120, FlxG.width, "SPACE = Back to First State | ESCAPE = Back to Menu", 16);
        instructionText.alignment = CENTER;
        instructionText.color = FlxColor.WHITE;
        FlowSpriteManager.addEnterAnimation(instructionText, FlowSpriteManager.createFadeIn(1.2));
        FlowSpriteManager.addExitAnimation(instructionText, FlowSpriteManager.createFadeOut(0.4));
        addSprite(instructionText);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Add keyboard controls
        if (FlxG.keys.justPressed.SPACE) {
            // Go back to first state
            if (FlowState.instance != null) {
                var firstState = new ExampleFlowState();
                FlowState.instance.transitionTo(firstState, function() {
                    trace("Transitioned back to first state!");
                });
            }
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            FlowStateExample.transitionBackToMain();
        }
    }
}

/**
 * Example of how to use the FlowState system
 */
class FlowStateExample {
    public static function createExampleFlowState():FlowState {
        var initialState = new ExampleFlowState();
        var flowState = new FlowState(initialState);

        return flowState;
    }

    public static function transitionToSecondState():Void {
        if (FlowState.instance != null) {
            var secondState = new SecondExampleFlowState();
            FlowState.instance.transitionTo(secondState, function() {
                trace("Transition to second state completed!");
            });
        }
    }

    public static function transitionBackToMain():Void {
        if (FlowState.instance != null) {
            // You can transition to any FlxState, not just BaseFlowStates
            FlowState.instance.transitionToFlxState(new states.MainMenuState(), function() {
                trace("Transitioned back to main menu!");
            });
        }
    }
}
