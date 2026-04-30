package debug;

/**
 * Song Selector Debug State
 *
 * A debug menu that allows you to:
 * - Browse ALL available songs from all categories and mods
 * - Preview songs by pressing SPACE (plays instrumental + vocals)
 * - Play songs directly by pressing ENTER
 * - Change difficulties with LEFT/RIGHT arrows
 * - See detailed song information including mod folder, week, character
 *
 * Fixed issues:
 * - Now properly loads songs from "all" category using FreeplayManager
 * - Song playing functionality works correctly with proper mod directory handling
 * - Better information display with mod status and song counts
 * - Improved error handling and debugging output
 */

import backend.ClientPrefs;
import backend.Difficulty;
import backend.Highscore;
import backend.Mods;
import backend.MusicBeatState;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import managers.FreeplayManager;
import objects.Alphabet;
import objects.HealthIcon;
import states.CategoryState;
import states.LoadingState;
import states.PlayState;

class SongSelectorDebugState extends MusicBeatState
{
    var songs:Array<SongDebugData> = [];
    var curSelected:Int = 0;
    var curDifficulty:Int = 0;

    var grpSongs:FlxTypedGroup<Alphabet>;
    var iconArray:Array<HealthIcon> = [];
    var bg:FlxSprite;
    var scoreBG:FlxSprite;
    var scoreText:FlxText;
    var diffText:FlxText;
    var helpText:FlxText;
    var titleText:FlxText;

    var instPlaying:Int = -1;
    var vocals:FlxSound;

    override function create()
    {
        super.create();

        // Create background
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFF292929;
        add(bg);

        // Add title text
        titleText = new FlxText(0, 20, FlxG.width, "Song Selector Debug Menu", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(titleText);

        grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

        // Create help text
        helpText = new FlxText(0, FlxG.height - 120, FlxG.width,
            "UP/DOWN - Select Song | LEFT/RIGHT - Change Difficulty\nENTER - Play Song | SPACE - Preview Audio | ESC - Back", 16);
        helpText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(helpText);

        // Score background
        scoreBG = new FlxSprite(FlxG.width * 0.7, 100).makeGraphic(1, 1, FlxColor.BLACK);
        scoreBG.alpha = 0.6;
        add(scoreBG);

        scoreText = new FlxText(scoreBG.x + 20, scoreBG.y + 20, 0, "", 32);
        scoreText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE);
        add(scoreText);

        diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        diffText.font = scoreText.font;
        add(diffText);

        loadSongList();
        changeSelection(0);
    }

