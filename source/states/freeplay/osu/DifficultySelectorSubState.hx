package states.freeplay.osu;

import backend.Highscore;
import backend.Song;
import backend.WeekData;
// import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import haxe.Json;
import lime.utils.Assets;
import states.freeplay.OsuFreeplayState;
import states.freeplay.backend.DifficultyStars;

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
    var difficultyStars:DifficultyStars;
    var diffTextnecausetherewasnoimage:FlxText;
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

        difficultyStars = new DifficultyStars(0, 0);
		difficultyStars.visible = true;
        difficultyStars.scrollFactor.set();
        difficultyStars.screenCenter();
        difficultyStars.y += 15;
        difficultyStars.x += 25;
		add(difficultyStars);

        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

        diffTextnecausetherewasnoimage = new FlxText(50, 0, FlxG.width - 100, '', 24);
        diffTextnecausetherewasnoimage.setFormat(Paths.font("difficulty.ttf"), 80, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        diffTextnecausetherewasnoimage.scrollFactor.set();
        diffTextnecausetherewasnoimage.visible = false;
        add(diffTextnecausetherewasnoimage);

        new FlxTimer().start(0.2, function(tmr:FlxTimer) {
            canDo = true;
        });

        Mods.currentModDirectory = song.folder;
        PlayState.storyWeek = song.week;
        switch (song.songName)
        {
            case 'Small Argument' | 'Beat Battle 2' | 'GeoStar' | 'Zeventeen' | 'Tag And Seek' | 'Rawr' | 'Funky Fanta':
                Difficulty.list = ['Hard'];
            case 'Rise' | 'Test Field' | 'Pack A Punch' | 'Driller':
                Difficulty.list = ['Normal'];
            case "Beat Battle":
                Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
            case "Testimony":
				Difficulty.list = ["4K", "Canon"];
            default:
                Difficulty.loadFromWeek();
        }
        listLength = Difficulty.list.length;
        WeekData.setDirectoryFromWeek();
        changeDiff();
    }

    public function setDifficultyStars(?difficulty:Int):Void
	{
		if (difficulty == null) return;
		difficultyStars.setNumber(difficulty);
        showStars();
	}

	/**
	 * Make the album stars visible.
	 */
	public function showStars():Void
	{
		difficultyStars.visible = true; // true;
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
                LoadingState.loadAndSwitchState(archipelago.APEntryState.inArchipelagoMode ? new archipelago.APPlayState().funcAndReturn(function(ps:archipelago.APPlayState) {
					@:privateAccess
                    {
                    archipelago.APPlayState.currentSong = OsuFreeplayState.instance.fpManager.songList[OsuFreeplayState.curSelected].songName;
					archipelago.APPlayState.currentMod = OsuFreeplayState.instance.fpManager.songList[OsuFreeplayState.curSelected].folder;
                    }
				}) : new states.PlayState());
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

        // I really don't wanna talk about it
        try {
            var ratingValue:Dynamic = OsuFreeplayState.instance.fpManager.metadata.get(song.songName.toLowerCase()).freeplay.ratings;
            var actualRating:Map<String, Int> = new Map<String, Int>();

            for (item in Reflect.fields(ratingValue)) {
                if (item == 'normal' || item == 'easy' || item == 'hard') {
                    actualRating.set(item, Reflect.field(ratingValue, item));
                } else {
                    actualRating.set(item.toLowerCase(), Reflect.field(ratingValue, item));
                }
            }

            var curDiff:String = Difficulty.list[difficulty].toLowerCase();
            setDifficultyStars(actualRating.get(curDiff));
        } catch(e) {
            difficultyStars.visible = false;
            trace("No Metadata Found!");
        }
    }

    function setDifficultyText(?diff:String) {
        if (diffTextnecausetherewasnoimage != null) {
            diffTextnecausetherewasnoimage.text = diff.toUpperCase();
            diffTextnecausetherewasnoimage.screenCenter();
            diffTextnecausetherewasnoimage.y += 2;
            diffTextnecausetherewasnoimage.visible = true;
        }
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

        if (!Paths.exists(Paths.file('images/menudifficulties/${diff}.png'))) {
            sprite.visible = false;
            setDifficultyText(diff);
        } else if (diffTextnecausetherewasnoimage != null) diffTextnecausetherewasnoimage.visible = false;
        sprite.updateHitbox();
        sprite.screenCenter();
        add(sprite);
    }
}
