package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.addons.display.FlxRuntimeShader;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;


#if MODS_ALLOWED
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var IMAGE_EXT = "png";
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static final HSCRIPT_EXTENSIONS:Array<String> = ["hscript", "hxs", "hx"];
	public static final LUA_EXTENSIONS:Array<String> = ["lua"];
	public static final SCRIPT_EXTENSIONS:Array<String> = [
		"hscript",
		"hxs",
		"hx",
		#if LUA_ALLOWED "lua" #end]; // TODo: initialize this by combining the top 2 vars ^

	// Troll Engine Things
	public static function getFileWithExtensions(scriptPath:String, extensions:Array<String>) {
		for (fileExt in extensions) {
			var baseFile:String = '$scriptPath.$fileExt';
			for (file in [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getSharedPath(baseFile)]) {
				if (Paths.exists(file))
					return file;
			}
		}

		return null;
	}

	public static function isHScript(file:String){
		for(ext in Paths.HSCRIPT_EXTENSIONS)
			if(file.endsWith('.$ext'))
				return true;
		
		return false;
	}
	public inline static function getHScriptPath(scriptPath:String)
	{
		#if HSCRIPT_ALLOWED
		return getFileWithExtensions(scriptPath, Paths.HSCRIPT_EXTENSIONS);
		#else
		return null;
		#end
	}

	public inline static function getLuaPath(scriptPath:String) {
		#if LUA_ALLOWED
		return getFileWithExtensions(scriptPath, Paths.LUA_EXTENSIONS);
		#else
		return null;
		#end
	}

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			//trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
					//trace('deleted $key');
				}
			}
		}
	}

	/** returns a FlxRuntimeShader but with file names lol **/ 
	public static function getShader(fragFile:String = null, vertFile:String = null, version:Int = 120):FlxRuntimeShader
	{
		try{
			var fragPath:Null<String> = fragFile==null ? null : shaderFragment(fragFile);
			var vertPath:Null<String> = vertFile==null ? null : shaderVertex(vertFile);

			return new FlxRuntimeShader(
				fragFile==null ? null : File.getContent(fragPath), 
				vertFile==null ? null : File.getContent(vertPath),
				//version
			);
		}catch(e:Dynamic){
			trace("Shader compilation error:" + e.message);
		}

		return null;		
	}

	inline static public function getFolders(dir:String, ?modsOnly:Bool = false){
		#if !MODS_ALLOWED
		return [Paths.getShadersPath('$dir/')];
		
		#else
		var foldersToCheck:Array<String> = [
			Paths.mods(Mods.currentModDirectory + '/$dir/'),
			Paths.mods('$dir/'),
			Paths.modFolders('$dir/'),
		];

		if(!modsOnly)
			foldersToCheck.push(Paths.getSharedPath('$dir/'));

		return foldersToCheck;
		#end
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function crawlDirectoryOG(directoryPath:String, fileExtension:String, ?targetArray:Array<String>):Array<String> {
		var result:Array<String> = targetArray != null ? targetArray : [];
		var recurrsion = 0;
		var fileCount = 0;
		for (folder in FileSystem.readDirectory(FileSystem.absolutePath(directoryPath))) {
			if (FileSystem.isDirectory('$directoryPath/$folder')) {
				recurrsion++;
				var subDirectoryResult = crawlDirectoryOG('$directoryPath/$folder', fileExtension, result);
				if (targetArray == null) {
					result = result.concat(subDirectoryResult);
				}
			} else {
				if (folder.endsWith(fileExtension)) {
					fileCount++;
					result.push(directoryPath+'/'+folder);                    
				}
			}
		}
		//trace('Crawled directory: ${directoryPath}, and found ${fileCount} files with extension ${fileExtension}. Total files found: ${result.length}');
		//trace('Files found: ${result}');
		//trace('Recursion: $recurrsion');
		return result;
	}

	public static function crawlDirectory(directoryPath:String, fileExtension:String, ?targetArray:Array<String> = null):Array<String> {
		var result:Array<String> = targetArray != null ? targetArray : [];
		var recursion = 0;
		var fileCount = 0;
		try {
			for (folder in FileSystem.readDirectory(directoryPath)) {
				var fullPath = directoryPath + '/' + folder; // Construct the full path
				if (FileSystem.isDirectory(fullPath)) {
					recursion++;
					// Do not pass 'result' to the recursive call
					var subDirectoryResult = crawlDirectory(fullPath, fileExtension);
					// Concatenate the results after the call returns
					result = result.concat(subDirectoryResult);
				} else {
					if (folder.endsWith(fileExtension)) {
						fileCount++;
						result.push(fullPath); // Add the full path to the result
					}
				}
			}
			//trace('Crawled directory: ${directoryPath}, and found ${fileCount} files with extension ${fileExtension}. Total files found: ${result.length}');
			//trace('Recursion: $recursion');
		} catch (e:Dynamic) {
			//trace('Error crawling directory: $e');
		}
		return result;
	}

	public static function crawlMulti(directoryPaths:Array<String>, fileExtension:String, ?targetArray:Array<String> = null, ?OG:Bool = false):Array<String> {
		var result:Array<String> = targetArray != null ? targetArray : [];
		var skipList:Array<String> = [];
		
		for (directoryPath in directoryPaths) {
			var skip:Bool = false;
			
			// Check if the directoryPath is a subdirectory of any path in result
			for (existingPath in result) {
				if (directoryPath.startsWith(existingPath)) {
					skipList.push(directoryPath);
					trace('Adding to skiplist: ' + directoryPath);
					skip = true;
					break;
				}
			}
			
			if (skip) {
				trace('Skipping: ' + directoryPath);
				continue;
			}
			
			if (OG)
				result = crawlDirectoryOG(directoryPath, fileExtension, result);
			else {
				result = crawlDirectory(directoryPath, fileExtension, result);
			}
		}
		
		return result;
	}

	public static function crawlDirectoryAlt(directoryPath:String, fileExtension:String, ?targetArray:Array<String>):Array<String> {
		// Helper function with an additional parameter for counting subdirectories
		function crawl(directoryPath:String, fileExtension:String, result:Array<String>, subdirectoryCount:Int):Array<String> {
			for (folder in FileSystem.readDirectory(FileSystem.absolutePath(directoryPath))) {
				if (FileSystem.isDirectory('$directoryPath/$folder')) {
					// Increment the subdirectory count
					result = crawl('$directoryPath/$folder', fileExtension, result, subdirectoryCount + 1);
				} else {
					if (folder.endsWith(fileExtension)) {
						result.push(directoryPath+'/'+folder);                    
					}
				}
			}
			// Trace the count at the root level of recursion
			if (subdirectoryCount == 0) {
			// trace('Total subdirectories crawled in: ${directoryPath} = ${subdirectoryCount}');
			}
			return result;
		}

		// Initialize the helper function with a subdirectory count of 0
		return crawl(directoryPath, fileExtension, targetArray != null ? targetArray : [], 0);
	}

	public static function url(url:String):String {
		// Basic validation (consider more robust validation/sanitization)
		if (!isValidUrl(url)) {
			throw "Invalid URL";
		}

		var curlCommand = "curl -s " + '"' + url + '"'; // -s for silent mode
		try {
			var process = new Process("curl", [url]);
			var output = process.stdout.readAll().toString();
			process.close();
			return output;
		} catch (e:Dynamic) {
			// Handle or log the error
			trace('Error executing curl command: $e');
			return null; // or handle as appropriate
		}
	}

	public static function connectWebSocket(url:String):hx.ws.WebSocket {
		if (!isValidUrl(url)) {
			throw "Invalid URL";
		}

		// Not to be used, at least not yet.

		var ws = new hx.ws.WebSocket(url);
		ws.onopen = function() {
			trace("WebSocket connection opened");
		};
		ws.onmessage = function(event) {
			trace("Message received: " + event);
		};
		ws.onclose = function() {
			trace("WebSocket connection closed from:" + url);
		};
		ws.onerror = function(event) {
			trace("WebSocket error: " + event.message);
		};
		return ws;
	}

	// Basic URL validation (implement a more comprehensive check)
	static function isValidUrl(url:String):Bool {
		return url.startsWith("http://") || url.startsWith("https://") || isValidIp(url);
	}

	// Basic IP address validation
	static function isValidIp(ip:String):Bool {
		var ipPattern:EReg = ~/^((25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})\.){3}(25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})$/;
		return ipPattern.match(ip);
	}


	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);
		
		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	static public function exists(someString:String):Bool
	{
		var toRet:Bool = false;
		if (OpenFlAssets.exists(someString))
		{
			toRet = true;
		}
		return toRet;
	}

	public static function getGraphic(path:String, cache:Bool = true, gpu:Bool = false):Null<FlxGraphic>
	{
		var newGraphic:FlxGraphic = cache ? currentTrackedAssets.get(path) : null;
		if (newGraphic == null) {
			var bitmap:BitmapData = getBitmapData(path);
			if (bitmap == null) return null;

			if (gpu) {
				var texture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
				texture.uploadFromBitmapData(bitmap);
				bitmap.image.data = null;
				bitmap.dispose();
				bitmap = BitmapData.fromTexture(texture);
			}

			newGraphic = FlxGraphic.fromBitmapData(bitmap, false, path, cache);
			newGraphic.persist = true;
			newGraphic.destroyOnNoUse = false;

			if (cache) {
				localTrackedAssets.push(path);
				currentTrackedAssets.set(path, newGraphic);
			}
		}

		return newGraphic;
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	inline public static function cacheGraphic(path:String):Null<FlxGraphic>
		return getGraphic(path, true);

	inline public static function imagePath(key:String):String
		return getPath('images/$key.$IMAGE_EXT');

	inline public static function imageExists(key:String):Bool
		return Paths.exists(imagePath(key));

	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/$key') + '.png';
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, IMAGE, parentFolder, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null)
			{
				trace('Bitmap not found: $file | key: $key');
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	public static function returnGraphic(key:String, ?library:String):Null<FlxGraphic>
	{
		var path:String = imagePath(key);

		if (currentTrackedAssets.exists(path)) {
			if (!localTrackedAssets.contains(path)) 
				localTrackedAssets.push(path);

			return currentTrackedAssets.get(path);
		}

		var graphic = getGraphic(path);
		if (graphic==null)
			trace('bitmap "$key" => "$path" returned null.');

		return graphic;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, !ignoreMods);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	public static function getBitmapData(path:String):Null<BitmapData> {
		#if sys
		if (FileSystem.exists(path))
			return BitmapData.fromFile(path);
		#end

		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			return BitmapData.fromFile(path);
		else #end if (OpenFlAssets.exists(path, IMAGE))
			return OpenFlAssets.getBitmapData(path);

		return null;
	}

	inline public static function getSound(path:String):Null<Sound> {
		#if sys
		if (FileSystem.exists(path))
			return Sound.fromFile(path);
		#else
		if(OpenFlAssets.exists(path, SOUND))
			OpenFlAssets.getSound(path);
		#end

		return null;
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, parentFolder, true);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder, true);
			if(OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, parentFolder);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		if(key.contains('psychic')) trace(key, parentFolder, allowGPU);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			#if sys
			if(FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	inline public static function soundPath(path:String, key:String, ?library:String)
	{
		return getPath('$path/$key.$SOUND_EXT');
	}

	public static function returnSoundCache(path:String, key:String, ?library:String)
	{
		var gottenPath:String = soundPath(path, key, library);
	
		if (currentTrackedSounds.exists(gottenPath)) {
			if (!localTrackedAssets.contains(gottenPath))
				localTrackedAssets.push(gottenPath);

			return currentTrackedSounds.get(gottenPath);
		}
		
		var sound = getSound(gottenPath);
		if (sound != null) {
			currentTrackedSounds.set(gottenPath, sound);
	
			if (!localTrackedAssets.contains(gottenPath))
				localTrackedAssets.push(gottenPath);	
			
			return sound;
		}
		
		trace('sound $path, $key => $gottenPath returned null');
		
		return null;
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if(!changedAnimJson)
			{
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	public static function file(file:String, type:AssetType = TEXT, ?library:String):String {
		return getPath(file, type, library);
	}

	static final audioExtension:String = "ogg";
    inline static public function file2(key:String, location:String, extension:String, ?startFolder:String = 'assets/shared'):String{
        var data:String = '$startFolder/$location/$key.$extension';
        return data;
    }

	static public function doesImageAssetExist(path:String)
	{
		if (path == null || path == "")
			return false;
		return OpenFlAssets.exists(path, AssetType.IMAGE);
	}
}
