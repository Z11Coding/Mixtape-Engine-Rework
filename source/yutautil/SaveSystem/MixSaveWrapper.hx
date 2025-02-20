import sys.io.File;

class MixSaveWrapper {
    public var mixSave:MixSave;
    private var filePath:String;

    public function new(mixSave:MixSave, filePath:String) {
        this.mixSave = mixSave;
        this.filePath = filePath;
    }

    public function save():Void {
        var fileContent = new Map<String, String>();
        for (key in mixSave.content.keys()) {
            fileContent.set(key, mixSave.saveContent(key));
        }
        File.saveContent(filePath, haxe.Json.stringify(fileContent));
    }

    public function load():Void {
        if (File.exists(filePath)) {
            var fileContent = haxe.Json.parse(File.getContent(filePath));
            for (key in fileContent.keys()) {
                mixSave.loadContent(key, fileContent.get(key));
            }
        }
    }
}