package yutautil.gamebanana;

import haxe.Http;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Path;
import haxe.io.BytesInput;
import haxe.zip.Uncompress;
import yutautil.gamebanana.GameBananaTypes;

class GameBananaAPI {
	public static final API_BASE:String = "https://api.gamebanana.com";
	public static final WEBSITE_BASE:String = "https://gamebanana.com";
	public static final FNF_GAME_NAME:String = "Friday Night Funkin'";

	private static final MOD_FIELDS:String = [
		"name",
		"catid",
		"Category().name",
		"RootCategory().id",
		"RootCategory().name",
		"Game().name",
		"downloads",
		"screenshots",
		"Files().aFiles()",
		"Preview().sSubFeedImageUrl()",
		"Url().sDownloadUrl()",
		"Url().sProfileUrl()",
		"text"
	].join(",");

	private static final FILE_FIELDS:String = [
		"name",
		"file",
		"aFileTree()",
		"aFlattenedFileList()",
		"sModManagerDownloadUrl()",
		"Url().sProfileUrl()"
	].join(",");

	public static function extractModIdFromUrl(url:String):Null<Int> {
		if (url == null) return null;
		var trimmed = url.trim();
		if (trimmed.length == 0) return null;

		var patterns = [
			~/\/mods\/(\d+)/i,
			~/\/mods\/download\/(\d+)/i,
			~/[?&]itemid=(\d+)/i
		];

		for (pattern in patterns) {
			if (pattern.match(trimmed)) {
				var matched = pattern.matched(1);
				var parsed = Std.parseInt(matched);
				if (parsed != null) return parsed;
			}
		}

		return null;
	}

