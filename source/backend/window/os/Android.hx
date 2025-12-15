package backend.window.os;

#if (android && CROSSPLATFORM)
class Android {
	// Get device RAM - Android specific approach
	public static function getTotalRam():Float
	{
		try {
			// Try to read /proc/meminfo like Linux
			var content = sys.io.File.getContent("/proc/meminfo");
			var lines = content.split("\n");

			for (line in lines) {
				if (line.indexOf("MemTotal:") == 0) {
					var parts = line.split(" ");
					for (part in parts) {
						var ram = Std.parseInt(part);
						if (ram != null) {
							return ram / 1024; // Convert KB to MB
						}
					}
				}
			}
		} catch (e:Dynamic) {
			trace("Failed to read Android RAM info: " + e);
		}
		return -1;
	}

	// Get available RAM
	public static function getAvailableRam():Float
	{
		try {
			var content = sys.io.File.getContent("/proc/meminfo");
			var lines = content.split("\n");

			for (line in lines) {
				if (line.indexOf("MemAvailable:") == 0) {
					var parts = line.split(" ");
					for (part in parts) {
						var ram = Std.parseInt(part);
						if (ram != null) {
							return ram / 1024; // Convert KB to MB
						}
					}
				}
			}
		} catch (e:Dynamic) {
			trace("Failed to read Android available RAM: " + e);
		}
		return -1;
	}

	// Check Android API level
	public static function getAPILevel():Int
	{
		try {
			var content = sys.io.File.getContent("/system/build.prop");
			var lines = content.split("\n");

			for (line in lines) {
				if (line.indexOf("ro.build.version.sdk=") == 0) {
					var level = line.split("=")[1];
					var apiLevel = Std.parseInt(level);
					return apiLevel != null ? apiLevel : -1;
				}
			}
		} catch (e:Dynamic) {
			trace("Failed to read Android API level: " + e);
		}
		return -1;
	}

	// Get Android version
	public static function getAndroidVersion():String
	{
		try {
			var content = sys.io.File.getContent("/system/build.prop");
			var lines = content.split("\n");

			for (line in lines) {
				if (line.indexOf("ro.build.version.release=") == 0) {
					return line.split("=")[1];
				}
			}
		} catch (e:Dynamic) {
			trace("Failed to read Android version: " + e);
		}
		return "Unknown";
	}

	// Check if device is rooted (basic check)
	public static function isRooted():Bool
	{
		var rootPaths = [
			"/system/app/Superuser.apk",
			"/sbin/su",
			"/system/bin/su",
			"/system/xbin/su",
			"/data/local/xbin/su",
			"/data/local/bin/su",
			"/system/sd/xbin/su",
			"/system/bin/failsafe/su",
			"/data/local/su"
		];

		for (path in rootPaths) {
			if (sys.FileSystem.exists(path)) {
				return true;
			}
		}
		return false;
	}

	// Get device model
	public static function getDeviceModel():String
	{
		try {
			var content = sys.io.File.getContent("/system/build.prop");
			var lines = content.split("\n");

			for (line in lines) {
				if (line.indexOf("ro.product.model=") == 0) {
					return line.split("=")[1];
				}
			}
		} catch (e:Dynamic) {
			trace("Failed to read device model: " + e);
		}
		return "Unknown";
	}
}
#end
