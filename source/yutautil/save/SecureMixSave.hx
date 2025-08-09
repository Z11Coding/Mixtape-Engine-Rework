package yutautil.save;

import haxe.crypto.Base64;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import sys.io.File;
import deflatex.Deflate;
import deflatex.Inflate;

/**
 * A secure wrapper for MixSave that provides compression and encryption
 * to prevent easy editing and reduce file size.
 */
@:privateAccess(yutautil.save.MixSaveWrapper)
class SecureMixSave {
    private var mixSaveWrapper:MixSaveWrapper;
    private var encryptionKey:String;
    private var compressionLevel:Int;
    private var useCompression:Bool;
    private var useEncryption:Bool;
    
    // File signature to identify secure save files
    private static inline var SECURE_SIGNATURE:String = "SMIX1.0";
    
    /**
     * Creates a new SecureMixSave instance
     * @param filePath Path to the save file (will use .smix extension)
     * @param encryptionKey Key used for encryption (if null, uses a default obfuscation)
     * @param compressionLevel Compression level (0-9, higher = better compression but slower)
     * @param useCompression Whether to enable compression
     * @param useEncryption Whether to enable encryption
     * @param autoLoad Whether to automatically load the file if it exists
     */
    public function new(filePath:String = "save/mixsave.smix", 
                       ?encryptionKey:String, 
                       compressionLevel:Int = 6,
                       useCompression:Bool = true,
                       useEncryption:Bool = true,
                       autoLoad:Bool = true) {
        
        // Ensure proper file extension
        if (!filePath.endsWith(".smix")) {
            filePath = filePath.replace(".json", "") + ".smix";
        }
        
        this.compressionLevel = Math.round(Math.max(0, Math.min(9, compressionLevel)));
        this.useCompression = useCompression;
        this.useEncryption = useEncryption;
        
        // Generate encryption key if not provided
        this.encryptionKey = encryptionKey != null ? encryptionKey : generateDefaultKey(filePath);
        
        // Create internal MixSaveWrapper with a temporary path (we handle file I/O ourselves)
        this.mixSaveWrapper = new MixSaveWrapper(new MixSave(), filePath, false);
        
        if (sys.FileSystem.exists(filePath) && autoLoad) {
            load();
        }
    }

    static public function createWithMixSave(mixSave:MixSave, filePath:String = "save/mixsave.smix", 
                                              ?encryptionKey:String, 
                                              compressionLevel:Int = 6,
                                              useCompression:Bool = true,
                                              useEncryption:Bool = true):SecureMixSave {
        var secureSave = new SecureMixSave(filePath, encryptionKey, compressionLevel, useCompression, useEncryption);
        secureSave.mixSaveWrapper = new MixSaveWrapper(mixSave, filePath, false);
        return secureSave;
    }

    /**
     * Generates a default encryption key based on the file path
     * This provides basic obfuscation but not cryptographic security
     */
    private function generateDefaultKey(filePath:String):String {
        var baseKey = "MixtapeEngine_" + filePath + "_SecureKey_2025";
        return Sha256.encode(baseKey).substr(0, 32);
    }
    
    /**
     * Simple XOR encryption/decryption
     * Not cryptographically secure but provides obfuscation
     */
    private function xorEncrypt(data:Bytes, key:String):Bytes {
        if (!useEncryption) return data;
        
        var keyBytes = Bytes.ofString(key);
        var result = Bytes.alloc(data.length);
        
        for (i in 0...data.length) {
            result.set(i, data.get(i) ^ keyBytes.get(i % keyBytes.length));
        }
        
        return result;
    }
    
    /**
     * Compress data using deflate
     */
    private function compress(data:Bytes):Bytes {
        if (!useCompression) return data;
        
        try {
            var compressed = Deflate.run(data, compressionLevel);
            return compressed;
        } catch (e:Dynamic) {
            trace("Compression failed: " + e);
            return data; // Return uncompressed data on failure
        }
    }
    
