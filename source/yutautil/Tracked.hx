package yutautil;

import haxe.ds.StringMap;

typedef TrackedCallback<T> = (event:String, value:T, ?field:String, ?oldValue:Dynamic, ?newValue:Dynamic) -> Void;

private class TrackedValueImpl<T> {
    private var _value:T;
    private var _callbacks:Array<TrackedCallback<T>> = [];
    public var nestedTracking:Bool = false;

    public function new(value:T, ?nestedTracking:Bool = false) {
        this._value = value;
        this.nestedTracking = nestedTracking;
    }

    public function addCallback(cb:TrackedCallback<T>):Void {
        _callbacks.push(cb);
    }

    public function removeCallback(cb:TrackedCallback<T>):Void {
        _callbacks.remove(cb);
    }

    public function get():T {
        _notify("get", _value);

        // After returning, check for field changes and notify if any
        var prevFields = Reflect.fields(_value);
        var prevSnapshot = new haxe.ds.StringMap<Dynamic>();
        for (field in prevFields) {
            prevSnapshot.set(field, Reflect.field(_value, field));
        }

        // Schedule a check on the next event loop tick
        haxe.Timer.delay(() -> {
            var currFields = (() -> {
            try {
                var fields = try Reflect.fields(_value) catch (e:Dynamic) {trace('Tracked: Error in Reflect.fields: $e'); [];};
                var instanceFields = try {Type.getInstanceFields(Type.getClass(_value));} catch (e:Dynamic) {trace('Tracked: Error in Type.getInstanceFields: $e'); [];};
                // Merge and deduplicate
                for (f in instanceFields) {
                if (fields.indexOf(f) == -1) fields.push(f);
                }
                return fields;
            } catch (e:Dynamic) {
                trace('Tracked: Error retrieving fields: $e');
                return [];
            }
            })();
            for (field in currFields) {
                var oldVal = prevSnapshot.get(field);
                var newVal = Reflect.field(_value, field);
                if (oldVal != newVal) {
                    _notify("fieldUpdate", _value, field, oldVal, newVal);
                }
                if (nestedTracking) {
                    // If nested tracking is enabled, check for changes in sub-fields
                    if ((Reflect.isObject(newVal) || Std.isOfType(newVal, Dynamic)) && newVal != null) {
                        var subPrevFields = Reflect.fields(oldVal);
                        var subCurrFields = Reflect.fields(newVal).concat(Type.getInstanceFields(Type.getClass(newVal)));
                        for (subField in subCurrFields) {
                            var oldSubVal = subPrevFields.indexOf(subField) != -1 ? Reflect.field(oldVal, subField) : null;
                            var newSubVal = Reflect.field(newVal, subField);
                            if (oldSubVal != newSubVal || (oldSubVal != null && newSubVal == null)) {
                                _notify("fieldUpdate", _value, field + "." + subField, oldSubVal, newSubVal);
                            }
                        }
                    } else if (newVal == null && oldVal != null) {
                        // If the new value is null but the old value was not, treat as a change
                        _notify("fieldUpdate", _value, field, oldVal, newVal);
                    }
                }
            }
        }, 0);

        return _value;
    }

    public function set(value:T):Void {
        var old = _value;
        _value = value;
        _notify("set", _value, null, old, value);
    }

