# Debug System Documentation

## Overview
The new debug system provides powerful tools for inspecting and editing the state of your game at runtime. It includes both a visual debug overlay and command-line interface.

## Debug Overlay (Ctrl+Alt+D)
Press `Ctrl+Alt+D` in debug builds to toggle the state debug overlay.

### Features:
- **Property Navigation**: Browse through all properties of the current state
- **Real-time Editing**: Modify basic types (bool, int, float, string) instantly
- **Collection Editors**: Special editors for arrays and maps with add/delete/edit functionality
- **Breadcrumb Navigation**: Shows your current path through nested objects
- **Static State Access**: View and modify static properties of all registered state classes
- **JSON Export**: Export current state as JSON file (only available within debug overlay)

### Navigation:
- **Arrow Keys**: Scroll through properties
- **Edit Button**: Modify property values
- **-> Button**: Navigate into complex objects
- **< Back Button**: Return to previous object
- **Static States Button**: Access static properties of registered state classes
- **Export JSON Button**: Export current state as JSON file
- **Escape**: Close the debug overlay
- **Backspace**: Quick back navigation

## Command Line Interface

### Debug Commands:
```
debug                              - Show debug help
debug toggle                       - Toggle debug overlay
debug states                       - List all available state classes
debug static <stateClass>          - View static properties of a state class
debug get <stateClass> <property>  - Get static property value
debug set <stateClass> <property> <value> - Set static property value
```

### State Edit Commands:
```
stateEdit                          - Show state editing help
stateEdit list                     - List all properties of current state
stateEdit get <property>           - Get property value
stateEdit set <property> <value>   - Set property value
stateEdit navigate <property>      - Navigate into complex object
```

### Examples:
```
debug static states.PlayState      - View PlayState static properties
debug set states.PlayState isStoryMode true - Set PlayState.isStoryMode to true
stateEdit list                     - Show all current state properties
stateEdit set curBeat 64           - Set current beat to 64
```

## JSON Export
JSON export is only available within the debug overlay for security reasons. Click the "Export JSON" button in the overlay to save the current state as a timestamped JSON file.

### Export Features:
- **File Export**: Saves to timestamped files on desktop platforms
- **Console Export**: Logs JSON to console on web platforms
- **Visual Feedback**: Shows temporary notifications for export status
- **Error Handling**: Displays error messages if export fails

## New JSON Serialization
The serialization system has been completely rewritten to use JSON instead of Haxe's native serialization:

### Benefits:
- **Human Readable**: JSON output can be inspected and modified in any text editor
- **Cross-Platform**: Works across different Haxe targets
- **Debugging Friendly**: Easy to understand the structure of serialized data
- **Anonymous Structure Support**: Properly handles anonymous objects vs class instances

### SerializedClass Structure:
```json
{
  "CLASS": "StateName",
  "TYPE": "full.package.path.StateName",
  "IS_ANONYMOUS": false,
  "FIELDS": { /* JSON object with all fields */ },
  "QUEUED_OBJECTS": { /* Nested objects */ },
  "METADATA": { /* Serialization statistics */ }
}
```

## Integration
The debug system automatically initializes when:
1. CommandPrompt is created
2. MusicBeatState updates (for key handling)
3. Debug commands are used

The system now uses `yutautil.StatePick` (the same system used by DebugStateMenu) to discover and access state classes, eliminating the need for manual state registration.

No manual initialization is required - just compile with debug flags and use Ctrl+Alt+D or the command interface.

## Performance Notes
- Debug overlays only activate in debug builds
- **Lazy Loading**: The debug overlay is only created when explicitly requested (Ctrl+Alt+D or debug toggle command)
- **Memory Efficient**: Overlay is destroyed when closed to free up memory
- **No Background Processing**: No debug processing occurs when overlay is not active
- JSON serialization is more efficient than the old system
- State inspection uses reflection efficiently only when needed

## Troubleshooting
- **F1 not working**: Ensure you're in a debug build and a MusicBeatState
- **Properties not showing**: Some objects may have no reflectable fields
- **Edit fails**: Some properties may be read-only or have type restrictions
- **JSON export fails**: Very large or circular object graphs may cause issues

## Extension Points
The debug system is designed to be extensible:
- Add new collection editors in `debug/CollectionEditor.hx`
- State classes are automatically discovered via `yutautil.StatePick` macro system
- Add new debug commands in `Main.hx` CommandPrompt.executeCommand()
- Create custom property editors by extending the overlay system
- State registration happens automatically at compile time through the `@:build(yutautil.StatePick.addToDatabase())` macro
