package hxpy.macros;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;

/**
 * Custom override of hxpy CopyFiles macro
 * Copies Python files to bin/python instead of directly to bin
 */
class CopyFiles {
	public static macro function run():Expr {
		var process:Process = new Process('haxelib libpath hxpy');
		var libPath:String = process.stdout.readLine();
		var outputFolder:String = Compiler.getOutput();
		var binFolder:String = outputFolder; // Store original bin folder for cleanup

		if(Context.defined("lime")){
			outputFolder = outputFolder.replace("obj", "bin");
			binFolder = outputFolder;
		}

		// Add python subdirectory for better organization
		outputFolder = haxe.io.Path.join([outputFolder, "python"]);

		process.close();

		var copiedFiles = copyFiles('$libPath/package', outputFolder);

		// Handle DLL files specially - copy them to both locations for runtime access
		copyDllsForRuntime('$libPath/package', binFolder, outputFolder);

		cleanupOldFiles(binFolder, copiedFiles);
		return macro null;
	}

	public static function copyFiles(start:String, destination:String):Array<String> {
		if (!FileSystem.exists(destination)) {
			FileSystem.createDirectory(destination);
		}

		var copiedFiles:Array<String> = [];

		for (file in FileSystem.readDirectory(start)) {
			var filePath:String = '$start/$file';
			var destPath:String = '$destination/$file';

			if (!FileSystem.exists(destPath)) {
				File.copy(filePath, destPath);
			}
      copiedFiles.push(file);
		}


		// Log where files were copied for debugging
		trace('Python files copied to: $destination');
		return copiedFiles;
	}

	public static function copyDllsForRuntime(start:String, binFolder:String, pythonFolder:String) {
		if (!FileSystem.exists(start)) return;

		trace('DLL Copy: Checking for Python DLLs to copy to main bin folder');

		for (file in FileSystem.readDirectory(start)) {
			var filePath:String = '$start/$file';

			// Look for Python DLL files (python313.dll, python3.dll, etc.)
			if (file.toLowerCase().endsWith('.dll') && file.toLowerCase().contains('python')) {
				var binDllPath = haxe.io.Path.join([binFolder, file]);
				var pythonDllPath = haxe.io.Path.join([pythonFolder, file]);

				trace('DLL Copy: Found Python DLL: $file');

				// Copy to main bin folder for runtime access
				try {
					if (!FileSystem.exists(binDllPath) || !filesAreIdentical(filePath, binDllPath)) {
						File.copy(filePath, binDllPath);
						trace('DLL Copy: Copied $file to main bin folder for runtime access');
					}
				} catch (e:Dynamic) {
					trace('Warning: Could not copy DLL to main bin: $e');
				}

				// Also ensure it's in the python folder
				try {
					if (!FileSystem.exists(pythonDllPath) || !filesAreIdentical(filePath, pythonDllPath)) {
						File.copy(filePath, pythonDllPath);
						trace('DLL Copy: Ensured $file is in python folder');
					}
				} catch (e:Dynamic) {
					trace('Warning: Could not copy DLL to python folder: $e');
				}
			}
		}
	}

  // You're welcome, Z11Gaming.
	public static function cleanupOldFiles(binFolder:String, copiedFiles:Array<String>) {
		trace('Cleanup: Starting cleanup in binFolder: $binFolder');
		trace('Cleanup: Looking for ${copiedFiles.length} files: ${copiedFiles.join(", ")}');

		if (!FileSystem.exists(binFolder)) {
			trace('Cleanup: binFolder does not exist: $binFolder');
			return;
		}

		var cleanedCount = 0;

		for (fileName in copiedFiles) {
			// Skip DLL files - they need to be in both locations for runtime access
			if (fileName.toLowerCase().endsWith('.dll') && fileName.toLowerCase().contains('python')) {
				trace('Cleanup: Skipping Python DLL cleanup: $fileName (needed in both locations)');
				continue;
			}

			var oldFilePath = haxe.io.Path.join([binFolder, fileName]);
			var newFilePath = haxe.io.Path.join([binFolder, "python", fileName]);

			// trace('Cleanup: Checking old file: $oldFilePath');
			// trace('Cleanup: Checking new file: $newFilePath');

			if (FileSystem.exists(oldFilePath)) {
				trace('Cleanup: Old file exists: $oldFilePath');
				if (FileSystem.exists(newFilePath)) {
					// trace('Cleanup: New file exists: $newFilePath');
					if (filesAreIdentical(oldFilePath, newFilePath)) {
						trace('Cleanup: Files are identical, deleting old file');
						try {
							FileSystem.deleteFile(oldFilePath);
							cleanedCount++;
							trace('Cleanup: Successfully deleted: $oldFilePath');
						} catch (e:Dynamic) {
							trace('Warning: Could not clean up old file: $oldFilePath - $e');
						}
					} else {
						trace('Warning: Skipping cleanup of $fileName - files are different');
					}
				} else {
					trace('Cleanup: New file does not exist: $newFilePath');
				}
			} else {
				// trace('Cleanup: Old file does not exist: $oldFilePath');
			}
		}

		if (cleanedCount > 0) {
			trace('Cleaning old litter: removed $cleanedCount Python files from bin directory');
      trace("You're welcome, Z11Gaming.");
		} else {
			trace('Cleanup: No files were cleaned up');
		}
	}

	public static function filesAreIdentical(file1:String, file2:String):Bool {
		try {
			var bytes1 = File.getBytes(file1);
			var bytes2 = File.getBytes(file2);

			if (bytes1.length != bytes2.length) {
				return false;
			}

			for (i in 0...bytes1.length) {
				if (bytes1.get(i) != bytes2.get(i)) {
					return false;
				}
			}

			return true;
		} catch (e:Dynamic) {
			trace('Warning: Could not compare files $file1 and $file2 - $e');
			return false;
		}
	}
}
