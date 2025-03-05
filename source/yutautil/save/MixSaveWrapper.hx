package yutautil.save;

import sys.io.File;
using yutautil.save.MixSave;
using yutautil.CollectionUtils;

enum OutputType {
    MixSaveWrapperType;
    MixSaveType;
    MapType;
    DynamicType;
}

class MixSaveWrapper {
    public var mixSave:MixSave;
    private var filePath:String;
    public var fancyFormat:Bool = false;

    public function new(?mixSave:MixSave, filePath:String = "save/mixsave.json", autoLoad:Bool = true) {
        this.mixSave = mixSave != null ? mixSave : new MixSave();
        this.filePath = filePath;
        if (!filePath.endsWith(".json")) {
            filePath += ".json";
            this.filePath = filePath;
        }
        if (sys.FileSystem.exists(filePath) && autoLoad) {
            load();
        }
    }

    public function save():Void {
        var fileContent = new Map<String, String>();
        for (key in mixSave.content.keys()) {
            fileContent.set(key, mixSave.saveContent(key));
        }
        if (!sys.FileSystem.exists(haxe.io.Path.directory(filePath))) {
            sys.FileSystem.createDirectory(haxe.io.Path.directory(filePath));
        }
        var jsonString = haxe.Json.stringify(fileContent, null, fancyFormat ? "\t" : null);
        File.saveContent(filePath, jsonString);
    }

    public function saveContent(key:String):String {
        return mixSave.saveContent(key);
    }

    public function addItem(key:String, value:Dynamic):Void {
        mixSave.addContent(key, value);
    }

    public function getItem(key:String):Dynamic {
        return mixSave.getContent(key);
    }

    public function removeItem(key:String):Void {
        mixSave.content.remove(key);
    }

    public function hasItem(key:String):Bool {
        return mixSave.content.exists(key);
    }

    public function editItem(key:String, value:Dynamic):Void {
        mixSave.content.set(key, value);
    }

    public function clear():Void {
        mixSave.content = new Map();
    }

    public function load():Void {
        if (sys.FileSystem.exists(filePath)) {
            var jsonContent = File.getContent(filePath);
            var parsedContent = haxe.Json.parse(jsonContent);
            var fileContent:Map<String, String> = new Map();
            for (key in Reflect.fields(parsedContent)) {
                fileContent.set(key, Reflect.field(parsedContent, key));
            }
            // trace(fileContent);
            for (key in fileContent.keys()) {
                mixSave.loadContent(key, fileContent.get(key));
            }
        }
    }

    public function addObject(thing:Dynamic):Void {
        for (field in Reflect.fields(thing)) {
            var value = Reflect.field(thing, field);
            mixSave.content.set(field, value);
        }
    }

    public static function saveObjectToFile(thing:Dynamic, filePath:String = "save/mixsave.json", ?fancy:Bool = false):Void {
        var wrapper = new MixSaveWrapper(new MixSave(), filePath);
        wrapper.addObject(thing);
        wrapper.fancyFormat = fancy;
        wrapper.save();
    }

    public static function loadObjectFromFile(thing:Dynamic, filePath:String = "save/mixsave.json"):Void {
        var wrapper = new MixSaveWrapper(new MixSave(), filePath);
        wrapper.load();
        for (field in Reflect.fields(thing)) {
            if (wrapper.mixSave.content.exists(field)) {
                Reflect.setField(thing, field, wrapper.mixSave.content.get(field));
            }
        }
    }

    /**
     * Loads a mix file from the specified file path and returns the content based on the specified output type.
     *
     * @param filePath The path to the mix file to load. Defaults to "save/mixsave.json".
     * @param outputType The type of output to return. Can be one of the following:
     *                   - MixSaveWrapperType: Returns the MixSaveWrapper instance.
     *                   - MixSaveType: Returns the MixSave instance.
     *                   - MapType: Returns the content of the MixSave as a map.
     *                   - DynamicType: Returns the content of the MixSave as a dynamic object.
     * @return The content of the mix file based on the specified output type.
     */
    public static function loadMixFile(filePath:String = "save/mixsave.json", outputType:OutputType):Dynamic {
        var wrapper = new MixSaveWrapper(new MixSave(), filePath);
        switch (outputType) {
            case MixSaveWrapperType:
                return wrapper;
            case MixSaveType:
                return wrapper.mixSave;
            case MapType:
                return wrapper.mixSave.content;
            case DynamicType:
                var result = {};
                for (field in wrapper.mixSave.content.keys()) {
                    Reflect.setField(result, field, wrapper.mixSave.content.get(field));
                }
                return result;
        }
    }

    public static function newWithData(mixSave:MixSave, data:Map<String, Dynamic>, filePath:String = "save/mixsave.json"):MixSaveWrapper {
        var wrapper = new MixSaveWrapper(mixSave, filePath);
        wrapper.mixSave.content = data;
        return wrapper;
    }

    public static function newWithDynamic(mixSave:MixSave, data:Dynamic, filePath:String = "save/mixsave.json"):MixSaveWrapper {
        var wrapper = new MixSaveWrapper(mixSave, filePath);
        for (field in Reflect.fields(data)) {
            wrapper.mixSave.content.set(field, Reflect.field(data, field));
        }
        return wrapper;
    }

    public static function newWithDefault(filePath:String = "save/mixsave.json"):MixSaveWrapper {
        var wrapper = new MixSaveWrapper(new MixSave(), filePath, false);
        if (!sys.FileSystem.exists(filePath)) {
            wrapper.mixSave.content = new Map();
            wrapper.save();
        } else {
            wrapper.load();
        }
        return wrapper;
    }

    public function isEmpty():Bool {
        return mixSave.content.toArray().length <= 0;
    }

    public function toString():String {
        return mixSave.content.toString();
    }
    public function toMap():Map<String, Dynamic> {
        return mixSave.content;
    }
    public function toDynamic():Dynamic {
        var result = {};
        for (field in mixSave.content.keys()) {
            Reflect.setField(result, field, mixSave.content.get(field));
        }
        return result;
    }
    public static function newMix(filePath = "save/mixsave.json"):MixSaveWrapper {
        return new MixSaveWrapper(new MixSave(), filePath);
    }
    public static function newMixWithData(data:Map<String, Dynamic>, filePath = "save/mixsave.json"):MixSaveWrapper {
        return newWithData(new MixSave(), data, filePath);
    }
}

class ActiveSave extends MixSaveWrapper { // Work in progress
    public function new(?mixSave:MixSave, filePath:String = "save/activesave.json") {
        super(mixSave, filePath);
    }

    override public function addObject(thing:Dynamic):Void {
        super.addObject(thing);
        save();
    }

    override public function save():Void {
        super.save();
    }

    override public function load():Void {
        super.load();
    }
}