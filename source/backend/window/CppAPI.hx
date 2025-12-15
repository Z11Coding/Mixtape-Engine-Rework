package backend.window;

import backend.window.*;

#if (linux && CROSSPLATFORM)
import backend.window.os.Linux;
#end
#if (mac && CROSSPLATFORM)
import backend.window.os.Mac;
#end
#if (android && CROSSPLATFORM)
import backend.window.os.Android;
#end

class CppAPI
{
	// RAM detection - cross-platform support
	public static function obtainRAM():Int
	{
		#if windows
		return WindowsData.obtainRAM();
		#elseif (linux && CROSSPLATFORM)
		return Std.int(Linux.getTotalRam());
		#elseif (mac && CROSSPLATFORM)
		return Std.int(Mac.getTotalRam());
		#elseif (android && CROSSPLATFORM)
		return Std.int(Android.getTotalRam());
		#else
		// Fallback for other platforms or when CROSSPLATFORM is disabled
		return -1;
		#end
	}

	// Dark/Light mode - Windows only for now, fallback on others
	public static function darkMode()
	{
		#if windows
		WindowsData.setWindowColorMode(DARK);
		#elseif CROSSPLATFORM
		// No-op on other platforms - could potentially implement via desktop environment APIs
		#end
	}

	public static function lightMode()
	{
		#if windows
		WindowsData.setWindowColorMode(LIGHT);
		#elseif CROSSPLATFORM
		// No-op on other platforms
		#end
	}

	// Window opacity - cross-platform using Lime
	public static function setWindowOppacity(a:Float)
	{
		#if windows
		WindowsData.setWindowAlpha(a);
		#elseif ((linux || mac) && CROSSPLATFORM)
		// Use Lime's built-in window opacity where available
		try {
			lime.app.Application.current.window.opacity = a;
		} catch (e:Dynamic) {
			trace("Window opacity not supported on this platform: " + e);
		}
		#else
		// No-op for other platforms including Android (doesn't make sense for mobile) or when CROSSPLATFORM is disabled
		#end
	}

	public static inline function setWindowOpacity(a:Float)
	{
		setWindowOppacity(a);
	}

	public static inline function getWindowOpacity():Float
	{
		#if windows
		return WindowsData.getWindowAlpha();
		#elseif ((linux || mac) && CROSSPLATFORM)
		try {
			return lime.app.Application.current.window.opacity;
		} catch (e:Dynamic) {
			trace("Window opacity not supported on this platform: " + e);
			return 1.0;
		}
		#else
		return 1.0; // Default full opacity
		#end
	}

	// Window layering - Windows specific
	public static function _setWindowLayered()
	{
		#if windows
		WindowsData._setWindowLayered();
		#elseif CROSSPLATFORM
		// No direct equivalent on other platforms
		#end
	}

	// Wallpaper management - cross-platform where possible
	public static function setWallpaper(path:String)
	{
		#if windows
		if(path == 'old') {
			if(Wallpaper.oldWallpaper != null) {
				path = Wallpaper.oldWallpaper;
			} else {
				return;
			}
		}
		Wallpaper.setWallpaper(path);
		#elseif (linux && CROSSPLATFORM)
		// Try common Linux desktop environments
		setLinuxWallpaper(path);
		#elseif (mac && CROSSPLATFORM)
		// Use macOS system command
		setMacWallpaper(path);
		#elseif CROSSPLATFORM
		// No-op for other platforms including Android (system restriction)
		trace("Wallpaper setting not supported on this platform");
		#end
	}

	#if (linux && CROSSPLATFORM)
	private static function setLinuxWallpaper(path:String)
	{
		// Try different desktop environments
		var commands = [
			'gsettings set org.gnome.desktop.background picture-uri "file://$path"', // GNOME
			'feh --bg-scale "$path"', // feh (common)
			'xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$path"', // XFCE
			'plasma-apply-wallpaperimage "$path"', // KDE Plasma
		];

		for (cmd in commands) {
			try {
				Sys.command(cmd);
				break; // If successful, don't try others
			} catch (e:Dynamic) {
				continue; // Try next command
			}
		}
	}
	#end

