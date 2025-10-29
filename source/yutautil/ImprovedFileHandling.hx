package yutautil;

import dialogs.Dialogs as FilePopup;
import dialogs.Dialogs.FileFilter;
import haxe.Json;
import haxe.ds.StringMap;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

enum ReadType
{
	Text;
	ByteData;
}

abstract Filter(FileFilter) from FileFilter to FileFilter
{
	public inline function new(ext:String, ?desc:String)
	{
		this = {
			ext: ext,
			desc: desc != null ? desc : '${ext.toUpperCase()} File'
		}
	}

	@:from static inline function fromObject(obj:{ext:String, ?desc:String}):Filter
	{
		return new Filter(obj.ext, obj.desc);
	}

	@:from static inline function fromOpenFLFilter(filter:openfl.net.FileFilter):Filter
	{
		return new Filter(filter.extension, filter.description);
	}

	public var ext(get, never):String;
	public var desc(get, never):String;

	function get_ext():String
		return this.ext;

	function get_desc():String
		return this.desc;
}

class ImprovedFileHandling
{
	public static var lastPath:String = "";

	public static function openFile(title:String, ?filters:OneOrMore<Filter>, ?preserve_cwd:Bool = true):String
	{
		if (filters != null)
		{
			for (filter in filters)
			{
				var f:FileFilter = filter;
				f.desc = f.desc != null ? f.desc : f.ext.toUpperCase() + " File";
			}
		}
		return FilePopup.open(title, cast filters, preserve_cwd);
	}

	public static function saveFile(title:String, ?filter:Filter, ?preserve_cwd:Bool = true):String
	{
		if (filter != null)
		{
			var f:FileFilter = filter;
			f.desc = f.desc != null ? f.desc : '${f.ext.toUpperCase()} File';
		}
		var filePath = FilePopup.save(title, cast filter, preserve_cwd);
		if (filePath != null && filter != null)
		{
			var f:FileFilter = filter;
			var ext = "." + f.ext;
			if (!filePath.endsWith(ext))
			{
				if (filePath.endsWith("."))
				{
					filePath += f.ext;
				}
				else
				{
					filePath += ext;
				}
			}
			lastPath = filePath;
		}
		return filePath;
	}

	public static function selectFolder(title:String, ?preserve_cwd:Bool = true):String
	{
		return FilePopup.folder(title, preserve_cwd).trim();
	}

	public static function loadFile(title:String, ?filters:OneOrMore<Filter>, readType:ReadType, ?operation:Dynamic->Dynamic, ?preserve_cwd:Bool = true):Dynamic
	{
		if (filters != null)
		{
			for (filter in filters)
			{
				var f:FileFilter = filter;
				f.desc = f.desc != null ? f.desc : '${f.ext.toUpperCase()} File';
			}
		}
		var filePath = openFile(title, filters, preserve_cwd);
		if (filePath != null && filePath.trim() != "")
		{
			lastPath = filePath;
			return
				operation != null ? operation(readType == ReadType.ByteData ? File.getBytes(filePath) : File.getContent(filePath)) : (readType == ReadType.ByteData ? File.getBytes(filePath) : File.getContent(filePath));
		}
		return null;
	}

		public static function saveOperation(title:String, ?filter:Filter, writeType:ReadType, data:Dynamic, ?preserve_cwd:Bool = true):Bool
		{
			if (filter != null)
			{
				var f:FileFilter = filter;
				f.desc = f.desc != null ? f.desc : '${f.ext.toUpperCase()} File';
			}
			var filePath = saveFile(title, filter, preserve_cwd);
			if (filePath != null && filePath.trim() != "")
			{
				var f:FileFilter = filter;
				var ext = "." + f.ext;
				if (!filePath.endsWith(ext))
				{
					if (filePath.endsWith("."))
					{
						filePath += f.ext;
					}
					else
					{
						filePath += ext;
					}
				}

				// Check if file exists and compare content before writing
				var existingData:Dynamic = null;
				if (FileSystem.exists(filePath))
				{
					existingData = writeType == ReadType.ByteData ? File.getBytes(filePath) : File.getContent(filePath);
				}

				// Only write if data is different
				var dataChanged:Bool = existingData == null || !compareData(writeType, existingData, data);
				if (dataChanged)
				{
					writeType == ReadType.ByteData ? File.saveBytes(filePath, data) : File.saveContent(filePath, data);
				}

				lastPath = filePath;
			}
			return filePath != null && filePath != "" && FileSystem.exists(filePath) ? (FileSystem.exists(filePath) && (writeType == ReadType.ByteData ? haxe.crypto.Base64.encode(File.getBytes(filePath)) == haxe.crypto.Base64.encode(data) : File.getContent(filePath) == data)) : false;
		}

