package stages.cutscenes;

class VideoCutscene {
    public static function playVideo(videoName:String,onEnd:() -> Void) {
        var game = PlayState.instance;
        if (videoName != null)
            {
                #if VIDEOS_ALLOWED
                game.startVideo(videoName);
                #if !LEGACY_PSYCH
                try {
                    game.videoCutscene.finishCallback = game.videoCutscene.onSkip = function()
                    {
                        game.videoCutscene = null;
                        onEnd();
                    };
                } catch (e:Dynamic) {
                    trace("Error setting video cutscene callbacks: " + e);
                    trace("It is likely that the video wasn't able to be loaded.");
                    onEnd();
                }
                #else
                @:privateAccess
                game.video.bitmap.onEndReached.add(function()
                    {
                        game.video = null;
                        onEnd();
                    });
                    #end
                #else // Make a timer to prevent it from crashing due to sprites not being ready yet.
                new FlxTimer().start(0.0, function(tmr:FlxTimer)
                {
                    onEnd();
                });
                #end
                return;
            }
    }
}