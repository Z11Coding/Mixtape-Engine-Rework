// package yutautil.media;

// import flixel.FlxSprite;
// import flixel.FlxG;
// import flixel.group.FlxGroup;
// import flixel.text.FlxText;
// import flixel.util.FlxColor;
// import openfl.display.BitmapData;
// import openfl.utils.ByteArray;

// /**
//  * MediaCombo class that handles both camera and microphone simultaneously
//  * Provides synchronized access and combined visual effects
//  */
// class MediaCombo {
//     // Media components
//     public var camera:MediaCamera;
//     public var microphone:MediaMicrophone;
    
//     // State management
//     public var isActive:Bool = false;
//     public var cameraEnabled:Bool = true;
//     public var microphoneEnabled:Bool = true;
    
//     // Combined effects
//     private var combinedTargets:Array<{sprite:FlxSprite, mode:CombinedMode}> = [];
    
//     // Callbacks
//     public var onMediaStatusChange:String->String->Void; // (camera_status, mic_status) -> Void
//     public var onCombinedActivity:Float->Bool->Void; // (audio_volume, camera_active) -> Void
    
//     // Settings
//     public var audioThreshold:Float = 20; // Minimum audio level to trigger effects
//     public var syncFrameRate:Float = 30;
    
//     public function new(?cameraWidth:Int = 640, ?cameraHeight:Int = 480, ?cameraFps:Float = 30, ?micSampleRate:Float = 44100) {
//         // Initialize camera
//         if (cameraEnabled) {
//             camera = new MediaCamera(cameraWidth, cameraHeight, cameraFps);
//             setupCameraCallbacks();
//         }
        
//         // Initialize microphone  
//         if (microphoneEnabled) {
//             microphone = new MediaMicrophone(micSampleRate);
//             setupMicrophoneCallbacks();
//         }
        
//         trace("MediaCombo initialized");
//     }
    
//     private function setupCameraCallbacks():Void {
//         if (camera == null) return;
        
//         camera.onStatusChange = function(status:String) {
//             if (onMediaStatusChange != null) {
//                 var micStatus = microphone != null ? (microphone.isActive ? "active" : "inactive") : "disabled";
//                 onMediaStatusChange(status, micStatus);
//             }
//         };
        
//         camera.onFrameReady = function(frame:BitmapData) {
//             updateCombinedEffects();
//         };
//     }
    
//     private function setupMicrophoneCallbacks():Void {
//         if (microphone == null) return;
        
//         microphone.onStatusChange = function(status:String) {
//             if (onMediaStatusChange != null) {
//                 var camStatus = camera != null ? (camera.isActive ? "active" : "inactive") : "disabled";
//                 onMediaStatusChange(camStatus, status);
//             }
//         };
        
//         microphone.onVolumeChange = function(volume:Float) {
//             updateCombinedEffects();
            
//             if (onCombinedActivity != null) {
//                 var cameraActive = camera != null && camera.isActive;
//                 onCombinedActivity(volume, cameraActive);
//             }
//         };
//     }
    
//     /**
//      * Start both camera and microphone
//      */
//     public function start():Bool {
//         var cameraSuccess = true;
//         var microphoneSuccess = true;
        
//         if (camera != null && cameraEnabled) {
//             camera.enableFrameCapture(1 / syncFrameRate);
//             cameraSuccess = camera.start();
//         }
        
//         if (microphone != null && microphoneEnabled) {
//             microphoneSuccess = microphone.start();
//         }
        
//         isActive = cameraSuccess || microphoneSuccess;
        
//         trace("MediaCombo started - Camera: " + cameraSuccess + ", Microphone: " + microphoneSuccess);
//         return isActive;
//     }
    
//     /**
//      * Stop both camera and microphone
//      */
//     public function stop():Void {
//         if (camera != null) {
//             camera.stop();
//         }
        
//         if (microphone != null) {
//             microphone.stop();
//         }
        
//         isActive = false;
//         trace("MediaCombo stopped");
//     }
    
//     /**
//      * Add a FlxSprite to receive combined camera/microphone effects
//      */
//     public function addCombinedTarget(sprite:FlxSprite, mode:CombinedMode):Void {
//         // Check if already added
//         for (target in combinedTargets) {
//             if (target.sprite == sprite) {
//                 target.mode = mode; // Update mode if already exists
//                 return;
//             }
//         }
        
//         combinedTargets.push({sprite: sprite, mode: mode});
//     }
    
