package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var warnText:FlxText;
	var betaText:String = '';
	override function create()
	{
		super.create();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Running an Outdated Build", null);
		#end

		betaText = FirstCheckState.betaVersion != 'none' ? "\n(This is a beta update, so feel free to skip it)" : "(This is an actual update)";

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"A newer version of this engine is available.\nWould you like to update?"+ betaText +"\n(ENTER for yes, ESC for no.)",
			32);
		warnText.setFormat(Paths.font('funkin.ttf'), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if (ClientPrefs.data.checkForUpdates)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				//leftState = true;
				#if windows FlxG.switchState(new UpdateState());
				#else
				CoolUtil.browserLoad("https://github.com/Z11Coding/Vs.-Z11-Mixtape-Madness/releases/");
				#end
			}
			else if(controls.BACK) {
				leftState = true;
			}

			if(leftState)
			{
				leftState = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						MusicBeatState.switchState(new states.FirstCheckState.APCheckState());
					}
				});
			}
		}
		else MusicBeatState.switchState(new states.FirstCheckState.APCheckState());
		super.update(elapsed);
	}
}
