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

class TwitchState extends FlxState
{
	public static var name:String;
	public static var password:String;
	public static var socket:Socket;
	public static var data:SetupData;
	public static var isConnected:Bool = false;

	var log:FlxText = new FlxText();

	override function create()
	{
		super.create();

		Main.streamMethod = "twitch";

		add(log);

		log.text = "Attempting to get Twitch account details...\n";

		if (!FileSystem.exists('streamVsChat/setup-twitch.json'))
		{
			error("Can't find setup-twitch.json!");
			return;
		}

		var rawJson:String = File.getContent('streamVsChat/setup-twitch.json');
		StringTools.trim(rawJson);
		rawJson = StringTools.replace(rawJson, "\"oauth-key\"", "\"oauth_key\"");
		data = haxe.Json.parse(rawJson);

		if (data == null || data.username == null || data.oauth_key == null)
		{
			error("setup-twitch.json is not formatted correctly!");
			return;
		}

		name = data.username.toLowerCase();
		password = data.oauth_key;
		name = StringTools.trim(name);
		password = StringTools.trim(password);

		if (name == 'username_goes_here' && password == 'oauth_key_goes_here')
		{
			error("It doesn't seem like you've entered your Twitch account details into setup-twitch.json!");
			return;
		}

		sys.thread.Thread.create(() ->
		{
			print("Attempting to connect to Twitch...");

			socket = new Socket();
			var twitchname = new Host("irc.chat.twitch.tv");

			try
			{
				socket.connect(twitchname, 6667);
			}
			catch (e)
			{
				print("Could not connect to Twitch with port 6667. Trying port 80...");
				try
				{
					socket.connect(twitchname, 80);
				}
				catch (e)
				{
					error("Could not connect to Twitch at all.");
					return;
				}
			}

			socket.setBlocking(false);
			socket.setFastSend(true);

			print("It seems we connected to Twitch.");
			print("Attempting to send our account info to Twitch...");

			var messageString = "USER " + name + "\r\n";
			var messageString2 = "PASS " + password + "\r\n";
			var messageString3 = "NICK " + name + "\r\n";
			var messageString4 = "JOIN #" + name + "\r\n";

			var bytesToSend:Bytes = haxe.io.Bytes.ofString(messageString);
			var bytesToSend2:Bytes = haxe.io.Bytes.ofString(messageString2);
			var bytesToSend3:Bytes = haxe.io.Bytes.ofString(messageString3);
			var bytesToSend4:Bytes = haxe.io.Bytes.ofString(messageString4);

			try
			{
				socket.output.writeBytes(bytesToSend, 0, bytesToSend.length);
				print("Sent username");
				socket.output.writeBytes(bytesToSend2, 0, bytesToSend2.length);
				print("Sent OAuth key");
				socket.output.writeBytes(bytesToSend3, 0, bytesToSend3.length);
				print("Sent nickname");
				socket.output.writeBytes(bytesToSend4, 0, bytesToSend4.length);
				print("Sent chat channel");
			}
			catch (e)
			{
				error("Could not send account info to Twitch. Did the connection suddenly get cut?");
				return;
			}

			print("All Twitch user data sent.");

			print("Waiting for response from Twitch...");
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
					if (!StringTools.contains(output, "You are in a maze of twisty passages"))
					{
						print("Something went wrong! Maybe your login details are not correct.");
						print("Here's what Twitch responded with:");
						error(output);
						return;
					}

					print("It seems like Twitch accepted our user info.");
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
		print("Restarting Game...");
		Application.current.window.alert(stuff, "Stream Method Error");
		FlxG.switchState(new TitleState());

	}

	public static function tryRead()
	{
		trace("Now reading for commands...");
		sys.thread.Thread.create(() ->
		{
			var check = new EReg("PRIVMSG #[a-zA-Z0-9_]+ :(.+)", "i");

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


								StringTools.trim(command);
								trace("COMMAND: " + command);
								PlayState.commands.push(command.substring(1, command.length));
								// trace("EVERYTHING: " + PlayState.commands + " LENGTH : " + PlayState.commands.length);

						}
					}
					else if (StringTools.contains(output, "PING :tmi.twitch.tv"))
					{
						var messageString = "PONG :tmi.twitch.tv\r\n";
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
		trace("Attempting to connect to Twitch...");

		socket = new Socket();
		var twitchname = new Host("irc.chat.twitch.tv");

		try
		{
			socket.connect(twitchname, 6667);
		}
		catch (e)
		{
			trace("Could not connect to Twitch with port 6667. Trying port 80...");
			try
			{
				socket.connect(twitchname, 80);
			}
			catch (e)
			{
				trace("Could not connect to Twitch at all.");
				return;
			}
		}

		socket.setBlocking(false);
		socket.setFastSend(true);

		trace("It seems we connected to Twitch.");
		trace("Attempting to send our account info to Twitch...");

		var messageString = "USER " + name + "\r\n";
		var messageString2 = "PASS " + password + "\r\n";
		var messageString3 = "NICK " + name + "\r\n";
		var messageString4 = "JOIN #" + name + "\r\n";

		var bytesToSend:Bytes = haxe.io.Bytes.ofString(messageString);
		var bytesToSend2:Bytes = haxe.io.Bytes.ofString(messageString2);
		var bytesToSend3:Bytes = haxe.io.Bytes.ofString(messageString3);
		var bytesToSend4:Bytes = haxe.io.Bytes.ofString(messageString4);

		try
		{
			socket.output.writeBytes(bytesToSend, 0, bytesToSend.length);
			trace("Sent username");
			socket.output.writeBytes(bytesToSend2, 0, bytesToSend2.length);
			trace("Sent OAuth key");
			socket.output.writeBytes(bytesToSend3, 0, bytesToSend3.length);
			trace("Sent nickname");
			socket.output.writeBytes(bytesToSend4, 0, bytesToSend4.length);
			trace("Sent chat channel");
		}
		catch (e)
		{
			trace("Could not send account info to Twitch. Did the connection suddenly get cut?");
			return;
		}

		trace("All Twitch user data sent.");

		trace("Waiting for response from Twitch...");
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
				if (!StringTools.contains(output, "You are in a maze of twisty passages"))
				{
					trace("Something went wrong! Maybe your login details are not correct.");
					trace("Here's what Twitch responded with:");
					trace(output);
					return;
				}

				trace("It seems like Twitch accepted our user info.");
				break;
			}
			catch (err:Dynamic)
			{
				// trace(err);
			}
		}
	}
}

typedef SetupData =
{
	var username:String;
	var oauth_key:String;
}