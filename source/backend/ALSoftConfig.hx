package backend;

import haxe.io.Path;
import sys.io.File;

/*
	A class that simply points OpenALSoft to a custom configuration file when the game starts up.
	The config overrides a few global OpenALSoft settings with the aim of improving audio quality on desktop targets.
 */
@:keep class ALSoftConfig
{
	#if desktop
	static function __init__():Void
	{
		var origin:String = #if hl Sys.getCwd() #else Sys.programPath() #end;

		var configPath:String = Path.directory(Path.withoutExtension(origin));
		#if windows
		configPath += "/plugins/alsoft.ini";
		#elseif mac
		configPath = Path.directory(configPath) + "/Resources/plugins/alsoft.conf";
		#else
		configPath += "/plugins/alsoft.conf";
		#end

		Sys.putEnv("ALSOFT_CONF", configPath);
	}
	#end
}

// class ALSoftProtection
// {
// 	macro static function check():Expr
// 	{
// 		var origin:String = #if hl Sys.getCwd() #else Sys.programPath() #end;
// 		var configPath:String = Path.directory(Path.withoutExtension(origin));
// 		#if windows
// 		configPath += "/plugins/alsoft.ini";
// 		#elseif mac
// 		configPath = Path.directory(configPath) + "/Resources/plugins/alsoft.conf";
// 		#else
// 		configPath += "/plugins/alsoft.conf";
// 		#end

// 		if (!File.exists(configPath))
// 		{
// 			var defaultConfig:String = "
// [general]
// channels=stereo
// sample-type=float32
// stereo-mode=speakers
// stereo-encoding=panpot
// hrtf=false
// cf_level=0
// resampler=fast_bsinc24
// front-stablizer=false
// output-limiter=false
// volume-adjust=0
// [decoder]
// hq-mode=false
// distance-comp=false
// nfc=false
// 			";
// 			File.saveContent(configPath, defaultConfig);
// 		}
// 		return macro true;
// 	}
// }
