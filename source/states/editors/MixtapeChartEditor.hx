package states.editors;

import flixel.FlxG;
import flixel.util.FlxColor;

/**
 * Configuration classes and typedefs for Mixtape Chart Editor
 */

typedef MixtapeChartSettings = {
    autoSaveEnabled: Bool,
    autoSaveInterval: Float,
    gridSize: Int,
    snapToGrid: Bool,
    showWaveform: Bool,
    playMetronome: Bool,
    theme: String,
    keyBindings: Map<String, Int>
}

typedef MixtapeColorScheme = {
    background: FlxColor,
    primary: FlxColor,
    secondary: FlxColor,
    accent: FlxColor,
    text: FlxColor,
    grid: FlxColor,
    gridAlt: FlxColor,
    selection: FlxColor,
    highlight: FlxColor
}

typedef MixtapePanelConfig = {
    x: Float,
    y: Float,
    width: Float,
    height: Float,
    visible: Bool,
    pinned: Bool,
    minimized: Bool
}

typedef MixtapeLayoutConfig = {
    analytics: MixtapePanelConfig,
    toolbox: MixtapePanelConfig,
    timeline: MixtapePanelConfig,
    properties: MixtapePanelConfig,
    events: MixtapePanelConfig
}

typedef MixtapeUndoAction = {
    type: String,
    data: Dynamic,
    timestamp: Float
}

typedef MixtapeChartAnalytics = {
    totalNotes: Int,
    notesPerSecond: Float,
    peakNPS: Float,
    bpmChanges: Int,
    sections: Int,
    difficulty: String,
    balance: Float
}

enum MixtapeEditorTool {
    SELECT;
    PLACE_NOTE;
    PLACE_EVENT;
    ERASE;
    MOVE;
    COPY;
}

enum MixtapeSnapMode {
    QUARTER;
    EIGHTH;
    SIXTEENTH;
    THIRTY_SECOND;
    FREE;
}

enum MixtapeViewMode {
    CHART;
    EVENTS;
    WAVEFORM;
    HYBRID;
}

class MixtapeChartDefaults {
    public static inline var GRID_SIZE:Int = 40;
    public static inline var DEFAULT_BPM:Float = 120;
    public static inline var DEFAULT_SPEED:Float = 1;

    public static var defaultColors:MixtapeColorScheme = {
        background: 0xFF1A1A2E,
        primary: 0xFF6B46C1,
        secondary: 0xFF8B5CF6,
        accent: 0xFFEC4899,
        text: 0xFFE5E7EB,
        grid: 0xFF4C1D95,
        gridAlt: 0xFF6B21A8,
        selection: 0xFFFFD700,
        highlight: 0xFF00FF00
    };

    public static function getDefaultLayout():MixtapeLayoutConfig {
        return {
            analytics: {
                x: FlxG.width - 320,
                y: 80,
                width: 300,
                height: 200,
                visible: true,
                pinned: false,
                minimized: false
            },
            toolbox: {
                x: 20,
                y: 80,
                width: 200,
                height: 400,
                visible: true,
                pinned: true,
                minimized: false
            },
            timeline: {
                x: 240,
                y: FlxG.height - 120,
                width: FlxG.width - 480,
                height: 100,
                visible: true,
                pinned: true,
                minimized: false
            },
            properties: {
                x: FlxG.width - 320,
                y: 300,
                width: 300,
                height: 250,
                visible: false,
                pinned: false,
                minimized: false
            },
            events: {
                x: 20,
                y: 500,
                width: 200,
                height: 200,
                visible: false,
                pinned: false,
                minimized: false
            }
        };
    }
}