    /**
     * Decompress data using inflate
     */
    private function decompress(data:Bytes):Bytes {
        if (!useCompression) return data;
        
        try {
            var decompressed = Inflate.run(data);
            return decompressed;
        } catch (e:Dynamic) {
            trace("Decompression failed: " + e);
            return data; // Return data as-is on failure
        }
    }
    
    /**
     * Save the MixSave data in a secure format
     */
    public function save():Void {
        // Get the JSON data from the internal MixSaveWrapper
        var fileContent = new Map<String, String>();
        for (key in mixSaveWrapper.mixSave.content.keys()) {
            fileContent.set(key, mixSaveWrapper.mixSave.saveContent(key));
        }
        
        var jsonString = haxe.Json.stringify(fileContent, null, mixSaveWrapper.fancyFormat ? "\t" : null);
        var jsonBytes = Bytes.ofString(jsonString);
        
        // Create header with metadata
        var header = createHeader();
        var headerBytes = Bytes.ofString(header);
        
        // Compress if enabled
        var processedData = compress(jsonBytes);
        
        // Encrypt if enabled
        processedData = xorEncrypt(processedData, encryptionKey);
        
        // Combine header and data
        var output = new BytesOutput();
        output.writeBytes(headerBytes, 0, headerBytes.length);
        output.writeBytes(processedData, 0, processedData.length);
        
        // Ensure directory exists
        var dir = haxe.io.Path.directory(mixSaveWrapper.filePath);
        if (!sys.FileSystem.exists(dir)) {
            sys.FileSystem.createDirectory(dir);
        }
        
        // Write to file
        File.saveBytes(mixSaveWrapper.filePath, output.getBytes());
    }
    
    /**
     * Load the secure MixSave data
     */
    public function load():Void {
        if (!sys.FileSystem.exists(mixSaveWrapper.filePath)) {
            return;
        }
        
        try {
            var fileBytes = File.getBytes(mixSaveWrapper.filePath);
            
            // Read and validate header
            var headerSize = readHeader(fileBytes);
            if (headerSize == -1) {
                throw "Invalid secure save file format";
            }
            
            // Extract data portion
            var dataBytes = fileBytes.sub(headerSize, fileBytes.length - headerSize);
            
            // Decrypt if needed
            dataBytes = xorEncrypt(dataBytes, encryptionKey);
            
            // Decompress if needed
            dataBytes = decompress(dataBytes);
            
            // Parse JSON
            var jsonString = dataBytes.toString();
            var parsedContent = haxe.Json.parse(jsonString);
            
            // Load into MixSave
            mixSaveWrapper.mixSave.content = new Map();
            for (key in Reflect.fields(parsedContent)) {
                var value = Reflect.field(parsedContent, key);
                mixSaveWrapper.mixSave.loadContent(key, value);
            }
            
        } catch (e:Dynamic) {
            trace("Failed to load secure save file: " + e);
            // Initialize with empty content on failure
            mixSaveWrapper.mixSave.content = new Map();
        }
    }
    
    /**
     * Create a header with metadata about the file format
     */
    private function createHeader():String {
        var metadata = {
            signature: SECURE_SIGNATURE,
            compressed: useCompression,
            encrypted: useEncryption,
            compressionLevel: compressionLevel,
            timestamp: Date.now().getTime()
        };
        
        var headerJson = haxe.Json.stringify(metadata);
        var headerLength = headerJson.length;
        
        // Format: [4 bytes length][JSON header]
        return String.fromCharCode((headerLength >> 24) & 0xFF) +
               String.fromCharCode((headerLength >> 16) & 0xFF) +
               String.fromCharCode((headerLength >> 8) & 0xFF) +
               String.fromCharCode(headerLength & 0xFF) +
               headerJson;
    }
    
