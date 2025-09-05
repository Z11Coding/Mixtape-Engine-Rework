package yutautil.save;

/**
 * Scope management system for function execution
 * Emulates Haxe's scoping rules with variable shadowing and nested scopes
 */
class ScopeManager {

    private var scopes:Array<Map<String, Dynamic>>;
    private var scopeNames:Array<String>;

    public function new() {
        scopes = [];
        scopeNames = [];
        enterScope("global");
    }

    /**
     * Enter a new scope
     * @param name Optional name for the scope (for debugging)
     */
    public function enterScope(?name:String):Void {
        scopes.push(new Map<String, Dynamic>());
        scopeNames.push(name != null ? name : "anonymous");
    }

    /**
     * Exit the current scope
     */
    public function exitScope():Void {
        if (scopes.length <= 1) {
            throw "Cannot exit global scope";
        }
        scopes.pop();
        scopeNames.pop();
    }

    /**
     * Set a variable in the current scope
     * @param name Variable name
     * @param value Variable value
     */
    public function setVariable(name:String, value:Dynamic):Void {
        if (scopes.length == 0) {
            throw "No active scope";
        }

        var currentScope = scopes[scopes.length - 1];
        currentScope.set(name, value);
    }

    /**
     * Get a variable value, searching from current scope up to global
     * @param name Variable name
     * @return Variable value or null if not found
     */
    public function getVariable(name:String):Dynamic {
        // Search from most recent scope backwards
        for (i in 0...scopes.length) {
            var scopeIndex = scopes.length - 1 - i;
            var scope = scopes[scopeIndex];

            if (scope.exists(name)) {
                return scope.get(name);
            }
        }

        throw 'Variable not found: ${name}';
    }

    /**
     * Check if a variable exists in any scope
     * @param name Variable name
     * @return True if variable exists
     */
    public function hasVariable(name:String):Bool {
        for (i in 0...scopes.length) {
            var scopeIndex = scopes.length - 1 - i;
            var scope = scopes[scopeIndex];

            if (scope.exists(name)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Update an existing variable (searches up the scope chain)
     * @param name Variable name
     * @param value New value
     * @return True if variable was found and updated
     */
    public function updateVariable(name:String, value:Dynamic):Bool {
        // Search from most recent scope backwards
        for (i in 0...scopes.length) {
            var scopeIndex = scopes.length - 1 - i;
            var scope = scopes[scopeIndex];

            if (scope.exists(name)) {
                scope.set(name, value);
                return true;
            }
        }

        return false;
    }

    /**
     * Get all variables in the current scope
     * @return Map of variable names to values
     */
    public function getCurrentScopeVariables():Map<String, Dynamic> {
        if (scopes.length == 0) {
            throw "No active scope";
        }

        var currentScope = scopes[scopes.length - 1];
        var result = new Map<String, Dynamic>();

        for (key in currentScope.keys()) {
            result.set(key, currentScope.get(key));
        }

        return result;
    }

    /**
     * Get all variables from all scopes (flattened, with current scope taking precedence)
     * @return Map of variable names to values
     */
    public function getAllVariables():Map<String, Dynamic> {
        var result = new Map<String, Dynamic>();

        // Add from global scope to current scope (so current scope overwrites)
        for (scope in scopes) {
            for (key in scope.keys()) {
                result.set(key, scope.get(key));
            }
        }

        return result;
    }

    /**
     * Get the current scope depth
     * @return Number of active scopes
     */
    public function getScopeDepth():Int {
        return scopes.length;
    }

    /**
     * Get the name of the current scope
     * @return Current scope name
     */
    public function getCurrentScopeName():String {
        if (scopeNames.length == 0) {
            return "none";
        }
        return scopeNames[scopeNames.length - 1];
    }

    /**
     * Get all scope names from global to current
     * @return Array of scope names
     */
    public function getScopeStack():Array<String> {
        return scopeNames.copy();
    }

    /**
     * Clone the current scope manager (deep copy)
     * Useful for capturing lambda closure scopes
     * @return New ScopeManager with copied state
     */
    public function cloneScope():ScopeManager {
        var clone = new ScopeManager();
        clone.scopes = [];
        clone.scopeNames = [];

        // Deep copy all scopes
        for (i in 0...scopes.length) {
            var originalScope = scopes[i];
            var newScope = new Map<String, Dynamic>();

            for (key in originalScope.keys()) {
                var value = originalScope.get(key);
                // Note: This is a shallow copy of the values
                // Deep copying would require more complex logic depending on value types
                newScope.set(key, value);
            }

            clone.scopes.push(newScope);
            clone.scopeNames.push(scopeNames[i]);
        }

        return clone;
    }

    /**
     * Clear all variables in the current scope
     */
    public function clearCurrentScope():Void {
        if (scopes.length == 0) {
            throw "No active scope";
        }

        var currentScope = scopes[scopes.length - 1];
        for (key in currentScope.keys()) {
            currentScope.remove(key);
        }
    }

    /**
     * Debug: Print current scope state
     */
    public function debugPrintScopes():Void {
        trace('=== Scope Debug (${scopes.length} scopes) ===');

        for (i in 0...scopes.length) {
            var scope = scopes[i];
            var scopeName = i < scopeNames.length ? scopeNames[i] : "unnamed";

            trace('Scope ${i} (${scopeName}):');

            if (Lambda.count(scope) == 0) {
                trace('  (empty)');
            } else {
                for (key in scope.keys()) {
                    var value = scope.get(key);
                    var valueStr = Std.string(value);
                    if (valueStr.length > 50) {
                        valueStr = valueStr.substring(0, 47) + "...";
                    }
                    trace('  ${key} = ${valueStr}');
                }
            }
        }

        trace('=== End Scope Debug ===');
    }

    /**
     * Create a variable in a specific scope level (0 = global, -1 = current)
     * @param name Variable name
     * @param value Variable value
     * @param scopeLevel Scope level (0 = global, -1 = current, etc.)
     */
    public function setVariableInScope(name:String, value:Dynamic, scopeLevel:Int = -1):Void {
        var targetScopeIndex:Int;

        if (scopeLevel < 0) {
            // Negative indices count from current scope backwards
            targetScopeIndex = scopes.length + scopeLevel;
        } else {
            // Positive indices are absolute from global scope
            targetScopeIndex = scopeLevel;
        }

        if (targetScopeIndex < 0 || targetScopeIndex >= scopes.length) {
            throw 'Invalid scope level: ${scopeLevel} (current depth: ${scopes.length})';
        }

        scopes[targetScopeIndex].set(name, value);
    }
}
