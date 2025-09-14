package backend;

import backend.Song;
import flixel.FlxG;
import haxe.ds.Map;
import objects.Note;
import yutautil.CollectionUtils;

/**
/**
 * Advanced Chart Modifier
 *
 * This class transforms existing charts into more difficult, rhythm game-style patterns
 * by analyzing note patterns and generating advanced techniques like doubles, triples, jacks, etc.
 *
 * Features:
 * - Pattern Analysis: Analyzes existing chart structure and rhythm
 * - Jack Detection: Identifies and enhances existing jack patterns (repeated notes on same column)
 * - Chord Generation: Creates doubles, triples, and quad patterns
 * - Difficulty Scaling: Adjusts complexity based on song intensity
 * - Playability Validation: Ensures generated patterns are physically possible
 */
class AdvancedChartModifier
{
    // Configuration constants
    private static final MIN_JACK_INTERVAL:Float = 100; // Minimum ms between jack notes
    private static final MAX_JACK_INTERVAL:Float = 300; // Maximum ms for jack patterns
    private static final CHORD_PROBABILITY:Float = 0.3; // Base probability for chord generation
    private static final JACK_PROBABILITY:Float = 0.4; // Base probability for jack patterns
    private static final PATTERN_COMPLEXITY_MULTIPLIER:Float = 1.5; // How much to increase complexity

    // Timing threshold constants for playability
    private static final FAST_JACK_THRESHOLD:Float = 80; // ms - anything faster than this is too fast for jacks
    private static final CHORD_SPACING_THRESHOLD:Float = 50; // ms - minimum spacing between large chords
    private static final MAX_SIMULTANEOUS_NOTES:Int = 4; // Maximum notes that can be played at once per side
    private static final NOTE_REPOSITIONING_RANGE:Float = 30; // ms - how far we can move notes to avoid conflicts

    // Complex mode constants
    private static final COMPLEX_CHORD_PROBABILITY:Float = 0.5; // Higher chord probability for complex mode
    private static final COMPLEX_PATTERN_PROBABILITY:Float = 0.6; // Higher pattern generation probability
    private static final MAX_CHORD_SIZE_NORMAL:Int = 3; // Normal mode max chord size
    private static final MAX_CHORD_SIZE_COMPLEX:Int = 5; // Complex mode max chord size

    // Pattern analysis data
    private static var notePatterns:Array<PatternData> = [];
    private static var rhythmData:RhythmAnalysis;
    private static var difficultyProfile:DifficultyProfile;
    private static var isComplexMode:Bool = false; // Track if we're in complex mode

    /**
     * Main entry point for advanced chart modification
     * Analyzes and transforms the entire chart
     */
    public static function transformChart(song:SwagSong, intensity:Float = 1.0, complexMode:Bool = false):SwagSong
    {
        if (song == null || song.notes == null) return song;

        // Set complex mode flag
        isComplexMode = complexMode;

        // Create a deep copy to avoid modifying original
        var modifiedSong:SwagSong = Reflect.copy(song);
        modifiedSong.notes = [];

        trace('AdvancedChartModifier: Starting chart transformation (Complex Mode: $complexMode)');

        // Phase 1: Analyze existing chart
        analyzeChart(song);

        // Phase 2: Transform each section
        for (i in 0...song.notes.length)
        {
            var transformedSection = transformSection(song.notes[i], intensity, i);
            modifiedSong.notes.push(transformedSection);
        }

        // Phase 3: Apply timing validation and corrections
        applyTimingValidation(modifiedSong);

        trace('AdvancedChartModifier: Chart transformation completed');
        return modifiedSong;
    }

    /**
     * Gets the effective key count for chord generation based on mania and complex mode
     */
    private static function getEffectiveKeyCount(mania:Int):Int
    {
        var baseKeys = Note.ammo[mania]; // Original key count

        // In complex mode and for higher mania modes, allow more keys
        if (isComplexMode && mania >= 4) // 5K+ modes
        {
            // Allow up to 8 keys total, or mania+1, whichever is smaller
            var maxKeys = Std.int(Math.min(8, mania + 1));
            return Std.int(Math.max(baseKeys, maxKeys));
        }

        return baseKeys;
    }

    /**
    private static function findBestChordColumn(usedColumns:Array<Int>, mania:Int):Int
    {
        var availableColumns:Array<Int> = [];
        var effectiveKeys = getEffectiveKeyCount(mania);

        for (i in 0...effectiveKeys)
        {
            if (usedColumns.indexOf(i) == -1)
                availableColumns.push(i);
        }

        if (availableColumns.length == 0) return -1;

        // Prefer columns that create good finger patterns
        // For 4k: prefer outer columns for doubles, middle for triples
        if (mania == 3 && availableColumns.length > 1) // 4K mode
        {
            // Prefer outer columns (0, 3) for doubles
            var outerColumns = availableColumns.filter(col -> col == 0 || col == 3);
            if (outerColumns.length > 0)
                return FlxG.random.getObject(outerColumns);
        }

        // Return random available column
        return FlxG.random.getObject(availableColumns);
    }

    /**
     * Analyzes the chart to understand patterns and difficulty
     */
    private static function analyzeChart(song:SwagSong):Void
    {
        notePatterns = [];
        rhythmData = {
            dominantPattern: null,
            avgTempo: null,
            rhythmComplexity: null
        };
        difficultyProfile = {
            averageNoteDensity: null,
            chordRatio: null,
            complexityScore: null,
            recommendedIntensity: null
        };

        var totalNotes = 0;
        var totalChords = 0;
        var noteDensityData:Array<Float> = [];

        for (section in song.notes)
        {
            var sectionNotes = section.sectionNotes.length;
            var sectionChords = 0;
            var noteTimestamps:Array<Float> = [];

            // Collect note data for this section
            for (note in section.sectionNotes)
            {
                var noteTime:Float = note[0];
                var noteData:Int = note[1];
                var sustainLength:Float = note[2];

                noteTimestamps.push(noteTime);
                totalNotes++;

                // Check for existing chords (notes at same timestamp)
                var chordsAtTime = section.sectionNotes.filter(n -> Math.abs(n[0] - noteTime) < 10).length;
                if (chordsAtTime > 1) sectionChords++;
            }

            totalChords += sectionChords;

            // Detect existing jack patterns in this section
            var sectionNotesArray:Array<Array<Dynamic>> = cast section.sectionNotes;
            var jackPatterns = detectJackPatterns(sectionNotesArray);
            var sectionJacks = jackPatterns.length;

            // Calculate note density (notes per beat)
            var sectionBeats = (CollectionUtils.isReal(section.sectionBeats) && section.sectionBeats > 0) ? section.sectionBeats : 4.0;
            var noteDensity = sectionNotes / sectionBeats;
            noteDensityData.push(noteDensity);

            // Store pattern data
            notePatterns.push({
                sectionIndex: notePatterns.length,
                noteCount: sectionNotes,
                chordCount: sectionChords,
                jackCount: sectionJacks,
                jackPatterns: jackPatterns,
                noteDensity: noteDensity,
                timestamps: noteTimestamps,
                avgInterval: calculateAverageInterval(noteTimestamps)
            });
        }

        // Calculate overall difficulty metrics
        difficultyProfile.averageNoteDensity = noteDensityData.length > 0 ?
            CollectionUtils.sum(noteDensityData) / noteDensityData.length : 0;
        difficultyProfile.chordRatio = totalNotes > 0 ? totalChords / totalNotes : 0;
        difficultyProfile.complexityScore = calculateComplexityScore(song);

        var jackCounts:Array<Int> = [for (pattern in notePatterns) pattern.jackCount];
        var totalJacks = CollectionUtils.sum(jackCounts);

        // Calculate density distribution for smarter pattern application
        var densityCategories = {sparse: 0, normal: 0, dense: 0, very_dense: 0};
        for (pattern in notePatterns) {
            if (pattern.noteDensity < 2) densityCategories.sparse++;
            else if (pattern.noteDensity < 4) densityCategories.normal++;
            else if (pattern.noteDensity < 6) densityCategories.dense++;
            else densityCategories.very_dense++;
        }

        trace('Chart Analysis - Notes: $totalNotes, Chords: $totalChords, Jacks: $totalJacks, Avg Density: ${difficultyProfile.averageNoteDensity}');
        trace('Density Distribution - Sparse: ${densityCategories.sparse}, Normal: ${densityCategories.normal}, Dense: ${densityCategories.dense}, Very Dense: ${densityCategories.very_dense}');
    }

