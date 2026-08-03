package yutautil.gamebanana;

import backend.util.ZipUtils;

#if sys
import sys.FileSystem;
#end

enum GameBananaArchiveType {
	ZIP;
	RAR;
	SEVEN_Z;
	UNKNOWN;
}

typedef GameBananaArchiveSupport = {
	var zip:Bool;
	var rar:Bool;
	var sevenZip:Bool;
}

typedef GameBananaArchiveExtractResult = {
	var success:Bool;
	var archiveType:GameBananaArchiveType;
	var message:String;
}

class GameBananaArchiveHandler {
	public static function detectArchiveType(fileName:String):GameBananaArchiveType {
		if (fileName == null) return UNKNOWN;
		var lower = fileName.toLowerCase();
		if (lower.endsWith(".zip")) return ZIP;
		if (lower.endsWith(".rar")) return RAR;
		if (lower.endsWith(".7z")) return SEVEN_Z;
		return UNKNOWN;
	}

	public static function getSupport():GameBananaArchiveSupport {
		return {
			zip: true,
			rar: commandExists("unrar") || commandExists("rar") || commandExists("7z"),
			sevenZip: commandExists("7z") || commandExists("7za")
		};
	}

	public static function extractArchive(archivePath:String, destination:String):GameBananaArchiveExtractResult {
		var archiveType = detectArchiveType(archivePath);
		#if !sys
		return {
			success: false,
			archiveType: archiveType,
			message: "Archive extraction requires sys target"
		};
		#else
		if (!FileSystem.exists(archivePath)) {
			return {
				success: false,
				archiveType: archiveType,
				message: 'Archive does not exist: $archivePath'
			};
		}

		if (!FileSystem.exists(destination)) {
			FileSystem.createDirectory(destination);
		}

		return switch (archiveType) {
			case ZIP:
				extractZip(archivePath, destination);
			case RAR:
				extractRar(archivePath, destination);
			case SEVEN_Z:
				extract7z(archivePath, destination);
			case UNKNOWN:
				{
					success: false,
					archiveType: UNKNOWN,
					message: "Unsupported archive type"
				};
		}
		#end
	}

	#if sys
	private static function extractZip(archivePath:String, destination:String):GameBananaArchiveExtractResult {
		try {
			var zip = ZipUtils.openZip(archivePath);
			var prog = ZipUtils.uncompressZip(zip, destination);
			if (prog.error != null) {
				return {
					success: false,
					archiveType: ZIP,
					message: 'ZIP extraction failed: ${prog.error}'
				};
			}
			return {
				success: true,
				archiveType: ZIP,
				message: "ZIP extracted successfully"
			};
		} catch (e:Dynamic) {
			return {
				success: false,
				archiveType: ZIP,
				message: 'ZIP extraction error: $e'
			};
		}
	}

	private static function extractRar(archivePath:String, destination:String):GameBananaArchiveExtractResult {
		if (commandExists("unrar")) {
			var exit = runExtractCommand('unrar x -o+ "' + archivePath + '" "' + destination + '"');
			if (exit == 0) return {success: true, archiveType: RAR, message: "RAR extracted with unrar"};
		}
		if (commandExists("7z")) {
			var exit = runExtractCommand('7z x -y -o"' + destination + '" "' + archivePath + '"');
			if (exit == 0) return {success: true, archiveType: RAR, message: "RAR extracted with 7z"};
		}
		return {
			success: false,
			archiveType: RAR,
			message: "RAR extraction requires unrar or 7z installed"
		};
	}

	private static function extract7z(archivePath:String, destination:String):GameBananaArchiveExtractResult {
		if (commandExists("7z")) {
			var exit = runExtractCommand('7z x -y -o"' + destination + '" "' + archivePath + '"');
			if (exit == 0) return {success: true, archiveType: SEVEN_Z, message: "7Z extracted with 7z"};
		}
		if (commandExists("7za")) {
			var exit = runExtractCommand('7za x -y -o"' + destination + '" "' + archivePath + '"');
			if (exit == 0) return {success: true, archiveType: SEVEN_Z, message: "7Z extracted with 7za"};
		}
		return {
			success: false,
			archiveType: SEVEN_Z,
			message: "7Z extraction requires 7z or 7za installed"
		};
	}

	private static function commandExists(command:String):Bool {
		#if windows
		var exit = Sys.command('where ' + command + ' >nul 2>nul');
		#else
		var exit = Sys.command('which ' + command + ' >/dev/null 2>/dev/null');
		#end
		return exit == 0;
	}

	private static function runExtractCommand(command:String):Int {
		trace('GameBananaArchiveHandler running: ' + command);
		return Sys.command(command);
	}
	#else
	private static function commandExists(_command:String):Bool {
		return false;
	}
	#end
}
