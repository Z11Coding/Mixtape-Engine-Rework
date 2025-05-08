package yutautil;

import dialogs.Dialogs.FileFilter;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import haxe.io.Path;
import haxe.ds.StringMap;
import dialogs.Dialogs as FilePopup;

enum ReadType {
    Text;
    Bytes;
}

class ImprovedFileHandling {
    public static var lastPath:String = "";
    public static function openFile(title:String, ?filters:Array<FileFilter>, ?preserve_cwd:Bool=true):String {
        if (filters != null) {
            for (filter in filters) {
                filter.desc = filter.desc != null ? filter.desc : filter.ext.toUpperCase() + " File";
            }
        }
        return FilePopup.open(title, filters, preserve_cwd);
    }

    public static function saveFile(title:String, ?filter:FileFilter, ?preserve_cwd:Bool=true):String {
        if (filter != null) {
            filter.desc = filter.desc != null ? filter.desc : '${filter.ext.toUpperCase()} File';
        }
        var filePath = FilePopup.save(title, filter, preserve_cwd);
        if (filePath != null && filter != null) {
            var ext = "." + filter.ext;
            if (!filePath.endsWith(ext)) {
                if (filePath.endsWith(".")) {
                    filePath += filter.ext;
                } else {
                    filePath += ext;
                }
            }
            lastPath = filePath;
        }
        return filePath;
    }

    public static function selectFolder(title:String, ?preserve_cwd:Bool=true):String {
        return FilePopup.folder(title, preserve_cwd);
    }

    public static function loadFile(title:String, ?filters:Array<FileFilter>, readType:ReadType, ?operation:Dynamic->Dynamic, ?preserve_cwd:Bool=true):Dynamic {
        if (filters != null) {
            for (filter in filters) {
                filter.desc = filter.desc != null ? filter.desc : '${filter.ext.toUpperCase()} File';
            }
        }
        var filePath = openFile(title, filters, preserve_cwd);
        if (filePath != null && filePath.trim() != "") {
            lastPath = filePath;
            return operation != null 
                ? operation(readType == ReadType.Bytes ? File.getBytes(filePath) : File.getContent(filePath)) 
                : (readType == ReadType.Bytes ? File.getBytes(filePath) : File.getContent(filePath));
        }
        return null;
    }

    public static function saveOperation(title:String, ?filter:FileFilter, writeType:ReadType, data:Dynamic, ?preserve_cwd:Bool=true):Bool {
        if (filter != null) {
            filter.desc = filter.desc != null ? filter.desc : '${filter.ext.toUpperCase()} File';
        }
        var filePath = saveFile(title, filter, preserve_cwd);
        if (filePath != null && filePath.trim() != "") {
            var ext = "." + filter.ext;
            if (!filePath.endsWith(ext)) {
                if (filePath.endsWith(".")) {
                    filePath += filter.ext;
                } else {
                    filePath += ext;
                }
            }
            writeType == ReadType.Bytes 
            ? File.saveBytes(filePath, data) 
            : File.saveContent(filePath, data);
            lastPath = filePath;
        }
        return filePath != null && filePath != "" && FileSystem.exists(filePath); // Return if not cancelled, and saved.
    }
}