    public function updateField(field:String, newValue:Dynamic):Void {
        var oldFields = [];
        var newFields = [];
        try {
            oldFields = Reflect.fields(_value);
        } catch (e:Dynamic) {
            trace('Tracked: Error in Reflect.fields (old): $e');
        }
        try {
            var cls = Type.getClass(_value);
            if (cls != null) {
            var instFields = Type.getInstanceFields(cls);
            for (f in instFields) if (oldFields.indexOf(f) == -1) oldFields.push(f);
            }
        } catch (e:Dynamic) {
            trace('Tracked: Error in Type.getInstanceFields (old): $e');
        }

        if (oldFields.indexOf(field) != -1) {
            var oldValue = Reflect.field(_value, field);
            Reflect.setField(_value, field, newValue);

            // Get new fields after update
            try {
            newFields = Reflect.fields(_value);
            } catch (e:Dynamic) {
            trace('Tracked: Error in Reflect.fields (new): $e');
            }
            try {
            var clsNew = Type.getClass(_value);
            if (clsNew != null) {
                var instFieldsNew = Type.getInstanceFields(clsNew);
                for (f in instFieldsNew) if (newFields.indexOf(f) == -1) newFields.push(f);
            }
            } catch (e:Dynamic) {
            trace('Tracked: Error in Type.getInstanceFields (new): $e');
            }

            _notify("fieldUpdate", _value, field, oldValue, newValue);
            if (nestedTracking)
            haxe.Timer.delay(() -> {
            // Check if the field was updated correctly
            var updatedValue = Reflect.field(_value, field);
            if (updatedValue != newValue) {
                trace('Warning: Field "$field" was not updated as expected. Expected: $newValue, Actual: $updatedValue');
            }

            // If the updated field is an object with fields, check for changes in its fields
            if (updatedValue != null && (Reflect.isObject(updatedValue) || Std.isOfType(updatedValue, Dynamic))) {
                var prevSubFields = [];
                var currSubFields = [];
                try {
                prevSubFields = Reflect.fields(oldValue);
                } catch (e:Dynamic) {
                trace('Tracked: Error in Reflect.fields (sub-old): $e');
                }
                try {
                var prevCls = Type.getClass(oldValue);
                if (prevCls != null) {
                    var prevInstFields = Type.getInstanceFields(prevCls);
                    for (f in prevInstFields) if (prevSubFields.indexOf(f) == -1) prevSubFields.push(f);
                }
                } catch (e:Dynamic) {
                trace('Tracked: Error in Type.getInstanceFields (sub-old): $e');
                }
                try {
                currSubFields = Reflect.fields(updatedValue);
                } catch (e:Dynamic) {
                trace('Tracked: Error in Reflect.fields (sub-new): $e');
                }
                try {
                var currCls = Type.getClass(updatedValue);
                if (currCls != null) {
                    var currInstFields = Type.getInstanceFields(currCls);
                    for (f in currInstFields) if (currSubFields.indexOf(f) == -1) currSubFields.push(f);
                }
                } catch (e:Dynamic) {
                trace('Tracked: Error in Type.getInstanceFields (sub-new): $e');
                }
                for (subField in currSubFields) {
                var oldSubVal = prevSubFields.indexOf(subField) != -1 ? Reflect.field(oldValue, subField) : null;
                var newSubVal = Reflect.field(updatedValue, subField);
                if (oldSubVal != newSubVal) {
                    _notify("fieldUpdate", _value, field + "." + subField, oldSubVal, newSubVal);
                }
                }
            } else if (oldValue != null && updatedValue == null) {
                // If the value changed from not null to null, treat as a change
                _notify("fieldUpdate", _value, field, oldValue, updatedValue);
            }
            }, 0);
        }
    }

    private function _notify(event:String, value:T, ?field:String, ?oldValue:Dynamic, ?newValue:Dynamic):Void {
        for (cb in _callbacks) {
            cb(event, value, field, oldValue, newValue);
        }
        // Default trace if no callbacks
        if (_callbacks.length == 0) {
            switch (event) {
                case "get":
                    trace('Tracked: Value accessed.');
                case "set":
                    trace('Tracked: Value changed from $oldValue to $newValue.');
                case "fieldUpdate":
                    trace('Tracked: Field "$field" changed from $oldValue to $newValue.');
                default:
                    trace('Tracked: Event $event occurred.');
            }
        }
    }
}

@:generic
abstract Tracked<T>(TrackedValueImpl<T>) from TrackedValueImpl<T> to TrackedValueImpl<T> to Dynamic{
    public function new(value:T, ?nestedTracking:Bool = false) {
        this = new TrackedValueImpl<T>(value, nestedTracking);
    }

    @:from
    public static function trackValue<T>(value:T):Tracked<T> {
        return new Tracked<T>(value);
    }

    @:to
    public function toValue():T {
        return this.get();
    }

    public function get():T {
        return this.get();
    }

    public function set(value:T):Void {
        this.set(value);
    }

    public function addCallback(cb:TrackedCallback<T>):Void {
        this.addCallback(cb);
    }

    public function removeCallback(cb:TrackedCallback<T>):Void {
        this.removeCallback(cb);
    }

    public function updateField(field:String, newValue:Dynamic):Void {
        this.updateField(field, newValue);
    }
    // Allow direct field access to the underlying value
    @:forward
    @:arrayAccess
    @:op(a.b)
    private inline function __getField(field:String):Dynamic {
        return cast new OneOrMore<Dynamic>(Reflect.field(this.get(), field).forceCast().toArray());
    }

    @:noCompletion
    @:arrayAccess
    @:op(a.b)
    private inline function __setField(field:String, value:Dynamic):Dynamic {
        this.updateField(field, value);
        return this;
    }

    @:noCompletion
    @:op([])
    public function attemptIter(field:String):Dynamic {
        return Reflect.field(this.get(), field).toIterable();
    }

    @:op(a)
    public inline function attemptGet(thing:Dynamic):Dynamic {
        this = new Tracked<T>(thing, this.nestedTracking);
        return this;
    }

    @:noCompletion
    public function resolve():T {
        return this.get();
    }
}