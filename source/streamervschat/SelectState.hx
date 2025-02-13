package streamervschat;

import flixel.math.FlxPoint;
import flixel.addons.display.shapes.FlxShapeArrow;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;
import lime.app.Application;

class SelectState extends FlxState
{
	var wasPressed:Bool = false;
	var selectText:FlxText = new FlxText();
	var twitch:FlxText = new FlxText();
	var yt:FlxText = new FlxText();
	var discord:FlxText = new FlxText();
	var offline:FlxText = new FlxText();
	var marker:FlxShapeArrow;

	var available:Array<FlxText> = [];
	var selected:Int = 0;

	override function create()
	{
		super.create();

		marker = new FlxShapeArrow(0, 0, FlxPoint.weak(0, 0), FlxPoint.weak(0, 1), 24, {color: FlxColor.WHITE});

		selectText.setFormat(null, 36, FlxColor.WHITE, FlxTextAlign.CENTER);
		selectText.text = "Select your streaming platform";
		selectText.y = 5;
		selectText.screenCenter(X);
		add(selectText);

		available.push(twitch);
		available.push(yt);
		// available.push(discord);
		available.push(offline);
		twitch.text = "Twitch";
		yt.text = "YouTube";
		discord.text = "Discord";
		offline.text = "Offline\n(no chat interaction)";

		for (i in 0...available.length)
		{
			available[i].setFormat(null, 24, FlxColor.WHITE, FlxTextAlign.CENTER);
			available[i].screenCenter(Y);
			available[i].x = (i * FlxG.width / available.length + FlxG.width / available.length / 2) - available[i].width / 2;
			add(available[i]);
		}

		add(marker);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && !wasPressed)
		{
			wasPressed = true;
			switch (selected)
			{
				case 0:
					FlxG.switchState(new TwitchState());
				case 1:
					FlxG.switchState(new YouTubeState());
				// case 2:
				// 	FlxG.switchState(new DiscordState());
				case 2:
					FlxG.switchState(new options.OptionsState());
			}
		}

		if (FlxG.keys.justPressed.LEFT)
		{
			changeSelection(-1);
		}

		if (FlxG.keys.justPressed.RIGHT)
		{
			changeSelection(1);
		}

		marker.x = available[selected].x + available[selected].width / 2 - marker.width / 2;
		marker.y = available[selected].y - marker.height - 5;
	}

	function changeSelection(direction:Int = 0)
	{
		if (wasPressed)
			return;

		selected = selected + direction;
		if (selected < 0)
			selected = available.length - 1;
		else if (selected >= available.length)
			selected = 0;
	}
}