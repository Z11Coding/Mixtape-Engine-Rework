package backend;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flixel.util.FlxSave;
import haxe.Json;
import haxe.crypto.Base64;
import flash.utils.ByteArray;

class ImageCache {

    public static var cache:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
    //private static var save:FlxSave = new FlxSave(); This was actually useless...

    public static function add(path:String):Void {
        try {
            var data:FlxGraphic = FlxGraphic.fromBitmapData(GPUBitmap.create(path));
            data.persist = true;
            data.destroyOnNoUse = false;
            //trace(cache);

            cache.set(path, data);
        } catch (e:Dynamic) {
            trace("Error adding image to cache: "+ e);
        }
    }

    public static function get(path:String):FlxGraphic {
        try {
            return cache.get(path);
        } catch (e:Dynamic) {
            trace("Error getting image from cache:"+ e);
            return null;
        }
    }

    public static function exists(path:String):Bool {
        try {
            return cache.exists(path);
        } catch (e:Dynamic) {
            trace("Error checking if image exists in cache: "+ e);
            return false;
        }
    }

    public static function testEncode():Void {
        // Create a small, simple bitmapData for testing
        var bitmapData:BitmapData = new BitmapData(2, 2, false, 0xFF0000); // Red square
        try {
            var bytes:ByteArray = bitmapData.encode(bitmapData.rect, new openfl.display.PNGEncoderOptions());
            var base64Data:String = Base64.encode(bytes);
            openfl.Lib.application.window.alert("Test encode success: " + base64Data);
        } catch (e:Dynamic) {
            openfl.Lib.application.window.alert("Test encode failed: " + e);
        }
    }

    

        // Function to serialize and save the cache
        public static function saveCache():Void {
            var cacheData:Array<{ id: String, imageData: String }> = [];
            for (id in cache.keys()) {
                var graphic:FlxGraphic = cache.get(id);
                if (graphic == null || graphic.bitmap == null) {
                    trace("Graphic or bitmapData is null for id: " + id);
                    continue; // Skip this iteration
                }
                var originalBitmapData:BitmapData = graphic.bitmap;
                trace("Processing id: " + id + ", size: " + originalBitmapData.width + "x" + originalBitmapData.height);
            
                // Create a new BitmapData object
                var newBitmapData:BitmapData = new BitmapData(originalBitmapData.width, originalBitmapData.height, true, 0x00000000);
                newBitmapData.draw(originalBitmapData); // Draw the original bitmap onto the new one
            
                // Encode the new BitmapData
                var bytes:ByteArray = newBitmapData.encode(newBitmapData.rect, new openfl.display.PNGEncoderOptions());
                if (bytes == null) {
                    trace("Encoded bytes are null for id: " + id);
                    continue; // Skip this iteration
                }
                bytes.position = 0; // Reset position before encoding to Base64
                var base64Data:String = Base64.encode(bytes);
                // Use the base64Data as needed
                cacheData.push({ id: id, imageData: base64Data });
            }
            var cacheJson:String = Json.stringify(cacheData); // Never trace this, OR WAIT FOREVER

            FlxG.save.data.ImageCache = cacheJson;
            FlxG.save.flush();  
        }
    
        // Function to load and deserialize the cache
        public static function loadCache():Void {
            try {
            var cacheJson:String = FlxG.save.data.ImageCache;
            if (cacheJson != null) {
                var cacheData:Array<{ id: String, imageData: String }> = Json.parse(cacheJson);
                for (data in cacheData) {
                var bytes:ByteArray = Base64.decode(data.imageData);
                var bitmapData:BitmapData = BitmapData.fromBytes(bytes);
                var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmapData);
                graphic.persist = true;
                graphic.destroyOnNoUse = false;
                cache.set(data.id, graphic);
                }
            }
            } catch (e:Dynamic) {
            trace("Error loading cache: " + e + " Likely doesn't exist.");
            }
        }
}