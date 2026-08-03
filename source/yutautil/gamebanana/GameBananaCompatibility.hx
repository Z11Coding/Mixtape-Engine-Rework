package yutautil.gamebanana;

import yutautil.gamebanana.GameBananaTypes;

class GameBananaCompatibility {
	public static function analyze(mod:GameBananaModData, fileTrees:Array<GameBananaFileData>, ?registry:GameBananaRegistryData):GameBananaCompatibilityResult {
		var reg = registry != null ? registry : GameBananaRegistry.getRegistry();
		var reasons:Array<String> = [];
		var matched:Array<String> = [];

		var setup = GameBananaRegistry.getSetupRequiredEntry(mod, reg);
		var isSupported = GameBananaRegistry.isSupportedMod(mod, reg);
		var isTesting = GameBananaRegistry.isTestingMod(mod, reg);
		var isSemiFunctional = GameBananaRegistry.isSemiFunctionalMod(mod, reg);

		if (mod == null) {
			return {
				verdict: INCOMPATIBLE,
				reasons: ["No mod data was provided"],
				matchedRules: [],
				isInTestingRepository: false,
				isInSemiFunctionalRepository: false,
				setupRequiredEntry: null
			};
		}

		var fnfValidation = GameBananaAPI.validateFNFMod(mod);
		if (fnfValidation != null) {
			reasons.push(fnfValidation);
			return {
				verdict: INCOMPATIBLE,
				reasons: reasons,
				matchedRules: matched,
				isInTestingRepository: isTesting,
				isInSemiFunctionalRepository: isSemiFunctional,
				setupRequiredEntry: setup
			};
		}

		if (matchesPsychCategory(mod, reg)) {
			matched.push("rule1_psych_category");
			reasons.push('Matched Psych category by ID/name (${mod.categoryId} / ${mod.categoryName})');
		}

		var treeEvidence = evaluateFileTrees(fileTrees);
		if (treeEvidence.hasExecutableLayout && (treeEvidence.hasNestedModPackage || treeEvidence.hasMeaningfulAssetFolders)) {
			matched.push("rule2_executable_layout_with_mod_assets");
			reasons.push("Archive appears executable-oriented and includes meaningful mod content");
		}

		if (isSupported) {
			matched.push("rule3_mixtape_supported_registry");
			reasons.push("Matched Mixtape-supported registry entry");
		}

		if (setup != null) {
			reasons.push("Matched setup-required repository entry");
		}
		if (isTesting) reasons.push("Mod is in the testing repository");
		if (isSemiFunctional) reasons.push("Mod is in the semi-functional repository");

		var verdict:GameBananaCompatibilityVerdict = UNKNOWN_NEEDS_TESTING;
		if (matched.contains("rule1_psych_category")) {
			verdict = COMPATIBLE;
		} else if (setup != null) {
			verdict = REQUIRES_SETUP;
		} else if (isSupported) {
			verdict = MIXTAPE_SUPPORTED;
		} else if (matched.contains("rule2_executable_layout_with_mod_assets")) {
			verdict = LIKELY_COMPATIBLE;
		}

		if (reasons.length == 0) {
			reasons.push("No strong compatibility signals found. Needs testing.");
		}

		return {
			verdict: verdict,
			reasons: reasons,
			matchedRules: matched,
			isInTestingRepository: isTesting,
			isInSemiFunctionalRepository: isSemiFunctional,
			setupRequiredEntry: setup
		};
	}

	private static function matchesPsychCategory(mod:GameBananaModData, registry:GameBananaRegistryData):Bool {
		if (registry.psychCategoryIds.contains(mod.categoryId) || registry.psychCategoryIds.contains(mod.rootCategoryId)) {
			return true;
		}

		var categoryName = (mod.categoryName + " " + mod.rootCategoryName).toLowerCase();
		for (name in registry.psychCategoryNames) {
			if (name != null && name.trim().length > 0 && categoryName.indexOf(name.toLowerCase()) != -1) {
				return true;
			}
		}

		return categoryName.indexOf("psych mod folders") != -1;
	}

	private static function evaluateFileTrees(fileTrees:Array<GameBananaFileData>):TreeEvidence {
		var hasModsFolder = false;
		var hasNestedModPackage = false;
		var hasMeaningfulAssetFolders = false;
		var hasExecutableLayout = false;

		for (tree in fileTrees) {
			for (rawPath in tree.flattenedFileList) {
				var path = normalizePath(rawPath);
				if (path.length == 0) continue;

				if (path.indexOf(".exe") != -1 || path.indexOf("/bin/") != -1 || path.indexOf("/plugins/") != -1) {
					hasExecutableLayout = true;
				}

				var hasModsSegment = path.indexOf("/mods/") != -1 || StringTools.startsWith(path, "mods/");
				if (hasModsSegment) {
					hasModsFolder = true;
					if (path.indexOf("/pack.json") != -1) {
						hasNestedModPackage = true;
					}
					if (isMeaningfulAssetPath(path)) {
						hasMeaningfulAssetFolders = true;
					}
				}
			}
		}

		return {
			hasModsFolder: hasModsFolder,
			hasNestedModPackage: hasNestedModPackage,
			hasMeaningfulAssetFolders: hasMeaningfulAssetFolders,
			hasExecutableLayout: hasExecutableLayout
		};
	}

	private static function isMeaningfulAssetPath(path:String):Bool {
		if (path.endsWith("readme.txt") || path.endsWith("readme.md")) return false;
		var assetFolderHit = path.indexOf("/assets/") != -1 || path.indexOf("/images/") != -1 || path.indexOf("/songs/") != -1 || path.indexOf("/weeks/") != -1 || path.indexOf("/data/") != -1;
		return assetFolderHit;
	}

	private static function normalizePath(path:String):String {
		if (path == null) return "";
		var normalized = path.toLowerCase();
		normalized = StringTools.replace(normalized, "\\", "/");
		while (normalized.indexOf("//") != -1) normalized = StringTools.replace(normalized, "//", "/");
		return normalized;
	}
}

private typedef TreeEvidence = {
	var hasModsFolder:Bool;
	var hasNestedModPackage:Bool;
	var hasMeaningfulAssetFolders:Bool;
	var hasExecutableLayout:Bool;
}
