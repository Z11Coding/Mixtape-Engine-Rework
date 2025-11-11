package states.freeplay.vslice;

import backend.NativeFileSystem;
import haxe.Json;

class PsliceRegistry {
    final regPath:String;
    public function new(registryName:String) {
        regPath = 'registry/$registryName';
    }
    function readJson(id:String):Dynamic {
        var char_path = Paths.getPath('$regPath/$id.json');
        if(!NativeFileSystem.exists(char_path)) return null;
        var text = NativeFileSystem.getContent(char_path);

        return Json.parse(text);// new PlayerData();
    }
    function listJsons():Array<String> {
        var char_path = Paths.getPath(regPath);
        var basedCharFiles = NativeFileSystem.readDirectory(char_path);
        if(char_path == 'mods/$regPath'){
            var nativeChars = NativeFileSystem.readDirectory(Paths.getPath(regPath,true));
            basedCharFiles = basedCharFiles.concat(nativeChars);
        }
        return basedCharFiles.filter(s -> s.endsWith(".json")).map(s -> s.substr(0,s.length-5));
    }
}
