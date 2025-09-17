package archipelago.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;
import states.MainMenuState;

class APChoiceState extends MusicBeatState
{
    // Visual elements
    private var bg:FlxSprite;
    private var titleText:FlxText;
    private var descriptionText:FlxText;
    private var choice1Button:FlxButton;
    private var choice2Button:FlxButton;
    private var choice1Text:FlxText;
    private var choice2Text:FlxText;
    private var warningText:FlxText;

    // Choice system
    private var choice1Callback:Void->Void;
    private var choice2Callback:Void->Void;
    private var returnState:FlxState;
    private var selectedChoice:Int = 0;
    private var canSelect:Bool = false;

    // Animation
    private var elementsGroup:FlxGroup;

    public function new(title:String, description:String, choice1:String, choice2:String,
                       choice1Action:Void->Void, choice2Action:Void->Void, ?backToState:FlxState)
    {
        super();

        this.choice1Callback = choice1Action;
        this.choice2Callback = choice2Action;
        this.returnState = backToState != null ? backToState : new MainMenuState();

        // Create visual elements
        createBackground();
        createTitle(title);
        createDescription(description);
        createChoiceButtons(choice1, choice2);
        createWarning();

        elementsGroup = new FlxGroup();
        elementsGroup.add(titleText);
        elementsGroup.add(descriptionText);
        elementsGroup.add(choice1Button);
        elementsGroup.add(choice2Button);
        elementsGroup.add(choice1Text);
        elementsGroup.add(choice2Text);
        elementsGroup.add(warningText);
    }

    override public function create():Void
    {
        super.create();

        add(bg);
        add(elementsGroup);

        // Start entrance animation
        playEntranceAnimation();

        // Play ominous sound
        FlxG.sound.playMusic(Paths.music('gameOver'), 0.4, true);
    }

    private function createBackground():Void
    {
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

        // Add subtle gradient effect
        var gradientHeight:Int = Std.int(FlxG.height * 0.3);
        for (i in 0...gradientHeight)
        {
            var alpha:Float = i / gradientHeight * 0.3;
            var color:FlxColor = FlxColor.fromRGBFloat(0.1, 0.0, 0.2, alpha);
            bg.pixels.fillRect(new openfl.geom.Rectangle(0, i, FlxG.width, 1), color);
        }

        for (i in 0...gradientHeight)
        {
            var alpha:Float = (gradientHeight - i) / gradientHeight * 0.3;
            var color:FlxColor = FlxColor.fromRGBFloat(0.1, 0.0, 0.2, alpha);
            var y:Int = FlxG.height - gradientHeight + i;
            bg.pixels.fillRect(new openfl.geom.Rectangle(0, y, FlxG.width, 1), color);
        }
    }

