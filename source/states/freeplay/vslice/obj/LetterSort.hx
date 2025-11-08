package states.freeplay.vslice.obj;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Letter sorting system for V-Slice freeplay
 * Allows sorting songs alphabetically by first letter
 */
class LetterSort extends FlxTypedGroup<FlxSprite>
{
    private var letters:Array<String> = [];
    private var letterSprites:Array<FlxSprite> = [];
    private var selectedIndex:Int = -1; // -1 means no filter

    public var currentFilter:String = "";

    public function new(x:Float = 0, y:Float = 0)
    {
        super();

        setupLetterSort(x, y);
    }

    private function setupLetterSort(x:Float, y:Float):Void
    {
        // Create alphabet letters
        letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                  "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

        // Load letter sorting graphics
        var letterFrames = Paths.getSparrowAtlas('freeplay/sortedLetters/sortedLetters', 'vslice');

        var offsetX:Float = 0;
        var offsetY:Float = 0;

        for (i in 0...letters.length) {
            var letter = letters[i];
            var letterSprite = new FlxSprite(x + offsetX, y + offsetY);

            if (letterFrames != null) {
                letterSprite.frames = letterFrames;
                letterSprite.animation.addByPrefix('idle', '$letter idle', 24, true);
                letterSprite.animation.addByPrefix('selected', '$letter selected', 24, true);
                letterSprite.animation.play('idle');
            } else {
                // Fallback text
                letterSprite.makeGraphic(20, 20, FlxColor.TRANSPARENT);
                var letterText = new FlxText(0, 0, 20, letter);
                letterText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
                letterText.stamp(letterSprite);
            }

            letterSprite.antialiasing = ClientPrefs.data.antialiasing;
            letterSprite.alpha = 0.6;
            letterSprite.ID = i;

            letterSprites.push(letterSprite);
            add(letterSprite);

            // Arrange letters in a grid
            offsetX += 25;
            if ((i + 1) % 6 == 0) {
                offsetX = 0;
                offsetY += 25;
            }
        }

        // Add "ALL" option at the end
        var allSprite = new FlxSprite(x + offsetX, y + offsetY);
        allSprite.makeGraphic(30, 20, FlxColor.TRANSPARENT);
        var allText = new FlxText(0, 0, 30, "ALL");
        allText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
        allText.stamp(allSprite);
        allSprite.antialiasing = ClientPrefs.data.antialiasing;
        allSprite.alpha = 1.0; // Start with ALL selected
        allSprite.ID = letters.length;

        letterSprites.push(allSprite);
        add(allSprite);
    }

    public function selectLetter(letterIndex:Int):Void
    {
        // Reset all letters to idle
        for (i in 0...letterSprites.length) {
            var sprite = letterSprites[i];
            sprite.alpha = 0.6;
            if (sprite.animation != null && sprite.animation.getByName('idle') != null) {
                sprite.animation.play('idle');
            }
        }

        // Highlight selected letter
        if (letterIndex >= 0 && letterIndex < letterSprites.length) {
            var selected = letterSprites[letterIndex];
            selected.alpha = 1.0;
            if (selected.animation != null && selected.animation.getByName('selected') != null) {
                selected.animation.play('selected');
            }

            selectedIndex = letterIndex;

            // Set current filter
            if (letterIndex >= letters.length) {
                // "ALL" option
                currentFilter = "";
            } else {
                currentFilter = letters[letterIndex];
            }
        }
    }

    public function getFilteredSongs(allSongs:Array<Dynamic>):Array<Dynamic>
    {
        if (currentFilter == "") {
            return allSongs; // Return all songs
        }

        // Filter songs by first letter
        return allSongs.filter(function(song) {
            if (song == null || song.songName == null) return false;
            var firstLetter = song.songName.charAt(0).toUpperCase();
            return firstLetter == currentFilter;
        });
    }

    public function nextLetter():Void
    {
        var newIndex = selectedIndex + 1;
        if (newIndex >= letterSprites.length) {
            newIndex = 0;
        }
        selectLetter(newIndex);
    }

    public function prevLetter():Void
    {
        var newIndex = selectedIndex - 1;
        if (newIndex < 0) {
            newIndex = letterSprites.length - 1;
        }
        selectLetter(newIndex);
    }

    public function reset():Void
    {
        // Select "ALL" by default
        selectLetter(letterSprites.length - 1);
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Handle input for letter selection
        // This would be handled by the parent freeplay state
    }
}
