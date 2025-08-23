package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import backend.MusicBeatState;
import backend.Paths;
#if DISCORD_ALLOWED
import backend.Discord.DiscordClient;
#end
import yutautil.media.MediaMicrophone;
import yutautil.media.MediaMicrophone.VisualMode;

/**
 * Microphone Test State - Test microphone functionality and visual feedback
 */
class MicrophoneTestState extends MusicBeatState {
    private var microphone:MediaMicrophone;
    private var titleText:FlxText;
    private var instructionText:FlxText;
    private var statusText:FlxText;
    private var audioLevelsText:FlxText;
    
    // Visual feedback sprites
    private var volumeBarSprite:FlxSprite;
    private var peakFlashSprite:FlxSprite;
    private var waveSprite:FlxSprite;
    private var colorIntensitySprite:FlxSprite;
    private var volumeWidthSprite:FlxSprite;
    
    // Visualizer bars
    private var visualizerBars:Array<FlxSprite> = [];
    private static var BAR_COUNT:Int = 20;
    
    // UI elements
    private var statusGroup:FlxGroup;
    
    override function create() {
        super.create();
        
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Testing Microphone", "Microphone Test State");
        #end
        
        setupBackground();
        setupMicrophone();
        setupUI();
        setupVisualFeedback();
        
        trace("MicrophoneTestState initialized");
    }
    
