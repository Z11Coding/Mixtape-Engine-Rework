package states;

import archipelago.HighQualityTrapManager;
import backend.ClientPrefs;
import backend.Difficulty;
import backend.Mods;
import backend.MusicBeatState;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import objects.Alphabet;
import objects.HealthIcon;
import states.LoadingState;
import states.MainMenuState;
import states.PlayState;

/**
 * High Quality Trap Test State
 * A testing interface for SiivaGunner High Quality Trap content
 * Based on SongSelectorDebugState design
 */
class HighQualityTrapTestState extends MusicBeatState
{
    var songs:Array<TrapSongData> = [];
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

        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Testing the SilvaTrap", null);
		#end

        trace("HighQualityTrapTestState: Starting creation...");

        // Check if we're in testing mode
        if (!MusicBeatState.isTrapTestingMode()) {
            trace("HighQualityTrapTestState: Not in testing mode, returning to main menu");
            FlxG.switchState(new MainMenuState());
            return;
        }

        // Create background
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFF2B1B69; // Purple tint for trap testing
        add(bg);

        // Add title text
        titleText = new FlxText(0, 20, FlxG.width, "High Quality Trap - Testing Mode", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(titleText);

        grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

        // Create help text
        helpText = new FlxText(0, FlxG.height - 120, FlxG.width,
            "UP/DOWN - Select Song | LEFT/RIGHT - Change Difficulty\nENTER - Play Song | SPACE - Preview Audio | R - Refresh | ESC - Exit Testing", 16);
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

        loadTrapSongs();
        changeSelection(0);

        trace("HighQualityTrapTestState: Creation complete");
    }

    function loadTrapSongs()
    {
        trace("HighQualityTrapTestState: Loading trap songs...");

        songs = [];

        // Check if trap is active
        if (!HighQualityTrapManager.isTrapActive()) {
            trace("HighQualityTrapTestState: Trap is not active");
            return;
        }

        // Get all available SiivaGunner replacements
        var replacements = HighQualityTrapManager.getAllReplacements();
        if (replacements == null) {
            trace("HighQualityTrapTestState: No replacements found");
            return;
        }

        var addedSongs:Map<String, Bool> = new Map();

        for (key in replacements.keys()) {
            var replacement = replacements.get(key);
            var uniqueKey = replacement.modName + ":" + replacement.replacementSong;

            if (!addedSongs.exists(uniqueKey)) {
                // Get difficulties from the week this song belongs to
                var difficulties:Array<String> = ['normal']; // Default fallback
                if (replacement.weekName != null) {
                    difficulties = HighQualityTrapManager.getWeekDifficulties(replacement.weekName, replacement.modName);
                }

                var trapSong:TrapSongData = {
                    name: replacement.replacementSong,
                    originalName: replacement.originalSong,
                    folder: replacement.modName,
                    character: 'bf', // Default character for trap content
                    color: [182, 105, 255], // Purple color for trap content
                    availableDifficulties: difficulties.copy()
                };

                songs.push(trapSong);
                addedSongs.set(uniqueKey, true);
                trace('HighQualityTrapTestState: Added trap song "${replacement.replacementSong}" (original: "${replacement.originalSong}") from mod "${replacement.modName}" week "${replacement.weekName}" with difficulties: ${trapSong.availableDifficulties.join(", ")}');
            }
        }

        // Sort by name
        songs.sort(function(a, b) {
            return Reflect.compare(a.name, b.name);
        });

        trace('HighQualityTrapTestState: Loaded ${songs.length} trap songs');

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
            var noSongsText:Alphabet = new Alphabet(90, 320, "No trap content found!", true);
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

        // Check if we're still in testing mode
        if (!MusicBeatState.isTrapTestingMode()) {
            FlxG.switchState(new MainMenuState());
            return;
        }

        if (songs.length == 0) {
            if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
                exitTestingMode();
            }
            if (FlxG.keys.justPressed.R) {
                loadTrapSongs();
                changeSelection(0);
            }
            return;
        }

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
                if (songData.folder != null && songData.folder != HighQualityTrapManager.BASE_GAME_MARKER) {
                    Mods.currentModDirectory = songData.folder;
                } else {
                    Mods.currentModDirectory = '';
                }

                var songName = Paths.formatToSongPath(songData.name);

                trace('HighQualityTrapTestState: Previewing trap song: ${songName}');

                try {
                    PlayfieldManager.SONG = Song.loadFromJson(songName, songName);

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
                            trace('HighQualityTrapTestState: Playing vocals for: ${PlayfieldManager.SONG.song}');
                        } catch(e:Dynamic) {
                            trace('HighQualityTrapTestState: No vocals found for ' + PlayfieldManager.SONG.song);
                        }

