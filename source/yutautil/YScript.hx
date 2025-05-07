package yutautil;

import haxe.ds.StringMap;

class YScript {
    private var keywords:Map<String, String>;

    public function new() {
        keywords = new StringMap<String>();
        keywords.set("class", "class");
        keywords.set("var", "var");
        keywords.set("struct", "struct");
        keywords.set("function", "function");
        keywords.set("use", "use");
        keywords.set("if", "if");
        keywords.set("while", "while");
        keywords.set("for", "for");
    }

    public function parse(script:String):Void {
        var lines = script.split("\n");
        for (line in lines) {
            line = line.trim();
            if (line == "" || line.startsWith("//")) continue; // Skip empty lines and comments

            try {
                parseLine(line);
            } catch (e:Dynamic) {
                trace("Error parsing line: " + line + "\n" + e);
            }
        }
    }

    private function parseLine(line:String):Void {
        if (line.indexOf(";") == -1) throw "Missing semicolon at the end of the line.";

        var tokens = line.split(" ");
        var keyword = tokens[0];

        if (!keywords.exists(keyword)) throw "Unknown keyword: " + keyword;

        switch (keyword) {
            case "class":
                parseClass(line);
            case "var":
                parseVariable(line);
            case "struct":
                parseStruct(line);
            case "function":
                parseFunction(line);
            case "use":
                parseUse(line);
            default:
                throw "Unhandled keyword: " + keyword;
        }
    }

    private function parseClass(line:String):Void {
        // Implement class parsing logic
    }

    private function parseVariable(line:String):Void {
        // Implement variable parsing logic
    }

    private function parseStruct(line:String):Void {
        // Implement struct parsing logic
    }

    private function parseFunction(line:String):Void {
        // Implement function parsing logic
    }

    private function parseUse(line:String):Void {
        // Implement use parsing logic
    }
}

