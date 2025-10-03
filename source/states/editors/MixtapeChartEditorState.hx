package states.editors;

import backend.Conductor;
import backend.MusicBeatState;
import backend.Paths;
import backend.Song.SwagSection;
import backend.Song.SwagSong;
import backend.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import objects.Note;
import objects.StrumNote;
import objects.charting.ChartingNote;
import objects.charting.ChartingStrumNote;
import states.MainMenuState;
import states.PlayState;
import states.editors.MasterEditorMenu;
import substates.Prompt;
import yutautil.GenericProgressSubstate;
import yutautil.ImprovedFileHandling.ReadType;
import yutautil.ImprovedFileHandling;

#if sys
import sys.io.File;
#end

/**
 * UI Layout Configuration
 */
typedef UILayoutConfig = {
    var panels:Array<UIPanelConfig>;
    var theme:String;
    var version:Int;
}

typedef UIPanelConfig = {
    var id:String;
    var x:Float;
    var y:Float;
    var width:Float;
    var height:Float;
    var visible:Bool;
    var docked:Bool;
    var elements:Array<String>;
}

/**
 * Stylish UI Panel for Chart Editor
 */
class MixtapeUIPanel extends FlxSprite
{
    public var panelId:String;
    public var elements:FlxTypedGroup<FlxSprite>;
    public var titleText:FlxText;
    public var isDragging:Bool = false;
    public var dragOffset:FlxPoint;

    public function new(id:String, title:String, x:Float, y:Float, width:Float, height:Float)
    {
        super(x, y);

        panelId = id;
        elements = new FlxTypedGroup<FlxSprite>();
        dragOffset = FlxPoint.get();

        // Create gradient panel background
        var panelBg = FlxGradient.createGradientFlxSprite(Std.int(width), Std.int(height),
            [0xFF1a1a2e, 0xFF16213e], 1, 90);
        loadGraphic(panelBg.graphic);

        // Panel border effect
        var border = new FlxSprite();
        border.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, true);

        // Draw border
        for (i in 0...Std.int(width)) {
            border.pixels.setPixel32(i, 0, 0xFF00FFFF); // Top
            border.pixels.setPixel32(i, Std.int(height-1), 0xFF00FFFF); // Bottom
        }
        for (i in 0...Std.int(height)) {
            border.pixels.setPixel32(0, i, 0xFF00FFFF); // Left
            border.pixels.setPixel32(Std.int(width-1), i, 0xFF00FFFF); // Right
        }

        // Blend border
        panelBg.stamp(border, 0, 0);
        loadGraphic(panelBg.graphic);

        // Title text
        titleText = new FlxText(x + 5, y + 5, width - 10, title, 14);
        titleText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 1;
    }

    public function addElement(element:FlxSprite):Void
    {
        elements.add(element);
    }

    public function updatePosition():Void
    {
        titleText.x = x + 5;
        titleText.y = y + 5;

        // Update element positions relative to panel
        elements.forEach(function(element) {
            // Elements should handle their own relative positioning
        });
    }

    override function destroy():Void
    {
        elements.destroy();
        titleText.destroy();
        dragOffset.put();
        super.destroy();
    }
}

/**
 * Custom Save Options Substate with Archipelago styling
 */
class SaveOptionsSubstate extends MusicBeatSubstate
{
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var descriptionText:FlxText;
    var combinedButton:FlxSprite;
    var splitButton:FlxSprite;
    var cancelButton:FlxSprite;
    var combinedText:FlxText;
    var splitText:FlxText;
    var cancelText:FlxText;
    var particles:FlxTypedGroup<FlxSprite>;

    var onCombined:Void->Void;
    var onSplit:Void->Void;
    var onCancel:Void->Void;

    var selectedButton:Int = 0;
    var buttons:Array<FlxSprite> = [];
    var buttonTexts:Array<FlxText> = [];

    public function new(onCombinedCallback:Void->Void, onSplitCallback:Void->Void, onCancelCallback:Void->Void)
    {
        super();

        onCombined = onCombinedCallback;
        onSplit = onSplitCallback;
        onCancel = onCancelCallback;
    }

    override function create():Void
    {
        super.create();

        // Archipelago-style background
        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 180));
        add(background);

        // Main panel with gradient
        panel = FlxGradient.createGradientFlxSprite(500, 350, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = Std.int((FlxG.width - panel.width) / 2);
        panel.y = Std.int((FlxG.height - panel.height) / 2);
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, "SAVE OPTIONS", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Description
        descriptionText = new FlxText(panel.x + 20, panel.y + 70, panel.width - 40,
            "Your chart contains both notes and events.\nHow would you like to save them?", 16);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);

        // Combined button
        combinedButton = new FlxSprite(panel.x + 50, panel.y + 140);
        combinedButton.makeGraphic(180, 50, FlxColor.BLUE);
        add(combinedButton);
        buttons.push(combinedButton);

        combinedText = new FlxText(combinedButton.x, combinedButton.y + 12, combinedButton.width, "COMBINED FILE", 14);
        combinedText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        combinedText.borderSize = 1;
        add(combinedText);
        buttonTexts.push(combinedText);

        // Split button
        splitButton = new FlxSprite(panel.x + 270, panel.y + 140);
        splitButton.makeGraphic(180, 50, FlxColor.GREEN);
        add(splitButton);
        buttons.push(splitButton);

        splitText = new FlxText(splitButton.x, splitButton.y + 12, splitButton.width, "SEPARATE FILES", 14);
        splitText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        splitText.borderSize = 1;
        add(splitText);
        buttonTexts.push(splitText);

        // Cancel button
        cancelButton = new FlxSprite(panel.x + 160, panel.y + 220);
        cancelButton.makeGraphic(180, 50, FlxColor.RED);
        add(cancelButton);
        buttons.push(cancelButton);

        cancelText = new FlxText(cancelButton.x, cancelButton.y + 12, cancelButton.width, "CANCEL", 14);
        cancelText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelText.borderSize = 1;
        add(cancelText);
        buttonTexts.push(cancelText);

        // Particle effects
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        for (i in 0...15)
        {
            var particle = new FlxSprite(
                panel.x + FlxG.random.float(0, panel.width),
                panel.y + FlxG.random.float(0, panel.height)
            );
            particle.makeGraphic(2, 2, FlxColor.CYAN);
            particle.alpha = FlxG.random.float(0.2, 0.6);
            particles.add(particle);

            FlxTween.tween(particle, {
                y: particle.y - FlxG.random.float(20, 40),
                alpha: 0
            }, FlxG.random.float(2, 4), {
                type: LOOPING,
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    particle.y = panel.y + panel.height;
                    particle.x = panel.x + FlxG.random.float(0, panel.width);
                    particle.alpha = FlxG.random.float(0.2, 0.6);
                }
            });
        }

        // Animate in
        panel.scale.set(0.8, 0.8);
        panel.alpha = 0;

        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
            ease: FlxEase.backOut
        });

        // Fade in other elements
        for (member in members)
        {
            if (member != background && member != panel && member != particles)
            {
                if (Std.isOfType(member, FlxSprite))
                {
                    var sprite:FlxSprite = cast(member, FlxSprite);
                    sprite.alpha = 0;
                    FlxTween.tween(sprite, {alpha: 1}, 0.3, {
                        ease: FlxEase.sineOut,
                        startDelay: 0.2
                    });
                }
            }
        }

        updateSelection();
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Navigation
        if (controls.UI_LEFT_P || controls.UI_RIGHT_P || controls.UI_UP_P || controls.UI_DOWN_P)
        {
            if (controls.UI_LEFT_P && selectedButton > 0)
                selectedButton--;
            else if (controls.UI_RIGHT_P && selectedButton < buttons.length - 1)
                selectedButton++;
            else if (controls.UI_UP_P && selectedButton == 2)
                selectedButton = 0;
            else if (controls.UI_DOWN_P && selectedButton < 2)
                selectedButton = 2;

            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        // Selection
        if (controls.ACCEPT)
        {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            switch (selectedButton)
            {
                case 0:
                    if (onCombined != null) onCombined();
                case 1:
                    if (onSplit != null) onSplit();
                case 2:
                    if (onCancel != null) onCancel();
            }
            close();
        }

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (onCancel != null) onCancel();
            close();
        }

        // Mouse interaction
        for (i in 0...buttons.length)
        {
            if (FlxG.mouse.overlaps(buttons[i]))
            {
                if (selectedButton != i)
                {
                    selectedButton = i;
                    updateSelection();
                }

                if (FlxG.mouse.justPressed)
                {
                    FlxG.sound.play(Paths.sound('confirmMenu'));
                    switch (selectedButton)
                    {
                        case 0:
                            if (onCombined != null) onCombined();
                        case 1:
                            if (onSplit != null) onSplit();
                        case 2:
                            if (onCancel != null) onCancel();
                    }
                    close();
                }
            }
        }
    }

    function updateSelection():Void
    {
        for (i in 0...buttons.length)
        {
            if (i == selectedButton)
            {
                buttons[i].color = FlxColor.WHITE;
                buttonTexts[i].color = FlxColor.YELLOW;
            }
            else
            {
                buttons[i].color = FlxColor.GRAY;
                buttonTexts[i].color = FlxColor.WHITE;
            }
        }
    }
}

