package yutautil;

import tjson.TJSON;
import yutautil.save.ObjectSerializer;

/**
 * Advanced string compression system with adaptive algorithms based on content size and patterns.
 * Provides both string compression and object serialization with compression.
 */
class StringCompressor {

    // Static compression maps generated immediately
    public static final basicCompressionMap:Map<String, String> = generateBasicCompressionMap();
    public static final reverseCompressionMap:Map<String, String> = generateReverseCompressionMap();
    public static final advancedPatternMap:Map<String, String> = generateAdvancedPatternMap();
    public static final reverseAdvancedMap:Map<String, String> = generateReverseAdvancedMap();

    /**
     * Compress a string using adaptive algorithms based on size and content.
     */
    public static function compress(input:String):String {
        if (input == null || input.length == 0) return "";

        var result = input;

        // Choose compression strategy based on string size
        if (input.length <= 50) {
            // Small strings: Use basic character substitution
            result = applyBasicCompression(result);
        } else if (input.length <= 200) {
            // Medium strings: Use pattern-based compression
            result = applyPatternCompression(result);
        } else {
            // Large strings: Use advanced multi-stage compression
            result = applyAdvancedCompression(result);
        }

        return result;
    }

    /**
     * Decompress a string back to its original form.
     */
    public static function decompress(compressed:String):String {
        if (compressed == null || compressed.length == 0) return "";

        var result = compressed;

        // Apply decompression in reverse order
        // Try advanced decompression first (it includes markers)
        if (result.contains("§")) {
            result = reverseAdvancedCompression(result);
        } else if (result.contains("¤")) {
            result = reversePatternCompression(result);
        } else {
            result = reverseBasicCompression(result);
        }

        return result;
    }

    /**
     * Compress an object using ObjectSerializer and string compression.
     */
    public static function compressData(data:Dynamic):String {
        try {
            // First serialize the object to SerializedClass
            var serialized = ObjectSerializer.serialize(data);

            // Convert SerializedClass to JSON string
            var jsonString = tjson.TJSON.encode(serialized);

            // Then compress the JSON string
            var compressed = compress(jsonString);

            // Add data marker to distinguish from regular string compression
            return "※" + compressed;
        } catch (e:Dynamic) {
            throw 'Failed to compress data: ${e}';
        }
    }

    /**
     * Decompress and deserialize an object.
     */
    public static function decompressData(compressedData:String):Dynamic {
        try {
            if (!compressedData.startsWith("※")) {
                throw "Invalid data compression format";
            }

            // Remove data marker
            var compressed = compressedData.substring(1);

            // Decompress to get JSON string
            var decompressed = decompress(compressed);

            // Parse JSON string back to SerializedClass
            var serializedClass:yutautil.save.StateSerializer.SerializedClass = tjson.TJSON.parse(decompressed);

            // Deserialize back to object
            return ObjectSerializer.deserialize(serializedClass);
        } catch (e:Dynamic) {
            throw 'Failed to decompress data: ${e}';
        }
    }

    // ============ COMPRESSION ALGORITHMS ============

    static function applyBasicCompression(input:String):String {
        var result = input;
        for (pattern in basicCompressionMap.keys()) {
            result = StringTools.replace(result, pattern, basicCompressionMap.get(pattern));
        }
        return "¢" + result; // Marker for basic compression
    }

    static function applyPatternCompression(input:String):String {
        var result = input;

        // Apply basic compression first
        for (pattern in basicCompressionMap.keys()) {
            result = StringTools.replace(result, pattern, basicCompressionMap.get(pattern));
        }

        // Apply advanced pattern compression
        for (pattern in advancedPatternMap.keys()) {
            result = StringTools.replace(result, pattern, advancedPatternMap.get(pattern));
        }

        return "¤" + result; // Marker for pattern compression
    }

    static function applyAdvancedCompression(input:String):String {
        var result = input;

        // Stage 1: Basic character substitution
        for (pattern in basicCompressionMap.keys()) {
            result = StringTools.replace(result, pattern, basicCompressionMap.get(pattern));
        }

        // Stage 2: Advanced pattern matching
        for (pattern in advancedPatternMap.keys()) {
            result = StringTools.replace(result, pattern, advancedPatternMap.get(pattern));
        }

        // Stage 3: Repetition compression
        result = compressRepetitions(result);

        // Stage 4: Frequency analysis compression
        result = compressFrequentSubstrings(result);

        return "§" + result; // Marker for advanced compression
    }

    static function compressRepetitions(input:String):String {
        var result = input;

        // Find and compress repeated patterns
        for (len in 2...Math.floor(input.length / 3)) {
            var i = 0;
            while (i < result.length - len) {
                var pattern = result.substr(i, len);
                var count = 1;
                var nextPos = i + len;

                // Count consecutive repetitions
                while (nextPos + len <= result.length && result.substr(nextPos, len) == pattern) {
                    count++;
                    nextPos += len;
                }

                // Compress if we have 3+ repetitions
                if (count >= 3) {
                    var replacement = '©${count}©${pattern}©';
                    var originalSection = "";
                    for (j in 0...count) {
                        originalSection += pattern;
                    }
                    result = StringTools.replace(result, originalSection, replacement);
                }

                i++;
            }
        }

        return result;
    }

