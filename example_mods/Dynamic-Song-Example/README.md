# Dynamic Song Example Mod

This mod demonstrates the Mixtape Engine's dynamic song system, where sections of a song can change based on programmatic logic, player performance, or random selection.

## What This Demonstrates

- **Multiple Verse Difficulties**: The song includes easy, normal, and hard verse sections that are selected based on the current difficulty and player performance
- **Random Bridge/Solo Selection**: The system randomly chooses between a bridge or solo section for variety
- **Programmatic Generation**: A Lua script controls which sections are played using custom logic
- **Seamless Audio**: Each section has its own audio file that transitions smoothly
- **Event Integration**: Sections include camera movements, effects, and character animations

## Files Included

### Song Data
- `data/example-dynamic/dynamic.json` - Main dynamic song configuration
- `data/example-dynamic/example-dynamic.json` - Fallback chart for non-dynamic engines
- `data/example-dynamic/sections/` - Individual section chart files

### Section Files
- `intro.json` - Opening section with simple pattern
- `verse_easy.json` - Easy verse with basic note patterns
- `verse_normal.json` - Normal verse with moderate complexity
- `verse_hard.json` - Hard verse with rapid note sequences
- `chorus.json` - Repeatable chorus section
- `bridge.json` - Calm bridge section with character changes
- `solo.json` - Intense solo section with effects
- `outro.json` - Ending section with fade out

### Scripts
- `scripts/dynamic_generation.lua` - Programmatic section generation logic

### Audio (Not Included)
Place audio files in `songs/example-dynamic/` following the engine's standard naming conventions:

**Main song files (fallback):**
- `Inst.ogg` - Main instrumental (fallback)
- `Voices.ogg` - Main vocals (fallback)

**Section audio files in `songs/example-dynamic/sections/`:**
- `intro.ogg` - Intro instrumental
- `Voices.ogg` - Intro vocals
- `verse_easy.ogg` - Easy verse instrumental
- `verse_normal.ogg` - Normal verse instrumental
- `verse_hard.ogg` - Hard verse instrumental
- `Voices-Player.ogg` - Player vocals for verses
- `Voices-Opponent.ogg` - Opponent vocals for verses
- `chorus.ogg` - Chorus instrumental
- `Voices-GF.ogg` - GF vocals for chorus
- `bridge.ogg` - Bridge instrumental
- `solo.ogg` - Solo instrumental
- `outro.ogg` - Outro instrumental

**Audio File Naming Convention:**
- Instrumentals: `sectionname.ogg` (e.g., `intro.ogg`, `verse_easy.ogg`)
- Vocals: `Voices.ogg` (general vocals) or `Voices-Character.ogg` (character-specific)
- Supported vocal characters: `Player`, `Opponent`, `GF`

## How It Works

1. The song loads `dynamic.json` which defines all available sections
2. The Lua script's `generateSectionSequence()` function is called
3. The script analyzes the current difficulty and player performance
4. It returns an array of section names in the desired order
5. The engine stitches these sections together seamlessly
6. Audio transitions happen automatically between sections

## Generation Logic

The included script demonstrates several generation strategies:

### Performance-Based Selection
- Easy verses for struggling players (< 60% accuracy)
- Hard verses for skilled players (> 95% accuracy)
- Normal verses for average performance

### Random Variety
- 50/50 chance between bridge and solo sections
- Weighted random selection for verse difficulties

### Adaptive Difficulty
- Monitors player accuracy during gameplay
- Adjusts upcoming sections based on performance

## Customization

You can modify the generation logic by editing `dynamic_generation.lua`:

```lua
function generateSectionSequence(config)
    local sections = {}

    -- Your custom logic here
    table.insert(sections, "intro")
    -- Add sections based on your criteria

    return sections
end
```

## Testing

To test this mod:
1. Place the mod folder in your `example_mods/` directory
2. Add the required audio files
3. Select "Example Dynamic" from the freeplay menu
4. Watch as the song adapts based on your performance

## Compatibility

- **Dynamic Engines**: Full dynamic functionality with section switching
- **Standard Engines**: Falls back to the static chart in `example-dynamic.json`
- **Audio Requirements**: Requires individual section audio files for best experience
