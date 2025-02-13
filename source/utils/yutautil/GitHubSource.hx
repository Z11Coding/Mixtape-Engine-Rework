import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.net.Http;

class ImportFromMacro {
    public static function processImportFrom():Void {
        var fields = Context.getBuildFields();
        for (field in fields) {
            var meta = field.meta;
            for (m in meta) {
                if (m.name == ":importFrom") {
                    var url = m.params[0].expr.toString();
                    var sourceCode = downloadSource(url);
                    if (isValidHaxeSource(sourceCode)) {
                        var tempFilePath = saveToTempFile(sourceCode);
                        Context.addGlobalMetadata(":build", [macro @:build(ImportFromMacro.processImportFrom())], null);
                        Context.addGlobalMetadata(":import", [macro import $v{tempFilePath};], null);
                    } else {
                        Context.error("Invalid Haxe source file at " + url, Context.currentPos());
                    }
                }
            }
        }
    }

    static function downloadSource(url:String):String {
        var http = new Http(url);
        http.onData = function(data:String) {
            return data;
        }
        http.onError = function(error:String) {
            Context.error("Failed to download source from " + url + ": " + error, Context.currentPos());
        }
        http.request(false);
        return http.responseData;
    }

    static function isValidHaxeSource(source:String):Bool {
        try {
            var parsed = haxe.macro.Parser.parseString(source);
            return parsed != null;
        } catch (e:Dynamic) {
            return false;
        }
    }

    static function saveToTempFile(source:String):String {
        var tempFilePath = "temp_" + Math.random() + ".hx";
        File.saveContent(tempFilePath, source);
        return tempFilePath;
    }
}