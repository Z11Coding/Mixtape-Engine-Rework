package yutautil.gamebanana;

import yutautil.gamebanana.GameBananaTypes;

class GameBananaHelper {
	public static function getModData(modId:Int):Null<GameBananaModData> {
		var result:GameBananaModData = null;
		var error:String = null;
		var completed = false;

		GameBananaAPI.getModData(modId, function(mod) {
			result = mod;
			completed = true;
		}, function(err) {
			error = err;
			completed = true;
		});

		var timeoutStart = Sys.time();
		while (!completed && (Sys.time() - timeoutStart) < 15.0) {
			Sys.sleep(0.01);
		}
		if (error != null) {
			trace('GameBananaHelper.getModData error: ' + error);
			return null;
		}
		return result;
	}

	public static function resolveModInput(input:String):Null<GameBananaModData> {
		var result:GameBananaModData = null;
		var error:String = null;
		var completed = false;

		GameBananaAPI.resolveModInput(input, function(mod) {
			result = mod;
			completed = true;
		}, function(err) {
			error = err;
			completed = true;
		});

		var timeoutStart = Sys.time();
		while (!completed && (Sys.time() - timeoutStart) < 15.0) {
			Sys.sleep(0.01);
		}
		if (error != null) {
			trace('GameBananaHelper.resolveModInput error: ' + error);
			return null;
		}
		return result;
	}

	public static function searchModsByQuery(query:String):GameBananaSearchResult {
		var result:GameBananaSearchResult = null;
		var error:String = null;
		var completed = false;

		GameBananaAPI.searchModsByQuery(query, function(searchResult) {
			result = searchResult;
			completed = true;
		}, function(err) {
			error = err;
			completed = true;
		});

		var timeoutStart = Sys.time();
		while (!completed && (Sys.time() - timeoutStart) < 35.0) {
			Sys.sleep(0.01);
		}
		if (error != null) {
			trace('GameBananaHelper.searchModsByQuery error: ' + error);
			return {
				query: query,
				usedWebSearch: false,
				items: [],
				warning: error
			};
		}
		return result;
	}

	public static function getFileData(fileId:Int):Null<GameBananaFileData> {
		var result:GameBananaFileData = null;
		var error:String = null;
		var completed = false;

		GameBananaAPI.getFileData(fileId, function(file) {
			result = file;
			completed = true;
		}, function(err) {
			error = err;
			completed = true;
		});

		var timeoutStart = Sys.time();
		while (!completed && (Sys.time() - timeoutStart) < 25.0) {
			Sys.sleep(0.01);
		}
		if (error != null) {
			trace('GameBananaHelper.getFileData error: ' + error);
			return null;
		}
		return result;
	}

	public static function getFileTreesForMod(mod:GameBananaModData, ?maxFiles:Int = 3):Array<GameBananaFileData> {
		if (mod == null) return [];
		if (maxFiles < 1) maxFiles = 1;

		var trees:Array<GameBananaFileData> = [];
		var count = 0;
		for (file in mod.files) {
			if (count >= maxFiles) break;
			if (!file.hasContents) continue;

			var data = getFileData(file.id);
			if (data != null) {
				trees.push(data);
				count++;
			}
		}
		return trees;
	}
}