    private function createTitle(title:String):Void
    {
        titleText = new FlxText(0, 80, FlxG.width, title, 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        titleText.alpha = 0;
    }

    private function createDescription(description:String):Void
    {
        descriptionText = new FlxText(50, 180, FlxG.width - 100, description, 20);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        descriptionText.alpha = 0;
    }

    private function createChoiceButtons(choice1:String, choice2:String):Void
    {
        var buttonWidth:Int = 350;
        var buttonHeight:Int = 80;
        var centerX:Float = FlxG.width * 0.5;
        var buttonY:Float = FlxG.height * 0.6;

        // Choice 1 (Left)
        choice1Button = new FlxButton(centerX - buttonWidth - 20, buttonY, "", selectChoice1);
        choice1Button.makeGraphic(buttonWidth, buttonHeight, FlxColor.TRANSPARENT);
        choice1Button.alpha = 0;
        choice1Button.scale.set(0.8, 0.8);

        choice1Text = new FlxText(choice1Button.x, choice1Button.y, buttonWidth, choice1, 18);
        choice1Text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        choice1Text.borderSize = 1;
        choice1Text.alpha = 0;

        // Choice 2 (Right)
        choice2Button = new FlxButton(centerX + 20, buttonY, "", selectChoice2);
        choice2Button.makeGraphic(buttonWidth, buttonHeight, FlxColor.TRANSPARENT);
        choice2Button.alpha = 0;
        choice2Button.scale.set(0.8, 0.8);

        choice2Text = new FlxText(choice2Button.x, choice2Button.y, buttonWidth, choice2, 18);
        choice2Text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        choice2Text.borderSize = 1;
        choice2Text.alpha = 0;
    }

    private function createWarning():Void
    {
        warningText = new FlxText(0, FlxG.height - 60, FlxG.width, "Choose wisely... there's no going back.", 16);
        warningText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
        warningText.borderSize = 1;
        warningText.alpha = 0;
    }

    private function playEntranceAnimation():Void
    {
        // Animate elements in sequence
        FlxTween.tween(titleText, {alpha: 1}, 0.8, {ease: FlxEase.backOut, startDelay: 0.2});
        FlxTween.tween(descriptionText, {alpha: 1}, 0.8, {ease: FlxEase.backOut, startDelay: 0.6});

        FlxTween.tween(choice1Button, {alpha: 1}, 0.6, {ease: FlxEase.backOut, startDelay: 1.0});
        FlxTween.tween(choice1Text, {alpha: 1}, 0.6, {ease: FlxEase.backOut, startDelay: 1.0});
        FlxTween.tween(choice1Button.scale, {x: 1, y: 1}, 0.6, {ease: FlxEase.backOut, startDelay: 1.0});

        FlxTween.tween(choice2Button, {alpha: 1}, 0.6, {ease: FlxEase.backOut, startDelay: 1.2});
        FlxTween.tween(choice2Text, {alpha: 1}, 0.6, {ease: FlxEase.backOut, startDelay: 1.2});
        FlxTween.tween(choice2Button.scale, {x: 1, y: 1}, 0.6, {ease: FlxEase.backOut, startDelay: 1.2});

        FlxTween.tween(warningText, {alpha: 1}, 0.8, {
            ease: FlxEase.backOut,
            startDelay: 1.6,
            onComplete: function(tween:FlxTween) {
                canSelect = true;
                // Add pulsing effect to warning
                FlxTween.tween(warningText, {alpha: 0.5}, 1.0, {
                    ease: FlxEase.sineInOut,
                    type: PINGPONG
                });
            }
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!canSelect) return;

        // Keyboard navigation
        if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
        {
            selectedChoice = selectedChoice == 0 ? 1 : 0;
            updateButtonHighlight();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.ACCEPT)
        {
            if (selectedChoice == 0)
                selectChoice1();
            else
                selectChoice2();
        }

        // Update button highlights based on hover
        updateButtonHover();
    }

    private function updateButtonHighlight():Void
    {
        // Reset both buttons
        choice1Button.color = FlxColor.WHITE;
        choice2Button.color = FlxColor.WHITE;
        choice1Text.color = FlxColor.WHITE;
        choice2Text.color = FlxColor.WHITE;

        // Highlight selected
        if (selectedChoice == 0)
        {
            choice1Button.color = FlxColor.YELLOW;
            choice1Text.color = FlxColor.YELLOW;
        }
        else
        {
            choice2Button.color = FlxColor.YELLOW;
            choice2Text.color = FlxColor.YELLOW;
        }
    }

    private function updateButtonHover():Void
    {
        if (FlxG.mouse.overlaps(choice1Button))
        {
            selectedChoice = 0;
            updateButtonHighlight();
        }
        else if (FlxG.mouse.overlaps(choice2Button))
        {
            selectedChoice = 1;
            updateButtonHighlight();
        }
    }

    private function selectChoice1():Void
    {
        if (!canSelect) return;

        canSelect = false;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Play exit animation then execute choice
        playExitAnimation(function() {
            if (choice1Callback != null) choice1Callback();
            returnToState();
        });
    }

    private function selectChoice2():Void
    {
        if (!canSelect) return;

        canSelect = false;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Play exit animation then execute choice
        playExitAnimation(function() {
            if (choice2Callback != null) choice2Callback();
            returnToState();
        });
    }

    private function playExitAnimation(onComplete:Void->Void):Void
    {
        // Fade out elements
        FlxTween.tween(elementsGroup, {alpha: 0}, 0.5, {ease: FlxEase.backIn});
        FlxTween.tween(bg, {alpha: 0}, 0.8, {
            ease: FlxEase.backIn,
            onComplete: function(tween:FlxTween) {
                if (onComplete != null) onComplete();
            }
        });
    }

    private function returnToState():Void
    {
        FlxG.sound.music?.stop();
        FlxG.switchState(returnState);
    }
}
