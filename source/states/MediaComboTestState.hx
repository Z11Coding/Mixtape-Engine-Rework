// package states;

// import flixel.FlxG;
// import flixel.FlxSprite;
// import flixel.text.FlxText;
// import flixel.util.FlxColor;
// import flixel.group.FlxGroup;
// import backend.MusicBeatState;
// import backend.Paths;
// #if DISCORD_ALLOWED
// import backend.Discord.DiscordClient;
// #end
// import yutautil.media.MediaCombo;
// import yutautil.media.MediaCombo.CombinedMode;

// /**
//  * MediaCombo Test State - Test combined camera and microphone functionality
//  */
// class MediaComboTestState extends MusicBeatState {
//     private var mediaCombo:MediaCombo;
//     private var titleText:FlxText;
//     private var instructionText:FlxText;
//     private var statusText:FlxText;
//     private var infoText:FlxText;
    
//     // Combined effect sprites
//     private var audioReactiveSprite:FlxSprite;
//     private var audioBorderSprite:FlxSprite;
//     private var audioTriggeredSprite:FlxSprite;
//     private var visualizationSprite:FlxSprite;
//     private var mirrorEffectSprite:FlxSprite;
    
//     // Status display
//     private var statusDisplay:FlxGroup;
    
//     // Current effect mode
//     private var currentMode:CombinedMode = AUDIO_REACTIVE_VIDEO;
//     private var modeNames:Array<String> = [
//         "Audio Reactive Video",
//         "Video with Audio Border", 
//         "Audio Triggered Effects",
//         "Sound Visualization Overlay",
//         "Mirror with Effects"
//     ];
    
//     override function create() {
//         super.create();
        
//         #if DISCORD_ALLOWED
//         DiscordClient.changePresence("Testing MediaCombo", "MediaCombo Test State");
//         #end
        
//         setupBackground();
//         setupMediaCombo();
//         setupUI();
//         setupCombinedEffects();
        
//         trace("MediaComboTestState initialized");
//     }
    
//     private function setupBackground():Void {
//         var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1a1a1a);
//         bg.scrollFactor.set();
//         add(bg);
//     }
    
//     private function setupMediaCombo():Void {
//         // Initialize with moderate settings
//         mediaCombo = new MediaCombo(320, 240, 30, 44100);
        
//         // Set up callbacks
//         mediaCombo.onMediaStatusChange = function(cameraStatus:String, micStatus:String) {
//             trace("Media status - Camera: " + cameraStatus + ", Microphone: " + micStatus);
//             updateStatusDisplay();
//         };
        
//         mediaCombo.onCombinedActivity = function(audioLevel:Float, cameraActive:Bool) {
//             updateInfoDisplay(audioLevel, cameraActive);
//         };
        
//         // Set reasonable audio threshold
//         mediaCombo.setAudioThreshold(15);
//     }
    
//     private function setupUI():Void {
//         // Title
//         titleText = new FlxText(0, 20, FlxG.width, "MEDIACOMBO TEST STATE", 28);
//         titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
//         add(titleText);
        
//         // Instructions
//         instructionText = new FlxText(20, 70, 400, "", 14);
//         instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN, LEFT);
//         instructionText.text = "MediaCombo Control:\n";
//         instructionText.text += "SPACE: Start/Stop Media\n";
//         instructionText.text += "C: Toggle Camera\n";
//         instructionText.text += "M: Toggle Microphone\n";
//         instructionText.text += "1-5: Change Effect Mode\n";
//         instructionText.text += "T: Adjust Audio Threshold\n";
//         instructionText.text += "R: Reset All Effects\n";
//         instructionText.text += "I: Show Media Info\n\n";
//         instructionText.text += "Current Mode: " + modeNames[0] + "\n\n";
//         instructionText.text += "ESC: Return to Debug Menu";
//         add(instructionText);
        
//         // Status text
//         statusText = new FlxText(20, 300, 400, "", 12);
//         statusText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, LEFT);
//         add(statusText);
        
//         // Info text
//         infoText = new FlxText(20, 420, 400, "", 10);
//         infoText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.LIME, LEFT);
//         add(infoText);
        
//         // Status display from MediaCombo
//         statusDisplay = mediaCombo.createStatusDisplay();
//         statusDisplay.x = FlxG.width - 220;
//         statusDisplay.y = 70;
//         add(statusDisplay);
        
//         updateStatusDisplay();
//     }
    
//     private function setupCombinedEffects():Void {
//         var startX = 450;
//         var startY = 100;
//         var spriteWidth = 200;
//         var spriteHeight = 150;
//         var spacing = 40;
        
//         // Audio Reactive Video
//         audioReactiveSprite = new FlxSprite(startX, startY);
//         audioReactiveSprite.makeGraphic(spriteWidth, spriteHeight, FlxColor.BLACK);
//         add(audioReactiveSprite);
        
//         var reactiveLabel = new FlxText(startX, startY - 20, spriteWidth, "Audio Reactive", 10);
//         reactiveLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(reactiveLabel);
        
