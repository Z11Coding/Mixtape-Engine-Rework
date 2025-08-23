// package states;

// import flixel.FlxG;
// import flixel.FlxSprite;
// import flixel.text.FlxText;
// import flixel.util.FlxColor;
// import flixel.group.FlxGroup;
// import backend.MusicBeatState;
// import backend.Paths;
// import backend.ClientPrefs;
// #if DISCORD_ALLOWED
// import backend.Discord.DiscordClient;
// #end
// import yutautil.media.MediaCamera;

// /**
//  * Camera Test State - Test camera functionality and visual transmission
//  */
// class CameraTestState extends MusicBeatState {
//     private var camera:MediaCamera;
//     private var titleText:FlxText;
//     private var instructionText:FlxText;
//     private var statusText:FlxText;
//     private var infoText:FlxText;
    
//     // Camera display sprites
//     private var cameraFeedSprite:FlxSprite;
//     private var previewSprite1:FlxSprite;
//     private var previewSprite2:FlxSprite;
    
//     // UI elements
//     private var statusGroup:FlxGroup;
    
//     override function create() {
//         super.create();
        
//         #if DISCORD_ALLOWED
//         DiscordClient.changePresence("Testing Camera", "Camera Test State");
//         #end
        
//         setupBackground();
//         setupCamera();
//         setupUI();
//         setupCameraDisplay();
        
//         trace("CameraTestState initialized");
//     }
    
//     private function setupBackground():Void {
//         var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1a1a1a);
//         bg.scrollFactor.set();
//         add(bg);
//     }
    
//     private function setupCamera():Void {
//         camera = new MediaCamera(320, 240, 30);
        
//         // Set up callbacks
//         camera.onStatusChange = function(status:String) {
//             trace("Camera status changed: " + status);
//             updateStatusDisplay();
//         };
        
//         camera.onActivityChange = function(active:Bool) {
//             trace("Camera activity: " + active);
//             updateStatusDisplay();
//         };
        
//         camera.onFrameReady = function(frame) {
//             // Frame ready callback - transmission happens automatically
//             updateInfoDisplay();
//         };
//     }
    
//     private function setupUI():Void {
//         // Title
//         titleText = new FlxText(0, 20, FlxG.width, "CAMERA TEST STATE", 28);
//         titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
//         add(titleText);
        
//         // Instructions
//         instructionText = new FlxText(20, 70, FlxG.width - 40, "", 14);
//         instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN, LEFT);
//         instructionText.text = "Camera Control:\n";
//         instructionText.text += "SPACE: Start/Stop Camera\n";
//         instructionText.text += "F: Toggle Frame Capture\n";
//         instructionText.text += "1-4: Set Quality (25%, 50%, 75%, 100%)\n";
//         instructionText.text += "R: Change Resolution\n";
//         instructionText.text += "C: Clear Transmission Targets\n";
//         instructionText.text += "A: Add Transmission Targets\n";
//         instructionText.text += "I: Show Camera Info\n\n";
//         instructionText.text += "ESC: Return to Debug Menu";
//         add(instructionText);
        
//         // Status group
//         statusGroup = new FlxGroup();
//         add(statusGroup);
        
//         setupStatusDisplay();
//         updateStatusDisplay();
//     }
    
//     private function setupStatusDisplay():Void {
//         // Status text
//         statusText = new FlxText(20, 240, 300, "", 12);
//         statusText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, LEFT);
//         statusGroup.add(statusText);
        
//         // Info text
//         infoText = new FlxText(20, 320, 300, "", 10);
//         infoText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.LIME, LEFT);
//         statusGroup.add(infoText);
//     }
    
//     private function setupCameraDisplay():Void {
//         // Main camera feed display
//         cameraFeedSprite = new FlxSprite(350, 100);
//         cameraFeedSprite.makeGraphic(320, 240, FlxColor.BLACK);
//         add(cameraFeedSprite);
        
//         var feedLabel = new FlxText(350, 80, 320, "Main Camera Feed", 12);
//         feedLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
//         add(feedLabel);
        
//         // Preview sprites for transmission testing
//         previewSprite1 = new FlxSprite(700, 100);
//         previewSprite1.makeGraphic(160, 120, FlxColor.GRAY);
//         add(previewSprite1);
        
//         var preview1Label = new FlxText(700, 80, 160, "Preview 1", 10);
//         preview1Label.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(preview1Label);
        
//         previewSprite2 = new FlxSprite(700, 240);
//         previewSprite2.makeGraphic(160, 120, FlxColor.GRAY);
//         add(previewSprite2);
        
//         var preview2Label = new FlxText(700, 220, 160, "Preview 2", 10);
//         preview2Label.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER);
//         add(preview2Label);
        
//         // Add transmission targets
//         addTransmissionTargets();
//     }
    
//     private function addTransmissionTargets():Void {
//         if (camera != null) {
//             camera.addTransmissionTarget(cameraFeedSprite);
//             camera.addTransmissionTarget(previewSprite1);
//             camera.addTransmissionTarget(previewSprite2);
//         }
//     }
    
