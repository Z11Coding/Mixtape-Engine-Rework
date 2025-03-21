package yutautil;


import flixel.util.FlxColor;
import openfl.text.TextFormat;

class MarkdownFlxText extends FlxText {
    public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
        super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
    }

    /**
     * Parses markdown-like syntax and applies formatting.
     * @param input The text with markdown-like syntax.
     * @return This `MarkdownFlxText` instance.
     */
    public function setMarkdownText(input:String):MarkdownFlxText {
        // Clear existing formats
        clearFormats();

        // Define formatting rules
        var boldRegex = ~/(\*\*(.*?)\*\*)/; // Matches **bold**
        var italicRegex = ~/(_(.*?)_)/;     // Matches _italic_
        var colorRegex = ~/(\{#([0-9A-Fa-f]{6})\}(.*?))\{/; // Matches {#RRGGBB}text{

        // Apply bold formatting
        input = applyRegex(input, boldRegex, function(match, start, end) {
            var format = new FlxTextFormat(FlxColor.WHITE, true, false);
            addFormat(format, start, end);
        });

        // Apply italic formatting
        input = applyRegex(input, italicRegex, function(match, start, end) {
            var format = new FlxTextFormat(FlxColor.WHITE, false, true);
            addFormat(format, start, end);
        });

        // Apply color formatting
        input = applyRegex(input, colorRegex, function(match, start, end) {
            var color = Std.parseInt("0x" + match.matched(2));
            var format = new FlxTextFormat(color);
            addFormat(format, start, end);
        });

        // Set the processed text
        text = input;

        return this;
    }

    /**
     * Helper function to apply a regex and execute a callback for each match.
     * @param input The input string.
     * @param regex The regex to match.
     * @param callback A function to execute for each match.
     * @return The input string with markers removed.
     */
    private function applyRegex(input:String, regex:EReg, callback:(EReg, Int, Int) -> Void):String {
        while (regex.match(input)) {
            var start = regex.matchedPos().pos;
            var end = start + regex.matchedPos().len;
            callback(regex, start, end);
            input = input.substr(0, start) + regex.matched(2) + input.substr(end); // Remove markers
        }
        return input;
    }
}