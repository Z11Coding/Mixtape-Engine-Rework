package states.editors;
//We gotta have music in the Editors!

import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.util.FlxTimer;

class EditingMusic extends flixel.FlxBasic
{
	public var music:FlxSound = new FlxSound();
	public var startTimer:FlxTimer = null;

	public var musicPaused:Bool = false;

	public function new() {
		super();
		playMusic(1);
	}

	public function shuffle() {
		music.time = 0;
		music.loadEmbedded(Paths.music('editorMusic/' + Std.string(FlxG.random.int(0, 4))));
		music.fadeIn(1, 0, 0.5);
		music.onComplete = shuffle;
	}

	public function pauseMusic() {
		music.pause();
		musicPaused = true;
		if (startTimer != null) startTimer.cancel();
		startTimer = null;
	}

	public function unpauseMusic(time:Float = 0) {
		musicPaused = false;
		if (time > 0)
		{
			if (music.fadeTween != null)
				music.fadeTween.cancel(); //cancel the fade tween so it doesnt NULL OBJECT REFERENCE
			if (startTimer != null) startTimer.cancel();
			startTimer = new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				music.fadeIn(1, 0, 0.5);
			});
		}
		else music.play();
	}

	public function FocusLost()
	{
		pauseMusic();
	}

	public function FocusGained():Void
	{
		unpauseMusic();
	}

	override public function destroy()
	{
		if (music.fadeTween != null)
			music.fadeTween.cancel(); //cancel the fade tween so it doesnt NULL OBJECT REFERENCE
		if (startTimer != null) startTimer.cancel();
		if (music != null) music.destroy();
		reset();
	}

	public function playMusic(time:Float = 0)
	{
		if (time > 0)
		{
			startTimer = new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				shuffle();
			});
		}
		else shuffle();
	}

	public function reset() {
		music.onComplete = null;
	}
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		music.update(elapsed);
	}
}