package states;

import haxe.Type;
import hscript.Parser;
import hscript.Interp;

class CustomState {
    public static var customState = {
        switchTo: function(stateName:String):Void {
            // Assuming state classes are in the "states" package
            var className = "states." + stateName;
            var stateClass = Type.resolveClass(className);
            if (stateClass != null) {
                var stateInstance:Dynamic = Type.createInstance(stateClass, []);
                trace("Switched to state: " + stateName);
                // Here you would switch the state, e.g., FlxG.switchState(stateInstance);
            } else {
                // Attempt to load and execute a Haxe script (.hx file) as a state
                try {
                    var scriptContent:String = sys.io.File.getContent("states/" + stateName + ".hx");
                    var parser = new Parser();
                    var expr = parser.parseString(scriptContent);
                    var interp = new Interp();
                    interp.execute(expr);
                    trace("Switched to state: " + stateName + " using hscript");
                } catch (e:Dynamic) {
                    trace("State not found: " + stateName + ", Error: " + e);
                }
            }
        }
    };
}