	#if (mac && CROSSPLATFORM)
	private static function setMacWallpaper(path:String)
	{
		try {
			Sys.command('osascript -e "tell application \\"Finder\\" to set desktop picture to POSIX file \\"$path\\""');
		} catch (e:Dynamic) {
			trace("Failed to set wallpaper on macOS: " + e);
		}
	}
	#end

	public static function setOld()
	{
		#if windows
		Wallpaper.setOld();
		#elseif CROSSPLATFORM
		// No equivalent for other platforms yet
		#end
	}

	// Taskbar management - platform specific
	public static function hideTaskbar()
	{
		#if windows
		WindowsData.hideTaskbar();
		#elseif (linux && CROSSPLATFORM)
		hideLinuxTaskbar();
		#elseif (mac && CROSSPLATFORM)
		hideMacDock();
		#elseif CROSSPLATFORM
		// No-op for other platforms
		#end
	}

	public static function restoreTaskbar()
	{
		#if windows
		WindowsData.restoreTaskbar();
		#elseif (linux && CROSSPLATFORM)
		showLinuxTaskbar();
		#elseif (mac && CROSSPLATFORM)
		showMacDock();
		#elseif CROSSPLATFORM
		// No-op for other platforms
		#end
	}

	#if (linux && CROSSPLATFORM)
	private static function hideLinuxTaskbar()
	{
		// Try different desktop environments
		var commands = [
			"gsettings set org.gnome.shell.extensions.dash-to-dock autohide true", // GNOME
			"xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -s 2", // XFCE
		];

		for (cmd in commands) {
			try {
				Sys.command(cmd);
				break;
			} catch (e:Dynamic) {
				continue;
			}
		}
	}

	private static function showLinuxTaskbar()
	{
		var commands = [
			"gsettings set org.gnome.shell.extensions.dash-to-dock autohide false",
			"xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -s 0",
		];

		for (cmd in commands) {
			try {
				Sys.command(cmd);
				break;
			} catch (e:Dynamic) {
				continue;
			}
		}
	}
	#end

	#if (mac && CROSSPLATFORM)
	private static function hideMacDock()
	{
		try {
			Sys.command("defaults write com.apple.dock autohide -bool true && killall Dock");
		} catch (e:Dynamic) {
			trace("Failed to hide macOS dock: " + e);
		}
	}

	private static function showMacDock()
	{
		try {
			Sys.command("defaults write com.apple.dock autohide -bool false && killall Dock");
		} catch (e:Dynamic) {
			trace("Failed to show macOS dock: " + e);
		}
	}
	#end

	// Window hiding - limited cross-platform support
	public static function hideWindows()
	{
		#if windows
		WindowsData.hideWindows();
		#elseif CROSSPLATFORM
		// No direct equivalent on other platforms - this is very Windows-specific
		trace("Window hiding not supported on this platform");
		#end
	}

	public static function restoreWindows()
	{
		#if windows
		WindowsData.restoreWindows();
		#elseif CROSSPLATFORM
		// No direct equivalent on other platforms
		#end
	}

	// Transparency - Windows specific
	public static function setTransparency(winName:String, color:Int)
	{
		#if windows
		Transparency.setTransparency(winName, color);
		#elseif CROSSPLATFORM
		// No equivalent on other platforms
		#end
	}

	// Window icon removal - Windows specific
	public static function removeWindowIcon()
	{
		#if windows
		WindowsData.removeWindowIcon();
		#elseif CROSSPLATFORM
		// No equivalent on other platforms
		#end
	}

	public static function reset()
	{
		#if windows
		Transparency.reset();
		#elseif CROSSPLATFORM
		// No equivalent on other platforms
		#end
	}

