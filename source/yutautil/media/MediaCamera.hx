// package yutautil.media;

// import flixel.FlxSprite;
// import flixel.FlxG;
// import flixel.math.FlxRect;
// import flixel.graphics.FlxGraphic;
// import openfl.display.BitmapData;
// import openfl.media.Video;
// import openfl.net.NetConnection;
// import openfl.net.NetStream;
// // import openfl.media.Camera.js as OpenFLCamera;
// import openfl.events.StatusEvent;
// import openfl.events.ActivityEvent;
// import haxe.Timer;

// typedef OpenFLCamera = Cam.Camera;

// /**
//  * MediaCamera class for capturing and managing camera input
//  * Provides different ways to capture and transmit camera data to Flx objects
//  */
// class MediaCamera {
//     // Camera properties
//     public var isActive:Bool = false;
//     public var isAvailable:Bool = false;
//     public var width:Int = 640;
//     public var height:Int = 480;
//     public var fps:Float = 30;
//     public var quality:Int = 0; // 0-100, where 0 is lowest quality
    
//     // OpenFL camera objects
//     private var camera:OpenFLCamera;
//     private var video:Video;
//     private var bitmapData:BitmapData;
    
//     // Callback functions
//     public var onActivityChange:Bool->Void;
//     public var onStatusChange:String->Void;
//     public var onFrameReady:BitmapData->Void;
    
//     // Frame capture settings
//     public var captureFrames:Bool = false;
//     private var captureTimer:Timer;
//     private var captureInterval:Float = 1/30; // 30 fps default
    
//     // Transmission targets
//     private var transmissionTargets:Array<FlxSprite> = [];
    
//     public function new(?width:Int = 640, ?height:Int = 480, ?fps:Float = 30) {
//         this.width = width;
//         this.height = height;
//         this.fps = fps;
        
//         initializeCamera();
//     }
    
//     private function initializeCamera():Void {
//         try {
//             // Get default camera
//             camera = OpenFLCamera.getCamera();
            
//             if (camera != null) {
//                 isAvailable = true;
                
//                 // Set camera properties
//                 camera.setMode(width, height, fps);
//                 camera.setQuality(0, quality);
                
//                 // Set up event listeners
//                 camera.addEventListener(StatusEvent.STATUS, onCameraStatus);
//                 camera.addEventListener(ActivityEvent.ACTIVITY, onCameraActivity);
                
//                 // Initialize video object for display
//                 video = new Video(width, height);
//                 bitmapData = new BitmapData(width, height, false, 0x000000);
                
//                 trace("MediaCamera initialized successfully");
//             } else {
//                 trace("No camera available");
//                 isAvailable = false;
//             }
//         } catch (e:Dynamic) {
//             trace("Error initializing camera: " + e);
//             isAvailable = false;
//         }
//     }
    
//     private function onCameraStatus(event:StatusEvent):Void {
//         trace("Camera status: " + event.code + " - " + event.level);
        
//         switch (event.code) {
//             case "Camera.Muted":
//                 isActive = false;
//                 if (onStatusChange != null) onStatusChange("muted");
                
//             case "Camera.Unmuted":
//                 isActive = true;
//                 if (onStatusChange != null) onStatusChange("unmuted");
                
//             default:
//                 if (onStatusChange != null) onStatusChange(event.code);
//         }
//     }
    
//     private function onCameraActivity(event:ActivityEvent):Void {
//         if (onActivityChange != null) {
//             onActivityChange(event.activating);
//         }
//     }
    
//     /**
//      * Start camera capture
//      */
//     public function start():Bool {
//         if (!isAvailable || camera == null) {
//             trace("Camera not available");
//             return false;
//         }
        
//         try {
//             video.attachCamera(camera);
//             isActive = true;
            
//             if (captureFrames) {
//                 startFrameCapture();
//             }
            
//             trace("MediaCamera started successfully");
//             return true;
//         } catch (e:Dynamic) {
//             trace("Error starting camera: " + e);
//             return false;
//         }
//     }
    
//     /**
//      * Stop camera capture
//      */
//     public function stop():Void {
//         if (camera != null) {
//             video.attachCamera(null);
//             isActive = false;
            
//             if (captureTimer != null) {
//                 captureTimer.stop();
//                 captureTimer = null;
//             }
            
//             trace("MediaCamera stopped");
//         }
//     }
    
//     /**
//      * Enable frame capture for transmission to Flx objects
//      */
//     public function enableFrameCapture(?interval:Float = 1/30):Void {
//         captureFrames = true;
//         captureInterval = interval;
        