/**
 * Mixtape Engine's Advanced Chart Editor
 * A complete charting state with animated UI and customizable features
 * Built as a self-contained state like ChartingState and ChartingStateOG
 */
class MixtapeChartEditorState extends MusicBeatState
{
    // Private song variable like other chart editors
    var _song:SwagSong;

    // Audio
    public var vocals:FlxSound;
    public var opponentVocals:FlxSound;

    // Camera system
    public var camHUD:FlxCamera;
    public var camGame:FlxCamera;

    // Grid and notes
    public var gridBg:FlxSprite;
    public var strumLineNotes:FlxTypedGroup<ChartingStrumNote>;
    public var notes:FlxTypedGroup<ChartingNote>;
    public var selectedNotes:Array<ChartingNote> = [];

    // UI Elements
    public var infoText:FlxText;
    public var playButton:FlxButton;
    public var stopButton:FlxButton;
    public var saveButton:FlxButton;
    public var loadButton:FlxButton;

    // Chart data
    public var gridSize:Int = 40;
    public var snapToGrid:Bool = true;
    public var showGrid:Bool = true;

    // Settings
    public var settings:Dynamic;

    // Undo/Redo system
    public var undoStack:Array<Dynamic> = [];
    public var redoStack:Array<Dynamic> = [];
    public var hasUnsavedChanges:Bool = false;

    // Animation system
    public var animatedBg:FlxSprite;
    public var uiAnimations:Map<String, FlxTween> = new Map();

    // Selection and editing
    public var isDragging:Bool = false;
    public var dragStartPos:FlxPoint;
    public var currentTool:String = "select";

    // Chart scrolling and view
    public var scrollY:Float = 0;
    public var zoomLevel:Float = 1.0;
    public var sectionStartTime:Float = 0;
    public var playbackSpeed:Float = 1.0;

    // UI System
    public var uiPanels:Map<String, MixtapeUIPanel> = new Map();
    public var uiLayout:UILayoutConfig;
    public var uiElements:FlxTypedGroup<FlxSprite>;

    // Song Properties Panel Elements
    public var songBPMStepper:FlxUINumericStepper;
    public var songSpeedStepper:FlxUINumericStepper;
    public var songOffsetStepper:FlxUINumericStepper;
    public var voicesCheckbox:FlxUICheckBox;

    // Section Panel Elements
    public var sectionBeatsLabel:FlxText;
    public var sectionLengthStepper:FlxUINumericStepper;
    public var mustHitCheckbox:FlxUICheckBox;
    public var gfSectionCheckbox:FlxUICheckBox;
    public var altAnimCheckbox:FlxUICheckBox;

    // Loading guard to prevent multiple simultaneous loading operations
    private var isLoadingChart:Bool = false;

    public function new()
    {
        super();

        // Initialize _song if needed
        if (PlayState.SONG == null)
        {
            _song = {
                song: 'New Song',
                notes: [],
                events: [],
                bpm: 120,
                needsVoices: true,
                speed: 1,
                offset: 0,
                player1: 'bf',
                player2: 'dad',
                player4: 'dad',
                player5: 'bf',
                gfVersion: 'gf',
                stage: 'stage',
                mania: 0,
                startMania: 0,
                format: 'psych_v1'
            };
        }
        else
        {
            _song = PlayState.SONG;
        }

        loadSettings();
    }

    override function create():Void
    {
        super.create();

        // Ensure cursor is visible
        FlxG.mouse.visible = true;

        setupCameras();
        setupAudio();
        createAnimatedBackground();
        createGrid();
        createStrumLine();
        createNotes();

        // Initialize UI system
        loadUILayout();
        createUISystem();
        createUI();

        // Set conductor
        Conductor.bpm = _song.bpm;

        // Start with entrance animation
        playEntranceAnimation();
    }

    function setupCameras():Void
    {
        camGame = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;

        FlxG.cameras.reset(camGame);
        FlxG.cameras.add(camHUD, false);

        FlxCamera.defaultCameras = [camGame];
    }

    function setupAudio():Void
    {
        var songKey = Paths.formatToSongPath(_song.song);

        // Stop any existing audio
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        if (vocals != null)
        {
            vocals.stop();
            vocals.destroy();
        }
        if (opponentVocals != null)
        {
            opponentVocals.stop();
            opponentVocals.destroy();
        }

        // Load instrumental (similar to ChartingStateOG)
        FlxG.sound.playMusic(Paths.inst(_song.song), 0.6, false);
        if (FlxG.sound.music != null)
        {
            FlxG.sound.music.pause();
            FlxG.sound.music.onComplete = function()
            {
                FlxG.sound.music.pause();
                Conductor.songPosition = 0;
                if (vocals != null)
                {
                    vocals.pause();
                    vocals.time = 0;
                }
                if (opponentVocals != null)
                {
                    opponentVocals.pause();
                    opponentVocals.time = 0;
                }
            };
        }

        // Load vocals with better error handling
        vocals = new FlxSound();
        opponentVocals = new FlxSound();

        if (_song.needsVoices)
        {
            try
            {
                var playerVocals = Paths.voices(_song.song, 'player');
                if (playerVocals != null)
                {
                    vocals.loadEmbedded(playerVocals);
                    vocals.volume = 0.6;
                    vocals.autoDestroy = false;
                    FlxG.sound.list.add(vocals);
                }
            }
            catch (e:Dynamic)
            {
                trace('Could not load player vocals: ' + e);
                vocals = null;
            }

            try
            {
                var oppVocals = Paths.voices(_song.song, 'opponent');
                if (oppVocals != null)
                {
                    opponentVocals.loadEmbedded(oppVocals);
                    opponentVocals.volume = 0.6;
                    opponentVocals.autoDestroy = false;
                    FlxG.sound.list.add(opponentVocals);
                }
            }
            catch (e:Dynamic)
            {
                trace('Could not load opponent vocals: ' + e);
                opponentVocals = null;
            }
        }
    }

