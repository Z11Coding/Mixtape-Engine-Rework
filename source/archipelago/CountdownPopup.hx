package archipelago;

import openfl.events.Event;
import openfl.geom.Matrix;
import flash.display.BitmapData;
import openfl.Lib;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.system.FlxSound;

class CountdownPopup extends openfl.display.Sprite {
    public var onFinish:Void->Void = null;
    private var countdown:Int = -1; // Initialize with -1 to indicate no value yet
    private var lastScale:Float = 1;
    private var intendedY:Float = 0;
    private var timePassed:Float = -1;
    private var lerpTime:Float = 0;
    private var bitmaps:Array<BitmapData> = [];
    private var textDisplay:FlxText;
    public static var instance:CountdownPopup = null;

    // private var name:String;
    private var desc:String;

    public function new(name:String, desc:String, initialCountdown:Int, ?onFinish:Void->Void) {
        super();
        this.countdown = initialCountdown;
        this.onFinish = onFinish;
        instance = this;
        this.name = name;
        this.desc = desc;

        // Background
        graphics.beginFill(FlxColor.BLACK);
        graphics.drawRoundRect(0, 0, 420, 130, 16, 16);

        // Text setup
        var textX = 15;
        var textY = 20;
        textDisplay = new FlxText(0, 0, 390, '', 16);
        textDisplay.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        drawTextAt(textDisplay, name, textX, textY);
        drawTextAt(textDisplay, desc, textX, textY + 30);
        drawTextAt(textDisplay, 'Countdown: ' + countdown, textX, textY + 60);
        graphics.endFill();

        // Play initial sound
        FlxG.sound.play(Paths.sound('countdown/start'));

        // Add to stage
        FlxG.stage.addEventListener(Event.RESIZE, onResize);
        addEventListener(Event.ENTER_FRAME, update);
        FlxG.game.addChild(this);

        // Initial scaling and positioning
        lastScale = (FlxG.stage.stageHeight / FlxG.height);
        this.x = 20 * lastScale;
        this.y = -130 * lastScale;
        this.scaleX = lastScale;
        this.scaleY = lastScale;
        intendedY = 20;
    }

    public function updateCountdown(newCountdown:Int) {
        if (newCountdown != countdown) {
            countdown = newCountdown;
        }

            // Clear and redraw graphics
            graphics.clear();
            graphics.beginFill(FlxColor.BLACK);
            graphics.drawRoundRect(0, 0, 420, 130, 16, 16);
            drawTextAt(textDisplay, name, 15, 20);
            drawTextAt(textDisplay, desc, 15, 50);
            drawTextAt(textDisplay, 'Countdown: ' + countdown, 15, 80);
            graphics.endFill();

            // Play countdown sound
            if (countdown > 0) {
                FlxG.sound.play(Paths.sound('countdown/tick'));
    }
}


    private function drawTextAt(text:FlxText, str:String, textX:Float, textY:Float) {
        text.text = str;
        text.updateHitbox();
        var clonedBitmap:BitmapData = text.graphic.bitmap.clone();
        bitmaps.push(clonedBitmap);
        graphics.beginBitmapFill(clonedBitmap, new Matrix(1, 0, 0, 1, textX, textY), false, false);
        graphics.drawRect(textX, textY, text.width + textX, text.height + textY);
    }

    private function update(e:Event) {
        if (timePassed < 0) {
            timePassed = Lib.getTimer();
            return;
        }

        var time = Lib.getTimer();
        var elapsed:Float = (time - timePassed) / 1000;
        timePassed = time;

        if (elapsed >= 0.5) return; // Skip if passed through a loading screen

        // Only update position if countdown is active
        if (countdown > 0) {
            lerpTime = Math.min(1, lerpTime + elapsed);
            y = ((FlxEase.elasticOut(lerpTime) * (intendedY + 130)) - 130) * lastScale;
        } else if (countdown == 0) {
            y -= FlxG.height * 2 * elapsed * lastScale;
            if (y <= -130 * lastScale) {
                destroy();
            }
        }
    }

    private function onResize(e:Event) {
        var mult = (FlxG.stage.stageHeight / FlxG.height);
        scaleX = mult;
        scaleY = mult;
        x = (mult / lastScale) * x;
        y = (mult / lastScale) * y;
        lastScale = mult;
    }

    public function destroy() {
        if (FlxG.game.contains(this)) {
            FlxG.game.removeChild(this);
        }
        FlxG.stage.removeEventListener(Event.RESIZE, onResize);
        removeEventListener(Event.ENTER_FRAME, update);
        deleteClonedBitmaps();
        if (onFinish != null) onFinish();
    }

    private function deleteClonedBitmaps() {
        for (clonedBitmap in bitmaps) {
            if (clonedBitmap != null) {
                clonedBitmap.dispose();
                clonedBitmap.disposeImage();
            }
        }
        bitmaps = null;
    }
}
