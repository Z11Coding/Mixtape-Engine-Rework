# Custom Archipelago Logic Integration Guide

This system allows you to add custom items and locations with access rules to your Friday Night Funkin' Archipelago world by creating player-specific Python files alongside your YAML files.

## Key Changes in Version 2.0

### Simplified Ownership Model
- **No Player Prefixes**: Location and item names no longer need player prefixes (e.g., use `"Custom Boss Battle"` not `"Alice:Custom Boss Battle"`)
- **Automatic Ownership**: The system tracks which players own which locations using a `LocationData` class similar to how songs work
- **Cleaner Names**: All names in your custom files should be clean, readable names without prefixes

### Improved ID Management
- **Smart ID Assignment**: Custom IDs automatically start after the last song/location IDs to avoid conflicts
- **No Hardcoded Numbers**: The system calculates the next available ID range automatically
- **Better Organization**: Items and locations get their own ID ranges for better organization

### Integrated Access Rules
- **Stored with Locations**: Access rules are now stored directly with `LocationData` objects, not in separate dictionaries
- **Consistent Structure**: Similar to how song locations work in the base system
- **Better Performance**: No need to look up access rules in separate dictionaries

## How It Works

1. **Player-Specific Loading**: The system scans for files named `{playerName}_customFNFData.py` in the same directory as your YAML files
2. **Dynamic Execution**: These files are executed using Python's `exec()` function during world generation
3. **Ownership Tracking**: Each player's locations are tracked using the new `LocationData` system, similar to songs
4. **Origin Song Formatting**: Songs are automatically formatted with mod names in parentheses for clarity
5. **Smart Integration**: Custom items and locations are automatically added with proper ID assignment

## Creating Custom Logic Files

### File Naming
- Files must be named `{playerName}_customFNFData.py` where `{playerName}` matches your YAML player name
- Examples: `Alice_customFNFData.py`, `Bob_customFNFData.py`, `Player1_customFNFData.py`

### Origin Song Formatting
The system automatically formats origin songs with mod information:
- `"Bopeebo"` with mod `"Base Game"` becomes `"Bopeebo (Base Game)"`
- `"Expurgation"` with mod `"Tricky Mod"` becomes `"Expurgation (Tricky Mod)"`
- `"Tutorial"` with empty/no mod stays as `"Tutorial"`

### Required Functions

Your custom logic file must include this function:

```python
def get_custom_data_for_class():
    """Returns custom data for integration during class setup"""
    return {
        'items': custom_items,           # List of custom item names
        'locations': get_custom_locations()  # Dict of location_name -> location_object (includes access rules)
    }
```

### Example Structure

```python
# Custom items that can be added to the item pool
# NOTE: No player prefixes needed - the system handles ownership automatically
custom_items = [
    "Custom Power-Up",
    "Special Note", 
    "Bonus Track Access",
]

# Access rule functions for custom locations
def get_access_rules() -> Dict[str, Callable]:
    access_rules = {}

    def my_custom_location_rule(state, player: int) -> bool:
        # Origin song with mod formatting (automatic)
        has_origin_song = state.has("Bopeebo (Base Game)", player)
        # Requires custom items
        has_required_items = state.has("Custom Power-Up", player)
        return has_origin_song and has_required_items

    access_rules["My Custom Location"] = my_custom_location_rule
    return access_rules

# Custom location objects with embedded access rules
def get_custom_locations() -> Dict[str, Dict[str, Any]]:
    # Get access rules to embed in location objects
    access_rules = get_access_rules()
    
    return {
        "My Custom Location": {
            "origin_song": "Bopeebo",
            "origin_mod": "Base Game",  # Will format as "Bopeebo (Base Game)"
            "access_rule": access_rules["My Custom Location"],  # Rule embedded in object
        },
        "Modded Location": {
            "origin_song": "Expurgation",
            "origin_mod": "Tricky Mod",  # Will format as "Expurgation (Tricky Mod)"
            "access_rule": access_rules["Modded Location"],
        },
        "Base Game Only": {
            "origin_song": "Tutorial",
            "origin_mod": "",  # Will stay as "Tutorial" (no parentheses)
            "access_rule": access_rules["Base Game Only"],
        },
    }

# Required integration function
def get_custom_data_for_class():
    return {
        'items': custom_items,
        'locations': get_custom_locations()  # Locations include access rules
    }
```

## Player-Specific Examples

### Alice_customData.py
```python
# NOTE: Location and item names no longer need player prefixes
# The system automatically tracks that these belong to Alice

custom_items = ["Magic Wand", "Enchanted Shield"]

def get_access_rules():
    def boss_fight_rule(state, player: int) -> bool:
        return state.has("Bopeebo (Base Game)", player) and state.has("Magic Wand", player)
    return {"Epic Boss Fight": boss_fight_rule}

def get_custom_locations():
    return {
        "Epic Boss Fight": {
            "origin_song": "Bopeebo",
            "origin_mod": "Base Game"
        }
    }

def get_custom_data_for_class():
    return {
        'items': custom_items,
        'access_rules': get_access_rules(),
        'location_data': get_custom_locations()
    }
```

### Bob_customData.py
```python
# NOTE: Bob can use the same location names as Alice - the system handles ownership
# Each player will only see their own custom locations

custom_items = ["Power Hammer", "Steel Armor"]

def get_access_rules():
    def challenge_arena_rule(state, player: int) -> bool:
        return state.has("Fresh (Base Game)", player) and state.has("Power Hammer", player)
    return {"Challenge Arena": challenge_arena_rule}

def get_custom_locations():
    return {
        "Challenge Arena": {
            "origin_song": "Fresh",
            "origin_mod": "Base Game"
        }
    }

def get_custom_data_for_class():
    return {
        'items': custom_items,
        'access_rules': get_access_rules(),
        'location_data': get_custom_locations()
    }
```

