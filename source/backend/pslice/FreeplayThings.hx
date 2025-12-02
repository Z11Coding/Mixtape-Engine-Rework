package backend.pslice;

typedef CharSave={
  mod_dir:String,
  char_name:String
}

class FreeplayThings {
  public static var LAST_MOD(get,set):CharSave; //format: "mod_dir||char_name"
  public static function get_LAST_MOD():CharSave {
    var shards = ClientPrefs.data.lastFreeplayMod.split('||');
    if(shards.length != 2) return {mod_dir: "", char_name: "bf"};
    else return {mod_dir: shards[0], char_name: shards[1]};
  }
  public static function set_LAST_MOD(value:CharSave) {
    ClientPrefs.data.lastFreeplayMod = '${value.mod_dir}||${value.char_name}';
    ClientPrefs.saveSettings();
    return value;
  }

  public static var curDirectory = 0;
  public static function getCurMod() {
    var curMod = listAllCharacterEntryIds()[curDirectory].modFolder;
    trace('Mod Directory List: ${listAllCharacterEntryIds()}');
    trace('Current Mod Directory: ${curMod}');
    return curMod;
  }

  public static function hasModsAvailable() {
    trace('Mod Directory has mods: ${listAllCharacterEntryIds().length > 1}');
    return listAllCharacterEntryIds().length > 1;
  }

  public static function listAllCharacterEntryIds():Array<{name:String, modFolder:String}> {
    var allJsons:Array<{name:String, modFolder:String}> = [];
    var registry_mods = Mods.getModsWithPlayersRegistry();
    var allMods = Mods.parseList().enabled.filter(s -> registry_mods.contains(s));
    for(mod in allMods){
      Mods.loadModDir(mod);
      for (eachName in listJsons()) {
        allJsons.push({name: eachName, modFolder: mod});
      }
    }
    Mods.loadModDir("");
    var basedCharFiles = FileSystem.readDirectory("assets/shared/registry/players");
    for (eachName in basedCharFiles.filter(s -> s.endsWith(".json")).map(s -> s.substr(0,s.length-5))) {
      allJsons.push({name: eachName, modFolder: ""});
    }
    return allJsons;
  }

  static function listJsons():Array<String> {
    var char_path = Paths.getPath('registry/players');
    var basedCharFiles = FileSystem.readDirectory(char_path);
    if(char_path == 'mods/registry/players') {
        var nativeChars = FileSystem.readDirectory(Paths.getPath('registry/players',true));
        basedCharFiles = basedCharFiles.concat(nativeChars);
    }
    return basedCharFiles.filter(s -> s.endsWith(".json")).map(s -> s.substr(0,s.length-5));
  }

}
