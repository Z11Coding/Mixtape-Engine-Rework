package managers;

import backend.Song.DynamicSongConfig;
import managers.DynamicSongManager;
import states.PlayState;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

/**
 * Dynamic Song Scripting Support
 * Provides Lua and HScript integration for dynamic songs
 */
class DynamicSongScripting
{
    /**
     * Register dynamic song functions with Lua scripts
     */
    #if LUA_ALLOWED
    public static function registerLuaFunctions(lua:FunkinLua):Void
    {
        // Check if current song is dynamic
        lua.set("isDynamicSong", function():Bool {
            return DynamicSongManager.instance != null && DynamicSongManager.instance.isActive;
        });

        // Get current dynamic section info
        lua.set("getCurrentDynamicSection", function():Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;
            return DynamicSongManager.instance.getCurrentSectionInfo();
        });

        // Get all section names
        lua.set("getDynamicSections", function():Array<String> {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return [];
            return DynamicSongManager.instance.currentSections.copy();
        });

        // Get section info by name
        lua.set("getDynamicSectionInfo", function(sectionName:String):Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;

            var config = DynamicSongManager.instance.currentConfig;
            if (config == null || !config.sections.exists(sectionName))
                return null;

            var section = config.sections.get(sectionName);
            return {
                name: sectionName,
                duration: section.duration,
                canRepeat: section.canRepeat ?? false,
                weight: section.weight ?? 1.0,
                chartFile: section.chartFile,
                hasVocals: section.audioFiles.vocals != null ||
                          section.audioFiles.vocalsPlayer != null ||
                          section.audioFiles.vocalsOpponent != null ||
                          section.audioFiles.vocalsGF != null
            };
        });

        // Get dynamic song metadata
        lua.set("getDynamicSongMetadata", function():Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;
            return DynamicSongManager.instance.currentConfig.metadata;
        });

        // Get section start times
        lua.set("getDynamicSectionTimes", function():Array<Float> {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return [];
            return DynamicSongManager.instance.sectionStartTimes.copy();
        });

        // Debug: Get current audio section info
        lua.set("getCurrentAudioSection", function():Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;
            return DynamicSongManager.instance.audioManager.getCurrentSectionInfo();
        });

        // Helper function to generate default section sequence
        lua.set("generateDefaultSectionSequence", function(sections:Dynamic):Array<String> {
            var sectionList:Array<String> = [];
            var sectionNames = Reflect.fields(sections);

            // Simple default: add all sections in order
            for (name in sectionNames)
            {
                sectionList.push(name);
            }

            return sectionList;
        });

        // Helper function for simple random generation
        lua.set("generateRandomSectionSequence", function(sections:Dynamic, startSection:String, endSection:String, middleSections:Array<String>, count:Int):Array<String> {
            var sequence:Array<String> = [];

            // Add start section
            if (startSection != null && startSection.length > 0)
            {
                sequence.push(startSection);
            }

            // Add random middle sections
            var availableMiddle = middleSections.copy();
            var actualCount = count == -1 ? availableMiddle.length : Math.min(count, availableMiddle.length);
            var actualCountInt = Std.int(actualCount);

            for (i in 0...actualCountInt)
            {
                if (availableMiddle.length == 0) break;
                var randomIndex = Math.floor(Math.random() * availableMiddle.length);
                sequence.push(availableMiddle[randomIndex]);
                availableMiddle.splice(randomIndex, 1);
            }

            // Add end section
            if (endSection != null && endSection.length > 0)
            {
                sequence.push(endSection);
            }

            return sequence;
        });
    }
    #end

    /**
     * Register dynamic song functions with HScript
     */
    #if HSCRIPT_ALLOWED
    public static function registerHScriptFunctions(hscript:psychlua.HScript):Void
    {
        // Check if current song is dynamic
        hscript.set("isDynamicSong", function():Bool {
            return DynamicSongManager.instance != null && DynamicSongManager.instance.isActive;
        });

        // Get current dynamic section info
        hscript.set("getCurrentDynamicSection", function():Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;
            return DynamicSongManager.instance.getCurrentSectionInfo();
        });

        // Get all section names
        hscript.set("getDynamicSections", function():Array<String> {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return [];
            return DynamicSongManager.instance.currentSections.copy();
        });

        // Get section info by name
        hscript.set("getDynamicSectionInfo", function(sectionName:String):Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;

            var config = DynamicSongManager.instance.currentConfig;
            if (config == null || !config.sections.exists(sectionName))
                return null;

            var section = config.sections.get(sectionName);
            return {
                name: sectionName,
                duration: section.duration,
                canRepeat: section.canRepeat ?? false,
                weight: section.weight ?? 1.0,
                chartFile: section.chartFile,
                hasVocals: section.audioFiles.vocals != null ||
                          section.audioFiles.vocalsPlayer != null ||
                          section.audioFiles.vocalsOpponent != null ||
                          section.audioFiles.vocalsGF != null
            };
        });

        // Get dynamic song metadata
        hscript.set("getDynamicSongMetadata", function():Dynamic {
            if (DynamicSongManager.instance == null || !DynamicSongManager.instance.isActive)
                return null;
            return DynamicSongManager.instance.currentConfig.metadata;
        });

        // Helper classes and functions
        hscript.set("DynamicSongManager", DynamicSongManager);
        hscript.set("Math", Math);
        hscript.set("Std", Std);

        // Array utilities for HScript
        hscript.set("shuffleArray", function(arr:Array<Dynamic>):Array<Dynamic> {
            var shuffled = arr.copy();
            for (i in 0...shuffled.length)
            {
                var j = Math.floor(Math.random() * shuffled.length);
                var temp = shuffled[i];
                shuffled[i] = shuffled[j];
                shuffled[j] = temp;
            }
            return shuffled;
        });
    }
    #end

    /**
     * Create example Lua script for dynamic song generation
     */
    public static function getExampleLuaScript():String
    {
        return '
-- Example Dynamic Song Generation Script
-- This function is called to generate the section sequence for a dynamic song

function generateSongSections(sections, metadata, gameState)
    local sequence = {}

    -- Always start with intro if it exists
    if sections.intro then
        table.insert(sequence, "intro")
    end

    -- Choose verse based on difficulty or performance
    if gameState.difficulty > 2 then
        if sections.verse_hard then
            table.insert(sequence, "verse_hard")
        elseif sections.verse_normal then
            table.insert(sequence, "verse_normal")
        end
    else
        if sections.verse_normal then
            table.insert(sequence, "verse_normal")
        elseif sections.verse_easy then
            table.insert(sequence, "verse_easy")
        end
    end

    -- Add chorus
    if sections.chorus then
        table.insert(sequence, "chorus")
    end

    -- Randomly decide on bridge or solo (50/50 chance)
    if math.random() > 0.5 then
        if sections.bridge then
            table.insert(sequence, "bridge")
        end
    else
        if sections.solo then
            table.insert(sequence, "solo")
        end
    end

    -- Second chorus
    if sections.chorus then
        table.insert(sequence, "chorus")
    end

    -- Always end with outro if it exists
    if sections.outro then
        table.insert(sequence, "outro")
    end

    return sequence
end

-- Advanced example with performance-based selection
function generateAdvancedSections(sections, metadata, gameState)
    local sequence = {}

    table.insert(sequence, "intro")

    -- Performance-based verse selection
    local accuracy = gameState.accuracy or 0
    if accuracy > 0.95 then
        table.insert(sequence, "verse_expert")
    elseif accuracy > 0.8 then
        table.insert(sequence, "verse_hard")
    elseif accuracy > 0.6 then
        table.insert(sequence, "verse_normal")
    else
        table.insert(sequence, "verse_easy")
    end

    table.insert(sequence, "chorus")

    -- Health-based middle section
    local health = gameState.health or 1
    if health > 1.5 then
        table.insert(sequence, "power_section")
    elseif health < 0.5 then
        table.insert(sequence, "recovery_section")
    else
        table.insert(sequence, "normal_section")
    end

    table.insert(sequence, "chorus")
    table.insert(sequence, "outro")

    return sequence
end
';
    }

    /**
     * Create example HScript for dynamic song generation
     */
    public static function getExampleHScript():String
    {
        return '
// Example Dynamic Song Generation Script (HScript)
// This function is called to generate the section sequence for a dynamic song

function generateSongSections(sections, metadata, gameState) {
    var sequence = [];

    // Always start with intro
    if (Reflect.hasField(sections, "intro")) {
        sequence.push("intro");
    }

    // Adaptive difficulty based on player performance
    var accuracy = gameState.accuracy != null ? gameState.accuracy : 0;
    var misses = gameState.misses != null ? gameState.misses : 0;

    if (misses < 5 && accuracy > 0.9) {
        // Expert performance - use harder sections
        if (Reflect.hasField(sections, "verse_expert")) {
            sequence.push("verse_expert");
        } else if (Reflect.hasField(sections, "verse_hard")) {
            sequence.push("verse_hard");
        }
    } else if (misses < 15 && accuracy > 0.7) {
        // Good performance - use normal sections
        if (Reflect.hasField(sections, "verse_normal")) {
            sequence.push("verse_normal");
        }
    } else {
        // Poor performance - use easier sections
        if (Reflect.hasField(sections, "verse_easy")) {
            sequence.push("verse_easy");
        } else if (Reflect.hasField(sections, "verse_normal")) {
            sequence.push("verse_normal");
        }
    }

    // Add chorus
    if (Reflect.hasField(sections, "chorus")) {
        sequence.push("chorus");
    }

    // Random selection for variety
    var middleOptions = [];
    if (Reflect.hasField(sections, "bridge")) middleOptions.push("bridge");
    if (Reflect.hasField(sections, "solo")) middleOptions.push("solo");
    if (Reflect.hasField(sections, "breakdown")) middleOptions.push("breakdown");

    if (middleOptions.length > 0) {
        var randomChoice = middleOptions[Math.floor(Math.random() * middleOptions.length)];
        sequence.push(randomChoice);
    }

    // Final chorus and outro
    if (Reflect.hasField(sections, "chorus")) {
        sequence.push("chorus");
    }

    if (Reflect.hasField(sections, "outro")) {
        sequence.push("outro");
    }

    return sequence;
}

// Simple random generation helper
function generateRandomSequence(sections, startSection, endSection, middleSections, count) {
    var sequence = [];

    if (startSection != null && startSection.length > 0) {
        sequence.push(startSection);
    }

    var availableMiddle = middleSections.copy();
    var actualCount = count == -1 ? availableMiddle.length : Math.min(count, availableMiddle.length);
    var actualCountInt = Std.int(actualCount);

    for (i in 0...actualCountInt) {
        if (availableMiddle.length == 0) break;
        var randomIndex = Math.floor(Math.random() * availableMiddle.length);
        sequence.push(availableMiddle[randomIndex]);
        availableMiddle.splice(randomIndex, 1);
    }

    if (endSection != null && endSection.length > 0) {
        sequence.push(endSection);
    }

    return sequence;
}
';
    }
}