    function loadSongList()
    {
        // Set up category to get all songs
        CategoryState.loadWeekForce = "all";

        // First load week data to ensure everything is available
        WeekData.reloadWeekFiles(false);

        var fpManager = FreeplayManager.loadFPManager(true);
        fpManager.reloadFreeplay(true, ''); // Use refresh=true to get all songs

        if (fpManager != null && fpManager.songList != null)
        {
            for (songData in fpManager.songList)
            {
                if (songData == null) continue;

                var debugData:SongDebugData = {
                    name: songData.songName,
                    folder: songData.folder,
                    week: songData.week,
                    character: songData.songCharacter,
                    color: songData.color != null && songData.color.length > 0 ?
                        [Std.int(songData.color[0][0]), Std.int(songData.color[0][1]), Std.int(songData.color[0][2])] :
                        [146, 113, 253]
                };

                songs.push(debugData);
            }
        }

        trace('Loaded ${songs.length} songs from FreeplayManager');

        // Create alphabet items
        for (i in 0...songs.length)
        {
            var songText:Alphabet = new Alphabet(90, 320, songs[i].name, true);
            songText.isMenuItem = true;
            songText.targetY = i;
            grpSongs.add(songText);

            var icon:HealthIcon = new HealthIcon(songs[i].character);
            icon.sprTracker = songText;
            iconArray.push(icon);
            add(icon);
        }

        if (songs.length == 0)
        {
            // Add "No songs found" message
            var noSongsText:Alphabet = new Alphabet(90, 320, "No songs found!", true);
            noSongsText.isMenuItem = true;
            noSongsText.targetY = 0;
            grpSongs.add(noSongsText);

            var icon:HealthIcon = new HealthIcon('face');
            icon.sprTracker = noSongsText;
            iconArray.push(icon);
            add(icon);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (songs.length == 0) return;

        var upP = controls.UI_UP_P;
        var downP = controls.UI_DOWN_P;
        var leftP = controls.UI_LEFT_P;
        var rightP = controls.UI_RIGHT_P;
        var accepted = controls.ACCEPT;
        var space = FlxG.keys.justPressed.SPACE;

        if (upP)
        {
            changeSelection(-1);
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        if (downP)
        {
            changeSelection(1);
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (leftP)
            changeDiff(-1);
        if (rightP)
            changeDiff(1);

        if (space)
        {
            if (instPlaying != curSelected)
            {
                destroyFreeplayVocals();

                var songData = songs[curSelected];

                // Set up mod directory for preview
                WeekData.setDirectoryFromWeek();
                if (songData.folder != null && songData.folder.length > 0) {
                    Mods.currentModDirectory = songData.folder;
                } else {
                    Mods.currentModDirectory = '';
                }

                var songName = Paths.formatToSongPath(songs[curSelected].name);
                var poop:String = Highscore.formatSong(songName, curDifficulty);

                trace('Previewing: ${songName} (${poop})');

                try {
                    PlayfieldManager.SONG = Song.loadFromJson(poop, songName);
                    if (PlayfieldManager.SONG == null) {
                        // Try without difficulty suffix
                        PlayfieldManager.SONG = Song.loadFromJson(songName, songName);
                    }

                    if (PlayfieldManager.SONG != null)
                    {
                        FlxG.sound.music.stop();
                        vocals = new FlxSound();

                        var inst = Paths.inst(PlayfieldManager.SONG.song);
                        FlxG.sound.playMusic(inst, 0.7);
                        FlxG.sound.music.time = 0;

                        try {
                            vocals.loadEmbedded(Paths.voices(PlayfieldManager.SONG.song));
                            FlxG.sound.list.add(vocals);
                            vocals.play();
                            vocals.time = 0;
                            trace('Playing vocals for: ${PlayfieldManager.SONG.song}');
                        } catch(e:Dynamic) {
                            trace('No vocals found for ' + PlayfieldManager.SONG.song);
                        }

                        instPlaying = curSelected;
                        trace('Now playing preview: ${PlayfieldManager.SONG.song}');
                    } else {
                        trace('Failed to load song for preview');
                    }
                } catch(e:Dynamic) {
                    trace('Error loading song for preview: $e');
                }
            }
            else
            {
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                    FlxG.sound.music.stop();
                destroyFreeplayVocals();
                instPlaying = -1;
                trace('Stopped music preview');
            }
        }

        if (accepted)
        {
            playSong();
        }

        if (controls.BACK)
        {
            if (FlxG.sound.music != null && FlxG.sound.music.playing)
                FlxG.sound.music.stop();
            destroyFreeplayVocals();
            FlxG.switchState(new debug.DebugMainMenuState());
        }
    }

    function changeSelection(change:Int = 0)
    {
        if (songs.length == 0) return;

        curSelected += change;

        if (curSelected < 0)
            curSelected = songs.length - 1;
        if (curSelected >= songs.length)
            curSelected = 0;

        // Update alphabet positions
        var bullShit:Int = 0;
        for (item in grpSongs.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;
            if (item.targetY == 0)
                item.alpha = 1;
        }

        // Update icons
        for (i in 0...iconArray.length)
        {
            iconArray[i].alpha = 0.6;
            if (i == curSelected)
                iconArray[i].alpha = 1;
        }

        // Update background color
        if (songs[curSelected] != null && songs[curSelected].color != null)
        {
            var newColor:FlxColor = FlxColor.fromRGB(songs[curSelected].color[0], songs[curSelected].color[1], songs[curSelected].color[2]);
            FlxTween.color(bg, 0.4, bg.color, newColor);
        }

        // Load difficulties for current song
        loadDifficulties();

        updateTexts();
    }

    function changeDiff(change:Int)
    {
        if (songs.length == 0) return;

        curDifficulty += change;

        if (curDifficulty < 0)
            curDifficulty = Difficulty.list.length - 1;
        if (curDifficulty >= Difficulty.list.length)
            curDifficulty = 0;

        updateTexts();
    }

    function loadDifficulties()
    {
        if (songs.length == 0) return;

        // Set mod directory
        WeekData.setDirectoryFromWeek();
        if (songs[curSelected].folder != null && songs[curSelected].folder.length > 0)
            Mods.currentModDirectory = songs[curSelected].folder;

        // Load difficulties
        try {
            var week = WeekData.weeksLoaded.get(WeekData.weeksList[songs[curSelected].week]);
            if (week != null)
                Difficulty.loadFromWeek(week);
            else
                Difficulty.resetList();
        } catch(e:Dynamic) {
            Difficulty.resetList();
        }

        // Clamp difficulty
        if (curDifficulty >= Difficulty.list.length)
            curDifficulty = 0;
    }

    function updateTexts()
    {
        if (songs.length == 0)
        {
            scoreText.text = "No songs available";
            diffText.text = "";
            return;
        }

        var songData = songs[curSelected];

        scoreText.text = 'Song: ${songData.name}';

        // Show mod information more clearly
        if (songData.folder != null && songData.folder.length > 0) {
            scoreText.text += '\nMod: ${songData.folder}';
        } else {
            scoreText.text += '\nMod: Base Game';
        }

        scoreText.text += '\nWeek: ${songData.week + 1}';
        scoreText.text += '\nCharacter: ${songData.character}';
        scoreText.text += '\nTotal Songs: ${songs.length}';

        // Show difficulty information
        if (Difficulty.list.length > 0 && curDifficulty < Difficulty.list.length) {
            diffText.text = 'Difficulty: ${Difficulty.list[curDifficulty].toUpperCase()}';
            diffText.text += ' (${curDifficulty + 1}/${Difficulty.list.length})';
        } else {
            diffText.text = 'Difficulty: NORMAL (1/1)';
        }

        // Update score background size
        var textHeight = scoreText.textField.textHeight + diffText.textField.textHeight + 60;
        var textWidth = Math.max(scoreText.textField.textWidth, diffText.textField.textWidth) + 40;
        scoreBG.setGraphicSize(Std.int(textWidth), Std.int(textHeight));
        scoreBG.updateHitbox();
    }

    function playSong()
    {
        if (songs.length == 0) return;

        var songData = songs[curSelected];

        trace('Playing song: ${songData.name} from folder: ${songData.folder}');

        // Stop any currently playing music
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
            FlxG.sound.music.stop();
        destroyFreeplayVocals();

        // Set up mod directory properly
        WeekData.setDirectoryFromWeek();
        if (songData.folder != null && songData.folder.length > 0) {
            Mods.currentModDirectory = songData.folder;
            trace('Set mod directory to: ${songData.folder}');
        } else {
            Mods.currentModDirectory = '';
            trace('Using base game directory');
        }

        // Load song with proper difficulty formatting
        var songLowercase:String = Paths.formatToSongPath(songData.name);
        var difficultyName:String = Difficulty.list.length > curDifficulty ? Difficulty.list[curDifficulty] : 'normal';
        var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

        trace('Loading song: ${poop} (${songLowercase})');
        trace('Difficulty: ${difficultyName} (index: ${curDifficulty})');

        try {
            // Load the song JSON
            PlayfieldManager.SONG = Song.loadFromJson(poop, songLowercase);

            if (PlayfieldManager.SONG == null) {
                trace('Failed to load song JSON, trying alternative method');
                // Try loading without difficulty suffix
                PlayfieldManager.SONG = Song.loadFromJson(songLowercase, songLowercase);
            }

            if (PlayfieldManager.SONG != null) {
                // Set up PlayState variables
                PlayState.isStoryMode = false;
                PlayState.storyDifficulty = curDifficulty;
                PlayState.storyWeek = songData.week;
                PlayState.campaignScore = 0;
                PlayState.campaignMisses = 0;
                PlayState.seenCutscene = false;
                PlayState.deathCounter = 0;

                trace('Song loaded successfully: ${PlayfieldManager.SONG.song}');
                trace('BPM: ${PlayfieldManager.SONG.bpm}');

                // Prepare and switch to PlayState
                LoadingState.prepareToSong();
                FlxG.switchState(new PlayState());
            } else {
                trace('PlayfieldManager.SONG is null after loading');
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
        } catch(e:Dynamic) {
            trace('Error loading song: $e');
            trace('Stack trace: ${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
            FlxG.sound.play(Paths.sound('cancelMenu'));
        }
    }

    function destroyFreeplayVocals()
    {
        if (vocals != null)
        {
            vocals.stop();
            vocals.destroy();
            vocals = null;
        }
    }

    override function destroy()
    {
        destroyFreeplayVocals();
        super.destroy();
    }
}

typedef SongDebugData = {
    var name:String;
    var folder:String;
    var week:Int;
    var character:String;
    var color:Array<Int>;
}
