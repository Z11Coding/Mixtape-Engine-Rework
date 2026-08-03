package yutautil.gamebanana;

enum GameBananaCompatibilityVerdict {
	COMPATIBLE;
	LIKELY_COMPATIBLE;
	MIXTAPE_SUPPORTED;
	REQUIRES_SETUP;
	UNKNOWN_NEEDS_TESTING;
	INCOMPATIBLE;
}

typedef GameBananaModFileEntry = {
	var id:Int;
	var fileName:String;
	var fileSize:Int;
	var downloadCount:Int;
	var downloadUrl:String;
	var description:String;
	var hasContents:Bool;
	var hasExeWarning:Bool;
}

typedef GameBananaScreenshot = {
	var caption:String;
	var previewUrl:String;
	var fullsizeUrl:String;
}

typedef GameBananaModData = {
	var id:Int;
	var name:String;
	var gameName:String;
	var categoryId:Int;
	var categoryName:String;
	var rootCategoryId:Int;
	var rootCategoryName:String;
	var downloads:Int;
	var profileUrl:String;
	var directDownloadUrl:String;
	var previewImageUrl:String;
	var screenshots:Array<GameBananaScreenshot>;
	var files:Array<GameBananaModFileEntry>;
	var text:String;
}

typedef GameBananaFileData = {
	var id:Int;
	var name:String;
	var archiveFileName:String;
	var profileUrl:String;
	var modManagerDownloadUrl:String;
	var flattenedFileList:Array<String>;
	var fileTree:Dynamic;
}

typedef GameBananaSetupRequiredEntry = {
	var id:Int;
	var url:String;
	var description:String;
	var postDownloadActions:Array<String>;
}

typedef GameBananaListedModEntry = {
	var id:Int;
	var url:String;
	var note:String;
}

typedef GameBananaRegistryData = {
	var version:Int;
	var psychCategoryIds:Array<Int>;
	var psychCategoryNames:Array<String>;
	var supportedMods:Array<GameBananaListedModEntry>;
	var testingMods:Array<GameBananaListedModEntry>;
	var semiFunctionalMods:Array<GameBananaListedModEntry>;
	var setupRequiredMods:Array<GameBananaSetupRequiredEntry>;
	var remoteRegistryUrl:String;
}

typedef GameBananaCompatibilityResult = {
	var verdict:GameBananaCompatibilityVerdict;
	var reasons:Array<String>;
	var matchedRules:Array<String>;
	var isInTestingRepository:Bool;
	var isInSemiFunctionalRepository:Bool;
	var setupRequiredEntry:Null<GameBananaSetupRequiredEntry>;
}

typedef GameBananaSearchResult = {
	var query:String;
	var usedWebSearch:Bool;
	var items:Array<GameBananaModData>;
	var warning:String;
}