def get_custom_data_for_class():
    return {
        'items': custom_items,
        'access_rules': get_access_rules(),
        'location_data': get_custom_locations()
    }
```

## Access Rule Examples

### Basic Song Requirement with Mod
```python
def simple_rule(state, player: int) -> bool:
    return state.has("Bopeebo (Base Game)", player)
```

### Base Game Song (No Mod Parentheses)
```python
def base_game_rule(state, player: int) -> bool:
    return state.has("Tutorial", player)  # No mod specified
```

### Modded Song Requirement
```python
def modded_rule(state, player: int) -> bool:
    return state.has("Expurgation (Tricky Mod)", player)
```

### Multiple Items Required
```python
def complex_rule(state, player: int) -> bool:
    has_song = state.has("Fresh (Base Game)", player)
    has_item1 = state.has("Special Note", player)
    has_item2 = state.has("Bonus Track Access", player)
    return has_song and has_item1 and has_item2
```

### Item Count Requirements
```python
def count_rule(state, player: int) -> bool:
    has_song = state.has("Dad Battle (Base Game)", player)
    has_multiple_shields = state.has("Super Shield", player, 3)  # Requires 3 shields
    return has_song and has_multiple_shields
```

## Integration Process

1. **Class Setup**: During the `stuff()` function, player-specific custom files are loaded and executed
2. **Ownership Tracking**: `LocationData` objects track which players own which locations (similar to `SongData` for songs)
3. **Smart ID Assignment**: Custom items and locations get IDs that start after the last song/location IDs
4. **Region Creation**: Custom locations are added to the "Freeplay" region only for players who own them
5. **Origin Song Formatting**: Songs are automatically formatted with mod names in parentheses
6. **Embedded Access Rules**: Custom access rules are stored directly within location objects
7. **Item Pool**: Custom items are added only for players who have custom locations

## Debugging

The system provides console output to help debug:
- "Loading custom logic for player 'PlayerName' from: filename.py"
- "Loaded X custom items and Y custom locations for player 'PlayerName'"
- "Applied custom access rule to: Location Name"
- "Applied origin song access rule (Song Name (Mod)) to: Location Name"
- "Added custom location for PlayerName: Location Name"

## Technical Details

### LocationData Class
```python
class LocationData:
    def __init__(self, code: int, location_name: str, player_owner: str, player_list: List[str], 
                 origin_song: str = "", origin_mod: str = "", access_rule_func=None):
        self.code = code                        # Unique location ID
        self.locationName = location_name       # Clean location name (no prefixes)
        self.playerLocationBelongsTo = player_owner  # Primary owner
        self.playerList = player_list           # All players who can access
        self.originSong = origin_song          # Song requirement
        self.originMod = origin_mod            # Mod for song formatting
        self.accessRuleFunc = access_rule_func # Custom access rule function
```

### ID Assignment
- **Song Items**: Start at `STARTING_CODE + 100`
- **Song Locations**: Start at `song_item_ids + 1000`
- **Custom Locations**: Start at `max(song_locations) + 1000`
- **Custom Items**: Start at `custom_location_end + 1000`

## Song Name Formatting Rules

1. **With Mod**: `"Bopeebo"` + `"Base Game"` → `"Bopeebo (Base Game)"`
2. **Without Mod**: `"Tutorial"` + `""` → `"Tutorial"`
3. **Custom Mod**: `"Expurgation"` + `"Tricky Mod"` → `"Expurgation (Tricky Mod)"`

## Debugging

The system provides console output to help debug:
- "Loading custom logic from: filename.py"
- "Loaded X custom items and Y custom locations from filename.py"
- "Applied custom access rule to: Location Name"
- "Added custom location: Location Name"

## Using the HaxE Generator

You can use the HaxE `APPythonGenerator` class to generate player-specific custom logic files:

```haxe
// Add items and locations (no player prefixes needed)
APLua.addItem("Custom Power-Up");
APLua.addSimpleLocation("Boss Battle", "Bopeebo", "Base Game", ["Custom Power-Up"]);

// Generate Python file
var pythonCode = APPythonGenerator.generatePythonScript();
// Save as "PlayerName_customData.py"
```

This will create a properly formatted Python file with:
- Clean location and item names (no player prefixes)
- Origin song formatting with mod parentheses
- All required functions and structure
- Ownership handled automatically by the system

## Best Practices

1. **File Naming**: Always name files `{PlayerName}_customFNFData.py` matching your YAML player name
2. **Clean Names**: Use clean, readable names without player prefixes - the system handles ownership
3. **Shared Names**: Multiple players can use the same location/item names - they won't conflict
4. **Origin Songs**: Always specify origin songs for automatic access rule generation
5. **Embedded Rules**: Include access rules directly in location objects for better organization
6. **Testing**: Use console output to verify your custom logic is loaded correctly
3. **Clear Origin Songs**: Always specify origin songs and mods for context
4. **Mod Specification**: Use empty string `""` for base game content, specific mod names for modded content
5. **Testing**: Test with multiple players to ensure no conflicts
6. **Documentation**: Comment your access rules clearly

## Troubleshooting

- **File not loading**: Check filename format is `{PlayerName}_customData.py`
- **Access rules not working**: Ensure function names match in `get_access_rules()`
- **Items not appearing**: Verify items are listed in `custom_items` array
- **Wrong song format**: Check origin_song and origin_mod are correctly specified
- **Player conflicts**: Each player should have their own separate file
- **Syntax errors**: Check Python syntax in your custom files