                        instPlaying = curSelected;
                        trace('HighQualityTrapTestState: Now playing preview: ${PlayfieldManager.SONG.song}');
                    } else {
                        trace('HighQualityTrapTestState: Failed to load song for preview');
                    }
                } catch(e:Dynamic) {
                    trace('HighQualityTrapTestState: Error loading song for preview: $e');
                }
            }
            else
            {
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                    FlxG.sound.music.stop();
                destroyFreeplayVocals();
                instPlaying = -1;
                trace('HighQualityTrapTestState: Stopped music preview');
            }
        }

        if (accepted)
        {
            playSong();
        }

        if (FlxG.keys.justPressed.R)
        {
            loadTrapSongs();
            changeSelection(0);
        }

        if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
        {
            exitTestingMode();
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
        if (songs[curSelected].folder != null && songs[curSelected].folder != HighQualityTrapManager.BASE_GAME_MARKER)
            Mods.currentModDirectory = songs[curSelected].folder;
        else
            Mods.currentModDirectory = '';

        // Use default difficulty list for trap content
        Difficulty.resetList();

        // Clamp difficulty
        if (curDifficulty >= Difficulty.list.length)
            curDifficulty = 0;
    }

    function updateTexts()
    {
        if (songs.length == 0)
        {
            scoreText.text = "No trap content available\nTry refreshing with R key";
            diffText.text = "";
            return;
        }

        var songData = songs[curSelected];

        scoreText.text = 'Trap Song: ${songData.name}';
        scoreText.text += '\nOriginal: ${songData.originalName}';

        // Show mod information
        if (songData.folder != null && songData.folder != HighQualityTrapManager.BASE_GAME_MARKER) {
            scoreText.text += '\nMod: ${songData.folder}';
        } else {
            scoreText.text += '\nMod: Base Game';
        }

        scoreText.text += '\nTotal Traps: ${songs.length}';

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

        trace('HighQualityTrapTestState: Playing trap song: ${songData.name} (original: ${songData.originalName}) from folder: ${songData.folder}');

        // Stop any currently playing music
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
            FlxG.sound.music.stop();
        destroyFreeplayVocals();

        // Set up mod directory properly
        WeekData.setDirectoryFromWeek();
        if (songData.folder != null && songData.folder != HighQualityTrapManager.BASE_GAME_MARKER) {
            Mods.currentModDirectory = songData.folder;
            trace('HighQualityTrapTestState: Set mod directory to: ${songData.folder}');
        } else {
            Mods.currentModDirectory = '';
            trace('HighQualityTrapTestState: Using base game directory');
        }

        // Load song
        var songLowercase:String = Paths.formatToSongPath(songData.name);

        trace('HighQualityTrapTestState: Loading song: ${songLowercase}');
        trace('HighQualityTrapTestState: Difficulty: ${curDifficulty}');

        try {
            // Load the song JSON - variants will be handled automatically by Song.loadFromJson
            PlayfieldManager.SONG = Song.loadFromJson(songLowercase, songLowercase);

            if (PlayfieldManager.SONG != null) {
                // Set up PlayState variables
                PlayState.isStoryMode = false;
                PlayState.storyDifficulty = curDifficulty;
                PlayState.storyWeek = 0;
                PlayState.campaignScore = 0;
                PlayState.campaignMisses = 0;
                PlayState.seenCutscene = false;
                PlayState.deathCounter = 0;

                trace('HighQualityTrapTestState: Trap song loaded successfully: ${PlayfieldManager.SONG.song}');
                trace('HighQualityTrapTestState: BPM: ${PlayfieldManager.SONG.bpm}');

                // Prepare and switch to PlayState
                LoadingState.prepareToSong();
                FlxG.switchState(new PlayState());
            } else {
                trace('HighQualityTrapTestState: PlayfieldManager.SONG is null after loading');
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
        } catch(e:Dynamic) {
            trace('HighQualityTrapTestState: Error loading song: $e');
            trace('HighQualityTrapTestState: Stack trace: ${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
            FlxG.sound.play(Paths.sound('cancelMenu'));
        }
    }

    function exitTestingMode()
    {
        trace("HighQualityTrapTestState: Exiting testing mode");

        // Stop any playing music
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
            FlxG.sound.music.stop();
        destroyFreeplayVocals();

        // Use the command system to properly exit
        if (Main.CommandPrompt.instance != null) {
            @:privateAccess Main.CommandPrompt.instance.executeCommand("testTrap exit");
        } else {
            // Fallback if command system isn't available
            HighQualityTrapManager.deactivateTrap();
            MusicBeatState.exitTrapTestingMode();
            FlxG.switchState(new MainMenuState());
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

typedef TrapSongData = {
    var name:String;
    var originalName:String;
    var folder:String;
    var character:String;
    var color:Array<Int>;
    var availableDifficulties:Array<String>;
}
