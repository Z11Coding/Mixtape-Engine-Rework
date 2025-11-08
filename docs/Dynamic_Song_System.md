# Dynamic Song System Documentation

## Overview
The Dynamic Song System allows songs to have sections that can change based on random chance, player performance, or custom scripting. Songs are dynamically stitched together from pre-defined sections to create a seamless, varying experience.

## Format Specification

### Format Identifier
- Format: `"mixtape_dynamic_v1"`
- Compatible with existing engines through fallback mechanisms
- Does not conflict with High Quality Trap formats

### File Structure
Dynamic songs use a main chart file and a sections folder:
```
data/song-name/
├── song-name.json (main chart)
├── sections/
│   ├── intro.json
│   ├── verse1a.json
│   ├── verse1b.json
│   ├── chorus.json
│   └── outro.json
└── dynamic.json (configuration)
```

### Dynamic Configuration Format (`dynamic.json`)

**Example 1: Programmatic Mode**
```jsonc
{
  "format": "mixtape_dynamic_v1",
  "songName": "example-song",
  "sections": {
    "intro": {
      "chartFile": "sections/intro.json",
      "audioFiles": {
        "inst": "sections/intro-Inst.ogg",
        "vocals": "sections/intro-Vocals.ogg"
      },
      "duration": 8000,
      "canRepeat": false,
      "weight": 1.0
    },
    "verse_normal": {
      "chartFile": "sections/verse_normal.json",
      "audioFiles": {
        "inst": "sections/verse_normal-Inst.ogg",
        "vocalsPlayer": "sections/verse_normal-Player.ogg",
        "vocalsOpponent": "sections/verse_normal-Opponent.ogg"
      },
      "duration": 16000,
      "canRepeat": false,
      "weight": 1.0
    },
    "verse_hard": {
      "chartFile": "sections/verse_hard.json",
      "audioFiles": {
        "inst": "sections/verse_hard-Inst.ogg",
        "vocalsPlayer": "sections/verse_hard-Player.ogg",
        "vocalsOpponent": "sections/verse_hard-Opponent.ogg"
      },
      "duration": 16000,
      "canRepeat": false,
      "weight": 1.0
    },
    "chorus": {
      "chartFile": "sections/chorus.json",
      "audioFiles": {
        "inst": "sections/chorus-Inst.ogg",
        "vocals": "sections/chorus-Vocals.ogg"
      },
      "duration": 12000,
      "canRepeat": true,
      "weight": 1.0
    },
    "outro": {
      "chartFile": "sections/outro.json",
      "audioFiles": {
        "inst": "sections/outro-Inst.ogg",
        "vocals": "sections/outro-Vocals.ogg"
      },
      "duration": 6000,
      "canRepeat": false,
      "weight": 1.0
    }
  },
  "flow": {
    "generationMode": "programmatic",
    "generator": "generateSongSections"
  },
  "fallback": {
    "mainChart": "example-song.json",
    "audioFiles": {
      "inst": "Inst.ogg",
      "vocals": "Vocals.ogg"
    }
  },
  "metadata": {
    "totalVariations": 4,
    "averageDuration": 120000,
    "scriptingEnabled": true,
    "description": "Dynamic song with difficulty-based verse selection"
  }
}
```

**Example 2: Simple Random Mode**
```jsonc
{
  "format": "mixtape_dynamic_v1",
  "songName": "random-song",
  "sections": {
    "intro": { /* section definition */ },
    "verse1": { /* section definition */ },
    "verse2": { /* section definition */ },
    "verse3": { /* section definition */ },
    "chorus": { /* section definition */ },
    "bridge": { /* section definition */ },
    "outro": { /* section definition */ }
  },
  "flow": {
    "generationMode": "simple_random",
    "simpleRandom": {
      "startSection": "intro",
      "endSection": "outro",
      "middleSections": ["verse1", "verse2", "verse3", "chorus", "bridge"],
      "middleCount": 3
    }
  },
  "fallback": {
    "mainChart": "random-song.json",
    "audioFiles": {
      "inst": "Inst.ogg",
      "vocals": "Vocals.ogg"
    }
  }
}
```

