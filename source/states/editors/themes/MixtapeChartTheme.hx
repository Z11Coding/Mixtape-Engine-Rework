package states.editors.themes;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.Json;
import objects.HealthIcon;
import psychlua.LuaUtils;
import states.editors.ChartingState;
import states.editors.themes.CustomizationPanel;
import states.editors.themes.MixtapeIntroAnimation;
import yutautil.save.MixSaveWrapper;

typedef MixtapeLayoutConfig = {
    analyticsPanel: {x: Float, y: Float},
    bpmPanel: {x: Float, y: Float},
    noteDistPanel: {x: Float, y: Float}
}

/**
 * Mixtape Engine's Advanced Chart Editor Theme
 * Features: Animated UI, detailed chart analytics, customizable layouts, and extensive information panels
 */
class MixtapeChartTheme
{
    // Theme constants
    public static inline var THEME_NAME:String = "MIXTAPE";
    public static inline var ANIMATION_DURATION:Float = 0.8;
    public static inline var PANEL_FADE_TIME:Float = 0.3;

    // Color scheme
    public static var primaryColor:FlxColor = 0xFF6B46C1;      // Deep purple
    public static var secondaryColor:FlxColor = 0xFF8B5CF6;    // Light purple
    public static var accentColor:FlxColor = 0xFFEC4899;       // Pink accent
    public static var backgroundGradientTop:FlxColor = 0xFF1E1B4B;    // Dark purple
    public static var backgroundGradientBottom:FlxColor = 0xFF0F0F23;  // Very dark purple
    public static var gridColorMain:FlxColor = 0xFF4C1D95;     // Grid main
    public static var gridColorAlt:FlxColor = 0xFF6B21A8;      // Grid alternate
    public static var textColor:FlxColor = 0xFFE5E7EB;         // Light gray text
    public static var panelBg:FlxColor = 0xFF1F2937;           // Panel background

    // Layout configuration
    public var layoutConfig:MixtapeLayoutConfig;
    public var saveWrapper:MixSaveWrapper;

    // UI Elements
    public var animatedBackground:FlxSprite;
    public var chartAnalyticsPanel:ChartAnalyticsPanel;
    public var bpmVisualizerPanel:BPMVisualizerPanel;
    public var noteDistributionPanel:NoteDistributionPanel;
    public var customizationPanel:CustomizationPanel;
    public var introAnimation:MixtapeIntroAnimation;

    // State references
    public var chartingState:ChartingState;
    public var isInitialized:Bool = false;
    public var panels:FlxGroup;

    public function new(chartingState:ChartingState)
    {
        this.chartingState = chartingState;

        // Initialize save system for layout
        saveWrapper = new MixSaveWrapper(null, "save/mixtape_chart_layout.json");
        loadLayoutConfig();

        panels = new FlxGroup();

        setupTheme();
    }

    function loadLayoutConfig():Void
    {
        var savedConfig = saveWrapper.getItem("layoutConfig");
        if (savedConfig != null)
        {
            layoutConfig = savedConfig;
        }
        else
        {
            // Default layout configuration
            layoutConfig = {
                analyticsPanel: {x: FlxG.width - 320, y: 80, width: 300, height: 200, visible: true},
                bpmPanel: {x: FlxG.width - 320, y: 300, width: 300, height: 150, visible: true},
                noteDistPanel: {x: FlxG.width - 320, y: 470, width: 300, height: 180, visible: true},
                customPanel: {x: 20, y: FlxG.height - 200, width: 250, height: 180, visible: false}
            };
        }
    }

    public function saveLayoutConfig():Void
    {
        saveWrapper.addItem("layoutConfig", layoutConfig);
        saveWrapper.save();
    }

    function setupTheme():Void
    {
        createAnimatedBackground();
        createPanels();
        setupGridColors();
    }

    function createAnimatedBackground():Void
    {
        // Create animated gradient background with floating particles
        animatedBackground = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [backgroundGradientTop, backgroundGradientBottom], 1, 45);

