package states;

import backend.ClientPrefs;
import backend.GitHubDownloadManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Http;
import haxe.io.Path;
import states.MainMenuState;
import sys.FileSystem;
import sys.io.File;

enum DownloadType {
    GITHUB_MOD;
    GITHUB_FOLDER;
    EXTERNAL_URL;
    CUSTOM;
}

typedef DownloadItem = {
    var type:DownloadType;
    var url:String;
    var ?destination:String;
    var ?description:String;
    var ?metadata:Dynamic;
}

class DownloadState extends MusicBeatState
{
    var target:FlxState = null;
    var stopMusic:Bool = false;
    var dontUpdate:Bool = false;

    // Loading bar elements (matching MixtapeLoadingScreen)
    var barGroup:FlxSpriteGroup;
    var bar:FlxSprite;
    var barWidth:Int = 0;
    var intendedPercent:Float = 0;
    var curPercent:Float = 0;
    var stateChangeDelay:Float = 0;

    // Mixtape theme elements (matching MixtapeLoadingScreen)
    var bg:FlxSprite;
    var logo:FlxSprite;
    var bottomEffect:FlxSprite;
    var loadingText:FlxText;

    // Animation/effect variables (matching MixtapeLoadingScreen)
    var timePassed:Float = 0;
    var logoFloatOffset:Float = 0;
    var finishedLoading:Bool = false;
    var isExiting:Bool = false;

    // Download management
    var downloadQueue:Array<DownloadItem> = [];
    var currentDownload:DownloadItem = null;
    var currentIndex:Int = 0;
    var totalDownloads:Int = 0;

    // Progress tracking
    var currentProgress:Float = 0.0;
    var overallProgress:Float = 0.0;

    public function new(downloads:Array<DownloadItem>, ?targetState:FlxState, ?previousState:FlxState, ?stopMusic:Bool = false)
    {
        super();

        this.downloadQueue = downloads != null ? downloads : [];
        this.totalDownloads = downloadQueue.length;
        this.target = targetState;
        this.stopMusic = stopMusic;

        // If no target state specified, use previous state or MainMenuState
        if (this.target == null) {
            if (previousState != null) {
                this.target = previousState;
            } else {
                this.target = new MainMenuState();
            }
        }
    }

    override function create()
    {
        super.create();

        persistentUpdate = true;

        // Create background similar to splash screen (matching MixtapeLoadingScreen)
        bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.color = 0xFF270138; // Purple tint similar to main menu
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        // Create the main Mixtape logo (matching MixtapeLoadingScreen)
        logo = new FlxSprite().loadGraphic(Paths.image('logo'));
        try {
            // logo.frames = Paths.getSparrowAtlas('logoBumpin');
            // logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
            // logo.animation.play('bump');
        } catch (e:haxe.Exception) {
            // Fallback to static image if animated atlas doesn't exist
            logo.loadGraphic(Paths.image('menuDesat')); // Use a basic background as fallback
        }
        logo.antialiasing = ClientPrefs.data.antialiasing;
        logo.setGraphicSize(Std.int(logo.width * 0.4));
        logo.updateHitbox();
        logo.screenCenter();
        logo.y -= 300;
        add(logo);

        // Create bottom effect/glow (matching MixtapeLoadingScreen)
        bottomEffect = new FlxSprite(0, FlxG.height - 150);
        bottomEffect.makeGraphic(FlxG.width, 150, FlxColor.WHITE);
        bottomEffect.alpha = 0.1;
        bottomEffect.blend = ADD;
        add(bottomEffect);

        // Create loading bar group (matching MixtapeLoadingScreen)
        barGroup = new FlxSpriteGroup();
        add(barGroup);

        var barBack:FlxSprite = new FlxSprite(0, 620).makeGraphic(1, 1, FlxColor.BLACK);
        barBack.scale.set(FlxG.width - 300, 25);
        barBack.updateHitbox();
        barBack.screenCenter(X);
        barGroup.add(barBack);

        bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, 0xFF33FFFF); // Mixtape blue
        bar.scale.set(0, 15);
        bar.updateHitbox();
        barGroup.add(bar);
        barWidth = Std.int(barBack.width - 10);

        // Loading text (matching MixtapeLoadingScreen)
        loadingText = new FlxText(0, 660, FlxG.width, "Preparing downloads...", 24);
        loadingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
        loadingText.borderSize = 2;
        loadingText.screenCenter(X);
        add(loadingText);

