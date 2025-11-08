package managers;

import backend.Conductor;
import backend.Paths;
import backend.Song.DynamicSection;
import backend.Song.DynamicSectionChart;
import backend.Song.DynamicSongConfig;
import backend.Song.DynamicTransition;
import backend.Song.SwagSong;
import backend.Song;
import flixel.FlxG;
import flixel.sound.FlxSound;
import haxe.Json;
import lime.utils.Assets;
import managers.DynamicAudioManager;
import states.PlayState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript;
#end

/**
 * Dynamic Song Manager
 * Handles the loading, processing, and stitching of dynamic songs with randomized sections.
 * Creates seamless song experiences by combining multiple chart and audio sections.
 */
class DynamicSongManager
{
    // Static instance for global access
    public static var instance:DynamicSongManager;

    // Current dynamic song configuration
    public var currentConfig:DynamicSongConfig;
    public var isActive:Bool = false;
    public var currentSections:Array<String> = [];
    public var currentSectionIndex:Int = 0;
    public var sectionStartTimes:Array<Float> = [];

    // Stitched song data
    public var stitchedSong:SwagSong;
    public var stitchedAudioDuration:Float = 0;

    // Audio management
    public var audioManager:DynamicAudioManager;

    public function new()
    {
        instance = this;
        audioManager = new DynamicAudioManager();
    }

    /**
     * Check if a song is a dynamic song by looking for dynamic.json
     */
    public static function isDynamicSong(songPath:String):Bool
    {
        var dynamicPath = Paths.getPath('data/$songPath/dynamic.json', TEXT, null, true);

        #if MODS_ALLOWED
        return FileSystem.exists(dynamicPath);
        #else
        return Assets.exists(dynamicPath);
        #end
    }

    /**
     * Load and process a dynamic song configuration
     */
    public function loadDynamicSong(songPath:String):Bool
    {
        try
        {
            var dynamicPath = Paths.getPath('data/$songPath/dynamic.json', TEXT, null, true);
            var configData:String = null;

            #if MODS_ALLOWED
            if (FileSystem.exists(dynamicPath))
                configData = File.getContent(dynamicPath);
            else
            #end
                configData = Assets.getText(dynamicPath);

            if (configData == null) return false;

            currentConfig = Json.parse(configData);
            if (currentConfig.format != "mixtape_dynamic_v1")
            {
                trace('DynamicSongManager: Unsupported format: ${currentConfig.format}');
                return false;
            }

            // Generate section sequence
            generateSectionSequence();

            // Stitch the song together
            stitchSong();

            // Create stitched audio - this creates single FlxSound objects compatible with PlayState
            var audioResult = audioManager.createStitchedAudio(currentConfig, currentSections);

            // Store audio references for PlayState to use
            stitchedSong.dynamicAudio = audioResult;
            stitchedSong.isDynamic = true;
            stitchedSong.sectionSequence = currentSections;

            isActive = true;
            trace('DynamicSongManager: Successfully loaded dynamic song: ${currentConfig.songName}');
            trace('DynamicSongManager: Section sequence: ${currentSections.join(" -> ")}');

            return true;
        }
        catch (e:Dynamic)
        {
            trace('DynamicSongManager: Error loading dynamic song: $e');
            return false;
        }
    }

    /**
     * Generate the sequence of sections to play based on flow configuration
     */
    function generateSectionSequence():Void
    {
        currentSections = [];
        sectionStartTimes = [];
        var currentTime:Float = 0;

        // Generate sections based on flow mode
        switch (currentConfig.flow.generationMode)
        {
            case "programmatic":
                currentSections = generateProgrammaticSequence();

            case "simple_random":
                currentSections = generateSimpleRandomSequence();

            case "custom":
                currentSections = generateCustomSequence();

            default:
                trace('DynamicSongManager: Unknown generation mode: ${currentConfig.flow.generationMode}');
                currentSections = generateFallbackSequence();
        }

        // Calculate start times for each section
        for (sectionName in currentSections)
        {
            sectionStartTimes.push(currentTime);
            var section = currentConfig.sections.get(sectionName);
            if (section != null)
            {
                currentTime += section.duration;
            }
        }

        stitchedAudioDuration = currentTime;
        trace('DynamicSongManager: Generated ${currentSections.length} sections, total duration: ${stitchedAudioDuration}ms');
    }