	// High DPI support - cross-platform via Lime
	public static function allowHighDPI() {
		#if windows
		WindowsData.registerHighDpi();
		#elseif ((linux || mac) && CROSSPLATFORM)
		// Lime handles this automatically on most platforms
		try {
			lime.app.Application.current.window.scale = lime.system.System.devicePixelRatio;
		} catch (e:Dynamic) {
			trace("High DPI support not available: " + e);
		}
		#elseif CROSSPLATFORM
		// Android and other platforms handle this automatically
		#end
	}

	// Notification system - cross-platform
	public static function sendWindowsNotification(title:String = "", desc:String = "") {
		#if windows
		return PlatformUtil.sendWindowsNotification(title, desc);
		#elseif (linux && CROSSPLATFORM)
		return sendLinuxNotification(title, desc);
		#elseif (mac && CROSSPLATFORM)
		return sendMacNotification(title, desc);
		#elseif (android && CROSSPLATFORM)
		return sendAndroidNotification(title, desc);
		#elseif CROSSPLATFORM
		trace('Notification: $title - $desc'); // Fallback to console
		return true;
		#else
		return true; // Do nothing when CROSSPLATFORM is disabled
		#end
	}

	#if (linux && CROSSPLATFORM)
	private static function sendLinuxNotification(title:String, desc:String):Bool
	{
		try {
			// Use notify-send (libnotify) - most common on Linux
			var result = Sys.command('notify-send "$title" "$desc" --app-name="Mixtape Engine" --urgency=normal');
			return result == 0;
		} catch (e:Dynamic) {
			trace("Failed to send Linux notification: " + e);
			return false;
		}
	}
	#end

	#if (mac && CROSSPLATFORM)
	private static function sendMacNotification(title:String, desc:String):Bool
	{
		try {
			// Use AppleScript for macOS notifications
			var script = 'display notification "$desc" with title "$title" subtitle "Mixtape Engine"';
			var result = Sys.command('osascript -e \'$script\'');
			return result == 0;
		} catch (e:Dynamic) {
			trace("Failed to send macOS notification: " + e);
			return false;
		}
	}
	#end

	#if (android && CROSSPLATFORM)
	private static function sendAndroidNotification(title:String, desc:String):Bool
	{
		// Android notifications would require JNI integration
		// For now, just log to console as Android apps handle notifications differently
		trace('Android Notification: $title - $desc');
		return true;
	}
	#end

	// Window title management - cross-platform via WindowUtils
	public static function setWinTitle(title:String = "") {
		WindowUtils.winTitle = title;
	}

	public static function setWinPrefix(title:String = "") {
		WindowUtils.prefix = title;
	}

	public static function setWinSuffix(title:String = "") {
		WindowUtils.suffix = title;
	}

	public static function resetTitle() {
		WindowUtils.resetTitle();
	}

	public static function resetAffixes() {
		WindowUtils.resetAffixes();
	}

	public static function updateTitle() {
		WindowUtils.updateTitle();
	}

	// Additional utility functions for cross-platform support

	// Get available RAM (cross-platform)
	public static function getAvailableRAM():Int
	{
		#if windows
		// Windows doesn't have a direct equivalent in WindowsData yet
		return -1;
		#elseif (linux && CROSSPLATFORM)
		return Std.int(Linux.getAvailableRam());
		#elseif (mac && CROSSPLATFORM)
		return Std.int(Mac.getAvailableRam());
		#elseif (android && CROSSPLATFORM)
		return Std.int(Android.getAvailableRam());
		#else
		return -1;
		#end
	}

	// Platform detection
	public static function getPlatform():String
	{
		#if windows
		return "Windows";
		#elseif linux
		return "Linux";
		#elseif mac
		return "macOS";
		#elseif android
		return "Android";
		#elseif ios
		return "iOS";
		#elseif html5
		return "HTML5";
		#else
		return "Unknown";
		#end
	}

