package backend.window.os;

#if (linux && CROSSPLATFORM)
@:cppFileCode('
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
')
class Linux {
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

		if(meminfo == NULL)
			return -1;

		char line[256];
		while(fgets(line, sizeof(line), meminfo))
		{
			int ram;
			if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
			{
				fclose(meminfo);
				return (ram / 1024);
			}
		}

		fclose(meminfo);
		return -1;
	')
	public static function getTotalRam():Float
	{
		return 0;
	}

	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

		if(meminfo == NULL)
			return -1;

		char line[256];
		while(fgets(line, sizeof(line), meminfo))
		{
			int ram;
			if(sscanf(line, "MemAvailable: %d kB", &ram) == 1)
			{
				fclose(meminfo);
				return (ram / 1024);
			}
		}

		fclose(meminfo);
		return -1;
	')
	public static function getAvailableRam():Float
	{
		return 0;
	}

	// Get desktop environment
	public static function getDesktopEnvironment():String
	{
		var envs = [
			"GNOME_DESKTOP_SESSION_ID" => "GNOME",
			"KDE_FULL_SESSION" => "KDE",
			"XFCE4_SESSION" => "XFCE",
			"DESKTOP_SESSION" => null // Will return the value directly
		];

		for (env => name in envs) {
			var value = Sys.getEnv(env);
			if (value != null) {
				return name != null ? name : value;
			}
		}

		return "Unknown";
	}

	// Check if a command exists
	public static function hasCommand(command:String):Bool
	{
		try {
			var result = Sys.command('which $command > /dev/null 2>&1');
			return result == 0;
		} catch (e:Dynamic) {
			return false;
		}
	}
}
#end