//     /**
//      * Remove a FlxSprite from combined targets
//      */
//     public function removeCombinedTarget(sprite:FlxSprite):Void {
//         combinedTargets = combinedTargets.filter(function(target) {
//             return target.sprite != sprite;
//         });
//     }
    
//     private function updateCombinedEffects():Void {
//         for (target in combinedTargets) {
//             if (target.sprite != null && target.sprite.exists) {
//                 applyCombinedEffect(target.sprite, target.mode);
//             }
//         }
//     }
    
//     private function applyCombinedEffect(sprite:FlxSprite, mode:CombinedMode):Void {
//         var audioLevel = microphone != null ? microphone.volume : 0;
//         var hasVideo = camera != null && camera.isActive;
//         var currentFrame = hasVideo ? camera.getCurrentFrame() : null;
        
//         switch (mode) {
//             case AUDIO_REACTIVE_VIDEO:
//                 // Scale video feed based on audio level
//                 if (hasVideo && currentFrame != null && audioLevel > audioThreshold) {
//                     var graphic = flixel.graphics.FlxGraphic.fromBitmapData(currentFrame, false, "combo_frame_" + Date.now().getTime());
//                     sprite.loadGraphic(graphic);
                    
//                     var scale = 1.0 + (audioLevel / 100) * 0.5;
//                     sprite.scale.set(scale, scale);
//                     sprite.alpha = Math.min(1.0, audioLevel / 50);
//                 }
                
//             case VIDEO_WITH_AUDIO_BORDER:
//                 // Show video with border that reacts to audio
//                 if (hasVideo && currentFrame != null) {
//                     var graphic = flixel.graphics.FlxGraphic.fromBitmapData(currentFrame, false, "combo_frame_" + Date.now().getTime());
//                     sprite.loadGraphic(graphic);
                    
//                     // Color border based on audio level
//                     if (audioLevel > audioThreshold) {
//                         var intensity = audioLevel / 100;
//                         sprite.color = FlxColor.fromRGBFloat(1.0, 1.0 - intensity, 1.0 - intensity);
//                     } else {
//                         sprite.color = FlxColor.WHITE;
//                     }
//                 }
                
//             case AUDIO_TRIGGERED_EFFECTS:
//                 // Apply various effects when audio threshold is reached
//                 if (audioLevel > audioThreshold) {
//                     if (hasVideo && currentFrame != null) {
//                         var graphic = flixel.graphics.FlxGraphic.fromBitmapData(currentFrame, false, "combo_frame_" + Date.now().getTime());
//                         sprite.loadGraphic(graphic);
//                     }
                    
//                     // Shake effect based on audio level
//                     sprite.x += FlxG.random.float(-audioLevel/20, audioLevel/20);
//                     sprite.y += FlxG.random.float(-audioLevel/20, audioLevel/20);
                    
//                     // Color flash
//                     sprite.color = FlxColor.fromHSB(FlxG.random.int(0, 360), 0.8, 1.0);
//                 } else {
//                     if (hasVideo && currentFrame != null) {
//                         var graphic = flixel.graphics.FlxGraphic.fromBitmapData(currentFrame, false, "combo_frame_" + Date.now().getTime());
//                         sprite.loadGraphic(graphic);
//                     }
//                     sprite.color = FlxColor.WHITE;
//                 }
                
//             case SOUND_VISUALIZATION_OVERLAY:
//                 // Show sound visualization over video
//                 if (hasVideo && currentFrame != null) {
//                     // Create a copy of the frame to modify
//                     var modifiedFrame = currentFrame.clone();
                    
//                     // Draw audio visualization lines
//                     var barCount = 20;
//                     var barWidth = modifiedFrame.width / barCount;
                    
//                     for (i in 0...barCount) {
//                         var barHeight = FlxG.random.float(audioLevel / 5, audioLevel / 2);
//                         var x = i * barWidth;
//                         var y = modifiedFrame.height - barHeight;
                        
//                         modifiedFrame.fillRect(new openfl.geom.Rectangle(x, y, barWidth - 2, barHeight), 0xFF00FF00);
//                     }
                    
//                     var graphic = flixel.graphics.FlxGraphic.fromBitmapData(modifiedFrame, false, "combo_viz_" + Date.now().getTime());
//                     sprite.loadGraphic(graphic);
//                     modifiedFrame.dispose();
//                 }
                
