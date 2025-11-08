package states.freeplay.vslice.obj;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

/**
 * Album roll display for V-Slice freeplay
 * Shows album artwork for the currently selected song
 */
class AlbumRoll extends FlxSprite
{
    public var albumArt:FlxSprite;

    public function new(x:Float = 0, y:Float = 0)
    {
        super(x, y);

        setupAlbumRoll();
    }

    private function setupAlbumRoll():Void
    {
        // Load album roll frames
        var rollFrames = Paths.getSparrowAtlas('freeplay/albumRoll/albumRoll', 'vslice');
        if (rollFrames != null) {
            frames = rollFrames;
            animation.addByPrefix('idle', 'albumRoll idle', 24, true);
            animation.addByPrefix('rollLeft', 'albumRoll rollLeft', 24, false);
            animation.addByPrefix('rollRight', 'albumRoll rollRight', 24, false);
            animation.play('idle');
        } else {
            // Fallback graphic
            makeGraphic(120, 120, 0xFF9271FD);
        }

        antialiasing = ClientPrefs.data.antialiasing;

        // Setup album art
        albumArt = new FlxSprite();
        albumArt.makeGraphic(100, 100, 0xFFFFFFFF);
        albumArt.antialiasing = ClientPrefs.data.antialiasing;
    }

    public function setAlbum(albumId:String):Void
    {
        // Try to load specific album art
        var albumPath = 'freeplay/albums/$albumId';
        var albumGraphic = Paths.image(albumPath, 'vslice');

        if (albumGraphic != null) {
            albumArt.loadGraphic(albumGraphic);
        } else {
            // Default album art
            albumArt.loadGraphic(Paths.image('freeplay/albums/default', 'vslice'));
            if (albumArt.graphic == null) {
                albumArt.makeGraphic(100, 100, 0xFF9271FD);
            }
        }

        // Position album art within the roll
        albumArt.setPosition(x + 10, y + 10);
    }

    public function rollLeft():Void
    {
        if (animation.curAnim != null) {
            animation.play('rollLeft');
            animation.finishCallback = function(name:String) {
                animation.play('idle');
                animation.finishCallback = null;
            };
        }
    }

    public function rollRight():Void
    {
        if (animation.curAnim != null) {
            animation.play('rollRight');
            animation.finishCallback = function(name:String) {
                animation.play('idle');
                animation.finishCallback = null;
            };
        }
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Update album art position if it exists
        if (albumArt != null) {
            albumArt.setPosition(x + 10, y + 10);
        }
    }

    override function draw():Void
    {
        super.draw();

        // Draw album art if it exists
        if (albumArt != null && albumArt.visible) {
            albumArt.draw();
        }
    }

    override function destroy():Void
    {
        if (albumArt != null) {
            albumArt.destroy();
            albumArt = null;
        }

        super.destroy();
    }
}
