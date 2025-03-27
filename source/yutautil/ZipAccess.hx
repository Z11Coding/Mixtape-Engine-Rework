package yutautil;

import haxe.zip.Reader;
import haxe.io.Bytes;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;

class ZipAccess {
    private var zipReader:Reader;
    private var entries:Map<String, Bytes>;

    public function new(zipFilePath:String) {
        var fileInput = File.read(zipFilePath, true);
        zipReader = new Reader(fileInput);
        entries = new Map<String, Bytes>();
        for (entry in zipReader.entries) {
            entries.set(entry.fileName, entry.fileData);
        }
    }

    enum ZipAction {
        ListFiles;
        ExtractFile(fileName:String, outputPath:String);
        GetFileContent(fileName:String);
        ExtractAll(outputDir:String);
    }

    public static function doTask(zipFilePath:String, action:ZipAction):Dynamic {
        var zipAccess = new ZipAccess(zipFilePath);
        switch (action) {
            case ListFiles:
                return zipAccess.listFiles();
            case ExtractFile(fileName, outputPath):
                zipAccess.extractFile(fileName, outputPath);
                return null;
            case GetFileContent(fileName):
                return zipAccess.getFileContent(fileName);
            case ExtractAll(outputDir):
                zipAccess.extractAll(outputDir);
                return null;
        }
    }

    public function listFiles():Array<String> {
        return entries.keys();
    }

    public function extractFile(fileName:String, outputPath:String):Void {
        if (entries.exists(fileName)) {
            var fileData = entries.get(fileName);
            var fileOutput = File.write(outputPath, true);
            fileOutput.write(fileData);
            fileOutput.close();
        } else {
            throw "File not found in zip: " + fileName;
        }
    }

    public function getFileContent(fileName:String):Bytes {
        if (entries.exists(fileName)) {
            return entries.get(fileName);
        } else {
            throw "File not found in zip: " + fileName;
        }
    }

    public function extractAll(outputDir:String):Void {
        for (fileName in entries.keys()) {
            var outputPath = outputDir + "/" + fileName;
            extractFile(fileName, outputPath);
        }
    }
}