        // Start downloading after a brief delay
        new FlxTimer().start(0.5, function(timer:FlxTimer) {
            startDownloads();
        });
    }

    function startDownloads()
    {
        if (downloadQueue.length == 0) {
            onAllDownloadsComplete();
            return;
        }

        // Check if GitHub content is already downloaded
        if (hasGitHubDownloads() && GitHubDownloadManager.areGitHubModsDownloaded()) {
            loadingText.text = "GitHub content already downloaded!";
            progressText.text = "100%";
            trace('GitHub content already available offline, skipping download');

            new FlxTimer().start(1.0, function(timer:FlxTimer) {
                onAllDownloadsComplete();
            });
            return;
        }

        trace('Starting ${downloadQueue.length} downloads...');
        processNextDownload();
    }

    function hasGitHubDownloads():Bool
    {
        for (download in downloadQueue) {
            if (download.type == GITHUB_MOD || download.type == GITHUB_FOLDER) {
                return true;
            }
        }
        return false;
    }

    function processNextDownload()
    {
        if (currentIndex >= downloadQueue.length) {
            onAllDownloadsComplete();
            return;
        }

        currentDownload = downloadQueue[currentIndex];
        currentProgress = 0.0;

        // Update UI
        var description = currentDownload.description != null ? currentDownload.description : "Downloading...";
        loadingText.text = description;

        trace('Processing download ${currentIndex + 1}/${totalDownloads}: ${currentDownload.url}');

        // Handle different download types
        switch (currentDownload.type) {
            case GITHUB_MOD:
                downloadGitHubMod();
            case GITHUB_FOLDER:
                downloadGitHubFolder();
            case EXTERNAL_URL:
                downloadExternalFile();
            case CUSTOM:
                downloadCustom();
        }
    }

    function downloadGitHubMod()
    {
        loadingText.text = 'Downloading GitHub content...';

        // Use the existing GitHubDownloadManager
        GitHubDownloadManager.downloadAllGitHubMods(
            function() {
                // Download complete
                trace('GitHub download completed successfully');
                onDownloadComplete();
            },
            function(progress:Float, status:String) {
                // Progress update
                loadingText.text = status;
                updateProgress(progress);
            }
        );
    }

    function downloadGitHubFolder()
    {
        loadingText.text = 'Downloading GitHub mods folder...';

        // Use the existing GitHubDownloadManager (it handles both individual and folder mods)
        GitHubDownloadManager.downloadAllGitHubMods(
            function() {
                // Download complete
                trace('GitHub folder download completed successfully');
                onDownloadComplete();
            },
            function(progress:Float, status:String) {
                // Progress update
                loadingText.text = status;
                updateProgress(progress);
            }
        );
    }

    function downloadExternalFile()
    {
        loadingText.text = 'Downloading: ${currentDownload.url}';

        // Perform actual HTTP download
        performHttpDownload(currentDownload.url, currentDownload.destination);
    }

    function downloadCustom()
    {
        loadingText.text = 'Processing custom download...';

        // Handle custom download logic based on metadata
        if (currentDownload.metadata != null && Reflect.hasField(currentDownload.metadata, "downloadUrl")) {
            var customUrl = Reflect.field(currentDownload.metadata, "downloadUrl");
            performHttpDownload(customUrl, currentDownload.destination);
        } else {
            // Fallback to URL if no custom metadata
            performHttpDownload(currentDownload.url, currentDownload.destination);
        }
    }

    /**
     * Performs actual HTTP download of external files
     */
    function performHttpDownload(url:String, ?destination:String)
    {
        if (url == null || url == "") {
            trace('Invalid URL for download: $url');
            onDownloadComplete();
            return;
        }

        trace('Starting HTTP download: $url');

        // Determine local path
        var fileName = destination != null ? destination : extractFileNameFromUrl(url);
        var localPath = 'downloads/external/$fileName';

        // Create directory if needed
        var dir = haxe.io.Path.directory(localPath);
        createDirectoryIfNotExists(dir);

        // Skip if file already exists and is recent (like GitHub downloads)
        if (FileSystem.exists(localPath)) {
            var stat = FileSystem.stat(localPath);
            var ageHours = (Date.now().getTime() - stat.mtime.getTime()) / (1000 * 60 * 60);
            if (ageHours < 24) { // Cache for 24 hours
                trace('File already exists and is recent, skipping: $localPath');
                updateProgress(1.0);
                onDownloadComplete();
                return;
            }
        }

        try {
            var http = new Http(url);
            http.addHeader("User-Agent", "Mixtape-Engine-Downloader");

            // Add custom headers if provided in metadata
            if (currentDownload.metadata != null && Reflect.hasField(currentDownload.metadata, "headers")) {
                var headers = Reflect.field(currentDownload.metadata, "headers");
                for (field in Reflect.fields(headers)) {
                    var value = Reflect.field(headers, field);
                    http.addHeader(field, Std.string(value));
                }
            }

            var responseData:haxe.io.Bytes = null;
            var responseError:String = null;
            var contentLength:Int = 0;
            var downloadedBytes:Int = 0;

            http.onData = function(data:String) {
                responseData = haxe.io.Bytes.ofString(data);
            };

            http.onBytes = function(data:haxe.io.Bytes) {
                responseData = data;
            };

            http.onError = function(error:String) {
                responseError = error;
                trace('HTTP download error for $url: $error');
            };

            http.onStatus = function(status:Int) {
                if (status < 200 || status >= 300) {
                    responseError = 'HTTP Error: $status';
                }
            };

            // Perform the download
            http.request(false);

            if (responseError == null && responseData != null) {
                try {
                    File.saveBytes(localPath, responseData);
                    trace('Successfully downloaded: $localPath (${responseData.length} bytes)');
                    updateProgress(1.0);
                    onDownloadComplete();
                } catch (e:Dynamic) {
                    trace('Error saving downloaded file $localPath: $e');
                    onDownloadComplete();
                }
            } else {
                trace('Failed to download $url: $responseError');
                onDownloadComplete();
            }

        } catch (e:Dynamic) {
            trace('Exception during HTTP download of $url: $e');
            onDownloadComplete();
        }
    }

    /**
     * Extracts filename from URL for local storage
     */
    function extractFileNameFromUrl(url:String):String
    {
        var urlParts = url.split("/");
        var fileName = urlParts[urlParts.length - 1];

        // Remove query parameters
        if (fileName.indexOf("?") != -1) {
            fileName = fileName.substring(0, fileName.indexOf("?"));
        }

        // Fallback if no filename found
        if (fileName == "" || fileName.indexOf(".") == -1) {
            fileName = "download_" + Date.now().getTime();
        }

        return fileName;
    }

    /**
     * Creates directory recursively if it doesn't exist
     */
    function createDirectoryIfNotExists(path:String):Void
    {
        if (FileSystem.exists(path)) return;

        var parts = path.replace("\\", "/").split("/");
        var current = "";

        for (i in 0...parts.length) {
            current += parts[i];
            if (current.length > 0 && !FileSystem.exists(current)) {
                try {
                    FileSystem.createDirectory(current);
                } catch (e:Dynamic) {
                    trace('Error creating directory $current: $e');
                }
            }
            if (i < parts.length - 1) current += "/";
        }
    }

    function updateProgress(progress:Float)
    {
        currentProgress = progress;

        // Calculate overall progress
        var completedDownloads = currentIndex;
        var currentDownloadProgress = progress;
        overallProgress = (completedDownloads + currentDownloadProgress) / totalDownloads;

        // Update intended percent for the loading bar
        intendedPercent = overallProgress;
    }

    function onDownloadComplete()
    {
        currentIndex++;

        // Add small delay between downloads
        new FlxTimer().start(0.2, function(timer:FlxTimer) {
            processNextDownload();
        });
    }

    function onAllDownloadsComplete()
    {
        loadingText.text = "Downloads complete!";

        trace('All downloads completed successfully!');

        finishedLoading = true;
        stateChangeDelay = 0.5; // Small delay before transition
    }

    function onLoad()
    {
        if (isExiting) return;
        isExiting = true;

        // Choose random exit animation: fade or drop (matching MixtapeLoadingScreen)
        var exitType = FlxG.random.bool() ? 'fade' : 'drop';

        trace('Downloads complete! Using exit animation: $exitType');

        switch(exitType)
        {
            case 'fade':
                // Fade out animation
                FlxTween.tween(logo, {alpha: 0}, 0.8, {ease: FlxEase.quadOut});
                FlxTween.tween(bottomEffect, {alpha: 0}, 0.6, {ease: FlxEase.quadOut});
                FlxTween.tween(barGroup, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
                FlxTween.tween(loadingText, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});

                FlxTween.tween(bg, {alpha: 0}, 1.0, {
                    ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween) {
                        finishTransition();
                    }
                });

            case 'drop':
                // Drop animation
                FlxTween.tween(logo, {y: FlxG.height + 100, angle: FlxG.random.float(-15, 15)}, 0.8, {
                    ease: FlxEase.backIn
                });
                FlxTween.tween(bottomEffect, {alpha: 0}, 0.6, {ease: FlxEase.quadOut});
                FlxTween.tween(barGroup, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
                FlxTween.tween(loadingText, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});

                new FlxTimer().start(0.9, function(tmr:FlxTimer) {
                    FlxTween.tween(bg, {alpha: 0}, 1.0, {
                        ease: FlxEase.quadOut,
                        onComplete: function(tween:FlxTween) {
                            finishTransition();
                        }
                    });
                });
        }
    }

    function finishTransition()
    {
        if (stopMusic && FlxG.sound.music != null)
            FlxG.sound.music.stop();

        FlxG.camera.visible = false;
        MusicBeatState.switchState(target);
        finishedLoading = true;
    }

    var transitioning:Bool = false;
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (dontUpdate || isExiting) return;

        timePassed += elapsed;

        // Logo floating animation (subtle) - matching MixtapeLoadingScreen
        logoFloatOffset = Math.sin(timePassed * 2) * 5;
        if (logo != null)
        {
            logo.offset.y = logoFloatOffset;
        }

        // Bottom effect breathing - matching MixtapeLoadingScreen
        if (bottomEffect != null)
        {
            bottomEffect.alpha = 0.05 + Math.sin(timePassed * 1.5) * 0.03;
        }

        // Loading text dots animation - matching MixtapeLoadingScreen
        var dots:String = '';
        switch(Math.floor(timePassed % 1.5 * 3))
        {
            case 0:
                dots = '.';
            case 1:
                dots = '..';
            case 2:
                dots = '...';
        }

        // Update loading text with current download status
        var baseText = currentDownload != null && currentDownload.description != null ?
                      currentDownload.description : "Downloading";
        loadingText.text = baseText + dots;

        if (!transitioning)
        {
            if (!finishedLoading)
            {
                // Update progress based on current download progress
                intendedPercent = overallProgress;
            }
            else if (stateChangeDelay <= 0)
            {
                transitioning = true;
                onLoad();
                return;
            }
            else
            {
                stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
            }
        }

        // Update loading bar (matching MixtapeLoadingScreen)
        if (curPercent != intendedPercent)
        {
            if (Math.abs(curPercent - intendedPercent) < 0.001) curPercent = intendedPercent;
            else curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

            bar.scale.x = barWidth * curPercent;
            bar.updateHitbox();
        }

        // Allow cancelling with ESC key
        if (FlxG.keys.justPressed.ESCAPE) {
            trace('Download cancelled by user');
            finishedLoading = true;
            stateChangeDelay = 0;
        }
    }

    // Static helper functions for easy state creation
    public static function downloadGitHubMod(owner:String, repo:String, ?targetState:FlxState, ?previousState:FlxState, ?stopMusic:Bool = false):DownloadState
    {
        var downloads:Array<DownloadItem> = [{
            type: GITHUB_MOD,
            url: 'https://github.com/$owner/$repo',
            description: 'Downloading GitHub mod: $owner/$repo'
        }];

        return new DownloadState(downloads, targetState, previousState, stopMusic);
    }

    public static function downloadGitHubFolder(owner:String, repo:String, ?targetState:FlxState, ?previousState:FlxState, ?stopMusic:Bool = false):DownloadState
    {
        var downloads:Array<DownloadItem> = [{
            type: GITHUB_FOLDER,
            url: 'https://github.com/$owner/$repo',
            description: 'Downloading GitHub mods folder: $owner/$repo'
        }];

        return new DownloadState(downloads, targetState, previousState, stopMusic);
    }

    public static function downloadMultipleGitHub(repos:Array<{owner:String, repo:String, isFolder:Bool}>, ?targetState:FlxState, ?previousState:FlxState, ?stopMusic:Bool = false):DownloadState
    {
        var downloads:Array<DownloadItem> = [];

        for (repoInfo in repos) {
            downloads.push({
                type: repoInfo.isFolder ? GITHUB_FOLDER : GITHUB_MOD,
                url: 'https://github.com/${repoInfo.owner}/${repoInfo.repo}',
                description: 'Downloading: ${repoInfo.owner}/${repoInfo.repo}'
            });
        }

        return new DownloadState(downloads, targetState, previousState, stopMusic);
    }

    public static function downloadCustomQueue(downloads:Array<DownloadItem>, ?targetState:FlxState, ?previousState:FlxState, ?stopMusic:Bool = false):DownloadState
    {
        return new DownloadState(downloads, targetState, previousState, stopMusic);
    }

    /**
     * Downloads all configured GitHub mods and folders
     */
    public static function downloadAllConfiguredGitHubMods(?targetState:FlxState, ?previousState:FlxState, ?stopMusic:Bool = false):DownloadState
    {
        var downloads:Array<DownloadItem> = [{
            type: GITHUB_MOD, // We'll use one item to trigger the GitHubDownloadManager
            url: "github://all",
            description: "Downloading all configured GitHub mods..."
        }];

        return new DownloadState(downloads, targetState, previousState, stopMusic);
    }
}
