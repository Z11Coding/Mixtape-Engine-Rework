package states.freeplay;

import backend.ClientPrefs;
import backend.Difficulty;
import backend.MusicBeatState;
import backend.Paths;
import backend.WeekData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import managers.FreeplayManager.GlobalSongMetadata;
import states.freeplay.vslice.capsule.SongMenuItem;
import states.freeplay.vslice.obj.AlbumRoll;
import states.freeplay.vslice.obj.BackingCard;
import states.freeplay.vslice.obj.FreeplayDJ;
import states.freeplay.vslice.obj.LetterSort;
import states.freeplay.vslice.obj.SngCapsuleData.FreeplaySongData;
import states.freeplay.vslice.obj.SngCapsuleData.FreeplayStyle;

using StringTools;
#if ARCHIPELAGO_ALLOWED
import archipelago.APEntryState;
import archipelago.APPlayState;
#end


/**
 * V-Slice style FreeplayState properly ported from P-Slice project
 * This is a complete rewrite to match the actual P-Slice architecture
 */
class VSliceFreeplayState extends MusicBeatState
{
    public static var instance:VSliceFreeplayState;

    // FreeplayManager instance - initialize once and reuse
    var fpManager:managers.FreeplayManager = managers.FreeplayManager.loadFPManager(true);

    // Core P-Slice V-Slice components
    var grpCapsules:FlxTypedGroup<states.freeplay.vslice.capsule.SongMenuItem>;
    var albumRoll:AlbumRoll;
    var dj:FreeplayDJ;
    var backingCard:BackingCard;
    var letterSort:LetterSort;

    // Core variables from P-Slice V-Slice
    var songs:Array<FreeplaySongData> = []; // Contains V-Slice song data
    var curSelected:Int = 0;
    var curSelectedFractal:Float = 0;
    var currentDifficulty:String = "normal";
    var diffIdsCurrent:Array<String> = [];
    var diffIdsTotal:Array<String> = ["easy", "normal", "hard"];

    // Camera system (P-Slice style)
    var funnyCam:FlxCamera;
    var rankCamera:FlxCamera;

    // UI Elements
    var bg:FlxSprite;
    var rankBg:FlxSprite;
    var ostName:FlxText;
    var charSelectHint:FlxText;

    // Audio constants from P-Slice
    public static final FADE_IN_DURATION:Float = 2;
    public static final FADE_IN_START_VOLUME:Float = 0;
    public static final FADE_IN_END_VOLUME:Float = 0.7;
    public static final FADE_IN_DELAY:Float = 0.25;
    public static final FADE_OUT_DURATION:Float = 0.25;
    public static final FADE_OUT_END_VOLUME:Float = 0.0;

    // Character system
    var currentCharacterId:String = "bf";

    // State control
    public var busy:Bool = false;

    // Archipelago integration
    #if ARCHIPELAGO_ALLOWED
    var apMode:Bool = false;
    #end

    override function create()
    {
        instance = this;

        #if ARCHIPELAGO_ALLOWED
        apMode = APEntryState.inArchipelagoMode;
        #end

        // Setup cameras like P-Slice
        setupCameras();

        // Initialize core components
        initializeComponents();

        // Load songs from FreeplayManager
        loadSongs();

        super.create();

        // Block input initially like P-Slice
        busy = true;

        // Start intro
        startIntro();
    }

    function setupCameras():Void
    {
        // Create cameras like P-Slice
        rankCamera = new FlxCamera();
        rankCamera.setSize(FlxG.width, FlxG.height);

        funnyCam = new FlxCamera();
        funnyCam.setSize(FlxG.width, FlxG.height);

        FlxG.cameras.add(rankCamera, false);
        FlxG.cameras.add(funnyCam, false);

        funnyCam.bgColor = FlxColor.TRANSPARENT;
        rankCamera.bgColor = FlxColor.TRANSPARENT;
    }

