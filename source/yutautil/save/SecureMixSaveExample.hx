package yutautil.save;

/**
 * Example demonstrating how to use SecureMixSave for compressed and encrypted save files
 */
class SecureMixSaveExample {
    public static function basicUsage():Void {
        trace("=== SecureMixSave Basic Usage Example ===");
        
        // Create a secure save with default settings (compression + encryption)
        var secureSave = SecureMixSave.createSecure("save/player_data.smix");
        
        // Add some data
        secureSave.addItem("playerName", "TestPlayer");
        secureSave.addItem("level", 42);
        secureSave.addItem("score", 98765);
        secureSave.addItem("settings", {
            volume: 0.8,
            difficulty: "Hard",
            achievements: ["first_win", "combo_master", "perfectionist"]
        });
        
        // Save to file (compressed and encrypted)
        secureSave.save();
        trace("Secure save created at: " + secureSave.filePath);
        
        // Load it back
        var loadedSave = new SecureMixSave("save/player_data.smix");
        trace("Loaded player name: " + loadedSave.getItem("playerName"));
        trace("Loaded level: " + loadedSave.getItem("level"));
        trace("Loaded score: " + loadedSave.getItem("score"));
        
        var settings = loadedSave.getItem("settings");
        trace("Loaded settings: " + haxe.Json.stringify(settings));
        
        trace("Security info: " + haxe.Json.stringify(loadedSave.getSecurityInfo()));
    }
    
    public static function compressionOnlyExample():Void {
        trace("\n=== SecureMixSave Compression-Only Example ===");
        
        // Create a save with compression but no encryption
        var compressedSave = SecureMixSave.createCompressed("save/game_data.smix");
        
        // Add large amounts of data to see compression benefits
        var largeData = [];
        for (i in 0...1000) {
            largeData.push({
                id: i,
                name: "Item_" + i,
                description: "This is a test item with ID " + i + " used for demonstrating compression.",
                properties: {
                    rarity: ["Common", "Uncommon", "Rare", "Epic", "Legendary"][i % 5],
                    value: i * 100,
                    category: "test_category_" + (i % 10)
                }
            });
        }
        
        compressedSave.addItem("inventory", largeData);
        compressedSave.addItem("gameVersion", "1.0.0");
        compressedSave.addItem("timestamp", Date.now().toString());
        
        compressedSave.save();
        trace("Compressed save created at: " + compressedSave.filePath);
        
        // Check file size
        var fileSize = sys.FileSystem.stat(compressedSave.filePath).size;
        trace("File size: " + fileSize + " bytes");
        
        // Load and verify
        var loadedCompressed = new SecureMixSave("save/game_data.smix");
        var loadedInventory = loadedCompressed.getItem("inventory");
        trace("Loaded inventory items: " + loadedInventory.length);
        trace("Security info: " + haxe.Json.stringify(loadedCompressed.getSecurityInfo()));
    }
    
    public static function customEncryptionExample():Void {
        trace("\n=== SecureMixSave Custom Encryption Example ===");
        
        // Create a save with custom encryption key
        var customKey = "MySecretGameKey_2025!";
        var secureSave = new SecureMixSave("save/secret_data.smix", customKey, 9, true, true, false);
        
        // Add sensitive data
        secureSave.addItem("secretCode", "CHEAT_ENABLED");
        secureSave.addItem("unlockAllLevels", true);
        secureSave.addItem("debugMode", true);
        secureSave.addItem("adminSettings", {
            godMode: false,
            infiniteHealth: false,
            skipCutscenes: true
        });
        
        secureSave.save();
        trace("Secret save created with custom encryption");
        
        // Try to load with wrong key (should fail gracefully)
        var wrongKeySave = new SecureMixSave("save/secret_data.smix", "WrongKey");
        trace("Loaded with wrong key - secret code: " + wrongKeySave.getItem("secretCode"));
        
        // Load with correct key
        var correctKeySave = new SecureMixSave("save/secret_data.smix", customKey);
        trace("Loaded with correct key - secret code: " + correctKeySave.getItem("secretCode"));
    }
    
    public static function migrationExample():Void {
        trace("\n=== SecureMixSave Migration Example ===");
        
        // Create a regular MixSaveWrapper
        var regularSave = new MixSaveWrapper(new MixSave(), "save/old_save.json", false);
        regularSave.addItem("playerName", "OldPlayer");
        regularSave.addItem("progress", 75);
        regularSave.addItem("coins", 12500);
        regularSave.save();
        trace("Created regular save file");
        
        // Load the regular save
        var loadedRegular = new MixSaveWrapper(new MixSave(), "save/old_save.json");
        
        // Convert to secure save
        var secureMigrated = SecureMixSave.fromMixSaveWrapper(
            loadedRegular, 
            "save/migrated_save.smix", 
            "migration_key_123"
        );
        
        // Add new secure data
        secureMigrated.addItem("migrationDate", Date.now().toString());
        secureMigrated.addItem("secureVersion", true);
        
        secureMigrated.save();
        trace("Migrated to secure save format");
        
        // Verify migration
        var verifyMigration = new SecureMixSave("save/migrated_save.smix", "migration_key_123");
        trace("Migrated player name: " + verifyMigration.getItem("playerName"));
        trace("Migrated progress: " + verifyMigration.getItem("progress"));
        trace("Migration date: " + verifyMigration.getItem("migrationDate"));
    }
    
    public static function performanceTest():Void {
        trace("\n=== SecureMixSave Performance Test ===");
        
        var testData = {
            largeArray: [],
            nestedObject: {},
            textData: ""
        };
        
        // Generate test data
        for (i in 0...5000) {
            testData.largeArray.push({
                index: i,
                value: Math.random() * 1000,
                text: "Performance test data item " + i
            });
        }
        
        for (i in 0...100) {
            Reflect.setField(testData.nestedObject, "key" + i, {
                subdata: [i, i*2, i*3, i*4, i*5],
                metadata: "nested_" + i
            });
        }
        
        // Create large text
        var baseText = "This is a test string for compression efficiency measurement. ";
        for (i in 0...10) {
            testData.textData += baseText;
        }
        
        // Test different configurations
        var configs = [
            {name: "No compression, no encryption", compress: false, encrypt: false},
            {name: "Compression only", compress: true, encrypt: false},
            {name: "Encryption only", compress: false, encrypt: true},
            {name: "Both compression and encryption", compress: true, encrypt: true}
        ];
        
        for (config in configs) {
            var startTime = Date.now().getTime();
            
            var save = new SecureMixSave(
                "save/perf_test_" + config.name.toLowerCase().replace(" ", "_") + ".smix",
                "test_key",
                9,
                config.compress,
                config.encrypt,
                false
            );
            
            save.addItem("testData", testData);
            save.save();
            
            var saveTime = Date.now().getTime() - startTime;
            var fileSize = sys.FileSystem.stat(save.filePath).size;
            
            startTime = Date.now().getTime();
            var loadedSave = new SecureMixSave(save.filePath, "test_key");
            var loadTime = Date.now().getTime() - startTime;
            
            trace(config.name + ":");
            trace("  Save time: " + saveTime + "ms");
            trace("  Load time: " + loadTime + "ms");
            trace("  File size: " + fileSize + " bytes");
            trace("");
        }
    }
    
    public static function runAllExamples():Void {
        trace("Running SecureMixSave Examples...\n");
        
        try {
            basicUsage();
            compressionOnlyExample();
            customEncryptionExample();
            migrationExample();
            performanceTest();
            
            trace("\n=== All examples completed successfully! ===");
        } catch (e:Dynamic) {
            trace("Error running examples: " + e);
        }
    }
}
