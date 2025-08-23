package yutautil.media;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import openfl.media.Microphone as OpenFLMicrophone;
import openfl.media.SoundTransform;
import openfl.events.StatusEvent;
import openfl.events.SampleDataEvent;
import openfl.events.ActivityEvent;
import openfl.utils.ByteArray;
import haxe.Timer;

/**
 * MediaMicrophone class for capturing and managing microphone input
 * Provides different ways to capture and transmit audio data to Flx objects
 */
class MediaMicrophone {
    // Microphone properties
    public var isActive:Bool = false;
    public var isAvailable:Bool = false;
    public var sampleRate:Float = 44100;
    public var gain:Float = 50; // 0-100
    public var silenceLevel:Float = 10; // 0-100
    public var silenceTimeout:Int = 4000; // milliseconds
    
    // OpenFL microphone object
    private var microphone:OpenFLMicrophone;
    
    // Audio analysis
    public var volume:Float = 0;
    public var averageVolume:Float = 0;
    public var peakVolume:Float = 0;
    private var volumeHistory:Array<Float> = [];
    private var maxHistorySize:Int = 30;
    
    // Callback functions
    public var onActivityChange:Bool->Void;
    public var onStatusChange:String->Void;
    public var onSampleData:ByteArray->Void;
    public var onVolumeChange:Float->Void;
    
    // Transmission targets for visual feedback
    private var visualTargets:Array<{sprite:FlxSprite, mode:VisualMode}> = [];
    
    // Update timer for visual feedback
    private var updateTimer:Timer;
    private var updateInterval:Float = 1/60; // 60 fps default
    
    public function new(?sampleRate:Float = 44100, ?gain:Float = 50) {
        this.sampleRate = sampleRate;
        this.gain = gain;
        
        initializeMicrophone();
    }
    
