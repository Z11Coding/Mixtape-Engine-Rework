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
import yutautil.GenericProgressSubstate.ProgressTask;
import yutautil.TypeUtils.OneOrMore;

typedef DualProgressConfig = {
    var title:String;
    var tasks:OneOrMore<ProgressTask>;
    var ?onComplete:Array<Dynamic>->Void;
    var ?onError:(String, Bool)->Void;
    var ?onCancel:Void->Void;
    var ?cancelButtonEnabled:Bool;
    var ?currentFileLabel:String;
    var ?overallLabel:String;
}

/**
 * DualProgressSubstate extends GenericProgressSubstate to provide two progress bars:
 * - Current file/operation progress
 * - Overall progress across all tasks
 *
 * This is useful for file downloads, batch operations, etc. where you want to show
 * both the progress of the current operation and the overall progress.
 */
class DualProgressSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var statusText:FlxText;
    var currentFileText:FlxText;

    // Current file/operation progress bar
    var currentProgressBar:FlxSprite;
    var currentProgressFill:FlxSprite;
    var currentProgressText:FlxText;

    // Overall progress bar
    var overallProgressBar:FlxSprite;
    var overallProgressFill:FlxSprite;
    var overallProgressText:FlxText;

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

    // Current file progress (0.0 to 1.0)
    var currentFileProgress:Float = 0.0;

    var taskFunctions:Array<ProgressTask>;
    var results:Array<Dynamic> = [];
    var onComplete:Array<Dynamic>->Void;
    var onError:(String, Bool)->Void;
    var onCancel:Void->Void;
    var cancelButtonEnabled:Bool = true;
    var currentFileLabel:String = "Current File";
    var overallLabel:String = "Overall Progress";

    public function new(config:DualProgressConfig) {
        super();

        this.taskFunctions = config.tasks;
        this.totalSteps = taskFunctions.length;
        this.onComplete = config.onComplete != null ? config.onComplete : function(results:Array<Dynamic>) {};
        this.onError = config.onError != null ? config.onError : function(error:String, shouldThrow:Bool) {
            trace('Progress error: $error');
            if (shouldThrow) throw new Exception(error);
        };
        this.onCancel = config.onCancel != null ? config.onCancel : function() {};
        this.cancelButtonEnabled = config.cancelButtonEnabled != null ? config.cancelButtonEnabled : true;
        this.currentFileLabel = config.currentFileLabel != null ? config.currentFileLabel : "Current File";
        this.overallLabel = config.overallLabel != null ? config.overallLabel : "Overall Progress";

        setupVisuals(config.title);
        setupAnimations();
        animateIn();

        new FlxTimer().start(0.5, function(_) {
            if (!isCanceled) executeNextTask();
        });
    }

    function setupVisuals(title:String) {
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 180));
        add(background);

        // Larger panel to accommodate two progress bars
        panel = FlxGradient.createGradientFlxSprite(550, 400, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = Std.int((FlxG.width - panel.width) / 2);
        panel.y = Std.int((FlxG.height - panel.height) / 2);
        add(panel);

        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        statusText = new FlxText(panel.x + 20, panel.y + 60, panel.width - 40, "Preparing...", 16);
        statusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        statusText.borderSize = 1;
        add(statusText);

        currentFileText = new FlxText(panel.x + 20, panel.y + 90, panel.width - 40, "", 14);
        currentFileText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, CENTER, OUTLINE, FlxColor.BLACK);
        currentFileText.borderSize = 1;
        add(currentFileText);

        // Current file progress section
        var currentLabel = new FlxText(panel.x + 20, panel.y + 120, panel.width - 40, currentFileLabel, 12);
        currentLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, LEFT, OUTLINE, FlxColor.BLACK);
        currentLabel.borderSize = 1;
        add(currentLabel);

        currentProgressBar = new FlxSprite(panel.x + 40, panel.y + 140);
        currentProgressBar.makeGraphic(Std.int(panel.width - 80), 16, FlxColor.fromRGB(40, 40, 70));
        add(currentProgressBar);

        currentProgressFill = new FlxSprite(currentProgressBar.x + 2, currentProgressBar.y + 2);
        currentProgressFill.makeGraphic(1, 12, FlxColor.LIME);
        add(currentProgressFill);

        currentProgressText = new FlxText(panel.x + 20, panel.y + 160, panel.width - 40, "0%", 12);
        currentProgressText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        currentProgressText.borderSize = 1;
        add(currentProgressText);

        // Overall progress section
        var overallLabel = new FlxText(panel.x + 20, panel.y + 190, panel.width - 40, overallLabel, 12);
        overallLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, LEFT, OUTLINE, FlxColor.BLACK);
        overallLabel.borderSize = 1;
        add(overallLabel);

        overallProgressBar = new FlxSprite(panel.x + 40, panel.y + 210);
        overallProgressBar.makeGraphic(Std.int(panel.width - 80), 20, FlxColor.fromRGB(40, 40, 70));
        add(overallProgressBar);

        overallProgressFill = new FlxSprite(overallProgressBar.x + 2, overallProgressBar.y + 2);
        overallProgressFill.makeGraphic(1, 16, FlxColor.CYAN);
        add(overallProgressFill);

        overallProgressText = new FlxText(panel.x + 20, panel.y + 240, panel.width - 40, "0%", 14);
        overallProgressText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        overallProgressText.borderSize = 1;
        add(overallProgressText);

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

        for (i in 0...20) {
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
        try {
            FlxTween.tween(panel, {"scale.x": 0.7, "scale.y": 0.7, alpha: 0}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                if (onCompleteCallback != null) onCompleteCallback();
                close();
            }
            });
        } catch (e:Dynamic) {
            // If tweening fails, force close immediately
            if (onCompleteCallback != null) onCompleteCallback();
            close();
        }

        try {
            FlxTween.tween(background, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
        } catch (e:Dynamic) {
            if (background != null) background.alpha = 0;
        }
    }

    /**
     * Update the current file/operation progress (0.0 to 1.0)
     */
    public function updateCurrentFileProgress(progress:Float, ?fileName:String) {
        currentFileProgress = Math.max(0.0, Math.min(1.0, progress));

        if (fileName != null) {
            currentFileText.text = fileName;
        }

        updateProgressBars();
    }

    /**
     * Reset current file progress to 0
     */
    public function resetCurrentFileProgress(?fileName:String) {
        updateCurrentFileProgress(0.0, fileName);
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
                resetCurrentFileProgress(funcTask.name);
                updateProgressBars();

                try {
                    var result = funcTask.func(results);
                    results.push(result);
                    currentStep++;
                    updateCurrentFileProgress(1.0);

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
                    resetCurrentFileProgress();
                }

                if (currentIterIndex >= totalIterItems) {
                    // Iteration complete
                    isIterating = false;
                    currentStep++;
                    updateCurrentFileProgress(1.0);
                    new FlxTimer().start(0.1, function(_) {
                        if (!isCanceled) executeNextTask();
                    });
                    return;
                }

                // Update status with iteration progress
                statusText.text = iterTask.name + ' (${currentIterIndex}/${totalIterItems})';
                var itemProgress = currentIterIndex / totalIterItems;
                updateCurrentFileProgress(itemProgress, 'Item ${currentIterIndex + 1}/${totalIterItems}');

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
                    resetCurrentFileProgress();
                }

                if (currentIterIndex >= totalIterItems) {
                    // Map iteration complete
                    isIterating = false;
                    mapKeys = [];
                    currentStep++;
                    updateCurrentFileProgress(1.0);
                    new FlxTimer().start(0.1, function(_) {
                        if (!isCanceled) executeNextTask();
                    });
                    return;
                }

                // Update status with iteration progress
                statusText.text = mapTask.name + ' (${currentIterIndex}/${totalIterItems})';
                var itemProgress = currentIterIndex / totalIterItems;
                updateCurrentFileProgress(itemProgress, 'Item ${currentIterIndex + 1}/${totalIterItems}');

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

    function updateProgressBars() {
        // Current file progress
        var currentFillWidth = Std.int((currentProgressBar.width - 4) * currentFileProgress);
        currentProgressFill.makeGraphic(Std.int(Math.max(1, currentFillWidth)), 12, FlxColor.LIME);

        var currentPercentage = Std.int(currentFileProgress * 100);
        currentProgressText.text = currentPercentage + "%";

        // Overall progress
        var overallProgress:Float;
        if (isIterating && totalIterItems > 0) {
            // Calculate progress within current iteration
            var iterProgress = currentIterIndex / totalIterItems;
            overallProgress = (currentStep + iterProgress) / totalSteps;
        } else {
            overallProgress = currentStep / totalSteps;
        }

        var overallFillWidth = Std.int((overallProgressBar.width - 4) * overallProgress);
        overallProgressFill.makeGraphic(Std.int(Math.max(1, overallFillWidth)), 16, FlxColor.CYAN);

        var overallPercentage = Std.int(overallProgress * 100);
        overallProgressText.text = overallPercentage + "%";
    }

    function finishProgress() {
        statusText.text = "Completed!";
        statusText.color = FlxColor.LIME;
        updateCurrentFileProgress(1.0, "All files completed");
        updateProgressBars();

        FlxFlicker.flicker(titleText, 1, 0.1);

        new FlxTimer().start(0.5, function(_) {
            if (onComplete != null) {
                onComplete(results);
            } else {
                trace("onComplete was null in finishProgress!\n" + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            }
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

    public static function createConfig(title:String, tasks:OneOrMore<ProgressTask>):DualProgressConfig {
        return {
            title: title,
            tasks: tasks
        };
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
