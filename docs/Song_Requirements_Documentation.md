# Song Requirements System Documentation

The Song Requirements system allows you to make specific songs require certain items before they can be accessed or played. This creates a progression system where players must earn items to unlock harder content.

## How It Works

### 1. HScript Implementation

In your mod's HScript files (`mods/YourMod/ap/yourscript.hx`), you can define song requirements:

```haxe
// Basic song requirement (single item)
addSimpleSongRequirement("Boss Battle", null, ["Power Boost"]);

// Multiple items required
addSimpleSongRequirement("Final Boss", null, ["Magic Key", "Super Shield"]);

// Items with specific counts
var requirements = [
    { name: "Energy Crystal", count: 3 },
    { name: "Master Key", count: 1 }
];
addSongRequirementWithCounts("Ultimate Challenge", null, requirements);

// Cross-mod requirements
addSimpleSongRequirement("Cross Mod Song", "Other Mod", ["Special Item"]);

// Base game song requirements
addSimpleSongRequirement("Roses", "", ["Thorns Protection"]);
```

### 2. Python Implementation

In your custom data Python files (`PlayerName_customFNFData.py`), add song requirements to the data:

```python
def get_custom_data_for_class():
    return {
        'items': ["Power Boost", "Magic Key", "Super Shield"],
        'locations': your_custom_locations,
        'song_requirements': [
            {
                "songName": "Boss Battle",
                "targetMod": "",  # Empty = base game
                "requiredItems": [
                    {"name": "Power Boost", "count": 1}
                ]
            },
            {
                "songName": "Final Boss",
                "targetMod": "",
                "requiredItems": [
                    {"name": "Magic Key", "count": 1},
                    {"name": "Super Shield", "count": 1}
                ]
            }
        ]
    }
```

## System Integration

### World Generation

During world generation, the system:

1. **Collects Requirements**: Gathers all song requirements from HScript and Python files
2. **Validates Songs**: Ensures required songs exist in the player's song pool
3. **Creates Access Rules**: Generates logic that checks for required items
4. **Applies to Locations**: All locations based on a song inherit its requirements

### Access Rule Logic

When a song has requirements, its locations become accessible only when:

1. **Song Access**: Player has received the song item (normal AP logic)
2. **Item Requirements**: Player has all required items with correct counts
3. **Victory Conditions**: Special handling for victory songs (still need tickets)

### Client Integration

The client receives song requirements through slot data:

```python
slot_data = {
    "songRequirements": [
        {
            "songName": "Boss Battle",
            "targetMod": "",
            "requiredItems": [{"name": "Power Boost", "count": 1}]
        }
    ]
}
```

## Use Cases

### Progressive Difficulty
Lock harder songs behind easier ones plus skill items:
```haxe
addSimpleSongRequirement("Expert Mode", null, ["Rhythm Master", "Perfect Timing"]);
```

### Story Progression
Gate story songs behind narrative items:
```haxe
addSimpleSongRequirement("Chapter 2", null, ["Chapter 1 Complete", "Story Key"]);
```

### Cross-Mod Integration
Make collaboration songs require items from multiple mods:
```haxe
addSimpleSongRequirement("Crossover Battle", null, ["Mod A Token", "Mod B Token"]);
```

### Challenge Modes
Lock special modes behind achievement items:
```haxe
addSimpleSongRequirement("Nightmare Mode", null, ["Courage", "Determination", "Skill"]);
```

### Item Gating
Create item sinks that require multiple copies:
```haxe
addSongRequirementWithCounts("Resource Sink", null, [
    { name: "Common Item", count: 10 },
    { name: "Rare Item", count: 3 }
]);
```

## Best Practices

### 1. Logical Progression
Ensure requirements create a logical flow through your content:
```haxe
// Good: Clear progression path
addSimpleSongRequirement("Tutorial Plus", null, ["Basic Training"]);
addSimpleSongRequirement("Advanced Test", null, ["Basic Training", "Advanced Techniques"]);
addSimpleSongRequirement("Expert Trial", null, ["Advanced Techniques", "Expert Knowledge"]);
```

### 2. Provide Sources
Always create locations that give the required items:
```haxe
// Require the item
addSimpleSongRequirement("Boss Battle", null, ["Power Boost"]);

// Provide the item
addItem("Power Boost");
addSimpleLocation("Power Training", "tutorial", null, []);  // Gives Power Boost
```

### 3. Avoid Softlocks
Don't create impossible requirements:
```haxe
// Bad: Circular dependency
addSimpleSongRequirement("Song A", null, ["Item from Song B"]);
addSimpleSongRequirement("Song B", null, ["Item from Song A"]);

// Good: Linear progression
addSimpleSongRequirement("Song A", null, ["Basic Item"]);
addSimpleSongRequirement("Song B", null, ["Basic Item", "Advanced Item"]);
```

### 4. Consider Song Limits
Song requirements work with song limits, but songs may be excluded:
```haxe
// If "Boss Battle" gets cut by song limit, its requirement is ignored
addSimpleSongRequirement("Boss Battle", null, ["Power Boost"]);
```

### 5. Test Thoroughly
Verify your progression makes sense:
- Can players actually obtain all required items?
- Are there multiple paths to progression?
- Do requirements match your intended difficulty curve?

## Error Handling

The system includes extensive validation:

- **Invalid Songs**: Requirements for non-existent songs are skipped
- **Missing Items**: Requirements for non-existent items are ignored
- **Mod Validation**: Cross-mod requirements check if target mods exist
- **Song Limits**: Requirements are validated against final song pools

Errors are logged but don't break generation, ensuring robustness.

## Technical Details

### HScript Functions

- `addSongRequirement(songName, targetMod, accessRule, requireTargetMod)`
- `addSimpleSongRequirement(songName, targetMod, requiredItems, requireTargetMod)`
- `addSongRequirementWithCounts(songName, targetMod, requiredItems, requireTargetMod)`
- `hasSongRequirement(songName, targetMod)`: Bool
- `getSongRequirement(songName, targetMod)`: APSongRequirement

### Python Data Format

```python
{
    "songName": "Song Name",
    "targetMod": "Mod Name or Empty String",
    "requiredItems": [
        {"name": "Item Name", "count": 1}
    ]
}
```

### Access Rule Generation

The system creates access rules that combine:
1. Normal song access (`state.has(song_name, player)`)
2. Item requirements (`state.has(item_name, player, count)`)
3. Victory song logic (ticket requirements)

## Examples

See `TestSongRequirements_customFNFData.py` for a complete working example that demonstrates:
- Progressive difficulty unlocking
- Multiple requirement types
- Item sourcing through custom locations
- Integration with existing AP systems

The song requirements system provides powerful tools for creating structured, progression-based experiences in your Friday Night Funkin' Archipelago worlds!
