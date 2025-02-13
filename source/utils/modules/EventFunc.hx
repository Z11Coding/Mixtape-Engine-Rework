package backend.modules;

enum EventType {
    GreaterThan(value: Float);
    LessThan(value: Float);
    EqualTo(value: Dynamic);
    Change;
}

class EventFunc {
    public var eventName: String;
    public var eventType: EventType;
    public var watchedVariable: Variable<Dynamic>; // Now a function returning Dynamic
    public var func: Void -> Void;
    private var lastValue: Dynamic;
    private var destroyOnTrigger: Null<Bool>;
    private static var instances: Array<EventFunc> = [];

    public inline function new(eventName: String, eventType: EventType, watchedVariable: Dynamic, func: Void -> Void, ?destroyOnTrigger: Bool = true) {
        this.eventName = eventName;
        this.eventType = eventType;
        this.watchedVariable = watchedVariable;
        this.func = func;
        this.lastValue = watchedVariable.evaluate(); // Evaluate to initialize
        this.destroyOnTrigger = destroyOnTrigger;
        trace('EventFunc created: ${eventName}');
        trace('Arguments: ${eventName}, ${eventType}, ${objectToString(watchedVariable)}, ${func}, ${destroyOnTrigger}');
        instances.push(this);
        trace(this.lastValue);
    }

    public inline function check(): Bool {
        var currentValue:Dynamic = watchedVariable.evaluate(); // Evaluate the expression
        var triggered = false;
        switch eventType {
            case GreaterThan(value):
                if (Std.is(currentValue, Float) && currentValue > value) {
                    triggered = true;
                }
            case LessThan(value):
                if (Std.is(currentValue, Float) && currentValue < value) {
                    triggered = true;
                }
            case EqualTo(value):
                if (currentValue == value) {
                    triggered = true;
                }
            case Change:
                if (currentValue != lastValue) {
                    triggered = true;
                }
        }
        if (triggered) {
            execute();
            lastValue = currentValue; // Update lastValue after execution
            return true;
        }
        //trace(lastValue);
        //trace(currentValue);
        lastValue = currentValue; // Always update lastValue
        return false;
    }
    

    private inline function execute(): Void {
        trace('Event triggered: ${eventName}');
        trace('Event type: ${Std.string(eventType)}');
        trace('Executing function: ${objectToString(func)}');
        func();


        if (destroyOnTrigger) {
            // Remove this instance from the array
            instances = instances.filter(function(e) return e != this);
            // Nullify references to the object
            eventName = null;
            eventType = null;
            watchedVariable = null;
            func = null;
            lastValue = null;
            destroyOnTrigger = null;
        }
    }

    public inline function update(): Void {
        check();
    }

    public static inline function updateAll(): Void {
        for (instance in instances) {
            try {
                instance.update();
            } catch (error: Dynamic) {
                trace('Could not track variable for ${instance.eventName}. Could it be removed, or invalid?');
                trace('Removing instance due to error');
                // Remove this instance from the array
                instances = instances.filter(function(e) return e != instance);
                // Nullify references to the object
                instance.eventName = null;
                instance.eventType = null;
                instance.watchedVariable = null;
                instance.func = null;
                instance.lastValue = null;
                instance.destroyOnTrigger = null;
            }
        }
    }


    public static inline function destroyAll(): Void {
        for (instance in instances) {
            instance = null;
        }
        instances = [];
        trace('All events destroyed');
    }

    public static inline function tracker(v:Dynamic):Dynamic {
        trace('Tracker called with value: ${Std.string(v)}');
        return v;
    }

    /*public static inline function getValue(v:Dynamic):Dynamic {
        trace('getValue called with value: ${Std.string(v)}');
        return v;
    }*/

    
    public static function objectToString(funcVar:Dynamic):String {
    // Check if it's indeed a function
        if (Reflect.isFunction(funcVar)) {
            // Attempt to retrieve any possible metadata or properties that might be attached to the function
            var properties:Array<String> = [];
            for (field in Reflect.fields(funcVar)) {
                var value = Reflect.field(funcVar, field);
                properties.push('$field: ${Std.string(value)}');
            }
            var propertiesString = properties.join(', ');
            return 'Function Variable' + (properties.length > 0 ? ' with properties { $propertiesString }' : '');
        } else {
            // Fallback for non-function variables, just in case
            return 'Not a Function Variable';
        }
        return '(Unknown Error parsing object)';
    }

    // public static function createEventFunc(eventName:String, eventType:EventType, expression:Dynamic, func:Void->Void, ?destroyOnTrigger:Bool = true):EventFunc {
    //     // Use HoldableVariable.createVariable to wrap the expression in a Variable
    //     var variableExpr = null;
        
    //     // Since createVariable is a macro, it returns an Expr, which needs to be evaluated to a Variable<Dynamic>
    //     // This step is conceptual and assumes the existence of a mechanism to convert Expr to Variable<Dynamic>
    //     // In practice, this might involve macro magic or a different approach to directly instantiate Variable
    //     var variable:Variable<Dynamic> = HoldableVariable.createVariable(expression);
    //     trace(variable + " is the variable");
        
    //     // Create the EventFunc instance with the Variable
    //     var eventFunc = new EventFunc(eventName, eventType, variable, func, destroyOnTrigger);
        
    //     return eventFunc;
    // }
}



    // class Tracker {
    // }
