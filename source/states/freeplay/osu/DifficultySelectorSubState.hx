package states.freeplay.osu;

import archipelago.APEntryState;
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

    // For unknown songs trap - store original difficulties
    var originalDifficultyList:Array<String> = [];
    var actualSelectedDifficulty:Int = 0;
    public function new(song:Dynamic)
    {
        super();

        setSubStateScript();

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

        // If unknownSongs is active, replace difficulty list with just "Unknown"
        if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
            // Store original difficulties for later random selection
            originalDifficultyList = Difficulty.list.copy();
            Difficulty.list = ['Unknown'];
        } else {
            // Normal difficulty loading
            switch (song.songName)
            {
                case 'Small Argument' | 'Beat Battle 2' | 'GeoStar' | 'Zeventeen' | 'Tag And Seek' | 'Rawr' | 'Funky Fanta' | 'Fightback' | 'Fangirl Frenzy' | 'Slowdown' | 'Pack-A-Punch':
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
            {
                // Block difficulty navigation if unknown songs is active
                if (!(APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs)) {
                    changeDiff(controls.UI_LEFT_P? -1 : 1);
                }
            }
            if(controls.BACK)
                close();
            if(controls.ACCEPT)
            {
                var actualDifficulty:Int = difficulty;

                // If unknownSongs is active, randomly select an actual difficulty
                if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs && originalDifficultyList.length > 0) {
                    var availableDifficulties:Array<Int> = [];
                    var songLowercase:String = Paths.formatToSongPath(song.songName);

                    // Try each original difficulty to see which ones are valid
                    for (i in 0...originalDifficultyList.length) {
                        try {
                            var testPoop:String = Highscore.formatSong(songLowercase, i);
                            // Test if the chart exists by trying to load it
                            var testSong = Song.loadFromJson(testPoop, songLowercase);
                            if (testSong != null) {
                                availableDifficulties.push(i);
                            }
                        } catch (e:Dynamic) {
                            // This difficulty doesn't exist, skip it
                            continue;
                        }
                    }

                    if (availableDifficulties.length > 0) {
                        // Randomly pick from available difficulties
                        actualDifficulty = availableDifficulties[FlxG.random.int(0, availableDifficulties.length - 1)];
                        trace('Unknown Songs (Osu): Randomly selected difficulty ${originalDifficultyList[actualDifficulty]} (index $actualDifficulty)');

                        // Temporarily restore original difficulty list for song loading
                        Difficulty.list = originalDifficultyList.copy();
                    } else {
                        // If no difficulties are available, show a generic error
                        missingText.text = 'ERROR:\nUnable to load song data.';
                        missingText.screenCenter(Y);
                        missingText.visible = true;
                        missingTextBG.visible = true;
                        FlxG.sound.play(Paths.sound('cancelMenu'));
                        super.update(elapsed);
                        return;
                    }
                }

                try
                {
                    persistentUpdate = false;
                    var songLowercase:String = Paths.formatToSongPath(song.songName);
    				var poop:String = Highscore.formatSong(songLowercase, actualDifficulty);
                    Mods.currentModDirectory = song.folder;
                    Song.loadFromJson(poop, songLowercase);
                    PlayState.isStoryMode = false;
                    PlayState.storyDifficulty = actualDifficulty;
                    trace('CURRENT WEEK: ' + WeekData.getWeekFileName());

                    // Check if required characters and stage are unlocked via sanity system
                    if (APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
                        var missingItems = archipelago.APEntryState.apGame.checkSongCharactersAndStageUnlocked(PlayState.SONG);
                        if (missingItems.length > 0) {
                            trace('Song requires unlocked sanity items: ' + missingItems.join(", "));

                            var itemList = "";
                            for (i in 0...missingItems.length) {
                                itemList += "• " + missingItems[i];
                                if (i < missingItems.length - 1) itemList += "\n";
                            }

                            missingText.text = 'This song requires unlocked characters or stages:\n\n' + itemList + '\n\nPlay other songs to unlock these items!';
                            missingText.screenCenter(Y);
                            missingText.visible = true;
                            missingTextBG.visible = true;
                            FlxG.sound.play(Paths.sound('cancelMenu'));

                            super.update(elapsed);
                            return;
                        }
                    }
                }
                catch(e:Dynamic)
                {
                    trace('ERROR! $e');

                    var errorStr:String;
                    // If unknownSongs is active, show anonymous error message
                    if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
                        errorStr = 'Unable to load song data.';
                    } else {
                        errorStr = e.toString();
                        if(errorStr.startsWith('[file_contents,assets/shared/songs/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
                    }

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

        // Hide difficulty info when unknownSongs is active
        if (APEntryState.inArchipelagoMode && archipelago.APItem.unknownSongs) {
            difficultyStars.visible = false;
            return;
        }

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

        if (!Paths.exists(Paths.file('images/menudifficulties/${diff}.png')) || archipelago.APItem.unknownSongs) {
            sprite.visible = false;
            setDifficultyText(diff);
        } else if (diffTextnecausetherewasnoimage != null) diffTextnecausetherewasnoimage.visible = false;
        sprite.updateHitbox();
        sprite.screenCenter();
        add(sprite);
    }
}
