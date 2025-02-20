package objects;

import sys.io.File;
import sys.FileSystem;
import haxe.Timer;

class FileLoader {
	public var filePath:String;
	public var fileContent:String;
	private var watcher:FileWatcher;
    
    public function new(filePath:String, liveUpdate:Bool = true) {
        this.filePath = filePath;
        this.fileContent = loadFileContent(filePath);
        if (liveUpdate) {
            this.watcher = new FileWatcher(filePath, updateContent);
        }
    }

	private function loadFileContent(filePath:String):String {
		try {
			return File.getContent(filePath);
		} catch (e:Dynamic) {
			trace('Error reading file: ' + e);
			return null;
		}
	}

	private function updateContent(newContent:String):Void {
		this.fileContent = newContent;
		trace('File content updated: ' + newContent);
	}

	public function getContent():String {
		return fileContent;
	}

	public function edit(newContent:String):Void {
		try {
			var file = File.write(filePath, false);
			file.writeString(newContent);
			file.close();
			this.fileContent = newContent;
			trace('File content edited: ' + newContent);
		} catch (e:Dynamic) {
			trace('Error writing to file: ' + e);
		}
	}

	public function append(newContent:String):Void {
		try {
			var file = File.write(filePath, true); // Open file in append mode
			file.writeString(newContent);
			file.close();
			this.fileContent += newContent; // Append new content to existing content
			trace('File content appended: ' + newContent);
		} catch (e:Dynamic) {
			trace('Error appending to file: ' + e);
		}
	}
}

class FileWatcher {
	private var filePath:String;
	private var lastModified:Date;
	private var callback:Dynamic->Void;
	private var timer:Timer;

	public function new(filePath:String, callback:Dynamic->Void) {
		this.filePath = filePath;
		this.callback = callback;
		this.lastModified = FileSystem.stat(filePath).mtime;
		this.timer = new Timer(1000); // Check every second
		this.timer.run = checkFile;
	}

	private function checkFile():Void {
		var currentModified = FileSystem.stat(filePath).mtime;
		if (currentModified != lastModified) {
			lastModified = currentModified;
			var content = File.getContent(filePath);
			callback(content);
		}
	}

	public function stop():Void {
		timer.stop();
	}
}