    function initializeComponents():Void
    {
        // Background setup
        bg = new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayBGdad', 'vslice'));
        if (bg.graphic == null) {
            bg.loadGraphic(Paths.image('menuDesat'));
        }
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

        // Rank background (P-Slice style)
        rankBg = new FlxSprite(0, 0);
        rankBg.makeGraphic(FlxG.width, FlxG.height, 0xD3000000);
        rankBg.alpha = 0;
        add(rankBg);

        // Backing card (behind everything else)
        backingCard = new BackingCard(200, 100, currentCharacterId);
        backingCard.animateIn();
        add(backingCard);

        // Song capsules group
        grpCapsules = new FlxTypedGroup<SongMenuItem>();
        add(grpCapsules);

        // Album roll
        albumRoll = new AlbumRoll(FlxG.width - 150, 50);
        albumRoll.setAlbum("default");
        add(albumRoll);

        // DJ character
        dj = new FreeplayDJ(50, FlxG.height - 200, currentCharacterId);
        add(dj);

        // Letter sorting system
        letterSort = new LetterSort(FlxG.width - 200, 150);
        letterSort.reset(); // Start with "ALL" selected
        add(letterSort);

        // Text elements
        ostName = new FlxText(8, 8, FlxG.width - 16, "MIXTAPE ENGINE", 48);
        ostName.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, RIGHT);
        add(ostName);

