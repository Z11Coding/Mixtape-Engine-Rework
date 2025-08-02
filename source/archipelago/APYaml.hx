package archipelago;

import haxe.format.JsonParser;
import haxe.ds.StringMap;
import haxe.ds.Map;

abstract APOption(String) {
    public inline function new(v:String) {
        this = v;
    }

    // Auto-conversion from various types
    @:from
    public static inline function fromString(value:String):APOption {
        return new APOption(value);
    }

    @:from
    public static inline function fromBool(value:Bool):APOption {
        return new APOption(value ? "true" : "false");
    }

    @:from
    public static inline function fromFloat(value:Float):APOption {
        return new APOption(Std.string(value));
    }

    @:from
    public static inline function fromInt(value:Int):APOption {
        return new APOption(Std.string(value));
    }

    @:from
    public static inline function fromArray(value:Array<String>):APOption {
        return new APOption("[" + value.join(", ") + "]");
    }

    // Auto-conversion to various types
    @:to
    public inline function toString():String {
        return this;
    }

    @:to
    public function toBool():Bool {
        return this == "true";
    }

    @:to
    public function toFloat():Float {
        var parsed = Std.parseFloat(this);
        return Math.isNaN(parsed) ? 0.0 : parsed;
    }

    @:to
    public function toInt():Int {
        return Std.int(toFloat());
    }

    @:to
    public function toArray():Array<String> {
        if (this.startsWith("[") && this.endsWith("]")) {
            var content = this.substr(1, this.length - 2);
            return content.split(",").map(function(item) return item.trim());
        }
        return [this];
    }

    // Smart parsing function that attempts to determine and convert to the appropriate type
    public function parseValue():Dynamic {
        // Check for array format
        if (this.startsWith("[") && this.endsWith("]")) {
            return toArray();
        }
        
        // Check for boolean
        if (this == "true" || this == "false") {
            return toBool();
        }
        
        // Check for numeric (float/int)
        var floatValue = Std.parseFloat(this);
        if (!Math.isNaN(floatValue)) {
            // Check if it's an integer
            if (floatValue == Std.int(floatValue)) {
                return toInt();
            }
            return toFloat();
        }
        
        // Default to string
        return toString();
    }

    // Check if the value represents a specific type
    public function isArray():Bool {
        return this.startsWith("[") && this.endsWith("]");
    }

    public function isBool():Bool {
        return this == "true" || this == "false";
    }

    public function isNumeric():Bool {
        return !Math.isNaN(Std.parseFloat(this));
    }
}


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
                        this.game = new APOption(value);
                    else if (key == "name")
                        this.name = new APOption(value);
                    else if (key == "description")
                        this.description = new APOption(value);

                    sectionData.set(key, new APOption(value));
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

