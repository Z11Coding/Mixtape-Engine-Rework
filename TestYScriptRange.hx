import yutautil.YScript;

class TestYScriptRange {
    static function main() {
        #if !macro
        backend.ClientPrefs.data.yscriptDebugMode = true;
        #end

        var yscript = new YScript();

        trace("Testing YScript range operator...");
        var success = yscript.loadFromFile("test_range.ys");

        if (success) {
            trace("✅ YScript loaded successfully!");
            trace("Executing script...");
            yscript.execute();
        } else {
            trace("❌ YScript failed to load: " + yscript.lastError);
        }
    }
}
