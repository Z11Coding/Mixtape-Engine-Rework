package backend;

import flixel.system.FlxSound;
import haxe.Json;
import haxe.zip.*;
import haxe.io.Path;
import backend.Song;

class FNFC {
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var song:Dynamic;

    public function new() {
        inst = new FlxSound();
        vocals = new FlxSound();
        song = Song.loadFromJson(this.song);
    }
    // Will punch later.
	//public function loadFromSource(sourcePath:String):Void {
	//	if (sourcePath.endsWith(".zip") || sourcePath.endsWith(".fnfc")) {
	//		var extractedFiles:Entry = Reader.unzip(File.getBytes(Reader.readZip(sourcePath)));
	//		for (file in extractedFiles) {
	//			if (file.endsWith("inst.mp3")) {
	//				this.inst.loadEmbedded(file, true);
	//			} else if (file.endsWith("vocals.mp3")) {
	//				this.vocals.loadEmbedded(file, true);
	//			} else if (file.endsWith(".json")) {
	//				var jsonData = File.getContent(file);
	//				this.song = Song.loadFromJson(jsonData);
	//			}
	//		}
	//	} else if (FileSystem.exists(sourcePath) && FileSystem.isDirectory(sourcePath)) {
	//		// Load directly from folder
	//		var instPath = Path.join([sourcePath, "inst.mp3"]);
	//		var vocalsPath = Path.join([sourcePath, "vocals.mp3"]);
	//		var jsonPath = Path.join([sourcePath, "song.json"]); // Assuming a fixed name for simplicit
	//		if (FileSystem.exists(instPath)) this.inst.loadEmbedded(instPath, true);
	//		if (FileSystem.exists(vocalsPath)) this.vocals.loadEmbedded(vocalsPath, true);
	//		if (FileSystem.exists(jsonPath)) {
	//			var jsonData = File.getContent(jsonPath);
	//			this.song = Song.loadFromJson(jsonData);
	//		}
	//	} else {
	//		throw "Source path does not exist or is not supported.";
	//	}
	//}
//
	//public function play():Void {
	//	PlayState.SONG = this.song;
	//	PlayState.fnfc = true;
	//	PlayState.fnfcData = this; // Assuming you want to pass the entire FNFC instance
	//	// Play inst and vocals
    //}
}