    private function setupBackground():Void {
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1a1a1a);
        bg.scrollFactor.set();
        add(bg);
    }
    
    private function setupMicrophone():Void {
        microphone = new MediaMicrophone(44100, 75);
        
        // Set up callbacks
        microphone.onStatusChange = function(status:String) {
            trace("Microphone status changed: " + status);
            updateStatusDisplay();
        };
        
        microphone.onActivityChange = function(active:Bool) {
            trace("Microphone activity: " + active);
            updateStatusDisplay();
        };
        
        microphone.onVolumeChange = function(volume:Float) {
            updateAudioLevels();
            updateVisualizerBars();
        };
        
        microphone.onSampleData = function(data) {
            // Sample data callback - can be used for advanced audio processing
        };
    }
    
    private function setupUI():Void {
        // Title
        titleText = new FlxText(0, 20, FlxG.width, "MICROPHONE TEST STATE", 28);
        titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
        add(titleText);
        
        // Instructions
        instructionText = new FlxText(20, 70, 350, "", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN, LEFT);
        instructionText.text = "Microphone Control:\n";
        instructionText.text += "SPACE: Start/Stop Microphone\n";
        instructionText.text += "1-5: Set Gain (20%, 40%, 60%, 80%, 100%)\n";
        instructionText.text += "S: Change Silence Level\n";
        instructionText.text += "E: Toggle Enhanced Capture\n";
        instructionText.text += "C: Clear Visual Targets\n";
        instructionText.text += "A: Add Visual Targets\n";
        instructionText.text += "I: Show Microphone Info\n\n";
        instructionText.text += "ESC: Return to Debug Menu";
        add(instructionText);
        
        // Status group
        statusGroup = new FlxGroup();
        add(statusGroup);
        
        setupStatusDisplay();
        updateStatusDisplay();
    }
    
    private function setupStatusDisplay():Void {
        // Status text
        statusText = new FlxText(20, 280, 350, "", 12);
        statusText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, LEFT);
        statusGroup.add(statusText);
        
        // Audio levels text
        audioLevelsText = new FlxText(20, 380, 350, "", 10);
        audioLevelsText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.LIME, LEFT);
        statusGroup.add(audioLevelsText);
    }
    
    private function setupVisualFeedback():Void {
        // Volume bar (vertical)
        volumeBarSprite = new FlxSprite(400, 100);
        volumeBarSprite.makeGraphic(40, 200, FlxColor.GREEN);
        volumeBarSprite.origin.set(20, 200);
        add(volumeBarSprite);
        
        var barLabel = new FlxText(380, 80, 80, "Volume Bar", 10);
        barLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
        add(barLabel);
        
        // Peak flash sprite
        peakFlashSprite = new FlxSprite(460, 100);
        peakFlashSprite.makeGraphic(60, 60, FlxColor.WHITE);
        add(peakFlashSprite);
        
        var peakLabel = new FlxText(450, 80, 80, "Peak Flash", 10);
        peakLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
        add(peakLabel);
        
        // Wave simulation sprite
        waveSprite = new FlxSprite(540, 100);
        waveSprite.makeGraphic(60, 60, FlxColor.BLUE);
        add(waveSprite);
        
        var waveLabel = new FlxText(530, 80, 80, "Wave Sim", 10);
        waveLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
        add(waveLabel);
        
        // Color intensity sprite
        colorIntensitySprite = new FlxSprite(620, 100);
        colorIntensitySprite.makeGraphic(60, 60, FlxColor.MAGENTA);
        add(colorIntensitySprite);
        
        var colorLabel = new FlxText(610, 80, 80, "Color Int", 10);
        colorLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
        add(colorLabel);
        
        // Volume width sprite
        volumeWidthSprite = new FlxSprite(400, 180);
        volumeWidthSprite.makeGraphic(200, 30, FlxColor.ORANGE);
        volumeWidthSprite.origin.set(0, 15);
        add(volumeWidthSprite);
        
        var widthLabel = new FlxText(480, 160, 80, "Volume Width", 10);
        widthLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
        add(widthLabel);
        
        // Visualizer bars
        setupVisualizerBars();
        
        // Add all visual targets to microphone
        addVisualTargets();
    }
    
    private function setupVisualizerBars():Void {
        var startX = 400;
        var startY = 350;
        var barWidth = 15;
        var barSpacing = 3;
        var maxHeight = 150;
        
        var vizLabel = new FlxText(startX, 320, 300, "Audio Visualizer", 12);
        vizLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT);
        add(vizLabel);
        
        for (i in 0...BAR_COUNT) {
            var bar = new FlxSprite(startX + i * (barWidth + barSpacing), startY);
            bar.makeGraphic(barWidth, maxHeight, FlxColor.fromHSB(i * 18, 0.8, 1.0)); // Rainbow colors
            bar.origin.set(barWidth / 2, maxHeight);
            bar.scale.y = 0.1;
            visualizerBars.push(bar);
            add(bar);
        }
    }
    
    private function addVisualTargets():Void {
        if (microphone != null) {
            microphone.addVisualTarget(volumeBarSprite, VOLUME_BAR);
            microphone.addVisualTarget(peakFlashSprite, PEAK_FLASH);
            microphone.addVisualTarget(waveSprite, WAVE_SIMULATION);
            microphone.addVisualTarget(colorIntensitySprite, COLOR_INTENSITY);
            microphone.addVisualTarget(volumeWidthSprite, VOLUME_WIDTH);
        }
    }
    
    private function clearVisualTargets():Void {
        if (microphone != null) {
            microphone.removeVisualTarget(volumeBarSprite);
            microphone.removeVisualTarget(peakFlashSprite);
            microphone.removeVisualTarget(waveSprite);
            microphone.removeVisualTarget(colorIntensitySprite);
            microphone.removeVisualTarget(volumeWidthSprite);
        }
        
        // Reset sprites to default state
        volumeBarSprite.scale.y = 0.1;
        volumeBarSprite.color = FlxColor.GREEN;
        
        peakFlashSprite.alpha = 0.5;
        peakFlashSprite.color = FlxColor.WHITE;
        
        waveSprite.scale.set(1, 1);
        
        colorIntensitySprite.alpha = 0.2;
        
        volumeWidthSprite.scale.x = 0.1;
    }
    
    private function updateStatusDisplay():Void {
        if (microphone == null) return;
        
        var status = "";
        status += "Microphone Status:\n";
        status += "Available: " + (microphone.isAvailable ? "Yes" : "No") + "\n";
        status += "Active: " + (microphone.isActive ? "Yes" : "No") + "\n";
        status += "Sample Rate: " + microphone.sampleRate + " Hz\n";
        status += "Gain: " + microphone.gain + "%\n";
        status += "Silence Level: " + microphone.silenceLevel + "%\n";
        status += "Silence Timeout: " + microphone.silenceTimeout + " ms\n";
        
        statusText.text = status;
    }
    
    private function updateAudioLevels():Void {
        if (microphone == null) return;
        
        var levels = microphone.getAudioLevels();
        var levelsStr = "";
        levelsStr += "Audio Levels:\n";
        levelsStr += "Current Volume: " + Std.int(levels.volume) + "%\n";
        levelsStr += "Average Volume: " + Std.int(levels.averageVolume) + "%\n";
        levelsStr += "Peak Volume: " + Std.int(levels.peakVolume) + "%\n";
        levelsStr += "Activity Level: " + levels.activityLevel + "\n";
        
        audioLevelsText.text = levelsStr;
    }
    
    private function updateVisualizerBars():Void {
        if (microphone == null) return;
        
        var volume = microphone.volume;
        var peakVolume = microphone.peakVolume;
        
        for (i in 0...visualizerBars.length) {
            var bar = visualizerBars[i];
            
            // Create a pseudo-frequency response based on volume and randomness
            var frequency = FlxG.random.float(0.1, 1.0);
            var response = (volume / 100) * frequency;
            
            // Add some peak influence
            if (peakVolume > 70) {
                response += FlxG.random.float(0.1, 0.3);
            }
            
            // Smooth the bar scaling
            var targetScale = Math.max(0.05, Math.min(1.0, response));
            bar.scale.y = flixel.math.FlxMath.lerp(bar.scale.y, targetScale, 0.3);
            
            // Color based on intensity
            var hue = (i * 18) % 360;
            var saturation = 0.8;
            var brightness = Math.min(1.0, response + 0.3);
            bar.color = FlxColor.fromHSB(hue, saturation, brightness);
        }
    }
    
    private function startStopMicrophone():Void {
        if (microphone == null) return;
        
        if (microphone.isActive) {
            microphone.stop();
            FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
        } else {
            if (microphone.start()) {
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
            } else {
                FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
            }
        }
        
        updateStatusDisplay();
    }
    
    private function setGain(gain:Float):Void {
        if (microphone == null) return;
        
        microphone.setGain(gain);
        updateStatusDisplay();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }
    
    private function changeSilenceLevel():Void {
        if (microphone == null) return;
        
        // Cycle through silence levels
        var currentLevel = microphone.silenceLevel;
        var newLevel:Float;
        
        if (currentLevel <= 5) {
            newLevel = 10;
        } else if (currentLevel <= 10) {
            newLevel = 20;
        } else if (currentLevel <= 20) {
            newLevel = 40;
        } else {
            newLevel = 5;
        }
        
        microphone.setSilenceLevel(newLevel, microphone.silenceTimeout);
        updateStatusDisplay();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
    }
    
    private function toggleEnhancedCapture():Void {
        if (microphone == null) return;
        
        // This would toggle enhanced capture features
        microphone.setEnhancedCapture(!microphone.isActive); // Simple toggle for demo
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        // Handle input
        if (controls.BACK) {
            if (microphone != null) {
                microphone.dispose();
            }
            MusicBeatState.switchState(new DebugStateMenu());
        }
        
        // Microphone controls
        if (FlxG.keys.justPressed.SPACE) {
            startStopMicrophone();
        }
        
        if (FlxG.keys.justPressed.ONE) {
            setGain(20);
        }
        
        if (FlxG.keys.justPressed.TWO) {
            setGain(40);
        }
        
        if (FlxG.keys.justPressed.THREE) {
            setGain(60);
        }
        
        if (FlxG.keys.justPressed.FOUR) {
            setGain(80);
        }
        
        if (FlxG.keys.justPressed.FIVE) {
            setGain(100);
        }
        
        if (FlxG.keys.justPressed.S) {
            changeSilenceLevel();
        }
        
        if (FlxG.keys.justPressed.E) {
            toggleEnhancedCapture();
        }
        
        if (FlxG.keys.justPressed.C) {
            clearVisualTargets();
            FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
        }
        
        if (FlxG.keys.justPressed.A) {
            addVisualTargets();
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
        }
        
        if (FlxG.keys.justPressed.I) {
            var info = microphone.getMicrophoneInfo();
            if (info != null) {
                trace("Microphone Info: " + haxe.Json.stringify(info));
            }
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
        }
    }
    
    override function destroy() {
        if (microphone != null) {
            microphone.dispose();
        }
        super.destroy();
    }
}