    /**
     * Transforms a single section with advanced patterns
     */
    private static function transformSection(section:SwagSection, intensity:Float, sectionIndex:Int):SwagSection
    {
        var newSection:SwagSection = Reflect.copy(section);
        newSection.sectionNotes = [];

        var pattern = notePatterns[sectionIndex];
        var sectionIntensity = calculateSectionIntensity(pattern, intensity);

        // Track which jack patterns have been enhanced to avoid duplicates
        var enhancedJacks:Array<JackPattern> = [];

        // Sort notes by time for processing
        var sortedNotes = section.sectionNotes.copy();
        sortedNotes.sort((a, b) -> Std.int(a[0] - b[0]));

        var processedNotes:Array<Array<Dynamic>> = [];
        var i = 0;

        while (i < sortedNotes.length)
        {
            var currentNote = sortedNotes[i];
            var noteTime:Float = currentNote[0];
            var noteData:Int = Std.int(currentNote[1]);
            var sustainLength:Float = currentNote[2];
            var noteType:String = (currentNote.length > 3 && CollectionUtils.isReal(currentNote[3])) ? Std.string(currentNote[3]) : "";

            // Get all notes at this timestamp (existing chords)
            var notesAtTime:Array<Array<Dynamic>> = [];
            var j = i;
            while (j < sortedNotes.length && Math.abs(sortedNotes[j][0] - noteTime) < 10)
            {
                notesAtTime.push(sortedNotes[j]);
                j++;
            }

            // Apply transformations based on context
            var transformedNotes = applyAdvancedPatterns(notesAtTime, sectionIntensity, pattern, enhancedJacks);
            processedNotes = processedNotes.concat(transformedNotes);

            i = j; // Skip processed notes
        }

        newSection.sectionNotes = processedNotes;
        return newSection;
    }

    /**
     * Applies advanced patterns to a group of notes at the same timestamp
     */
    private static function applyAdvancedPatterns(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData, enhancedJacks:Array<JackPattern>):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var baseNote = notes[0];
        var noteTime:Float = baseNote[0];

        // Always add original notes first to ensure we never reduce complexity
        for (note in notes) {
            result.push(note);
        }

        // Determine what patterns to apply (smarter distribution based on density)
        var shouldCreateChord = shouldGenerateChord(notes, intensity, pattern);
        var shouldCreateJack = shouldGenerateJack(notes, intensity, pattern);
        var shouldAddComplexPattern = isComplexMode && shouldGenerateComplexPattern(notes, intensity, pattern);
        var shouldCreateTrill = shouldGenerateTrill(notes, intensity, pattern);
        var shouldEnhanceExistingPattern = shouldEnhanceExistingPatterns(notes, intensity, pattern);

        // Log pattern decisions for debugging
        if (shouldCreateChord || shouldCreateJack || shouldAddComplexPattern || shouldCreateTrill || shouldEnhanceExistingPattern) {
            var patternTypes:Array<String> = [];
            if (shouldCreateChord) patternTypes.push("Chord");
            if (shouldCreateJack) patternTypes.push("Jack");
            if (shouldAddComplexPattern) patternTypes.push("Complex");
            if (shouldCreateTrill) patternTypes.push("Trill");
            if (shouldEnhanceExistingPattern) patternTypes.push("Enhancement");
            trace('Section ${pattern.sectionIndex}: Density ${Math.round(pattern.noteDensity * 100) / 100}, applying: ${patternTypes.join(", ")}');
        }

        if (shouldCreateChord)
        {
            // Generate chord patterns (doubles, triples) - ADD to existing notes
            var chordNotes = generateChordPattern(notes, intensity);
            // Remove the original notes from chord result since we already added them
            chordNotes = chordNotes.filter(note -> !containsNote(result, note));
            result = result.concat(chordNotes);
        }

        if (shouldCreateTrill)
        {
            // Generate trill patterns for more interesting gameplay
            var trillNotes = generateTrillPattern(notes, intensity, pattern);
            result = result.concat(trillNotes);
        }

        if (shouldEnhanceExistingPattern)
        {
            // Transform existing patterns into more interesting ones
            var enhancedNotes = enhanceExistingPatterns(notes, intensity, pattern);
            result = result.concat(enhancedNotes);
        }

        if (shouldCreateJack)
        {
            // Enhance existing jack patterns with doubles/triples - ADD to existing notes
            var jackNotes = enhanceJackPattern(notes, intensity, pattern, enhancedJacks);
            // Remove the original notes from jack result since we already added them
            jackNotes = jackNotes.filter(note -> !containsNote(result, note));
            result = result.concat(jackNotes);
        }

