package streamervschat;

import haxe.io.Error;
import sys.io.File;
import haxe.io.Bytes;
import flixel.util.FlxColor;
import sys.net.Host;
import sys.net.Socket;
import sys.FileSystem;
import flixel.text.FlxText;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;

class OfflineState extends FlxState
{
	var log:FlxText = new FlxText();

	override function create()
	{
		super.create();

		Main.streamMethod = "offline";

		tryRead();
		FlxG.switchState(new TitleState());
	}

	public static function tryRead()
	{
		var accepted = File.getContent('scripts/accepted_commands.txt');
		var commands:Array<String>;
		if (accepted.indexOf("\r\n") >= 0)
			commands = accepted.split("\r\n");
		else if (accepted.indexOf("\r") >= 0)
			commands = accepted.split("\r");
		else
			commands = accepted.split("\n");

		trace("ARRAYLENGTH: " + commands.length);

		sys.thread.Thread.create(() ->
		{
			while (true)
			{
				var selected = FlxG.random.getObject(commands);
				StringTools.trim(selected);
				trace("COMMAND: " + selected);
				PlayState.commands.push(selected.substring(1, selected.length));
				Sys.sleep(4);
			}
		});
	}
}