    private function initializeMicrophone():Void {
        try {
            // Get default microphone
            microphone = OpenFLMicrophone.getMicrophone();
            
            if (microphone != null) {
                isAvailable = true;
                
                // Set microphone properties
                microphone.rate = Std.int(sampleRate / 1000); // Convert to kHz
                microphone.gain = gain;
                microphone.setSilenceLevel(silenceLevel, silenceTimeout);
                
                // Set up event listeners
                microphone.addEventListener(StatusEvent.STATUS, onMicrophoneStatus);
                microphone.addEventListener(ActivityEvent.ACTIVITY, onMicrophoneActivity);
                microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onMicrophoneSampleData);
                
                trace("MediaMicrophone initialized successfully");
            } else {
                trace("No microphone available");
                isAvailable = false;
            }
        } catch (e:Dynamic) {
            trace("Error initializing microphone: " + e);
            isAvailable = false;
        }
    }
    
    private function onMicrophoneStatus(event:StatusEvent):Void {
        trace("Microphone status: " + event.code + " - " + event.level);
        
        switch (event.code) {
            case "Microphone.Muted":
                isActive = false;
                if (onStatusChange != null) onStatusChange("muted");
                
            case "Microphone.Unmuted":
                isActive = true;
                if (onStatusChange != null) onStatusChange("unmuted");
                
            default:
                if (onStatusChange != null) onStatusChange(event.code);
        }
    }
    
    private function onMicrophoneActivity(event:ActivityEvent):Void {
        if (onActivityChange != null) {
            onActivityChange(event.activating);
        }
    }
    
    private function onMicrophoneSampleData(event:SampleDataEvent):Void {
        if (onSampleData != null) {
            onSampleData(event.data);
        }
        
        // Analyze audio data for volume levels
        analyzeAudioData(event.data);
    }
    
    private function analyzeAudioData(data:ByteArray):Void {
        if (data == null || data.length == 0) return;
        
        data.position = 0;
        var sum:Float = 0;
        var samples:Int = 0;
        var peak:Float = 0;
        
        // Read samples and calculate volume metrics
        while (data.bytesAvailable >= 4) { // 4 bytes per float
            var sample:Float = Math.abs(data.readFloat());
            sum += sample;
            samples++;
            
            if (sample > peak) {
                peak = sample;
            }
        }
        
        if (samples > 0) {
            // Calculate current volume (0-100 scale)
            volume = Math.min(100, (sum / samples) * 1000);
            peakVolume = Math.min(100, peak * 1000);
            
            // Update volume history
            volumeHistory.push(volume);
            if (volumeHistory.length > maxHistorySize) {
                volumeHistory.shift();
            }
            
            // Calculate average volume
            var historySum:Float = 0;
            for (v in volumeHistory) {
                historySum += v;
            }
            averageVolume = historySum / volumeHistory.length;
            
            // Trigger volume change callback
            if (onVolumeChange != null) {
                onVolumeChange(volume);
            }
            
            // Update visual targets
            updateVisualTargets();
        }
    }
    
    /**
     * Start microphone capture
     */
    public function start():Bool {
        if (!isAvailable || microphone == null) {
            trace("Microphone not available");
            return false;
        }
        
        try {
            isActive = true;
            startVisualUpdates();
            
            trace("MediaMicrophone started successfully");
            return true;
        } catch (e:Dynamic) {
            trace("Error starting microphone: " + e);
            return false;
        }
    }
    
    /**
     * Stop microphone capture
     */
    public function stop():Void {
        if (microphone != null) {
            isActive = false;
            
            if (updateTimer != null) {
                updateTimer.stop();
                updateTimer = null;
            }
            
            trace("MediaMicrophone stopped");
        }
    }
    
    private function startVisualUpdates():Void {
        if (updateTimer != null) {
            updateTimer.stop();
        }
        
        updateTimer = new Timer(Std.int(updateInterval * 1000));
        updateTimer.run = updateVisualTargets;
    }
    
    private function updateVisualTargets():Void {
        for (target in visualTargets) {
            if (target.sprite != null && target.sprite.exists) {
                updateVisualTarget(target.sprite, target.mode);
            }
        }
    }
    
    private function updateVisualTarget(sprite:FlxSprite, mode:VisualMode):Void {
        switch (mode) {
            case VOLUME_BAR:
                // Scale sprite height based on volume
                sprite.scale.y = FlxMath.lerp(0.1, 1.0, volume / 100);
                
            case VOLUME_WIDTH:
                // Scale sprite width based on volume
                sprite.scale.x = FlxMath.lerp(0.1, 1.0, volume / 100);
                
            case COLOR_INTENSITY:
                // Change sprite alpha based on volume
                sprite.alpha = FlxMath.lerp(0.2, 1.0, volume / 100);
                
            case PEAK_FLASH:
                // Flash sprite when peak volume is detected
                if (peakVolume > 80) {
                    sprite.alpha = 1.0;
                    sprite.color = 0xFF00FF00; // Green flash
                } else if (volume > 50) {
                    sprite.alpha = FlxMath.lerp(0.5, 1.0, volume / 100);
                    sprite.color = 0xFFFFFF00; // Yellow
                } else {
                    sprite.alpha = 0.5;
                    sprite.color = 0xFFFFFFFF; // White
                }
                
            case WAVE_SIMULATION:
                // Simulate wave motion based on volume
                sprite.scale.x = 1.0 + (volume / 100) * 0.5;
                sprite.scale.y = 1.0 + (Math.sin(Date.now().getTime() / 100) * volume / 200);
        }
    }
    
    /**
     * Add a FlxSprite to receive visual feedback from microphone data
     */
    public function addVisualTarget(sprite:FlxSprite, mode:VisualMode = VOLUME_BAR):Void {
        // Check if already added
        for (target in visualTargets) {
            if (target.sprite == sprite) {
                target.mode = mode; // Update mode if already exists
                return;
            }
        }
        
        visualTargets.push({sprite: sprite, mode: mode});
    }
    
    /**
     * Remove a FlxSprite from visual targets
     */
    public function removeVisualTarget(sprite:FlxSprite):Void {
        visualTargets = visualTargets.filter(function(target) {
            return target.sprite != sprite;
        });
    }
    
    /**
     * Create a FlxSprite that responds to microphone input
     */
    public function createVisualizerSprite(mode:VisualMode = VOLUME_BAR):FlxSprite {
        var sprite = new FlxSprite();
        sprite.makeGraphic(50, 100, 0xFF00FF00); // Default green rectangle
        addVisualTarget(sprite, mode);
        return sprite;
    }
    
    /**
     * Set microphone gain (0-100)
     */
    public function setGain(gain:Float):Void {
        this.gain = Math.max(0, Math.min(100, gain));
        if (microphone != null) {
            microphone.gain = this.gain;
        }
    }
    
    /**
     * Set silence level and timeout
     */
    public function setSilenceLevel(level:Float, timeout:Int):Void {
        this.silenceLevel = Math.max(0, Math.min(100, level));
        this.silenceTimeout = timeout;
        
        if (microphone != null) {
            microphone.setSilenceLevel(this.silenceLevel, this.silenceTimeout);
        }
    }
    
    /**
     * Get current audio levels
     */
    public function getAudioLevels():Dynamic {
        return {
            volume: volume,
            averageVolume: averageVolume,
            peakVolume: peakVolume,
            activityLevel: microphone != null ? microphone.activityLevel : 0,
            isActive: isActive
        };
    }
    
    /**
     * Get microphone info
     */
    public function getMicrophoneInfo():Dynamic {
        if (microphone == null) return null;
        
        return {
            name: microphone.name,
            rate: microphone.rate,
            gain: microphone.gain,
            silenceLevel: microphone.silenceLevel,
            silenceTimeout: microphone.silenceTimeout,
            isActive: isActive,
            isAvailable: isAvailable,
            muted: microphone.muted,
            activityLevel: microphone.activityLevel
        };
    }
    
    /**
     * Enable/disable enhanced sample data capture
     */
    public function setEnhancedCapture(enabled:Bool):Void {
        if (microphone == null) return;
        
        if (enabled) {
            microphone.setLoopBack(true);
            microphone.setUseEchoSuppression(true);
        } else {
            microphone.setLoopBack(false);
            microphone.setUseEchoSuppression(false);
        }
    }
    
    /**
     * Cleanup and dispose
     */
    public function dispose():Void {
        stop();
        
        if (microphone != null) {
            microphone.removeEventListener(StatusEvent.STATUS, onMicrophoneStatus);
            microphone.removeEventListener(ActivityEvent.ACTIVITY, onMicrophoneActivity);
            microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onMicrophoneSampleData);
        }
        
        visualTargets = [];
        volumeHistory = [];
        microphone = null;
        
        onActivityChange = null;
        onStatusChange = null;
        onSampleData = null;
        onVolumeChange = null;
    }
}

/**
 * Visual modes for microphone feedback
 */
enum VisualMode {
    VOLUME_BAR;     // Scale height based on volume
    VOLUME_WIDTH;   // Scale width based on volume
    COLOR_INTENSITY; // Change alpha/opacity based on volume
    PEAK_FLASH;     // Flash colors based on peak detection
    WAVE_SIMULATION; // Simulate wave motion
}
