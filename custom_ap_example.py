# Generated Archipelago custom locations and access rules
# This file should be named '{playerName}_customFNFData.py' and placed in the same directory as your YAML file
# Replace {playerName} with your actual player name from the YAML file
# Example: if your player name is "Alice", name this file "Alice_customFNFData.py"

from typing import Dict, Callable, Any

# Custom items that can be added to the item pool
# NOTE: Items are now shared across players - no player prefixes needed
# The system will automatically handle which players get which items based on their custom locations
custom_items = [
    "Custom Power-Up",
    "Special Note", 
    "Bonus Track Access",
    "Super Shield",
    "Mega Health Boost",
]

# Access rule functions for custom locations  
def get_access_rules() -> Dict[str, Callable]:
    """Returns a dictionary of location names to their access rule functions"""
    access_rules = {}

    # Access rule for Custom Boss Battle
    def custom_boss_battle_rule(state, player: int) -> bool:
        # Requires origin song: Bopeebo (Base Game)
        has_origin_song = state.has("Bopeebo (Base Game)", player)
        # Required items: Custom Power-Up
        has_required_items = state.has("Custom Power-Up", player)
        return has_origin_song and has_required_items

    access_rules["Custom Boss Battle"] = custom_boss_battle_rule

    # Access rule for Secret Area
    def secret_area_rule(state, player: int) -> bool:
        # Requires origin song: Fresh (Base Game)
        has_origin_song = state.has("Fresh (Base Game)", player)
        # Required items: Special Note, Bonus Track Access
        has_required_items = state.has("Special Note", player) and state.has("Bonus Track Access", player)
        return has_origin_song and has_required_items

    access_rules["Secret Area"] = secret_area_rule

    # Access rule for Ultimate Challenge
    def ultimate_challenge_rule(state, player: int) -> bool:
        # Requires origin song: Dad Battle (Base Game)
        has_origin_song = state.has("Dad Battle (Base Game)", player)
        # Required items: Super Shield, Mega Health Boost
        has_required_items = state.has("Super Shield", player, 2) and state.has("Mega Health Boost", player)
        return has_origin_song and has_required_items

    access_rules["Ultimate Challenge"] = ultimate_challenge_rule

    # Access rule for Modded Location (example with custom mod)
    def modded_location_rule(state, player: int) -> bool:
        # Requires origin song: Expurgation (Tricky Mod)
        has_origin_song = state.has("Expurgation (Tricky Mod)", player)
        # Required items: Custom Power-Up, Super Shield
        has_required_items = state.has("Custom Power-Up", player) and state.has("Super Shield", player)
        return has_origin_song and has_required_items

    access_rules["Modded Location"] = modded_location_rule

    # Access rule for Base Game Location (no mod parentheses)
    def base_game_location_rule(state, player: int) -> bool:
        # Requires origin song: Tutorial (no mod specified)
        has_origin_song = state.has("Tutorial", player)
        # Required items: Special Note
        has_required_items = state.has("Special Note", player)
        return has_origin_song and has_required_items

    access_rules["Base Game Location"] = base_game_location_rule

    return access_rules

# Custom location objects with embedded access rules and metadata
def get_custom_locations() -> Dict[str, Dict[str, Any]]:
    """Returns custom location objects with access rules and metadata combined"""
    # Get the access rules
    access_rules = get_access_rules()
    
    return {
        "Custom Boss Battle": {
            "origin_song": "Bopeebo",
            "origin_mod": "Base Game",
            "access_rule": access_rules["Custom Boss Battle"],  # Rule embedded in location object
        },
        "Secret Area": {
            "origin_song": "Fresh", 
            "origin_mod": "Base Game",
            "access_rule": access_rules["Secret Area"],
        },
        "Ultimate Challenge": {
            "origin_song": "Dad Battle",
            "origin_mod": "Base Game",
            "access_rule": access_rules["Ultimate Challenge"],
        },
        "Modded Location": {
            "origin_song": "Expurgation",
            "origin_mod": "Tricky Mod",
            "access_rule": access_rules["Modded Location"],
        },
        "Base Game Location": {
            "origin_song": "Tutorial",
            "origin_mod": "",  # Empty string = no mod suffix
            "access_rule": access_rules["Base Game Location"],
        },
    }

# Main function to integrate with Archipelago world
# NOTE: This function signature has changed - no longer uses separate access rules
def apply_custom_logic(world_instance):
    """Apply custom items and locations to the world instance"""
    # Get location data (which now includes access rules)
    location_data = get_custom_locations()

    # Store in world instance for use during generation
    if not hasattr(world_instance, 'custom_location_data'):
        world_instance.custom_location_data = {}
    if not hasattr(world_instance, 'custom_items'):
        world_instance.custom_items = []

    # Apply the custom data (no separate access rules needed)
    world_instance.custom_location_data.update(location_data)
    world_instance.custom_items.extend(custom_items)

    return world_instance

# Function to return data for class-level integration
# NOTE: This function now returns combined location objects
def get_custom_data_for_class():
    """Returns custom data for integration during class setup"""
    return {
        'items': custom_items,
        'locations': get_custom_locations()  # Locations now include access rules
    }

# Helper function to create song-based locations
def create_song_location_rule(song_name: str, additional_requirements=None):
    """Create an access rule that requires a specific song plus optional additional requirements"""
    def rule(state, player: int) -> bool:
        has_song = state.has(song_name, player)
        if additional_requirements:
            return has_song and additional_requirements(state, player)
        return has_song
    return rule

# Example of how locations are now handled:
# - Location names have NO player prefixes (e.g., "Custom Boss Battle" not "Alice:Custom Boss Battle")
# - Each player's custom data file defines the same location names
# - The system automatically tracks which players own which locations
# - Custom IDs start after the last song/location IDs to avoid conflicts
# - Access rules are stored directly with the LocationData objects in the 'access_rule' field
# - Files should be named '{playerName}_customFNFData.py' (not _customData.py)
