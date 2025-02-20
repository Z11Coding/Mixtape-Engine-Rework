class MixSave {
    public var content:Map<String, Dynamic>;
    private var customBehaviors:Map<String, {save:Dynamic->String, load:String->Dynamic}>;

    public function new() {
        content = new Map();
        customBehaviors = new Map();
    }

    public function addContent(key:String, value:Dynamic):Void {
        content.set(key, value);
    }

    public function getContent(key:String):Dynamic {
        return content.get(key);
    }

    public function registerBehavior(key:String, saveFunc:Dynamic->String, loadFunc:String->Dynamic):Void {
        customBehaviors.set(key, {save: saveFunc, load: loadFunc});
    }

    public function saveContent(key:String):String {
        if (customBehaviors.exists(key)) {
            return customBehaviors.get(key).save(content.get(key));
        } else {
            return haxe.Json.stringify(content.get(key));
        }
    }

    public function loadContent(key:String, data:String):Void {
        if (customBehaviors.exists(key)) {
            content.set(key, customBehaviors.get(key).load(data));
        } else {
            content.set(key, haxe.Json.parse(data));
        }
    }
}