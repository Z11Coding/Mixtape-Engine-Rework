package yutautil.gamebanana;

import haxe.Http;
import haxe.Json;
import openfl.utils.Assets;
import yutautil.gamebanana.GameBananaTypes;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class GameBananaRegistry {
	public static final DEFAULT_REGISTRY_PATH:String = "assets/shared/data/gamebanana/mixtape_mod_support.json";
	private static var cached:Null<GameBananaRegistryData> = null;
	private static var cacheTime:Float = 0.0;
	private static var cacheLifetimeSeconds:Float = 60.0;

	public static function getRegistry(?forceReload:Bool = false):GameBananaRegistryData {
		if (!forceReload && cached != null && (Sys.time() - cacheTime) <= cacheLifetimeSeconds) {
			return cached;
		}

		var base = loadLocalRegistry();
		if (base == null) {
			base = getDefaultRegistry();
		}

		if (base.remoteRegistryUrl != null && base.remoteRegistryUrl.trim().length > 0) {
			var remote = loadRemoteRegistrySync(base.remoteRegistryUrl);
			if (remote != null) {
				base = mergeRegistry(base, remote);
			}
		}

		cached = base;
		cacheTime = Sys.time();
		return cached;
	}

	public static function isSupportedMod(mod:GameBananaModData, registry:GameBananaRegistryData):Bool {
		if (mod == null) return false;
		if (matchById(mod.id, registry.supportedMods)) return true;
		return matchByUrl(mod.profileUrl, registry.supportedMods);
	}

	public static function isTestingMod(mod:GameBananaModData, registry:GameBananaRegistryData):Bool {
		if (mod == null) return false;
		if (matchById(mod.id, registry.testingMods)) return true;
		return matchByUrl(mod.profileUrl, registry.testingMods);
	}

	public static function isSemiFunctionalMod(mod:GameBananaModData, registry:GameBananaRegistryData):Bool {
		if (mod == null) return false;
		if (matchById(mod.id, registry.semiFunctionalMods)) return true;
		return matchByUrl(mod.profileUrl, registry.semiFunctionalMods);
	}

	public static function getSetupRequiredEntry(mod:GameBananaModData, registry:GameBananaRegistryData):Null<GameBananaSetupRequiredEntry> {
		if (mod == null) return null;
		for (entry in registry.setupRequiredMods) {
			if (entry.id == mod.id) return entry;
			if (normalizeUrl(entry.url) == normalizeUrl(mod.profileUrl)) return entry;
		}
		return null;
	}

	private static function loadLocalRegistry():Null<GameBananaRegistryData> {
		try {
			var raw:String = null;
			#if sys
			if (FileSystem.exists(DEFAULT_REGISTRY_PATH)) {
				raw = File.getContent(DEFAULT_REGISTRY_PATH);
			}
			#end
			if (raw == null && Assets.exists(DEFAULT_REGISTRY_PATH)) {
				raw = Assets.getText(DEFAULT_REGISTRY_PATH);
			}
			if (raw == null || raw.trim().length == 0) return null;

			var parsed:Dynamic = Json.parse(raw);
			return normalizeRegistry(parsed);
		} catch (e:Dynamic) {
			trace('GameBananaRegistry local load error: $e');
			return null;
		}
	}

	private static function loadRemoteRegistrySync(url:String):Null<GameBananaRegistryData> {
		var result:GameBananaRegistryData = null;
		var completed = false;

		var http = new Http(url);
		http.onData = function(data:String) {
			try {
				result = normalizeRegistry(Json.parse(data));
			} catch (e:Dynamic) {
				trace('GameBananaRegistry remote parse error: $e');
			}
			completed = true;
		};
		http.onError = function(error:String) {
			trace('GameBananaRegistry remote error: $error');
			completed = true;
		};
		http.addHeader("User-Agent", "Mixtape-Engine-GameBanana");
		http.request();

		var timeoutStart = Sys.time();
		while (!completed && (Sys.time() - timeoutStart) < 8.0) {
			Sys.sleep(0.01);
		}
		return result;
	}

	private static function mergeRegistry(base:GameBananaRegistryData, overlay:GameBananaRegistryData):GameBananaRegistryData {
		return {
			version: overlay.version > 0 ? overlay.version : base.version,
			psychCategoryIds: uniqueIntArray(base.psychCategoryIds.concat(overlay.psychCategoryIds)),
			psychCategoryNames: uniqueStringArray(base.psychCategoryNames.concat(overlay.psychCategoryNames)),
			supportedMods: mergeListedMods(base.supportedMods, overlay.supportedMods),
			testingMods: mergeListedMods(base.testingMods, overlay.testingMods),
			semiFunctionalMods: mergeListedMods(base.semiFunctionalMods, overlay.semiFunctionalMods),
			setupRequiredMods: mergeSetupEntries(base.setupRequiredMods, overlay.setupRequiredMods),
			remoteRegistryUrl: (overlay.remoteRegistryUrl != null && overlay.remoteRegistryUrl.trim().length > 0) ? overlay.remoteRegistryUrl : base.remoteRegistryUrl
		};
	}

	private static function normalizeRegistry(raw:Dynamic):GameBananaRegistryData {
		var version = safeInt(raw, "version", 1);
		var remoteUrl = safeString(raw, "remoteRegistryUrl", "");

		return {
			version: version,
			psychCategoryIds: readIntArray(Reflect.field(raw, "psychCategoryIds")),
			psychCategoryNames: readStringArray(Reflect.field(raw, "psychCategoryNames")),
			supportedMods: readListedMods(Reflect.field(raw, "supportedMods")),
			testingMods: readListedMods(Reflect.field(raw, "testingMods")),
			semiFunctionalMods: readListedMods(Reflect.field(raw, "semiFunctionalMods")),
			setupRequiredMods: readSetupEntries(Reflect.field(raw, "setupRequiredMods")),
			remoteRegistryUrl: remoteUrl
		};
	}

	private static function getDefaultRegistry():GameBananaRegistryData {
		return {
			version: 1,
			psychCategoryIds: [],
			psychCategoryNames: ["Psych Mod Folders"],
			supportedMods: [],
			testingMods: [],
			semiFunctionalMods: [],
			setupRequiredMods: [],
			remoteRegistryUrl: ""
		};
	}

	private static function readListedMods(raw:Dynamic):Array<GameBananaListedModEntry> {
		var out:Array<GameBananaListedModEntry> = [];
		if (!Std.isOfType(raw, Array)) return out;

		for (entry in (cast raw:Array<Dynamic>)) {
			out.push({
				id: safeInt(entry, "id", 0),
				url: normalizeUrl(safeString(entry, "url", "")),
				note: safeString(entry, "note", "")
			});
		}
		return out;
	}

	private static function readSetupEntries(raw:Dynamic):Array<GameBananaSetupRequiredEntry> {
		var out:Array<GameBananaSetupRequiredEntry> = [];
		if (!Std.isOfType(raw, Array)) return out;

		for (entry in (cast raw:Array<Dynamic>)) {
			out.push({
				id: safeInt(entry, "id", 0),
				url: normalizeUrl(safeString(entry, "url", "")),
				description: safeString(entry, "description", ""),
				postDownloadActions: readStringArray(Reflect.field(entry, "postDownloadActions"))
			});
		}
		return out;
	}

	private static function readIntArray(raw:Dynamic):Array<Int> {
		if (!Std.isOfType(raw, Array)) return [];
		var out:Array<Int> = [];
		for (entry in (cast raw:Array<Dynamic>)) {
			var parsed = Std.parseInt(Std.string(entry));
			if (parsed != null && !out.contains(parsed)) out.push(parsed);
		}
		return out;
	}

	private static function readStringArray(raw:Dynamic):Array<String> {
		if (!Std.isOfType(raw, Array)) return [];
		var out:Array<String> = [];
		for (entry in (cast raw:Array<Dynamic>)) {
			var str = Std.string(entry);
			if (str.length > 0 && !out.contains(str)) out.push(str);
		}
		return out;
	}

	private static function mergeListedMods(base:Array<GameBananaListedModEntry>, overlay:Array<GameBananaListedModEntry>):Array<GameBananaListedModEntry> {
		var result = base.copy();
		for (entry in overlay) {
			var exists = false;
			for (existing in result) {
				if (existing.id == entry.id || normalizeUrl(existing.url) == normalizeUrl(entry.url)) {
					exists = true;
					break;
				}
			}
			if (!exists) result.push(entry);
		}
		return result;
	}

	private static function mergeSetupEntries(base:Array<GameBananaSetupRequiredEntry>, overlay:Array<GameBananaSetupRequiredEntry>):Array<GameBananaSetupRequiredEntry> {
		var result = base.copy();
		for (entry in overlay) {
			var replaced = false;
			for (i in 0...result.length) {
				if (result[i].id == entry.id || normalizeUrl(result[i].url) == normalizeUrl(entry.url)) {
					result[i] = entry;
					replaced = true;
					break;
				}
			}
			if (!replaced) result.push(entry);
		}
		return result;
	}

	private static function uniqueIntArray(arr:Array<Int>):Array<Int> {
		var out:Array<Int> = [];
		for (v in arr) if (!out.contains(v)) out.push(v);
		return out;
	}

	private static function uniqueStringArray(arr:Array<String>):Array<String> {
		var out:Array<String> = [];
		for (v in arr) if (!out.contains(v)) out.push(v);
		return out;
	}

	private static function matchById(id:Int, list:Array<GameBananaListedModEntry>):Bool {
		for (entry in list) {
			if (entry.id != 0 && entry.id == id) return true;
		}
		return false;
	}

	private static function matchByUrl(url:String, list:Array<GameBananaListedModEntry>):Bool {
		var norm = normalizeUrl(url);
		if (norm.length == 0) return false;
		for (entry in list) {
			if (normalizeUrl(entry.url) == norm) return true;
		}
		return false;
	}

	private static function normalizeUrl(url:String):String {
		if (url == null) return "";
		var value = url.trim().toLowerCase();
		while (value.endsWith("/")) value = value.substr(0, value.length - 1);
		return value;
	}

	private static function safeString(obj:Dynamic, key:String, fallback:String):String {
		if (obj == null || !Reflect.hasField(obj, key)) return fallback;
		var v = Reflect.field(obj, key);
		if (v == null) return fallback;
		return Std.string(v);
	}

	private static function safeInt(obj:Dynamic, key:String, fallback:Int):Int {
		if (obj == null || !Reflect.hasField(obj, key)) return fallback;
		var parsed = Std.parseInt(Std.string(Reflect.field(obj, key)));
		return parsed == null ? fallback : parsed;
	}
}
