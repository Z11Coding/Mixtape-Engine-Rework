package backend.modules;

import flixel.system.FlxSound;

// Represents a single sound layer
class SoundLayer {
	public var sound:FlxSound;
	public var id:String;

	public function new(id:String, soundPath:String) {
		this.id = id;
		this.sound = new FlxSound();
		this.sound.loadEmbedded(soundPath, true);
	}

	public function play():Void {
		this.sound.play();
	}

	public function stop():Void {
		this.sound.stop();
	}

	public function setVolume(volume:Float):Void {
		this.sound.volume = volume;
	}
}

// class SoundVariant extends SoundLayer {
//     public var variants:Array<SoundLayer>;
//     public var currentVariantIndex:Int;
//     public var switchMode:SwitchMode;
//     public var chance:Chance<SoundLayer>;
//     public var onSwitch:Dynamic->Void;

//     public function new(id:String, soundPaths:Array<String>, switchMode:SwitchMode, onSwitch:Dynamic->Void) {
//         super(id, soundPaths[0]);
//         this.variants = [];
//         for (path in soundPaths) {
//             this.variants.push(new SoundLayer(id, path));
//         }
//         this.currentVariantIndex = 0;
//         this.switchMode = switchMode;
//         this.onSwitch = onSwitch;
//         if (switchMode == SwitchMode.Chance) {
//             this.chance = new Chance<SoundLayer>(this.variants);
//         }
//     }

//     override public function play():Void {
//         this.variants[currentVariantIndex].play();
//     }

//     override public function stop():Void {
//         this.variants[currentVariantIndex].stop();
//     }

//     override public function setVolume(volume:Float):Void {
//         for (variant in variants) {
//             variant.setVolume(volume);
//         }
//     }

//     public function switchVariant(index:Int):Void {
//         if (index >= 0 && index < variants.length) {
//             this.currentVariantIndex = index;
//             this.onSwitch(this.variants[index]);
//         }
//     }

//     public function autoSwitch():Void {
//         switch (this.switchMode) {
//             case Loop:
//                 // Do nothing, keep the same variant
//             case Progressive:
//                 this.currentVariantIndex = (this.currentVariantIndex + 1) % this.variants.length;
//             case Random:
//                 this.currentVariantIndex = Std.random(this.variants.length);
//             case Chance:
//                 var selectedVariant = this.chance.selectOption();
//                 this.currentVariantIndex = this.variants.indexOf(selectedVariant);
//         }
//         this.onSwitch(this.variants[this.currentVariantIndex]);
//     }
// }

// Manages multiple sound layers
class SoundGroup {
    public var layers:Array<SoundLayer> = [];

    public function new() {}

    // public function addLayersFromData(data:Array<Dynamic>):Void {
    //     for (item in data) {
    //         if (item instanceof Array<Dynamic> && item.length == 2) {
    //             var id:String = item[0];
    //             var soundPath:String = item[1];
    //             var layer:SoundLayer = new SoundLayer(id, soundPath);
    //             addLayer(layer);
    //         } else if (item instanceof Map<String, String>) {
    //             for (id in item.keys()) {
    //                 var soundPath:String = item.get(id);
    //                 var layer:SoundLayer = new SoundLayer(id, soundPath);
    //                 addLayer(layer);
    //             }
    //         }
    //     }
    // }

    public function addLayer(layer:SoundLayer):Void {
        var id:String = layer.id;
        var count:Int = 1;
        
        while (layerExists(id)) {
            count++;
            id = layer.id + "-" + count;
        }
        
        layer.id = id;
        layers.push(layer);
    }

    public function addLayers(layers:Array<SoundLayer>):Void {
        for (layer in layers) {
            addLayer(layer);
        }
    }

    public function addLayersFromMap(layerMap:Map<String, String>):Void {
        for (id in layerMap.keys()) {
            var soundPath:String = layerMap.get(id);
            var layer:SoundLayer = new SoundLayer(id, soundPath);
            addLayer(layer);
        }
    }
    
    private function layerExists(id:String):Bool {
        for (layer in layers) {
            if (layer.id == id) {
                return true;
            }
        }
        return false;
    }


    public function stopAll():Void {
        for (layer in layers) {
            layer.stop();
        }
    }

    public function stopLayer(id:String):Void {
        for (layer in layers) {
            if (layer.id == id) {
                layer.stop();
                break;
            }
        }
    }

    public function pause(layer:SoundLayer):Void {
        layer.sound.pause();
    }

    public function pauseAll():Void {
        for (layer in layers) {
            layer.sound.pause();
        }
    }

    public function sync(layer:SoundLayer, unpause:Bool = true):Void {
        layer.sound.time = layers[0].sound.time;
        if (unpause) {
            layer.sound.play();
        }
    }

    public function syncAll(unpause:Bool = true):Void {
        for (layer in layers) {
            this.sync(layer, unpause);
        }
    }

    public function setVolumeForLayer(id:String, volume:Float):Void {
        for (layer in layers) {
            if (layer.id == id) {
                layer.setVolume(volume);
                break;
            }
        }
    }

    public function setVolumeForAllLayers(volume:Float):Void {
        for (layer in layers) {
            layer.setVolume(volume);
        }
    }

    // public function preloadAndPlayAll():Void {
    //     var soundsToLoad = layers.length;
    //     for (layer in layers) {
    //         layer.sound.loadEmbedded(layer.sound, true, false, onSoundLoaded);
    //     }

    //     function onSoundLoaded():Void {
    //         soundsToLoad--;
    //         if (soundsToLoad == 0) {
    //             // All sounds are loaded, play them together
    //             for (layer in layers) {
    //                 layer.play();
    //             }
    //         }
    //     }
    // }

    public static function createGroupFromFiles(soundPaths:Map<String, String>):SoundGroup {
        var group:SoundGroup = new SoundGroup();
        var layerIDs:Map<String, Int> = new Map<String, Int>();
        
        for (id in soundPaths.keys()) {
            var soundPath:String = soundPaths.get(id);
            
            if (id == null || id == "") {
                id = "unknown";
            }
            
            if (layerIDs.exists(id)) {
                var count:Int = layerIDs.get(id);
                count++;
                id = id + "-" + count;
                layerIDs.set(id, count);
            } else {
                layerIDs.set(id, 1);
            }
            
            var layer:SoundLayer = new SoundLayer(id, soundPath);
            group.addLayer(layer);
        }
        
        return group;
    }

    public static function createGroupFromNameAndFiles(name:String, filePaths:Array<String>):SoundGroup {
        var group:SoundGroup = new SoundGroup();
        var counter:Int = 1;
    
        for (filePath in filePaths) {
            var id:String = name + "-" + counter;
            var layer:SoundLayer = new SoundLayer(id, filePath);
            group.addLayer(layer);
            counter++;
        }
    
        return group;
    }
}