//         // Video with Audio Border
//         audioBorderSprite = new FlxSprite(startX + spriteWidth + spacing, startY);
//         audioBorderSprite.makeGraphic(spriteWidth, spriteHeight, FlxColor.BLACK);
//         add(audioBorderSprite);
        
//         var borderLabel = new FlxText(startX + spriteWidth + spacing, startY - 20, spriteWidth, "Audio Border", 10);
//         borderLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(borderLabel);
        
//         // Audio Triggered Effects
//         audioTriggeredSprite = new FlxSprite(startX, startY + spriteHeight + spacing);
//         audioTriggeredSprite.makeGraphic(spriteWidth, spriteHeight, FlxColor.BLACK);
//         add(audioTriggeredSprite);
        
//         var triggeredLabel = new FlxText(startX, startY + spriteHeight + spacing - 20, spriteWidth, "Audio Triggered", 10);
//         triggeredLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(triggeredLabel);
        
//         // Sound Visualization Overlay
//         visualizationSprite = new FlxSprite(startX + spriteWidth + spacing, startY + spriteHeight + spacing);
//         visualizationSprite.makeGraphic(spriteWidth, spriteHeight, FlxColor.BLACK);
//         add(visualizationSprite);
        
//         var vizLabel = new FlxText(startX + spriteWidth + spacing, startY + spriteHeight + spacing - 20, spriteWidth, "Visualization", 10);
//         vizLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(vizLabel);
        
//         // Mirror with Effects (centered below)
//         mirrorEffectSprite = new FlxSprite(startX + (spriteWidth + spacing) / 2, startY + (spriteHeight + spacing) * 2);
//         mirrorEffectSprite.makeGraphic(spriteWidth, spriteHeight, FlxColor.BLACK);
//         add(mirrorEffectSprite);
        
//         var mirrorLabel = new FlxText(startX + (spriteWidth + spacing) / 2, startY + (spriteHeight + spacing) * 2 - 20, spriteWidth, "Mirror Effects", 10);
//         mirrorLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(mirrorLabel);
        
//         // Add combined targets with different modes
//         setupCombinedTargets();
//     }
    
//     private function setupCombinedTargets():Void {
//         if (mediaCombo == null) return;
        
//         mediaCombo.addCombinedTarget(audioReactiveSprite, AUDIO_REACTIVE_VIDEO);
//         mediaCombo.addCombinedTarget(audioBorderSprite, VIDEO_WITH_AUDIO_BORDER);
//         mediaCombo.addCombinedTarget(audioTriggeredSprite, AUDIO_TRIGGERED_EFFECTS);
//         mediaCombo.addCombinedTarget(visualizationSprite, SOUND_VISUALIZATION_OVERLAY);
//         mediaCombo.addCombinedTarget(mirrorEffectSprite, MIRROR_WITH_EFFECTS);
//     }
    
//     private function clearCombinedTargets():Void {
//         if (mediaCombo == null) return;
        
//         mediaCombo.removeCombinedTarget(audioReactiveSprite);
//         mediaCombo.removeCombinedTarget(audioBorderSprite);
//         mediaCombo.removeCombinedTarget(audioTriggeredSprite);
//         mediaCombo.removeCombinedTarget(visualizationSprite);
//         mediaCombo.removeCombinedTarget(mirrorEffectSprite);
        
//         // Reset sprites
//         audioReactiveSprite.makeGraphic(200, 150, FlxColor.BLACK);
//         audioBorderSprite.makeGraphic(200, 150, FlxColor.BLACK);
//         audioTriggeredSprite.makeGraphic(200, 150, FlxColor.BLACK);
//         visualizationSprite.makeGraphic(200, 150, FlxColor.BLACK);
//         mirrorEffectSprite.makeGraphic(200, 150, FlxColor.BLACK);
//     }
    
//     private function updateStatusDisplay():Void {
//         if (mediaCombo == null) return;
        
//         var status = mediaCombo.getMediaStatus();
//         var statusStr = "";
//         statusStr += "MediaCombo Status:\n";
//         statusStr += "Active: " + (status.isActive ? "Yes" : "No") + "\n";
//         statusStr += "Camera Enabled: " + (mediaCombo.cameraEnabled ? "Yes" : "No") + "\n";
//         statusStr += "Microphone Enabled: " + (mediaCombo.microphoneEnabled ? "Yes" : "No") + "\n";
//         statusStr += "Audio Threshold: " + mediaCombo.audioThreshold + "%\n";
//         statusStr += "Combined Targets: " + status.combinedTargetCount + "\n";
        
//         if (status.camera != null) {
//             statusStr += "\nCamera:\n";
//             statusStr += "  Active: " + (status.camera.isActive ? "Yes" : "No") + "\n";
//             statusStr += "  Resolution: " + status.camera.width + "x" + status.camera.height + "\n";
//         }
        
//         if (status.microphone != null) {
//             statusStr += "\nMicrophone:\n";
//             statusStr += "  Active: " + (status.microphone.isActive ? "Yes" : "No") + "\n";
//             statusStr += "  Gain: " + status.microphone.gain + "%\n";
//         }
        
//         statusText.text = statusStr;
//     }
    
