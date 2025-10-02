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

typedef FuncTask = {
    var name:String;
    var func:Array<Dynamic>->Dynamic;
    var ?throwOnError:Bool;
}

typedef IterTask = {
    var name:String;
    var iterable:Array<Dynamic>;
    var func:Dynamic->Dynamic;
    var ?throwOnError:Bool;
}

typedef MapIterTask = {
    var name:String;
    var map:Map<Dynamic, Dynamic>;
    var func:(Dynamic, Dynamic)->Dynamic; // key, value -> result
    var ?throwOnError:Bool;
}

enum ProgressTask {
    Func(task:FuncTask);
    Iter(task:IterTask);
    MapIter(task:MapIterTask);
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

    // For IterTask and MapIterTask progress tracking
    var currentIterIndex:Int = 0;
    var totalIterItems:Int = 0;
    var isIterating:Bool = false;
    var mapKeys:Array<Dynamic> = [];

    var taskFunctions:Array<ProgressTask>;
    var results:Array<Dynamic> = [];
    var onComplete:Array<Dynamic>->Void;
    var onError:(String, Bool)->Void;
    var onCancel:Void->Void;
    var cancelButtonEnabled:Bool = true;

    public function new(title:String, tasks:OneOrMore<ProgressTask>, ?onComplete:Array<Dynamic>->Void, ?onError:(String, Bool)->Void, ?onCancel:Void->Void, ?cancelButtonEnabled:Bool = true) {
        super();

        this.taskFunctions = tasks;
        this.totalSteps = taskFunctions.length;
        this.onComplete = onComplete != null ? onComplete : function(results:Array<Dynamic>) {};
        this.onError = onError != null ? onError : function(error:String, shouldThrow:Bool) {
            trace('Progress error: $error');
            if (shouldThrow) throw new Exception(error);
        };
        this.onCancel = onCancel != null ? onCancel : function() {};
        this.cancelButtonEnabled = cancelButtonEnabled;

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
        cancelButton.makeGraphic(120, 40, cancelButtonEnabled ? FlxColor.RED : FlxColor.GRAY);
        add(cancelButton);

        cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 16);
        cancelButtonText.setFormat(Paths.font("vcr.ttf"), 16, cancelButtonEnabled ? FlxColor.WHITE : FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
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

        switch (task) {
            case Func(funcTask):
                statusText.text = funcTask.name;
                updateProgress();

                try {
                    var result = funcTask.func(results);
                    results.push(result);
                    currentStep++;

                    new FlxTimer().start(0.1, function(_) {
                        if (!isCanceled) executeNextTask();
                    });

                } catch (e:Exception) {
                    handleTaskError(funcTask.name, e, funcTask.throwOnError);
                }

            case Iter(iterTask):
                if (!isIterating) {
                    // Start iteration
                    isIterating = true;
                    currentIterIndex = 0;
                    totalIterItems = iterTask.iterable.length;
                    var iterResults:Array<Dynamic> = [];
                    results.push(iterResults); // Push the result array for this iter task
                }

                if (currentIterIndex >= totalIterItems) {
                    // Iteration complete
                    isIterating = false;
                    currentStep++;
                    new FlxTimer().start(0.1, function(_) {
                        if (!isCanceled) executeNextTask();
                    });
                    return;
                }

                // Update status with iteration progress
                statusText.text = iterTask.name + ' (${currentIterIndex}/${totalIterItems})';
                updateProgress();

                try {
                    var item = iterTask.iterable[currentIterIndex];
                    var result = iterTask.func(item);

                    // Add result to the current iteration's result array
                    var iterResults:Array<Dynamic> = results[results.length - 1];
                    iterResults.push(result);

                    currentIterIndex++;

                    new FlxTimer().start(0.05, function(_) {
                        if (!isCanceled) executeNextTask();
                    });

                } catch (e:Exception) {
                    handleTaskError(iterTask.name + ' (item ${currentIterIndex})', e, iterTask.throwOnError);
                }

            case MapIter(mapTask):
                if (!isIterating) {
                    // Start map iteration
                    isIterating = true;
                    currentIterIndex = 0;
                    mapKeys = [for (key in mapTask.map.keys()) key];
                    totalIterItems = mapKeys.length;
                    var iterResults:Array<Dynamic> = [];
                    results.push(iterResults); // Push the result array for this map iter task
                }

                if (currentIterIndex >= totalIterItems) {
                    // Map iteration complete
                    isIterating = false;
                    mapKeys = [];
                    currentStep++;
                    new FlxTimer().start(0.1, function(_) {
                        if (!isCanceled) executeNextTask();
                    });
                    return;
                }

                // Update status with iteration progress
                statusText.text = mapTask.name + ' (${currentIterIndex}/${totalIterItems})';
                updateProgress();

                try {
                    var key = mapKeys[currentIterIndex];
                    var value = mapTask.map.get(key);
                    var result = mapTask.func(key, value);

                    // Add result to the current iteration's result array
                    var iterResults:Array<Dynamic> = results[results.length - 1];
                    iterResults.push(result);

                    currentIterIndex++;

                    new FlxTimer().start(0.05, function(_) {
                        if (!isCanceled) executeNextTask();
                    });

                } catch (e:Exception) {
                    handleTaskError(mapTask.name + ' (item ${currentIterIndex})', e, mapTask.throwOnError);
                }
        }
    }

    function handleTaskError(taskName:String, e:Exception, ?throwOnError:Bool) {
        var errorMsg = 'Error in step "${taskName}"\n\n${e.message}';
        var shouldThrow = throwOnError != null ? throwOnError : false;


        trace('Progress error trace: ${e.stack}');

        if (!shouldThrow) {
            statusText.text = "Error: " + e.message;
            statusText.color = FlxColor.RED;
            FlxFlicker.flicker(statusText, 2, 0.1);

            new FlxTimer().start(3, function(_) {
                animateOut(() -> {
                    onError(errorMsg, shouldThrow);
                });
            });
        }
    }

    function updateProgress() {
        var progress:Float;

        if (isIterating && totalIterItems > 0) {
            // Calculate progress within current iteration
            var iterProgress = currentIterIndex / totalIterItems;
            progress = (currentStep + iterProgress) / totalSteps;
        } else {
            progress = currentStep / totalSteps;
        }

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

        // Only allow cancel input if cancel button is enabled
        if (cancelButtonEnabled) {
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
        } else {
            // Keep the button gray when disabled and don't respond to hover/click
            cancelButton.color = FlxColor.GRAY;
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
        return Func({
            name: name,
            func: func,
            throwOnError: throwOnError
        });
    }

    public static function createIterTask(name:String, iterable:Array<Dynamic>, func:Dynamic->Dynamic, ?throwOnError:Bool = false):ProgressTask {
        return Iter({
            name: name,
            iterable: iterable,
            func: func,
            throwOnError: throwOnError
        });
    }

    public static function createMapIterTask(name:String, map:Map<Dynamic, Dynamic>, func:(Dynamic, Dynamic)->Dynamic, ?throwOnError:Bool = false):ProgressTask {
        return MapIter({
            name: name,
            map: map,
            func: func,
            throwOnError: throwOnError
        });
    }
}