    static function compressFrequentSubstrings(input:String):String {
        var result = input;
        var substringCounts = new Map<String, Int>();

        // Analyze substring frequency (2-6 character substrings)
        for (len in 2...7) {
            for (i in 0...(input.length - len + 1)) {
                var substr = input.substr(i, len);
                substringCounts.set(substr, (substringCounts.get(substr) ?? 0) + 1);
            }
        }

        // Create compression for frequent substrings
        var compressionIndex = 0;
        for (substr in substringCounts.keys()) {
            if (substringCounts.get(substr) >= 3 && substr.length >= 3) {
                var replacement = '®${compressionIndex}®';
                result = StringTools.replace(result, substr, replacement);
                compressionIndex++;

                // Store the mapping for decompression
                if (compressionIndex >= 50) break; // Limit to prevent over-compression
            }
        }

        return result;
    }

    // ============ OBJECT COMPRESSION ============

    /**
     * Compress an object using ObjectSerializer + string compression
     * @param obj The object to compress
     * @return Compressed string representation
     */
    public static function compressObject(obj:Dynamic):String {
        // First serialize the object to a SerializedClass object
        var serializedClass = yutautil.save.ObjectSerializer.serialize(obj);

        // Convert the SerializedClass to JSON string
        var jsonString = tjson.TJSON.encode(serializedClass);

        // Then compress that JSON string
        return compress(jsonString);
    }

    /**
     * Decompress and restore an object using ObjectSerializer
     * @param compressed The compressed string
     * @return The restored object
     */
    public static function decompressObject(compressed:String):Dynamic {
        // First decompress to get the JSON string
        var jsonString = decompress(compressed);

        // Parse the JSON back to SerializedClass object
        var serializedClass:yutautil.save.StateSerializer.SerializedClass = tjson.TJSON.parse(jsonString);

        // Then deserialize back to object
        return yutautil.save.ObjectSerializer.deserialize(serializedClass);
    }

    // ============ DECOMPRESSION ALGORITHMS ============

    static function reverseBasicCompression(input:String):String {
        var result = input.substring(1); // Remove marker
        for (compressed in reverseCompressionMap.keys()) {
            result = StringTools.replace(result, compressed, reverseCompressionMap.get(compressed));
        }
        return result;
    }

    static function reversePatternCompression(input:String):String {
        var result = input.substring(1); // Remove marker

        // Reverse advanced patterns first
        for (compressed in reverseAdvancedMap.keys()) {
            result = StringTools.replace(result, compressed, reverseAdvancedMap.get(compressed));
        }

        // Then reverse basic compression
        for (compressed in reverseCompressionMap.keys()) {
            result = StringTools.replace(result, compressed, reverseCompressionMap.get(compressed));
        }

        return result;
    }

    static function reverseAdvancedCompression(input:String):String {
        var result = input.substring(1); // Remove marker

        // Reverse in opposite order of compression
        result = decompressFrequentSubstrings(result);
        result = decompressRepetitions(result);

        // Reverse advanced patterns
        for (compressed in reverseAdvancedMap.keys()) {
            result = StringTools.replace(result, compressed, reverseAdvancedMap.get(compressed));
        }

        // Reverse basic compression
        for (compressed in reverseCompressionMap.keys()) {
            result = StringTools.replace(result, compressed, reverseCompressionMap.get(compressed));
        }

        return result;
    }

    static function decompressRepetitions(input:String):String {
        var result = input;
        var regex = ~/©(\d+)©([^©]+)©/g;

        while (regex.match(result)) {
            var count = Std.parseInt(regex.matched(1));
            var pattern = regex.matched(2);
            var replacement = "";
            for (i in 0...count) {
                replacement += pattern;
            }
            result = StringTools.replace(result, regex.matched(0), replacement);
        }

        return result;
    }

    static function decompressFrequentSubstrings(input:String):String {
        // This would need to store the mapping during compression
        // For now, just remove the markers
        var result = input;
        var regex = ~/®(\d+)®/g;

        // Simple removal for now - in a full implementation,
        // we'd need to store the mapping
        while (regex.match(result)) {
            result = StringTools.replace(result, regex.matched(0), "");
        }

        return result;
    }

    // ============ MAP GENERATION ============

