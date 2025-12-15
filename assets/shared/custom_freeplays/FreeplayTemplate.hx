import flixel.text.FlxText;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.Alphabet;

var curSelected = 0;
var curDifficulty = 0;
var songItems = [];
var difficultySprites = [];
var errorText;
var titleText;
var instructionText;
var difficultyText;
var difficultySprite;
var hasTracedSongs = false;
var hasCreatedMenu = false;
var songs = []; // Accessible song list
var songNames = []; // Array of song name strings

function create() {
    trace("[CustomFreeplayState] Script create() called, hasCreatedMenu: " + hasCreatedMenu);

    if (hasCreatedMenu) {
        trace("[CustomFreeplayState] Menu already created, skipping...");
        return;
    }

    hasCreatedMenu = true;

    errorText = new FlxText(0, 0, FlxG.width, "Loaded an invalid freeplay state, or entered through debug menu", 32);
    errorText.alignment = "center";
    errorText.screenCenter();
    state.add(errorText);

    // Show error message for 1 second then create menu
    FlxTween.tween(errorText, {alpha: 0}, 0.5, {
        startDelay: 1.0,
        ease: FlxEase.quadOut,
        onComplete: function(tween) {
            errorText.destroy();
            createMinimalistMenu();
        }
    });
}

function createMinimalistMenu() {
    // Title
    titleText = new FlxText(0, 50, FlxG.width, "FREEPLAY", 48);
    titleText.alignment = "center";
    titleText.alpha = 0;
    state.add(titleText);
    FlxTween.tween(titleText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});

    // Instructions
    instructionText = new FlxText(0, FlxG.height - 80, FlxG.width, "UP/DOWN: Select Song | LEFT/RIGHT: Difficulty | ENTER: Play | ESC: Back", 16);
    instructionText.alignment = "center";
    instructionText.alpha = 0;
    state.add(instructionText);
    FlxTween.tween(instructionText, {alpha: 0.7}, 0.5, {startDelay: 0.2, ease: FlxEase.quadOut});

    // Difficulty display
    difficultyText = new FlxText(0, 110, FlxG.width, "", 24);
    difficultyText.alignment = "center";
    difficultyText.alpha = 0;
    state.add(difficultyText);

    // Load song list
    var allSongs = fpManager.songList;

    // Only trace songs once to avoid spam
    if (!hasTracedSongs) {
        trace("[CustomFreeplayState] Song list loaded with " + allSongs.length + " total songs");

        // Trace each song for debugging
        for (i in 0...allSongs.length) {
            var song = allSongs[i];
            trace("[CustomFreeplayState] Song " + i + ": \\"" + song.songName + "\\" from mod: \\"" + (song.folder != null ? song.folder : "base_game") + "\\"");
        }
        hasTracedSongs = true;
    }

    // Clear previous songs
    songs = [];
    songNames = [];

    // Filter songs based on accessibility
    trace("[CustomFreeplayState] Filtering songs for accessibility...");
    for (song in allSongs) {
        var accessible = isSongAccessible(song.songName, song.folder);
        trace("[CustomFreeplayState] Song \\"" + song.songName + "\\" accessible: " + accessible);
        if (accessible) {
            songs.push(song);
            songNames.push(song.songName);
        }
    }

    trace("[CustomFreeplayState] Filtered to " + songs.length + " accessible songs");

    if (songs.length == 0) {
        var noSongsText = new FlxText(0, 0, FlxG.width, "No accessible songs available", 24);
        noSongsText.alignment = "center";
        noSongsText.screenCenter();
        noSongsText.alpha = 0;
        state.add(noSongsText);
        FlxTween.tween(noSongsText, {alpha: 1}, 0.5, {startDelay: 0.4, ease: FlxEase.quadOut});
        return;
    }

    // Create song items
    for (i in 0...Math.min(songs.length, 10)) { // Limit to 10 songs for simplicity
        var songName = songs[i].songName;
        var songItem = new Alphabet(0, 170 + (i * 60), songName, true);
        songItem.screenCenter();
        songItem.alpha = 0;
        songItem.y += 50;
        songItems.push(songItem);
        state.add(songItem);

        // Stagger the animations
        FlxTween.tween(songItem, {alpha: 1, y: songItem.y - 50}, 0.3, {
            startDelay: 0.5 + (i * 0.1),
            ease: FlxEase.quadOut
        });
    }

    // Initialize difficulty
    curDifficulty = 0;
    updateDifficulty();
    updateSelection();
}

function updateSelection() {
    if (songItems == null || songItems.length == 0) return;

    for (i in 0...songItems.length) {
        var item = songItems[i];
        if (i == curSelected) {
            item.alpha = 1.0;
            FlxTween.cancelTweensOf(item.scale);
            FlxTween.tween(item.scale, {x: 1.1, y: 1.1}, 0.15, {ease: FlxEase.quadOut});
        } else {
            item.alpha = 0.6;
            FlxTween.cancelTweensOf(item.scale);
            FlxTween.tween(item.scale, {x: 1.0, y: 1.0}, 0.15, {ease: FlxEase.quadOut});
        }
    }
}