//     private function updateInfoDisplay(audioLevel:Float, cameraActive:Bool):Void {
//         var infoStr = "";
//         infoStr += "Real-time Info:\n";
//         infoStr += "Audio Level: " + Std.int(audioLevel) + "%\n";
//         infoStr += "Camera Active: " + (cameraActive ? "Yes" : "No") + "\n";
//         infoStr += "Audio Above Threshold: " + (audioLevel > mediaCombo.audioThreshold ? "Yes" : "No") + "\n";
        
//         if (mediaCombo.microphone != null) {
//             var levels = mediaCombo.microphone.getAudioLevels();
//             infoStr += "Peak Volume: " + Std.int(levels.peakVolume) + "%\n";
//             infoStr += "Average Volume: " + Std.int(levels.averageVolume) + "%\n";
//         }
        
//         infoText.text = infoStr;
//     }
    
//     private function startStopMedia():Void {
//         if (mediaCombo == null) return;
        
//         if (mediaCombo.isActive) {
//             mediaCombo.stop();
//             FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
//         } else {
//             if (mediaCombo.start()) {
//                 FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
//             } else {
//                 FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
//             }
//         }
        
//         updateStatusDisplay();
//     }
    
//     private function toggleCamera():Void {
//         if (mediaCombo == null) return;
        
//         mediaCombo.setCameraEnabled(!mediaCombo.cameraEnabled);
//         updateStatusDisplay();
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
//     }
    
//     private function toggleMicrophone():Void {
//         if (mediaCombo == null) return;
        
//         mediaCombo.setMicrophoneEnabled(!mediaCombo.microphoneEnabled);
//         updateStatusDisplay();
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
//     }
    
//     private function changeEffectMode(mode:Int):Void {
//         if (mode < 0 || mode >= modeNames.length) return;
        
//         currentMode = switch(mode) {
//             case 0: AUDIO_REACTIVE_VIDEO;
//             case 1: VIDEO_WITH_AUDIO_BORDER;
//             case 2: AUDIO_TRIGGERED_EFFECTS;
//             case 3: SOUND_VISUALIZATION_OVERLAY;
//             case 4: MIRROR_WITH_EFFECTS;
//             default: AUDIO_REACTIVE_VIDEO;
//         };
        
//         // Update instruction text to show current mode
//         var lines = instructionText.text.split("\n");
//         for (i in 0...lines.length) {
//             if (lines[i].indexOf("Current Mode:") != -1) {
//                 lines[i] = "Current Mode: " + modeNames[mode];
//                 break;
//             }
//         }
//         instructionText.text = lines.join("\n");
        
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
//     }
    
//     private function adjustAudioThreshold():Void {
//         if (mediaCombo == null) return;
        
//         var currentThreshold = mediaCombo.audioThreshold;
//         var newThreshold:Float;
        
//         if (currentThreshold <= 10) {
//             newThreshold = 20;
//         } else if (currentThreshold <= 20) {
//             newThreshold = 30;
//         } else if (currentThreshold <= 30) {
//             newThreshold = 50;
//         } else {
//             newThreshold = 10;
//         }
        
//         mediaCombo.setAudioThreshold(newThreshold);
//         updateStatusDisplay();
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
//     }
    
//     private function resetAllEffects():Void {
//         clearCombinedTargets();
//         setupCombinedTargets();
//         FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
//     }
    
//     private function showMediaInfo():Void {
//         if (mediaCombo == null) return;
        
//         var status = mediaCombo.getMediaStatus();
//         trace("MediaCombo Status: " + haxe.Json.stringify(status));
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
//     }
    
//     override function update(elapsed:Float) {
//         super.update(elapsed);
        
//         // Handle input
//         if (controls.BACK) {
//             if (mediaCombo != null) {
//                 mediaCombo.dispose();
//             }
//             MusicBeatState.switchState(new DebugStateMenu());
//         }
        
//         // MediaCombo controls
//         if (FlxG.keys.justPressed.SPACE) {
//             startStopMedia();
//         }
        
//         if (FlxG.keys.justPressed.C) {
//             toggleCamera();
//         }
        
//         if (FlxG.keys.justPressed.M) {
//             toggleMicrophone();
//         }
        
//         if (FlxG.keys.justPressed.ONE) {
//             changeEffectMode(0);
//         }
        
//         if (FlxG.keys.justPressed.TWO) {
//             changeEffectMode(1);
//         }
        
//         if (FlxG.keys.justPressed.THREE) {
//             changeEffectMode(2);
//         }
        
//         if (FlxG.keys.justPressed.FOUR) {
//             changeEffectMode(3);
//         }
        
//         if (FlxG.keys.justPressed.FIVE) {
//             changeEffectMode(4);
//         }
        
//         if (FlxG.keys.justPressed.T) {
//             adjustAudioThreshold();
//         }
        
//         if (FlxG.keys.justPressed.R) {
//             resetAllEffects();
//         }
        
//         if (FlxG.keys.justPressed.I) {
//             showMediaInfo();
//         }
//     }
    
//     override function destroy() {
//         if (mediaCombo != null) {
//             mediaCombo.dispose();
//         }
//         super.destroy();
//     }
// }
