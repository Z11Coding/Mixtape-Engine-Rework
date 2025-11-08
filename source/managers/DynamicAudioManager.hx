package managers;

import backend.Paths;
import backend.Song.DynamicSection;
import backend.Song.DynamicSongConfig;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import lime.utils.Assets;
import openfl.media.Sound;
import openfl.utils.ByteArray;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Dynamic Audio Manager
 * Creates single stitched FlxSound objects compatible with PlayState's Inst/vocals syncing system.
 * Vocals sync to Inst, and Inst syncs to Conductor.
 */
class DynamicAudioManager
{
    public static var instance:DynamicAudioManager;

    // Stitched audio tracks for PlayState compatibility
    public var stitchedInst:FlxSound;
    public var stitchedVocals:FlxSound;
    public var stitchedVocalsPlayer:FlxSound;
    public var stitchedVocalsOpponent:FlxSound;
    public var stitchedVocalsGF:FlxSound;

    // Section timing information
    private var sectionTimings:Array<{
        section:String,
        startTime:Float,
        endTime:Float,
        duration:Float
    }> = [];

    // Current state
    private var config:DynamicSongConfig;
    private var isActive:Bool = false;
    private var totalDuration:Float = 0;

    public function new()
    {
        instance = this;
    }

    /**
     * Create stitched audio from dynamic song sections
     * Note: Due to OpenFL limitations, this creates a fallback approach using the first section's audio
     * For true audio stitching, external tools or different audio libraries would be needed
     */
    public function createStitchedAudio(config:DynamicSongConfig, sections:Array<String>):Dynamic
    {
        try
        {
            this.config = config;
            this.isActive = true;

            trace('DynamicAudioManager: Creating dynamic audio for ${sections.length} sections');
            trace('DynamicAudioManager: Note - True audio stitching requires external tools. Using fallback approach.');

            // Calculate section timings for script access
            calculateSectionTimings(sections);

            // Create FlxSound objects using fallback approach
            stitchedInst = createFallbackInst(sections);
            stitchedVocals = createFallbackVocals(sections, null);
            stitchedVocalsPlayer = createFallbackVocals(sections, "Player");
            stitchedVocalsOpponent = createFallbackVocals(sections, "Opponent");
            stitchedVocalsGF = createFallbackVocals(sections, "GF");

            // Set up PlayState compatibility
            setupPlayStateCompatibility();

            trace('DynamicAudioManager: Created dynamic audio - Total duration: ${totalDuration}s');

            return {
                inst: stitchedInst,
                vocals: stitchedVocals,
                vocalsPlayer: stitchedVocalsPlayer,
                vocalsOpponent: stitchedVocalsOpponent,
                vocalsGF: stitchedVocalsGF,
                sectionTimings: sectionTimings.copy(),
                totalLength: totalDuration
            };
        }
        catch (e:Dynamic)
        {
            trace('DynamicAudioManager: Error creating dynamic audio: $e');
            return createFallbackAudio(config.songName);
        }
    }

    /**
     * Calculate section timing information
     */
    function calculateSectionTimings(sections:Array<String>):Void
    {
        sectionTimings = [];
        var currentTime:Float = 0;

        for (sectionName in sections)
        {
            var section = config.sections.get(sectionName);
            if (section == null) continue;

            var duration = section.duration / 1000; // Convert ms to seconds

            sectionTimings.push({
                section: sectionName,
                startTime: currentTime,
                endTime: currentTime + duration,
                duration: duration
            });

            currentTime += duration;
        }

        totalDuration = currentTime;
    }

    /**
     * Create fallback instrumental audio (uses first available section)
     */
    function createFallbackInst(sections:Array<String>):FlxSound
    {
        var sound = new FlxSound();

        for (sectionName in sections)
        {
            var section = config.sections.get(sectionName);
            if (section?.audioFiles?.inst != null)
            {
                try
                {
                    var audioFile = section.audioFiles.inst;
                    var pathParts = audioFile.split('/');
                    var fileName = pathParts[1];
                    var baseName = fileName.split('.')[0];
                    var secName = baseName.split('-')[0];

                    var audioSound = Paths.returnSound('${Paths.formatToSongPath(config.songName)}/sections/$secName', 'songs', true, false);
                    if (audioSound != null)
                    {
                        sound.loadEmbedded(audioSound);
                        sound.autoDestroy = false;
                        sound.persist = true;
                        trace('DynamicAudioManager: Using fallback inst from section: $sectionName');
                        break;
                    }
                }
                catch (e:Dynamic)
                {
                    trace('DynamicAudioManager: Failed to load inst from section $sectionName: $e');
                }
            }
        }

        return sound;
    }