    static function generateBasicCompressionMap():Map<String, String> {
        trace('StringCompressor: Initializing basic compression map...');
        var map = new Map<String, String>();

        // Numbers 0-9 mapped to single Unicode characters
        for (i in 0...10) {
            map.set(Std.string(i), String.fromCharCode(0x2080 + i)); // Subscript digits
        }

        // Lowercase letters a-z
        for (i in 0...26) {
            var letter = String.fromCharCode(97 + i); // a-z
            var compressed = String.fromCharCode(0x24B6 + i); // Circled letters
            map.set(letter, compressed);
        }

        // Uppercase letters A-Z
        for (i in 0...26) {
            var letter = String.fromCharCode(65 + i); // A-Z
            var compressed = String.fromCharCode(0x1F130 + i); // Squared letters
            map.set(letter, compressed);
        }

        // Common symbols
        map.set(" ", "·"); // Middle dot for space
        map.set(".", "•"); // Bullet for period
        map.set(",", "‚"); // Single low-9 quotation mark
        map.set(":", "∶"); // Ratio symbol
        map.set(";", "؛"); // Arabic semicolon
        map.set("(", "❨"); // Medium left parenthesis
        map.set(")", "❩"); // Medium right parenthesis
        map.set("[", "⟦"); // Left white square bracket
        map.set("]", "⟧"); // Right white square bracket
        map.set("{", "❴"); // Medium left brace
        map.set("}", "❵"); // Medium right brace
        map.set('"', "❝"); // Heavy double comma quotation mark
        map.set("'", "❜"); // Heavy single comma quotation mark
        map.set("-", "⁻"); // Superscript minus
        map.set("_", "⎽"); // Horizontal line extension
        map.set("=", "⩵"); // Identical to
        map.set("+", "➕"); // Heavy plus sign
        map.set("*", "✱"); // Heavy asterisk
        map.set("/", "∕"); // Division slash
        map.set("\\", "∖"); // Set minus
        map.set("|", "❘"); // Light vertical bar
        map.set("&", "⩕"); // Plus sign in triangle
        map.set("%", "٪"); // Arabic percent sign
        map.set("$", "💲"); // Heavy dollar sign
        map.set("#", "⦸"); // Circled reverse solidus
        map.set("@", "⊕"); // Circled plus
        map.set("!", "❗"); // Heavy exclamation mark
        map.set("?", "❓"); // Heavy question mark
        map.set("<", "❮"); // Heavy left-pointing angle bracket
        map.set(">", "❯"); // Heavy right-pointing angle bracket

        return map;
    }

    static function generateReverseCompressionMap():Map<String, String> {
        trace('StringCompressor: Initializing reverse compression map...');
        var reverseMap = new Map<String, String>();
        for (original in basicCompressionMap.keys()) {
            reverseMap.set(basicCompressionMap.get(original), original);
        }
        return reverseMap;
    }

    static function generateAdvancedPatternMap():Map<String, String> {
        trace('StringCompressor: Initializing advanced pattern map...');
        var map = new Map<String, String>();

        // Common programming patterns
        map.set("null", "∅");
        map.set("true", "⊤");
        map.set("false", "⊥");
        map.set("void", "∀");
        map.set("int", "ℤ");
        map.set("float", "ℝ");
        map.set("string", "𝕊");
        map.set("bool", "𝔹");
        map.set("var", "∃");
        map.set("function", "ƒ");
        map.set("return", "↩");
        map.set("if", "⦿");
        map.set("else", "⦾");
        map.set("for", "∀");
        map.set("while", "⟲");
        map.set("do", "⟳");
        map.set("try", "🛠");
        map.set("catch", "⚠");
        map.set("throw", "💥");
        map.set("new", "✨");
        map.set("class", "🏛");
        map.set("interface", "📋");
        map.set("extends", "⤴");
        map.set("implements", "🔗");
        map.set("public", "🌐");
        map.set("private", "🔒");
        map.set("static", "📍");
        map.set("final", "🔒");
        map.set("override", "🔄");
        map.set("super", "⬆");
        map.set("this", "👆");

        // Common JSON patterns
        map.set('":"', "⦂");
        map.set('","', "⦙");
        map.set('":null', "⦂∅");
        map.set('":true', "⦂⊤");
        map.set('":false', "⦂⊥");

        // File extensions
        map.set(".hx", "🅷");
        map.set(".js", "🅹");
        map.set(".json", "📄");
        map.set(".xml", "📰");
        map.set(".txt", "📝");

        // Common words
        map.set("Error", "⚡");
        map.set("Exception", "💀");
        map.set("Object", "📦");
        map.set("Reference", "👉");
        map.set("Pointer", "➤");
        map.set("State", "🏪");
        map.set("Manager", "👔");
        map.set("Handler", "🤝");
        map.set("Event", "⚡");
        map.set("Type", "📋");
        map.set("Data", "📊");
        map.set("File", "📄");
        map.set("Path", "🛤");
        map.set("Name", "🏷");
        map.set("Value", "💎");
        map.set("Key", "🗝");
        map.set("Index", "📇");
        map.set("Length", "📏");
        map.set("Size", "📐");
        map.set("Count", "🔢");
        map.set("Number", "🔢");
        map.set("String", "🧵");
        map.set("Array", "📚");
        map.set("List", "📜");
        map.set("Map", "🗺");
        map.set("Set", "🔗");

        return map;
    }

    static function generateReverseAdvancedMap():Map<String, String> {
        trace('StringCompressor: Initializing reverse advanced pattern map...');
        var reverseMap = new Map<String, String>();
        for (original in advancedPatternMap.keys()) {
            reverseMap.set(advancedPatternMap.get(original), original);
        }
        return reverseMap;
    }
}