    /**
     * Generate sequence using programmatic/script approach
     */
    function generateProgrammaticSequence():Array<String>
    {
        var generatorFunction = currentConfig.flow.generator ?? "generateSongSections";
        var sequence:Array<String> = null;

        #if LUA_ALLOWED
        // Try Lua first
        if (PlayState.instance != null)
        {
            for (script in PlayState.instance.luaArray)
            {
                if (script.scriptName.endsWith('.lua'))
                {
                  var script:FunkinLua = cast script;
                    var luaResult = script.call(generatorFunction, [
                        convertSectionsForScript(),
                        currentConfig.metadata,
                        createGameStateData(new Map())
                    ]);

                    if (luaResult != null && Std.isOfType(luaResult, Array))
                    {
                        sequence = cast {LuaResult:luaResult}.LuaResult;
                        break;
                    }
                }
            }
        }
        #end

        #if HSCRIPT_ALLOWED
        // Try HScript if Lua didn't work
        if (sequence == null && PlayState.instance != null)
        {
            for (script in PlayState.instance.hscriptArray)
            {
                try
                {
                    var hscriptResult = script.call(generatorFunction, [
                        convertSectionsForScript(),
                        currentConfig.metadata,
                        createGameStateData(new Map())
                    ]);

                    if (hscriptResult != null && Std.isOfType(hscriptResult.returnValue, Array))
                    {
                        sequence = cast hscriptResult.returnValue;
                        break;
                    }
                }
                catch (e:Dynamic)
                {
                    trace('DynamicSongManager: HScript error in sequence generation: $e');
                }
            }
        }
        #end

        // Fallback to simple sequence if script failed
        if (sequence == null || sequence.length == 0)
        {
            trace('DynamicSongManager: Programmatic generation failed, using fallback');
            return generateFallbackSequence();
        }

        // Validate that all sections exist
        var validatedSequence:Array<String> = [];
        for (sectionName in sequence)
        {
            if (currentConfig.sections.exists(sectionName))
            {
                validatedSequence.push(sectionName);
            }
            else
            {
                trace('DynamicSongManager: Warning - section "$sectionName" does not exist, skipping');
            }
        }

        return validatedSequence.length > 0 ? validatedSequence : generateFallbackSequence();
    }

    /**
     * Generate sequence using simple random mode
     */
    function generateSimpleRandomSequence():Array<String>
    {
        var config = currentConfig.flow.simpleRandom;
        if (config == null)
        {
            trace('DynamicSongManager: Simple random mode specified but no config provided');
            return generateFallbackSequence();
        }

        var sequence:Array<String> = [];

        // Add start section
        if (currentConfig.sections.exists(config.startSection))
        {
            sequence.push(config.startSection);
        }

        // Add middle sections
        var availableMiddle = config.middleSections.copy();
        var middleCount = config.middleCount;

        if (middleCount == -1)
        {
            // Use all middle sections in random order
            for (i in 0...availableMiddle.length)
            {
                var j = FlxG.random.int(0, availableMiddle.length - 1);
                var temp = availableMiddle[i];
                availableMiddle[i] = availableMiddle[j];
                availableMiddle[j] = temp;
            }
            sequence = sequence.concat(availableMiddle);
        }
        else
        {
            // Use specific number of middle sections
            middleCount = Std.int(Math.min(middleCount, availableMiddle.length));
            for (i in 0...middleCount)
            {
                var randomIndex = FlxG.random.int(0, availableMiddle.length - 1);
                sequence.push(availableMiddle[randomIndex]);
                availableMiddle.splice(randomIndex, 1);
            }
        }

        // Add end section
        if (currentConfig.sections.exists(config.endSection))
        {
            sequence.push(config.endSection);
        }

        return sequence;
    }

    /**
     * Generate sequence using custom mode (extensible for future features)
     */
    function generateCustomSequence():Array<String>
    {
        trace('DynamicSongManager: Custom generation mode not yet implemented');
        return generateFallbackSequence();
    }

    /**
     * Generate a basic fallback sequence (all sections in order)
     */
    function generateFallbackSequence():Array<String>
    {
        var sections:Array<String> = [];
        for (sectionName in currentConfig.sections.keys())
        {
            sections.push(sectionName);
        }
        return sections;
    }