	// Get platform-specific information
	public static function getPlatformInfo():String
	{
		#if windows
		return "Windows " + Sys.systemName();
		#elseif (linux && CROSSPLATFORM)
		return "Linux (" + Linux.getDesktopEnvironment() + ")";
		#elseif (mac && CROSSPLATFORM)
		return "macOS " + Mac.getMacOSVersion() + " (" + Mac.getArchitecture() + ")";
		#elseif (android && CROSSPLATFORM)
		return "Android " + Android.getAndroidVersion() + " (API " + Android.getAPILevel() + ") - " + Android.getDeviceModel();
		#else
		return getPlatform();
		#end
	}

	// Check if a system command is available
	public static function hasSystemCommand(command:String):Bool
	{
		#if windows
		try {
			var result = Sys.command('where $command >nul 2>&1');
			return result == 0;
		} catch (e:Dynamic) {
			return false;
		}
		#elseif ((linux || mac) && CROSSPLATFORM)
		try {
			var result = Sys.command('which $command > /dev/null 2>&1');
			return result == 0;
		} catch (e:Dynamic) {
			return false;
		}
		#else
		return false;
		#end
	}

	// Open file/URL with system default application
	public static function openWithSystem(path:String):Bool
	{
		#if CROSSPLATFORM
		try {
			#if windows
			Sys.command('start "" "$path"');
			return true;
			#elseif mac
			Sys.command('open "$path"');
			return true;
			#elseif linux
			Sys.command('xdg-open "$path"');
			return true;
			#else
			trace('Cannot open with system: $path');
			return false;
			#end
		} catch (e:Dynamic) {
			trace('Failed to open with system: $e');
			return false;
		}
		#else
		return false;
		#end
	}

	// Reveal file in file manager
	public static function revealInFileManager(path:String):Bool
	{
		#if CROSSPLATFORM
		try {
			#if windows
			Sys.command('explorer /select,"$path"');
			return true;
			#elseif mac
			Sys.command('open -R "$path"');
			return true;
			#elseif linux
			// Try different file managers
			var managers = ["nautilus", "dolphin", "thunar", "pcmanfm", "nemo"];
			for (manager in managers) {
				if (hasSystemCommand(manager)) {
					if (manager == "nautilus" || manager == "nemo") {
						Sys.command('$manager --select "$path"');
					} else {
						// For other managers, open the parent directory
						var dir = haxe.io.Path.directory(path);
						Sys.command('$manager "$dir"');
					}
					return true;
				}
			}
			// Fallback to xdg-open with directory
			var dir = haxe.io.Path.directory(path);
			Sys.command('xdg-open "$dir"');
			return true;
			#else
			return openWithSystem(haxe.io.Path.directory(path));
			#end
		} catch (e:Dynamic) {
			trace('Failed to reveal in file manager: $e');
			return false;
		}
		#else
		return false;
		#end
	}

	// Get system uptime (where possible)
	public static function getSystemUptime():Float
	{
		#if (linux && CROSSPLATFORM)
		try {
			var content = sys.io.File.getContent("/proc/uptime");
			var uptime = Std.parseFloat(content.split(" ")[0]);
			return uptime != null ? uptime : -1;
		} catch (e:Dynamic) {
			return -1;
		}
		#elseif (mac && CROSSPLATFORM)
		try {
			var process = new sys.io.Process("uptime", []);
			var output = process.stdout.readAll().toString();
			process.close();
			// Parse uptime output (this is a simplified approach)
			if (output.indexOf("up") != -1) {
				// This would need more sophisticated parsing
				return 0; // Placeholder
			}
		} catch (e:Dynamic) {
			return -1;
		}
		#end
		return -1;
	}

	// Simple performance test
	public static function getPerformanceScore():Float
	{
		var startTime = haxe.Timer.stamp();

		// Simple CPU-bound operation
		var sum:Float = 0;
		for (i in 0...1000000) {
			sum += Math.sin(i) * Math.cos(i);
		}

		var endTime = haxe.Timer.stamp();
		var duration = endTime - startTime;

		// Return inverse duration as score (higher is better)
		return duration > 0 ? 1.0 / duration : 0;
	}
}
