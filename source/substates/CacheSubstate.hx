package substates;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

class SimpleLoadingSubstate extends FlxSubState {
    var progressBar:FlxSprite;
    var progressBarBackground:FlxSprite;
    var loadingComplete:Bool = false;
    var loadTotal:Int = 0;
    var currentLoadProgress:Int = 0; // Tracks the number of completed operations

    public function new() {
        super();

        progressBarBackground = new FlxSprite(0, FlxG.height - 20);
        progressBarBackground.makeGraphic(FlxG.width, 20, FlxColor.DARK_GREY);
        add(progressBarBackground);

        progressBar = new FlxSprite(0, FlxG.height - 20);
        progressBar.makeGraphic(1, 20, FlxColor.GREEN);
        add(progressBar);
    }


    
    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (!initialized) {
            initializeCache();
            initialized = true;
        }
    
        if (!loadingComplete) {
            // Update currentLoadProgress based on actual loading progress
            // This should be done elsewhere in the code, where the loading operations are actually performed
            // For example, increment currentLoadProgress each time an operation (like loading a file) completes
    
            // Calculate the percentage of operations completed
            var progressPercentage:Float = currentLoadProgress / loadTotal;
    
            // Update progressBar scale based on progress
            progressBar.scale.x = progressPercentage * FlxG.width;
    
            // Check if loading is complete
            if (currentLoadProgress >= totalLoadOperations) {
                progressBar.scale.x = FlxG.width; // Ensure the progressBar is fully scaled
                loadingComplete = true;
                slideOffScreen();
            }
        }
    }

    function slideOffScreen():Void {
        FlxTween.tween(this, { y: -FlxG.height }, 0.5, {
            onComplete: function(_) {
                close();
            }
        });
    }

    function initializeCache():Void {
        #if cpp
        var combinedImages:Array<String> = [];
        var combinedMusic:Array<String> = [];

        if (ClientPrefs.data.graphicsPreload2) {
            Paths.crawlDirectory("assets", ".png", combinedImages);
            Paths.crawlDirectory("mods", ".png", combinedImages);
        }

        if (ClientPrefs.data.musicPreload2) {
            Paths.crawlDirectory("assets", ".ogg", combinedMusic);
            Paths.crawlDirectory("mods", ".ogg", combinedMusic); // Corrected extension
        }

        for (imagePath in combinedImages) {
            ImageCache.add(imagePath);
            loadTotal++;
        }

        for (musicPath in combinedMusic) {
            if(CoolUtil.exists(musicPath)){
                if(CoolUtil.exists(Paths.cacheInst(musicPath))){
                    FlxG.sound.cache(Paths.cacheInst(musicPath));
                }
                if(CoolUtil.exists(Paths.cacheVoices(musicPath))){
                    FlxG.sound.cache(Paths.cacheVoices(musicPath));
                }
                if(CoolUtil.exists(Paths.cacheSound(musicPath))){
                    FlxG.sound.cache(Paths.cacheSound(musicPath));
                }
                if(CoolUtil.exists(Paths.cacheMusic(musicPath))) {
                    FlxG.sound.cache(Paths.cacheMusic(musicPath));
                }
            }
            else{
                trace("Music/Sound: File at " + musicPath + " not found, skipping cache.");
            }
            loadTotal++;
        }

        var jsonCache:Array<String> = [];
        Paths.crawlDirectory("assets", ".json", jsonCache);
        Paths.crawlDirectory("mods", ".json", jsonCache);

        for (json in jsonCache) {
            JSONCache.addToCache(json);
        }

        loadTotal = combinedImages.length + combinedMusic.length;
        trace("Loading total items: " + loadTotal);
        #end
    }
}