	public static function identifyModById(modId:Int, callback:Bool->Void, errorCallback:String->Void):Void {
		var url = '$API_BASE/Core/Item/IdentifyById?itemtype=Mod&itemid=$modId';
		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var parsed:Dynamic = Json.parse(data);
				if (Std.isOfType(parsed, Array)) {
					var arr:Array<Dynamic> = cast parsed;
					callback(arr.length > 0 && arr[0] == true);
					return;
				}
				callback(false);
			} catch (e:Dynamic) {
				errorCallback('Failed to parse identify response: $e');
			}
		};

		http.onError = function(error:String) {
			errorCallback('Failed to identify mod: $error');
		};

		http.addHeader("User-Agent", "Mixtape-Engine-GameBanana");
		http.request();
	}

	public static function getModData(modId:Int, callback:GameBananaModData->Void, errorCallback:String->Void):Void {
		var url = '$API_BASE/Core/Item/Data?itemtype=Mod&itemid=$modId&fields=' + StringTools.urlEncode(MOD_FIELDS);
		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var parsed:Dynamic = Json.parse(data);
				if (!Std.isOfType(parsed, Array)) {
					errorCallback("Invalid response format for mod data");
					return;
				}

				var fields:Array<Dynamic> = cast parsed;
				var mod = parseModFields(modId, fields);
				callback(mod);
			} catch (e:Dynamic) {
				errorCallback('Failed to parse mod data: $e');
			}
		};

		http.onError = function(error:String) {
			errorCallback('Failed to fetch mod data: $error');
		};

		http.addHeader("User-Agent", "Mixtape-Engine-GameBanana");
		http.request();
	}

	public static function getFileData(fileId:Int, callback:GameBananaFileData->Void, errorCallback:String->Void):Void {
		var url = '$API_BASE/Core/Item/Data?itemtype=File&itemid=$fileId&fields=' + StringTools.urlEncode(FILE_FIELDS);
		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var parsed:Dynamic = Json.parse(data);
				if (!Std.isOfType(parsed, Array)) {
					errorCallback("Invalid response format for file data");
					return;
				}

				var fields:Array<Dynamic> = cast parsed;
				var fileData = parseFileFields(fileId, fields);
				callback(fileData);
			} catch (e:Dynamic) {
				errorCallback('Failed to parse file data: $e');
			}
		};

		http.onError = function(error:String) {
			errorCallback('Failed to fetch file data: $error');
		};

		http.addHeader("User-Agent", "Mixtape-Engine-GameBanana");
		http.request();
	}

	public static function resolveModInput(input:String, callback:GameBananaModData->Void, errorCallback:String->Void):Void {
		if (input == null || input.trim().length == 0) {
			errorCallback("Input was empty");
			return;
		}

		var trimmed = input.trim();
		var asInt = Std.parseInt(trimmed);
		if (asInt != null) {
			getModData(asInt, callback, errorCallback);
			return;
		}

		var modId = extractModIdFromUrl(trimmed);
		if (modId == null) {
			errorCallback("Could not extract a GameBanana mod ID from input");
			return;
		}

		getModData(modId, callback, errorCallback);
	}

	public static function searchModsByQuery(query:String, callback:GameBananaSearchResult->Void, errorCallback:String->Void):Void {
		if (query == null || query.trim().length == 0) {
			errorCallback("Search query was empty");
			return;
		}

		// Website fallback search because Core/List/Like does not support Mod itemtype.
		var encoded = StringTools.urlEncode(query.trim());
		var url = '$WEBSITE_BASE/search?query=$encoded&section=mods';
		var http = new Http(url);

		http.onData = function(data:String) {
			try {
				var idPattern = ~/\/mods\/(\d+)/ig;
				var ids:Array<Int> = [];
				var cursor = 0;
				while (idPattern.matchSub(data, cursor)) {
					var matched = idPattern.matched(1);
					var parsed = Std.parseInt(matched);
					if (parsed != null && !ids.contains(parsed)) {
						ids.push(parsed);
					}
					var pos = idPattern.matchedPos();
					cursor = pos.pos + pos.len;
					if (ids.length >= 12) break;
				}

				if (ids.length == 0) {
					callback({
						query: query,
						usedWebSearch: true,
						items: [],
						warning: "No mod IDs could be parsed from GameBanana search results. Use direct links as fallback."
					});
					return;
				}

				var collected:Array<GameBananaModData> = [];
				var idx = 0;
				var finished = false;

				var loadNext:Void->Void = null;
				loadNext = function() {
					if (finished) return;
					if (idx >= ids.length) {
						finished = true;
						callback({
							query: query,
							usedWebSearch: true,
							items: collected,
							warning: "Search used GameBanana webpage parsing fallback."
						});
						return;
					}

					var modId = ids[idx++];
					getModData(modId, function(mod) {
						if (mod.gameName != null && mod.gameName.toLowerCase() == FNF_GAME_NAME.toLowerCase()) {
							collected.push(mod);
						}
						loadNext();
					}, function(_err) {
						loadNext();
					});
				};

				loadNext();
			} catch (e:Dynamic) {
				errorCallback('Failed while searching mods: $e');
			}
		};

		http.onError = function(error:String) {
			errorCallback('Failed to search GameBanana: $error');
		};

		http.addHeader("User-Agent", "Mixtape-Engine-GameBanana");
		http.request();
	}

	public static function validateFNFMod(mod:GameBananaModData):Null<String> {
		if (mod == null) return "Mod data was null";
		if (mod.gameName == null || mod.gameName.toLowerCase() != FNF_GAME_NAME.toLowerCase()) {
			return 'Item is not in Friday Night Funkin\' category (game was: ${mod.gameName})';
		}
		return null;
	}

	private static function parseModFields(modId:Int, fields:Array<Dynamic>):GameBananaModData {
		var screenshots = parseScreenshots(fields[7]);
		var files = parseModFiles(fields[8]);

		return {
			id: modId,
			name: asString(fields[0]),
			categoryId: asInt(fields[1]),
			categoryName: asString(fields[2]),
			rootCategoryId: asInt(fields[3]),
			rootCategoryName: asString(fields[4]),
			gameName: asString(fields[5]),
			downloads: asInt(fields[6]),
			screenshots: screenshots,
			files: files,
			previewImageUrl: sanitizeUrl(asString(fields[9])),
			directDownloadUrl: sanitizeUrl(asString(fields[10])),
			profileUrl: sanitizeUrl(asString(fields[11])),
			text: asString(fields[12])
		};
	}

	private static function parseFileFields(fileId:Int, fields:Array<Dynamic>):GameBananaFileData {
		return {
			id: fileId,
			name: asString(fields[0]),
			archiveFileName: asString(fields[1]),
			fileTree: fields[2],
			flattenedFileList: parseFlattenedList(fields[3]),
			modManagerDownloadUrl: sanitizeUrl(asString(fields[4])),
			profileUrl: sanitizeUrl(asString(fields[5]))
		};
	}

	private static function parseScreenshots(raw:Dynamic):Array<GameBananaScreenshot> {
		var results:Array<GameBananaScreenshot> = [];
		if (raw == null) return results;

		var parsed:Dynamic = raw;
		if (Std.isOfType(raw, String)) {
			var txt:String = cast raw;
			try {
				parsed = Json.parse(txt);
			} catch (_e:Dynamic) {
				return results;
			}
		}

		if (!Std.isOfType(parsed, Array)) return results;
		for (entry in (cast parsed:Array<Dynamic>)) {
			var full = extractScreenshotUrl(entry);
			var preview = extractScreenshotPreviewUrl(entry);
			results.push({
				caption: fieldAsString(entry, "_sCaption"),
				previewUrl: preview,
				fullsizeUrl: full
			});
		}
		return results;
	}

	private static function parseModFiles(raw:Dynamic):Array<GameBananaModFileEntry> {
		var entries:Array<GameBananaModFileEntry> = [];
		if (raw == null) return entries;

		var dynObj:Dynamic = raw;
		for (key in Reflect.fields(dynObj)) {
			var item:Dynamic = Reflect.field(dynObj, key);
			if (item == null) continue;

			var warnings:Dynamic = Reflect.field(item, "_aAnalysisWarnings");
			var hasExe = false;
			if (warnings != null) {
				hasExe = Reflect.hasField(warnings, "contains_exe");
			}

			entries.push({
				id: fieldAsInt(item, "_idRow"),
				fileName: fieldAsString(item, "_sFile"),
				fileSize: fieldAsInt(item, "_nFilesize"),
				downloadCount: fieldAsInt(item, "_nDownloadCount"),
				downloadUrl: sanitizeUrl(fieldAsString(item, "_sDownloadUrl")),
				description: fieldAsString(item, "_sDescription"),
				hasContents: fieldAsBool(item, "_bHasContents"),
				hasExeWarning: hasExe
			});
		}

		entries.sort(function(a, b) {
			return b.downloadCount - a.downloadCount;
		});
		return entries;
	}

	private static function parseFlattenedList(raw:Dynamic):Array<String> {
		if (raw == null) return [];
		if (!Std.isOfType(raw, Array)) return [];
		var list:Array<String> = [];
		for (entry in (cast raw:Array<Dynamic>)) {
			list.push(asString(entry));
		}
		return list;
	}

	private static function extractScreenshotUrl(entry:Dynamic):String {
		var file = fieldAsString(entry, "_sFile");
		if (file.length > 0) {
			return 'https://images.gamebanana.com/img/ss/mods/' + file;
		}
		return sanitizeUrl(fieldAsString(entry, "_sFile800"));
	}

	private static function extractScreenshotPreviewUrl(entry:Dynamic):String {
		var file220 = fieldAsString(entry, "_sFile220");
		if (file220.length > 0) {
			return 'https://images.gamebanana.com/img/ss/mods/' + file220;
		}
		var file100 = fieldAsString(entry, "_sFile100");
		if (file100.length > 0) {
			return 'https://images.gamebanana.com/img/ss/mods/' + file100;
		}
		return "";
	}

	private static inline function asString(v:Dynamic):String {
		if (v == null) return "";
		return Std.string(v);
	}

	private static inline function asInt(v:Dynamic):Int {
		if (v == null) return 0;
		var parsed = Std.parseInt(Std.string(v));
		return parsed == null ? 0 : parsed;
	}

	private static inline function fieldAsString(o:Dynamic, name:String):String {
		if (o == null || !Reflect.hasField(o, name)) return "";
		return asString(Reflect.field(o, name));
	}

	private static inline function fieldAsInt(o:Dynamic, name:String):Int {
		if (o == null || !Reflect.hasField(o, name)) return 0;
		return asInt(Reflect.field(o, name));
	}

	private static inline function fieldAsBool(o:Dynamic, name:String):Bool {
		if (o == null || !Reflect.hasField(o, name)) return false;
		return Reflect.field(o, name) == true;
	}

	private static function sanitizeUrl(url:String):String {
		if (url == null || url.length == 0) return "";
		return StringTools.replace(url, "\\/", "/");
	}
}
