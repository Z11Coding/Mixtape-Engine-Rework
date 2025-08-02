package archipelago;

import haxe.format.JsonParser;
import haxe.ds.StringMap;
import haxe.ds.Map;
class APYaml {
    public var game:String;
    public var name:String;
    public var description:String;
    public var settings:Dynamic;

    public function new(yamlContent:String) {
        var jsonContent = convertYamlToJson(yamlContent);
        var parsedData = JsonParser.parse(jsonContent);

        this.game = parsedData.game;
        this.name = parsedData.name;
        this.description = parsedData.description;
        this.settings = Reflect.field(parsedData, "Friday Night Funkin");
    }

    private function convertYamlToJson(yamlContent:String):String {
        var lines = yamlContent.split("\n");
        var jsonObject = new Map<String, Dynamic>();
        var currentSection:String = null;
        var sectionData = new Map<String, Dynamic>();

        for (line in lines) {
            line = line.trim();
            if (line == "" || line.startsWith("#")) {
                continue; // Skip empty lines and comments
            }

            if (line.endsWith(":")) {
                if (currentSection != null) {
                    jsonObject.set(currentSection, sectionData);
                }
                currentSection = line.substr(0, line.length - 1);
                sectionData = new Map<String, Dynamic>();
            } else {
                var keyValue = line.split(":");
                if (keyValue.length == 2) {
                    var key = keyValue[0].trim();
                    var value = keyValue[1].trim();

                    if (key == "game")
                        this.game = value;
                    else if (key == "name")
                        this.name = value;
                    else if (key == "description")
                        this.description = value;

                    if (value.startsWith("[") && value.endsWith("]")) {
                        value = value.substr(1, value.length - 2);
                        sectionData.set(key, value.split(",").map(function(item) return item.trim()));
                    } else if (value == "true" || value == "false") {
                        sectionData.set(key, value == "true");
                    } else if (cast(Std.parseFloat(value), Null<Float>) != null || !Math.isNaN(Std.parseFloat(value))) {
                        sectionData.set(key, Std.parseFloat(value));
                    } else {
                        sectionData.set(key, value);
                    }
                }
            }
        }

        if (currentSection != null) {
            jsonObject.set(currentSection, sectionData);
        }

        return haxe.Json.stringify(jsonObject);
    }

    public function getSongList():Array<String> {
        return settings.songList;
    }

    public function getTicketWinPercentage():Float {
        return Std.parseFloat(settings.ticket_win_percentage);
    }

    public function isModsEnabled():Bool {
        return settings.mods_enabled;
    }

    
    // Add more methods to access other settings as needed.
}