    /**
     * Read and validate the header, returns header size or -1 if invalid
     */
    private function readHeader(fileBytes:Bytes):Int {
        if (fileBytes.length < 4) return -1;
        
        // Read header length
        var headerLength = (fileBytes.get(0) << 24) |
                          (fileBytes.get(1) << 16) |
                          (fileBytes.get(2) << 8) |
                          fileBytes.get(3);
        
        if (headerLength < 0 || headerLength > fileBytes.length - 4) return -1;
        
        // Read header JSON
        var headerBytes = fileBytes.sub(4, headerLength);
        var headerJson = headerBytes.toString();
        
        try {
            var metadata = haxe.Json.parse(headerJson);
            
            // Validate signature
            if (metadata.signature != SECURE_SIGNATURE) {
                throw "Invalid signature";
            }
            
            // Update settings based on file metadata
            this.useCompression = metadata.compressed;
            this.useEncryption = metadata.encrypted;
            this.compressionLevel = metadata.compressionLevel;
            
            return 4 + headerLength;
            
        } catch (e:Dynamic) {
            return -1;
        }
    }
    
    // Delegate methods to internal MixSaveWrapper
    public function addItem(key:String, value:Dynamic):Void {
        mixSaveWrapper.addItem(key, value);
    }
    
    public function getItem(key:String):Dynamic {
        return mixSaveWrapper.getItem(key);
    }
    
    public function removeItem(key:String):Void {
        mixSaveWrapper.removeItem(key);
    }
    
    public function hasItem(key:String):Bool {
        return mixSaveWrapper.hasItem(key);
    }
    
    public function editItem(key:String, value:Dynamic):Void {
        mixSaveWrapper.editItem(key, value);
    }
    
    public function clear():Void {
        mixSaveWrapper.clear();
    }
    
    public function addObject(thing:Dynamic):Void {
        mixSaveWrapper.addObject(thing);
    }
    
    public function isEmpty():Bool {
        return mixSaveWrapper.isEmpty();
    }
    
    public function toMap():Map<String, Dynamic> {
        return mixSaveWrapper.toMap();
    }
    
    public function toDynamic():Dynamic {
        return mixSaveWrapper.toDynamic();
    }
    
    // Additional properties
    public var fancyFormat(get, set):Bool;
    private function get_fancyFormat():Bool {
        return mixSaveWrapper.fancyFormat;
    }
    private function set_fancyFormat(value:Bool):Bool {
        return mixSaveWrapper.fancyFormat = value;
    }
    
    public var filePath(get, never):String;
    private function get_filePath():String {
        return mixSaveWrapper.filePath;
    }
    
    /**
     * Get information about the security settings
     */
    public function getSecurityInfo():Dynamic {
        return {
            compressionEnabled: useCompression,
            encryptionEnabled: useEncryption,
            compressionLevel: compressionLevel,
            fileExtension: ".smix"
        };
    }
    
    /**
     * Convert a regular MixSaveWrapper to SecureMixSave
     */
    public static function fromMixSaveWrapper(wrapper:MixSaveWrapper, 
                                            newFilePath:String,
                                            ?encryptionKey:String,
                                            compressionLevel:Int = 6,
                                            useCompression:Bool = true,
                                            useEncryption:Bool = true):SecureMixSave {
        var secure = new SecureMixSave(newFilePath, encryptionKey, compressionLevel, useCompression, useEncryption, false);
        secure.mixSaveWrapper.mixSave.content = wrapper.mixSave.content.copy();
        secure.mixSaveWrapper.fancyFormat = wrapper.fancyFormat;
        return secure;
    }
    
    /**
     * Create a SecureMixSave with default settings optimized for save files
     */
    public static function createSecure(filePath:String = "save/mixsave.smix", ?encryptionKey:String):SecureMixSave {
        return new SecureMixSave(filePath, encryptionKey, 6, true, true, true);
    }
    
    /**
     * Create a SecureMixSave with compression only (no encryption)
     */
    public static function createCompressed(filePath:String = "save/mixsave.smix"):SecureMixSave {
        return new SecureMixSave(filePath, null, 9, true, false, true);
    }
}
