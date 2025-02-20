package backend;

#if sys
import sys.FileSystem;
import states.TitleState;
class CommandLineHandler {
	public static function parseCommandLine(cmd:Array<String>) {
		var i:Int = 0;
		while(i < cmd.length) {
			switch(cmd[i]) {
				case null:
					break;
				case "-h" | "-help" | "help":
					Sys.println("-- Mixtape Engine Command Line help \n[Credits to Codename] --");
					Sys.println("-help                | Show this help");
					#if MOD_SUPPORT
					Sys.println("-mod [mod name]      | Load a specific mod");
					Sys.println("-modfolder [path]    | Sets the mod folder path");
					Sys.println("-addonsfolder [path] | Sets the addons folder path");
					#end
					Sys.println("-nocolor             | Disables colors in the terminal");
					Sys.println("-nogpubitmap         | Forces GPU only bitmaps off");
					Sys.exit(0);
				#if MOD_SUPPORT
				case "-m" | "-mod" | "-currentmod":
					i++;
					var arg = cmd[i];
					if (arg == null) {
						Sys.println("[ERROR] You need to specify the mod name");
						Sys.exit(1);
					} else {
						Main.modToLoad = arg.trim();
					}
				#end
				case "-nocolor":
					Main.noTerminalColor = true;
				case "-nogpubitmap":
					Main.forceGPUOnlyBitmapsOff = true;
				case "-livereload":
					// do nothing
				case '-playtest':
					Main.playTest = true;
				default:
					Sys.println("Unknown command");
			}
			i++;
		}
	}
}
#end