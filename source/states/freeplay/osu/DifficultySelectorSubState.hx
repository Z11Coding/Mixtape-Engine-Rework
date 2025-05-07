package states.freeplay.osu;

// import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import states.freeplay.OsuFreeplayState;

import backend.Highscore;
import backend.Song;

class DifficultySelectorSubState extends MusicBeatSubstate
{
    private static var listLength:Int = Difficulty.list.length;

    var sprite:FlxSprite;
    private static var difficulty:Int = 0;

    var missingTextBG:FlxSprite;
	var missingText:FlxText;

    var song:Dynamic;

    var canDo:Bool = false;

    public function new(song:Dynamic)
    {
        super();

        this.song = song;

        var background:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0.85;
        add(background);

        sprite = new FlxSprite().loadGraphic(Paths.image('menudifficulties/${Difficulty.list[difficulty].toLowerCase()}'));
        sprite.screenCenter();
        add(sprite);

        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

        new FlxTimer().start(0.2, function(tmr:FlxTimer) {
            canDo = true;
        });
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if(canDo)
        {
            if(controls.UI_LEFT_P || controls.UI_RIGHT_P)
                changeDiff(controls.UI_LEFT_P? -1 : 1);
            if(controls.BACK)
                close();
            if(controls.ACCEPT)
            {
                try
                {
                    persistentUpdate = false;
                    var songLowercase:String = Paths.formatToSongPath(song.songName);
    				var poop:String = Highscore.formatSong(songLowercase, difficulty);
                    Song.loadFromJson(poop, songLowercase);
                    PlayState.isStoryMode = false;
                    PlayState.storyDifficulty = difficulty;
                }
                catch(e:Dynamic)
                {
                    trace('ERROR! $e');

                    var errorStr:String = e.toString();
                    if(errorStr.startsWith('[file_contents,assets/shared/songs/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
                    missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
                    missingText.screenCenter(Y);
                    missingText.visible = true;
                    missingTextBG.visible = true;
                    FlxG.sound.play(Paths.sound('cancelMenu'));

                    super.update(elapsed);
                    return;
                }
                LoadingState.prepareToSong();
                LoadingState.loadAndSwitchState(new PlayState());
            }
            if (FlxG.keys.firstJustPressed() != FlxKey.NONE && missingText.visible)
			{
				missingText.visible = false;
                missingTextBG.visible = false;
			}
        }
    }

    function changeDiff(diff:Int = 0)
    {
        difficulty += diff;

        if(difficulty > listLength - 1)
            difficulty = 0;
        if(difficulty < 0)
            difficulty = listLength - 1;

        sprite.loadGraphic(Paths.image('menudifficulties/${Difficulty.list[difficulty].toLowerCase()}'));
        sprite.screenCenter();
    }

    override function destroy() {
		OsuFreeplayState.inSub = false;
	}
}