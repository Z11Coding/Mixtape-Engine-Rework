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
        return FilePopup.save(title, filter, preserve_cwd);
    }

    public static function selectFolder(title:String, ?preserve_cwd:Bool=true):String {
        return FilePopup.folder(title, preserve_cwd);
    }

    // Functions for automatically handling these functions.
    // For loading a file, add a function that will take that file and load it into a variable, using the dialogs.
    public static function loadFile(title:String, ?filters:Array<FileFilter>, readType:ReadType, ?operation:Dynamic->Dynamic, ?preserve_cwd:Bool=true):Dynamic {
        if (filters != null) {
            for (filter in filters) {
                filter.desc = filter.desc != null ? filter.desc : '${filter.ext.toUpperCase()} File';
            }
        }
        var filePath = openFile(title, filters, preserve_cwd);
        if (filePath != null) {
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
        if (filePath != null || filePath != "") {
            writeType == ReadType.Bytes 
            ? File.saveBytes(filePath, data) 
            : File.saveContent(filePath, data);
        }
        return filePath != null && filePath != "" && FileSystem.exists(filePath); // Return if not cancelled, and saved.
    }
}