//         if (isActive) {
//             startFrameCapture();
//         }
//     }
    
//     /**
//      * Disable frame capture
//      */
//     public function disableFrameCapture():Void {
//         captureFrames = false;
        
//         if (captureTimer != null) {
//             captureTimer.stop();
//             captureTimer = null;
//         }
//     }
    
//     private function startFrameCapture():Void {
//         if (captureTimer != null) {
//             captureTimer.stop();
//         }
        
//         captureTimer = new Timer(Std.int(captureInterval * 1000));
//         captureTimer.run = captureFrame;
//     }
    
//     private function captureFrame():Void {
//         if (!isActive || video == null) return;
        
//         try {
//             // Draw video frame to bitmap data
//             bitmapData.draw(video);
            
//             // Notify frame ready callback
//             if (onFrameReady != null) {
//                 onFrameReady(bitmapData);
//             }
            
//             // Update transmission targets
//             updateTransmissionTargets();
            
//         } catch (e:Dynamic) {
//             trace("Error capturing frame: " + e);
//         }
//     }
    
//     /**
//      * Add a FlxSprite to receive camera data
//      */
//     public function addTransmissionTarget(sprite:FlxSprite):Void {
//         if (transmissionTargets.indexOf(sprite) == -1) {
//             transmissionTargets.push(sprite);
//         }
//     }
    
//     /**
//      * Remove a FlxSprite from transmission targets
//      */
//     public function removeTransmissionTarget(sprite:FlxSprite):Void {
//         transmissionTargets.remove(sprite);
//     }
    
//     private function updateTransmissionTargets():Void {
//         if (bitmapData == null) return;
        
//         for (target in transmissionTargets) {
//             if (target != null && target.exists) {
//                 // Create or update the graphic for the sprite
//                 var graphic = FlxGraphic.fromBitmapData(bitmapData.clone(), false, "camera_frame_" + Date.now().getTime());
//                 target.loadGraphic(graphic);
//             }
//         }
//     }
    
//     /**
//      * Get current frame as BitmapData
//      */
//     public function getCurrentFrame():BitmapData {
//         if (bitmapData != null) {
//             return bitmapData.clone();
//         }
//         return null;
//     }
    
//     /**
//      * Create a FlxSprite with current camera feed
//      */
//     public function createCameraSprite():FlxSprite {
//         var sprite = new FlxSprite();
//         addTransmissionTarget(sprite);
//         return sprite;
//     }
    
//     /**
//      * Set camera quality (0-100)
//      */
//     public function setQuality(quality:Int):Void {
//         this.quality = Math.floor(Math.max(0, Math.min(100, quality)));
//         if (camera != null) {
//             camera.setQuality(0, this.quality);
//         }
//     }
    
//     /**
//      * Set camera resolution
//      */
//     public function setResolution(width:Int, height:Int):Void {
//         this.width = width;
//         this.height = height;
        
//         if (camera != null) {
//             camera.setMode(width, height, fps);
//         }
        
//         if (video != null) {
//             video.width = width;
//             video.height = height;
//         }
        
//         if (bitmapData != null) {
//             bitmapData.dispose();
//             bitmapData = new BitmapData(width, height, false, 0x000000);
//         }
//     }
    
//     /**
//      * Set frame rate
//      */
//     public function setFrameRate(fps:Float):Void {
//         this.fps = fps;
//         this.captureInterval = 1 / fps;
        
//         if (camera != null) {
//             camera.setMode(width, height, fps);
//         }
        
//         if (captureFrames && isActive) {
//             startFrameCapture();
//         }
//     }
    
//     /**
//      * Get camera info
//      */
//     public function getCameraInfo():Dynamic {
//         if (camera == null) return null;
        
//         return {
//             name: camera.name,
//             width: width,
//             height: height,
//             fps: fps,
//             quality: quality,
//             isActive: isActive,
//             isAvailable: isAvailable,
//             muted: camera.muted,
//             currentFPS: camera.currentFPS
//         };
//     }
    
//     /**
//      * Cleanup and dispose
//      */
//     public function dispose():Void {
//         stop();
        
//         if (camera != null) {
//             camera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
//             camera.removeEventListener(ActivityEvent.ACTIVITY, onCameraActivity);
//         }
        
//         if (bitmapData != null) {
//             bitmapData.dispose();
//             bitmapData = null;
//         }
        
//         transmissionTargets = [];
//         video = null;
//         camera = null;
        
//         onActivityChange = null;
//         onStatusChange = null;
//         onFrameReady = null;
//     }
// }
