package archipelago;

// Typedefs for items and locations
typedef APItem = {
    name: String
};

typedef APLocation = {
    name: String,
    accessRule: () -> () -> Bool
};

// Class to hold static arrays of items and locations
class APDataStore {
    public static var items:Array<APItem> = [];
    public static var locations:Array<APLocation> = [];
}

// Class for Lua-based AP logic
class APLua {
    public static function addItem(name:String):Void {
        APDataStore.items.push({ name: name });
    }

    public static function addLocation(name:String, accessRule:() -> () -> Bool):Void {
        APDataStore.locations.push({ name: name, accessRule: accessRule });
    }
}

// Class for HScript-based AP logic
class APHScript {
    public static function addItem(name:String):Void {
        APLua.addItem(name);
    }

    public static function addLocation(name:String, accessRule:() -> () -> Bool):Void {
        APLua.addLocation(name, accessRule);
    }
}

// Function to generate HScript file
class APHScriptGenerator {
    public static function generateHScript():String {
        var hscriptContent = "";

        // Generate items
        hscriptContent += "function getItems() {\n";
        for (item in APDataStore.items) {
            hscriptContent += "    { name: \"" + item.name + "\" },\n";
        }
        hscriptContent += "}\n\n";

        // Generate locations
        hscriptContent += "function getLocations() {\n";
        for (location in APDataStore.locations) {
            hscriptContent += "    { name: \"" + location.name + "\", accessRule: " + location.accessRule()() + " },\n";
        }
        hscriptContent += "}\n\n";

        // Final function to gather both
        hscriptContent += "function getAPData() {\n";
        hscriptContent += "    return { items: getItems(), locations: getLocations() };\n";
        hscriptContent += "}\n";

        return hscriptContent;
    }
}