        charSelectHint = new FlxText(0, 18, FlxG.width, "Press [SPACE] to change characters | [TAB] to filter by letter | [R] to reset filter", 24);
        charSelectHint.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.fromRGB(95, 95, 95), CENTER);
        add(charSelectHint);
    }

    function loadSongs():Void
    {
        // Clear existing songs
        songs = [];

        // Load from FreeplayManager and convert to V-Slice format
        var allSongs:Array<GlobalSongMetadata> = fpManager?.songList;
        for (songData in allSongs) {
            // Use song character from metadata for proper icons
            var characterForSong = songData.songCharacter != null && songData.songCharacter.length > 0 ? songData.songCharacter : 'bf';
            var vSliceSong = new FreeplaySongData(songData.songName, Paths.formatToSongPath(songData.songName), characterForSong);
            vSliceSong.artist = songData.artist;
            vSliceSong.charter = songData.charter;

            // Convert color array to hex string
            var colorHex:String = "#9271FD"; // Default color
            try {
                if (songData.color != null && songData.color.length > 0) {
                    var firstColor = songData.color[0];
                    if (firstColor != null && firstColor.length >= 3) {
                        var r = Std.int(firstColor[0]);
                        var g = Std.int(firstColor[1]);
                        var b = Std.int(firstColor[2]);
                        colorHex = '#${StringTools.hex(r, 2)}${StringTools.hex(g, 2)}${StringTools.hex(b, 2)}';
                    }
                }
            } catch (e:Dynamic) {
                // Use default color if conversion fails
                trace('Error converting color for song ${songData.songName}: $e');
            }
            vSliceSong.color = colorHex;

            // Convert week int to string
            vSliceSong.week = Std.string(songData.week);
            vSliceSong.folder = songData.folder;

            // Try to get BPM from song data or use default
            try {
                var songPath = Paths.formatToSongPath(songData.songName);
                var songJson = backend.Song.loadFromJson(songPath, songPath);
                if (songJson != null && songJson.bpm > 0) {
                    vSliceSong.songStartingBpm = songJson.bpm;
                } else {
                    vSliceSong.songStartingBpm = 102; // Default BPM
                }
            } catch (e:Dynamic) {
                vSliceSong.songStartingBpm = 102; // Default BPM
            }

            vSliceSong.difficultyRating = FlxG.random.int(1, 10); // Random rating for now
            vSliceSong.isNew = false; // TODO: Implement new song detection based on ClientPrefs
            vSliceSong.isFav = false; // TODO: Load from ClientPrefs favorites

            // Convert week int to week name
            vSliceSong.songWeekName = WeekData.weeksList.length > songData.week ? WeekData.weeksList[songData.week] : "Week " + songData.week;

            // Store original metadata for easy access
            vSliceSong.originalMetadata = songData;

            songs.push(vSliceSong);
        }

        // Create visual capsules
        createSongCapsules();
    }

    function createSongCapsules():Void
    {
        // Clear existing capsules
        grpCapsules.clear();

        // Initialize global shader data for SongMenuItem
        SongMenuItem.reloadGlobalItemData();

        // Create default freeplay style
        var defaultStyle = new FreeplayStyle("default", "freeplay/freeplayCapsule/freeplayCapsule");

        // Add random option first
        var randomCapsule = new SongMenuItem(300, 120, defaultStyle);
        randomCapsule.applySongData(null); // null means "Random Song"
        randomCapsule.targetPos.x = 300;
        randomCapsule.targetPos.y = 120;
        randomCapsule.ID = 0;
        grpCapsules.add(randomCapsule);

        // Add regular songs
        for (i in 0...songs.length) {
            var capsule = new SongMenuItem(300, 120 + ((i + 1) * 90), defaultStyle);
            capsule.applySongData(songs[i]);
            capsule.targetPos.x = 300;
            capsule.targetPos.y = 120 + ((i + 1) * 90);
            capsule.ID = i + 1;
            grpCapsules.add(capsule);
        }

        updateSelection();
    }

    function startIntro():Void
    {
        // P-Slice style intro animation using SongMenuItem's animation system
        for (i in 0...grpCapsules.members.length) {
            var capsule = grpCapsules.members[i];
            if (capsule != null) {
                // Set up P-Slice style jump-in animation
                capsule.setCapsuleAnimation(states.freeplay.vslice.capsule.SongMenuItem.SongCapsuleAnim.JUMPIN);

                // Enable input after animation completes
                if (i == grpCapsules.members.length - 1) {
                    FlxTimer.wait(1.0, function() {
                        busy = false;
                    });
                }
            }
        }

        // Animate other V-Slice elements
        albumRoll.x += 300;
        FlxTween.tween(albumRoll, {x: albumRoll.x - 300}, 0.8, {ease: FlxEase.quartOut});

        dj.playIntro();
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (busy) return;

        handleInput();
        updateVisuals(elapsed);
    }

    function handleInput():Void
    {
        if (controls.UI_UP_P) {
            changeSelection(-1);
        }

        if (controls.UI_DOWN_P) {
            changeSelection(1);
        }

        if (controls.ACCEPT) {
            selectSong();
        }

        if (controls.BACK) {
            exitFreeplay();
        }

        if (controls.UI_LEFT_P) {
            changeDifficulty(-1);
        }

        if (controls.UI_RIGHT_P) {
            changeDifficulty(1);
        }

        // Letter sorting controls (Tab/Shift+Tab or additional keys)
        if (FlxG.keys.justPressed.TAB) {
            if (FlxG.keys.pressed.SHIFT) {
                letterSort.prevLetter();
            } else {
                letterSort.nextLetter();
            }
            applyLetterFilter();
        }

        // Reset letter filter with R key
        if (FlxG.keys.justPressed.R) {
            letterSort.reset();
            applyLetterFilter();
        }

        // Character selection with SPACE key
        if (FlxG.keys.justPressed.SPACE) {
            changeCharacter();
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        curSelected += change;

        var totalItems = songs.length + 1; // +1 for random option

        if (curSelected < 0)
            curSelected = totalItems - 1;
        if (curSelected >= totalItems)
            curSelected = 0;

        updateSelection();
        playCurSongPreview();
    }

    function updateSelection():Void
    {
        // Update capsule selection state
        for (i in 0...grpCapsules.members.length) {
            var capsule = grpCapsules.members[i];
            if (capsule != null) {
                capsule.selected = (i == curSelected);
            }
        }

        // Update other UI elements based on selection
        updateInfoDisplay();
    }

    function updateInfoDisplay():Void
    {
        if (curSelected == 0) {
            ostName.text = "RANDOM SONG";
            albumRoll.setAlbum("random");
        } else if (curSelected > 0 && curSelected <= songs.length) {
            var song = songs[curSelected - 1]; // Account for random option at index 0
            ostName.text = song.songName.toUpperCase();

            // Update album art based on song character or week
            var albumId = song.songCharacter != null ? song.songCharacter : "default";
            albumRoll.setAlbum(albumId);

            // Update backing card if character changed
            if (song.songCharacter != null && song.songCharacter != backingCard.characterId) {
                backingCard.changeCard(song.songCharacter);
            }

            // Update DJ character if needed (optional - could be character selection system)
            // dj.changeCharacter(song.songCharacter);
        }
    }

    function changeDifficulty(change:Int = 0):Void
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        var diffIndex = diffIdsTotal.indexOf(currentDifficulty);
        diffIndex += change;

        if (diffIndex < 0)
            diffIndex = diffIdsTotal.length - 1;
        if (diffIndex >= diffIdsTotal.length)
            diffIndex = 0;

        currentDifficulty = diffIdsTotal[diffIndex];

        // Update difficulty display
        // TODO: Add difficulty sprites
    }

    public function playCurSongPreview():Void
    {
        if (curSelected == 0) {
            // Random song - play default music
            FlxG.sound.playMusic(Paths.music('freeplayRandom'), 0);
            if (FlxG.sound.music != null) {
                FlxG.sound.music.fadeIn(FADE_IN_DURATION, FADE_IN_START_VOLUME, FADE_IN_END_VOLUME);
            }
            return;
        }

        var songIndex = curSelected - 1; // Account for random option at index 0
        if (songIndex < 0 || songIndex >= songs.length) return;

        var song = songs[songIndex];

        // Stop current music and fade out
        if (FlxG.sound.music != null) {
            FlxG.sound.music.fadeOut(FADE_OUT_DURATION, FADE_OUT_END_VOLUME);
        }

        // Load and play song preview
        FlxTimer.wait(FADE_IN_DELAY, function() {
            try {
                var songName = Paths.formatToSongPath(song.songName);
                FlxG.sound.playMusic(Paths.inst(songName), 0);
                if (FlxG.sound.music != null) {
                    FlxG.sound.music.fadeIn(FADE_IN_DURATION, FADE_IN_START_VOLUME, FADE_IN_END_VOLUME);
                }
            } catch (e:Dynamic) {
                // Fallback to default music
                FlxG.sound.playMusic(Paths.music('freeplayRandom'), 0);
                if (FlxG.sound.music != null) {
                    FlxG.sound.music.fadeIn(FADE_IN_DURATION, FADE_IN_START_VOLUME, FADE_IN_END_VOLUME);
                }
            }
        });
    }

    function selectSong():Void
    {
        if (busy) return;

        FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);

        busy = true;

        if (curSelected == 0) {
            // Random song selection
            selectRandomSong();
            return;
        }

        var songIndex = curSelected - 1; // Account for random option at index 0
        if (songIndex < 0 || songIndex >= songs.length) return;

        var song = songs[songIndex];

        // Prepare for PlayState
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = Difficulty.list.indexOf(currentDifficulty);
        if (PlayState.storyDifficulty < 0) PlayState.storyDifficulty = 1;

        var songLowercase:String = Paths.formatToSongPath(song.songName);
        var poop:String = backend.Highscore.formatSong(songLowercase, PlayState.storyDifficulty);

        PlayState.SONG = backend.Song.loadFromJson(poop, songLowercase);
        // Convert week string to index or use 0 as default
        PlayState.storyWeek = WeekData.weeksList.indexOf(song.week);
        if (PlayState.storyWeek < 0) PlayState.storyWeek = 0;

        // Stop music
        if (FlxG.sound.music != null) {
            FlxG.sound.music.volume = 0;
        }

        fpManager.destroyFreeplayVocals();

        // Transition to play state
        #if ARCHIPELAGO_ALLOWED
        if (apMode) {
            states.LoadingState.loadAndSwitchState(new APPlayState());
        } else {
        #end
            states.LoadingState.loadAndSwitchState(new states.PlayState());
        #if ARCHIPELAGO_ALLOWED
        }
        #end
    }

    function selectRandomSong():Void
    {
        if (songs.length <= 0) return;

        // Select random song (1-based index to account for random option at 0)
        var randomIndex = FlxG.random.int(1, songs.length);
        curSelected = randomIndex;
        updateSelection();

        // Delay and then select
        FlxTimer.wait(0.5, function() {
            selectSong();
        });
    }

    function exitFreeplay():Void
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));

        // Stop music
        if (FlxG.sound.music != null) {
            FlxG.sound.music.fadeOut(0.5, 0);
        }

        fpManager.destroyFreeplayVocals();

        FlxG.switchState(new states.CategoryState());
    }

    function applyLetterFilter():Void
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        // Get all songs from FreeplayManager
        var allSongs:Array<GlobalSongMetadata> = fpManager?.songList;
        if (allSongs == null) return;

        // Convert to FreeplaySongData format (reuse existing logic)
        var tempSongs:Array<FreeplaySongData> = [];
        for (songData in allSongs) {
            var characterForSong = songData.songCharacter != null && songData.songCharacter.length > 0 ? songData.songCharacter : 'bf';
            var vSliceSong = new FreeplaySongData(songData.songName, Paths.formatToSongPath(songData.songName), characterForSong);
            vSliceSong.originalMetadata = songData;
            tempSongs.push(vSliceSong);
        }

        // Apply letter filter
        var filteredSongs:Array<Dynamic> = letterSort.getFilteredSongs(tempSongs);
        songs = cast filteredSongs;

        // Recreate capsules with filtered songs
        createSongCapsules();

        // Reset selection
        curSelected = 0;
        updateSelection();
    }

    function updateVisuals(elapsed:Float):Void
    {
        // Smooth interpolation for selection
        curSelectedFractal = FlxMath.lerp(curSelectedFractal, curSelected, elapsed * 8);

        // Update capsule positions based on selection
        for (i in 0...grpCapsules.members.length) {
            var capsule = grpCapsules.members[i];
            if (capsule != null) {
                // Update target position based on selection
                var targetY = 120 + ((i - curSelectedFractal) * 90);
                capsule.targetPos.y = targetY;

                // Alpha based on distance from selection
                var distance = Math.abs(i - curSelectedFractal);
                var targetAlpha = distance < 3 ? 1.0 : 0.6;
                capsule.alpha = FlxMath.lerp(capsule.alpha, targetAlpha, elapsed * 8);
            }
        }
    }

    function changeCharacter():Void
    {
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);

        // Available characters for cycling
        var availableChars = ["bf", "gf", "pico", "spooky", "monster", "parents", "senpai"];
        var currentIndex = availableChars.indexOf(currentCharacterId);

        if (currentIndex < 0) currentIndex = 0;

        var nextIndex = (currentIndex + 1) % availableChars.length;
        var newCharacter = availableChars[nextIndex];

        // Update current character
        currentCharacterId = newCharacter;

        // Update DJ and backing card
        dj.changeCharacter(newCharacter);
        dj.playCharSelect();
        backingCard.changeCard(newCharacter);

        // Update character hint text
        charSelectHint.text = 'Character: ${newCharacter.toUpperCase()} | [SPACE] to change | [TAB] to filter | [R] to reset';
    }

    /**
     * Reload songs from FreeplayManager - called by FreeplayManager.reloadSongs()
     */
    public function reloadSongs(refresh:Bool = false):Void
    {
        if (!refresh) return;

        // Reload songs from FreeplayManager
        loadSongs();

        // Reset selection to prevent out of bounds
        curSelected = 0;
        updateSelection();

        // Update visuals
        playCurSongPreview();
    }

    override function destroy():Void
    {
        if (fpManager != null) {
            fpManager.destroyFreeplayVocals();
        }

        super.destroy();
        instance = null;
    }
}
