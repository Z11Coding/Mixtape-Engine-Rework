package archipelago.states;

import archipelago.APCategoryState;
import archipelago.APInfo;
import archipelago.HighQualityTrapManager;
import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * HighQualityWaitingState
 * A waiting state that appears when the High Quality Trap is activated
 * and the SiivaGunner mod needs to be downloaded and installed.
 */
class HighQualityWaitingState extends MusicBeatState {
    private var bg:FlxSprite;
    private var titleText:FlxText;
    private var statusText:FlxText;
    private var loadingText:FlxText;
    private var progressBar:FlxSprite;
    private var progressFill:FlxSprite;

    private var checkTimer:FlxTimer;
    private var loadingDots:Int = 0;
    private var loadingTimer:FlxTimer;
    private var _apGame:archipelago.APGameState;
    private var _apClient:archipelago.Client;
    private var _useTrap:Bool;

    public function new(apGame:archipelago.APGameState, apClient:archipelago.Client, ?useTrap:Bool = true) {
        super();
        _apGame = apGame;
        _apClient = apClient;
        _useTrap = useTrap;
    }

    override function create():Void {
        super.create();

        // Background
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(20, 20, 30));
        add(bg);

        // Title
        titleText = new FlxText(0, FlxG.height * 0.2, FlxG.width, "High Quality Trap Activated!");
        titleText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Status text
        statusText = new FlxText(0, FlxG.height * 0.35, FlxG.width, "Downloading SiivaGunner High Quality Rips to temporary folder...");
        statusText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        statusText.borderSize = 1;
        add(statusText);

        // Loading text with animated dots
        loadingText = new FlxText(0, FlxG.height * 0.5, FlxG.width, "Installing temporary mods");
        loadingText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        loadingText.borderSize = 1;
        add(loadingText);

        // Progress bar background
        progressBar = new FlxSprite(FlxG.width * 0.25, FlxG.height * 0.6).makeGraphic(Std.int(FlxG.width * 0.5), 20, FlxColor.GRAY);
        add(progressBar);

        // Progress bar fill
        progressFill = new FlxSprite(progressBar.x, progressBar.y).makeGraphic(1, 20, FlxColor.LIME);
        add(progressFill);

        // Subtitle with SiivaGunner reference
        var subtitleText = new FlxText(0, FlxG.height * 0.8, FlxG.width,
            "Preparing to replace your songs with higher quality rips...\n" +
            "(Downloaded to temporary folder - will be cleaned up later)\n" +
            "(This is a joke reference to SiivaGunner's channel)");
        subtitleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
        subtitleText.borderSize = 1;
        add(subtitleText);

        // Start timers
        startLoadingAnimation();
        startProgressCheck();

        // Fade in effect
        titleText.alpha = 0;
        statusText.alpha = 0;
        loadingText.alpha = 0;

        FlxTween.tween(titleText, {alpha: 1}, 0.5);
        FlxTween.tween(statusText, {alpha: 1}, 0.5, {startDelay: 0.2});
        FlxTween.tween(loadingText, {alpha: 1}, 0.5, {startDelay: 0.4});
    }

    private function startLoadingAnimation():Void {
        loadingTimer = new FlxTimer().start(0.5, function(timer:FlxTimer) {
            loadingDots = (loadingDots + 1) % 4;
            var dotsString = "";
            for (i in 0...loadingDots) {
                dotsString += ".";
            }
            loadingText.text = "Installing temporary mods" + dotsString;
        }, 0);
    }

    private function startProgressCheck():Void {
        checkTimer = new FlxTimer().start(0.1, function(timer:FlxTimer) {
            updateProgress();

            // Check if download is complete
            if (!HighQualityTrapManager.needsWaitingState()) {
                // Download complete, proceed to category state
                completeInstallation();
            }
        }, 0);
    }

    private function updateProgress():Void {
        var progress = HighQualityTrapManager.getDownloadProgress();
        var targetWidth = Std.int(progressBar.width * progress);

        // Animate progress bar
        if (progressFill.width != targetWidth) {
            FlxTween.cancelTweensOf(progressFill);
            FlxTween.tween(progressFill, {width: targetWidth}, 0.2);
        }

        // Update status based on progress
        if (progress < 0.1) {
            statusText.text = "Connecting to SiivaGunner repository...";
        } else if (progress < 0.3) {
            statusText.text = "Downloading High Quality Rips to temp folder...";
        } else if (progress < 0.7) {
            statusText.text = "Installing temporary mod files...";
        } else if (progress < 1.0) {
            statusText.text = "Finalizing temporary installation...";
        } else {
            statusText.text = "Temporary installation complete!";
        }
    }

    private function completeInstallation():Void {
        // Stop timers
        if (checkTimer != null) {
            checkTimer.cancel();
            checkTimer = null;
        }
        if (loadingTimer != null) {
            loadingTimer.cancel();
            loadingTimer = null;
        }

        // Update final text
        statusText.text = "High Quality Trap ready!";
        loadingText.text = "Proceeding to game (temp mods loaded)...";

        // Refresh the trap manager to scan for new songs
        HighQualityTrapManager.refresh();

        // Wait a moment then transition to APCategoryState
        new FlxTimer().start(1.5, function(timer:FlxTimer) {
            trace("HighQualityWaitingState: Transitioning to APCategoryState");

            if (_useTrap) {
                HighQualityTrapManager.startUsingTrap();
            }

            // Get the current AP game state from APInfo
            var gameState = APInfo.apGame;
            if (gameState != null) {
                FlxG.switchState(new APCategoryState(_apGame, _apClient));
            } else {
                trace("HighQualityWaitingState: Warning - No AP game state available, transitioning to regular CategoryState");
                FlxG.switchState(new states.CategoryState());
            }
        });
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Allow manual skip with ESCAPE or ENTER (for testing)
        // if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER) {
        //     trace("HighQualityWaitingState: Manual skip triggered");
        //     completeInstallation();
        // }
    }

    override function destroy():Void {
        if (checkTimer != null) {
            checkTimer.cancel();
            checkTimer = null;
        }
        if (loadingTimer != null) {
            loadingTimer.cancel();
            loadingTimer = null;
        }

        HighQualityTrapManager.activateTrap();

        super.destroy();
    }
}