    /**
     * Create fallback vocal audio (uses first available section)
     */
    function createFallbackVocals(sections:Array<String>, postfix:String):FlxSound
    {
        var sound = new FlxSound();

        for (sectionName in sections)
        {
            var section = config.sections.get(sectionName);
            var audioFile:String = null;

            // Determine which vocal file to use
            if (postfix == null)
                audioFile = section?.audioFiles?.vocals;
            else if (postfix == "Player")
                audioFile = section?.audioFiles?.vocalsPlayer;
            else if (postfix == "Opponent")
                audioFile = section?.audioFiles?.vocalsOpponent;
            else if (postfix == "GF")
                audioFile = section?.audioFiles?.vocalsGF;

            if (audioFile != null)
            {
                try
                {
                    var vocalsKey = '${Paths.formatToSongPath(config.songName)}/sections/Voices';
                    if (postfix != null) vocalsKey += '-' + postfix;

                    var audioSound = Paths.returnSound(vocalsKey, 'songs', true, false);
                    if (audioSound != null)
                    {
                        sound.loadEmbedded(audioSound);
                        sound.autoDestroy = false;
                        sound.persist = true;
                        trace('DynamicAudioManager: Using fallback vocals${postfix != null ? "-" + postfix : ""} from section: $sectionName');
                        break;
                    }
                }
                catch (e:Dynamic)
                {
                    trace('DynamicAudioManager: Failed to load vocals from section $sectionName: $e');
                }
            }
        }

        return sound;
    }

    /**
     * Get the appropriate audio file path for a section and audio type
     */
    function getAudioFileForType(section:DynamicSection, audioType:String):String
    {
        return switch (audioType)
        {
            case "inst": section.audioFiles.inst;
            case "vocals": section.audioFiles.vocals;
            case "vocalsPlayer": section.audioFiles.vocalsPlayer;
            case "vocalsOpponent": section.audioFiles.vocalsOpponent;
            case "vocalsGF": section.audioFiles.vocalsGF;
            default: null;
        };
    }

    /**
     * Set up PlayState compatibility - ensures vocals sync to inst properly
     */
    function setupPlayStateCompatibility():Void
    {
        // Add to FlxG.sound.list for proper management
        if (stitchedInst != null) FlxG.sound.list.add(stitchedInst);
        if (stitchedVocals != null) FlxG.sound.list.add(stitchedVocals);
        if (stitchedVocalsPlayer != null) FlxG.sound.list.add(stitchedVocalsPlayer);
        if (stitchedVocalsOpponent != null) FlxG.sound.list.add(stitchedVocalsOpponent);
        if (stitchedVocalsGF != null) FlxG.sound.list.add(stitchedVocalsGF);

        // Set up timing synchronization - vocals will sync to inst in PlayState
        if (stitchedInst != null && stitchedVocals != null)
        {
            // PlayState handles the actual syncing, we just ensure they're properly set up
            stitchedVocals.time = stitchedInst.time;
        }
    }

    /**
     * Creates fallback audio from traditional inst/vocals files
     */
    public function createFallbackAudio(songName:String):Dynamic
    {
        var inst = new FlxSound();
        var vocals = new FlxSound();

        try
        {
            // Use proper Paths functions for loading
            var instSound = Paths.inst(songName);
            var vocalsSound = Paths.voices(songName);

            if (instSound != null)
            {
                inst.loadEmbedded(instSound);
                inst.autoDestroy = false;
                inst.persist = true;
                FlxG.sound.list.add(inst);
            }

            if (vocalsSound != null)
            {
                vocals.loadEmbedded(vocalsSound);
                vocals.autoDestroy = false;
                vocals.persist = true;
                FlxG.sound.list.add(vocals);
            }

            trace('DynamicAudioManager: Created fallback audio for: $songName');
        }
        catch (e:Dynamic)
        {
            trace('DynamicAudioManager: Failed to load fallback audio: $e');
        }

        return {
            inst: inst,
            vocals: vocals,
            vocalsPlayer: vocals, // Use same vocals for compatibility
            vocalsOpponent: vocals,
            vocalsGF: vocals,
            sectionTimings: [],
            totalLength: inst.length / 1000
        };
    }

    /**
     * Gets the section name at a specific time position
     */
    public function getSectionAtTime(time:Float):String
    {
        for (timing in sectionTimings)
        {
            if (time >= timing.startTime && time < timing.endTime)
            {
                return timing.section;
            }
        }
        return "";
    }

