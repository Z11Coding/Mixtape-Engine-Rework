# Task Priority System - Implementation Summary

## Overview
Successfully re-implemented the task priority system from the old Mixtape Engine (Archipelago branch) into the current engine structure. This feature allows users to set the process priority level for better performance control.

## Files Modified/Created

### 1. **WindowsData.hx** - Added Process Priority Functions
- `setProcessPriorityIdle()` - Sets process to Idle priority
- `setProcessPriorityBelowNormal()` - Sets process to Below Normal priority
- `setProcessPriorityNormal()` - Sets process to Normal priority
- `setProcessPriorityAboveNormal()` - Sets process to Above Normal priority
- `setProcessPriorityHigh()` - Sets process to High priority
- `setProcessPriorityRealtime()` - Sets process to Realtime priority
- `getProcessPriority()` - Gets current process priority level

These functions use Windows API calls (`SetPriorityClass`, `GetPriorityClass`) to control the process priority.

### 2. **Priority.hx** - Main Priority Management Class (NEW)
- `setPriority(priority:Int)` - Set priority using numeric levels (0-5)
- `getPriority()` - Get current priority as number
- `getPriorityString()` - Get priority as human-readable string
- `setPriorityString(priorityString:String)` - Set priority using string names
- `checkForExternalChanges(lastKnownPriority:Int)` - Detect external priority changes
- `resetToNormal()` - Reset to Normal priority

### 3. **ClientPrefs.hx** - Settings Integration
- Added `processPriority:String = 'Normal'` preference
- Automatically applies priority setting on startup in `loadPrefs()`

### 4. **MixtapeSettingsSubState.hx** - Options Menu Integration
- Added Process Priority option in the MISC section
- Dropdown menu with all priority levels
- Changes apply immediately when selected
- Only visible on Windows

### 5. **CppAPI.hx** - API Wrapper Functions
- `setPriority(priority:Int)` - Wrapper for Priority.setPriority
- `getPriority()` - Wrapper for Priority.getPriority
- `getPriorityString()` - Wrapper for Priority.getPriorityString
- `setPriorityString(priorityString:String)` - Wrapper for Priority.setPriorityString
- `resetPriorityToNormal()` - Wrapper for Priority.resetToNormal

### 6. **WindowFunctions.hx** - Lua Script Integration
Added Lua callbacks for script control:
- `setPriority(priority)`
- `getPriority()`
- `getPriorityString()`
- `setPriorityString(priorityString)`
- `resetPriorityToNormal()`

### 7. **Main.hx** - Command Prompt Integration
Added console commands for testing and control:
- `testPriority` - Run basic functionality tests
- `monitorPriority` - Monitor for external changes (10 seconds)
- `setPriority <0-5>` - Set priority using numeric level
- `setPriorityString <name>` - Set priority using string name
- `getPriority` - Display current priority

### 8. **PriorityTest.hx** - Testing Utilities (NEW)
- `runBasicTests()` - Tests all priority functions
- `monitorPriorityChanges()` - Monitors for external changes

## Priority Levels
0. **Idle** - Lowest priority, runs when system is idle
1. **Below Normal** - Lower than normal priority
2. **Normal** - Standard priority (default)
3. **Above Normal** - Higher than normal priority
4. **High** - High priority, gets more CPU time
5. **Realtime** - Highest priority (use with caution!)

## Features
- **Automatic Detection**: Detects when priority is changed externally (Task Manager, etc.)
- **Cross-Platform Safe**: Only available on Windows, gracefully ignored on other platforms
- **Settings Persistence**: Priority preference is saved and restored on restart
- **Multiple Interfaces**: Accessible via options menu, console commands, and Lua scripts
- **Real-time Updates**: Changes take effect immediately
- **Safe Defaults**: Defaults to Normal priority for system stability

## Usage Examples

### Via Options Menu
1. Go to Settings > Mixtape Settings
2. Scroll to MISC section
3. Find "Process Priority" option
4. Select desired priority level
5. Change takes effect immediately

### Via Console Commands
```
getPriority              # Show current priority
setPriority 3           # Set to Above Normal
setPriorityString High  # Set to High priority
testPriority           # Run functionality tests
monitorPriority        # Monitor for external changes
```

### Via Lua Scripts
```lua
setPriority(4)                    -- Set to High priority
print(getPriorityString())        -- Print current priority name
setPriorityString("Above Normal") -- Set using string name
resetPriorityToNormal()          -- Reset to Normal
```

## Implementation Notes
- Windows-only feature using WinAPI functions
- Priority changes are immediate and persistent until changed
- Higher priorities can improve performance but may affect system responsiveness
- Realtime priority should be used with extreme caution as it can freeze the system
- The system automatically monitors for external changes (e.g., via Task Manager)
- All functions include proper error handling and fallbacks

This implementation fully restores the task priority functionality from the old engine while integrating seamlessly with the current engine's architecture.
