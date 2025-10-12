# Song Access Rule Fix

## Problem
The original implementation had two issues with song access rules:

1. **Unreliable mod name parsing**: When extracting mod names from song names with multiple parentheses, the parsing logic could incorrectly identify which parentheses contained the mod name.

2. **Incorrect state.has() checks**: The access rules were checking for just the song name (e.g., "Bopeebo") but the actual item names include the mod name in parentheses (e.g., "Bopeebo (MyMod)").

## Solution
Fixed the `_create_song_access_rule` method to:

1. **Build full item names correctly**: Instead of trying to parse mod names from complex song names, the method now builds the full item name by combining the song name and mod name parameters passed to it.

2. **Use full names in state.has()**: The access rules now check for the complete item name including mod name in parentheses.

## Example

### Before (Problematic)
```python
def song_access_rule(state):
    # This would fail for "My Song (Special Edition) (MyMod)"
    has_song = state.has("My Song", self.player)  # Wrong - item is "My Song (Special Edition) (MyMod)"
    return has_song
```

### After (Fixed)
```python
def song_access_rule(state):
    # Build the full item name correctly
    full_song_name = f"{song_name} ({mod_name})" if mod_name else song_name
    has_song = state.has(full_song_name, self.player)  # Correct - matches actual item name
    return has_song
```

## Impact
- Song requirements now work correctly for modded songs
- Access rules properly check for the actual item names in the player's inventory
- Victory song detection works correctly for modded songs
- Custom locations with song requirements function properly

## Code Changes
- Updated `_create_song_access_rule()` method to build full item names
- Improved mod name extraction in `create_regions()` to be more reliable
- Maintained backward compatibility with base game songs (no mod name)
