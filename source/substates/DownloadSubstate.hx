package substates;

import backend.GitHubDownloadManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.DownloadState;

/**
 * Transparent substate version of DownloadState for downloading GitHub content
 * without interrupting the current state. Prevents state updates while downloading.
 */
class DownloadSubstate extends MusicBeatSubstate
{
    private var downloadGroup:FlxTypedGroup<FlxSprite>;
    private var loadingBg:FlxSprite;
    private var progressBar:FlxSprite;
    private var progressBarBg:FlxSprite;
    private var loadingText:FlxText;
    private var progressText:FlxText;

    private var downloadStarted:Bool = false;
    private var downloadComplete:Bool = false;

    private var onComplete:Void->Void;
    private var onProgress:Float->String->Void;

    private var barWidth:Float = 400;
    private var barHeight:Float = 20;

    public function new(?onComplete:Void->Void, ?onProgress:Float->String->Void)
    {
        super();

        this.onComplete = onComplete;
        this.onProgress = onProgress;

        // Prevent parent state from updating while downloading
        persistentUpdate = false;
        persistentDraw = true;
    }

    override function create()
    {
        super.create();

        downloadGroup = new FlxTypedGroup<FlxSprite>();
        add(downloadGroup);

        // Semi-transparent background to indicate loading state
        loadingBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        loadingBg.alpha = 0.7;
        downloadGroup.add(loadingBg);

        // Progress bar background
        progressBarBg = new FlxSprite(0, 0).makeGraphic(Std.int(barWidth + 10), Std.int(barHeight + 10), FlxColor.WHITE);
        progressBarBg.screenCenter();
        downloadGroup.add(progressBarBg);

        // Progress bar
        progressBar = new FlxSprite(0, 0).makeGraphic(Std.int(barWidth), Std.int(barHeight), 0xFF00FF00);
        progressBar.setPosition(progressBarBg.x + 5, progressBarBg.y + 5);
        progressBar.scale.x = 0;
        progressBar.updateHitbox();
        downloadGroup.add(progressBar);

        // Loading text
        loadingText = new FlxText(0, progressBarBg.y - 60, FlxG.width, "Downloading GitHub content...", 24);
        loadingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
        loadingText.borderSize = 2;
        downloadGroup.add(loadingText);

        // Progress percentage text
        progressText = new FlxText(0, progressBarBg.y + 40, FlxG.width, "0%", 18);
        progressText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
        progressText.borderSize = 1;
        downloadGroup.add(progressText);

        // Start download after brief delay
        new FlxTimer().start(0.5, function(timer:FlxTimer) {
            startDownload();
        });
    }

    private function startDownload():Void
    {
        if (downloadStarted) return;

        downloadStarted = true;

        trace('DownloadSubstate: Starting GitHub content download...');

        // Check if content is already downloaded
        if (GitHubDownloadManager.areGitHubModsDownloaded())
        {
            loadingText.text = "GitHub content already available!";
            progressText.text = "100%";
            updateProgressBar(1.0);

            new FlxTimer().start(1.0, function(timer:FlxTimer) {
                completeDownload();
            });
            return;
        }

        // Start the actual download
        GitHubDownloadManager.downloadAllGitHubMods(
            function() {
                // Download completed
                trace('DownloadSubstate: GitHub download completed successfully');
                completeDownload();
            },
            function(progress:Float, status:String) {
                // Progress update
                loadingText.text = status;
                progressText.text = '${Math.round(progress * 100)}%';
                updateProgressBar(progress);

                if (onProgress != null) onProgress(progress, status);
            }
        );
    }

    private function updateProgressBar(progress:Float):Void
    {
        progress = FlxMath.bound(progress, 0, 1);

        FlxTween.tween(progressBar.scale, {x: progress}, 0.2, {
            ease: FlxEase.quadOut,
            onUpdate: function(tween:FlxTween) {
                progressBar.updateHitbox();
            }
        });
    }

    private function completeDownload():Void
    {
        if (downloadComplete) return;

        downloadComplete = true;

        loadingText.text = "Download complete!";
        progressText.text = "100%";
        updateProgressBar(1.0);

        // Fade out the download UI
        FlxTween.tween(downloadGroup, {alpha: 0}, 0.5, {
            ease: FlxEase.quadOut,
            onComplete: function(tween:FlxTween) {
                if (onComplete != null) onComplete();

                // Re-enable parent state updating
                persistentUpdate = true;

                // Close the substate
                close();
            }
        });
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Allow cancelling with ESC key (but show warning)
        if (FlxG.keys.justPressed.ESCAPE && downloadStarted && !downloadComplete)
        {
            trace('DownloadSubstate: Download cancelled by user');
            loadingText.text = "Download cancelled - some content may not be available";

            // Still complete the download process to prevent hanging
            new FlxTimer().start(2.0, function(timer:FlxTimer) {
                completeDownload();
            });
        }
    }

    /**
     * Static helper to trigger a download substate if GitHub content is missing
     * @param state The current state to add the substate to
     * @param onComplete Callback when download is complete
     * @param onProgress Progress callback
     * @return True if download was triggered, false if content already exists
     */
    public static function downloadIfMissing(state:MusicBeatState, ?onComplete:Void->Void, ?onProgress:Float->String->Void):Bool
    {
        // Check if we have missing GitHub files that need downloading
        backend.GitHubAPI.checkAllConfiguredMods();

        if (backend.GitHubAPI.hasMissingGitHubFiles() || !GitHubDownloadManager.areGitHubModsDownloaded())
        {
            trace('DownloadSubstate: Missing GitHub content detected, starting download...');

            var downloadSubstate = new DownloadSubstate(onComplete, onProgress);
            state.openSubState(downloadSubstate);

            return true;
        }

        // Content already available
        if (onComplete != null) onComplete();
        return false;
    }
}
