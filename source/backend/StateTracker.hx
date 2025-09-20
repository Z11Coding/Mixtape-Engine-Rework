package backend;

import flixel.FlxG;

/**
 * State tracking system for capturing variables from specific states
 * while maintaining non-null values and managing allowed navigation states
 */
class StateTracker {
    // The specific state class being tracked
    private var trackedStateClass:Dynamic;

    // State class to return to when leaving allowed states
    private var returnStateClass:Dynamic;
    private var returnStateArgs:Array<Dynamic>;

    // States that are allowed without triggering return
    private var allowedStates:Array<Dynamic>;

    // Variables to track and their current values
    private var trackedVariables:Map<String, Dynamic>;
    private var variableNames:Array<String>;

    // Navigation context for the tracking session
    private var navigationContext:String;

    // Flag to prevent repeated processing of the same state
    private var lastProcessedStateClass:Dynamic;

    public function new() {
        trackedVariables = new Map<String, Dynamic>();
        allowedStates = [];
        variableNames = [];
        returnStateArgs = [];
    }

    /**
     * Sets up state tracking configuration
     * @param trackedState The specific state class to track variables from
     * @param returnState The state class to return to when leaving allowed states
     * @param allowedStates Array of state classes that are allowed without triggering return
     * @param variablesToTrack Array of variable names to track from the tracked state
     * @param returnArgs Optional constructor arguments for the return state
     * @param context Optional context string for this tracking session
     */
    public function setupTracking(
        trackedState:Dynamic,
        returnState:Dynamic,
        allowedStates:Array<Dynamic>,
        variablesToTrack:Array<String>,
        ?returnArgs:Array<Dynamic>,
        ?context:String
    ) {
        this.trackedStateClass = trackedState;
        this.returnStateClass = returnState;
        this.allowedStates = allowedStates.copy();
        this.variableNames = variablesToTrack.copy();
        this.returnStateArgs = returnArgs != null ? returnArgs.copy() : [];
        this.navigationContext = context;
        this.lastProcessedStateClass = null;

        // Initialize tracked variables with null values
        trackedVariables.clear();
        for (varName in variablesToTrack) {
            trackedVariables.set(varName, null);
        }
    }

    /**
     * Updates tracked variables from the current state if it's the tracked state
     * Only updates variables that are non-null, preserving existing values otherwise
     */
    public function updateFromState(currentState:MusicBeatState) {
        if (trackedStateClass == null || currentState == null || trackedVariables == null) return;

        var currentStateClass = Type.getClass(currentState);

        // Only update if we're in the tracked state
        if (currentStateClass == trackedStateClass) {
            for (varName in variableNames) {
                try {
                    var value = Reflect.field(currentState, varName);
                    // Only update if the value is non-null
                    if (value != null && value != trackedVariables.get(varName)) {
                        trackedVariables.set(varName, value);
                        trace('Updated tracked variable: $varName = $value');
                    }
                } catch (e:Dynamic) {
                    trace('Failed to read variable: $varName from ${Type.getClassName(currentStateClass)}');
                }
            }
        }
    }

    /**
     * Checks if we should return to the return state
     * Call this from update() in MusicBeatState
     */
    public function checkForReturn(currentState:MusicBeatState):Bool {
        if (returnStateClass == null || currentState == null || allowedStates == null) return false;

        var currentStateClass = Type.getClass(currentState);

        // Don't process if we're already in the return state
        if (currentStateClass == returnStateClass) return false;

        // Don't process if we already handled this state class
        if (currentStateClass == lastProcessedStateClass) return false;

        // Check if current state is in allowed states or is the tracked state
        var isAllowed = currentStateClass == trackedStateClass;
        if (!isAllowed) {
            for (allowedClass in allowedStates) {
                if (currentStateClass == allowedClass) {
                    isAllowed = true;
                    break;
                }
            }
        }

        // If current state is not allowed and not the return state
        if (!isAllowed && currentStateClass != returnStateClass) {
            // Mark this state as processed to prevent repeated captures
            lastProcessedStateClass = currentStateClass;

            try {
                // Trigger return to the return state
                var newState:MusicBeatState = Type.createInstance(returnStateClass, returnStateArgs != null ? returnStateArgs : []);
                FlxG.switchState(newState);
                return true;
            } catch (e:Dynamic) {
                trace('Failed to create return state: ${e}');
                return false;
            }
        }

        return false;
    }

    /**
     * Gets the current tracked variables with their values
     * Returns a copy of the tracked variables map
     */
    public function getTrackedVariables():Map<String, Dynamic> {
        if (trackedVariables == null) {
            return new Map<String, Dynamic>();
        }

        var result = new Map<String, Dynamic>();
        for (key in trackedVariables.keys()) {
            result.set(key, trackedVariables.get(key));
        }

        // Add navigation context if it exists
        if (navigationContext != null) {
            result.set("_navigationContext", navigationContext);
        }

        return result;
    }

    /**
     * Gets a specific tracked variable value
     */
    public function getTrackedVariable(name:String):Dynamic {
        if (trackedVariables == null) return null;
        return trackedVariables.get(name);
    }

    /**
     * Checks if tracking is currently active
     */
    public function isActive():Bool {
        return trackedStateClass != null && returnStateClass != null;
    }

    /**
     * Clears all tracking configuration
     */
    public function clear() {
        trackedStateClass = null;
        returnStateClass = null;
        allowedStates = [];
        variableNames = [];
        returnStateArgs = [];
        navigationContext = null;
        lastProcessedStateClass = null;
        trackedVariables.clear();
    }

    /**
     * Gets the navigation context for this tracking session
     */
    public function getNavigationContext():String {
        return navigationContext;
    }
}
