import yutautil.YScript;

class TestRangeDebug {
    static function main() {
        #if !macro
        backend.ClientPrefs.data.yscriptDebugMode = true;
        #end

        var yscript = new YScript();
        var code = "for (i in 0...100) { trace(i); }";
        trace('Testing YScript with: "$code"');
        yscript.loadFromSource(code, "test_range.ys");
    }
}
