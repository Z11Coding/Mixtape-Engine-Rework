package yutautil.games.pong.backend;

import flixel.FlxG;

/**
 * Sound effects manager for Pong game
 */
class PongSounds {
    public static var paddleHitSound:String = "scrollMenu";
    public static var wallBounceSound:String = "scrollMenu";
    public static var scoreSound:String = "confirmMenu";
    public static var gameStartSound:String = "confirmMenu";
    public static var gameEndSound:String = "cancelMenu";

    /**
     * Play paddle hit sound
     */
    public static function playPaddleHit():Void {
        FlxG.sound.play(Paths.sound(paddleHitSound), 0.7);
    }

    /**
     * Play wall bounce sound
     */
    public static function playWallBounce():Void {
        FlxG.sound.play(Paths.sound(wallBounceSound), 0.3);
    }

    /**
     * Play score sound
     */
    public static function playScore():Void {
        FlxG.sound.play(Paths.sound(scoreSound), 0.8);
    }

    /**
     * Play game start sound
     */
    public static function playGameStart():Void {
        FlxG.sound.play(Paths.sound(gameStartSound), 0.6);
    }

    /**
     * Play game end sound
     */
    public static function playGameEnd():Void {
        FlxG.sound.play(Paths.sound(gameEndSound), 0.8);
    }
}
