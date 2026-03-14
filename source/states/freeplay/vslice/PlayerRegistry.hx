package states.freeplay.vslice;

import backend.NativeFileSystem;
import haxe.Json;
import states.freeplay.vslice.PlayerData;

//TODO softcode this soon
class PlayerRegistry extends PsliceRegistry{
    public static var instance:PlayerRegistry = new PlayerRegistry();
    public function new() {
      super('players');
    }

    public function isCharacterOwned(id:String):Bool {
      return true;
    }

    public function hasNewCharacter():Bool {
      return false;
    }

    public function fetchEntry(playableCharId:String):Null<PlayableCharacter> {
      var player_blob:Dynamic = readJson(playableCharId);// new PlayerData();
      if(player_blob == null) {
        trace('COULDN\'T FIND DJ!');
        return null;
      }
      var player_data = new PlayerData().mergeWithJson(player_blob,["freeplayDJ"]);
      var dj = new PlayerFreeplayDJData().mergeWithJson(player_blob.freeplayDJ);
      player_data.freeplayDJ = dj;
      return new PlayableCharacter(player_data);
    }

    // return ALL characters avaliable (from current mod)
    public function listEntryIds():Array<String> {
      if(Mods.currentModDirectory == ""){
        var allJsons:Array<String> = [];
        var registry_mods = Mods.getModsWithPlayersRegistry();
        var globalMods = Mods.getGlobalMods().filter(s -> registry_mods.contains(s));
        for(mod in globalMods){
          Mods.loadModDir(mod);
          allJsons.pushMany(listJsons());
        }
        Mods.loadModDir("");
        var basedCharFiles = FileSystem.readDirectory("assets/shared/registry/players");
        allJsons.pushMany(basedCharFiles.filter(s -> s.endsWith(".json")).map(s -> s.substr(0,s.length-5)));
        return allJsons;
      }
      else return listJsons();
    }

    // return ALL characters avaliable
    public function listAllEntryIds():Array<String> {
      var allJsons:Array<String> = [];
      var registry_mods = Mods.getModsWithPlayersRegistry();
      var allMods = Mods.parseList().enabled.filter(s -> registry_mods.contains(s));
      for(mod in allMods){
        Mods.loadModDir(mod);
        allJsons.pushMany(listJsons());
      }
      Mods.loadModDir("");
      var basedCharFiles:Array<String> = [];
      try {
        basedCharFiles = FileSystem.readDirectory("assets/shared/registry/players");
      } catch (e:Dynamic) {
        trace('Failed to read directory assets/shared/registry/players: $e');
      }
      try {
        allJsons.pushMany(basedCharFiles.filter(s -> s.endsWith(".json")).map(s -> s.substr(0,s.length-5)));
      } catch (e:Dynamic) {
        trace("Nothing here!");
      }
      return allJsons;
    }

    // This is only used to check if we should allow the player to open charSelect
    public function countUnlockedCharacters():Int {
      return 2;
    }
}