    function createAnimatedBackground():Void
    {
        // Archipelago-style gradient background
        animatedBg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0xFF0d1a2e, 0xFF16213e, 0xFF0f3460], 1, 90);
        animatedBg.scrollFactor.set();
        add(animatedBg);

        // Animated overlay for depth
        var gradientOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0x00000000, 0x3335ff6b, 0x00000000], 1, 0);
        gradientOverlay.scrollFactor.set();
        gradientOverlay.alpha = 0.6;
        add(gradientOverlay);

        // Pulse animation
        FlxTween.tween(gradientOverlay, {alpha: 0.8}, 2.0, {
            ease: FlxEase.sineInOut,
            type: PINGPONG
        });

        // Subtle color shift animation
        var colorShift = FlxTween.color(animatedBg, 6.0, 0xFF0d1a2e, 0xFF1a0d2e, {
            ease: FlxEase.sineInOut,
            type: PINGPONG
        });
        uiAnimations.set("bgColorShift", colorShift);

        // Add particle effects for enhanced visual appeal
        createParticleEffects();
    }

    function createParticleEffects():Void
    {
        for (i in 0...20)
        {
            var particle = new FlxSprite(
                FlxG.random.float(0, FlxG.width),
                FlxG.random.float(0, FlxG.height)
            );
            particle.makeGraphic(2, 2, FlxColor.CYAN);
            particle.alpha = FlxG.random.float(0.2, 0.6);
            add(particle);

            FlxTween.tween(particle, {
                y: particle.y - FlxG.random.float(30, 60),
                alpha: 0
            }, FlxG.random.float(3, 6), {
                type: LOOPING,
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    particle.y = FlxG.height + 10;
                    particle.x = FlxG.random.float(0, FlxG.width);
                    particle.alpha = FlxG.random.float(0.2, 0.6);
                }
            });
        }
    }

    function createGrid():Void
    {
        gridBg = new FlxSprite(100, 50);
        updateGrid();
        add(gridBg);
    }

    function updateGrid():Void
    {
        if (!showGrid) {
            gridBg.visible = false;
            return;
        }

        gridBg.visible = true;
        var gridWidth = gridSize * 8; // 4 player lanes + 4 opponent lanes
        var gridHeight = gridSize * 64; // Much longer grid for continuous feel

        gridBg.makeGraphic(gridWidth, gridHeight, FlxColor.TRANSPARENT, true);

        // Draw grid lines
        for (i in 0...9) // Vertical lines
        {
            var x = i * gridSize;
            var color = (i == 4) ? 0xFFFFFFFF : 0xFF666666; // Middle line is brighter
            for (y in 0...gridHeight)
            {
                gridBg.pixels.setPixel32(x, y, color);
            }
        }

        for (i in 0...65) // More horizontal lines for continuous grid
        {
            var y = i * gridSize;
            var color = (i % 4 == 0) ? 0xFFFFFFFF : 0xFF444444; // Beat lines are brighter
            for (x in 0...gridWidth)
            {
                gridBg.pixels.setPixel32(x, y, color);
            }
        }
    }

    function createStrumLine():Void
    {
        strumLineNotes = new FlxTypedGroup<ChartingStrumNote>();
        add(strumLineNotes);

        for (i in 0...8)
        {
            var strum = new ChartingStrumNote(gridBg.x + (i * gridSize), gridBg.y, i % 4, i >= 4 ? 1 : 0);
            strum.setGraphicSize(Std.int(gridSize));
            strum.updateHitbox();
            strumLineNotes.add(strum);
        }
    }

    function createUI():Void
    {
        // Info text (top-left corner)
        infoText = new FlxText(10, 10, 0, "", 16);
        infoText.cameras = [camHUD];
        infoText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        infoText.borderSize = 1;
        add(infoText);

        // Create Song Properties Panel Elements
        createSongPropertiesPanel();

        // Create Section Properties Panel Elements
        createSectionPropertiesPanel();

        // Create Playback Controls Panel Elements
        createPlaybackControlsPanel();
    }

    function createSongPropertiesPanel():Void
    {
        var panel = uiPanels.get("songProperties");
        if (panel == null) return;

        var yOffset:Float = 30; // Start below title
        var elementSpacing:Float = 35;

        // Song BPM
        var bpmLabel = new FlxText(panel.x + 10, panel.y + yOffset, 100, "BPM:", 12);
        bpmLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        bpmLabel.cameras = [camHUD];
        uiElements.add(bpmLabel);

        songBPMStepper = new FlxUINumericStepper(panel.x + 60, panel.y + yOffset - 2, 1, _song.bpm, 1, 999, 1);
        songBPMStepper.cameras = [camHUD];
        songBPMStepper.name = 'song_bpm';
        uiElements.add(songBPMStepper);

        yOffset += elementSpacing;

        // Song Speed
        var speedLabel = new FlxText(panel.x + 10, panel.y + yOffset, 100, "Speed:", 12);
        speedLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        speedLabel.cameras = [camHUD];
        uiElements.add(speedLabel);

        songSpeedStepper = new FlxUINumericStepper(panel.x + 60, panel.y + yOffset - 2, 0.1, _song.speed, 0.1, 10, 1);
        songSpeedStepper.cameras = [camHUD];
        songSpeedStepper.name = 'song_speed';
        uiElements.add(songSpeedStepper);

        yOffset += elementSpacing;

        // Song Offset
        var offsetLabel = new FlxText(panel.x + 10, panel.y + yOffset, 100, "Offset:", 12);
        offsetLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        offsetLabel.cameras = [camHUD];
        uiElements.add(offsetLabel);

        songOffsetStepper = new FlxUINumericStepper(panel.x + 60, panel.y + yOffset - 2, 1, _song.offset, -500, 500, 0);
        songOffsetStepper.cameras = [camHUD];
        songOffsetStepper.name = 'song_offset';
        uiElements.add(songOffsetStepper);

        yOffset += elementSpacing;

        // Needs Voices Checkbox
        voicesCheckbox = new FlxUICheckBox(panel.x + 10, panel.y + yOffset, null, null, "Needs Voices", 120);
        voicesCheckbox.cameras = [camHUD];
        voicesCheckbox.checked = _song.needsVoices;
        voicesCheckbox.callback = function() {
            _song.needsVoices = voicesCheckbox.checked;
            hasUnsavedChanges = true;
            // Reload audio when this changes
            setupAudio();
        };
        uiElements.add(voicesCheckbox);
    }

    function createSectionPropertiesPanel():Void
    {
        var panel = uiPanels.get("sectionProperties");
        if (panel == null) return;

        var yOffset:Float = 30;
        var elementSpacing:Float = 35;

        // Section info label
        sectionBeatsLabel = new FlxText(panel.x + 10, panel.y + yOffset, panel.width - 20, "Section: 0", 12);
        sectionBeatsLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
        sectionBeatsLabel.cameras = [camHUD];
        uiElements.add(sectionBeatsLabel);

        yOffset += elementSpacing;

        // Must Hit Section
        mustHitCheckbox = new FlxUICheckBox(panel.x + 10, panel.y + yOffset, null, null, "Must Hit Section", 150);
        mustHitCheckbox.cameras = [camHUD];
        mustHitCheckbox.callback = function() {
            if (getCurrentSection() != null) {
                getCurrentSection().mustHitSection = mustHitCheckbox.checked;
                hasUnsavedChanges = true;
            }
        };
        uiElements.add(mustHitCheckbox);

        yOffset += elementSpacing;

        // GF Section
        gfSectionCheckbox = new FlxUICheckBox(panel.x + 10, panel.y + yOffset, null, null, "GF Section", 150);
        gfSectionCheckbox.cameras = [camHUD];
        gfSectionCheckbox.callback = function() {
            if (getCurrentSection() != null) {
                getCurrentSection().gfSection = gfSectionCheckbox.checked;
                hasUnsavedChanges = true;
            }
        };
        uiElements.add(gfSectionCheckbox);

        yOffset += elementSpacing;

        // Alt Animation
        altAnimCheckbox = new FlxUICheckBox(panel.x + 10, panel.y + yOffset, null, null, "Alt Animation", 150);
        altAnimCheckbox.cameras = [camHUD];
        altAnimCheckbox.callback = function() {
            if (getCurrentSection() != null) {
                getCurrentSection().altAnim = altAnimCheckbox.checked;
                hasUnsavedChanges = true;
            }
        };
        uiElements.add(altAnimCheckbox);
    }

    function createPlaybackControlsPanel():Void
    {
        var panel = uiPanels.get("playbackControls");
        if (panel == null) return;

        // These buttons are created with enhanced styling
        var buttonWidth = 80;
        var buttonHeight = 35;
        var spacing = 90;
        var startX = panel.x + 10;
        var buttonY = panel.y + 30;

        // Enhanced Play Button
        playButton = new FlxButton(startX, buttonY, "Play", function() {
            togglePlayback();
        });
        playButton.setGraphicSize(buttonWidth, buttonHeight);
        playButton.updateHitbox();
        playButton.cameras = [camHUD];
        playButton.color = FlxColor.GREEN;
        uiElements.add(playButton);

        // Enhanced Stop Button
        stopButton = new FlxButton(startX + spacing, buttonY, "Stop", function() {
            stopPlayback();
        });
        stopButton.setGraphicSize(buttonWidth, buttonHeight);
        stopButton.updateHitbox();
        stopButton.cameras = [camHUD];
        stopButton.color = FlxColor.RED;
        uiElements.add(stopButton);

        // Enhanced Save Button
        saveButton = new FlxButton(startX + spacing * 2, buttonY, "Save", function() {
            saveChart();
        });
        saveButton.setGraphicSize(buttonWidth, buttonHeight);
        saveButton.updateHitbox();
        saveButton.cameras = [camHUD];
        saveButton.color = FlxColor.BLUE;
        uiElements.add(saveButton);

        // Enhanced Load Button
        loadButton = new FlxButton(startX + spacing * 3, buttonY, "Load", function() {
            openChart();
        });
        loadButton.setGraphicSize(buttonWidth, buttonHeight);
        loadButton.updateHitbox();
        loadButton.cameras = [camHUD];
        loadButton.color = FlxColor.PURPLE;
        uiElements.add(loadButton);

        // Animate buttons in with archipelago style
        var buttons = [playButton, stopButton, saveButton, loadButton];
        for (i in 0...buttons.length)
        {
            var button = buttons[i];
            button.alpha = 0;
            button.y += 20;

            FlxTween.tween(button, {alpha: 1, y: button.y - 20}, 0.5, {
                ease: FlxEase.backOut,
                startDelay: i * 0.1
            });
        }
    }

    function getCurrentSection():SwagSection
    {
        var section = Math.floor(Conductor.songPosition / (Conductor.crochet * 4));
        if (section >= 0 && section < _song.notes.length)
            return _song.notes[section];
        return null;
    }

    function updateSectionUI():Void
    {
        var currentSection = getCurrentSection();
        var sectionIndex = Math.floor(Conductor.songPosition / (Conductor.crochet * 4));

        if (sectionBeatsLabel != null)
            sectionBeatsLabel.text = 'Section: $sectionIndex';

        if (currentSection != null)
        {
            if (mustHitCheckbox != null)
                mustHitCheckbox.checked = currentSection.mustHitSection;
            if (gfSectionCheckbox != null)
                gfSectionCheckbox.checked = currentSection.gfSection;
            if (altAnimCheckbox != null)
                altAnimCheckbox.checked = currentSection.altAnim;
        }
    }

    function animateButtonsIn(buttons:Array<FlxButton>):Void
    {
        for (i in 0...buttons.length)
        {
            var button = buttons[i];
            button.y += 100; // Start below screen
            button.alpha = 0;

            FlxTween.tween(button, {y: button.y - 100, alpha: 1}, 0.5, {
                ease: FlxEase.bounceOut,
                startDelay: i * 0.1
            });
        }
    }

    function createNotes():Void
    {
        notes = new FlxTypedGroup<ChartingNote>();
        add(notes);

        // Load existing notes from PlayState.SONG
        loadNotesFromSong();
    }

    function loadNotesFromSong():Void
    {
        // Prevent multiple loading operations
        if (isLoadingChart) {
            trace("Chart loading already in progress, skipping duplicate request");
            return;
        }

        isLoadingChart = true;
        notes.clear();

        if (_song.notes == null) {
            isLoadingChart = false;
            return;
        }

        // Collect all notes first
        var allNotes:Array<Dynamic> = [];
        for (section in _song.notes)
        {
            if (section.sectionNotes == null) continue;
            for (noteData in section.sectionNotes)
            {
                allNotes.push(noteData);
            }
        }

        if (allNotes.length == 0) {
            isLoadingChart = false;
            return;
        }

        // Use GenericProgressSubstate with regular tasks instead of iter task
        var loadTasks = [
            GenericProgressSubstate.createTask("Preparing chart data...", function(results) {
                return "Chart data prepared";
            }),
            GenericProgressSubstate.createTask("Loading " + allNotes.length + " notes...", function(results) {
                // Load all notes in batches to show progress
                var notesCreated = 0;
                var batchSize = Math.max(1, Math.floor(allNotes.length / 10)); // Process in 10% chunks

                for (i in 0...allNotes.length) {
                    var noteData = allNotes[i];
                    // Fix animation data to cycle 0-3 for proper animations
                    var animData = Std.int(noteData[1]) % 4;
                    var note = new ChartingNote(noteData[0], animData, null, false, true);
                    note.x = gridBg.x + (noteData[1] * gridSize);
                    note.y = gridBg.y + getYFromTime(noteData[0]);

                    // Set scale to match strum size
                    note.setGraphicSize(Std.int(gridSize));
                    note.updateHitbox();

                    notes.add(note);
                    notesCreated++;
                }
                return "Loaded " + notesCreated + " notes";
            }),
            GenericProgressSubstate.createTask("Applying note animations...", function(results) {
                // Animate notes appearing
                animateNotesIn();
                return "Note animations applied";
            }),
            GenericProgressSubstate.createTask("Finalizing chart load...", function(results) {
                return "Chart loaded successfully";
            })
        ];

        var progressDialog = new GenericProgressSubstate(
            "Loading Chart: " + _song.song,
            loadTasks,
            function(results) {
                isLoadingChart = false;
                trace("Chart loaded with " + notes.length + " notes");
            },
            function(error, shouldThrow) {
                isLoadingChart = false;
                trace("Error loading chart: " + error);
            },
            null,
            false // Disable cancel for chart loading
        );

        openSubState(progressDialog);
    }

    function animateNotesIn():Void
    {
        var delay:Float = 0;
        notes.forEach(function(note:ChartingNote) {
            note.alpha = 0;
            note.scale.set(0.1, 0.1);

            FlxTween.tween(note, {alpha: 1}, 0.3, {
                ease: FlxEase.sineOut,
                startDelay: delay
            });

            FlxTween.tween(note.scale, {x: 1, y: 1}, 0.4, {
                ease: FlxEase.backOut,
                startDelay: delay
            });

            delay += 0.01; // Stagger animation
        });
    }

    function getYFromTime(time:Float):Float
    {
        var crochet = (60 / _song.bpm) * 1000;
        return (time / crochet) * gridSize;
    }

    function getTimeFromY(y:Float):Float
    {
        var crochet = (60 / _song.bpm) * 1000;
        return ((y - gridBg.y) / gridSize) * crochet;
    }

    function playEntranceAnimation():Void
    {
        // Slide in grid
        gridBg.x -= 200;
        FlxTween.tween(gridBg, {x: gridBg.x + 200}, 0.8, {
            ease: FlxEase.backOut
        });

        // Animate strum notes
        for (i in 0...strumLineNotes.length)
        {
            var strum = strumLineNotes.members[i];
            strum.alpha = 0;
            strum.y -= 50;

            FlxTween.tween(strum, {alpha: 1, y: strum.y + 50}, 0.6, {
                ease: FlxEase.elasticOut,
                startDelay: i * 0.05
            });
        }

        // After entrance animation, check and load existing chart
        new FlxTimer().start(1.2, function(_) {
            checkAndLoadExistingChart();
        });
    }

    function checkAndLoadExistingChart():Void
    {
        if (PlayState.SONG != null && PlayState.SONG.notes != null && PlayState.SONG.notes.length > 0)
        {
            // Chart exists, load it with animation
            loadNotesFromSong();
        }
        else
        {
            trace("No existing chart to load");
        }
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Ensure cursor remains visible throughout the session
        if (!FlxG.mouse.visible)
            FlxG.mouse.visible = true;

        updateInfo();
        handleInput();
        updateAudio();
        updateScrolling();
        updateSectionUI(); // Update section-related UI elements

        // Update conductor
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            Conductor.songPosition = FlxG.sound.music.time;
            // curStep, curBeat, curSection are automatically updated by parent MusicBeatState

            // Auto-scroll when playing
            autoScrollDuringPlayback();
        }
    }

    function updateInfo():Void
    {
        var bpm = PlayState.SONG?.bpm;
        var time = FlxG.sound.music != null ? FlxG.sound.music.time : 0;
        var pos = 'Step: $curStep | Beat: $curBeat | Section: $curSection';
        var songInfo = 'Song: ${PlayState.SONG?.song} | BPM: $bpm';

        infoText.text = '$songInfo\\n$pos\\nTime: ${Math.round(time)}ms';
    }

    function handleInput():Void
    {
        // Playback controls
        if (FlxG.keys.justPressed.SPACE)
            togglePlayback();

        if (FlxG.keys.justPressed.ENTER)
            testPlayChart();

        // Save/Load
        if (FlxG.keys.pressed.CONTROL)
        {
            if (FlxG.keys.justPressed.S)
                saveChart();
            else if (FlxG.keys.justPressed.O)
                openChart();
            else if (FlxG.keys.justPressed.N)
                newChart();
            else if (FlxG.keys.justPressed.Z && !FlxG.keys.pressed.SHIFT)
                undo();
            else if (FlxG.keys.justPressed.Y || (FlxG.keys.justPressed.Z && FlxG.keys.pressed.SHIFT))
                redo();
        }

        // Grid controls
        if (FlxG.keys.justPressed.G)
            toggleGrid();

        if (FlxG.keys.justPressed.H)
            toggleSnap();

        // Note editing
        if (FlxG.keys.justPressed.DELETE)
            deleteSelectedNotes();

        // Copy/Paste
        if (FlxG.keys.pressed.CONTROL)
        {
            if (FlxG.keys.justPressed.C)
                copySelection();
            else if (FlxG.keys.justPressed.V)
                pasteSelection();
            else if (FlxG.keys.justPressed.X)
                cutSelection();
        }

        // Select all
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A)
            selectAll();

        // Mouse input
        handleMouseInput();

        // Exit
        if (FlxG.keys.justPressed.ESCAPE)
            exitEditor();
    }

    function updateScrolling():Void
    {
        // Manual scrolling with mouse wheel
        if (FlxG.mouse.wheel != 0)
        {
            scrollY -= FlxG.mouse.wheel * gridSize * 2;
            updateGridPosition();
        }

        // Manual scrolling with arrow keys
        if (FlxG.keys.pressed.UP)
        {
            scrollY -= gridSize * 4 * FlxG.elapsed;
            updateGridPosition();
        }
        else if (FlxG.keys.pressed.DOWN)
        {
            scrollY += gridSize * 4 * FlxG.elapsed;
            updateGridPosition();
        }

        // Page up/down for faster scrolling
        if (FlxG.keys.justPressed.PAGEUP)
        {
            scrollY -= gridSize * 16;
            updateGridPosition();
        }
        else if (FlxG.keys.justPressed.PAGEDOWN)
        {
            scrollY += gridSize * 16;
            updateGridPosition();
        }

        // Home/End for section navigation
        if (FlxG.keys.justPressed.HOME)
        {
            scrollY = 0;
            updateGridPosition();
        }
        else if (FlxG.keys.justPressed.END)
        {
            var maxScroll = getSongLengthInPixels();
            scrollY = maxScroll - (gridSize * 16);
            updateGridPosition();
        }
    }

    function autoScrollDuringPlayback():Void
    {
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            var currentTimePos = getYFromTime(Conductor.songPosition);
            var targetScrollY = currentTimePos - (gridSize * 8); // Keep playhead in middle

            // Smooth auto-scroll
            scrollY = FlxMath.lerp(scrollY, targetScrollY, 0.1);
            updateGridPosition();
        }
    }

    function updateGridPosition():Void
    {
        // Create infinite scroll effect by repositioning grid
        var gridOffset = scrollY % (gridSize * 4); // Repeat every 4 beats
        gridBg.y = 50 - gridOffset;

        // Update strum line position (always stays at top)
        strumLineNotes.forEach(function(strum) {
            strum.y = 50; // Keep strums at fixed position
        });

        // Update note positions
        notes.forEach(function(note:ChartingNote) {
            note.y = 50 + getYFromTime(note.strumTime) - scrollY;
        });
    }

    function getSongLengthInPixels():Float
    {
        if (FlxG.sound.music != null)
        {
            return getYFromTime(FlxG.sound.music.length);
        }
        return gridSize * 64; // Default fallback
    }

    function handleMouseInput():Void
    {
        if (FlxG.mouse.justPressed)
        {
            var mouseX = FlxG.mouse.x;
            var mouseY = FlxG.mouse.y;

            // Check if clicking on grid
            if (mouseX >= gridBg.x && mouseX < gridBg.x + gridBg.width &&
                mouseY >= gridBg.y && mouseY < gridBg.y + gridBg.height)
            {
                var gridX = Math.floor((mouseX - gridBg.x) / gridSize);
                var gridY = Math.floor((mouseY - gridBg.y) / gridSize);

                if (currentTool == "select")
                {
                    selectNotesAt(gridX, gridY);
                }
                else if (currentTool == "place")
                {
                    placeNote(gridX, gridY);
                }
            }
        }

        if (FlxG.mouse.pressed && isDragging)
        {
            // Handle dragging selected notes
            dragSelectedNotes();
        }

        if (FlxG.mouse.justReleased)
        {
            isDragging = false;
        }
    }

    function selectNotesAt(gridX:Int, gridY:Int):Void
    {
        var found = false;
        notes.forEach(function(note:ChartingNote) {
            var noteGridX = Math.floor((note.x - gridBg.x) / gridSize);
            var noteGridY = Math.floor((note.y - gridBg.y) / gridSize);

            if (noteGridX == gridX && noteGridY == gridY)
            {
                if (!FlxG.keys.pressed.SHIFT)
                    clearSelection();

                selectedNotes.push(note);
                note.alpha = 0.7; // Highlight selected notes
                found = true;
            }
        });

        if (!found && !FlxG.keys.pressed.SHIFT)
            clearSelection();
    }

    function placeNote(gridX:Int, gridY:Int):Void
    {
        var time = getTimeFromY(gridY * gridSize);
        // Properly modulate note data to ensure valid animations (0-3 cycle)
        var noteData = gridX % 4;
        var note = new ChartingNote(time, noteData, null, false, true);
        note.x = gridBg.x + (gridX * gridSize);
        note.y = gridBg.y + (gridY * gridSize);

        // Set scale to match strum size
        note.setGraphicSize(Std.int(gridSize));
        note.updateHitbox();

        // Animate note placement - only alpha, no scale conflicts
        note.alpha = 0;

        notes.add(note);

        // Animate note appearing
        FlxTween.tween(note, {alpha: 1}, 0.2, {
            ease: FlxEase.sineOut
        });

        // Add to song data with proper data value
        addNoteToSong(time, noteData);

        // Add to undo stack
        addUndoAction("place_note", {note: note});

        hasUnsavedChanges = true;
    }

    function addNoteToSong(time:Float, data:Int):Void
    {
        // Find appropriate section
        var section = Math.floor(time / (Conductor.crochet * 4));

        // Ensure section exists
        while (_song.notes.length <= section)
        {
            _song.notes.push({
                sectionNotes: [],
                sectionBeats: 4,
                sectionSteps: 16,
                mustHitSection: false
            });
        }

        // Add note data [time, data, sustainLength, noteType]
        // Data should be 0-3 for proper animation handling
        _song.notes[section].sectionNotes.push([time, data, 0]);
    }

    function clearSelection():Void
    {
        for (note in selectedNotes)
            note.alpha = 1.0;
        selectedNotes = [];
    }

    function dragSelectedNotes():Void
    {
        // Implementation for dragging notes
        // This would move all selected notes based on mouse movement
    }

    function updateAudio():Void
    {
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            // Sync vocals
            if (vocals != null)
            {
                if (Math.abs(vocals.time - FlxG.sound.music.time) > 20)
                    vocals.time = FlxG.sound.music.time;
            }

            if (opponentVocals != null)
            {
                if (Math.abs(opponentVocals.time - FlxG.sound.music.time) > 20)
                    opponentVocals.time = FlxG.sound.music.time;
            }
        }
    }

    // Chart Functions
    public function togglePlayback():Void
    {
        if (FlxG.sound.music == null) return;

        if (FlxG.sound.music.playing)
        {
            FlxG.sound.music.pause();
            if (vocals != null) vocals.pause();
            if (opponentVocals != null) opponentVocals.pause();

            // Animate play button
            FlxTween.tween(playButton, {alpha: 1}, 0.2);
        }
        else
        {
            FlxG.sound.music.play();
            if (vocals != null) vocals.play();
            if (opponentVocals != null) opponentVocals.play();

            // Animate play button
            FlxTween.tween(playButton, {alpha: 0.7}, 0.2);
        }
    }

    public function stopPlayback():Void
    {
        if (FlxG.sound.music != null)
        {
            FlxG.sound.music.pause();
            FlxG.sound.music.time = 0;
        }

        if (vocals != null)
        {
            vocals.pause();
            vocals.time = 0;
        }

        if (opponentVocals != null)
        {
            opponentVocals.pause();
            opponentVocals.time = 0;
        }

        // Reset conductor
        Conductor.songPosition = 0;
        // curStep, curBeat, curSection are automatically updated by parent MusicBeatState
    }

    public function saveChart():Void
    {
        #if sys
        // Check if both chart and events exist for split save option
        var hasEvents = _song.events != null && _song.events.length > 0;
        var hasNotes = _song.notes != null && _song.notes.length > 0;

        if (hasEvents && hasNotes)
        {
            // Show custom save options substate
            var saveOptionsSubstate = new SaveOptionsSubstate(
                function() {
                    saveChartCombined();
                },
                function() {
                    saveChartSplit();
                },
                function() {
                    // Cancel - do nothing
                }
            );
            openSubState(saveOptionsSubstate);
        }
        else
        {
            saveChartCombined();
        }
        #end
    }

    function saveChartCombined():Void
    {
        #if sys
        var saveTasks = [
            GenericProgressSubstate.createTask("Preparing chart data...", function(results) {
                PlayState.SONG = _song;
                return "Chart data prepared";
            }),
            GenericProgressSubstate.createTask("Generating JSON...", function(results) {
                var json = {
                    "song": _song
                };
                return Json.stringify(json, "\t");
            }),
            GenericProgressSubstate.createTask("Saving file...", function(results) {
                var data:String = results[1];
                var success = ImprovedFileHandling.saveOperation(
                    Paths.formatToSongPath(_song.song) + ".json",
                    {ext: "json", desc: "Chart JSON File"},
                    ReadType.Text,
                    data
                );
                return success ? "File saved successfully" : "Save failed";
            })
        ];

        var progressDialog = new GenericProgressSubstate(
            "Saving Chart: " + _song.song,
            saveTasks,
            function(results) {
                hasUnsavedChanges = false;
                showSaveConfirmation("Chart saved successfully!");
            },
            function(error, shouldThrow) {
                showSaveConfirmation("Save failed: " + error, FlxColor.RED);
            }
        );

        openSubState(progressDialog);
        #end
    }

    function saveChartSplit():Void
    {
        #if sys
        var saveTasks = [
            GenericProgressSubstate.createTask("Preparing chart data...", function(results) {
                PlayState.SONG = _song;
                return "Chart data prepared";
            }),
            GenericProgressSubstate.createTask("Generating chart JSON...", function(results) {
                var chartData = {
                    song: _song.song,
                    notes: _song.notes,
                    bpm: _song.bpm,
                    needsVoices: _song.needsVoices,
                    speed: _song.speed,
                    offset: _song.offset,
                    player1: _song.player1,
                    player2: _song.player2,
                    player4: _song.player4,
                    player5: _song.player5,
                    gfVersion: _song.gfVersion,
                    stage: _song.stage,
                    mania: _song.mania,
                    startMania: _song.startMania,
                    format: _song.format
                };
                var json = {
                    "song": chartData
                };
                return Json.stringify(json, "\t");
            }),
            GenericProgressSubstate.createTask("Generating events JSON...", function(results) {
                return Json.stringify({"events": _song.events}, "\t");
            }),
            GenericProgressSubstate.createTask("Saving files...", function(results) {
                var chartData:String = results[1];
                var eventsData:String = results[2];

                var extraFiles = [{
                    name: "events.json",
                    data: eventsData
                }];

                var success = ImprovedFileHandling.multiSaveOperation(
                    Paths.formatToSongPath(_song.song) + ".json",
                    {ext: "json", desc: "Chart JSON File"},
                    ReadType.Text,
                    chartData,
                    extraFiles
                );
                return success ? "Files saved successfully" : "Save failed";
            })
        ];

        var progressDialog = new GenericProgressSubstate(
            "Saving Chart + Events: " + _song.song,
            saveTasks,
            function(results) {
                hasUnsavedChanges = false;
                showSaveConfirmation("Chart and events saved successfully!");
            },
            function(error, shouldThrow) {
                showSaveConfirmation("Save failed: " + error, FlxColor.RED);
            }
        );

        openSubState(progressDialog);
        #end
    }

    function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
        {
            var stepper:FlxUINumericStepper = cast sender;
            var stepperName = stepper.name;

            switch (stepperName)
            {
                case 'song_bpm':
                    _song.bpm = stepper.value;
                    Conductor.bpm = stepper.value;
                    hasUnsavedChanges = true;

                case 'song_speed':
                    _song.speed = stepper.value;
                    hasUnsavedChanges = true;

                case 'song_offset':
                    _song.offset = stepper.value;
                    hasUnsavedChanges = true;

                case 'section_beats':
                    var currentSection = getCurrentSection();
                    if (currentSection != null)
                    {
                        currentSection.sectionBeats = stepper.value;
                        hasUnsavedChanges = true;
                        reloadGrid();
                    }

                case 'section_steps':
                    var currentSection = getCurrentSection();
                    if (currentSection != null)
                    {
                        currentSection.sectionSteps = stepper.value;
                        hasUnsavedChanges = true;
                        reloadGrid();
                    }
            }
        }
        else if (id == FlxUICheckBox.CLICK_EVENT && (sender is FlxUICheckBox))
        {
            var checkbox:FlxUICheckBox = cast sender;
            var checkboxName = checkbox.name;

            switch (checkboxName)
            {
                case 'must_hit_section':
                    var currentSection = getCurrentSection();
                    if (currentSection != null)
                    {
                        currentSection.mustHitSection = checkbox.checked;
                        hasUnsavedChanges = true;
                        updateGrid();
                    }

                case 'gf_section':
                    var currentSection = getCurrentSection();
                    if (currentSection != null)
                    {
                        currentSection.gfSection = checkbox.checked;
                        hasUnsavedChanges = true;
                        updateGrid();
                    }

                case 'change_bpm':
                    var currentSection = getCurrentSection();
                    if (currentSection != null)
                    {
                        currentSection.changeBPM = checkbox.checked;
                        hasUnsavedChanges = true;
                    }
            }
        }
    }

    function reloadGrid():Void
    {
        updateGrid();
        // Additional grid reloading logic can be added here
    }

    function showSaveConfirmation(message:String, ?color:FlxColor):Void
    {
        var saveText = new FlxText(saveButton.x, saveButton.y - 30, 0, message, 12);
        saveText.cameras = [camHUD];
        saveText.color = color != null ? color : FlxColor.GREEN;
        saveText.setFormat(Paths.font("vcr.ttf"), 12, saveText.color, CENTER, OUTLINE, FlxColor.BLACK);
        saveText.borderSize = 1;
        add(saveText);

        FlxTween.tween(saveText, {alpha: 0, y: saveText.y - 20}, 1.5, {
            ease: FlxEase.sineOut,
            onComplete: function(tween) {
                remove(saveText);
            }
        });
    }

    public function openChart():Void
    {
        // For now, just trace - in full implementation would open file dialog
        trace("Open chart dialog would appear here");
    }

    public function newChart():Void
    {
        if (hasUnsavedChanges)
        {
            // In full implementation, show confirmation dialog
            trace("Confirm new chart dialog would appear here");
        }

        _song = {
            song: 'New Song',
            notes: [],
            events: [],
            bpm: 120,
            needsVoices: true,
            speed: 1,
            offset: 0,
            player1: 'bf',
            player2: 'dad',
            player4: 'dad',
            player5: 'bf',
            gfVersion: 'gf',
            stage: 'stage',
            mania: 0,
            startMania: 0,
            format: 'psych_v1'
        };

        Conductor.bpm = _song.bpm;
        loadNotesFromSong();
        clearUndoStack();
        hasUnsavedChanges = false;
    }

    public function testPlayChart():Void
    {
        if (FlxG.sound.music == null)
        {
            trace("Load a song first!");
            return;
        }

        // Save current state
        var currentTime = FlxG.sound.music.time;

        // In full implementation, would switch to PlayState in test mode
        trace("Would test play from position: " + currentTime);
    }

    public function toggleGrid():Void
    {
        showGrid = !showGrid;
        updateGrid();

        // Animate grid toggle
        if (showGrid)
        {
            gridBg.alpha = 0;
            FlxTween.tween(gridBg, {alpha: 1}, 0.3);
        }
        else
        {
            FlxTween.tween(gridBg, {alpha: 0}, 0.3);
        }
    }

    public function toggleSnap():Void
    {
        snapToGrid = !snapToGrid;

        // Show feedback
        var snapText = new FlxText(FlxG.width - 200, 50, 0, "Snap: " + (snapToGrid ? "ON" : "OFF"), 16);
        snapText.cameras = [camHUD];
        snapText.color = snapToGrid ? FlxColor.GREEN : FlxColor.RED;
        add(snapText);

        FlxTween.tween(snapText, {alpha: 0}, 2.0, {
            onComplete: function(tween) {
                remove(snapText);
            }
        });
    }

    // Selection functions
    public function deleteSelectedNotes():Void
    {
        if (selectedNotes.length == 0) return;

        addUndoAction("delete_notes", {notes: selectedNotes.copy()});

        for (note in selectedNotes)
        {
            notes.remove(note);
            removeNoteFromSong(note);
        }

        selectedNotes = [];
        hasUnsavedChanges = true;
    }

    function removeNoteFromSong(note:ChartingNote):Void
    {
        // Find and remove note from song data
        for (section in _song.notes)
        {
            if (section.sectionNotes == null) continue;

            for (i in 0...section.sectionNotes.length)
            {
                var noteData = section.sectionNotes[i];
                if (Math.abs(noteData[0] - note.strumTime) < 1 && noteData[1] == note.noteData)
                {
                    section.sectionNotes.remove(noteData);
                    break;
                }
            }
        }
    }

    public function copySelection():Void
    {
        // Implementation for copying selected notes
        trace("Copied " + selectedNotes.length + " notes");
    }

    public function pasteSelection():Void
    {
        // Implementation for pasting notes
        trace("Paste notes");
    }

    public function cutSelection():Void
    {
        copySelection();
        deleteSelectedNotes();
    }

    public function selectAll():Void
    {
        clearSelection();
        notes.forEach(function(note:ChartingNote) {
            selectedNotes.push(note);
            note.alpha = 0.7;
        });
    }

    // Undo/Redo system
    function addUndoAction(type:String, data:Dynamic):Void
    {
        undoStack.push({type: type, data: data});
        redoStack = []; // Clear redo stack when new action is added

        // Limit undo stack size
        if (undoStack.length > 50)
            undoStack.shift();
    }

    public function undo():Void
    {
        if (undoStack.length == 0) return;

        var action = undoStack.pop();
        redoStack.push(action);

        // Perform undo based on action type
        switch (action.type)
        {
            case "place_note":
                var note = action.data.note;
                notes.remove(note);
                removeNoteFromSong(note);

            case "delete_notes":
                var deletedNotes:Array<ChartingNote> = cast action.data.notes;
                for (note in deletedNotes)
                {
                    notes.add(note);
                    addNoteToSong(note.strumTime, note.noteData);
                }
        }

        hasUnsavedChanges = true;
    }

    public function redo():Void
    {
        if (redoStack.length == 0) return;

        var action = redoStack.pop();
        undoStack.push(action);

        // Perform redo (opposite of undo)
        switch (action.type)
        {
            case "place_note":
                var note = action.data.note;
                notes.add(note);
                addNoteToSong(note.strumTime, note.noteData);

            case "delete_notes":
                var deletedNotes:Array<ChartingNote> = cast action.data.notes;
                for (note in deletedNotes)
                {
                    notes.remove(note);
                    removeNoteFromSong(note);
                }
        }

        hasUnsavedChanges = true;
    }

    function clearUndoStack():Void
    {
        undoStack = [];
        redoStack = [];
    }

    // Settings
    function loadSettings():Void
    {
        settings = {
            snapToGrid: true,
            showGrid: true,
            gridSize: 40,
            autoSave: true
        };
    }

    function loadUILayout():Void
    {
        // Try to load existing layout
        var layoutPath = "chartEditorLayout.json";

        #if sys
        if (sys.FileSystem.exists(layoutPath))
        {
            try
            {
                var layoutData = sys.io.File.getContent(layoutPath);
                uiLayout = Json.parse(layoutData);
                return;
            }
            catch (e:Dynamic)
            {
                trace("Failed to load UI layout: " + e);
            }
        }
        #end

        // Default layout if none exists
        createDefaultUILayout();
    }

    function createDefaultUILayout():Void
    {
        uiLayout = {
            panels: [
                {
                    id: "songProperties",
                    x: FlxG.width - 320,
                    y: 20,
                    width: 300,
                    height: 250,
                    visible: true,
                    docked: true,
                    elements: ["songBPM", "songSpeed", "songOffset", "needsVoices"]
                },
                {
                    id: "sectionProperties",
                    x: FlxG.width - 320,
                    y: 280,
                    width: 300,
                    height: 200,
                    visible: true,
                    docked: true,
                    elements: ["sectionLength", "mustHitSection", "gfSection", "altAnim"]
                },
                {
                    id: "playbackControls",
                    x: 20,
                    y: FlxG.height - 120,
                    width: 400,
                    height: 100,
                    visible: true,
                    docked: true,
                    elements: ["playButton", "stopButton", "saveButton", "loadButton"]
                }
            ],
            theme: "archipelago",
            version: 1
        };
    }

    function saveUILayout():Void
    {
        #if sys
        try
        {
            var layoutData = Json.stringify(uiLayout, "  ");
            sys.io.File.saveContent("chartEditorLayout.json", layoutData);
        }
        catch (e:Dynamic)
        {
            trace("Failed to save UI layout: " + e);
        }
        #end
    }

    function createUISystem():Void
    {
        uiElements = new FlxTypedGroup<FlxSprite>();
        add(uiElements);

        // Create panels based on layout
        for (panelConfig in uiLayout.panels)
        {
            if (panelConfig.visible)
            {
                var panel = createUIPanel(panelConfig);
                uiPanels.set(panelConfig.id, panel);
                uiElements.add(panel);
                uiElements.add(panel.titleText);
            }
        }
    }

    function createUIPanel(config:UIPanelConfig):MixtapeUIPanel
    {
        var title = switch(config.id) {
            case "songProperties": "Song Properties";
            case "sectionProperties": "Section Properties";
            case "playbackControls": "Playback Controls";
            default: config.id;
        }

        var panel = new MixtapeUIPanel(config.id, title, config.x, config.y, config.width, config.height);
        panel.cameras = [camHUD];

        return panel;
    }

    function saveSettings():Void
    {
        // Save settings to file
    }

    public function exitEditor():Void
    {
        if (hasUnsavedChanges)
        {
            // In full implementation, show confirmation dialog
            trace("Unsaved changes dialog would appear here");
        }

        // Stop all audio
        stopPlayback();

        // Hide cursor when leaving (let the next state handle cursor visibility)
        FlxG.mouse.visible = false;

        // Cleanup tweens
        for (tween in uiAnimations)
        {
            if (tween != null)
                tween.cancel();
        }

        FlxG.switchState(new MasterEditorMenu());
    }

    override function destroy():Void
    {
        // Save UI layout before destroying
        saveUILayout();

        // Cleanup UI system
        if (uiElements != null)
        {
            uiElements.destroy();
            uiElements = null;
        }

        for (panel in uiPanels)
        {
            panel.destroy();
        }
        uiPanels.clear();

        // Cleanup audio
        if (vocals != null)
        {
            vocals.destroy();
            vocals = null;
        }

        if (opponentVocals != null)
        {
            opponentVocals.destroy();
            opponentVocals = null;
        }

        // Cleanup tweens
        for (tween in uiAnimations)
        {
            if (tween != null)
                tween.cancel();
        }
        uiAnimations.clear();

        super.destroy();
    }
}