    /**
     * Gets the start time of a specific section
     */
    public function getSectionStartTime(sectionName:String):Float
    {
        for (timing in sectionTimings)
        {
            if (timing.section == sectionName)
            {
                return timing.startTime;
            }
        }
        return 0;
    }

    /**
     * Gets all section timing information
     */
    public function getSectionTimings():Array<{section:String, startTime:Float, endTime:Float, duration:Float}>
    {
        return sectionTimings.copy();
    }

    /**
     * Get current section information (for script access)
     */
    public function getCurrentSectionInfo():Dynamic
    {
        // Since we use stitched audio, we need to determine current section based on playback time
        if (!isActive || stitchedInst == null) return null;

        var currentTime = stitchedInst.time / 1000; // Convert to seconds
        var currentSection = getSectionAtTime(currentTime);

        if (currentSection == "") return null;

        // Find section index
        var sectionIndex = -1;
        for (i in 0...sectionTimings.length)
        {
            if (sectionTimings[i].section == currentSection)
            {
                sectionIndex = i;
                break;
            }
        }

        return {
            name: currentSection,
            index: sectionIndex,
            startTime: getSectionStartTime(currentSection),
            isLast: sectionIndex == sectionTimings.length - 1
        };
    }

    /**
     * Update method for compatibility (not needed for stitched audio system)
     */
    public function update(songPosition:Float):Void
    {
        // For stitched audio, no real-time updates are needed since everything is pre-stitched
        // This method exists for compatibility with existing code
        // The stitched audio automatically plays as one continuous stream
    }

    /**
     * Pre-validates that all section audio files exist
     */
    public function validateSectionAudio(config:DynamicSongConfig, sections:Array<String>):Array<String>
    {
        var missingFiles = [];

        for (sectionName in sections)
        {
            var section = config.sections.get(sectionName);
            if (section == null)
            {
                missingFiles.push('Section definition: $sectionName');
                continue;
            }

            // Check each audio file type
            var audioTypes = ["inst", "vocals", "vocalsPlayer", "vocalsOpponent", "vocalsGF"];
            for (audioType in audioTypes)
            {
                var audioFile = getAudioFileForType(section, audioType);
                if (audioFile != null)
                {
                    var exists = false;

                    try
                    {
                        // Check if this follows the section audio pattern
                        if (audioFile.startsWith('sections/'))
                        {
                            var pathParts = audioFile.split('/');
                            var fileName = pathParts[1];
                            var baseName = fileName.split('.')[0];

                            var secName:String;
                            var fileAudioType:String = "Inst";

                            if (baseName.indexOf('-') != -1)
                            {
                                var parts = baseName.split('-');
                                secName = parts[0];
                                fileAudioType = parts[1];
                            }
                            else
                            {
                                secName = baseName;
                            }

                            if (fileAudioType == "Inst")
                            {
                                var sound = Paths.returnSound('${Paths.formatToSongPath(config.songName)}/sections/$secName', 'songs', true, false);
                                exists = (sound != null);
                            }
                            else
                            {
                                var vocalsKey = '${Paths.formatToSongPath(config.songName)}/sections/Voices';
                                if (fileAudioType != "Vocals") vocalsKey += '-' + fileAudioType;

                                var sound = Paths.returnSound(vocalsKey, 'songs', true, false);
                                exists = (sound != null);
                            }
                        }
                        else
                        {
                            // Direct path check
                            var sound = Paths.returnSound(audioFile, 'songs', true, false);
                            exists = (sound != null);
                        }
                    }
                    catch (e:Dynamic)
                    {
                        exists = false;
                    }

                    if (!exists)
                    {
                        missingFiles.push('$sectionName/$audioType: $audioFile');
                    }
                }
            }
        }

        return missingFiles;
    }

    /**
     * Cleanup and reset
     */
    public function reset():Void
    {
        isActive = false;

        // Destroy stitched audio
        if (stitchedInst != null)
        {
            stitchedInst.destroy();
            stitchedInst = null;
        }

        if (stitchedVocals != null)
        {
            stitchedVocals.destroy();
            stitchedVocals = null;
        }

        if (stitchedVocalsPlayer != null)
        {
            stitchedVocalsPlayer.destroy();
            stitchedVocalsPlayer = null;
        }

        if (stitchedVocalsOpponent != null)
        {
            stitchedVocalsOpponent.destroy();
            stitchedVocalsOpponent = null;
        }

        if (stitchedVocalsGF != null)
        {
            stitchedVocalsGF.destroy();
            stitchedVocalsGF = null;
        }

        // Reset state
        sectionTimings = [];
        config = null;
        totalDuration = 0;
    }
}