		static function compareData(writeType:ReadType, existing:Dynamic, newData:Dynamic):Bool
			return writeType == ReadType.ByteData ? haxe.crypto.Base64.encode(existing) == haxe.crypto.Base64.encode(newData) : existing == newData;


	/**
	 * Saves multiple files. The first file is the main file, and extra files are objects with {name, data}.
	 * @param title Dialog title
	 * @param filter File filter
	 * @param writeType ReadType.ByteData or ReadType.Text
	 * @param mainData Main file data
	 * @param extraFiles Array of {name:String, data:Dynamic} for extra files
	 * @param preserve_cwd Preserve current working directory
	 * @return Array of saved file paths (main file first, then extra files)
	 */
	public static function multiSaveOperation(title:String, ?filter:Filter, writeType:ReadType, mainData:Dynamic,
			?extraFiles:Array<{name:String, data:Dynamic}>, ?preserve_cwd:Bool = true):Bool
	{
		if (filter != null)
		{
			var f:FileFilter = filter;
			f.desc = f.desc != null ? f.desc : '${f.ext.toUpperCase()} File';
		}
		var filePaths:Array<String> = [];

		// Save main file
		var mainFilePath = saveFile(title, filter, preserve_cwd);
		if (mainFilePath != null && mainFilePath.trim() != "")
		{
			var f:FileFilter = filter;
			var ext = "." + f.ext;
			if (!mainFilePath.endsWith(ext))
			{
				if (mainFilePath.endsWith("."))
				{
					mainFilePath += f.ext;
				}
				else
				{
					mainFilePath += ext;
				}
			}
			writeType == ReadType.ByteData ? File.saveBytes(mainFilePath, mainData) : File.saveContent(mainFilePath, mainData);
			lastPath = mainFilePath;
			filePaths.push(mainFilePath);

			// Save extra files in the same directory as the main file
			if (extraFiles != null)
			{
				var dir = Path.directory(mainFilePath);
				for (extra in extraFiles)
				{
					var extraPath = Path.join([dir, extra.name]);
					if (!extraPath.endsWith(ext))
					{
						if (extraPath.endsWith("."))
						{
							extraPath += f.ext;
						}
						else
						{
							extraPath += ext;
						}
					}
					writeType == ReadType.ByteData ? File.saveBytes(extraPath, extra.data) : File.saveContent(extraPath, extra.data);
					filePaths.push(extraPath);
				}
			}
		}
		return checkFilesExist(filePaths);
	}

	public static function checkFileExists(filePath:String):Bool
	{
		return FileSystem.exists(filePath);
	}

	public static function checkFilesExist(filePaths:Array<String>):Bool
	{
		for (filePath in filePaths)
		{
			if (!FileSystem.exists(filePath))
			{
				return false;
			}
		}
		return true;
	}
}

/**
 * Dynamically manages a file's content, keeping it in sync with disk.
 * Supports reading, writing, removing, and auto-reloading.
 * Uses FlxBasic's update for polling.
 */
class DynamicFileStream extends flixel.FlxBasic
{
	public var path:String;
	public var data:Dynamic;
	public var throwOnDelete:Bool;
	public var pollInterval:Int;

	var _lastModified:Float;
	var _pollCounter:Int = 0;

	/**
	 * @param filePath Path to the file.
	 * @param throwOnDelete If true, throws if file is deleted externally.
	 * @param pollInterval Polling interval in ms (default 500).
	 */
	public function new(filePath:String, ?throwOnDelete:Bool = false, ?pollInterval:Int = 500)
	{
		super();
		path = filePath;
		this.throwOnDelete = throwOnDelete;
		this.pollInterval = pollInterval;
		_lastModified = -1;
		load();
	}

	override public function update(elapsed:Float):Void
	{
		// Convert elapsed to ms and accumulate
		_pollCounter += Std.int(elapsed * 1000);
		if (_pollCounter >= pollInterval)
		{
			_pollCounter = 0;
			if (!sys.FileSystem.exists(path))
			{
				if (throwOnDelete)
					throw 'File "$path" was deleted externally.';
				data = null;
				_lastModified = -1;
				return;
			}
			var stat:sys.FileStat = sys.FileSystem.stat(path);
			if (stat.mtime.getTime() != _lastModified)
			{
				load();
			}
		}
	}

	public function load():Void
	{
		if (sys.FileSystem.exists(path))
		{
			data = sys.io.File.getContent(path);
			_lastModified = sys.FileSystem.stat(path).mtime.getTime();
		}
		else
		{
			data = null;
			_lastModified = -1;
		}
	}

	public function write(newData:Dynamic):Void
	{
		data = newData;
		sys.io.File.saveContent(path, Std.string(newData));
		_lastModified = sys.FileSystem.stat(path).mtime.getTime();
	}

	public function remove():Void
	{
		if (sys.FileSystem.exists(path))
		{
			sys.FileSystem.deleteFile(path);
			data = null;
			_lastModified = -1;
		}
	}
}