    /**
     * Convert sections map to format suitable for scripts
     */
    function convertSectionsForScript():Dynamic
    {
        var sectionsObj:Dynamic = {};
        for (sectionName in currentConfig.sections.keys())
        {
            var section = currentConfig.sections.get(sectionName);
            Reflect.setField(sectionsObj, sectionName, {
                duration: section.duration,
                canRepeat: section.canRepeat ?? false,
                weight: section.weight ?? 1.0,
                chartFile: section.chartFile,
                hasVocals: section.audioFiles.vocals != null ||
                          section.audioFiles.vocalsPlayer != null ||
                          section.audioFiles.vocalsOpponent != null ||
                          section.audioFiles.vocalsGF != null
            });
        }
        return sectionsObj;
    }

    /**
     * Create game state data for script functions
     */
    function createGameStateData(visitedSections:Map<String, Int>):Dynamic
    {
        var gameState:Dynamic = {};

        if (PlayState.instance != null)
        {
            gameState.health = PlayState.instance.health;
            gameState.score = PlayState.instance.comboManager?.songScore ?? 0;
            gameState.misses = PlayState.instance.comboManager?.songMisses ?? 0;
            gameState.hits = PlayState.instance.comboManager?.songHits ?? 0;
            gameState.accuracy = PlayState.instance.comboManager?.ratingPercent ?? 0;
            // Calculate current step and beat from Conductor data
            gameState.curStep = Math.floor(Conductor.songPosition / Conductor.stepCrochet);
            gameState.curBeat = Math.floor(Conductor.songPosition / Conductor.crochet);
            gameState.difficulty = PlayState.storyDifficulty;
        }

        gameState.visitedSections = visitedSections;
        gameState.currentSections = currentSections;
        gameState.sectionIndex = currentSectionIndex;

        return gameState;
    }

    /**
     * Stitch together the selected sections into a single song
     */
    function stitchSong():Void
    {
        if (currentSections.length == 0) return;

        // Create base song structure from first section
        var firstSectionName = currentSections[0];
        var firstSection = currentConfig.sections.get(firstSectionName);
        var firstChart = loadSectionChart(firstSection.chartFile);

        stitchedSong = {
            song: currentConfig.songName,
            notes: [],
            events: [],
            bpm: firstChart.bpm,
            needsVoices: hasVocals(),
            speed: PlayState.SONG?.speed ?? 1.0,
            offset: firstChart.offset,
            player1: PlayState.SONG?.player1 ?? "bf",
            player2: PlayState.SONG?.player2 ?? "dad",
            player4: PlayState.SONG?.player4 ?? "",
            player5: PlayState.SONG?.player5 ?? "",
            gfVersion: PlayState.SONG?.gfVersion ?? "gf",
            stage: PlayState.SONG?.stage ?? "stage",
            format: "mixtape_dynamic_v1",
            mania: PlayState.SONG?.mania,
            startMania: PlayState.SONG?.startMania
        };

        // Stitch together chart data
        var currentTime:Float = 0;
        var currentSection:Int = 0;

        for (i in 0...currentSections.length)
        {
            var sectionName = currentSections[i];
            var section = currentConfig.sections.get(sectionName);
            var chart = loadSectionChart(section.chartFile);

            // Add notes with time offset
            for (note in chart.notes)
            {
                var adjustedNote = adjustNoteTime(note, currentTime);
                stitchedSong.notes.push(adjustedNote);
            }

            // Add events with time offset
            for (event in chart.events)
            {
                var adjustedEvent = adjustEventTime(event, currentTime);
                stitchedSong.events.push(adjustedEvent);
            }

            currentTime += section.duration;
        }

        // Sort notes and events by time
        stitchedSong.notes.sort(function(a:Dynamic, b:Dynamic):Int {
            return Std.int(a[0] - b[0]);
        });

        stitchedSong.events.sort(function(a:Dynamic, b:Dynamic):Int {
            return Std.int(a[0] - b[0]);
        });

        trace('DynamicSongManager: Stitched song with ${stitchedSong.notes.length} notes and ${stitchedSong.events.length} events');
    }

    /**
     * Load a section chart file
     */
    function loadSectionChart(chartFile:String):DynamicSectionChart
    {
        var chartPath = Paths.getPath('data/${currentConfig.songName}/$chartFile', TEXT, null, true);
        var chartData:String = null;

        #if MODS_ALLOWED
        if (FileSystem.exists(chartPath))
            chartData = File.getContent(chartPath);
        else
        #end
            chartData = Assets.getText(chartPath);

        return Json.parse(chartData);
    }