        // Add subtle animation to background
        FlxTween.tween(animatedBackground, {alpha: 0.8}, 2.0, {
            ease: FlxEase.sineInOut,
            type: PINGPONG
        });
    }

    function createPanels():Void
    {
        // Chart Analytics Panel
        chartAnalyticsPanel = new ChartAnalyticsPanel(
            layoutConfig.analyticsPanel.x,
            layoutConfig.analyticsPanel.y,
            layoutConfig.analyticsPanel.width,
            layoutConfig.analyticsPanel.height,
            this
        );
        chartAnalyticsPanel.visible = layoutConfig.analyticsPanel.visible;
        panels.add(chartAnalyticsPanel);

        // BPM Visualizer Panel
        bpmVisualizerPanel = new BPMVisualizerPanel(
            layoutConfig.bpmPanel.x,
            layoutConfig.bpmPanel.y,
            layoutConfig.bpmPanel.width,
            layoutConfig.bpmPanel.height,
            this
        );
        bpmVisualizerPanel.visible = layoutConfig.bpmPanel.visible;
        panels.add(bpmVisualizerPanel);

        // Note Distribution Panel
        noteDistributionPanel = new NoteDistributionPanel(
            layoutConfig.noteDistPanel.x,
            layoutConfig.noteDistPanel.y,
            layoutConfig.noteDistPanel.width,
            layoutConfig.noteDistPanel.height,
            this
        );
        noteDistributionPanel.visible = layoutConfig.noteDistPanel.visible;
        panels.add(noteDistributionPanel);

        // Customization Panel (initially hidden)
        customizationPanel = new CustomizationPanel(
            layoutConfig.customPanel.x,
            layoutConfig.customPanel.y,
            layoutConfig.customPanel.width,
            layoutConfig.customPanel.height,
            this
        );
        customizationPanel.visible = layoutConfig.customPanel.visible;
        panels.add(customizationPanel);

        // Make panels draggable
        makePanelsDraggable();
    }

    function makePanelsDraggable():Void
    {
        for (panel in panels.members)
        {
            if (Std.isOfType(panel, MixtapeThemePanel))
            {
                var mixtapePanel:MixtapeThemePanel = cast panel;
                mixtapePanel.makeDraggable();
            }
        }
    }

    function setupGridColors():Void
    {
        chartingState.gridColors = [gridColorMain, gridColorAlt];
        chartingState.gridColorsOther = [
            FlxColor.fromRGB(
                Std.int(gridColorMain.red * 0.7),
                Std.int(gridColorMain.green * 0.7),
                Std.int(gridColorMain.blue * 0.7)
            ),
            FlxColor.multiply(gridColorAlt, 0.7)
        ];
    }

    public function playIntroAnimation():Void
    {
        if (introAnimation != null)
        {
            introAnimation.destroy();
        }

        introAnimation = new MixtapeIntroAnimation(this);
        chartingState.add(introAnimation);
        introAnimation.play();
    }

    public function update(elapsed:Float):Void
    {
        if (!isInitialized) return;

        // Update panels
        for (panel in panels.members)
        {
            if (Std.isOfType(panel, MixtapeThemePanel))
            {
                var mixtapePanel:MixtapeThemePanel = cast panel;
                mixtapePanel.updatePanel(elapsed);
            }
        }

        // Update analytics in real-time
        updateAnalytics();
    }

    function updateAnalytics():Void
    {
        if (chartAnalyticsPanel != null && chartAnalyticsPanel.visible)
        {
            chartAnalyticsPanel.refreshData();
        }

        if (bpmVisualizerPanel != null && bpmVisualizerPanel.visible)
        {
            bpmVisualizerPanel.refreshData();
        }

        if (noteDistributionPanel != null && noteDistributionPanel.visible)
        {
            noteDistributionPanel.refreshData();
        }
    }

    public function togglePanel(panelType:String):Void
    {
        switch (panelType.toLowerCase())
        {
            case "analytics":
                chartAnalyticsPanel.visible = !chartAnalyticsPanel.visible;
                layoutConfig.analyticsPanel.visible = chartAnalyticsPanel.visible;

            case "bpm":
                bpmVisualizerPanel.visible = !bpmVisualizerPanel.visible;
                layoutConfig.bpmPanel.visible = bpmVisualizerPanel.visible;

            case "distribution":
                noteDistributionPanel.visible = !noteDistributionPanel.visible;
                layoutConfig.noteDistPanel.visible = noteDistributionPanel.visible;

            case "customization":
                customizationPanel.visible = !customizationPanel.visible;
                layoutConfig.customPanel.visible = customizationPanel.visible;
        }

        saveLayoutConfig();
    }

    public function resetLayout():Void
    {
        loadLayoutConfig();

        chartAnalyticsPanel.setPosition(layoutConfig.analyticsPanel.x, layoutConfig.analyticsPanel.y);
        bpmVisualizerPanel.setPosition(layoutConfig.bpmPanel.x, layoutConfig.bpmPanel.y);
        noteDistributionPanel.setPosition(layoutConfig.noteDistPanel.x, layoutConfig.noteDistPanel.y);
        customizationPanel.setPosition(layoutConfig.customPanel.x, layoutConfig.customPanel.y);
    }

    public function destroy():Void
    {
        saveLayoutConfig();

        if (animatedBackground != null)
        {
            animatedBackground.destroy();
            animatedBackground = null;
        }

        if (panels != null)
        {
            panels.destroy();
            panels = null;
        }

        if (introAnimation != null)
        {
            introAnimation.destroy();
            introAnimation = null;
        }
    }
}

typedef MixtapeThemeLayoutConfig = {
    analyticsPanel: PanelConfig,
    bpmPanel: PanelConfig,
    noteDistPanel: PanelConfig,
    customPanel: PanelConfig
}

typedef PanelConfig = {
    x: Float,
    y: Float,
    width: Float,
    height: Float,
    visible: Bool
}