        if (shouldAddComplexPattern)
        {
            // Add complex patterns like polyrhythms, grace notes, etc.
            var complexNotes = generateComplexPattern(notes, intensity, pattern);
            result = result.concat(complexNotes);
        }

        // For sparse areas or when no specific patterns were added, still try basic enhancements
        if (pattern.noteDensity < 3 || (!shouldCreateChord && !shouldCreateJack && !shouldCreateTrill))
        {
            var basicEnhancements = enhanceBasicPattern(notes, intensity);
            // Remove original notes from basic enhancements since we already added them
            basicEnhancements = basicEnhancements.filter(note -> !containsNote(result, note));
            result = result.concat(basicEnhancements);
        }

        return result;
    }

    /**
     * Determines if chord patterns should be generated
     */
    private static function shouldGenerateChord(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Bool
    {
        // Don't create chords if we already have multiple notes
        if (notes.length > 1) return false;

        // For dense areas (>6 notes per beat), reduce chord generation significantly
        if (pattern.noteDensity > 6) {
            // Only create chords 20% of the time in very dense areas
            var denseProbability = CHORD_PROBABILITY * intensity * 0.2;
            return FlxG.random.bool(denseProbability * 100);
        }

        // For sparse areas (<2 notes per beat), increase chord generation
        if (pattern.noteDensity < 2) {
            var sparseProbability = CHORD_PROBABILITY * intensity * 1.8; // 80% boost
            return FlxG.random.bool(sparseProbability * 100);
        }

        // Normal areas: reduce if already chord-heavy, increase if not
        var chordProbability = CHORD_PROBABILITY * intensity;
        if (difficultyProfile.chordRatio > 0.3) {
            chordProbability *= 0.6; // Reduce if already chord-heavy
        } else {
            chordProbability *= 1.2; // Slight boost if not chord-heavy
        }

        return FlxG.random.bool(chordProbability * 100);
    }

    /**
     * Determines if existing jack patterns should be enhanced
     */
    private static function shouldGenerateJack(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Bool
    {
        // Only enhance if we have existing jacks in this pattern
        if (pattern.jackCount == 0) return false;

        // In very dense areas, be much more conservative with jack enhancement
        if (pattern.noteDensity > 6) {
            var conservativeJackProbability = JACK_PROBABILITY * intensity * 0.3; // 70% reduction
            return FlxG.random.bool(conservativeJackProbability * 100);
        }

        // In moderately dense areas, be somewhat conservative
        if (pattern.noteDensity > 4) {
            var moderateJackProbability = JACK_PROBABILITY * intensity * 0.7; // 30% reduction
            return FlxG.random.bool(moderateJackProbability * 100);
        }

        // Check if any of the provided notes are part of an existing jack
        for (note in notes)
        {
            var noteTime:Float = note[0];
            var noteColumn:Int = Std.int(note[1]);

            for (jack in pattern.jackPatterns)
            {
                if (jack.column == noteColumn)
                {
                    // Check if this note is part of this jack pattern
                    for (jackNote in jack.notes)
                    {
                        if (Math.abs(jackNote[0] - noteTime) < 10) // 10ms tolerance
                        {
                            var enhanceProbability = JACK_PROBABILITY * intensity;
                            return FlxG.random.bool(enhanceProbability * 100);
                        }
                    }
                }
            }
        }

        return false;
    }

    /**
     * Generates chord patterns (doubles, triples, etc.)
     */
    private static function generateChordPattern(notes:Array<Array<Dynamic>>, intensity:Float):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var baseNote = notes[0];
        var noteTime:Float = baseNote[0];
        var primaryColumn:Int = Std.int(baseNote[1]);
        var sustainLength:Float = baseNote[2];
        var noteType:String = (baseNote.length > 3 && CollectionUtils.isReal(baseNote[3])) ? Std.string(baseNote[3]) : "";

        // Add the original note
        result.push(baseNote);

        // Determine chord size based on intensity and mode
        var chordSize = 1; // Base note already added
        var maxChordSize = isComplexMode ? MAX_CHORD_SIZE_COMPLEX : MAX_CHORD_SIZE_NORMAL;

        if (isComplexMode)
        {
            // More aggressive chord generation in complex mode
            var chordProbability = COMPLEX_CHORD_PROBABILITY * intensity * 100;
            if (intensity > 0.8 && FlxG.random.bool(chordProbability * 0.5)) chordSize = Std.int(Math.min(5, maxChordSize)); // Quintuple
            else if (intensity > 0.6 && FlxG.random.bool(chordProbability * 0.7)) chordSize = Std.int(Math.min(4, maxChordSize)); // Quadruple
            else if (intensity > 0.4 && FlxG.random.bool(chordProbability * 0.8)) chordSize = Std.int(Math.min(3, maxChordSize)); // Triple
            else if (FlxG.random.bool(chordProbability)) chordSize = Std.int(Math.min(2, maxChordSize)); // Double
        }
        else
        {
            // Normal mode chord generation
            if (intensity > 0.7 && FlxG.random.bool(30)) chordSize = Std.int(Math.min(3, maxChordSize)); // Triple
            else if (FlxG.random.bool(60)) chordSize = Std.int(Math.min(2, maxChordSize)); // Double
        }

        // Generate additional chord notes
        var usedColumns:Array<Int> = [primaryColumn % Note.ammo[PlayState.SONG.mania]];
        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;

        for (i in 1...chordSize)
        {
            var newColumn = findBestChordColumn(usedColumns, mania);
            if (newColumn != -1)
            {
                usedColumns.push(newColumn);
                var mustPress = primaryColumn >= Note.ammo[mania];
                var finalColumn = newColumn + (mustPress ? Note.ammo[mania] : 0);

                result.push([noteTime, finalColumn, sustainLength, noteType]);
            }
        }

        return result;
    }

    /**
     * Enhances existing jack patterns with chords (doubles, triples)
     */
    private static function enhanceJackPattern(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData, enhancedJacks:Array<JackPattern>):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var baseNote = notes[0];
        var noteTime:Float = baseNote[0];
        var noteColumn:Int = Std.int(baseNote[1]);

        // Find which jack pattern this note belongs to
        var targetJackPattern:JackPattern = null;
        for (jack in pattern.jackPatterns)
        {
            if (jack.column == noteColumn)
            {
                // Check if this note is part of this jack pattern
                for (jackNote in jack.notes)
                {
                    if (Math.abs(jackNote[0] - noteTime) < 10) // 10ms tolerance
                    {
                        targetJackPattern = jack;
                        break;
                    }
                }
                if (targetJackPattern != null) break;
            }
        }

        if (targetJackPattern == null)
        {
            // Fallback: just return the original note if no jack pattern found
            result.push(baseNote);
            return result;
        }

        // Check if this jack pattern has already been enhanced
        for (enhanced in enhancedJacks)
        {
            if (enhanced.column == targetJackPattern.column &&
                Math.abs(enhanced.startTime - targetJackPattern.startTime) < 10)
            {
                // This jack pattern was already enhanced, just return the original note
                result.push(baseNote);
                return result;
            }
        }

        // Mark this jack pattern as enhanced
        enhancedJacks.push(targetJackPattern);

        // Determine enhancement level based on intensity, jack length, and mode
        var enhancementLevel = isComplexMode ?
            Math.floor(1 + intensity * 3) : // 1-4 additional columns in complex mode
            Math.floor(1 + intensity * 2); // 1-3 additional columns in normal mode

        if (targetJackPattern.length >= 4) enhancementLevel++; // Boost for longer jacks
        if (isComplexMode && targetJackPattern.length >= 6) enhancementLevel++; // Extra boost in complex mode

        // Cap enhancement level based on available keys
        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;
        var maxEnhancement = getEffectiveKeyCount(mania) - 1; // Reserve at least one key for the original
        enhancementLevel = Std.int(Math.min(enhancementLevel, maxEnhancement));

        // Enhance ALL notes in the jack pattern, not just this one
        for (jackNote in targetJackPattern.notes)
        {
            var enhancedNotes = enhanceJackNote(jackNote, enhancementLevel, targetJackPattern.column);
            result = result.concat(enhancedNotes);
        }

        return result;
    }

    /**
     * Enhances a single note from a jack pattern with additional chord notes
     */
    private static function enhanceJackNote(jackNote:Array<Dynamic>, enhancementLevel:Int, originalColumn:Int):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var noteTime:Float = jackNote[0];
        var sustainLength:Float = jackNote[2];
        var noteType:String = (jackNote.length > 3 && CollectionUtils.isReal(jackNote[3])) ? Std.string(jackNote[3]) : "";

        // Add the original jack note
        result.push(jackNote);

        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;
        var usedColumns:Array<Int> = [originalColumn % Note.ammo[mania]];

        // Add enhancement notes (make it a chord)
        for (i in 0...enhancementLevel)
        {
            var newColumn = findBestChordColumn(usedColumns, mania);
            if (newColumn != -1)
            {
                usedColumns.push(newColumn);
                var mustPress = originalColumn >= Note.ammo[mania];
                var finalColumn = newColumn + (mustPress ? Note.ammo[mania] : 0);

                result.push([noteTime, finalColumn, 0, noteType]); // No sustain for chord parts of jacks
            }
        }

        return result;
    }

    /**
     * Enhances basic patterns with subtle improvements
     */
    private static function enhanceBasicPattern(notes:Array<Array<Dynamic>>, intensity:Float):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];

        // Add original notes
        for (note in notes)
        {
            result.push(note);
        }

        // Be more selective about when to add enhancements
        var enhancementChance = 15 * intensity; // Reduced base chance

        // Only add ghost notes or grace notes in sparse areas or when intensity is high
        if (FlxG.random.bool(enhancementChance) && notes.length == 1)
        {
            var baseNote = notes[0];
            var noteTime:Float = baseNote[0];

            // Choose enhancement type based on context
            var enhancementType = FlxG.random.int(0, 2);

            switch (enhancementType) {
                case 0: // Grace note (before main note)
                    var ghostTime = noteTime - (40 + FlxG.random.float(0, 30)); // 40-70ms before
                    var ghostColumn = findAlternateColumn(Std.int(baseNote[1]));
                    if (ghostColumn != -1 && ghostTime > 0) {
                        result.push([ghostTime, ghostColumn, 0, "Grace Note"]);
                    }

                case 1: // Ghost note (after main note)
                    var ghostTime = noteTime + (60 + FlxG.random.float(0, 40)); // 60-100ms after
                    var ghostColumn = findAlternateColumn(Std.int(baseNote[1]));
                    if (ghostColumn != -1) {
                        result.push([ghostTime, ghostColumn, 0, "Ghost Note"]);
                    }

                case 2: // Accent pattern (emphasize with nearby note)
                    var accentTime = noteTime + (30 + FlxG.random.float(0, 20)); // 30-50ms after
                    var accentColumn = findAlternateColumn(Std.int(baseNote[1]));
                    if (accentColumn != -1) {
                        result.push([accentTime, accentColumn, 0, "Accent"]);
                    }
            }
        }

        return result;
    }

    /**
     * Determines if trill patterns should be generated
     */
    private static function shouldGenerateTrill(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Bool
    {
        // Only generate trills in moderately dense areas (not too sparse, not too dense)
        if (pattern.noteDensity < 1.5 || pattern.noteDensity > 5) return false;

        // Higher chance in areas with good spacing for trills
        if (pattern.avgInterval > 150 && pattern.avgInterval < 400) {
            var trillProbability = 0.3 * intensity;
            return FlxG.random.bool(trillProbability * 100);
        }

        return false;
    }

    /**
     * Determines if existing patterns should be enhanced
     */
    private static function shouldEnhanceExistingPatterns(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Bool
    {
        // Focus on enhancing when we already have chords (make them more interesting)
        if (difficultyProfile.chordRatio > 0.2) {
            var enhanceProbability = 0.4 * intensity;
            return FlxG.random.bool(enhanceProbability * 100);
        }

        // Also enhance in moderately dense areas to make them more interesting
        if (pattern.noteDensity > 2 && pattern.noteDensity < 6) {
            var enhanceProbability = 0.25 * intensity;
            return FlxG.random.bool(enhanceProbability * 100);
        }

        return false;
    }

    /**
     * Generates trill patterns for more engaging gameplay
     */
    private static function generateTrillPattern(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var baseNote = notes[0];
        var noteTime:Float = baseNote[0];
        var noteColumn:Int = Std.int(baseNote[1]);

        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;
        var baseColumn = noteColumn % Note.ammo[mania];
        var mustPress = noteColumn >= Note.ammo[mania];

        // Find an adjacent column for the trill
        var trillColumn = -1;
        var adjacentColumns = [baseColumn - 1, baseColumn + 1];

        for (col in adjacentColumns) {
            if (col >= 0 && col < Note.ammo[mania]) {
                trillColumn = col + (mustPress ? Note.ammo[mania] : 0);
                break;
            }
        }

        if (trillColumn == -1) return result; // No valid trill column

        // Generate trill notes based on average interval
        var trillInterval = Math.max(80, pattern.avgInterval * 0.5); // Half the average interval, min 80ms
        var trillLength = Std.int(2 + intensity * 2); // 2-4 additional notes

        for (i in 1...trillLength + 1) {
            var trillTime = noteTime + (i * trillInterval);
            var useMainColumn = (i % 2 == 1); // Alternate between main and trill column
            var column = useMainColumn ? noteColumn : trillColumn;

            result.push([trillTime, column, 0, "Trill"]);
        }

        return result;
    }

    /**
     * Enhances existing patterns to make them more interesting
     */
    private static function enhanceExistingPatterns(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];

        if (notes.length == 1) {
            // Single note - add complementary patterns
            result = result.concat(generateComplementaryPattern(notes[0], intensity, pattern));
        } else if (notes.length > 1) {
            // Chord - enhance with arpeggiation or fills
            result = result.concat(generateChordEnhancement(notes, intensity, pattern));
        }

        return result;
    }

    /**
     * Generates complementary patterns for single notes
     */
    private static function generateComplementaryPattern(note:Array<Dynamic>, intensity:Float, pattern:PatternData):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var noteTime:Float = note[0];
        var noteColumn:Int = Std.int(note[1]);

        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;

        // Generate a small pattern around the note
        var patternType = FlxG.random.int(0, 2);

        switch (patternType) {
            case 0: // Leading notes (build-up)
                var leadTime = noteTime - 120;
                var leadColumn = findAlternateColumn(noteColumn);
                if (leadColumn != -1 && leadTime > 0) {
                    result.push([leadTime, leadColumn, 0, "Lead-in"]);
                }

            case 1: // Following notes (follow-up)
                var followTime = noteTime + 100;
                var followColumn = findAlternateColumn(noteColumn);
                if (followColumn != -1) {
                    result.push([followTime, followColumn, 0, "Follow-up"]);
                }

            case 2: // Bracket pattern (surround with notes)
                var beforeTime = noteTime - 80;
                var afterTime = noteTime + 80;
                var altColumn = findAlternateColumn(noteColumn);
                if (altColumn != -1 && beforeTime > 0) {
                    result.push([beforeTime, altColumn, 0, "Bracket Start"]);
                    result.push([afterTime, altColumn, 0, "Bracket End"]);
                }
        }

        return result;
    }

    /**
     * Generates enhancements for chord patterns
     */
    private static function generateChordEnhancement(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var chordTime:Float = notes[0][0];

        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;

        // Determine enhancement type based on chord size and intensity
        var enhancementType = FlxG.random.int(0, 2);

        switch (enhancementType) {
            case 0: // Arpeggiation (spread the chord over time)
                if (notes.length >= 2 && pattern.avgInterval > 200) {
                    for (i in 0...Std.int(Math.min(notes.length, 3))) {
                        var arpTime = chordTime + (i * 40); // 40ms between arp notes
                        var originalColumn = Std.int(notes[i][1]);
                        var arpColumn = findAlternateColumn(originalColumn);
                        if (arpColumn != -1) {
                            result.push([arpTime, arpColumn, 0, "Arpeggio"]);
                        }
                    }
                }

            case 1: // Fill pattern (add notes before/after chord)
                var fillBefore = chordTime - 60;
                var fillAfter = chordTime + 120;
                var fillColumn = findSafeColumnForFill(notes, mania);

                if (fillColumn != -1 && fillBefore > 0) {
                    result.push([fillBefore, fillColumn, 0, "Fill Before"]);
                }
                if (fillColumn != -1) {
                    result.push([fillAfter, fillColumn, 0, "Fill After"]);
                }

            case 2: // Echo pattern (repeat part of chord later)
                if (notes.length >= 2) {
                    var echoTime = chordTime + 150 + FlxG.random.float(0, 50);
                    var echoNote = FlxG.random.getObject(notes);
                    var echoColumn = findAlternateColumn(Std.int(echoNote[1]));
                    if (echoColumn != -1) {
                        result.push([echoTime, echoColumn, 0, "Echo"]);
                    }
                }
        }

        return result;
    }

    /**
     * Finds a safe column for fill patterns that doesn't conflict with chord
     */
    private static function findSafeColumnForFill(chordNotes:Array<Array<Dynamic>>, mania:Int):Int
    {
        var usedColumns:Array<Int> = [];
        var mustPress = false;

        // Collect used columns and determine player side
        for (note in chordNotes) {
            var column:Int = Std.int(note[1]);
            var baseColumn = column % Note.ammo[mania];
            usedColumns.push(baseColumn);
            mustPress = column >= Note.ammo[mania];
        }

        // Find available column
        for (i in 0...Note.ammo[mania]) {
            if (usedColumns.indexOf(i) == -1) {
                return i + (mustPress ? Note.ammo[mania] : 0);
            }
        }

        return -1; // No safe column
    }

    /**
     * Finds the best column for chord notes
     */
    private static function findBestChordColumn(usedColumns:Array<Int>, mania:Int):Int
    {
        var availableColumns:Array<Int> = [];

        for (i in 0...Note.ammo[mania])
        {
            if (usedColumns.indexOf(i) == -1)
                availableColumns.push(i);
        }

        if (availableColumns.length == 0) return -1;

        // Prefer columns that create good finger patterns
        // For 4k: prefer outer columns for doubles, middle for triples
        if (mania == 3 && availableColumns.length > 1) // 4K mode
        {
            var preferredColumns = [0, 3]; // Outer columns first
            for (col in preferredColumns)
            {
                if (availableColumns.indexOf(col) != -1)
                    return col;
            }
        }

        // Otherwise return random available column
        return availableColumns[FlxG.random.int(0, availableColumns.length - 1)];
    }

    /**
     * Finds an alternate column for ghost notes
     */
    private static function findAlternateColumn(originalColumn:Int):Int
    {
        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;
        var baseColumn = originalColumn % Note.ammo[mania];
        var mustPress = originalColumn >= Note.ammo[mania];

        // Simple alternation logic
        var alternateBase = (baseColumn + 1) % Note.ammo[mania];
        return alternateBase + (mustPress ? Note.ammo[mania] : 0);
    }

    /**
     * Applies timing validation to prevent overly fast patterns
     */
    private static function applyTimingValidation(song:SwagSong):Void
    {
        trace('Applying timing validation to prevent unplayable patterns...');

        for (section in song.notes)
        {
            validateSectionTiming(section);
        }
    }

    /**
     * Validates and corrects timing issues in a section
     */
    private static function validateSectionTiming(section:SwagSection):Void
    {
        var notes = section.sectionNotes;
        if (notes.length == 0) return;

        // Sort notes by time
        notes.sort((a, b) -> Std.int(a[0] - b[0]));

        var correctedNotes:Array<Array<Dynamic>> = [];
        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;

        for (i in 0...notes.length)
        {
            var currentNote = notes[i];
            var noteTime:Float = currentNote[0];
            var noteColumn:Int = Std.int(currentNote[1]);

            // Check for overly fast jacks
            var correctedNote = correctFastJacks(currentNote, correctedNotes, mania);

            // Check for excessive simultaneous notes
            correctedNote = correctExcessiveChords(correctedNote, correctedNotes, mania);

            correctedNotes.push(correctedNote);
        }

        section.sectionNotes = correctedNotes;
    }

    /**
     * Corrects notes that would create overly fast jacks
     */
    private static function correctFastJacks(note:Array<Dynamic>, existingNotes:Array<Array<Dynamic>>, mania:Int):Array<Dynamic>
    {
        var noteTime:Float = note[0];
        var noteColumn:Int = Std.int(note[1]);
        var baseColumn = noteColumn % Note.ammo[mania];
        var mustPress = noteColumn >= Note.ammo[mania];

        // Find the most recent note in the same column
        var lastSameColumnNote:Array<Dynamic> = null;
        var lastSameColumnTime:Float = -1;

        for (existingNote in existingNotes)
        {
            var existingTime:Float = existingNote[0];
            var existingColumn:Int = Std.int(existingNote[1]);
            var existingBaseColumn = existingColumn % Note.ammo[mania];
            var existingMustPress = existingColumn >= Note.ammo[mania];

            // Check if it's the same column and same side (player/opponent)
            if (existingBaseColumn == baseColumn && existingMustPress == mustPress)
            {
                if (existingTime > lastSameColumnTime)
                {
                    lastSameColumnNote = existingNote;
                    lastSameColumnTime = existingTime;
                }
            }
        }

        // If we found a recent note in the same column, check timing
        if (lastSameColumnNote != null)
        {
            var timeDiff = noteTime - lastSameColumnTime;
            if (timeDiff < FAST_JACK_THRESHOLD && timeDiff > 0)
            {
                // This would be too fast - move to a different column
                var newColumn = findSafeAlternateColumn(noteColumn, noteTime, existingNotes, mania);
                if (newColumn != -1)
                {
                    var correctedNote = note.copy();
                    correctedNote[1] = newColumn;
                    trace('Moved note from column $noteColumn to $newColumn to avoid fast jack (${timeDiff}ms)');
                    return correctedNote;
                }
                else
                {
                    // If no safe column found, delay the note slightly
                    var correctedNote = note.copy();
                    correctedNote[0] = lastSameColumnTime + FAST_JACK_THRESHOLD;
                    trace('Delayed note by ${FAST_JACK_THRESHOLD - timeDiff}ms to avoid fast jack');
                    return correctedNote;
                }
            }
        }

        return note;
    }

    /**
     * Corrects notes that would create excessive simultaneous chords
     */
    private static function correctExcessiveChords(note:Array<Dynamic>, existingNotes:Array<Array<Dynamic>>, mania:Int):Array<Dynamic>
    {
        var noteTime:Float = note[0];
        var noteColumn:Int = Std.int(note[1]);
        var mustPress = noteColumn >= Note.ammo[mania];

        // Count simultaneous notes on the same side at this time
        var simultaneousNotes:Array<Array<Dynamic>> = [];
        for (existingNote in existingNotes)
        {
            var existingTime:Float = existingNote[0];
            var existingColumn:Int = Std.int(existingNote[1]);
            var existingMustPress = existingColumn >= Note.ammo[mania];

            // Check if it's at the same time and same side
            if (Math.abs(existingTime - noteTime) < 10 && existingMustPress == mustPress)
            {
                simultaneousNotes.push(existingNote);
            }
        }

        // If we already have max simultaneous notes, move this note
        if (simultaneousNotes.length >= MAX_SIMULTANEOUS_NOTES)
        {
            // Try to find a nearby time slot that's not overcrowded
            var newTime = findSafeTimeSlot(noteTime, existingNotes, mania, mustPress);
            if (newTime != noteTime)
            {
                var correctedNote = note.copy();
                correctedNote[0] = newTime;
                trace('Moved note from ${noteTime}ms to ${newTime}ms to avoid excessive chord');
                return correctedNote;
            }
        }

        // Also check if we're creating a full 4-note chord too close to another one
        if (simultaneousNotes.length == 3) // This would make it a 4-note chord
        {
            // Check for nearby large chords
            for (existingNote in existingNotes)
            {
                var existingTime:Float = existingNote[0];
                var timeDiff = Math.abs(existingTime - noteTime);

                if (timeDiff > 0 && timeDiff < CHORD_SPACING_THRESHOLD)
                {
                    // Count notes at that time on the same side
                    var nearbyChordSize = 0;
                    for (checkNote in existingNotes)
                    {
                        var checkTime:Float = checkNote[0];
                        var checkColumn:Int = Std.int(checkNote[1]);
                        var checkMustPress = checkColumn >= Note.ammo[mania];

                        if (Math.abs(checkTime - existingTime) < 10 && checkMustPress == mustPress)
                        {
                            nearbyChordSize++;
                        }
                    }

                    // If there's a 3+ note chord nearby, avoid creating another 4-note chord
                    if (nearbyChordSize >= 3)
                    {
                        var newTime = findSafeTimeSlot(noteTime, existingNotes, mania, mustPress);
                        if (newTime != noteTime)
                        {
                            var correctedNote = note.copy();
                            correctedNote[0] = newTime;
                            trace('Moved 4-note chord to avoid clustering with nearby large chord');
                            return correctedNote;
                        }
                    }
                }
            }
        }

        return note;
    }

    /**
     * Finds a safe alternate column that won't create timing conflicts
     */
    private static function findSafeAlternateColumn(originalColumn:Int, noteTime:Float, existingNotes:Array<Array<Dynamic>>, mania:Int):Int
    {
        var baseColumn = originalColumn % Note.ammo[mania];
        var mustPress = originalColumn >= Note.ammo[mania];

        // Try each available column
        for (i in 0...Note.ammo[mania])
        {
            if (i == baseColumn) continue; // Skip original column

            var testColumn = i + (mustPress ? Note.ammo[mania] : 0);

            // Check if this column is safe (no recent notes)
            var isSafe = true;
            for (existingNote in existingNotes)
            {
                var existingTime:Float = existingNote[0];
                var existingColumn:Int = Std.int(existingNote[1]);

                if (existingColumn == testColumn)
                {
                    var timeDiff = Math.abs(existingTime - noteTime);
                    if (timeDiff < FAST_JACK_THRESHOLD)
                    {
                        isSafe = false;
                        break;
                    }
                }
            }

            if (isSafe) return testColumn;
        }

        return -1; // No safe column found
    }

    /**
     * Finds a safe time slot that doesn't create timing conflicts
     */
    private static function findSafeTimeSlot(originalTime:Float, existingNotes:Array<Array<Dynamic>>, mania:Int, mustPress:Bool):Float
    {
        // Try moving the note forward first, then backward
        var searchDirections = [1, -1];
        var searchStep:Float = 10; // 10ms increments

        for (direction in searchDirections)
        {
            for (offset in 1...Std.int(NOTE_REPOSITIONING_RANGE / searchStep))
            {
                var testTime = originalTime + (direction * offset * searchStep);
                if (testTime < 0) continue; // Don't go negative

                // Check if this time slot is safe
                var simultaneousCount = 0;
                var hasNearbyLargeChords = false;

                for (existingNote in existingNotes)
                {
                    var existingTime:Float = existingNote[0];
                    var existingColumn:Int = Std.int(existingNote[1]);
                    var existingMustPress = existingColumn >= Note.ammo[mania];

                    var timeDiff = Math.abs(existingTime - testTime);

                    // Count simultaneous notes
                    if (timeDiff < 10 && existingMustPress == mustPress)
                    {
                        simultaneousCount++;
                    }

                    // Check for nearby large chords
                    if (timeDiff < CHORD_SPACING_THRESHOLD && timeDiff > 0)
                    {
                        var chordSize = 0;
                        for (checkNote in existingNotes)
                        {
                            var checkTime:Float = checkNote[0];
                            var checkColumn:Int = Std.int(checkNote[1]);
                            var checkMustPress = checkColumn >= Note.ammo[mania];

                            if (Math.abs(checkTime - existingTime) < 10 && checkMustPress == mustPress)
                            {
                                chordSize++;
                            }
                        }

                        if (chordSize >= 3)
                        {
                            hasNearbyLargeChords = true;
                            break;
                        }
                    }
                }

                // If this time slot is safe, use it
                if (simultaneousCount < MAX_SIMULTANEOUS_NOTES - 1 && !hasNearbyLargeChords)
                {
                    return testTime;
                }
            }
        }

        return originalTime; // Couldn't find a better time
    }

    /**
     * Validates that generated patterns are playable
     */
    private static function validatePlayability(song:SwagSong):Void
    {
        trace('Validating chart playability...');

        for (section in song.notes)
        {
            // Remove impossible patterns (too many simultaneous notes)
            var notesByTime:Dynamic = {};

            for (note in section.sectionNotes)
            {
                var time:Float = note[0];
                var timeKey:String = Std.string(time);
                if (!Reflect.hasField(notesByTime, timeKey))
                    Reflect.setField(notesByTime, timeKey, []);
                var notesAtTime:Array<Array<Dynamic>> = Reflect.field(notesByTime, timeKey);
                notesAtTime.push(note);
            }

            // Check each timestamp for playability
            for (timeKey in Reflect.fields(notesByTime))
            {
                var notes:Array<Array<Dynamic>> = Reflect.field(notesByTime, timeKey);
                validateNotesAtTime(notes);
            }
        }
    }

    /**
     * Validates notes at a specific timestamp
     */
    private static function validateNotesAtTime(notes:Array<Array<Dynamic>>):Void
    {
        var mania = CollectionUtils.isReal(PlayState.SONG.mania) ? PlayState.SONG.mania : 3;

        // Group by player side
        var playerNotes:Array<Array<Dynamic>> = [];
        var opponentNotes:Array<Array<Dynamic>> = [];

        for (note in notes)
        {
            if (note[1] >= Note.ammo[mania])
                playerNotes.push(note);
            else
                opponentNotes.push(note);
        }

        // Ensure no more than 4 simultaneous notes per side (max human fingers)
        if (playerNotes.length > 4)
        {
            trace('Warning: Too many simultaneous player notes (${playerNotes.length}), reducing complexity');
            // Keep only the first 4 notes
            playerNotes = playerNotes.slice(0, 4);
        }

        if (opponentNotes.length > 4)
        {
            trace('Warning: Too many simultaneous opponent notes (${opponentNotes.length}), reducing complexity');
            opponentNotes = opponentNotes.slice(0, 4);
        }
    }

    // Helper functions
    private static function calculateAverageInterval(timestamps:Array<Float>):Float
    {
        if (timestamps.length < 2) return 1000; // Default large interval

        var intervals:Array<Float> = [];
        for (i in 1...timestamps.length)
        {
            intervals.push(timestamps[i] - timestamps[i-1]);
        }

        return CollectionUtils.sum(intervals) / intervals.length;
    }

    /**
     * Detects existing jack patterns in a section
     */
    private static function detectJackPatterns(sectionNotes:Array<Array<Dynamic>>):Array<JackPattern>
    {
        var jackPatterns:Array<JackPattern> = [];
        var notesByColumn:Map<Int, Array<Array<Dynamic>>> = new Map();

        // Group notes by column
        for (note in sectionNotes)
        {
            var column:Int = Std.int(note[1]);
            if (!notesByColumn.exists(column))
                notesByColumn.set(column, []);
            notesByColumn.get(column).push(note);
        }

        // Analyze each column for jack patterns
        for (column => notes in notesByColumn)
        {
            if (notes.length < 2) continue;

            // Sort notes by time
            notes.sort((a, b) -> Std.int(a[0] - b[0]));

            var currentJack:Array<Array<Dynamic>> = [notes[0]];
            var jackStart:Float = notes[0][0];

            for (i in 1...notes.length)
            {
                var prevTime:Float = notes[i-1][0];
                var currentTime:Float = notes[i][0];
                var interval:Float = currentTime - prevTime;

                // If interval is within jack range, continue the jack
                if (interval >= MIN_JACK_INTERVAL && interval <= MAX_JACK_INTERVAL)
                {
                    currentJack.push(notes[i]);
                }
                else
                {
                    // End current jack if it has at least 2 notes and isn't too fast
                    if (currentJack.length >= 2 && !isJackTooFast(currentJack))
                    {
                        jackPatterns.push({
                            column: column,
                            startTime: jackStart,
                            notes: currentJack.copy(),
                            length: currentJack.length
                        });
                    }

                    // Start new potential jack
                    currentJack = [notes[i]];
                    jackStart = notes[i][0];
                }
            }

            // Check final jack
            if (currentJack.length >= 2 && !isJackTooFast(currentJack))
            {
                jackPatterns.push({
                    column: column,
                    startTime: jackStart,
                    notes: currentJack.copy(),
                    length: currentJack.length
                });
            }
        }

        return jackPatterns;
    }

    private static function calculateComplexityScore(song:SwagSong):Float
    {
        // Simple complexity calculation based on note count and variety
        var totalNotes = 0;
        var totalChords = 0;

        for (section in song.notes)
        {
            totalNotes += section.sectionNotes.length;
            var notesByTime:Dynamic = {};

            for (note in section.sectionNotes)
            {
                var time:Float = note[0];
                var timeKey:String = Std.string(time);
                if (!Reflect.hasField(notesByTime, timeKey))
                    Reflect.setField(notesByTime, timeKey, 0);
                var count:Int = Reflect.field(notesByTime, timeKey);
                Reflect.setField(notesByTime, timeKey, count + 1);
            }

            for (timeKey in Reflect.fields(notesByTime))
            {
                var count:Int = Reflect.field(notesByTime, timeKey);
                if (count > 1) totalChords++;
            }
        }

        return totalNotes * 0.1 + totalChords * 0.5;
    }

    private static function calculateSectionIntensity(pattern:PatternData, baseIntensity:Float):Float
    {
        // Adjust intensity based on section characteristics
        var densityMultiplier = Math.min(pattern.noteDensity / 4.0, 2.0); // Cap at 2x
        var intervalMultiplier = Math.max(1.0, 500.0 / pattern.avgInterval); // Faster = more intense

        return Math.min(baseIntensity * densityMultiplier * intervalMultiplier, 2.0);
    }

    /**
     * Helper function to check if a note array contains a specific note
     */
    private static function containsNote(noteArray:Array<Array<Dynamic>>, targetNote:Array<Dynamic>):Bool
    {
        for (note in noteArray)
        {
            if (note.length >= 2 && targetNote.length >= 2)
            {
                var timeDiff = Math.abs(note[0] - targetNote[0]);
                var columnMatch = note[1] == targetNote[1];
                if (timeDiff < 10 && columnMatch) // 10ms tolerance for timing
                    return true;
            }
        }
        return false;
    }

    /**
     * Determines if complex patterns should be generated
     */
    private static function shouldGenerateComplexPattern(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Bool
    {
        if (!isComplexMode) return false;

        // Avoid complex patterns in very dense areas
        if (pattern.noteDensity > 7) return false;

        // Prefer complex patterns in moderately dense areas
        var complexProbability = COMPLEX_PATTERN_PROBABILITY * intensity;

        // Boost probability in good density range
        if (pattern.noteDensity >= 2 && pattern.noteDensity <= 4) {
            complexProbability *= 1.3; // 30% boost
        }
        // Reduce in sparse areas
        else if (pattern.noteDensity < 1.5) {
            complexProbability *= 0.7; // 30% reduction
        }

        return FlxG.random.bool(complexProbability * 100);
    }

    /**
     * Generates complex note patterns (polyrhythms, syncopation, grace notes)
     */
    private static function generateComplexPattern(notes:Array<Array<Dynamic>>, intensity:Float, pattern:PatternData):Array<Array<Dynamic>>
    {
        var result:Array<Array<Dynamic>> = [];
        var baseNote = notes[0];
        var noteTime:Float = baseNote[0];
        var noteColumn:Int = Std.int(baseNote[1]);

        // Generate different types of complex patterns
        var patternType = FlxG.random.int(0, 3);

        switch (patternType)
        {
            case 0: // Grace notes (quick notes before main note)
                var graceTime = noteTime - (50 + FlxG.random.float(0, 50)); // 50-100ms before
                var graceColumn = findAlternateColumn(noteColumn);
                if (graceColumn != -1)
                {
                    result.push([graceTime, graceColumn, 0, "Grace Note"]);
                }

            case 1: // Polyrhythm (offset timing)
                var offsetTime = noteTime + (25 + FlxG.random.float(0, 25)); // 25-50ms after
                var offsetColumn = findAlternateColumn(noteColumn);
                if (offsetColumn != -1)
                {
                    result.push([offsetTime, offsetColumn, 0, "Polyrhythm"]);
                }

            case 2: // Syncopation (add notes between beats)
                if (pattern.avgInterval > 200) // Only if there's space
                {
                    var syncoTime = noteTime + pattern.avgInterval * 0.5;
                    var syncoColumn = findAlternateColumn(noteColumn);
                    if (syncoColumn != -1)
                    {
                        result.push([syncoTime, syncoColumn, 0, "Syncopation"]);
                    }
                }

            case 3: // Echo notes (delayed repeats)
                var echoTime = noteTime + (100 + FlxG.random.float(0, 100)); // 100-200ms after
                var echoColumn = findAlternateColumn(noteColumn);
                if (echoColumn != -1)
                {
                    result.push([echoTime, echoColumn, 0, "Echo"]);
                }
        }

        return result;
    }

    /**
     * Checks if a jack pattern has any intervals that are too fast to be playable
     */
    private static function isJackTooFast(jackNotes:Array<Array<Dynamic>>):Bool
    {
        if (jackNotes.length < 2) return false;

        for (i in 1...jackNotes.length)
        {
            var interval = jackNotes[i][0] - jackNotes[i-1][0];
            if (interval < FAST_JACK_THRESHOLD)
            {
                return true;
            }
        }

        return false;
    }
}

/**
 * Data structures for pattern analysis
 */
typedef PatternData = {
    sectionIndex:Int,
    noteCount:Int,
    chordCount:Int,
    jackCount:Int,
    jackPatterns:Array<JackPattern>,
    noteDensity:Float,
    timestamps:Array<Float>,
    avgInterval:Float
}

typedef JackPattern = {
    column:Int,
    startTime:Float,
    notes:Array<Array<Dynamic>>,
    length:Int
}

typedef RhythmAnalysis = {
    ?dominantPattern:String,
    ?avgTempo:Float,
    ?rhythmComplexity:Float
}

typedef DifficultyProfile = {
    ?averageNoteDensity:Float,
    ?chordRatio:Float,
    ?complexityScore:Float,
    ?recommendedIntensity:Float
}