### Section Chart Format
Each section uses standard FNF chart format with relative timing:
```jsonc
{
  "format": "mixtape_section_v1",
  "sectionName": "intro",
  "notes": [/* Standard FNF notes with time relative to section start */],
  "events": [/* Events relative to section start */],
  "bpm": 120,
  "offset": 0,
  "duration": 8000 // Section duration in milliseconds
}
```

## Generation Modes

### Programmatic Generation
The default mode where section sequences are determined by custom logic:
```lua
function generateSongSections(sections, metadata, gameState)
    local sequence = {}

    -- Always start with intro
    table.insert(sequence, "intro")

    -- Determine verses based on difficulty
    if gameState.difficulty > 2 then
        table.insert(sequence, "verse_hard")
    else
        table.insert(sequence, "verse_normal")
    end

    -- Add chorus
    table.insert(sequence, "chorus")

    -- End with outro
    table.insert(sequence, "outro")

    return sequence
end
```

### Simple Random Mode
A built-in mode for basic randomization:
- Automatically uses `startSection` first
- Randomly selects `middleCount` sections from `middleSections`
- Always ends with `endSection`
- If `middleCount` is -1, uses all middle sections in random order

### Custom Mode
Uses a custom generator function with full control over the selection process.

## Audio Stitching

The system concatenates audio files seamlessly:
1. Pre-loads all required audio sections during song generation
2. Builds a master timeline of selected sections
3. Creates virtual audio tracks that play segments at correct times
4. Supports both single vocals and multi-track vocals (Player/Opponent/GF)
5. Handles audio synchronization and crossfading

## Modding Integration

### Lua Functions
```lua
-- Generate song sections (main function)
function generateSongSections(sections, metadata, gameState)
    local sequence = {}

    -- Example: Simple progression
    table.insert(sequence, "intro")
    table.insert(sequence, "verse1")
    table.insert(sequence, "chorus")
    table.insert(sequence, "verse2")
    table.insert(sequence, "chorus")
    table.insert(sequence, "outro")

    return sequence
end

-- Advanced example with conditional logic
function generateAdvancedSections(sections, metadata, gameState)
    local sequence = {}

    -- Always start with intro
    table.insert(sequence, "intro")

    -- Choose verse based on player performance
    if gameState.accuracy > 0.9 then
        table.insert(sequence, "verse_expert")
    elseif gameState.accuracy > 0.7 then
        table.insert(sequence, "verse_hard")
    else
        table.insert(sequence, "verse_normal")
    end

    -- Add chorus
    table.insert(sequence, "chorus")

    -- Randomly pick bridge or solo
    if math.random() > 0.5 then
        table.insert(sequence, "bridge")
    else
        table.insert(sequence, "solo")
    end

    -- Final chorus and outro
    table.insert(sequence, "chorus")
    table.insert(sequence, "outro")

    return sequence
end

-- Get current dynamic section
function getCurrentDynamicSection()
    -- Implementation provided by engine
end

-- Force regeneration of remaining sections (advanced)
function regenerateDynamicSections()
    -- Implementation provided by engine
end

-- Check if song is dynamic
function isDynamicSong()
    -- Implementation provided by engine
end
```

### HScript Integration
Full HScript support for complex dynamic logic and custom selection algorithms.

## Compatibility

### High Quality Trap Compatibility
- Dynamic songs work alongside High Quality Traps
- Trap replacements can apply to entire dynamic songs or individual sections
- Format identifiers prevent conflicts

### Engine Compatibility
- Fallback mechanism for non-supporting engines
- Standard FNF format compatibility through main chart
- Graceful degradation when dynamic features unavailable

## Performance Considerations

- Pre-loading of audio segments during song generation
- Memory management for multiple audio tracks
- Efficient section switching without audio gaps
- Pooled audio objects for performance

## Use Cases

1. **Randomized Song Variations**: Different verses/bridges each playthrough
2. **Adaptive Difficulty**: Sections change based on player performance
3. **Narrative Branching**: Different musical paths based on story choices
4. **Remix Capabilities**: Mix and match sections from different versions
5. **Live Performance Mode**: Real-time section switching for performances

## Implementation Notes

- Maintains compatibility with existing Mixtape Engine features
- Integrates with note pooling system for performance
- Supports all existing modding capabilities
- Works with Archipelago randomizer system
- Compatible with chart editors through section editing mode