//     private function clearTransmissionTargets():Void {
//         if (camera != null) {
//             camera.removeTransmissionTarget(cameraFeedSprite);
//             camera.removeTransmissionTarget(previewSprite1);
//             camera.removeTransmissionTarget(previewSprite2);
//         }
        
//         // Reset sprites to default
//         cameraFeedSprite.makeGraphic(320, 240, FlxColor.BLACK);
//         previewSprite1.makeGraphic(160, 120, FlxColor.GRAY);
//         previewSprite2.makeGraphic(160, 120, FlxColor.GRAY);
//     }
    
//     private function updateStatusDisplay():Void {
//         if (camera == null) return;
        
//         var status = "";
//         status += "Camera Status:\n";
//         status += "Available: " + (camera.isAvailable ? "Yes" : "No") + "\n";
//         status += "Active: " + (camera.isActive ? "Yes" : "No") + "\n";
//         status += "Frame Capture: " + (camera.captureFrames ? "Enabled" : "Disabled") + "\n";
//         status += "Resolution: " + camera.width + "x" + camera.height + "\n";
//         status += "FPS: " + camera.fps + "\n";
//         status += "Quality: " + camera.quality + "%\n";
        
//         statusText.text = status;
//     }
    
//     private function updateInfoDisplay():Void {
//         if (camera == null) return;
        
//         var info = camera.getCameraInfo();
//         if (info != null) {
//             var infoStr = "";
//             infoStr += "Camera Info:\n";
//             infoStr += "Name: " + (info.name != null ? info.name : "Unknown") + "\n";
//             infoStr += "Current FPS: " + (info.currentFPS != null ? info.currentFPS : "N/A") + "\n";
//             infoStr += "Muted: " + (info.muted ? "Yes" : "No") + "\n";
            
//             infoText.text = infoStr;
//         }
//     }
    
//     private function startStopCamera():Void {
//         if (camera == null) return;
        
//         if (camera.isActive) {
//             camera.stop();
//             FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
//         } else {
//             if (camera.start()) {
//                 FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
//             } else {
//                 FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
//             }
//         }
        
//         updateStatusDisplay();
//     }
    
//     private function toggleFrameCapture():Void {
//         if (camera == null) return;
        
//         if (camera.captureFrames) {
//             camera.disableFrameCapture();
//         } else {
//             camera.enableFrameCapture();
//         }
        
//         updateStatusDisplay();
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
//     }
    
//     private function setQuality(quality:Int):Void {
//         if (camera == null) return;
        
//         camera.setQuality(quality);
//         updateStatusDisplay();
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
//     }
    
//     private function changeResolution():Void {
//         if (camera == null) return;
        
//         // Cycle through common resolutions
//         if (camera.width == 320 && camera.height == 240) {
//             camera.setResolution(640, 480);
//         } else if (camera.width == 640 && camera.height == 480) {
//             camera.setResolution(800, 600);
//         } else if (camera.width == 800 && camera.height == 600) {
//             camera.setResolution(1280, 720);
//         } else {
//             camera.setResolution(320, 240);
//         }
        
//         // Recreate display sprites with new resolution
//         var scale = Math.min(320 / camera.width, 240 / camera.height);
//         cameraFeedSprite.makeGraphic(Std.int(camera.width * scale), Std.int(camera.height * scale), FlxColor.BLACK);
        
//         updateStatusDisplay();
//         FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
//     }
    
//     override function update(elapsed:Float) {
//         super.update(elapsed);
        
//         // Handle input
//         if (controls.BACK) {
//             if (camera != null) {
//                 camera.dispose();
//             }
//             MusicBeatState.switchState(new DebugStateMenu());
//         }
        
//         // Camera controls
//         if (FlxG.keys.justPressed.SPACE) {
//             startStopCamera();
//         }
        
//         if (FlxG.keys.justPressed.F) {
//             toggleFrameCapture();
//         }
        
//         if (FlxG.keys.justPressed.ONE) {
//             setQuality(25);
//         }
        
//         if (FlxG.keys.justPressed.TWO) {
//             setQuality(50);
//         }
        
//         if (FlxG.keys.justPressed.THREE) {
//             setQuality(75);
//         }
        
//         if (FlxG.keys.justPressed.FOUR) {
//             setQuality(100);
//         }
        
//         if (FlxG.keys.justPressed.R) {
//             changeResolution();
//         }
        
//         if (FlxG.keys.justPressed.C) {
//             clearTransmissionTargets();
//             FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
//         }
        
//         if (FlxG.keys.justPressed.A) {
//             addTransmissionTargets();
//             FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
//         }
        
//         if (FlxG.keys.justPressed.I) {
//             updateInfoDisplay();
//             FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
//         }
//     }
    
//     override function destroy() {
//         if (camera != null) {
//             camera.dispose();
//         }
//         super.destroy();
//     }
// }
