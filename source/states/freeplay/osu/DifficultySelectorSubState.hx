package states.freeplay.osu;

// import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import states.freeplay.OsuFreeplayState;

import backend.Highscore;
import backend.Song;
import backend.WeekData;

class DifficultySelectorSubState extends MusicBeatSubstate
{
    private var listLength:Int = Difficulty.list.length;

    var sprite:FlxSprite;
    private static var difficulty:Int = 0;

    var currentDifficultyId:String = 'normal';

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

        difficultySprites = new Map<String, FlxSprite>();

        sprite = new FlxSprite().loadGraphic(Paths.image('menudifficulties/${Difficulty.list[difficulty].toLowerCase()}'));
        sprite.screenCenter();
        add(sprite);

        buildDifficultySprite('normal');
        buildDifficultySprite();

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

        Mods.currentModDirectory = song.folder;
        PlayState.storyWeek = song.week;
        Difficulty.loadFromWeek();
        listLength = Difficulty.list.length;
        WeekData.setDirectoryFromWeek();
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
                    Mods.currentModDirectory = song.folder;
                    Song.loadFromJson(poop, songLowercase);
                    PlayState.isStoryMode = false;
                    PlayState.storyDifficulty = difficulty;
                    trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
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

        buildDifficultySprite(Difficulty.list[difficulty].toLowerCase());
        sprite.screenCenter();
    }

    var difficultySprites:Map<String, FlxSprite>;
    function buildDifficultySprite(?diff:String):Void
    {
        if (diff == null) diff = currentDifficultyId;
        remove(sprite);
        sprite = difficultySprites.get(diff);
        if (sprite == null)
        {
            sprite = new FlxSprite(0, 0);
        
            if (Paths.exists(Paths.file('images/menudifficulties/${diff}.xml')))
            {
                sprite.frames = Paths.getSparrowAtlas('menudifficulties/${diff}');
                sprite.animation.addByPrefix('idle', 'idle0', 24, true);
                if (ClientPrefs.data.flashing) sprite.animation.play('idle');
            }
            else
            {
                sprite.loadGraphic(Paths.image('menudifficulties/${diff}'));
            }
        
            difficultySprites.set(diff, sprite);
        }    
        sprite.updateHitbox();
        sprite.screenCenter();
        add(sprite);
    }
}