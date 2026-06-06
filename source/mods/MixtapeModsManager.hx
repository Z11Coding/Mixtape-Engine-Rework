package mods;

// Aight enough's enough im doing this now i dont care anymore
import haxe.Json;
import openfl.utils.Assets;

class MixtapeModsManager extends MusicBeatState {
  static public var currentModDirectory:String = '';
  static public var currentDLCDirectory:String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'registry',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements',
		'chartModifiers',
		'__mixtape__',
		'temp_siivagunner_mods',  // Ignore SiivaGunner temp folder
		'custom_freeplays',
    'playlists',
	];

  private static var globalMods:Array<String> = [];
  private static var engineMods:Array<String> = [];

  inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		for(mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			if(pack != null && (pack.isFullMod != null && !pack.isFullMod) && (pack.runsGlobally != null && pack.runsGlobally)) globalMods.push(mod);
		}
		return globalMods;
	}

  inline public static function getEngineMods()
		return engineMods;

	inline public static function pushEngineMods() // prob a better way to do this but idc
	{
		engineMods = [];
		for(mod in parseList().engine)
		{
			var pack:MixtapePackJSON = getPack(mod);
			if(pack != null && (pack.isFullMod != null && pack.isFullMod) && (pack.runsGlobally != null && !pack.runsGlobally)) engineMods.push(mod);
		}
		return engineMods;
	}

  inline public static function getModDirectories():Array<String>
  {
    var list:Array<String> = [];
    #if MODS_ALLOWED
    var modsFolder:String = Paths.mods();
    if(FileSystem.exists(modsFolder)) {
      for (folder in FileSystem.readDirectory(modsFolder))
      {
        var path = haxe.io.Path.join([modsFolder, folder]);
        if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
          list.push(folder);
      }
    }
    #end
    return list;
  }

  inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
  {
    if(defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
    defaultDirectory = defaultDirectory.trim();
    if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
    if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

    var mergedList:Array<String> = [];
    var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

    var defaultPath:String = defaultDirectory + path;
    if(paths.contains(defaultPath))
    {
      paths.remove(defaultPath);
      paths.insert(0, defaultPath);
    }

    for (file in paths)
    {
      var list:Array<String> = CoolUtil.coolTextFile(file);
      for (value in list)
        if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
          mergedList.push(value);
    }
    return mergedList;
  }

  inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
  {
    var foldersToCheck:Array<String> = [];
    //Main folder
    if(FileSystem.exists(path + fileToFind))
      foldersToCheck.push(path + fileToFind);

    // Week folder
    if(Paths.currentLevel != null && Paths.currentLevel != path)
    {
      var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
      if(!foldersToCheck.contains(pth) && FileSystem.exists(pth))
        foldersToCheck.push(pth);
    }

    #if MODS_ALLOWED
    if(mods)
    {
      // Global mods first
      for(mod in Mods.getGlobalMods())
      {
        var folder:String = Paths.mods(mod + '/' + fileToFind);
        if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
      }

      // Then engine mods
      for(mod in Mods.getEngineMods())
      {
        var folder:String = Paths.mods(mod + '/' + fileToFind);
        if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
      }

      // Then "MixtapeEngine/mods/" main folder
      var folder:String = Paths.mods(fileToFind);
      if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));

      // And lastly, the loaded mod's folder
      if(MixtapeModsManager.currentModDirectory != null && MixtapeModsManager.currentModDirectory.length > 0)
      {
        var folder:String = Paths.mods(MixtapeModsManager.currentModDirectory + '/' + fileToFind);
        if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
      }
    }
    #end
    return foldersToCheck;
  }

  public static function getPack(?folder:String = null):MixtapePackJSON
  {
    #if MODS_ALLOWED
    if(folder == null) folder = Mods.currentModDirectory;

    var path = Paths.mods(folder + '/mixtape.json');
    if(FileSystem.exists(path)) {
      try {
        #if sys
        var rawJson:String = File.getContent(path);
        #else
        var rawJson:String = Assets.getText(path);
        #end
        if(rawJson != null && rawJson.length > 0) return tjson.TJSON.parse(rawJson);
      } catch(e:Dynamic) {
        trace(e);
      }
    }
    #end
    return null;
  }

  public static var updatedOnState:Bool = false;
	inline public static function parseList():MixtapeModsList {
		if(!updatedOnState) updateModList();
		var list:MixtapeModsList = {enabled: [], disabled: [], engine: [], activeDLC: [], all: []};

		#if MODS_ALLOWED
		try {
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				//trace('Mod: $mod');
				if(mod.trim().length < 1) continue;

				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);

        // 0 means it's a normal mod
        // 1 means it's an engine mod
        // 2 means it's a DLC for a mod
        if (dat[2] == "1")
          list.engine.push(dat[0]);
        else if (dat[2] == "2")
          list.activeDLC.push(dat[0]);
			}
		} catch(e) {
			trace(e);
		}
		#end
		return list;
	}
}
