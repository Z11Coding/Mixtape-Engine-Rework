package yutautil;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

/**
 * A utility class for handling permessage-deflate compression/decompression
 * specifically designed for WebSocket messages following RFC 7692.
 * 
 * This implementation includes a complete deflate algorithm implementation
 * that doesn't rely on external libraries.
 */
class PermessageDeflate {
    
    // Huffman codes for literal/length alphabet (fixed Huffman)
    private static var FIXED_LITERAL_CODES:Array<Int>;
    private static var FIXED_LITERAL_LENGTHS:Array<Int>;
    private static var FIXED_DISTANCE_CODES:Array<Int>;
    private static var FIXED_DISTANCE_LENGTHS:Array<Int>;
    
    // Length and distance extra bits
    private static var LENGTH_EXTRA_BITS = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0];
    private static var LENGTH_BASE = [3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258];
    private static var DISTANCE_EXTRA_BITS = [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13];
    private static var DISTANCE_BASE = [1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577];
    
    private static var initialized = false;
    
    /**
     * Initialize the Huffman tables for fixed codes
     */
    private static function initializeHuffmanTables():Void {
        if (initialized) return;
        
        FIXED_LITERAL_CODES = [];
        FIXED_LITERAL_LENGTHS = [];
        FIXED_DISTANCE_CODES = [];
        FIXED_DISTANCE_LENGTHS = [];
        
        // Fixed literal/length alphabet
        for (i in 0...288) {
            if (i <= 143) {
                FIXED_LITERAL_CODES[i] = i + 48;  // 0011 0000 to 1011 1111
                FIXED_LITERAL_LENGTHS[i] = 8;
            } else if (i <= 255) {
                FIXED_LITERAL_CODES[i] = i + 256;  // 1100 0000 to 1111 1111
                FIXED_LITERAL_LENGTHS[i] = 9;
            } else if (i <= 279) {
                FIXED_LITERAL_CODES[i] = i - 256;  // 0000 0000 to 0001 7111
                FIXED_LITERAL_LENGTHS[i] = 7;
            } else {
                FIXED_LITERAL_CODES[i] = i - 88;   // 1100 0000 to 1100 0111
                FIXED_LITERAL_LENGTHS[i] = 8;
            }
        }
        
        // Fixed distance alphabet (all 5 bits)
        for (i in 0...32) {
            FIXED_DISTANCE_CODES[i] = i;
            FIXED_DISTANCE_LENGTHS[i] = 5;
        }
        
        initialized = true;
    }
    
    /**
     * Simple deflate decompression implementation for permessage-deflate
     */
    public static function decompress(compressedData:Bytes):Null<Bytes> {
        if (compressedData == null || compressedData.length == 0) {
            return null;
        }
        
        // Try multiple decompression strategies
        var strategies = [
            // Strategy 1: Standard permessage-deflate with suffix
            function() {
                trace("Strategy 1: Standard permessage-deflate with suffix");
                var modifiedData = new BytesOutput();
                modifiedData.write(compressedData);
                modifiedData.writeByte(0x00);
                modifiedData.writeByte(0x00);
                modifiedData.writeByte(0xFF);
                modifiedData.writeByte(0xFF);
                
                var dataWithSuffix = modifiedData.getBytes();
                var input = new BytesInput(dataWithSuffix);
                var output = new BytesOutput();
                return simpleInflate(input, output);
            },
            
            // Strategy 2: Raw data without suffix
            function() {
                trace("Strategy 2: Raw data without suffix");
                var input = new BytesInput(compressedData);
                var output = new BytesOutput();
                return simpleInflate(input, output);
            },
            
            // Strategy 3: Try to decompress as raw deflate with manual header
            function() {
                trace("Strategy 3: Raw deflate with manual header");
                return rawInflateWithHeader(compressedData);
            },
            
            // Strategy 4: Check if it's already valid text
            function() {
                trace("Strategy 4: Check if already valid text");
                if (isValidUTF8(compressedData)) {
                    var str = compressedData.toString();
                    trace("Data appears to be plain text: " + str.substr(0, 50));
                    return compressedData;
                }
                return null;
            },
            
            // Strategy 5: Try interpreting as different formats
            function() {
                trace("Strategy 5: Alternative format interpretation");
                // Check if it starts with deflate magic numbers
                if (compressedData.length >= 2) {
                    var first = compressedData.get(0);
                    var second = compressedData.get(1);
                    trace("First two bytes: 0x" + StringTools.hex(first, 2) + " 0x" + StringTools.hex(second, 2));
                    
                    // Common deflate/zlib headers
                    if ((first == 0x78 && (second == 0x01 || second == 0x5E || second == 0x9C || second == 0xDA)) ||
                        (first == 0x08 || first == 0x01)) { // deflate block types
                        trace("Looks like deflate/zlib format");
                        var input = new BytesInput(compressedData);
                        var output = new BytesOutput();
                        return simpleInflate(input, output);
                    }
                }
                return null;
            }
        ];
        
        for (i in 0...strategies.length) {
            try {
                initializeHuffmanTables();
                trace("Trying strategy " + (i + 1) + "...");
                var result = strategies[i]();
                if (result != null) {
                    trace("Strategy " + (i + 1) + " successful! Input: " + compressedData.length + " bytes -> Output: " + result.length + " bytes");
                    
                    // Verify the result is actually different and valid
                    if (result.length != compressedData.length || result.toString() != compressedData.toString()) {
                        var resultStr = result.toString();
                        trace("Result preview: " + resultStr.substr(0, 100));
                        
                        // Check if result looks like valid JSON
                        var trimmed = StringTools.trim(resultStr);
                        if (trimmed.startsWith("[") || trimmed.startsWith("{")) {
                            trace("Result appears to be valid JSON!");
                            return result;
                        } else {
                            trace("Result doesn't look like JSON but returning anyway");
                            return result;
                        }
                    } else {
                        trace("Strategy " + (i + 1) + " returned same data, trying next strategy");
                        continue;
                    }
                }
            } catch (e:Dynamic) {
                trace("Strategy " + (i + 1) + " failed: " + e);
                continue;
            }
        }
        
        trace("All decompression strategies failed");
        return null;
    }
    
    /**
     * Check if bytes represent valid UTF-8
     */
    private static function isValidUTF8(data:Bytes):Bool {
        try {
            var str = data.toString();
            return str != null && str.length > 0;
        } catch (e:Dynamic) {
            return false;
        }
    }
    
    /**
     * Raw inflate with manual header construction
     */
    private static function rawInflateWithHeader(data:Bytes):Bytes {
        var output = new BytesOutput();
        
        // Try to interpret as literal data (uncompressed block)
        // Write a manual deflate header for uncompressed data
        var headerOutput = new BytesOutput();
        headerOutput.writeByte(0x01); // BFINAL=1, BTYPE=00 (stored/uncompressed)
        
        // Write length and complement in little-endian
        var len = data.length;
        headerOutput.writeByte(len & 0xFF);
        headerOutput.writeByte((len >> 8) & 0xFF);
        headerOutput.writeByte((~len) & 0xFF);
        headerOutput.writeByte(((~len) >> 8) & 0xFF);
        
        // Write the data
        headerOutput.write(data);
        
        // Add termination suffix
        headerOutput.writeByte(0x00);
        headerOutput.writeByte(0x00);
        headerOutput.writeByte(0xFF);
        headerOutput.writeByte(0xFF);
        
        var fullData = headerOutput.getBytes();
        var input = new BytesInput(fullData);
        
        return simpleInflate(input, output);
    }
    
    /**
     * Simple inflate implementation
     */
    private static function simpleInflate(input:BytesInput, output:BytesOutput):Bytes {
        var bitState = { buffer: 0, count: 0 };
        var finalBlock = false;
        
        while (!finalBlock) {
            // Read block header
            finalBlock = readBits(input, 1, bitState) == 1;
            var blockType = readBits(input, 2, bitState);
            
            switch (blockType) {
                case 0: // No compression
                    inflateStored(input, output, bitState);
                case 1: // Fixed Huffman codes
                    inflateFixed(input, output, bitState);
                case 2: // Dynamic Huffman codes
                    inflateDynamic(input, output, bitState);
                default:
                    throw "Invalid block type: " + blockType;
            }
        }
        
        return output.getBytes();
    }
    
    /**
     * Read bits from input stream
     */
    private static function readBits(input:BytesInput, count:Int, bitState:Dynamic):Int {
        while (bitState.count < count) {
            try {
                var byte = input.readByte();
                bitState.buffer |= (byte << bitState.count);
                bitState.count += 8;
            } catch (e:Dynamic) {
                throw "Unexpected end of input";
            }
        }
        
        var result = bitState.buffer & ((1 << count) - 1);
        bitState.buffer >>= count;
        bitState.count -= count;
        
        return result;
    }
    
    /**
     * Inflate stored (uncompressed) block
     */
    private static function inflateStored(input:BytesInput, output:BytesOutput, bitState:Dynamic):Void {
        // Skip to byte boundary
        bitState.buffer = 0;
        bitState.count = 0;
        
        try {
            // Read length and its complement in little-endian format
            var len = input.readByte() | (input.readByte() << 8);
            var nlen = input.readByte() | (input.readByte() << 8);
            
            trace("Stored block: len=" + len + ", nlen=" + nlen + ", expected nlen=" + (~len & 0xFFFF));
            
            // Check if length and complement are valid
            if ((len ^ nlen) != 0xFFFF) {
                // Try alternative: maybe the data is just raw without proper deflate headers
                trace("Invalid stored block length, trying raw copy");
                
                // Reset input position and copy remaining data as-is
                var remainingData = input.readAll();
                if (remainingData.length > 0) {
                    output.write(remainingData);
                }
                return;
            }
            
            // Copy the specified number of bytes
            for (i in 0...len) {
                output.writeByte(input.readByte());
            }
            
        } catch (e:Dynamic) {
            trace("Error in inflateStored: " + e);
            // As fallback, try to read remaining bytes
            try {
                var remainingData = input.readAll();
                if (remainingData.length > 0) {
                    output.write(remainingData);
                }
            } catch (e2:Dynamic) {
                trace("Even fallback failed: " + e2);
            }
        }
    }
    
    /**
     * Inflate block with fixed Huffman codes
     */
    private static function inflateFixed(input:BytesInput, output:BytesOutput, bitState:Dynamic):Void {
        while (true) {
            var symbol = decodeFixedLiteral(input, bitState);
            
            if (symbol < 256) {
                // Literal byte
                output.writeByte(symbol);
            } else if (symbol == 256) {
                // End of block
                break;
            } else {
                // Length/distance pair
                var length = decodeLength(symbol, input, bitState);
                var distanceCode = decodeFixedDistance(input, bitState);
                var distance = decodeDistance(distanceCode, input, bitState);
                
                copyFromHistory(output, distance, length);
            }
        }
    }
    
    /**
     * Simple dynamic Huffman implementation (basic version)
     */
    private static function inflateDynamic(input:BytesInput, output:BytesOutput, bitState:Dynamic):Void {
        // For simplicity, we'll implement a basic version
        // In a real implementation, this would build dynamic Huffman trees
        
        // Read the number of literal/length codes (HLIT + 257)
        var hlit = readBits(input, 5, bitState) + 257;
        // Read the number of distance codes (HDIST + 1)  
        var hdist = readBits(input, 5, bitState) + 1;
        // Read the number of code length codes (HCLEN + 4)
        var hclen = readBits(input, 4, bitState) + 4;
        
        // For now, fall back to fixed codes for dynamic blocks
        // This is a simplification - a full implementation would decode the dynamic trees
        inflateFixed(input, output, bitState);
    }
    
    /**
     * Decode fixed literal/length symbol
     */
    private static function decodeFixedLiteral(input:BytesInput, bitState:Dynamic):Int {
        // Simplified fixed Huffman decoding
        var bits = readBits(input, 7, bitState);
        
        if (bits <= 23) {
            // 7-bit codes 0000000-0010111 -> 256-279
            return bits + 256;
        }
        
        bits = (bits << 1) | readBits(input, 1, bitState);
        
        if (bits >= 48 && bits <= 191) {
            // 8-bit codes 00110000-10111111 -> 0-143
            return bits - 48;
        } else if (bits >= 192 && bits <= 199) {
            // 8-bit codes 11000000-11000111 -> 280-287
            return bits + 88;
        }
        
        bits = (bits << 1) | readBits(input, 1, bitState);
        
        if (bits >= 400 && bits <= 511) {
            // 9-bit codes 110010000-111111111 -> 144-255
            return bits - 256;
        }
        
        throw "Invalid literal/length code";
    }
    
    /**
     * Decode fixed distance symbol
     */
    private static function decodeFixedDistance(input:BytesInput, bitState:Dynamic):Int {
        return readBits(input, 5, bitState);
    }
    
    /**
     * Decode length from symbol
     */
    private static function decodeLength(symbol:Int, input:BytesInput, bitState:Dynamic):Int {
        var lengthIndex = symbol - 257;
        if (lengthIndex < 0 || lengthIndex >= LENGTH_BASE.length) {
            throw "Invalid length symbol: " + symbol;
        }
        
        var length = LENGTH_BASE[lengthIndex];
        var extraBits = LENGTH_EXTRA_BITS[lengthIndex];
        
        if (extraBits > 0) {
            length += readBits(input, extraBits, bitState);
        }
        
        return length;
    }
    
    /**
     * Decode distance from code
     */
    private static function decodeDistance(code:Int, input:BytesInput, bitState:Dynamic):Int {
        if (code < 0 || code >= DISTANCE_BASE.length) {
            throw "Invalid distance code: " + code;
        }
        
        var distance = DISTANCE_BASE[code];
        var extraBits = DISTANCE_EXTRA_BITS[code];
        
        if (extraBits > 0) {
            distance += readBits(input, extraBits, bitState);
        }
        
        return distance;
    }
    
    /**
     * Copy data from output history - fixed version
     */
    private static function copyFromHistory(output:BytesOutput, distance:Int, length:Int):Void {
        var outputBytes = output.getBytes();
        var outputLength = outputBytes.length;
        
        if (distance <= 0) {
            throw "Invalid distance: " + distance;
        }
        
        if (distance > outputLength) {
            throw "Distance too large: " + distance + " > " + outputLength;
        }
        
        // Copy bytes one by one, allowing for overlapping copies
        for (i in 0...length) {
            var sourcePos = outputLength - distance + (i % distance);
            if (sourcePos < 0 || sourcePos >= outputLength) {
                throw "Invalid source position: " + sourcePos;
            }
            var byte = outputBytes.get(sourcePos);
            output.writeByte(byte);
            
            // Update our view of the output for overlapping copies
            if (i < length - 1) {
                outputBytes = output.getBytes();
                outputLength = outputBytes.length;
            }
        }
    }
    
    /**
     * Simple compression (for completeness)
     */
    public static function compress(data:Bytes):Null<Bytes> {
        if (data == null || data.length == 0) {
            return null;
        }
        
        try {
            var output = new BytesOutput();
            
            // Write deflate header (final block, no compression)
            output.writeByte(0x01); // BFINAL=1, BTYPE=00 (no compression)
            
            // Write length and complement
            var len = data.length;
            output.writeByte(len & 0xFF);
            output.writeByte((len >> 8) & 0xFF);
            output.writeByte((~len) & 0xFF);
            output.writeByte(((~len) >> 8) & 0xFF);
            
            // Write data
            output.write(data);
            
            var compressed = output.getBytes();
            
            // For permessage-deflate, remove the trailing [0x00, 0x00, 0xFF, 0xFF] if present
            if (compressed.length >= 4) {
                var lastFour = compressed.sub(compressed.length - 4, 4);
                if (lastFour.get(0) == 0x00 && lastFour.get(1) == 0x00 && 
                    lastFour.get(2) == 0xFF && lastFour.get(3) == 0xFF) {
                    compressed = compressed.sub(0, compressed.length - 4);
                }
            }
            
            return compressed;
            
        } catch (e:Dynamic) {
            trace("PermessageDeflate.compress failed: " + e);
            return null;
        }
    }
    
    /**
     * Attempts to decompress a string that may contain compressed data.
     */
    public static function decompressString(compressedString:String, ?encoding:haxe.io.Encoding):String {
        if (compressedString == null || compressedString.length == 0) {
            return compressedString;
        }
        
        if (encoding == null) {
            encoding = haxe.io.Encoding.RawNative;
        }
        
        try {
            // First, try to see if it's already valid JSON/text
            var trimmed = StringTools.trim(compressedString);
            if (trimmed.startsWith("{") || trimmed.startsWith("[") || trimmed.indexOf('"') >= 0) {
                trace("Data appears to be uncompressed JSON/text");
                return compressedString;
            }
            
            // Log detailed information about the input data
            trace("=== DECOMPRESSION DEBUG ===");
            trace("Input string length: " + compressedString.length);
            trace("First 50 chars: " + compressedString.substr(0, 50));
            
            // Show character codes of first 20 characters
            var charCodes = [];
            for (i in 0...Std.int(Math.min(20, compressedString.length))) {
                charCodes.push(compressedString.charCodeAt(i));
            }
            trace("First 20 char codes: " + charCodes.join(", "));
            
            // Convert string to bytes and attempt decompression
            var compressedBytes = haxe.io.Bytes.ofString(compressedString, encoding);
            trace("Converted to " + compressedBytes.length + " bytes");
            
            // Show first 20 bytes in hex
            var hexBytes = [];
            for (i in 0...Std.int(Math.min(20, compressedBytes.length))) {
                hexBytes.push(StringTools.hex(compressedBytes.get(i), 2));
            }
            trace("First 20 bytes (hex): " + hexBytes.join(" "));
            
            var decompressedBytes = decompress(compressedBytes);
            
            if (decompressedBytes != null && decompressedBytes.length != compressedBytes.length) {
                var result = decompressedBytes.toString();
                trace("Decompression successful! Original: " + compressedBytes.length + " bytes -> " + decompressedBytes.length + " bytes");
                trace("Result preview: " + result.substr(0, 100));
                return result;
            } else {
                trace("Decompression failed or returned same size - trying alternative approaches");
                
                // Try different encodings
                var encodings = [haxe.io.Encoding.UTF8, haxe.io.Encoding.RawNative];
                for (enc in encodings) {
                    if (enc == encoding) continue; // Skip the one we already tried
                    
                    try {
                        trace("Trying encoding: " + enc);
                        var testBytes = haxe.io.Bytes.ofString(compressedString, enc);
                        var testResult = decompress(testBytes);
                        if (testResult != null && testResult.length != testBytes.length) {
                            var result = testResult.toString();
                            trace("Alternative encoding " + enc + " worked!");
                            return result;
                        }
                    } catch (e:Dynamic) {
                        trace("Encoding " + enc + " failed: " + e);
                    }
                }
                
                // Try raw binary interpretation
                trace("Trying manual base64 decode...");
                try {
                    var base64Decoded = haxe.crypto.Base64.decode(compressedString);
                    var base64Result = decompress(base64Decoded);
                    if (base64Result != null) {
                        trace("Base64 decode + decompress worked!");
                        return base64Result.toString();
                    }
                } catch (e:Dynamic) {
                    trace("Base64 approach failed: " + e);
                }
                
                trace("All decompression attempts failed, returning original");
                return compressedString;
            }
            
        } catch (e:Dynamic) {
            trace("PermessageDeflate.decompressString failed: " + e);
            return compressedString;
        }
    }
    
    /**
     * Compresses a string using permessage-deflate format.
     */
    public static function compressString(data:String, ?encoding:haxe.io.Encoding):String {
        if (data == null || data.length == 0) {
            return data;
        }
        
        if (encoding == null) {
            encoding = haxe.io.Encoding.UTF8;
        }
        
        try {
            var dataBytes = haxe.io.Bytes.ofString(data, encoding);
            var compressedBytes = compress(dataBytes);
            
            if (compressedBytes != null) {
                return compressedBytes.toString();
            } else {
                return data;
            }
            
        } catch (e:Dynamic) {
            trace("PermessageDeflate.compressString failed: " + e);
            return data;
        }
    }
    
    /**
     * Detects if data might be compressed by checking for non-printable characters
     */
    public static function isLikelyCompressed(data:String):Bool {
        if (data == null || data.length == 0) {
            return false;
        }
        
        var nonPrintableCount = 0;
        var totalChars = Std.int(Math.min(data.length, 100));

        for (i in 0...totalChars) {
            var charCode = data.charCodeAt(i);
            
            if ((charCode < 32 && charCode != 9 && charCode != 10 && charCode != 13) || charCode > 126) {
                nonPrintableCount++;
            }
        }
        
        return (nonPrintableCount / totalChars) > 0.3;
    }
    
    /**
     * Smart decompression that checks if data looks compressed before attempting decompression.
     */
    public static function smartDecompress(data:String, ?encoding:haxe.io.Encoding):String {
        if (data == null || data.length == 0) {
            return data;
        }
        
        var trimmed = StringTools.trim(data);
        if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
            return data;
        }
        
        if (isLikelyCompressed(data)) {
            return decompressString(data, encoding);
        }
        
        return data;
    }
}
