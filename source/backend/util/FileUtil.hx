import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.FileReference;
import sys.thread.Semaphore;

typedef FileOperationCallback = Void->Void;
typedef FileLoadCallback = String->Void;

class FileRead {
    public var data:String;
    public function new(block:Bool = true, onLoad:FileLoadCallback = null, onCancel:FileOperationCallback = null, onError:FileOperationCallback = null) {
        var fileUtil = new FileUtil(true, onLoad, onCancel, onError);
        if (block) {
            fileUtil.semaphore.acquire(); // Block until the operation is complete
        }
    }
}

class FileWrite {
    public function new(data:String, path:String, block:Bool = true, onComplete:FileOperationCallback = null, onCancel:FileOperationCallback = null, onError:FileOperationCallback = null) {
        var fileUtil = new FileUtil();
        fileUtil.save(data, path, onComplete, onCancel, onError);
        if (block) {
            fileUtil.semaphore.acquire(); // Block until the operation is complete
        }
    }
}

class FileUtil {
    private var _file:FileReference;
    private var onComplete:FileOperationCallback;
    private var onCancel:FileOperationCallback;
    private var onError:FileOperationCallback;
    private var onLoad:FileLoadCallback;
    public var semaphore:Semaphore;

    public function new(instantAction:Bool = false, onLoad:FileLoadCallback = null, onCancel:FileOperationCallback = null, onError:FileOperationCallback = null) {
        _file = new FileReference();
        _file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
        _file.addEventListener(Event.CANCEL, onSaveCancel);
        _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file.addEventListener(Event.COMPLETE, onLoadComplete);
        
        if (instantAction && onLoad != null) {
            this.load(onLoad, onCancel, onError);
        }
    }

    public function save(data:String, path:String, onComplete:FileOperationCallback, onCancel:FileOperationCallback, onError:FileOperationCallback):Void {
        this.onComplete = onComplete;
        this.onCancel = onCancel;
        this.onError = onError;
        semaphore = new Semaphore(0);
        _file.save(data.trim(), path);
    }

    public function load(onLoad:FileLoadCallback, onCancel:FileOperationCallback, onError:FileOperationCallback):Void {
        this.onLoad = onLoad;
        this.onCancel = onCancel;
        this.onError = onError;
        semaphore = new Semaphore(0);
        _file.browse();
    }

    private function onSaveComplete(event:Event):Void {
        if (onComplete != null) {
            onComplete();
        }
        semaphore.release(); // Unblock the save method
    }

    private function onSaveCancel(event:Event):Void {
        if (onCancel != null) {
            onCancel();
        }
        semaphore.release(); // Unblock the save method
    }

    private function onSaveError(event:IOErrorEvent):Void {
        if (onError != null) {
            onError();
        }
        semaphore.release(); // Unblock the save method
    }

    private function onLoadComplete(event:Event):Void {
        _file.load();
        _file.addEventListener(Event.COMPLETE, function(e:Event):Void {
            if (onLoad != null) {
                onLoad(_file.data.readUTFBytes(_file.data.length));
            }
            semaphore.release(); // Unblock the load method
        });
    }

    private function clearListeners():Void {
        _file.removeEventListener(Event.SELECT, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file.removeEventListener(Event.COMPLETE, onLoadComplete);
    }
}