/**
 * Typed dynamic file stream for FlxBasic, e.g. for JSON files.
 * Keeps the file in sync with a typed structure.
 */
class TypedDynamicFileStream<T> extends DynamicFileStream
{
	public var typedData(get, set):T;

	public function new(filePath:String, ?throwOnDelete:Bool = false, ?pollInterval:Int = 500)
	{
		super(filePath, throwOnDelete, pollInterval);
	}

	override public function load():Void
	{
		if (sys.FileSystem.exists(path))
		{
			var content:String = sys.io.File.getContent(path);
			try
			{
				data = Json.parse(content);
			}
			catch (e:Dynamic)
			{
				// Try to distinguish between invalid JSON and field mismatch
				var isJson:Bool = false;
				try
				{
					Json.parse(content);
					isJson = true;
				}
				catch (_:Dynamic)
				{
					isJson = false;
				}
				if (!isJson)
				{
					throw 'File "$path" is not valid JSON.';
				}
				else
				{
					throw 'File "$path" is JSON, but does not match the expected structure: $e';
				}
			}
			_lastModified = sys.FileSystem.stat(path).mtime.getTime();
		}
		else
		{
			data = null;
			_lastModified = -1;
		}
	}

	override public function write(newData:Dynamic):Void
	{
		data = newData;
		sys.io.File.saveContent(path, haxe.Json.stringify(newData, null, "  "));
		_lastModified = sys.FileSystem.stat(path).mtime.getTime();
	}

	function get_typedData():T
	{
		return data;
	}

	function set_typedData(v:T):T
	{
		write(v);
		return v;
	}
}

/**
 * Dynamically manages a file's content, keeping it in sync with disk.
 * Supports reading, writing, removing, and auto-reloading.
 * Uses haxe.Timer for polling.
 */
class DynamicFileStreamTimer
{
	public var path:String;
	public var data:Dynamic;
	public var throwOnDelete:Bool;
	public var pollInterval:Int;

	var _timer:haxe.Timer;
	var _lastModified:Float;

	public function new(filePath:String, ?throwOnDelete:Bool = false, ?pollInterval:Int = 500)
	{
		path = filePath;
		this.throwOnDelete = throwOnDelete;
		this.pollInterval = pollInterval;
		_lastModified = -1;
		load();
		_timer = new haxe.Timer(pollInterval);
		_timer.run = update;
	}

	function update():Void
	{
		if (!sys.FileSystem.exists(path))
		{
			if (throwOnDelete)
				throw 'File "$path" was deleted externally.';
			data = null;
			_lastModified = -1;
			return;
		}
		var stat:sys.FileStat = sys.FileSystem.stat(path);
		if (stat.mtime.getTime() != _lastModified)
		{
			load();
		}
	}

	public function load():Void
	{
		if (sys.FileSystem.exists(path))
		{
			data = sys.io.File.getContent(path);
			_lastModified = sys.FileSystem.stat(path).mtime.getTime();
		}
		else
		{
			data = null;
			_lastModified = -1;
		}
	}

	public function write(newData:Dynamic):Void
	{
		data = newData;
		sys.io.File.saveContent(path, Std.string(newData));
		_lastModified = sys.FileSystem.stat(path).mtime.getTime();
	}

	public function remove():Void
	{
		if (sys.FileSystem.exists(path))
		{
			sys.FileSystem.deleteFile(path);
			data = null;
			_lastModified = -1;
		}
	}

	public function close():Void
	{
		if (_timer != null)
		{
			_timer.stop();
			_timer = null;
		}
	}
}

/**
 * Typed dynamic file stream for Timer, e.g. for JSON files.
 * Keeps the file in sync with a typed structure.
 */
class TypedDynamicFileStreamTimer<T> extends DynamicFileStreamTimer
{
	public var typedData(get, set):T;

	public function new(filePath:String, ?throwOnDelete:Bool = false, ?pollInterval:Int = 500)
	{
		super(filePath, throwOnDelete, pollInterval);
	}

	override public function load():Void
	{
		if (sys.FileSystem.exists(path))
		{
			var content:String = sys.io.File.getContent(path);
			try
			{
				data = haxe.Json.parse(content);
			}
			catch (e:Dynamic)
			{
				data = null;
			}
			_lastModified = sys.FileSystem.stat(path).mtime.getTime();
		}
		else
		{
			data = null;
			_lastModified = -1;
		}
	}

	override public function write(newData:Dynamic):Void
	{
		data = newData;
		sys.io.File.saveContent(path, haxe.Json.stringify(newData, null, "  "));
		_lastModified = sys.FileSystem.stat(path).mtime.getTime();
	}

	function get_typedData():T
	{
		return data;
	}

	function set_typedData(v:T):T
	{
		write(v);
		return v;
	}
}
