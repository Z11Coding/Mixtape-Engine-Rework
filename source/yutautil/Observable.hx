package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

// Callback types for different kinds of changes
typedef ObjectChangeCallback<T> = (oldValue:T, newValue:T) -> Void;
typedef FieldChangeCallback<T> = (fieldName:String, oldValue:Dynamic, newValue:Dynamic) -> Void;
typedef UsageCallback<T> = (object:T, operation:String) -> Void;

// Internal implementation class for Observable
private class ObservableImpl<T> {
    public var value:T;
    public var objectChangeCallbacks:Array<ObjectChangeCallback<T>>;
    public var fieldChangeCallbacks:Array<FieldChangeCallback<T>>;
    public var usageCallbacks:Array<UsageCallback<T>>;
    public var isTracking:Bool;
    
    // Store original field values for comparison
    public var originalFields:Map<String, Dynamic>;

    public function new(value:T) {
        this.value = value;
        this.objectChangeCallbacks = [];
        this.fieldChangeCallbacks = [];
        this.usageCallbacks = [];
        this.isTracking = true;
        this.originalFields = new Map();
        
        // Initialize field tracking
        if (value != null) {
            captureFields();
        }
    }

    public function captureFields():Void {
        if (value == null) return;
        
        // Use reflection to capture current field values
        var fields = Reflect.fields(value);
        for (field in fields) {
            originalFields.set(field, Reflect.field(value, field));
        }
    }

    public function checkFieldChanges():Void {
        if (value == null || !isTracking) return;
        
        var fields = Reflect.fields(value);
        for (field in fields) {
            var currentValue = Reflect.field(value, field);
            var originalValue = originalFields.get(field);
            
            if (currentValue != originalValue) {
                // Field changed
                for (callback in fieldChangeCallbacks) {
                    callback(field, originalValue, currentValue);
                }
                originalFields.set(field, currentValue);
            }
        }
    }

    public function setValue(newValue:T):Void {
        if (value == newValue) return;
        
        var oldValue = value;
        value = newValue;
        
        // Trigger object change callbacks
        for (callback in objectChangeCallbacks) {
            callback(oldValue, newValue);
        }
        
        // Update field tracking
        if (newValue != null) {
            captureFields();
        }
    }

    public function triggerUsage(operation:String):Void {
        if (!isTracking) return;
        
        for (callback in usageCallbacks) {
            callback(value, operation);
        }
        
        // Check for field changes after usage
        checkFieldChanges();
    }

    public function onObjectChange(callback:ObjectChangeCallback<T>):ObservableImpl<T> {
        objectChangeCallbacks.push(callback);
        return this;
    }

    public function onFieldChange(callback:FieldChangeCallback<T>):ObservableImpl<T> {
        fieldChangeCallbacks.push(callback);
        return this;
    }

    public function onUsage(callback:UsageCallback<T>):ObservableImpl<T> {
        usageCallbacks.push(callback);
        return this;
    }

    public function stopTracking():Void {
        isTracking = false;
    }

    public function startTracking():Void {
        isTracking = true;
        if (value != null) {
            captureFields();
        }
    }
}

// Abstract wrapper for Observable functionality
abstract Observable<T>(ObservableImpl<T>) {
    
    public inline function new(value:T) {
        this = new ObservableImpl<T>(value);
    }

    // Allow implicit conversion from any value to Observable
    @:from
    public static inline function fromValue<T>(value:T):Observable<T> {
        return new Observable<T>(value);
    }

    // Allow using as the wrapped type
    @:to
    public inline function toValue():T {
        this.triggerUsage("access");
        return this.value;
    }

    // Allow implicit conversion to the wrapped type
    @:op(A)
    public inline function get():T {
        this.triggerUsage("get");
        return this.value;
    }

    // Manual set method (since assignment operator overloading isn't supported)
    public inline function set(newValue:T):T {
        this.setValue(newValue);
        return newValue;
    }

    // Field access method
    public inline function getField(fieldName:String):Dynamic {
        this.triggerUsage("field_access." + fieldName);
        return Reflect.field(this.value, fieldName);
    }

    // Field assignment method
    public inline function setField(fieldName:String, value:Dynamic):Dynamic {
        var oldValue = Reflect.field(this.value, fieldName);
        Reflect.setField(this.value, fieldName, value);
        
        // Trigger field change callbacks
        for (callback in this.fieldChangeCallbacks) {
            callback(fieldName, oldValue, value);
        }
        this.originalFields.set(fieldName, value);
        this.triggerUsage("field_set." + fieldName);
        return value;
    }

    // Array access methods (only for array-like types)
    public inline function getAt(index:Int):Dynamic {
        this.triggerUsage("array_access");
        return cast(this.value, Array<Dynamic>)[index];
    }

    public inline function setAt(index:Int, value:Dynamic):Dynamic {
        this.triggerUsage("array_set");
        return cast(this.value, Array<Dynamic>)[index] = value;
    }

    // Callback registration methods
    public inline function onObjectChange(callback:ObjectChangeCallback<T>):Observable<T> {
        this.onObjectChange(callback);
        return cast this;
    }

    public inline function onFieldChange(callback:FieldChangeCallback<T>):Observable<T> {
        this.onFieldChange(callback);
        return cast this;
    }

    public inline function onUsage(callback:UsageCallback<T>):Observable<T> {
        this.onUsage(callback);
        return cast this;
    }

    // Control methods
    public inline function stopTracking():Void {
        this.stopTracking();
    }

    public inline function startTracking():Void {
        this.startTracking();
    }

    public inline function checkFieldChanges():Void {
        this.checkFieldChanges();
    }

    // Utility methods
    public inline function getValue():T {
        return this.value;
    }

    public inline function isTracking():Bool {
        return this.isTracking;
    }
}