function updateDifficulty() {
    var diffCount = getDifficultyCount();
    if (diffCount == 0) {
        difficultyText.text = "< NO DIFFICULTIES >";
        return;
    }

    // Wrap difficulty selection
    if (curDifficulty < 0) curDifficulty = diffCount - 1;
    if (curDifficulty >= diffCount) curDifficulty = 0;

    var diffName = getDifficultyName(curDifficulty);
    if (diffCount > 1) {
        difficultyText.text = "< " + diffName.toUpperCase() + " >";
    } else {
        difficultyText.text = diffName.toUpperCase();
    }

    // Remove old difficulty sprite if exists
    if (difficultySprite != null) {
        difficultySprite.destroy();
        difficultySprite = null;
    }

    // Create new difficulty sprite
    difficultySprite = createDifficultySprite(curDifficulty);
    if (difficultySprite != null) {
        difficultySprite.setGraphicSize(Std.int(difficultySprite.width * 0.7));
        difficultySprite.updateHitbox();
        difficultySprite.x = (FlxG.width - difficultySprite.width) / 2;
        difficultySprite.y = 140;
        difficultySprite.alpha = 0;
        state.add(difficultySprite);
        FlxTween.tween(difficultySprite, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});

        // Hide text when sprite is available
        difficultyText.alpha = 0;
    } else {
        // Show text when sprite failed to load
        FlxTween.tween(difficultyText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
    }
}

function update(elapsed) {
    // Defensive checks
    if (songItems == null || songItems.length == 0) return;
    if (songs == null || songs.length == 0) return;

    // Song selection
    if (FlxG.keys.justPressed.UP) {
        curSelected--;
        if (curSelected < 0) curSelected = Math.max(0, songItems.length - 1);
        updateSelection();
        FlxG.sound.play("assets/sounds/scrollMenu.ogg");
    }
    if (FlxG.keys.justPressed.DOWN) {
        curSelected++;
        if (curSelected >= songItems.length) curSelected = 0;
        updateSelection();
        FlxG.sound.play("assets/sounds/scrollMenu.ogg");
    }

    // Difficulty selection
    if (FlxG.keys.justPressed.LEFT) {
        curDifficulty--;
        updateDifficulty();
        FlxG.sound.play("assets/sounds/scrollMenu.ogg");
    }
    if (FlxG.keys.justPressed.RIGHT) {
        curDifficulty++;
        updateDifficulty();
        FlxG.sound.play("assets/sounds/scrollMenu.ogg");
    }

    // Play song
    if (FlxG.keys.justPressed.ENTER) {
        // Validate selection bounds
        if (curSelected < 0 || curSelected >= songs.length) {
            FlxG.sound.play("assets/sounds/cancelMenu.ogg");
            return;
        }

        // Find the original index of the selected song in the full song list
        var selectedSong = songs[curSelected];
        var originalIndex = -1;
        for (i in 0...fpManager.songList.length) {
            if (fpManager.songList[i].songName == selectedSong.songName && fpManager.songList[i].folder == selectedSong.folder) {
                originalIndex = i;
                break;
            }
        }

        if (originalIndex >= 0) {
            playSong(originalIndex, curDifficulty);
        } else {
            FlxG.sound.play("assets/sounds/cancelMenu.ogg");
        }
    }
}

function destroy() {
    songItems = null;
    if (difficultySprite != null) {
        difficultySprite.destroy();
        difficultySprite = null;
    }
}

function onFreeplayReload(refresh, searchText) {
    // Tween out all elements before reloading
    var tweenCount = 0;
    var totalTweens = 0;

    // Count total tweens needed
    if (titleText != null) totalTweens++;
    if (instructionText != null) totalTweens++;
    if (difficultyText != null) totalTweens++;
    if (difficultySprite != null) totalTweens++;
    totalTweens += songItems.length;

    function onTweenComplete() {
        tweenCount++;
        if (tweenCount >= totalTweens) {
            // All tweens complete, reload the state
            FlxG.resetState();
        }
    }

    // If no tweens needed, just reload immediately
    if (totalTweens == 0) {
        FlxG.resetState();
        return true; // Prevent default behavior
    }

    // Tween out title
    if (titleText != null) {
        FlxTween.tween(titleText, {alpha: 0, y: titleText.y - 50}, 0.3, {
            ease: FlxEase.quadIn,
            onComplete: function(tween) { onTweenComplete(); }
        });
    }

    // Tween out instructions
    if (instructionText != null) {
        FlxTween.tween(instructionText, {alpha: 0}, 0.2, {
            startDelay: 0.1,
            ease: FlxEase.quadIn,
            onComplete: function(tween) { onTweenComplete(); }
        });
    }

    // Tween out difficulty text
    if (difficultyText != null) {
        FlxTween.tween(difficultyText, {alpha: 0}, 0.2, {
            startDelay: 0.15,
            ease: FlxEase.quadIn,
            onComplete: function(tween) { onTweenComplete(); }
        });
    }

    // Tween out difficulty sprite
    if (difficultySprite != null) {
        FlxTween.tween(difficultySprite, {alpha: 0, y: difficultySprite.y + 50}, 0.2, {
            startDelay: 0.15,
            ease: FlxEase.quadIn,
            onComplete: function(tween) { onTweenComplete(); }
        });
    }

    // Tween out song items (staggered)
    for (i in 0...songItems.length) {
        var songItem = songItems[i];
        FlxTween.tween(songItem, {alpha: 0, y: songItem.y + 50}, 0.25, {
            startDelay: 0.2 + (i * 0.05),
            ease: FlxEase.quadIn,
            onComplete: function(tween) { onTweenComplete(); }
        });
    }

    return true; // Prevent default reload behavior
}

// Return object with function references
{
    create: create,
    update: update,
    destroy: destroy,
    onFreeplayReload: onFreeplayReload
};
