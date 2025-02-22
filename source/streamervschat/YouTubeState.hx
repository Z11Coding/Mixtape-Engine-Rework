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
import lime.app.Application;

class YouTubeState extends FlxState
{
	public static var id:String;
	public static var socket:Socket;
	public static var data:YTSetupData;
	public static var isConnected:Bool = false;

	var log:FlxText = new FlxText();

	override function create()
	{
		super.create();

		Main.streamMethod = "yt";

		add(log);

		log.text = "Attempting to get YouTube video ID details...\n";

		if (!FileSystem.exists('streamVsChat/setup-youtube.json'))
		{
			error("Can't find setup-youtube.json!");
			return;
		}

		var rawJson:String = File.getContent('scripts/setup-youtube.json');
		StringTools.trim(rawJson);
		data = haxe.Json.parse(rawJson);

		if (data == null || data.video_id == null)
		{
			error("setup-youtube.json is not formatted correctly!");
			return;
		}

		id = StringTools.trim(data.video_id);

		if (id == 'video_id_goes_here')
		{
			error("It doesn't seem like you've entered your YouTube stream video ID into setup-youtube.json!");
			return;
		}

		sys.thread.Thread.create(() ->
		{
			print("Attempting to connect to Septapus IRC...");

			socket = new Socket();
			var ircname = new Host("irc.septapus.com");

			try
			{
				socket.connect(ircname, 6667);
			}
			catch (e)
			{
				error("Could not connect to Septapus with port 6667.");
				return;
			}

			socket.setBlocking(false);
			socket.setFastSend(true);

			print("It seems we connected to Septapus.");
			print("Attempting to send our video id to Septapus...");

			var thingy:String = "guest" + Date.now().getHours() + Date.now().getMinutes() + Date.now().getSeconds() + FlxG.random.int(0, 4096);

			var messageString = "USER " + thingy + " " + thingy + " " + thingy + " :" + thingy + "\r\n";
			var messageString3 = "NICK " + thingy + "\r\n";
			var messageString4 = "JOIN #" + id + "\r\n";

			var bytesToSend:Bytes = haxe.io.Bytes.ofString(messageString);
			var bytesToSend3:Bytes = haxe.io.Bytes.ofString(messageString3);
			var bytesToSend4:Bytes = haxe.io.Bytes.ofString(messageString4);

			try
			{
				socket.output.writeBytes(bytesToSend, 0, bytesToSend.length);
				print("Sent username");
				socket.output.writeBytes(bytesToSend3, 0, bytesToSend3.length);
				print("Sent nickname");
				socket.output.writeBytes(bytesToSend4, 0, bytesToSend4.length);
				print("Sent video id");
			}
			catch (e)
			{
				error("Could not send info to Septapus. Did the connection suddenly get cut?");
				return;
			}

			print("Waiting for response from Septapus...");
			print("If the program seems to halt here, try restarting...");
			while (true)
			{
				try
				{
					var byteBuffer = Bytes.alloc(1024);
					var output:String;
					var bytesRead:Int = socket.input.readBytes(byteBuffer, 0, 1024);
					var byteString = Bytes.alloc(bytesRead);
					byteString.blit(0, byteBuffer, 0, bytesRead);
					output = byteString.toString();

					trace(output);

					if (!StringTools.contains(output, "Welcome to the IRC Network")
						&& !StringTools.contains(output, "You have not linked your YouTube account properly"))
					{
						print("Something went wrong with trying to connect to Septapus.");
						print("Here's what Septapus responded with:");
						error(output);
						return;
					}

					print("It seems like we're connected to Septapus now.");
					print("Let's start the game!");

					isConnected = true;
					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						tryRead();
						FlxG.switchState(new TitleState());
					});
					break;
				}
				catch (err:Dynamic)
				{
					// trace(err);
				}
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	function print(stuff:String)
	{
		log.text += stuff + "\n";
	}

	function error(stuff:String)
	{
		print(stuff);
		print("");
		print("Program will now halt.");
		Application.current.window.alert("No Setup File detected.");
		FlxG.switchState(new TitleState());
	}

	public static function tryRead()
	{
		trace("Now reading for commands...");
		sys.thread.Thread.create(() ->
		{
			var check = new EReg("PRIVMSG #[a-zA-Z0-9_]+ :(.+)", "i");
			var accepted = File.getContent('scripts/accepted_commands.txt');
			while (true)
			{
				try
				{
					var byteBuffer = Bytes.alloc(1024);
					var output:String;
					var bytesRead:Int = socket.input.readBytes(byteBuffer, 0, 1024);
					var byteString = Bytes.alloc(bytesRead);
					byteString.blit(0, byteBuffer, 0, bytesRead);
					output = byteString.toString();

					// trace(output);

					if (check.match(output))
					{
						for (message in getMatches(check, output, 1))
						{
							var stop = message.indexOf("\n");
							var stop2 = message.indexOf("\r");
							var realStop:Int;
							if (stop == -1 && stop2 == -1)
								realStop = message.length;
							else if (stop2 == -1)
								realStop = stop;
							else if (stop == -1)
								realStop = stop2;
							else
								realStop = Math.floor(Math.min(stop, stop2));

							var command = message.substring(0, realStop);
							var check2:EReg = new EReg("(\\s|^)" + command + "(\\s|$)", "i");

							if (check2.match(accepted))
							{
								StringTools.trim(command);
								trace("COMMAND: " + command);
								PlayState.commands.push(command.substring(1, command.length));
								// trace("EVERYTHING: " + PlayState.commands + " LENGTH : " + PlayState.commands.length);
							}
						}
					}
					else if (StringTools.contains(output, "PING"))
					{
						var messageString = "PONG :irc.septapus.com\r\n";
						var bytesToSend:Bytes = haxe.io.Bytes.ofString(messageString);

						try
						{
							socket.output.writeBytes(bytesToSend, 0, bytesToSend.length);
							trace("Sent Ping-Pong");
						}
						catch (e)
						{
							trace("Error sending Ping-Pong...");
						}
					}
				}
				catch (err:Dynamic)
				{
					// trace(err);
					if (err == Error.Blocked)
					{
						// trace("BLOCKED");
					}
					else
					{
						trace("Potential error with connecting. Attempting to reconnect");
						tryReconnect();
					}
				}
			}
		});
	}

	public static function getMatches(ereg:EReg, input:String, index:Int = 0):Array<String>
	{
		var matches = [];
		while (ereg.match(input))
		{
			matches.push(ereg.matched(index));
			input = ereg.matchedRight();
		}
		return matches;
	}

	public static function tryReconnect()
	{
		trace("Closing current socket");

		socket.close();

		trace("Attempting to reconnect");
		trace("Attempting to connect to Septapus IRC...");

		socket = new Socket();
		var ircname = new Host("irc.septapus.com");

		try
		{
			socket.connect(ircname, 6667);
		}
		catch (e)
		{
			trace("Could not connect to Septapus with port 6667.");
			return;
		}

		socket.setBlocking(false);
		socket.setFastSend(true);

		trace("It seems we connected to Septapus.");
		trace("Attempting to send our video id to Septapus...");

		var thingy:String = "guest" + Date.now().getHours() + Date.now().getMinutes() + Date.now().getSeconds() + FlxG.random.int(0, 4096);

		var messageString = "USER " + thingy + " " + thingy + " " + thingy + " :" + thingy + "\r\n";
		var messageString3 = "NICK " + thingy + "\r\n";
		var messageString4 = "JOIN #" + id + "\r\n";

		var bytesToSend:Bytes = haxe.io.Bytes.ofString(messageString);
		var bytesToSend3:Bytes = haxe.io.Bytes.ofString(messageString3);
		var bytesToSend4:Bytes = haxe.io.Bytes.ofString(messageString4);

		try
		{
			socket.output.writeBytes(bytesToSend, 0, bytesToSend.length);
			trace("Sent username");
			socket.output.writeBytes(bytesToSend3, 0, bytesToSend3.length);
			trace("Sent nickname");
			socket.output.writeBytes(bytesToSend4, 0, bytesToSend4.length);
			trace("Sent video id");
		}
		catch (e)
		{
			trace("Could not send info to Septapus. Did the connection suddenly get cut?");
			return;
		}

		trace("Waiting for response from Septapus...");
		trace("If the program seems to halt here, try restarting...");
		while (true)
		{
			try
			{
				var byteBuffer = Bytes.alloc(1024);
				var output:String;
				var bytesRead:Int = socket.input.readBytes(byteBuffer, 0, 1024);
				var byteString = Bytes.alloc(bytesRead);
				byteString.blit(0, byteBuffer, 0, bytesRead);
				output = byteString.toString();

				trace(output);

				if (!StringTools.contains(output, "Welcome to the IRC Network")
					&& !StringTools.contains(output, "You have not linked your YouTube account properly"))
				{
					trace("Something went wrong with trying to connect to Septapus.");
					trace("Here's what Septapus responded with:");
					trace(output);
					return;
				}

				trace("It seems like we're connected to Septapus now.");
				break;
			}
			catch (err:Dynamic)
			{
				// trace(err);
			}
		}
	}
}

typedef YTSetupData =
{
	var video_id:String;
}