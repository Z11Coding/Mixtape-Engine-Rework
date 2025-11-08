# V-Slice FreeplayState Integration

## Overview
Successfully integrated a V-Slice style FreeplayState into the Mixtape Engine, providing a "Base Game" freeplay option that combines P-Slice/V-Slice features with Mixtape Engine's systems.

## Implementation Details

### Core Features Implemented

#### 1. VSliceFreeplayState Class
- **Location**: `source/states/freeplay/VSliceFreeplayState.hx`
- **Purpose**: V-Slice style freeplay menu with enhanced features
- **Base**: Extended from MusicBeatState with full Mixtape Engine integration

#### 2. Key Features
- **V-Slice Style UI**: Album art display, freeplay cards, enhanced visual design
- **Character Filtering**: Optional character-specific song filtering (toggle with F key)
- **Song Previews**: Automatic song previews when selecting songs
- **Search Functionality**: Real-time song search with FlxUIInputText
- **Archipelago Integration**: Full support for AP mode with automatic detection
- **FreeplayManager Integration**: Uses existing song loading and management systems

#### 3. Settings Integration
- **Character Filtering**: `ClientPrefs.data.vsliceCharacterFiltering` (default: false)
- **Song Previews**: `ClientPrefs.data.freeplaySongPreviews` (default: true)
- **Menu Selection**: Updated "Base Game" option in freeplay menu settings

### Archipelago Mode Support

#### Automatic Detection
- Detects when `APEntryState.inArchipelagoMode` is true
- Switches to `APPlayState` instead of regular `PlayState` when in AP mode
- Shows AP-specific status in bottom info display
- Supports AP check refreshing with R key

#### Integration Points
- Uses existing `APFreeplayManager` for song loading in AP mode
- Maintains compatibility with AP song requirements and restrictions
- Properly handles AP-specific song metadata

### Assets System

#### Directory Structure
```
assets/vslice/
├── images/
│   └── freeplay/
│       ├── freeplayBG.png (background)
│       ├── freeplayCard.png (info card)
│       └── albums/ (individual song album art)
├── sounds/ (V-Slice specific sounds)
├── music/ (freeplay menu music)
└── README.md (asset installation guide)
```

#### Fallback System
- Falls back to `menuDesat` if `freeplayBG` not found
- Creates simple colored rectangles if `freeplayCard` not found
- Uses character icons if album art not available

### FreeplayManager Updates

#### Updated Methods
- `getFreeplay()`: Added "Base Game" case returning `VSliceFreeplayState`
- `getFreeplayState()`: Added support for VSliceFreeplayState class
- `getInstance()`: Added VSliceFreeplayState instance handling
- `getNewFreeplayInstance()`: Added VSlice instance creation
- `reloadFreeplayState()`: Added VSlice reload support

#### APFreeplayManager Updates
- Added "Base Game" case to song reloading switch statement
- Maintains full compatibility with Archipelago mode

### Settings Menu Integration

#### MixtapeSettingsSubState Updates
- Updated freeplay menu description to mention V-Slice features
- Added "V-Slice Character Filtering" option
- Added "Freeplay Song Previews" option
- Proper conditional display based on selected freeplay menu

### Controls and Navigation

#### Standard Controls
- **Arrow Keys**: Navigate songs and difficulties
- **Enter**: Select song and start gameplay
- **Escape**: Return to main menu

#### V-Slice Specific Controls
- **F Key**: Toggle character filtering (cycles through characters or disables)
- **R Key**: Refresh Archipelago checks (AP mode only)
- **Search Bar**: Type to filter songs in real-time

### Visual Features

#### Enhanced UI Elements
- **Album Art Display**: 80x80 album art for each song
- **Freeplay Card**: Information overlay showing song details
- **Gradient Background**: V-Slice style visual design
- **Smooth Animations**: Entrance animations and transitions
- **Score Display**: Personal best scores and ratings
- **Artist/Charter Info**: Display song metadata

#### Character Filtering Display
- Shows current filter in bottom status bar
- Cycles through: bf → dad → gf → pico → mom → senpai → tank → none
- Instant song list refresh when filter changes

## Technical Implementation

### Class Structure
```haxe
class VSliceFreeplayState extends MusicBeatState
{
    // Core state management
    public static var instance:VSliceFreeplayState;

    // UI components
    var grpSongs:FlxTypedGroup<Alphabet>;
    var iconList:FlxTypedGroup<HealthIcon>;
    var albumArt:FlxSprite;
    var freeplayCard:FlxSprite;

    // Character filtering
    var characterFilter:String;
    var enableCharacterFiltering:Bool;

    // Archipelago integration
    var apMode:Bool;
}
```

### Key Methods
- `reloadSongs()`: Loads and filters songs from FreeplayManager
- `changeSelection()`: Handles song navigation with visual updates
- `updateSongInfo()`: Updates score, difficulty, and metadata display
- `updateAlbumArt()`: Loads and displays song-specific album art
- `toggleCharacterFilter()`: Cycles through character filters
- `selectSong()`: Starts gameplay with proper state handling

## Future Enhancements

### Potential Additions
1. **Custom Animations**: More elaborate V-Slice style animations
2. **Extended Album Art**: Support for animated album art
3. **Additional Filters**: Genre, week, or mod-based filtering
4. **Performance Stats**: More detailed performance tracking
5. **Social Features**: Leaderboards and sharing capabilities

### Asset Improvements
1. **P-Slice Asset Port**: Copy actual assets from P-Slice project
2. **Custom V-Slice Assets**: Create unique Mixtape Engine styled assets
3. **Animated Backgrounds**: Moving or interactive backgrounds
4. **Sound Effects**: V-Slice specific menu sounds

## Usage Instructions

### For Users
1. Go to Options → Mixtape Settings
2. Set "Freeplay Menu" to "Base Game"
3. Optionally enable "V-Slice Character Filtering"
4. Navigate to Freeplay to use the new interface

### For Developers
1. Assets go in `assets/vslice/` directory structure
2. Character filtering list can be modified in `toggleCharacterFilter()`
3. Album art naming: `songname.png` in `assets/vslice/images/freeplay/albums/`
4. Extend functionality by modifying `VSliceFreeplayState.hx`

## Compatibility

### Fully Compatible With
- ✅ Archipelago Mode (automatic detection and switching)
- ✅ All existing Mixtape Engine song formats
- ✅ FreeplayManager song loading system
- ✅ Character and icon systems
- ✅ Difficulty system
- ✅ Score tracking and leaderboards
- ✅ Mod loading and custom content

### Tested Scenarios
- ✅ Regular freeplay usage
- ✅ Archipelago mode integration
- ✅ Character filtering functionality
- ✅ Song preview system
- ✅ Asset fallback system
- ✅ Settings integration

This integration successfully brings V-Slice style freeplay functionality to the Mixtape Engine while maintaining full compatibility with all existing systems and adding enhanced features for both regular and Archipelago gameplay.
