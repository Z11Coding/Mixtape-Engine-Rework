package backend.window;

#if windows
@:headerCode('
    #include <windows.h>
    #include <iostream>
    #include <string>
    #include <hxcpp.h>
')
#end
class Wallpaper
{
	@:noCompletion
	public static var oldWallpaper(default, null):String;

	@:noCompletion
	public static function setOld():Void
	{
		#if windows
		oldWallpaper = _setOld();
		#elseif CROSSPLATFORM
		// Store current wallpaper path for non-Windows platforms
		oldWallpaper = getCurrentWallpaper();
		#end
	}

	#if windows
	@:functionCode('
        wchar_t* wallpath = const_cast<wchar_t*>(path.wchar_str());
        SystemParametersInfoW(SPI_SETDESKWALLPAPER, 0, reinterpret_cast<void*>(wallpath), SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    ')
	@:noCompletion
	public static function setWallpaper(path:String):Void
		return;

	@:functionCode('
        WCHAR buffer[1024] = {0};
        SystemParametersInfoW(SPI_GETDESKWALLPAPER, 256, &buffer, NULL);
        return String(buffer);
    ')
	@:noCompletion
	private static function _setOld():String
		return "";
	#else
	@:noCompletion
	public static function setWallpaper(path:String):Void
	{
		#if (linux && CROSSPLATFORM)
		setLinuxWallpaper(path);
		#elseif (mac && CROSSPLATFORM)
		setMacWallpaper(path);
		#elseif CROSSPLATFORM
		trace("Wallpaper setting not supported on this platform");
		#end
	}

	@:noCompletion
	private static function getCurrentWallpaper():String
	{
		#if (linux && CROSSPLATFORM)
		return getLinuxWallpaper();
		#elseif (mac && CROSSPLATFORM)
		return getMacWallpaper();
		#else
		return "";
		#end
	}

	#if (linux && CROSSPLATFORM)
	private static function setLinuxWallpaper(path:String):Void
	{
		var commands = [
			'gsettings set org.gnome.desktop.background picture-uri "file://$path"',
			'feh --bg-scale "$path"',
			'xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$path"',
			'plasma-apply-wallpaperimage "$path"',
		];

		for (cmd in commands) {
			try {
				var result = Sys.command(cmd);
				if (result == 0) break;
			} catch (e:Dynamic) {
				continue;
			}
		}
	}

	private static function getLinuxWallpaper():String
	{
		try {
			// Try to get GNOME wallpaper
			var process = new sys.io.Process("gsettings", ["get", "org.gnome.desktop.background", "picture-uri"]);
			var result = process.stdout.readAll().toString().trim();
			process.close();
			if (result.length > 0 && result != "") {
				// Remove quotes and file:// prefix
				result = result.replace("'", "").replace('"', "").replace("file://", "");
				return result;
			}
		} catch (e:Dynamic) {
			// Ignore and try other methods
		}
		return "";
	}
	#end	#if (mac && CROSSPLATFORM)
	private static function setMacWallpaper(path:String):Void
	{
		try {
			Sys.command('osascript -e "tell application \\"Finder\\" to set desktop picture to POSIX file \\"$path\\""');
		} catch (e:Dynamic) {
			trace("Failed to set wallpaper on macOS: " + e);
		}
	}

	private static function getMacWallpaper():String
	{
		try {
			var process = new sys.io.Process("osascript", ["-e", "tell application \"Finder\" to get desktop picture as string"]);
			var result = process.stdout.readAll().toString().trim();
			process.close();
			return result;
		} catch (e:Dynamic) {
			return "";
		}
	}
	#end
	#end
}