//             case MIRROR_WITH_EFFECTS:
//                 // Mirror camera feed with audio-reactive effects
//                 if (hasVideo && currentFrame != null) {
//                     // Create mirrored frame
//                     var mirroredFrame = new BitmapData(currentFrame.width, currentFrame.height, false, 0x000000);
//                     var matrix = new openfl.geom.Matrix();
//                     matrix.scale(-1, 1);
//                     matrix.translate(currentFrame.width, 0);
//                     mirroredFrame.draw(currentFrame, matrix);
                    
//                     var graphic = flixel.graphics.FlxGraphic.fromBitmapData(mirroredFrame, false, "combo_mirror_" + Date.now().getTime());
//                     sprite.loadGraphic(graphic);
                    
//                     // Audio reactive rotation
//                     sprite.angle = (audioLevel / 100) * 15 - 7.5; // -7.5 to 7.5 degrees
                    
//                     mirroredFrame.dispose();
//                 }
//         }
//     }
    
//     /**
//      * Create a combined effect sprite
//      */
//     public function createCombinedSprite(mode:CombinedMode):FlxSprite {
//         var sprite = new FlxSprite();
//         addCombinedTarget(sprite, mode);
//         return sprite;
//     }
    
//     /**
//      * Create a status display group
//      */
//     public function createStatusDisplay():FlxGroup {
//         var group = new FlxGroup();
        
//         var titleText = new FlxText(10, 10, 200, "MediaCombo Status", 16);
//         titleText.color = FlxColor.WHITE;
//         group.add(titleText);
        
//         var cameraText = new FlxText(10, 35, 200, "Camera: " + (camera != null && camera.isActive ? "Active" : "Inactive"), 12);
//         cameraText.color = camera != null && camera.isActive ? FlxColor.GREEN : FlxColor.RED;
//         group.add(cameraText);
        
//         var micText = new FlxText(10, 50, 200, "Microphone: " + (microphone != null && microphone.isActive ? "Active" : "Inactive"), 12);
//         micText.color = microphone != null && microphone.isActive ? FlxColor.GREEN : FlxColor.RED;
//         group.add(micText);
        
//         var audioText = new FlxText(10, 65, 200, "Audio Level: " + (microphone != null ? Std.int(microphone.volume) : 0), 12);
//         audioText.color = FlxColor.YELLOW;
//         group.add(audioText);
        
//         return group;
//     }
    
//     /**
//      * Get combined media status
//      */
//     public function getMediaStatus():Dynamic {
//         return {
//             isActive: isActive,
//             camera: camera != null ? camera.getCameraInfo() : null,
//             microphone: microphone != null ? microphone.getMicrophoneInfo() : null,
//             combinedTargetCount: combinedTargets.length
//         };
//     }
    
//     /**
//      * Set audio threshold for triggering effects
//      */
//     public function setAudioThreshold(threshold:Float):Void {
//         audioThreshold = Math.max(0, Math.min(100, threshold));
//     }
    
//     /**
//      * Enable/disable camera component
//      */
//     public function setCameraEnabled(enabled:Bool):Void {
//         cameraEnabled = enabled;
        
//         if (!enabled && camera != null) {
//             camera.stop();
//         } else if (enabled && camera == null) {
//             camera = new MediaCamera();
//             setupCameraCallbacks();
//         }
//     }
    
//     /**
//      * Enable/disable microphone component
//      */
//     public function setMicrophoneEnabled(enabled:Bool):Void {
//         microphoneEnabled = enabled;
        
//         if (!enabled && microphone != null) {
//             microphone.stop();
//         } else if (enabled && microphone == null) {
//             microphone = new MediaMicrophone();
//             setupMicrophoneCallbacks();
//         }
//     }
    
//     /**
//      * Cleanup and dispose all components
//      */
//     public function dispose():Void {
//         stop();
        
//         if (camera != null) {
//             camera.dispose();
//             camera = null;
//         }
        
//         if (microphone != null) {
//             microphone.dispose();
//             microphone = null;
//         }
        
//         combinedTargets = [];
//         onMediaStatusChange = null;
//         onCombinedActivity = null;
//     }
// }

// /**
//  * Combined effect modes for MediaCombo
//  */
// enum CombinedMode {
//     AUDIO_REACTIVE_VIDEO;       // Video scales/reacts to audio
//     VIDEO_WITH_AUDIO_BORDER;    // Video with audio-reactive border
//     AUDIO_TRIGGERED_EFFECTS;    // Various effects triggered by audio
//     SOUND_VISUALIZATION_OVERLAY; // Audio visualization over video
//     MIRROR_WITH_EFFECTS;        // Mirrored video with audio effects
// }
