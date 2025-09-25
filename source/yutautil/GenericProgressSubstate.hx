package yutautil;

import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.Exception;

typedef ProgressTask = {
    var name:String;
    var func:Array<Dynamic>->Dynamic;
    var ?throwOnError:Bool;
}

class GenericProgressSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var statusText:FlxText;
    var progressBar:FlxSprite;
    var progressFill:FlxSprite;
    var cancelButton:FlxSprite;
    var cancelButtonText:FlxText;
    var particles:FlxTypedGroup<FlxSprite>;

    var currentStep:Int = 0;
    var totalSteps:Int = 0;
    var isAnimating:Bool = false;
    var isCanceled:Bool = false;

    var taskFunctions:Array<ProgressTask>;
    var results:Array<Dynamic> = [];
    var onComplete:Array<Dynamic>->Void;
    var onError:(String, Bool)->Void;
    var onCancel:Void->Void;

    public function new(title:String, tasks:OneOrMore<ProgressTask>, ?onComplete:Array<Dynamic>->Void, ?onError:(String, Bool)->Void, ?onCancel:Void->Void) {
        super();

        this.taskFunctions = tasks;
        this.totalSteps = taskFunctions.length;
        this.onComplete = onComplete != null ? onComplete : function(results:Array<Dynamic>) {};
        this.onError = onError != null ? onError : function(error:String, shouldThrow:Bool) {
            trace('Progress error: $error');
            if (shouldThrow) throw new Exception(error);
        };
        this.onCancel = onCancel != null ? onCancel : function() {};

        setupVisuals(title);
        setupAnimations();
        animateIn();

        new FlxTimer().start(0.5, function(_) {
            if (!isCanceled) executeNextTask();
        });
    }

    function setupVisuals(title:String) {
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 180));
        add(background);

        panel = FlxGradient.createGradientFlxSprite(500, 300, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = Std.int((FlxG.width - panel.width) / 2);
        panel.y = Std.int((FlxG.height - panel.height) / 2);
        add(panel);

        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        statusText = new FlxText(panel.x + 20, panel.y + 70, panel.width - 40, "Preparing...", 16);
        statusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        statusText.borderSize = 1;
        add(statusText);

        progressBar = new FlxSprite(panel.x + 40, panel.y + 120);
        progressBar.makeGraphic(Std.int(panel.width - 80), 20, FlxColor.fromRGB(40, 40, 70));
        add(progressBar);

        progressFill = new FlxSprite(progressBar.x + 2, progressBar.y + 2);
        progressFill.makeGraphic(1, 16, FlxColor.CYAN);
        add(progressFill);

        // Progress percentage text
        var progressText = new FlxText(panel.x + 20, panel.y + 150, panel.width - 40, "0%", 14);
        progressText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        progressText.borderSize = 1;
        add(progressText);

        cancelButton = new FlxSprite(panel.x + (panel.width - 120) / 2, panel.y + panel.height - 60);
        cancelButton.makeGraphic(120, 40, FlxColor.RED);
        add(cancelButton);

        cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 16);
        cancelButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelButtonText.borderSize = 1;
        add(cancelButtonText);
    }

    function animateIn() {
        isAnimating = true;
        panel.scale.set(0.8, 0.8);
        panel.alpha = 0;

        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                isAnimating = false;
            }
        });

        // Fade in other elements
        for (member in members) {
            if (member != background && member != panel && member != particles) {
                if (Std.isOfType(member, FlxSprite)) {
                    var sprite:FlxSprite = cast(member, FlxSprite);
                    sprite.alpha = 0;
                    FlxTween.tween(sprite, {alpha: 1}, 0.3, {
                        ease: FlxEase.sineOut,
                        startDelay: 0.2
                    });
                }
            }
        }
    }

    function setupAnimations() {
        // Particle effects
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        for (i in 0...15) {
            var particle = new FlxSprite(
                panel.x + FlxG.random.float(0, panel.width),
                panel.y + FlxG.random.float(0, panel.height)
            );
            particle.makeGraphic(2, 2, FlxColor.CYAN);
            particle.alpha = FlxG.random.float(0.2, 0.6);
            particles.add(particle);

            FlxTween.tween(particle, {
                y: particle.y - FlxG.random.float(20, 40),
                alpha: 0
            }, FlxG.random.float(2, 4), {
                type: LOOPING,
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    particle.y = panel.y + panel.height;
                    particle.x = panel.x + FlxG.random.float(0, panel.width);
                    particle.alpha = FlxG.random.float(0.2, 0.6);
                }
            });
        }
    }

    function animateOut(?onCompleteCallback:Void->Void) {
        if (isAnimating) return;
        isAnimating = true;

        FlxTween.tween(panel, {"scale.x": 0.7, "scale.y": 0.7, alpha: 0}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                if (onCompleteCallback != null) onCompleteCallback();
                close();
            }
        });

        FlxTween.tween(background, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
    }

    function executeNextTask() {
        if (isCanceled || currentStep >= totalSteps) {
            finishProgress();
            return;
        }

        var task = taskFunctions[currentStep];
        statusText.text = task.name;
        updateProgress();

        try {
            var result = task.func(results);
            results.push(result);
            currentStep++;

            new FlxTimer().start(0.1, function(_) {
                if (!isCanceled) executeNextTask();
            });

        } catch (e:Exception) {
            var errorMsg = 'Error in step "${task.name}": ${e.message}';
            var shouldThrow = task.throwOnError != null ? task.throwOnError : false;

            onError(errorMsg, shouldThrow);

            if (!shouldThrow) {
                statusText.text = "Error: " + e.message;
                statusText.color = FlxColor.RED;
                FlxFlicker.flicker(statusText, 2, 0.1);

                new FlxTimer().start(3, function(_) {
                    animateOut();
                });
            }
        }
    }

    function updateProgress() {
        var progress = currentStep / totalSteps;
        var fillWidth = Std.int((progressBar.width - 4) * progress);

        // Update progress fill by recreating the graphic with the correct width
        progressFill.makeGraphic(Std.int(Math.max(1, fillWidth)), 16, FlxColor.CYAN);

        // Update percentage text
        var percentage = Std.int(progress * 100);
        for (member in members) {
            if (Std.isOfType(member, FlxText)) {
                var text:FlxText = cast(member, FlxText);
                if (text.text.indexOf("%") != -1) {
                    text.text = percentage + "%";
                }
            }
        }
    }

    function finishProgress() {
        statusText.text = "Completed!";
        statusText.color = FlxColor.LIME;
        updateProgress();

        FlxFlicker.flicker(titleText, 1, 0.1);

        new FlxTimer().start(0.5, function(_) {
            onComplete(results);
            animateOut();
        });
    }

    function cancel() {
        if (isCanceled || isAnimating) return;

        isCanceled = true;
        statusText.text = "Canceled";
        statusText.color = FlxColor.YELLOW;

        FlxG.sound.play(Paths.sound('cancelMenu'));
        onCancel();
        animateOut();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (isAnimating || isCanceled) return;

        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            cancel();
        }

        if (FlxG.mouse.overlaps(cancelButton)) {
            cancelButton.color = FlxColor.fromRGB(255, 150, 150);
            if (FlxG.mouse.justPressed) {
                cancel();
            }
        } else {
            cancelButton.color = FlxColor.RED;
        }
    }

    override function destroy() {
        taskFunctions = null;
        results = null;
        onComplete = null;
        onError = null;
        onCancel = null;
        super.destroy();
    }

    public static function createTask(name:String, func:Array<Dynamic>->Dynamic, ?throwOnError:Bool = false):ProgressTask {
        return {
            name: name,
            func: func,
            throwOnError: throwOnError
        };
    }
}
