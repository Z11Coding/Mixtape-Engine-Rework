package yutautil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.URLRequest;
import haxe.Timer;

enum DO {
    LOAD_FILE, SAVE_FILE, DOWNLOAD_FILE
}

class FileHandler {
    private var fileRef:FileReference;
    private var fileData:Dynamic;
    private var filePath:String;

    public function new() {
        fileRef = new FileReference();
    }

    public static function do(action:DO, data:Dynamic):Dynamic {
        var fileHandler = new FileHandler();
        switch (action) {
            case LOAD_FILE:
                fileHandler.loadFile();
                fileHandler.waitForFile();
                break;
            case SAVE_FILE:
                fileHandler.saveFile(data, defaultFileName);
                break;
            case DOWNLOAD_FILE:
                var url = data;
                fileHandler.downloadFile(url, savePath);
                fileHandler.waitForDownload();
                break;
        }
        return fileHandler.fileData;
    }

    

    public function loadFile():Void {
        fileRef.addEventListener(Event.SELECT, onFileSelected);
        fileRef.addEventListener(Event.CANCEL, onFileCancel);
        fileRef.addEventListener(IOErrorEvent.IO_ERROR, onFileError);
        fileRef.browse();
    }

    private function onFileSelected(event:Event):Void {
        fileRef.addEventListener(Event.COMPLETE, onFileLoadComplete);
        fileRef.load();
    }

    private function onFileLoadComplete(event:Event):Void {
        fileData = fileRef.data;
        trace("File loaded successfully.");
    }

    private function onFileCancel(event:Event):Void {
        trace("File load canceled.");
    }

    private function onFileError(event:IOErrorEvent):Void {
        trace("File load error: " + event.text);
    }

    public function saveFile(data:Dynamic, defaultFileName:String = "file.txt"):Void {
        fileRef.save(data, defaultFileName);
    }

    public function downloadFile(url:String, savePath:String = null):Void {
        var request = new URLRequest(url);
        fileRef.addEventListener(Event.COMPLETE, onDownloadComplete);
        fileRef.addEventListener(IOErrorEvent.IO_ERROR, onDownloadError);
        fileRef.download(request, savePath);
    }

    private function onDownloadComplete(event:Event):Void {
        trace("File downloaded successfully.");
    }

    private function onDownloadError(event:IOErrorEvent):Void {
        trace("File download error: " + event.text);
    }

    public function waitForFile():Void {
        wait(() -> fileData != null, "Waiting for file to be loaded...");
    }

    public function waitForDownload():Void {
        wait(() -> fileRef.data != null, "Waiting for file to be downloaded...");
    }
}