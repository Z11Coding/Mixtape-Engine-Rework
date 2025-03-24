package yutautil.save;

import haxe.macro.Context;
import yutautil.save.FuncEmbed as FuncE;
import haxe.macro.Expr;
import haxe.macro.Printer;

class MixSave {
    public var content:Map<String, Dynamic>;
    public var customBehaviors:Map<String, {save:String, load:String}>;

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

    public macro function addContentWithBehavior(key:String, value:Dynamic, saveFunc:Expr, loadFunc:Expr):Expr {
        var saveFuncStr = FuncE.functionToString(saveFunc);
        var loadFuncStr = FuncE.functionToString(loadFunc);
        var key = Context.makeExpr(key, Context.currentPos());
        return macro {
            this.addContent($key, $value);
            this.customBehaviors.set($key, {save: $saveFuncStr, load: $loadFuncStr});
        };
    }

    public macro function registerBehavior(key:String, saveFunc:Expr, loadFunc:Expr):Expr {
        var saveFuncStr = FuncE.functionToString(saveFunc);
        var loadFuncStr = FuncE.functionToString(loadFunc);
        var key = Context.makeExpr(key, Context.currentPos());
        return macro {
            this.customBehaviors.set($key, {save: $saveFuncStr, load: $loadFuncStr});
            if (!this.content.exists($key)) {
                this.content.set($key, null);
            }
        };
    }

    public function saveContent(key:String):String {
        if (customBehaviors.exists(key)) {
            var saveFuncStr = customBehaviors.get(key).save;
            var saveFunc = FuncE.runFunctionFromString(saveFuncStr, this.content.get(key));
            return saveFunc(content.get(key));
        } else {
            return haxe.Json.stringify(content.get(key));
        }
    }

    public function loadContent(key:String, data:String):Void {
        if (customBehaviors.exists(key)) {
            var loadFuncStr = customBehaviors.get(key).load;
            var loadFunc = FuncE.runFunctionFromString(loadFuncStr, this);
            content.set(key, loadFunc(data));
        } else {
            content.set(key, haxe.Json.parse(data));
        }
    }
}