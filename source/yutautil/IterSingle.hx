package yutautil;
class IterSingle {
    private var variable:Array<Dynamic>;
    private var func:Dynamic;
    private var debug:Bool;

    public function new(variable:Array<Dynamic>, func:Dynamic, autoExecute:Bool, ?debug:Bool = false) {
        this.variable = variable;
        this.func = func;
        this.debug = debug;
        if (autoExecute) {
            execute();
        }
    }

    public static function funcIterate(variable:Array<Dynamic>, func:Dynamic, ?debug:Bool = false):Dynamic {
        return new IterSingle(variable, func, false, debug).execute();
    }

    public function execute():Dynamic {
        var results:Array<Dynamic> = [];
        for (item in variable) {
            if (debug) {
                trace("Input: " + item);
            }
            var result = func(item);
            if (debug) {
                trace("Output: " + result);
            }
            if (result != null) {
                results.push(result);
            }
        }
        return results.length > 0 ? results : null;
    }
}