    /**
     * Adjust note timing for stitched song
     */
    function adjustNoteTime(note:Dynamic, timeOffset:Float):Dynamic
    {
        var adjustedNote:Dynamic = {};
        for (field in Reflect.fields(note))
        {
            Reflect.setField(adjustedNote, field, Reflect.field(note, field));
        }

        // Adjust time (first element in note array)
        if (Std.isOfType(note, Array))
        {
            var noteArray:Array<Dynamic> = cast note;
            if (noteArray.length > 0)
            {
                noteArray[0] = noteArray[0] + timeOffset;
            }
        }

        return adjustedNote;
    }

    /**
     * Adjust event timing for stitched song
     */
    function adjustEventTime(event:Dynamic, timeOffset:Float):Dynamic
    {
        var adjustedEvent:Dynamic = {};
        for (field in Reflect.fields(event))
        {
            Reflect.setField(adjustedEvent, field, Reflect.field(event, field));
        }

        // Adjust time (first element in event array)
        if (Std.isOfType(event, Array))
        {
            var eventArray:Array<Dynamic> = cast event;
            if (eventArray.length > 0)
            {
                eventArray[0] = eventArray[0] + timeOffset;
            }
        }

        return adjustedEvent;
    }

    /**
     * Check if the dynamic song has vocals
     */
    function hasVocals():Bool
    {
        for (sectionName in currentSections)
        {
            var section = currentConfig.sections.get(sectionName);
            if (section.audioFiles.vocals != null ||
                section.audioFiles.vocalsPlayer != null ||
                section.audioFiles.vocalsOpponent != null ||
                section.audioFiles.vocalsGF != null)
            {
                return true;
            }
        }
        return false;
    }

    /**
     * Get the stitched song data
     */
    public function getStitchedSong():SwagSong
    {
        return stitchedSong;
    }

    /**
     * Get current section info for display/scripting
     */
    public function getCurrentSectionInfo():Dynamic
    {
        if (!isActive || currentSectionIndex >= currentSections.length)
            return null;

        var sectionName = currentSections[currentSectionIndex];
        var section = currentConfig.sections.get(sectionName);

        return {
            name: sectionName,
            index: currentSectionIndex,
            duration: section.duration,
            startTime: sectionStartTimes[currentSectionIndex],
            canRepeat: section.canRepeat ?? false,
            weight: section.weight ?? 1.0
        };
    }

    /**
     * Update dynamic song state (called from PlayState)
     */
    public function update(songPosition:Float):Void
    {
        if (!isActive) return;

        // Update current section tracking
        updateCurrentSection(songPosition);

        // Update audio manager
        audioManager.update(songPosition);
    }

    /**
     * Update current section based on song position
     */
    public function updateCurrentSection(songPosition:Float):Void
    {
        if (!isActive) return;

        for (i in 0...sectionStartTimes.length)
        {
            if (i == sectionStartTimes.length - 1 || songPosition < sectionStartTimes[i + 1])
            {
                currentSectionIndex = i;
                break;
            }
        }
    }

    /**
     * Get dynamic audio manager for PlayState integration
     */
    public function getAudioManager():DynamicAudioManager
    {
        return audioManager;
    }

    /**
     * Reset the manager
     */
    public function reset():Void
    {
        isActive = false;
        currentConfig = null;
        currentSections = [];
        currentSectionIndex = 0;
        sectionStartTimes = [];
        stitchedSong = null;
        stitchedAudioDuration = 0;

        // Reset audio manager
        if (audioManager != null)
        {
            audioManager.reset();
        }
    }

    /**
     * Get dynamic song fallback data for non-supporting engines
     */
    public function getFallbackSong():SwagSong
    {
        if (currentConfig?.fallback == null) return null;

        var fallbackPath = Paths.getPath('data/${currentConfig.songName}/${currentConfig.fallback.mainChart}', TEXT, null, true);
        var fallbackData:String = null;

        #if MODS_ALLOWED
        if (FileSystem.exists(fallbackPath))
            fallbackData = File.getContent(fallbackPath);
        else
        #end
            fallbackData = Assets.getText(fallbackPath);

        if (fallbackData == null) return null;

        return Song.parseJSON(fallbackData, currentConfig.songName);
    }
}
